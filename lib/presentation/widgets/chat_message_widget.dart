import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_shapes.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/entities/chat_message.dart';
import '../services/file_part_action_service.dart' as file_part_action;
import '../utils/diff_parser.dart';
import '../utils/reasoning_status_parser.dart';

/// Chat message widget.
///
/// Uses a StatefulWidget so that completed messages can skip expensive
/// rebuilds when only transient props (like [isSessionActivelyResponding])
/// change during streaming — those props don't affect completed bubbles.
class ChatMessageWidget extends StatefulWidget {
  const ChatMessageWidget({
    super.key,
    required this.message,
    this.activeReasoningPartKey,
    this.showThinkingBubbles = true,
    this.showToolCallBubbles = true,
    this.isSessionActivelyResponding = false,
    this.onBackgroundLongPress,
    this.onBackgroundLongPressEnd,
  });

  final ChatMessage message;
  final String? activeReasoningPartKey;
  final bool showThinkingBubbles;
  final bool showToolCallBubbles;
  final bool isSessionActivelyResponding;
  final VoidCallback? onBackgroundLongPress;
  final VoidCallback? onBackgroundLongPressEnd;

  @override
  State<ChatMessageWidget> createState() => _ChatMessageWidgetState();
}

class _ChatMessageWidgetState extends State<ChatMessageWidget> {
  static const int _collapsedToolDetailMaxLines = 2;
  static const int _collapsedReasoningMaxLines = 4;
  static const int _expandedReasoningMaxLines = 12;
  static const int _maxMarkdownCharsForRichRender = 64000;
  static const int _maxToolOutputPreviewChars = 50000;
  static const int _maxToolCommandPreviewChars = 6000;
  static const int _maxSyntheticDiffChars = 20000;

  // Snapshot of the last build inputs to skip redundant rebuilds.
  // Completed messages can skip rebuild when no visible prop changed.
  int _lastPartCount = -1;
  String? _lastPartId;
  String? _lastReasoningKey;
  bool _lastShowThinking = true;
  bool _lastShowToolCalls = true;
  bool _lastResponding = false;

  /// Whether the current rebuild can be skipped (inputs unchanged).
  bool _canSkipRebuild() {
    final msg = widget.message;
    final isCompleted = msg is AssistantMessage && msg.isCompleted;
    if (!isCompleted) return false;

    final partCount = msg.parts.length;
    final lastPartId = msg.parts.isNotEmpty ? msg.parts.last.id : null;
    return partCount == _lastPartCount &&
        lastPartId == _lastPartId &&
        widget.activeReasoningPartKey == _lastReasoningKey &&
        widget.showThinkingBubbles == _lastShowThinking &&
        widget.showToolCallBubbles == _lastShowToolCalls &&
        widget.isSessionActivelyResponding == _lastResponding;
  }

  void _updateBuildSnapshot() {
    final msg = widget.message;
    _lastPartCount = msg.parts.length;
    _lastPartId = msg.parts.isNotEmpty ? msg.parts.last.id : null;
    _lastReasoningKey = widget.activeReasoningPartKey;
    _lastShowThinking = widget.showThinkingBubbles;
    _lastShowToolCalls = widget.showToolCallBubbles;
    _lastResponding = widget.isSessionActivelyResponding;
  }

  // Cached build result to return when rebuild is skipped.
  Widget? _cachedBuild;

  // Cached MarkdownStyleSheet and builders to avoid re-creating objects on
  // every build, which would force flutter_markdown_plus to re-parse.
  MarkdownStyleSheet? _cachedMarkdownStyleSheet;
  Brightness? _cachedMarkdownBrightness;

