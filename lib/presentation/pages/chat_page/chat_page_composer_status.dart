part of '../chat_page.dart';

extension _ChatPageComposerStatus on _ChatPageState {
  void _scheduleCompactionStateSync({
    required bool wasCompactingContext,
    required String? frozenCompactionBoundaryId,
  }) {
    if (_wasCompactingContext == wasCompactingContext &&
        _frozenCompactionBoundaryId == frozenCompactionBoundaryId) {
      return;
    }

    _nextWasCompactingContext = wasCompactingContext;
    _nextFrozenCompactionBoundaryId = frozenCompactionBoundaryId;
    if (_compactionStateSyncScheduled) {
      return;
    }

    _compactionStateSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _compactionStateSyncScheduled = false;
      if (!mounted) {
        return;
      }
      if (_wasCompactingContext == _nextWasCompactingContext &&
          _frozenCompactionBoundaryId == _nextFrozenCompactionBoundaryId) {
        return;
      }
      _setState(() {
        _wasCompactingContext = _nextWasCompactingContext;
        _frozenCompactionBoundaryId = _nextFrozenCompactionBoundaryId;
      });
    });
  }

  _ComposerStatusPresentation? _resolveComposerStatusTarget(
    ChatProvider chatProvider,
  ) {
    final latestMessage = chatProvider.messages.isEmpty
        ? null
        : chatProvider.messages.last;
    if (latestMessage is AssistantMessage && latestMessage.isCompleted) {
      return null;
    }

    final progressStage = _resolveAssistantProgressStage(chatProvider);
    if (progressStage == null) {
      return null;
    }

    final reasoningStatusLabel = _resolveLatestReasoningStatusLabel(
      chatProvider.messages,
    );
    if (reasoningStatusLabel != null) {
      return _ComposerStatusPresentation.dynamicReasoning(reasoningStatusLabel);
    }

    // Both thinking and receiving stages show the same visual output:
    // - Tips enabled: rotating tips with lightbulb icon
    // - Tips disabled: static "Reasoning..." fallback
    // Internally they remain separate stages so the progress detection
    // logic is preserved, but visually the user sees no transition.
    return switch (progressStage) {
      _AssistantProgressStage.receiving || _AssistantProgressStage.thinking =>
        context.read<SettingsProvider>().showComposerTips
            ? _ComposerStatusPresentation.tip(
                _ComposerStatusPresentation._receivingTips[_currentTipIndex],
              )
            : const _ComposerStatusPresentation.receiving(),
      _AssistantProgressStage.retrying => null,
    };
  }
}
