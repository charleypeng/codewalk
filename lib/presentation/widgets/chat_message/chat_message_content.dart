part of '../chat_message_widget.dart';

const _assistantBubbleMaxWidth = 760.0;
const _userBubbleMaxWidth = 640.0;
// 82% gives a natural messaging-app feel while leaving visible left margin.
const _userBubbleWidthFactor = 0.82;
const _userBubbleMinWidth = 220.0;

/// Top-level content builder: bubble layout, header, error display,
/// and touch/hold gesture layer.
extension _ChatMessageContentBuilder on _ChatMessageWidgetState {
  Widget _buildContent(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final colorScheme = Theme.of(context).colorScheme;
    final bubblePadding = isUser
        ? const EdgeInsets.fromLTRB(14, 10, 14, 12)
        : const EdgeInsets.fromLTRB(12, 8, 12, 10);
    final headerContentSpacing = _resolveHeaderContentSpacing(
      context,
      isUser: isUser,
    );
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : _assistantBubbleMaxWidth;
            final assistantMaxWidth = math.min(
              _assistantBubbleMaxWidth,
              availableWidth,
            );
            final userCandidateWidth = math.min(
              _userBubbleMaxWidth,
              availableWidth * _userBubbleWidthFactor,
            );
            final userMaxWidth = math.min(
              assistantMaxWidth,
              math.max(_userBubbleMinWidth, userCandidateWidth),
            );
            final bubbleMaxWidth = isUser ? userMaxWidth : assistantMaxWidth;

            final bubble = RepaintBoundary(
              key: _shareImageKey,
              child: ConstrainedBox(
                key: ValueKey<String>('message_bubble_${message.id}'),
                constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
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
                  child: Semantics(
                    label: isUser ? 'Your message' : 'Assistant message',
                    child: Container(
                      padding: bubblePadding,
                      decoration: BoxDecoration(
                        color: isUser
                            ? colorScheme.primaryContainer.withValues(
                                alpha: 0.45,
                              )
                            : colorScheme.surfaceContainerHigh,
                        borderRadius: bubbleBorderRadius,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isUser) ...[
                                Text(
                                  'You',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                _formatTime(message.time),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                              ),
                              const Spacer(),
                              _buildShareImageButton(context),
                              if (!isUser &&
                                  message is AssistantMessage) ...[
                                _buildReadAloudButton(
                                  context,
                                  message as AssistantMessage,
                                ),
                                const SizedBox(width: 8),
                                _buildAssistantInfo(
                                  context,
                                  message as AssistantMessage,
                                ),
                              ],
                            ],
                          ),
                          SizedBox(
                            key: ValueKey<String>(
                              'message_header_spacing_${message.id}',
                            ),
                            height: headerContentSpacing,
                          ),
                          if (isUser)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: renderedParts,
                            )
                          else
                            SelectionArea(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                    ),
                  ),
                ),
              ),
            );

            if (!isUser) {
              return bubble;
            }

            if (showInlineUndoAction) {
              // Keep the undo control tied to the latest user turn while
              // leaving the bubble header free for message metadata and content.
              return Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Tooltip(
                    message: context.l10n.msgInfoUndoThisTurn,
                    child: IconButton(
                      key: ValueKey<String>(
                        'chat_message_undo_button_${message.id}',
                      ),
                      icon: const Icon(Symbols.undo_rounded),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      splashRadius: 18,
                      tooltip: context.l10n.msgInfoUndoThisTurn,
                      onPressed: onInlineUndo,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(fit: FlexFit.loose, child: bubble),
                ],
              );
            }

            if (onInlineRevertToHere != null) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Tooltip(
                    message: 'Rewind and edit from here',
                    child: IconButton(
                      key: ValueKey<String>(
                        'chat_message_revert_button_${message.id}',
                      ),
                      icon: const Icon(Symbols.settings_backup_restore),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      splashRadius: 18,
                      tooltip: 'Rewind and edit from here',
                      onPressed: onInlineRevertToHere,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(fit: FlexFit.loose, child: bubble),
                ],
              );
            }

            return bubble;
          },
        ),
      ),
    );
  }

  double _resolveHeaderContentSpacing(
    BuildContext context, {
    required bool isUser,
  }) {
    final density = Theme.of(context).visualDensity.vertical;
    final baseSpacing = isUser ? 8.0 : 4.0;
    return (baseSpacing + density).clamp(2.0, 12.0);
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
    if (part is ReasoningPart) {
      if (!showThinkingBubbles || shouldSuppressLiveReasoningPart(part)) {
        return false;
      }
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

  Widget _buildShareImageButton(BuildContext context) {
    if (_hideShareImageButtonForCapture) {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: context.l10n.msgShareAsImage,
      child: IconButton(
        key: ValueKey<String>('chat_message_share_image_button_${message.id}'),
        icon: const Icon(Symbols.share, size: 18),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        splashRadius: 18,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        tooltip: context.l10n.msgShareAsImage,
        onPressed: () => _onShareAsImage(context),
      ),
    );
  }

  Future<void> _onShareAsImage(BuildContext context) async {
    if (_hideShareImageButtonForCapture) return;

    setState(() {
      _hideShareImageButtonForCapture = true;
      _localUiStateVersion += 1;
    });

    var result = MessageImageExportResult.failed;
    try {
      // Rebuild without the share action before capturing so exported images
      // contain only message content, not the control used to create them.
      await WidgetsBinding.instance.endOfFrame;
      result = await MessageImageExportService.captureAndShare(
        boundaryKey: _shareImageKey,
        subject: context.l10n.msgShareAsImageSubject,
      );
    } finally {
      if (mounted) {
        setState(() {
          _hideShareImageButtonForCapture = false;
          _localUiStateVersion += 1;
        });
      }
    }

    if (!context.mounted) return;

    switch (result) {
      case MessageImageExportResult.shared:
        // Success — share sheet was invoked, nothing else to do.
        break;
      case MessageImageExportResult.tooTall:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.msgShareAsImageTooTall),
            duration: const Duration(seconds: 3),
          ),
        );
        break;
      case MessageImageExportResult.notLaidOut:
      case MessageImageExportResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.msgShareAsImageFailed),
            duration: const Duration(seconds: 3),
          ),
        );
        break;
    }
  }

  Widget _buildReadAloudButton(BuildContext context, AssistantMessage message) {
    if (!di.sl.isRegistered<ReadAloudService>()) {
      return const SizedBox.shrink();
    }

    final readAloudService = di.sl<ReadAloudService>();

    return ListenableBuilder(
      listenable: readAloudService,
      builder: (context, _) {
        // Check settings inside builder so the button hides/reacts when the
        // user toggles readAloudEnabled without a full ChatMessage rebuild.
        final settingsProvider = context.read<SettingsProvider>();
        if (!settingsProvider.readAloudEnabled) {
          return const SizedBox.shrink();
        }

        // Evaluate state inside builder so icon/color/onPressed react to
        // ReadAloudService notifications.
        final isActive = readAloudService.activeMessageId == message.id;
        final isPlaying = isActive && readAloudService.isSpeaking;
        final icon = isPlaying ? Symbols.stop : Symbols.volume_up;
        final tooltip = isPlaying
            ? context.l10n.msgStopReadAloud
            : context.l10n.msgReadAloud;

        return IconButton(
          icon: Icon(icon, size: 18),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          splashRadius: 18,
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
          tooltip: tooltip,
          onPressed: () {
            // Guard: respect the current setting even if the button was
            // rendered before the user toggled readAloudEnabled off.
            if (!settingsProvider.readAloudEnabled) {
              return;
            }
            if (isPlaying) {
              unawaited(readAloudService.stop());
              return;
            }
            final text = _extractReadableText(message);
            if (text.isEmpty) {
              return;
            }
            unawaited(
              readAloudService.speak(
                messageId: message.id,
                text: text,
                rate: settingsProvider.readAloudRate,
                pitch: settingsProvider.readAloudPitch,
                voice: settingsProvider.readAloudVoice,
              ),
            );
          },
        );
      },
    );
  }

  // Strips basic Markdown syntax so TTS reads natural text, not raw
  // formatting characters. Handles bold (**/__), italic (*/_), inline code
  // (`), links [...](...), images ![..](..), headings (#), and blockquotes (>).
  static final RegExp _ttsStrippingRegExp = RegExp(
    r'(\*\*|__)(.*?)\1|'
    r'(\*|_)(.*?)\3|'
    r'`([^`]*)`|'
    r'!?\[([^\]]*)\]\([^)]*\)|'
    r'^#{1,6}\s*|'
    r'^>\s*',
    multiLine: true,
  );

  String _extractReadableText(AssistantMessage message) {
    final buffer = StringBuffer();
    for (final part in message.parts) {
      if (part is TextPart && part.text.trim().isNotEmpty) {
        // Strip markdown formatting before feeding to TTS.
        // Dart replaceAll does not interpolate capture groups in the
        // replacement string — use replaceAllMapped instead.
        final cleaned = part.text.replaceAllMapped(
          _ttsStrippingRegExp,
          (m) => m.group(2) ?? m.group(4) ?? m.group(5) ?? m.group(6) ?? '',
        );
        buffer.write(cleaned);
        buffer.write(' ');
      }
    }
    return buffer.toString().trim();
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
      tooltip: context.l10n.msgInfoMessageInfo,
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