  MarkdownStyleSheet _resolveMarkdownStyleSheet(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (_cachedMarkdownStyleSheet != null &&
        _cachedMarkdownBrightness == brightness) {
      return _cachedMarkdownStyleSheet!;
    }
    final sheet = MarkdownStyleSheet(
      p: Theme.of(context).textTheme.bodyMedium,
      code: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontFamily: 'monospace',
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      codeblockDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: AppShapes.borderSmall,
      ),
    );
    _cachedMarkdownBrightness = brightness;
    _cachedMarkdownStyleSheet = sheet;
    return sheet;
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedBuild != null && _canSkipRebuild()) {
      return _cachedBuild!;
    }
    _updateBuildSnapshot();
    final result = _buildContent(context);
    _cachedBuild = result;
    return result;
  }

  // -- Accessors to shorten migration from StatelessWidget to StatefulWidget --
  ChatMessage get message => widget.message;
  String? get activeReasoningPartKey => widget.activeReasoningPartKey;
  bool get showThinkingBubbles => widget.showThinkingBubbles;
  bool get showToolCallBubbles => widget.showToolCallBubbles;
  bool get isSessionActivelyResponding => widget.isSessionActivelyResponding;
  VoidCallback? get onBackgroundLongPress => widget.onBackgroundLongPress;
  VoidCallback? get onBackgroundLongPressEnd => widget.onBackgroundLongPressEnd;

  Widget _buildContent(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final colorScheme = Theme.of(context).colorScheme;
    final bubbleBorderRadius = AppShapes.borderLarge.copyWith(
      bottomRight: isUser ? const Radius.circular(6) : null,
      bottomLeft: !isUser ? const Radius.circular(6) : null,
    );

    final hasVisibleContent = _messageHasVisibleContent(message);
    final hasVisibleError =
        message is AssistantMessage &&
        (message as AssistantMessage).error != null;
    final latestReasoningPartId = message.parts
        .whereType<ReasoningPart>()
        .lastOrNull
        ?.id;
    // Lazy: only check if copyable text exists (cheap), defer the full
    // text composition to the onDoubleTap callback to avoid O(parts) per build.
    final canCopyWholeMessage = message.parts.whereType<TextPart>().any(
      (part) => part.text.trim().isNotEmpty,
    );

    if (!hasVisibleContent && !hasVisibleError) {
      return const SizedBox.shrink();
    }

    final renderedParts = _buildMessagePartWidgets(
      context,
      latestReasoningPartId: latestReasoningPartId,
      activeReasoningPartKey: activeReasoningPartKey,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: _BubbleTouchHoldLayer(
            borderRadius: bubbleBorderRadius,
            flashColor: colorScheme.primary.withValues(alpha: 0.16),
            onLongPress: isUser ? onBackgroundLongPress : null,
            onLongPressRelease: isUser ? onBackgroundLongPressEnd : null,
            onDoubleTap: canCopyWholeMessage
                ? () => _copyTextToClipboard(
                    context,
                    _composeMessageCopyText(message),
                  )
                : null,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: BoxDecoration(
                color: isUser
                    ? colorScheme.primaryContainer.withValues(alpha: 0.45)
                    : colorScheme.surfaceContainerHigh,
                borderRadius: bubbleBorderRadius,
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isUser ? 'You' : 'Assistant',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: isUser
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(message.time),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                          ),
                          const Spacer(),
                          if (!isUser && message is AssistantMessage)
                            _buildAssistantInfo(
                              context,
                              message as AssistantMessage,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (isUser)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: renderedParts,
                        )
                      else
                        SelectionArea(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: renderedParts,
                          ),
                        ),
                      if (message is AssistantMessage &&
                          (message as AssistantMessage).error != null)
                        _buildErrorInfo(
                          context,
                          (message as AssistantMessage).error!,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _messageHasVisibleContent(ChatMessage message) {
    for (final part in message.parts) {
      if (!_shouldRenderPart(part)) {
        continue;
      }
      if (_partHasVisiblePayload(part)) {
        return true;
      }
    }
    return false;
  }

  bool _shouldRenderPart(MessagePart part) {
    if (part.type == PartType.reasoning && !showThinkingBubbles) {
      return false;
    }
    if ((part.type == PartType.tool || part.type == PartType.patch) &&
        !showToolCallBubbles) {
      return false;
    }
    if (part.type == PartType.tool && _isTodoToolPart(part as ToolPart)) {
      return false;
    }
    return true;
  }

  bool _partHasVisiblePayload(MessagePart part) {
    switch (part.type) {
      case PartType.text:
        return (part as TextPart).text.trim().isNotEmpty;
      case PartType.reasoning:
        final reasoningPart = part as ReasoningPart;
        return parseReasoningStatusLabel(reasoningPart.text) == null &&
            reasoningPart.text.trim().isNotEmpty;
      case PartType.stepStart:
      case PartType.stepFinish:
        return false;
      default:
        return true;
    }
  }

  Widget _buildAssistantInfo(BuildContext context, AssistantMessage message) {
    final stepStarts = message.parts.whereType<StepStartPart>().toList();
    final stepFinishes = message.parts.whereType<StepFinishPart>().toList();

    return PopupMenuButton<String>(
      icon: Icon(
        Symbols.info,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      tooltip: 'Message Info',
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[
          if (message.modelId != null)
            PopupMenuItem(
              enabled: false,
              child: Text('Model: ${message.modelId}'),
            ),
          if (message.providerId != null)
            PopupMenuItem(
              enabled: false,
              child: Text('Provider: ${message.providerId}'),
            ),
          if (message.tokens != null)
            PopupMenuItem(
              enabled: false,
              child: Text('Tokens: ${message.tokens!.total}'),
            ),
          if (message.cost != null)
            PopupMenuItem(
              enabled: false,
              child: Text('Cost: \$${message.cost!.toStringAsFixed(6)}'),
            ),
        ];

        final hasStepMetadata =
            stepStarts.isNotEmpty || stepFinishes.isNotEmpty;
        if (items.isNotEmpty && hasStepMetadata) {
          items.add(const PopupMenuDivider());
        }

        for (var index = 0; index < stepStarts.length; index += 1) {
          final stepStart = stepStarts[index];
          final snapshot = stepStart.snapshot?.trim();
          final details = snapshot == null || snapshot.isEmpty
              ? 'Step started #${index + 1}'
              : 'Step started #${index + 1}: $snapshot';
          items.add(PopupMenuItem(enabled: false, child: Text(details)));
        }

        for (var index = 0; index < stepFinishes.length; index += 1) {
          final stepFinish = stepFinishes[index];
          final details =
              'Step finished #${index + 1}: ${stepFinish.reason} • tokens ${stepFinish.tokens.total} • \$${stepFinish.cost.toStringAsFixed(6)}';
          items.add(PopupMenuItem(enabled: false, child: Text(details)));
        }

        if (items.isEmpty) {
          items.add(
            const PopupMenuItem(
              enabled: false,
              child: Text('No metadata available'),
            ),
          );
        }

        return items;
      },
    );
  }

  Widget _buildMessagePart(
    BuildContext context,
    MessagePart part, {
    required String? latestReasoningPartId,
    required String? activeReasoningPartKey,
  }) {
    switch (part.type) {
      case PartType.text:
        return _buildTextPart(context, part as TextPart);
      case PartType.file:
        return _buildFilePart(context, part as FilePart);
      case PartType.tool:
        if (!showToolCallBubbles) {
          return const SizedBox.shrink();
        }
        if (_isTodoToolPart(part as ToolPart)) {
          return const SizedBox.shrink();
        }
        return _buildToolPart(context, part);
      case PartType.agent:
        return _buildAgentPart(context, part as AgentPart);
      case PartType.reasoning:
        if (!showThinkingBubbles) {
          return const SizedBox.shrink();
        }
        final reasoningPart = part as ReasoningPart;
        final reasoningPartKey = _reasoningPartKey(
          messageId: reasoningPart.messageId,
          partId: reasoningPart.id,
        );
        return _buildReasoningPart(
          context,
          reasoningPart,
          partKey: reasoningPartKey,
          isLatestReasoningPart: activeReasoningPartKey == null
              ? reasoningPart.id == latestReasoningPartId
              : reasoningPartKey == activeReasoningPartKey,
        );
      case PartType.stepStart:
        return const SizedBox.shrink();
      case PartType.stepFinish:
        return const SizedBox.shrink();
      case PartType.snapshot:
        return _buildSnapshotPart(context, part as SnapshotPart);
      case PartType.patch:
        if (!showToolCallBubbles) {
          return const SizedBox.shrink();
        }
        return _buildPatchPart(context, part as PatchPart);
      case PartType.subtask:
        return _buildSubtaskPart(context, part as SubtaskPart);
      case PartType.retry:
        return _buildRetryPart(context, part as RetryPart);
      case PartType.compaction:
        return _buildCompactionPart(context, part as CompactionPart);
    }
  }

  Widget _buildMessagePartSafely(
    BuildContext context,
    MessagePart part, {
    required String? latestReasoningPartId,
    required String? activeReasoningPartKey,
  }) {
    try {
      return _buildMessagePart(
        context,
        part,
        latestReasoningPartId: latestReasoningPartId,
        activeReasoningPartKey: activeReasoningPartKey,
      );
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Failed to render message part safely',
        error: error,
        stackTrace: stackTrace,
      );
      return _buildInfoContainer(
        context,
        icon: Symbols.warning_amber_rounded,
        title: 'Message part unavailable',
        subtitle: 'Large or malformed content was skipped for stability.',
      );
    }
  }

  List<Widget> _buildMessagePartWidgets(
    BuildContext context, {
    required String? latestReasoningPartId,
    required String? activeReasoningPartKey,
  }) {
    final assistantMessage = message is AssistantMessage
        ? message as AssistantMessage
        : null;
    final shouldAutoCollapseToolChains =
        assistantMessage != null &&
        assistantMessage.isCompleted &&
        !isSessionActivelyResponding;
    if (assistantMessage == null ||
        !shouldAutoCollapseToolChains ||
        !showToolCallBubbles) {
      return message.parts
          .map<Widget>(
            (part) => _buildMessagePartSafely(
              context,
              part,
              latestReasoningPartId: latestReasoningPartId,
              activeReasoningPartKey: activeReasoningPartKey,
            ),
          )
          .toList(growable: false);
    }

    final rendered = <Widget>[];
    var index = 0;
    while (index < message.parts.length) {
      final part = message.parts[index];
      if (!_isToolSurfacePart(part)) {
        rendered.add(
          _buildMessagePartSafely(
            context,
            part,
            latestReasoningPartId: latestReasoningPartId,
            activeReasoningPartKey: activeReasoningPartKey,
          ),
        );
        index += 1;
        continue;
      }

      final chainParts = <MessagePart>[];
      while (index < message.parts.length &&
          _isToolSurfacePart(message.parts[index])) {
        chainParts.add(message.parts[index]);
        index += 1;
      }

      if (chainParts.length <= 1) {
        rendered.add(
          _buildMessagePartSafely(
            context,
            chainParts.first,
            latestReasoningPartId: latestReasoningPartId,
            activeReasoningPartKey: activeReasoningPartKey,
          ),
        );
        continue;
      }

      rendered.add(
        _CollapsibleToolChain(
          key: ValueKey<String>(
            'tool_chain_${message.id}_${chainParts.first.id}',
          ),
          messageId: message.id,
          startPartId: chainParts.first.id,
          autoCollapsed: shouldAutoCollapseToolChains,
          parts: chainParts,
          partBuilder: (toolPart) => _buildMessagePart(
            context,
            toolPart,
            latestReasoningPartId: latestReasoningPartId,
            activeReasoningPartKey: activeReasoningPartKey,
          ),
        ),
      );
    }

    return rendered;
  }

  bool _isToolSurfacePart(MessagePart part) {
    if (part.type == PartType.tool && _isTodoToolPart(part as ToolPart)) {
      return false;
    }
    return part.type == PartType.tool || part.type == PartType.patch;
  }

  bool _isTodoToolPart(ToolPart part) {
    final normalized = _normalizeToolName(part.tool);
    return normalized == 'todowrite' || normalized == 'todoread';
  }

  Widget _buildTextPart(BuildContext context, TextPart part) {
    // Don't display if text is empty or only whitespace
    if (part.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final textForRender = _truncatePreview(
      part.text,
      maxChars: _maxMarkdownCharsForRichRender,
      reason: 'Large message preview truncated for app stability.',
    );
    final usePlainText = textForRender != part.text;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (usePlainText)
            Text(textForRender, style: Theme.of(context).textTheme.bodyMedium)
          else
            MarkdownBody(
              data: textForRender,
              styleSheet: _resolveMarkdownStyleSheet(context),
              builders: <String, MarkdownElementBuilder>{
                'pre': _MarkdownCodeBlockTapBuilder(
                  onTapCode: (code) => _copyTextToClipboard(context, code),
                ),
                'code': _MarkdownInlineCodeTapBuilder(
                  onTapCode: (code) => _copyTextToClipboard(context, code),
                ),
              },
              onTapLink: (text, href, title) {
                final normalizedHref = href?.trim();
                if (normalizedHref == null || normalizedHref.isEmpty) {
                  return;
                }
                unawaited(_openMarkdownLink(context, normalizedHref));
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _composeMessageCopyText(ChatMessage message) {
    final parts = message.parts
        .whereType<TextPart>()
        .map((part) => part.text.trim())
        .where((text) => text.isNotEmpty)
        .toList(growable: false);
    return parts.join('\n\n');
  }

  void _copyTextToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.android) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  Future<void> _openMarkdownLink(BuildContext context, String href) async {
    Uri? uri = Uri.tryParse(href);
    if (uri == null) {
      _showLinkOpenFeedback(context, 'Invalid link format');
      return;
    }
    if (!uri.hasScheme) {
      uri = Uri.tryParse('https://$href');
    }
    if (uri == null || uri.host.trim().isEmpty) {
      _showLinkOpenFeedback(context, 'Invalid link format');
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showLinkOpenFeedback(context, 'Unable to open link');
      }
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Failed to open markdown link',
        error: error,
        stackTrace: stackTrace,
      );
      _showLinkOpenFeedback(context, 'Unable to open link');
    }
  }

  void _showLinkOpenFeedback(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildFilePart(BuildContext context, FilePart part) {
    final sourcePath = part.fileSource?.path ?? part.symbolSource?.path;
    final isInlineDataAttachment = _isInlineDataAttachment(part.url);
    final imagePreview = _buildImageAttachmentPreview(context, part);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: AppShapes.borderSmall,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imagePreview != null) ...[
            imagePreview,
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Icon(
                _getFileIcon(part.mime),
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.filename ?? 'File',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (sourcePath != null && sourcePath.trim().isNotEmpty)
                      Text(
                        sourcePath,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  unawaited(
                    _handleFilePartAction(
                      context,
                      url: part.url,
                      sourcePath: sourcePath,
                      mimeType: part.mime,
                      filename: part.filename,
                    ),
                  );
                },
                icon: Icon(
                  isInlineDataAttachment
                      ? Symbols.download_rounded
                      : Symbols.open_in_new_rounded,
                ),
                tooltip: isInlineDataAttachment ? 'Save File' : 'Open File',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _buildImageAttachmentPreview(BuildContext context, FilePart part) {
    if (!part.mime.toLowerCase().startsWith('image/')) {
      return null;
    }

    final image = _resolveAttachmentImageWidget(part.url);
    if (image == null) {
      return null;
    }

    return ClipRRect(
      key: ValueKey<String>('file_image_preview_${part.id}'),
      borderRadius: AppShapes.borderSmall,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220, minHeight: 120),
        child: Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.surface,
          child: image,
        ),
      ),
    );
  }

  Widget? _resolveAttachmentImageWidget(String rawUrl) {
    final trimmedUrl = rawUrl.trim();
    if (trimmedUrl.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(trimmedUrl);
    if (parsed == null) {
      return null;
    }

    final scheme = parsed.scheme.toLowerCase();
    if (scheme == 'data') {
      final bytes = _decodeDataUriBytes(trimmedUrl);
      if (bytes == null || bytes.isEmpty) {
        return null;
      }
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      );
    }
    if (scheme == 'http' || scheme == 'https') {
      return Image.network(trimmedUrl, fit: BoxFit.cover);
    }
    return null;
  }

  Uint8List? _decodeDataUriBytes(String dataUrl) {
    try {
      return Uint8List.fromList(UriData.parse(dataUrl).contentAsBytes());
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleFilePartAction(
    BuildContext context, {
    required String url,
    required String? sourcePath,
    required String mimeType,
    required String? filename,
  }) async {
    final result = await file_part_action.handleFilePartAction(
      url: url,
      sourcePath: sourcePath,
      mimeType: mimeType,
      filename: filename,
    );
    if (!context.mounted || result.message == null) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message!)));
  }

  bool _isInlineDataAttachment(String url) {
    if (url.trim().isEmpty) {
      return false;
    }
    final parsed = Uri.tryParse(url.trim());
    return parsed?.scheme.toLowerCase() == 'data';
  }

  _ToolPresentation _toolPresentation(String rawToolName) {
    final normalized = _normalizeToolName(rawToolName);
    switch (normalized) {
      case 'bash':
      case 'shell':
        return _ToolPresentation(
          title: 'Running command',
          subtitle: rawToolName,
          icon: Symbols.terminal_rounded,
        );
      case 'read':
        return _ToolPresentation(
          title: 'Reading file',
          subtitle: rawToolName,
          icon: Symbols.description,
        );
      case 'write':
        return _ToolPresentation(
          title: 'Writing file',
          subtitle: rawToolName,
          icon: Symbols.edit_note_rounded,
        );
      case 'edit':
      case 'apply_patch':
      case 'patch':
        return _ToolPresentation(
          title: 'Editing files',
          subtitle: rawToolName,
          icon: Symbols.auto_fix_high_rounded,
        );
      case 'glob':
      case 'find':
        return _ToolPresentation(
          title: 'Finding files',
          subtitle: rawToolName,
          icon: Symbols.folder_open,
        );
      case 'grep':
        return _ToolPresentation(
          title: 'Searching code',
          subtitle: rawToolName,
          icon: Symbols.search_rounded,
        );
      case 'webfetch':
      case 'google_search':
      case 'brave_web_search':
      case 'brave_news_search':
      case 'brave_video_search':
      case 'brave_image_search':
      case 'brave_local_search':
        return _ToolPresentation(
          title: 'Searching the web',
          subtitle: rawToolName,
          icon: Symbols.travel_explore_rounded,
        );
      case 'question':
        return _ToolPresentation(
          title: 'Waiting for your input',
          subtitle: rawToolName,
          icon: Symbols.help_outline_rounded,
        );
      case 'todowrite':
      case 'todoread':
        return _ToolPresentation(
          title: 'Updating task list',
          subtitle: rawToolName,
          icon: Symbols.checklist_rounded,
        );
      default:
        return _ToolPresentation(
          title: 'Running ${_humanizeToolName(normalized)}',
          subtitle: rawToolName,
          icon: Symbols.extension,
        );
    }
  }

  String _normalizeToolName(String rawToolName) {
    final normalized = rawToolName.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'tool';
    }
    final separatorIndex = normalized.lastIndexOf('.');
    final compactName = separatorIndex >= 0
        ? normalized.substring(separatorIndex + 1)
        : normalized;
    return compactName.replaceAll('-', '_');
  }

  String _humanizeToolName(String normalizedToolName) {
    final words = normalizedToolName
        .split('_')
        .where((segment) => segment.trim().isNotEmpty)
        .map((segment) {
          final trimmed = segment.trim();
          return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
        })
        .toList(growable: false);
    if (words.isEmpty) {
      return 'Tool';
    }
    return words.join(' ');
  }

  Widget _buildToolPart(BuildContext context, ToolPart part) {
    final isCompactToolStatus = MediaQuery.sizeOf(context).width < 600;
    final colorScheme = Theme.of(context).colorScheme;
    final presentation = _toolPresentation(part.tool);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppShapes.borderSmall,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(presentation.icon, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      presentation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      presentation.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildToolStatusChip(
                context,
                part.state.status,
                showLabel: !isCompactToolStatus,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Tool status details
          _buildToolStateDetails(context, part.state, part.tool),
        ],
      ),
    );
  }

  Widget _buildReasoningPart(
    BuildContext context,
    ReasoningPart part, {
    required String partKey,
    required bool isLatestReasoningPart,
  }) {
    if (parseReasoningStatusLabel(part.text) != null) {
      return const SizedBox.shrink();
    }

    // Don't display if reasoning text is empty or only whitespace
    if (part.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: AppShapes.borderSmall,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Symbols.psychology,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Thinking Process',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _CollapsibleReasoningContent(
            partKey: partKey,
            text: part.text,
            collapsedMaxLines: _collapsedReasoningMaxLines,
            expandedMaxLines: _expandedReasoningMaxLines,
            isLatestReasoningPart: isLatestReasoningPart,
            textStyle: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentPart(BuildContext context, AgentPart part) {
    return _buildInfoContainer(
      context,
      icon: Symbols.support_agent,
      title: 'Agent',
      subtitle: part.name,
    );
  }

  Widget _buildSnapshotPart(BuildContext context, SnapshotPart part) {
    return _buildInfoContainer(
      context,
      icon: Symbols.camera_alt,
      title: 'Snapshot',
      subtitle: part.snapshot,
    );
  }

  Widget _buildPatchPart(BuildContext context, PatchPart part) {
    final files = part.files.take(4).join(', ');
    final suffix = part.files.length > 4
        ? ' (+${part.files.length - 4} more)'
        : '';
    return _buildInfoContainer(
      context,
      icon: Symbols.compare_arrows,
      title: 'Patch',
      subtitle: files.isEmpty ? part.hash : '$files$suffix',
    );
  }

  Widget _buildSubtaskPart(BuildContext context, SubtaskPart part) {
    final model = part.model == null
        ? ''
        : ' • ${part.model!.providerId}/${part.model!.modelId}';
    return _buildInfoContainer(
      context,
      icon: Symbols.task,
      title: 'Subtask (${part.agent})',
      subtitle: '${part.description}$model',
    );
  }

  Widget _buildRetryPart(BuildContext context, RetryPart part) {
    return _buildInfoContainer(
      context,
      icon: Symbols.refresh,
      title: 'Retry #${part.attempt}',
      subtitle: part.error.message,
    );
  }

  Widget _buildCompactionPart(BuildContext context, CompactionPart part) {
    return _buildInfoContainer(
      context,
      icon: Symbols.compress,
      title: 'Compaction',
      subtitle: part.auto ? 'automatic' : 'manual',
    );
  }

  Widget _buildInfoContainer(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: AppShapes.borderSmall,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolStatusChip(
    BuildContext context,
    ToolStatus status, {
    required bool showLabel,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case ToolStatus.pending:
        color = colorScheme.secondary;
        label = 'Queued';
        icon = Symbols.schedule;
        break;
      case ToolStatus.running:
        color = colorScheme.primary;
        label = 'In progress';
        icon = Symbols.play_arrow;
        break;
      case ToolStatus.completed:
        color = colorScheme.tertiary;
        label = 'Done';
        icon = Symbols.check_circle_outline_rounded;
        break;
      case ToolStatus.error:
        color = colorScheme.error;
        label = 'Needs attention';
        icon = Symbols.warning_amber_rounded;
        break;
    }

    if (!showLabel) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppShapes.borderFull,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 16, color: color),
      );
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: Theme.of(context).visualDensity,
    );
  }

  Widget _buildToolStateDetails(
    BuildContext context,
    ToolState state,
    String toolName,
  ) {
    final command = _extractToolCommand(state);
    switch (state.status) {
      case ToolStatus.running:
        final runningState = state as ToolStateRunning;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (command != null)
              _buildToolCommandSection(
                context,
                toolName: toolName,
                command: command,
              ),
            if (runningState.title != null)
              Text(
                runningState.title!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const LinearProgressIndicator(),
          ],
        );
      case ToolStatus.completed:
        final completedState = state as ToolStateCompleted;
        final resolvedOutput = _resolveToolOutput(
          toolName: toolName,
          state: completedState,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (command != null)
              _buildToolCommandSection(
                context,
                toolName: toolName,
                command: command,
              ),
            if (completedState.title != null)
              Text(
                completedState.title!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            if (resolvedOutput.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: AppShapes.borderExtraSmall,
                ),
                child: _buildToolBodyContent(
                  context,
                  text: resolvedOutput,
                  toolName: toolName,
                  lineKeyPrefix: 'tool_output_diff',
                ),
              ),
          ],
        );
      case ToolStatus.error:
        final errorState = state as ToolStateError;
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: AppShapes.borderExtraSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (command != null)
                _buildToolCommandSection(
                  context,
                  toolName: toolName,
                  command: command,
                  inErrorContainer: true,
                ),
              _buildToolBodyContent(
                context,
                text: errorState.error,
                toolName: toolName,
                lineKeyPrefix: 'tool_error_diff',
                textColor: Theme.of(context).colorScheme.onErrorContainer,
                toggleColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildToolBodyContent(
    BuildContext context, {
    required String text,
    required String toolName,
    required String lineKeyPrefix,
    Color? textColor,
    Color? toggleColor,
  }) {
    final textForRender = _truncatePreview(
      text,
      maxChars: _maxToolOutputPreviewChars,
      reason: 'Large tool output preview truncated for app stability.',
    );
    return _CollapsibleToolContent(
      text: textForRender,
      collapsedMaxLines: _collapsedToolDetailMaxLines,
      toolName: toolName,
      lineKeyPrefix: lineKeyPrefix,
      textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: textColor,
        fontFamily: 'monospace',
      ),
      toggleTextStyle: toggleColor == null
          ? null
          : Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: toggleColor),
    );
  }

  Widget _buildToolCommandSection(
    BuildContext context, {
    required String toolName,
    required String command,
    bool inErrorContainer = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelColor = inErrorContainer
        ? colorScheme.onErrorContainer.withValues(alpha: 0.84)
        : colorScheme.onSurfaceVariant;
    final valueColor = inErrorContainer
        ? colorScheme.onErrorContainer
        : colorScheme.onSurface;
    final backgroundColor = inErrorContainer
        ? colorScheme.onErrorContainer.withValues(alpha: 0.08)
        : colorScheme.surface;
    final prefix = toolName.trim().toLowerCase() == 'bash'
        ? 'Command'
        : 'Input';

    final shouldColorizeInput =
        prefix == 'Input' && _isDiffLikeToolInput(toolName, command);

    if (shouldColorizeInput) {
      final normalizedInput = _normalizeToolInputDiff(command);
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppShapes.borderExtraSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$prefix:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            _buildToolBodyContent(
              context,
              text: normalizedInput,
              toolName: toolName,
              lineKeyPrefix: 'tool_input_diff',
              textColor: valueColor,
              toggleColor: labelColor,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppShapes.borderExtraSmall,
      ),
      child: RichText(
        key: const ValueKey<String>('tool_command_text'),
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          children: [
            TextSpan(
              text: '$prefix: ',
              style: TextStyle(color: labelColor, fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: command,
              style: TextStyle(color: valueColor),
            ),
          ],
        ),
      ),
    );
  }

  bool _isDiffLikeToolInput(String toolName, String command) {
    final toolLower = toolName.trim().toLowerCase();

    if (toolLower.contains('apply_patch') ||
        toolLower.contains('patch') ||
        toolLower == 'edit') {
      return command.contains('*** Begin Patch') ||
          command.contains('\n+') ||
          command.contains('\n-') ||
          command.contains('\n@@') ||
          command.contains('\ndiff --git');
    }

    return isDiffFormat(command);
  }

  String _normalizeToolInputDiff(String command) {
    const markers = <String>['*** Begin Patch', 'diff --git', '--- ', '@@'];

    for (final marker in markers) {
      final index = command.indexOf(marker);
      if (index > 0) {
        return command.substring(index).trimRight();
      }
      if (index == 0) {
        return command;
      }
    }

    return command;
  }

  String? _extractToolCommand(ToolState state) {
    switch (state.status) {
      case ToolStatus.pending:
        return null;
      case ToolStatus.running:
        final runningState = state as ToolStateRunning;
        return _extractCommandFromInputMap(runningState.input);
      case ToolStatus.completed:
        final completedState = state as ToolStateCompleted;
        return _extractCommandFromInputMap(completedState.input);
      case ToolStatus.error:
        final errorState = state as ToolStateError;
        return _extractCommandFromInputMap(errorState.input);
    }
  }

  String? _extractCommandFromInputMap(Map<String, dynamic> input) {
    if (input.isEmpty) {
      return null;
    }

    String? readString(dynamic value) {
      if (value is! String) {
        return null;
      }
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    Map<String, dynamic>? readMap(dynamic value) {
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return null;
    }

    final command = readString(input['command']) ?? readString(input['cmd']);
    if (command != null) {
      return _truncatePreview(
        command,
        maxChars: _maxToolCommandPreviewChars,
        reason: 'Command preview truncated for stability.',
      );
    }

    final nestedInput = readMap(input['input']);
    if (nestedInput != null) {
      final nestedCommand = _extractCommandFromInputMap(nestedInput);
      if (nestedCommand != null) {
        return nestedCommand;
      }
    }

    final fallback = input.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(' | ')
        .trim();
    if (fallback.isEmpty) {
      return null;
    }
    return _truncatePreview(
      fallback,
      maxChars: _maxToolCommandPreviewChars,
      reason: 'Input preview truncated for stability.',
    );
  }

  String _resolveToolOutput({
    required String toolName,
    required ToolStateCompleted state,
  }) {
    final output = state.output.trim();
    if (output.isNotEmpty) {
      return _truncatePreview(
        state.output,
        maxChars: _maxToolOutputPreviewChars,
        reason: 'Tool output preview truncated for app stability.',
      );
    }

    final input = state.input;
    final tool = toolName.toLowerCase();
    final directDiff = _firstInputString(input, const [
      'diff',
      'patch',
      'unified_diff',
      'unifiedDiff',
      'content',
      'text',
    ]);
    if (directDiff != null && directDiff.trim().isNotEmpty) {
      return _truncatePreview(
        directDiff,
        maxChars: _maxToolOutputPreviewChars,
        reason: 'Diff preview truncated for app stability.',
      );
    }

    if (tool == 'edit' || tool.contains('edit') || tool.contains('patch')) {
      final syntheticDiff = _buildSyntheticEditDiff(input);
      if (syntheticDiff != null) {
        return syntheticDiff;
      }
    }

    return '';
  }

  String? _firstInputString(Map<String, dynamic> input, List<String> keys) {
    for (final key in keys) {
      final value = input[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String? _buildSyntheticEditDiff(Map<String, dynamic> input) {
    final before = _firstInputString(input, const [
      'old_string',
      'oldString',
      'before',
      'old',
    ]);
    final after = _firstInputString(input, const [
      'new_string',
      'newString',
      'after',
      'new',
    ]);
    if (before == null || after == null || before == after) {
      return null;
    }

    if (before.length + after.length > _maxSyntheticDiffChars) {
      return 'Diff preview omitted: edit payload is too large to render safely on mobile.';
    }

    final path =
        _firstInputString(input, const [
          'file_path',
          'path',
          'file',
          'target',
        ]) ??
        'file';

    final beforeLines = before.split('\n').map((line) => '-$line').join('\n');
    final afterLines = after.split('\n').map((line) => '+$line').join('\n');
    return '--- $path\n+++ $path\n@@\n$beforeLines\n$afterLines';
  }

  String _truncatePreview(
    String text, {
    required int maxChars,
    required String reason,
  }) {
    if (text.length <= maxChars) {
      return text;
    }
    final head = text.substring(0, maxChars);
    final remaining = text.length - maxChars;
    return '$head\n\n[truncated $remaining chars] $reason';
  }

  Widget _buildErrorInfo(BuildContext context, MessageError error) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: AppShapes.borderSmall,
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Symbols.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                Text(
                  error.message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String mime) {
    if (mime.startsWith('image/')) {
      return Symbols.image;
    } else if (mime.startsWith('video/')) {
      return Symbols.video_file;
    } else if (mime.startsWith('audio/')) {
      return Symbols.audio_file;
    } else if (mime.contains('pdf')) {
      return Symbols.picture_as_pdf;
    } else if (mime.contains('text/')) {
      return Symbols.text_snippet;
    } else {
      return Symbols.insert_drive_file;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  String _reasoningPartKey({
    required String messageId,
    required String partId,
  }) {
    return '$messageId::$partId';
  }
}

class _CollapsibleToolChain extends StatefulWidget {
  const _CollapsibleToolChain({
    super.key,
    required this.messageId,
    required this.startPartId,
    required this.autoCollapsed,
    required this.parts,
    required this.partBuilder,
  });

  final String messageId;
  final String startPartId;
  final bool autoCollapsed;
  final List<MessagePart> parts;
  final Widget Function(MessagePart part) partBuilder;

  @override
  State<_CollapsibleToolChain> createState() => _CollapsibleToolChainState();
}

class _CollapsibleToolChainState extends State<_CollapsibleToolChain> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = !widget.autoCollapsed;
  }

  @override
  void didUpdateWidget(covariant _CollapsibleToolChain oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.autoCollapsed && widget.autoCollapsed && _expanded) {
      setState(() {
        _expanded = false;
      });
      return;
    }

    if (oldWidget.autoCollapsed && !widget.autoCollapsed && !_expanded) {
      setState(() {
        _expanded = true;
      });
    }
  }

  String _buildSummaryLabel() {
    final toolParts = widget.parts.whereType<ToolPart>().toList(
      growable: false,
    );
    final patchCount = widget.parts.whereType<PatchPart>().length;
    if (toolParts.isEmpty) {
      return patchCount == 1 ? '1 patch' : '$patchCount patches';
    }

    final pending = toolParts
        .where((part) => part.state.status == ToolStatus.pending)
        .length;
    final running = toolParts
        .where((part) => part.state.status == ToolStatus.running)
        .length;
    final completed = toolParts
        .where((part) => part.state.status == ToolStatus.completed)
        .length;
    final failed = toolParts
        .where((part) => part.state.status == ToolStatus.error)
        .length;

    final summaryParts = <String>[
      toolParts.length == 1 ? '1 call' : '${toolParts.length} calls',
      if (completed > 0) '$completed done',
      if (running > 0) '$running running',
      if (pending > 0) '$pending queued',
      if (failed > 0) '$failed needs attention',
      if (patchCount > 0) patchCount == 1 ? '1 patch' : '$patchCount patches',
    ];
    return summaryParts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Container(
      key: ValueKey<String>(
        'tool_chain_container_${widget.messageId}_${widget.startPartId}',
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
        borderRadius: AppShapes.borderSmall,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Symbols.account_tree, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _expanded ? 'Tool calls' : 'Tool calls collapsed',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _buildSummaryLabel(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: ValueKey<String>(
                  'tool_chain_toggle_${widget.messageId}_${widget.startPartId}',
                ),
                onPressed: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                ),
                child: Text(_expanded ? 'Hide tool calls' : 'Show tool calls'),
              ),
            ],
          ),
          AnimatedSize(
            duration: disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_expanded
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.parts
                          .map<Widget>(widget.partBuilder)
                          .toList(growable: false),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CollapsibleToolContent extends StatefulWidget {
  const _CollapsibleToolContent({
    required this.text,
    required this.collapsedMaxLines,
    required this.toolName,
    this.lineKeyPrefix = 'tool_diff_line',
    this.textStyle,
    this.toggleTextStyle,
  });

  final String text;
  final int collapsedMaxLines;
  final String toolName;
  final String lineKeyPrefix;
  final TextStyle? textStyle;
  final TextStyle? toggleTextStyle;

  @override
  State<_CollapsibleToolContent> createState() =>
      _CollapsibleToolContentState();
}

class _ToolPresentation {
  const _ToolPresentation({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

class _DiffLineVisualStyle {
  const _DiffLineVisualStyle({this.textColor, this.backgroundColor});

  final Color? textColor;
  final Color? backgroundColor;
}

class _CollapsibleToolContentState extends State<_CollapsibleToolContent> {
  bool _expanded = false;

  double _expandedToolViewportHeight(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final responsiveCap = viewportHeight * 0.4;
    return math.min(300.0, responsiveCap.clamp(180.0, 300.0));
  }

  bool get _canExpand {
    if (widget.text.trim().isEmpty) {
      return false;
    }
    final lineCount = '\n'.allMatches(widget.text).length + 1;
    return lineCount > widget.collapsedMaxLines || widget.text.length > 160;
  }

  /// Detecção híbrida: nome da tool + heurística de conteúdo
  bool _isDiffContent(String toolName, String text) {
    final toolLower = toolName.toLowerCase();
    if (toolLower.contains('apply_patch') ||
        toolLower.contains('patch') ||
        toolLower == 'edit') {
      return true;
    }

    // Heurística para bash/outros (primeiras 20 linhas)
    return isDiffFormat(text);
  }

  DiffLineType _resolveDiffLineType(String line) {
    if (line.isEmpty) {
      return DiffLineType.context;
    }
    return parseDiffLines(line).first.type;
  }

  _DiffLineVisualStyle _resolveDiffVisualStyle(
    BuildContext context,
    DiffLineType lineType,
  ) {
    final brightness = Theme.of(context).brightness;
    switch (lineType) {
      case DiffLineType.add:
        return _DiffLineVisualStyle(
          textColor: brightness == Brightness.dark
              ? Colors.green.shade400
              : Colors.green.shade700,
          backgroundColor: brightness == Brightness.dark
              ? Colors.green.shade800.withValues(alpha: 0.45)
              : Colors.green.shade100,
        );
      case DiffLineType.remove:
        return _DiffLineVisualStyle(
          textColor: brightness == Brightness.dark
              ? Colors.red.shade400
              : Colors.red.shade700,
          backgroundColor: brightness == Brightness.dark
              ? Colors.red.shade800.withValues(alpha: 0.42)
              : Colors.red.shade100,
        );
      case DiffLineType.hunk:
        return _DiffLineVisualStyle(
          textColor: brightness == Brightness.dark
              ? Colors.amber.shade300
              : Colors.orange.shade800,
          backgroundColor: brightness == Brightness.dark
              ? Colors.amber.shade800.withValues(alpha: 0.38)
              : Colors.orange.shade100,
        );
      case DiffLineType.metadata:
        return _DiffLineVisualStyle(
          textColor: Theme.of(context).colorScheme.onSurfaceVariant,
        );
      case DiffLineType.context:
        return const _DiffLineVisualStyle();
    }
  }

  Widget _buildDiffLine(
    BuildContext context, {
    required int index,
    required String line,
  }) {
    final lineType = _resolveDiffLineType(line);
    final visualStyle = _resolveDiffVisualStyle(context, lineType);

    return Container(
      key: ValueKey<String>('${widget.lineKeyPrefix}_container_$index'),
      width: double.infinity,
      color: visualStyle.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Text(
        line,
        key: ValueKey<String>('${widget.lineKeyPrefix}_text_$index'),
        style:
            widget.textStyle?.copyWith(color: visualStyle.textColor) ??
            TextStyle(color: visualStyle.textColor, fontFamily: 'monospace'),
      ),
    );
  }

  /// Renderização de diff por linha para garantir fundo visível.
  Widget _buildColorizedDiffContent(BuildContext context, String text) {
    final lines = text.split('\n');
    final maxVisibleLines = _expanded ? lines.length : widget.collapsedMaxLines;
    final visibleLines = lines.take(maxVisibleLines).toList(growable: false);
    final hasHiddenLines = lines.length > visibleLines.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < visibleLines.length; i++)
          _buildDiffLine(context, index: i, line: visibleLines[i]),
        if (!_expanded && hasHiddenLines)
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 2),
            child: Text(
              '...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDiff = _isDiffContent(widget.toolName, widget.text);

    Widget contentWidget;

    if (isDiff) {
      // Diff deve manter semântica visual tanto colapsado quanto expandido.
      contentWidget = _buildColorizedDiffContent(context, widget.text);
    } else {
      // Não é diff → comportamento original
      contentWidget = Text(
        widget.text,
        key: const ValueKey<String>('tool_content_text'),
        maxLines: _expanded ? null : widget.collapsedMaxLines,
        overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        style: widget.textStyle,
      );
    }

    if (!_canExpand) {
      return contentWidget;
    }

    final contentViewport = _expanded
        ? ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: _expandedToolViewportHeight(context),
            ),
            child: SingleChildScrollView(
              key: const ValueKey<String>('tool_content_expanded_scroll'),
              primary: false,
              child: contentWidget,
            ),
          )
        : contentWidget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        contentViewport,
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: const ValueKey<String>('tool_content_toggle_button'),
            onPressed: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            ),
            child: Text(
              _expanded ? 'Show less' : 'Show more',
              style: widget.toggleTextStyle,
            ),
          ),
        ),
      ],
    );
  }
}

