import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../domain/entities/chat_message.dart';
import '../utils/reasoning_status_parser.dart';
import '../utils/diff_parser.dart';

/// Chat message widget
class ChatMessageWidget extends StatelessWidget {
  static const int _collapsedToolDetailMaxLines = 2;
  static const int _collapsedReasoningMaxLines = 2;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.activeReasoningPartKey,
    this.showThinkingBubbles = true,
    this.showToolCallBubbles = true,
    this.onBackgroundLongPress,
    this.onBackgroundLongPressEnd,
  });

  final ChatMessage message;
  final String? activeReasoningPartKey;
  final bool showThinkingBubbles;
  final bool showToolCallBubbles;
  final VoidCallback? onBackgroundLongPress;
  final VoidCallback? onBackgroundLongPressEnd;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final colorScheme = Theme.of(context).colorScheme;
    final bubbleBorderRadius = BorderRadius.circular(18).copyWith(
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

    if (!hasVisibleContent && !hasVisibleError) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: _BubbleTouchHoldLayer(
            borderRadius: bubbleBorderRadius,
            flashColor: colorScheme.primary.withValues(alpha: 0.16),
            onLongPress: onBackgroundLongPress,
            onLongPressRelease: onBackgroundLongPressEnd,
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
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onDoubleTap: () {
                        final copyText = _composeMessageCopyText(message);
                        if (copyText.isNotEmpty) {
                          _copyTextToClipboard(context, copyText);
                        }
                      },
                    ),
                  ),
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
                          children: [
                            ...message.parts.map(
                              (part) => _buildMessagePart(
                                context,
                                part,
                                latestReasoningPartId: latestReasoningPartId,
                                activeReasoningPartKey: activeReasoningPartKey,
                              ),
                            ),
                          ],
                        )
                      else
                        SelectionArea(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...message.parts.map(
                                (part) => _buildMessagePart(
                                  context,
                                  part,
                                  latestReasoningPartId: latestReasoningPartId,
                                  activeReasoningPartKey:
                                      activeReasoningPartKey,
                                ),
                              ),
                            ],
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
        Icons.info_outline,
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
        return _buildToolPart(context, part as ToolPart);
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

  Widget _buildTextPart(BuildContext context, TextPart part) {
    // Don't display if text is empty or only whitespace
    if (part.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Render text using Markdown
          MarkdownBody(
            data: part.text,
            styleSheet: MarkdownStyleSheet(
              p: Theme.of(context).textTheme.bodyMedium,
              code: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
              codeblockDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onTapLink: (text, href, title) {
              if (href != null) {
                // TODO: Implement link navigation
              }
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

  Widget _buildFilePart(BuildContext context, FilePart part) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (part.source?.path != null)
                  Text(
                    part.source!.path,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Implement file download or view
            },
            icon: const Icon(Icons.download),
            tooltip: 'Download File',
          ),
        ],
      ),
    );
  }

  _ToolPresentation _toolPresentation(String rawToolName) {
    final normalized = _normalizeToolName(rawToolName);
    switch (normalized) {
      case 'bash':
      case 'shell':
        return _ToolPresentation(
          title: 'Running command',
          subtitle: rawToolName,
          icon: Icons.terminal_rounded,
        );
      case 'read':
        return _ToolPresentation(
          title: 'Reading file',
          subtitle: rawToolName,
          icon: Icons.description_outlined,
        );
      case 'write':
        return _ToolPresentation(
          title: 'Writing file',
          subtitle: rawToolName,
          icon: Icons.edit_note_rounded,
        );
      case 'edit':
      case 'apply_patch':
      case 'patch':
        return _ToolPresentation(
          title: 'Editing files',
          subtitle: rawToolName,
          icon: Icons.auto_fix_high_rounded,
        );
      case 'glob':
      case 'find':
        return _ToolPresentation(
          title: 'Finding files',
          subtitle: rawToolName,
          icon: Icons.folder_open_outlined,
        );
      case 'grep':
        return _ToolPresentation(
          title: 'Searching code',
          subtitle: rawToolName,
          icon: Icons.search_rounded,
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
          icon: Icons.travel_explore_rounded,
        );
      case 'question':
        return _ToolPresentation(
          title: 'Waiting for your input',
          subtitle: rawToolName,
          icon: Icons.help_outline_rounded,
        );
      case 'todowrite':
      case 'todoread':
        return _ToolPresentation(
          title: 'Updating task list',
          subtitle: rawToolName,
          icon: Icons.checklist_rounded,
        );
      default:
        return _ToolPresentation(
          title: 'Running ${_humanizeToolName(normalized)}',
          subtitle: rawToolName,
          icon: Icons.extension_outlined,
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
        borderRadius: BorderRadius.circular(8),
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
        borderRadius: BorderRadius.circular(8),
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
                Icons.psychology,
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
      icon: Icons.support_agent,
      title: 'Agent',
      subtitle: part.name,
    );
  }

  Widget _buildSnapshotPart(BuildContext context, SnapshotPart part) {
    return _buildInfoContainer(
      context,
      icon: Icons.camera_alt_outlined,
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
      icon: Icons.compare_arrows_outlined,
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
      icon: Icons.task_outlined,
      title: 'Subtask (${part.agent})',
      subtitle: '${part.description}$model',
    );
  }

  Widget _buildRetryPart(BuildContext context, RetryPart part) {
    return _buildInfoContainer(
      context,
      icon: Icons.refresh_outlined,
      title: 'Retry #${part.attempt}',
      subtitle: part.error.message,
    );
  }

  Widget _buildCompactionPart(BuildContext context, CompactionPart part) {
    return _buildInfoContainer(
      context,
      icon: Icons.compress_outlined,
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
        borderRadius: BorderRadius.circular(8),
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
        icon = Icons.schedule;
        break;
      case ToolStatus.running:
        color = colorScheme.primary;
        label = 'In progress';
        icon = Icons.play_arrow;
        break;
      case ToolStatus.completed:
        color = colorScheme.tertiary;
        label = 'Done';
        icon = Icons.check_circle_outline_rounded;
        break;
      case ToolStatus.error:
        color = colorScheme.error;
        label = 'Needs attention';
        icon = Icons.warning_amber_rounded;
        break;
    }

    if (!showLabel) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
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
                  borderRadius: BorderRadius.circular(4),
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
            borderRadius: BorderRadius.circular(4),
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
    return _CollapsibleToolContent(
      text: text,
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
          borderRadius: BorderRadius.circular(4),
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
        borderRadius: BorderRadius.circular(4),
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
      return command;
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
    return fallback.isEmpty ? null : fallback;
  }

  String _resolveToolOutput({
    required String toolName,
    required ToolStateCompleted state,
  }) {
    final output = state.output.trim();
    if (output.isNotEmpty) {
      return state.output;
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
      return directDiff;
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

  Widget _buildErrorInfo(BuildContext context, MessageError error) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
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
      return Icons.image;
    } else if (mime.startsWith('video/')) {
      return Icons.video_file;
    } else if (mime.startsWith('audio/')) {
      return Icons.audio_file;
    } else if (mime.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (mime.contains('text/')) {
      return Icons.text_snippet;
    } else {
      return Icons.insert_drive_file;
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
    required this.isLatestReasoningPart,
    this.textStyle,
  });

  final String partKey;
  final String text;
  final int collapsedMaxLines;
  final bool isLatestReasoningPart;
  final TextStyle? textStyle;

  @override
  State<_CollapsibleReasoningContent> createState() =>
      _CollapsibleReasoningContentState();
}

class _CollapsibleReasoningContentState
    extends State<_CollapsibleReasoningContent> {
  late bool _expanded;

  bool get _canExpand {
    if (widget.text.trim().isEmpty) {
      return false;
    }
    final lineCount = '\n'.allMatches(widget.text).length + 1;
    return lineCount > widget.collapsedMaxLines || widget.text.length > 160;
  }

  @override
  void initState() {
    super.initState();
    _expanded = widget.isLatestReasoningPart;
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
    if (!oldWidget.isLatestReasoningPart && widget.isLatestReasoningPart) {
      if (!_expanded) {
        setState(() {
          _expanded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      widget.text,
      key: ValueKey<String>('thinking_content_text_${widget.partKey}'),
      maxLines: _expanded ? null : widget.collapsedMaxLines,
      overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
      style: widget.textStyle,
    );
    if (!_canExpand) {
      return textWidget;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textWidget,
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: ValueKey<String>('thinking_content_toggle_${widget.partKey}'),
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
            child: Text(_expanded ? 'Show less' : 'Show more'),
          ),
        ),
      ],
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
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Color flashColor;
  final VoidCallback? onLongPress;
  final VoidCallback? onLongPressRelease;

  @override
  State<_BubbleTouchHoldLayer> createState() => _BubbleTouchHoldLayerState();
}

class _BubbleTouchHoldLayerState extends State<_BubbleTouchHoldLayer> {
  static const Duration _holdDelay = Duration(milliseconds: 260);
  static const Duration _flashDuration = Duration(milliseconds: 170);
  static const double _moveTolerance = 14;

  Timer? _holdTimer;
  Timer? _flashTimer;
  int? _activePointer;
  Offset? _pointerDownPosition;
  bool _longPressTriggered = false;
  bool _isFlashing = false;

  @override
  void dispose() {
    _holdTimer?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.onLongPress == null) {
      return;
    }
    _holdTimer?.cancel();
    _activePointer = event.pointer;
    _pointerDownPosition = event.localPosition;
    _longPressTriggered = false;
    _holdTimer = Timer(_holdDelay, _triggerLongPress);
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
      _cancelHold();
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
