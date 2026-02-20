part of '../chat_page.dart';

extension _ChatPageComposerWidgets on _ChatPageState {
  Widget _buildShortcutHint(String shortcut, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              shortcut,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineTodoCard(
    BuildContext context,
    ChatProvider chatProvider,
    SettingsProvider sp,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: SessionTodoListWidget(
            todos: chatProvider.currentSessionTodo,
            collapsed: sp.taskListCollapsed,
            onToggleCollapsed: () =>
                unawaited(sp.setTaskListCollapsed(!sp.taskListCollapsed)),
          ),
        ),
      ),
    );
  }

  void _queueComposerStatusSync(_ComposerStatusPresentation? target) {
    if (_composerStatusTargetInitialized &&
        _lastComposerStatusTarget == target) {
      return;
    }
    _composerStatusTargetInitialized = true;
    _lastComposerStatusTarget = target;
    _queuedComposerStatusTarget = target;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final queuedTarget = _queuedComposerStatusTarget;
      _queuedComposerStatusTarget = null;
      _applyComposerStatusTarget(queuedTarget);
    });
  }

  void _showComposerStopHint() {
    _composerStopHintTimer?.cancel();
    _setState(() {
      _priorityComposerStatus = const _ComposerStatusPresentation.stopHint();
    });
    _composerStopHintTimer = Timer(
      _ChatPageState._composerStopHintDuration,
      () {
        if (!mounted) {
          return;
        }
        _composerStopHintTimer = null;
        if (_priorityComposerStatus?.type != _ComposerStatusType.stopHint) {
          return;
        }
        _setState(() {
          _priorityComposerStatus = null;
        });
      },
    );
  }

  void _applyComposerStatusTarget(_ComposerStatusPresentation? target) {
    if (target == null) {
      _tipRotationTimer?.cancel();
      _tipRotationTimer = null;
      _composerStatusShowTimer?.cancel();
      _composerStatusShowTimer = null;
      _pendingComposerStatus = null;
      if (_visibleComposerStatus == null) {
        return;
      }
      if (_composerStatusHideTimer != null) {
        return;
      }
      _composerStatusHideTimer = Timer(
        _ChatPageState._composerStatusHideDelay,
        () {
          if (!mounted) {
            return;
          }
          _composerStatusHideTimer = null;
          if (_visibleComposerStatus == null) {
            return;
          }
          _setState(() {
            _visibleComposerStatus = null;
          });
        },
      );
      return;
    }

    _composerStatusHideTimer?.cancel();
    _composerStatusHideTimer = null;

    if (target.type == _ComposerStatusType.dynamicReasoning) {
      _tipRotationTimer?.cancel();
      _tipRotationTimer = null;
      _composerStatusShowTimer?.cancel();
      _composerStatusShowTimer = null;
      _pendingComposerStatus = null;
      if (_visibleComposerStatus == target) {
        return;
      }
      _setState(() {
        _visibleComposerStatus = target;
      });
      return;
    }

    if (target.type == _ComposerStatusType.tip && _tipRotationTimer == null) {
      _tipRotationTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (!mounted) {
          return;
        }
        final tips = _ComposerStatusPresentation._receivingTips;
        _currentTipIndex = (_currentTipIndex + 1) % tips.length;
        _setState(() {
          _visibleComposerStatus = _ComposerStatusPresentation.tip(
            tips[_currentTipIndex],
          );
        });
      });
    } else if (target.type != _ComposerStatusType.tip) {
      _tipRotationTimer?.cancel();
      _tipRotationTimer = null;
    }

    final shouldDebounceFallback =
        _visibleComposerStatus == null ||
        _visibleComposerStatus?.type == _ComposerStatusType.dynamicReasoning;

    if (shouldDebounceFallback) {
      if (_pendingComposerStatus == target &&
          _composerStatusShowTimer != null) {
        return;
      }
      _pendingComposerStatus = target;
      _composerStatusShowTimer?.cancel();
      _composerStatusShowTimer = Timer(
        _ChatPageState._composerStatusShowDelay,
        () {
          if (!mounted) {
            return;
          }
          final pendingStatus = _pendingComposerStatus;
          _composerStatusShowTimer = null;
          _pendingComposerStatus = null;
          if (pendingStatus == null) {
            return;
          }
          _setState(() {
            _visibleComposerStatus = pendingStatus;
          });
        },
      );
      return;
    }

    if (_visibleComposerStatus != null) {
      _composerStatusShowTimer?.cancel();
      _composerStatusShowTimer = null;
      _pendingComposerStatus = null;
      if (_visibleComposerStatus == target) {
        return;
      }
      _setState(() {
        _visibleComposerStatus = target;
      });
      return;
    }
  }

  Widget _buildComposerReasoningStatusSlot(
    _ComposerStatusPresentation? status,
  ) {
    return SizedBox(
      key: const ValueKey<String>('composer_reasoning_status_slot'),
      height: _ChatPageState._composerStatusReservedHeight,
      child: status == null
          ? const SizedBox.expand()
          : _buildComposerReasoningStatusLine(status),
    );
  }

  Widget _buildComposerReasoningStatusLine(_ComposerStatusPresentation status) {
    final colorScheme = Theme.of(context).colorScheme;
    final leading = switch (status.type) {
      _ComposerStatusType.thinking => SizedBox(
        key: const ValueKey<String>('composer_reasoning_status_spinner'),
        width: 16,
        height: 16,
        child: CircularProgressIndicator.adaptive(
          strokeWidth: 2.4,
          strokeCap: StrokeCap.round,
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        ),
      ),
      _ComposerStatusType.tip => Icon(
        Symbols.lightbulb_outline,
        key: const ValueKey<String>('composer_reasoning_status_icon_tip'),
        size: 15,
        color: colorScheme.primary,
      ),
      _ComposerStatusType.receiving ||
      _ComposerStatusType.dynamicReasoning => Icon(
        Symbols.auto_awesome,
        key: const ValueKey<String>('composer_reasoning_status_icon'),
        size: 15,
        color: colorScheme.primary,
      ),
      _ComposerStatusType.stopHint => const SizedBox.shrink(),
    };
    final textStyle = status.type == _ComposerStatusType.stopHint
        ? Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.error,
            fontWeight: FontWeight.w400,
          )
        : Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          key: const ValueKey<String>('composer_reasoning_status_line'),
          mainAxisSize: MainAxisSize.min,
          children: [
            KeyedSubtree(
              key: ValueKey<String>(
                'composer_reasoning_status_type_${status.type.name}',
              ),
              child: leading,
            ),
            if (status.type != _ComposerStatusType.stopHint)
              const SizedBox(width: 8),
            Flexible(
              child: _ComposerStatusLanternText(
                text: status.label,
                key: const ValueKey<String>('composer_reasoning_status_text'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _collectSentMessageHistory(List<ChatMessage> messages) {
    // Cache: skip O(N) filter when messages haven't changed.
    final lastId = messages.isNotEmpty ? messages.last.id : null;
    if (_cachedSentHistory != null &&
        messages.length == _cachedSentHistoryMsgCount &&
        lastId == _cachedSentHistoryLastMsgId) {
      return _cachedSentHistory!;
    }

    final history = <String>[];
    for (final message in messages) {
      if (message.role != MessageRole.user) {
        continue;
      }
      final text = message.parts
          .whereType<TextPart>()
          .map((part) => part.text)
          .join('\n')
          .trim();
      if (text.isEmpty) {
        continue;
      }
      history.add(text);
    }
    final result = List<String>.unmodifiable(history);
    _cachedSentHistoryMsgCount = messages.length;
    _cachedSentHistoryLastMsgId = lastId;
    _cachedSentHistory = result;
    return result;
  }

  String _extractUserMessageText(ChatMessage message) {
    return message.parts
        .whereType<TextPart>()
        .map((part) => part.text)
        .join('\n')
        .trim();
  }
}