class _CollapsibleReasoningContent extends StatefulWidget {
  const _CollapsibleReasoningContent({
    required this.partKey,
    required this.text,
    required this.collapsedMaxLines,
    required this.expandedMaxLines,
    required this.isLatestReasoningPart,
    this.textStyle,
  });

  final String partKey;
  final String text;
  final int collapsedMaxLines;
  final int expandedMaxLines;
  final bool isLatestReasoningPart;
  final TextStyle? textStyle;

  @override
  State<_CollapsibleReasoningContent> createState() =>
      _CollapsibleReasoningContentState();
}

class _CollapsibleReasoningContentState
    extends State<_CollapsibleReasoningContent> {
  late bool _expanded;
  late final ScrollController _scrollController;
  late bool _canExpandSticky;

  bool _computeCanExpand(String text) {
    if (text.trim().isEmpty) {
      return false;
    }
    final lineCount = '\n'.allMatches(text).length + 1;
    return lineCount > widget.collapsedMaxLines || text.length > 160;
  }

  bool get _canExpand {
    if (widget.text.trim().isEmpty) {
      return false;
    }
    return _canExpandSticky || _computeCanExpand(widget.text);
  }

  @override
  void initState() {
    super.initState();
    _expanded = false;
    _scrollController = ScrollController();
    _canExpandSticky = _computeCanExpand(widget.text);
    _scheduleLatestReasoningAutoScroll(forceJump: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CollapsibleReasoningContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLatestReasoningPart && !widget.isLatestReasoningPart) {
      if (_expanded) {
        setState(() {
          _expanded = false;
        });
      }
      return;
    }

    if (!_canExpandSticky && _computeCanExpand(widget.text)) {
      _canExpandSticky = true;
    }

    if (oldWidget.text != widget.text ||
        oldWidget.isLatestReasoningPart != widget.isLatestReasoningPart) {
      _scheduleLatestReasoningAutoScroll(forceJump: false);
    }
  }

  double _resolveViewportHeight(BuildContext context) {
    final fallbackStyle = Theme.of(context).textTheme.bodyMedium;
    final resolvedStyle = widget.textStyle ?? fallbackStyle;
    final fontSize = resolvedStyle?.fontSize ?? 14;
    final lineHeightFactor = resolvedStyle?.height ?? 1.4;
    final textScaler = MediaQuery.textScalerOf(context);
    final lineHeight = textScaler.scale(fontSize) * lineHeightFactor;
    final lineTarget = _expanded
        ? widget.expandedMaxLines
        : widget.collapsedMaxLines;
    return math.max(1, lineTarget) * lineHeight;
  }

  void _scheduleLatestReasoningAutoScroll({required bool forceJump}) {
    if (!widget.isLatestReasoningPart) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      if (maxScrollExtent <= 0) {
        return;
      }
      final currentOffset = _scrollController.position.pixels;
      if ((maxScrollExtent - currentOffset).abs() < 1.0) {
        return;
      }
      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (forceJump || disableAnimations) {
        _scrollController.jumpTo(maxScrollExtent);
        return;
      }
      unawaited(
        _scrollController
            .animateTo(
              maxScrollExtent,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
            )
            .catchError((_) {}),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      widget.text,
      key: ValueKey<String>('thinking_content_text_${widget.partKey}'),
      style: widget.textStyle,
    );
    if (!_canExpand) {
      return textWidget;
    }

    final scrollView = SingleChildScrollView(
      key: ValueKey<String>('thinking_content_scroll_${widget.partKey}'),
      controller: _scrollController,
      primary: false,
      child: textWidget,
    );

    final scrollableContent = _expanded
        ? Scrollbar(
            key: ValueKey<String>(
              'thinking_content_scrollbar_${widget.partKey}',
            ),
            controller: _scrollController,
            thumbVisibility: true,
            child: scrollView,
          )
        : scrollView;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          key: ValueKey<String>('thinking_content_viewport_${widget.partKey}'),
          constraints: BoxConstraints(
            maxHeight: _resolveViewportHeight(context),
          ),
          child: scrollableContent,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: ValueKey<String>('thinking_content_toggle_${widget.partKey}'),
            onPressed: () {
              setState(() {
                _expanded = !_expanded;
              });
              _scheduleLatestReasoningAutoScroll(forceJump: true);
            },
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            ),
            child: Text(_expanded ? 'Show less' : 'Show more'),
          ),
        ),
      ],
    );
  }
}

