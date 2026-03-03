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
import 'package:url_launcher/url_launcher.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/entities/chat_message.dart';
import '../services/file_part_action_service.dart' as file_part_action;
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
  bool _lastHasSubtaskNavigate = false;
  bool _lastHasTaskToolNavigate = false;
  double _lastVisualDensityVertical = 0;
  double _lastVisualDensityHorizontal = 0;

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
        (widget.onSubtaskNavigate != null) == _lastHasSubtaskNavigate &&
        (widget.onTaskToolNavigate != null) == _lastHasTaskToolNavigate &&
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
    _lastHasSubtaskNavigate = widget.onSubtaskNavigate != null;
    _lastHasTaskToolNavigate = widget.onTaskToolNavigate != null;
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
    final normalizedErrorName = error.name.trim().toLowerCase();
    final isInlineAbortError =
        normalizedErrorName.contains('abort') ||
        normalizedErrorName.contains('cancel');
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
                  error.message,
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
