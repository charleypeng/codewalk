import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_shapes.dart';
import '../theme/app_animations.dart';
import 'message_entrance_animation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/entities/chat_message.dart';
import '../services/file_part_action_service.dart' as file_part_action;
import '../utils/chat_abort_message.dart';
import '../utils/diff_parser.dart';
import '../utils/reasoning_status_parser.dart';

part 'chat_message/chat_message_content.dart';
part 'chat_message/chat_message_part_dispatch.dart';
part 'chat_message/chat_message_text_part.dart';
part 'chat_message/chat_message_file_part.dart';
part 'chat_message/chat_message_tool_helpers.dart';
part 'chat_message/chat_message_tool_part.dart';
part 'chat_message/chat_message_info_parts.dart';

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
    this.isQueuedUserMessage = false,
    this.onBackgroundLongPress,
    this.onBackgroundLongPressEnd,
    this.onSubtaskNavigate,
    this.onTaskToolNavigate,
  });

  final ChatMessage message;
  final String? activeReasoningPartKey;
  final bool showThinkingBubbles;
  final bool showToolCallBubbles;
  final bool isSessionActivelyResponding;
  final bool isQueuedUserMessage;
  final VoidCallback? onBackgroundLongPress;
  final VoidCallback? onBackgroundLongPressEnd;
  final ValueChanged<SubtaskPart>? onSubtaskNavigate;
  final ValueChanged<ToolPart>? onTaskToolNavigate;

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
  static final RegExp _whitespaceRegExp = RegExp(r'\s+');

  // Snapshot of the last build inputs to skip redundant rebuilds.
  // Completed messages can skip rebuild when no visible prop changed.
  int _lastPartCount = -1;
  int _lastMessageHash = 0;
  String? _lastPartId;
  String? _lastReasoningKey;
  bool _lastShowThinking = true;
  bool _lastShowToolCalls = true;
  bool _lastResponding = false;
  bool _lastQueued = false;
  int _lastLocalUiStateVersion = 0;
  ValueChanged<SubtaskPart>? _lastSubtaskNavigate;
  ValueChanged<ToolPart>? _lastTaskToolNavigate;
  double _lastVisualDensityVertical = 0;
  double _lastVisualDensityHorizontal = 0;
  final Set<String> _seenPartIds = <String>{};
  final Set<String> _newlyArrivedPartIds = <String>{};
  final Map<String, Timer> _partAnimationTimers = <String, Timer>{};
  final Map<String, String> _stableIdentityByPartKey = <String, String>{};
  final Map<String, String> _stableIdentityByCallKey = <String, String>{};
  final Map<String, String> _stableIdentityByHashKey = <String, String>{};
  final Map<String, bool> _toolChainExpandedById = <String, bool>{};
  final Map<String, bool> _toolDetailsExpandedById = <String, bool>{};
  int _stableIdentitySequence = 0;
  int _localUiStateVersion = 0;

  String _nextStableIdentity(String prefix) {
    _stableIdentitySequence += 1;
    return '$prefix:$_stableIdentitySequence';
  }

  String _stableToolIdentity({
    required String partId,
    required String callId,
  }) {
    final partKey = 'tool:part:$partId';
    final normalizedCallId = callId.trim();

    if (normalizedCallId.isNotEmpty) {
      final callKey = 'tool:call:$normalizedCallId';
      final existing =
          _stableIdentityByCallKey[callKey] ?? _stableIdentityByPartKey[partKey];
      if (existing != null) {
        _stableIdentityByPartKey[partKey] = existing;
        _stableIdentityByCallKey[callKey] = existing;
        return existing;
      }

      final created = _nextStableIdentity('tool');
      _stableIdentityByPartKey[partKey] = created;
      _stableIdentityByCallKey[callKey] = created;
      return created;
    }

    return _stableIdentityByPartKey.putIfAbsent(
      partKey,
      () => _nextStableIdentity('tool'),
    );
  }

  String _stablePatchIdentity({
    required String partId,
    required String hash,
  }) {
    final partKey = 'patch:part:$partId';
    final normalizedHash = hash.trim();

    if (normalizedHash.isNotEmpty) {
      final hashKey = 'patch:hash:$normalizedHash';
      final existing =
          _stableIdentityByHashKey[hashKey] ?? _stableIdentityByPartKey[partKey];
      if (existing != null) {
        _stableIdentityByPartKey[partKey] = existing;
        _stableIdentityByHashKey[hashKey] = existing;
        return existing;
      }

      final created = _nextStableIdentity('patch');
      _stableIdentityByPartKey[partKey] = created;
      _stableIdentityByHashKey[hashKey] = created;
      return created;
    }

    return _stableIdentityByPartKey.putIfAbsent(
      partKey,
      () => _nextStableIdentity('patch'),
    );
  }

  String _partIdentityToken(MessagePart part) {
    if (part case ToolPart(:final callId, :final id)) {
      return _stableToolIdentity(partId: id, callId: callId);
    }
    if (part case PatchPart(:final hash, :final id)) {
      return _stablePatchIdentity(partId: id, hash: hash);
    }
    return '${part.type.name}:${part.id}';
  }

  @override
  void initState() {
    super.initState();
    _seedPartAnimationBaseline(widget.message);
  }

  @override
  void didUpdateWidget(covariant ChatMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshPartAnimationState(oldWidget.message, widget.message);
  }

  @override
  void dispose() {
    for (final timer in _partAnimationTimers.values) {
      timer.cancel();
    }
    _partAnimationTimers.clear();
    super.dispose();
  }

  /// Whether the current rebuild can be skipped (inputs unchanged).
  bool _canSkipRebuild() {
    final msg = widget.message;
    final isCompleted = msg is AssistantMessage && msg.isCompleted;
    if (!isCompleted) return false;

    final partCount = msg.parts.length;
    final lastPartId = msg.parts.isNotEmpty ? msg.parts.last.id : null;
    final density = Theme.of(context).visualDensity;
    return msg.hashCode == _lastMessageHash &&
        partCount == _lastPartCount &&
        lastPartId == _lastPartId &&
        widget.activeReasoningPartKey == _lastReasoningKey &&
        widget.showThinkingBubbles == _lastShowThinking &&
        widget.showToolCallBubbles == _lastShowToolCalls &&
        widget.isSessionActivelyResponding == _lastResponding &&
        widget.isQueuedUserMessage == _lastQueued &&
        _localUiStateVersion == _lastLocalUiStateVersion &&
        identical(widget.onSubtaskNavigate, _lastSubtaskNavigate) &&
        identical(widget.onTaskToolNavigate, _lastTaskToolNavigate) &&
        density.vertical == _lastVisualDensityVertical &&
        density.horizontal == _lastVisualDensityHorizontal;
  }

  void _updateBuildSnapshot(BuildContext context) {
    final msg = widget.message;
    final density = Theme.of(context).visualDensity;
    _lastMessageHash = msg.hashCode;
    _lastPartCount = msg.parts.length;
    _lastPartId = msg.parts.isNotEmpty ? msg.parts.last.id : null;
    _lastReasoningKey = widget.activeReasoningPartKey;
    _lastShowThinking = widget.showThinkingBubbles;
    _lastShowToolCalls = widget.showToolCallBubbles;
    _lastResponding = widget.isSessionActivelyResponding;
    _lastQueued = widget.isQueuedUserMessage;
    _lastLocalUiStateVersion = _localUiStateVersion;
    _lastSubtaskNavigate = widget.onSubtaskNavigate;
    _lastTaskToolNavigate = widget.onTaskToolNavigate;
    _lastVisualDensityVertical = density.vertical;
    _lastVisualDensityHorizontal = density.horizontal;
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
    _updateBuildSnapshot(context);
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
  bool get isQueuedUserMessage => widget.isQueuedUserMessage;
  VoidCallback? get onBackgroundLongPress => widget.onBackgroundLongPress;
  VoidCallback? get onBackgroundLongPressEnd => widget.onBackgroundLongPressEnd;
  ValueChanged<SubtaskPart>? get onSubtaskNavigate => widget.onSubtaskNavigate;
  ValueChanged<ToolPart>? get onTaskToolNavigate => widget.onTaskToolNavigate;

  void _seedPartAnimationBaseline(ChatMessage currentMessage) {
    for (final timer in _partAnimationTimers.values) {
      timer.cancel();
    }
    _partAnimationTimers.clear();
    _stableIdentityByPartKey.clear();
    _stableIdentityByCallKey.clear();
    _stableIdentityByHashKey.clear();
    _toolChainExpandedById.clear();
    _toolDetailsExpandedById.clear();
    _stableIdentitySequence = 0;
    _localUiStateVersion = 0;
    _seenPartIds
      ..clear()
      ..addAll(currentMessage.parts.map(_partIdentityToken));
    _newlyArrivedPartIds.clear();
  }

  void _refreshPartAnimationState(
    ChatMessage previousMessage,
    ChatMessage currentMessage,
  ) {
    if (previousMessage.id != currentMessage.id) {
      _seedPartAnimationBaseline(currentMessage);
      return;
    }

    final currentPartIds = currentMessage.parts.map(_partIdentityToken).toSet();
    for (final partId in currentPartIds.where(
      (partId) => !_seenPartIds.contains(partId),
    )) {
      _markPartForEntranceAnimation(partId);
    }
    for (final partId
        in _newlyArrivedPartIds
            .where((partId) => !currentPartIds.contains(partId))
            .toList(growable: false)) {
      _partAnimationTimers.remove(partId)?.cancel();
      _newlyArrivedPartIds.remove(partId);
    }
    _seenPartIds
      ..clear()
      ..addAll(currentPartIds);
  }

  void _markPartForEntranceAnimation(String partId) {
    if (_newlyArrivedPartIds.contains(partId)) {
      return;
    }
    _newlyArrivedPartIds.add(partId);
    _partAnimationTimers[partId]?.cancel();
    _partAnimationTimers[partId] = Timer(
      AppAnimations.messagePart + AppAnimations.fast,
      () {
        _partAnimationTimers.remove(partId);
        if (!mounted) {
          return;
        }
        if (_newlyArrivedPartIds.remove(partId)) {
          setState(() {});
        }
      },
    );
  }

  bool _shouldAnimatePartArrival(MessagePart part) {
    return _newlyArrivedPartIds.contains(_partIdentityToken(part));
  }

  bool _isToolDetailsExpanded(String toolIdentityToken) {
    return _toolDetailsExpandedById[toolIdentityToken] ?? false;
  }

  void _setToolDetailsExpanded(String toolIdentityToken, bool expanded) {
    final previous = _toolDetailsExpandedById[toolIdentityToken];
    if (previous == expanded) {
      return;
    }
    setState(() {
      _toolDetailsExpandedById[toolIdentityToken] = expanded;
      _localUiStateVersion += 1;
    });
  }

  bool _resolveToolChainExpanded(
    String chainIdentityToken,
    List<MessagePart> parts,
  ) {
    final explicit = _toolChainExpandedById[chainIdentityToken];
    if (explicit != null) {
      return explicit;
    }
    for (final toolPart in parts.whereType<ToolPart>()) {
      if (_isToolDetailsExpanded(_partIdentityToken(toolPart))) {
        return true;
      }
    }
    return false;
  }

  void _setToolChainExpanded(String chainIdentityToken, bool expanded) {
    final previous = _toolChainExpandedById[chainIdentityToken];
    if (previous == expanded) {
      return;
    }
    setState(() {
      _toolChainExpandedById[chainIdentityToken] = expanded;
      _localUiStateVersion += 1;
    });
  }

  // -- Shared utilities used by 3+ part clusters --

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

  Widget _buildErrorInfo(BuildContext context, MessageError error) {
    final isInlineAbortError = isAbortLikeError(
      name: error.name,
      message: error.message,
    );
    final displayMessage = normalizeAbortMessageForDisplay(
      error.message,
      name: error.name,
    );
    final title = isInlineAbortError ? null : error.name;

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
                if (title != null)
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                Text(
                  displayMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: isInlineAbortError
                        ? FontWeight.w600
                        : FontWeight.normal,
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
}