class _MarkdownCodeBlockTapBuilder extends MarkdownElementBuilder {
  _MarkdownCodeBlockTapBuilder({required this.onTapCode});

  final ValueChanged<String> onTapCode;

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = element.textContent;
    if (code.trim().isEmpty) {
      return null;
    }
    final style =
        preferredStyle ??
        parentStyle ??
        Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTapCode(code),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        child: Text(code, style: style),
      ),
    );
  }
}

class _MarkdownInlineCodeTapBuilder extends MarkdownElementBuilder {
  _MarkdownInlineCodeTapBuilder({required this.onTapCode});

  final ValueChanged<String> onTapCode;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = element.textContent;
    if (code.trim().isEmpty) {
      return null;
    }
    final style =
        preferredStyle ??
        parentStyle ??
        Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTapCode(code),
      child: Text(code, style: style),
    );
  }
}

class _BubbleTouchHoldLayer extends StatefulWidget {
  const _BubbleTouchHoldLayer({
    required this.child,
    required this.borderRadius,
    required this.flashColor,
    this.onLongPress,
    this.onLongPressRelease,
    this.onDoubleTap,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Color flashColor;
  final VoidCallback? onLongPress;
  final VoidCallback? onLongPressRelease;
  final VoidCallback? onDoubleTap;

  @override
  State<_BubbleTouchHoldLayer> createState() => _BubbleTouchHoldLayerState();
}

class _BubbleTouchHoldLayerState extends State<_BubbleTouchHoldLayer> {
  static const Duration _holdDelay = Duration(milliseconds: 260);
  static const Duration _flashDuration = Duration(milliseconds: 170);
  static const Duration _doubleTapTimeout = Duration(milliseconds: 320);
  static const double _moveTolerance = 14;
  static const double _doubleTapTolerance = 24;

  Timer? _holdTimer;
  Timer? _flashTimer;
  int? _activePointer;
  Offset? _pointerDownPosition;
  bool _longPressTriggered = false;
  bool _isFlashing = false;
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;
  PointerDeviceKind? _lastTapKind;

  bool _isTouchLikePointer(PointerEvent event) {
    return event.kind == PointerDeviceKind.touch ||
        event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus;
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.onLongPress == null && widget.onDoubleTap == null) {
      return;
    }
    _holdTimer?.cancel();
    _activePointer = event.pointer;
    _pointerDownPosition = event.localPosition;
    _longPressTriggered = false;
    if (widget.onLongPress != null && _isTouchLikePointer(event)) {
      _holdTimer = Timer(_holdDelay, _triggerLongPress);
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer || _pointerDownPosition == null) {
      return;
    }
    final movedDistance =
        (event.localPosition - _pointerDownPosition!).distance;
    if (!_longPressTriggered && movedDistance > _moveTolerance) {
      _cancelHold();
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer == _activePointer) {
      final shouldDispatchLongPressRelease = _longPressTriggered;
      final shouldHandleTap =
          !_longPressTriggered &&
          _pointerDownPosition != null &&
          (event.localPosition - _pointerDownPosition!).distance <=
              _moveTolerance;
      _cancelHold();
      if (shouldHandleTap) {
        _handlePointerTap(event);
      }
      if (shouldDispatchLongPressRelease) {
        widget.onLongPressRelease?.call();
      }
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer == _activePointer) {
      _cancelHold();
    }
  }

  void _triggerLongPress() {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (!mounted || widget.onLongPress == null) {
      return;
    }
    _longPressTriggered = true;
    _clearTapTracking();
    widget.onLongPress!();
    _triggerFlash();
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _activePointer = null;
    _pointerDownPosition = null;
    _longPressTriggered = false;
  }

  void _clearTapTracking() {
    _lastTapTime = null;
    _lastTapPosition = null;
    _lastTapKind = null;
  }

  void _handlePointerTap(PointerUpEvent event) {
    if (widget.onDoubleTap == null) {
      return;
    }
    final now = DateTime.now();
    final previousTime = _lastTapTime;
    final previousPosition = _lastTapPosition;
    final previousKind = _lastTapKind;
    final isSecondTap =
        previousTime != null &&
        previousPosition != null &&
        previousKind == event.kind &&
        now.difference(previousTime) <= _doubleTapTimeout &&
        (event.localPosition - previousPosition).distance <=
            _doubleTapTolerance;
    if (isSecondTap) {
      _clearTapTracking();
      widget.onDoubleTap?.call();
      return;
    }
    _lastTapTime = now;
    _lastTapPosition = event.localPosition;
    _lastTapKind = event.kind;
  }

  void _triggerFlash() {
    if (!mounted) {
      return;
    }
    _flashTimer?.cancel();
    setState(() {
      _isFlashing = true;
    });
    _flashTimer = Timer(_flashDuration, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _isFlashing = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerCancel,
          child: AbsorbPointer(
            absorbing: _longPressTriggered,
            child: widget.child,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _isFlashing ? 1 : 0,
              duration: const Duration(milliseconds: 120),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.flashColor,
                  borderRadius: widget.borderRadius,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
