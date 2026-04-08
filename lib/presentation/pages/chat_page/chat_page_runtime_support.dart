part of '../chat_page.dart';

extension _ChatPageRuntimeSupport on _ChatPageState {
  bool _isChatScreenActive() {
    if (!mounted || !_isAppInForeground) {
      return false;
    }
    final route = ModalRoute.of(context);
    if (route == null) {
      return true;
    }
    return route.isCurrent;
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) {
      return true;
    }
    return _distanceToBottom() <= _ChatPageState._nearBottomThreshold;
  }

  double _distanceToBottom() {
    if (!_scrollController.hasClients) {
      return 0;
    }
    final position = _scrollController.position;
    final distance = position.maxScrollExtent - position.pixels;
    if (distance < 0) {
      return 0;
    }
    return distance;
  }

  bool _canContinueScrollToBottomRequest(int requestToken) {
    return mounted &&
        _scrollController.hasClients &&
        requestToken == _scrollToBottomRequestToken;
  }

  bool _shouldShowJumpToFirstFab() {
    if (!_scrollController.hasClients) {
      return false;
    }
    final position = _scrollController.position;
    if (position.pixels <= _ChatPageState._nearBottomThreshold) {
      return false;
    }
    return _distanceToBottom() >= _ChatPageState._jumpToFirstFabThreshold;
  }

  bool _handleScrollMetricsChanged(ScrollMetricsNotification notification) {
    if (!_scrollController.hasClients) {
      return false;
    }
    final currentMax = _scrollController.position.maxScrollExtent;
    final contentShrank = currentMax < _lastKnownMaxScrollExtent;
    final chatProvider = _chatProvider;
    final hasActiveViewportOwner =
        _deferAssistantWorkCollapse ||
        _responseSettleFramesRemaining > 0 ||
        (chatProvider?.isCurrentSessionActivelyResponding ?? false);
    final hasScrollOwner =
        _currentScrollOwner != _ScrollOwner.none &&
        _currentScrollOwner != _ScrollOwner.contentShrinkSnap;
    if (_autoFollowToLatest &&
        !_isProgrammaticScrollInFlight &&
        !_isReturnRevealInFlight &&
        !_olderMessagesAnchorRestoreInFlight &&
        !_suppressPostCompletionAutoSnap &&
        !hasActiveViewportOwner &&
        !hasScrollOwner &&
        contentShrank &&
        _isNearBottom()) {
      final gap = _distanceToBottom();
      if (gap > _ChatPageState._scrollToBottomEpsilon) {
        _setScrollOwner(_ScrollOwner.contentShrinkSnap);
        _scrollController.jumpTo(currentMax);
        _setScrollOwner(_ScrollOwner.none);
      }
    }

    if (_currentScrollOwner == _ScrollOwner.userDrag) {
      _lastKnownMaxScrollExtent = currentMax;
      return false;
    }

    if (!_isProgrammaticScrollInFlight &&
        !_isReturnRevealInFlight &&
        !_olderMessagesAnchorRestoreInFlight &&
        _isNearBottom() &&
        (!_autoFollowToLatest ||
            _showScrollToLatestFab ||
            _hasUnreadMessagesBelow ||
            _showScrollToFirstFab)) {
      _setState(() {
        _autoFollowToLatest = true;
        _showScrollToLatestFab = false;
        _hasUnreadMessagesBelow = false;
        _showScrollToFirstFab = false;
      });
    }

    _lastKnownMaxScrollExtent = currentMax;
    return false;
  }

  void _beginResponseSettleWindow() {
    _responseSettleFramesRemaining = 2;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _drainResponseSettleWindow();
    });
  }

  void _drainResponseSettleWindow() {
    if (!mounted || _responseSettleFramesRemaining <= 0) {
      return;
    }
    _responseSettleFramesRemaining -= 1;
    if (_responseSettleFramesRemaining <= 0) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _drainResponseSettleWindow();
    });
  }

  void _consumePendingUiNotice(ChatProvider chatProvider) {
    final notice = chatProvider.consumePendingUiNotice();
    if (notice == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final hasRetryAction =
          notice.type == ChatUiNoticeType.remoteAbort && notice.hasAction;
      _showChatPageSnackBar(
        content: Text(notice.message),
        action: hasRetryAction
            ? SnackBarAction(
                label: notice.actionLabel!,
                onPressed: () {
                  unawaited(
                    chatProvider.refreshActiveSessionView(
                      reason: 'ui-notice-remote-abort-retry',
                    ),
                  );
                },
              )
            : null,
      );
    });
  }

  void _consumeRejectedDraft(ChatProvider chatProvider) {
    if (!_isChatScreenActive()) {
      return;
    }
    final currentSessionId = chatProvider.currentSession?.id;
    if (currentSessionId == null || currentSessionId.isEmpty) {
      return;
    }
    final rejectedDraft = chatProvider.consumeRejectedDraft(
      sessionId: currentSessionId,
    );
    if (rejectedDraft == null || !rejectedDraft.hasContent) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _chatInputController.hasDraftContent) {
        return;
      }
      _setState(() {
        _composerPrefilledDraft = rejectedDraft;
        _composerPrefilledDraftVersion += 1;
      });
      if (rejectedDraft.hasContent) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _inputFocusNode.requestFocus();
        });
      }
    });
  }

  void _consumePendingHistoryComposerSync(ChatProvider chatProvider) {
    if (!_isChatScreenActive()) {
      return;
    }
    final currentSessionId = chatProvider.currentSession?.id;
    if (currentSessionId == null || currentSessionId.isEmpty) {
      return;
    }
    final pending = chatProvider.consumePendingHistoryComposerSync(
      sessionId: currentSessionId,
    );
    if (pending == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (pending.clear) {
        _chatInputController.clearDraftWithoutFocus();
      }
      final draft = pending.draft;
      if (draft != null) {
        _setState(() {
          _composerPrefilledDraft = draft;
          _composerPrefilledDraftVersion += 1;
        });
      }
      if (draft != null && draft.hasContent) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _inputFocusNode.requestFocus();
        });
      }
    });
  }

  _AssistantWorkCompactionDecision _resolveAssistantWorkCompactionDecision({
    required List<ChatMessage> messages,
    required bool isResponding,
  }) {
    final settingsProvider = _settingsProvider;
    final showThinkingBubbles = settingsProvider?.showThinkingBubbles ?? true;
    final showToolCallBubbles = settingsProvider?.showToolCallBubbles ?? true;
    final latestRevealableAssistantMessageId =
        _resolveLatestRevealableAssistantMessageId(messages);
    final latestSettledAssistantWorkGroupId =
        _resolveLatestSettledAssistantWorkGroupId(
          messages: messages,
          showThinkingBubbles: showThinkingBubbles,
          showToolCallBubbles: showToolCallBubbles,
        );

    final decision = _AssistantWorkCompactionDecision(
      shouldDeferLatestCollapse: false,
      latestRevealableAssistantMessageId: latestRevealableAssistantMessageId,
      settledLatestAssistantWorkGroupId: latestSettledAssistantWorkGroupId,
    );

    if (!isResponding || decision.hasSettledLatestWorkGroup) {
      return decision;
    }

    return _AssistantWorkCompactionDecision(
      shouldDeferLatestCollapse: true,
      latestRevealableAssistantMessageId: latestRevealableAssistantMessageId,
      settledLatestAssistantWorkGroupId: latestSettledAssistantWorkGroupId,
    );
  }

  void _restoreSettledAssistantWorkOwnership(
    ChatProvider chatProvider, {
    required String reason,
  }) {
    final compactionDecision = _resolveAssistantWorkCompactionDecision(
      messages: chatProvider.messages,
      isResponding: chatProvider.isCurrentSessionActivelyResponding,
    );

    // Passive busy pulses can survive session switches. Rebuild settled
    // ownership from the visible turn first so return/revalidation does not
    // re-enter the active collapse path for an already finished group.
    _settledLatestAssistantWorkGroupId =
        compactionDecision.settledLatestAssistantWorkGroupId;
    _finalAssistantRevealSettledMessageId =
        compactionDecision.latestRevealableAssistantMessageId;
    _wasCurrentSessionActivelyResponding =
        chatProvider.isCurrentSessionActivelyResponding &&
        !compactionDecision.hasSettledLatestWorkGroup;

    _traceFinalUi(
      'restore-settled-assistant-work-ownership',
      details:
          'reason=$reason latestRevealableAssistantMessageId=${compactionDecision.latestRevealableAssistantMessageId ?? "-"} latestSettledAssistantWorkGroupId=${compactionDecision.settledLatestAssistantWorkGroupId ?? "-"} responding=${chatProvider.isCurrentSessionActivelyResponding}',
    );
  }

  _CachedViewportRestoreTarget _resolveCachedViewportRestoreTarget(
    ChatProvider chatProvider,
  ) {
    if (chatProvider.currentSession == null || chatProvider.messages.isEmpty) {
      return _CachedViewportRestoreTarget.none;
    }
    if (chatProvider.isCurrentSessionActivelyResponding) {
      return _CachedViewportRestoreTarget.bottom;
    }
    final latestRevealableAssistantMessageId =
        _resolveLatestRevealableAssistantMessageId(chatProvider.messages);
    if (latestRevealableAssistantMessageId == null ||
        latestRevealableAssistantMessageId.isEmpty) {
      return _CachedViewportRestoreTarget.bottom;
    }
    return _CachedViewportRestoreTarget.latestResponse;
  }

  void _queueCachedViewportRestore(
    ChatProvider chatProvider, {
    required String reason,
  }) {
    final sessionId = chatProvider.currentSession?.id;
    if (sessionId == null || sessionId.isEmpty) {
      _pendingInitialScrollSessionId = null;
      _pendingCachedViewportRestoreTarget = _CachedViewportRestoreTarget.none;
      return;
    }
    _pendingInitialScrollSessionId = sessionId;
    _pendingCachedViewportRestoreTarget = _resolveCachedViewportRestoreTarget(
      chatProvider,
    );
    _traceFinalUi(
      'queue-cached-viewport-restore',
      details:
          'reason=$reason target=${_pendingCachedViewportRestoreTarget.name} session=$sessionId',
    );
  }

  bool _consumeQueuedCachedViewportRestore(
    ChatProvider chatProvider, {
    required String reason,
  }) {
    final sessionId = chatProvider.currentSession?.id;
    if (sessionId == null ||
        sessionId.isEmpty ||
        _pendingInitialScrollSessionId != sessionId ||
        chatProvider.state == ChatState.loading ||
        chatProvider.messages.isEmpty) {
      return false;
    }

    final target = _pendingCachedViewportRestoreTarget;
    _pendingInitialScrollSessionId = null;
    _pendingCachedViewportRestoreTarget = _CachedViewportRestoreTarget.none;
    if (target == _CachedViewportRestoreTarget.none) {
      return false;
    }

    final signature = [
      sessionId,
      target.name,
      chatProvider.messages.length,
      chatProvider.messages.last.id,
      chatProvider.isCurrentSessionActivelyResponding,
    ].join('|');
    final now = DateTime.now();
    if (_lastConsumedCachedViewportRestoreAt != null &&
        _lastConsumedCachedViewportRestoreSignature == signature &&
        now.difference(_lastConsumedCachedViewportRestoreAt!) <
            const Duration(milliseconds: 400)) {
      _traceFinalUi(
        'cached-viewport-restore-skip-duplicate',
        details: 'reason=$reason signature=$signature',
      );
      return false;
    }
    _lastConsumedCachedViewportRestoreSignature = signature;
    _lastConsumedCachedViewportRestoreAt = now;

    _traceFinalUi(
      'consume-cached-viewport-restore',
      details: 'reason=$reason target=${target.name} signature=$signature',
    );
    switch (target) {
      case _CachedViewportRestoreTarget.none:
        return false;
      case _CachedViewportRestoreTarget.bottom:
        _scrollToBottom(force: true, animate: false);
        return true;
      case _CachedViewportRestoreTarget.latestResponse:
        _revealLatestMessageForCachedRestore(chatProvider, reason: reason);
        return true;
    }
  }

  void _scheduleQueuedDesktopViewportRestore(
    ChatProvider chatProvider, {
    required String reason,
  }) {
    if (_resumeRefreshViewportRestorePending) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_isChatScreenActive() ||
          _chatProvider?.currentSession?.id !=
              chatProvider.currentSession?.id) {
        return;
      }
      _consumeQueuedCachedViewportRestore(chatProvider, reason: reason);
    });
  }

  void _syncSessionScrollState(ChatProvider chatProvider) {
    final sessionId = chatProvider.currentSession?.id;
    if (sessionId != _trackedSessionId) {
      // Persist collapse state of the outgoing session before clearing.
      final outgoing = _trackedSessionId;
      if (outgoing != null) {
        _sessionCollapseHistoryCache[outgoing] =
            _expandedCollapsedHistoryGroupId;
        // Evict oldest entry when cache exceeds 20 sessions.
        if (_sessionCollapseHistoryCache.length > 20) {
          _sessionCollapseHistoryCache.remove(
            _sessionCollapseHistoryCache.keys.first,
          );
        }
      }
      _trackedSessionId = sessionId;
      if (sessionId != null) {
        unawaited(
          _notificationService?.clearNotificationsForSession(sessionId),
        );
      }
      _queueCachedViewportRestore(chatProvider, reason: 'session-switch');
      _olderMessagesLoadTriggerArmed = true;
      _setScrollOwner(_ScrollOwner.none);
      // Restore collapse state for the incoming session (null if not cached).
      _expandedCollapsedHistoryGroupId = sessionId != null
          ? _sessionCollapseHistoryCache[sessionId]
          : null;
      _expandedAssistantWorkGroupId = null;
      _frozenCompactionBoundaryId = null;
      _wasCompactingContext = false;
      _nextFrozenCompactionBoundaryId = null;
      _nextWasCompactingContext = false;
      _deferAssistantWorkCollapse = false;
      _suppressPostCompletionAutoSnap = false;
      _shouldRevealFinalAssistantOnCompletion = false;
      _manualScrollFollowPaused = false;
      _pendingFinalAssistantRevealMessageId = null;
      _restoreSettledAssistantWorkOwnership(
        chatProvider,
        reason: 'session-switch',
      );
      _finalAssistantRevealScheduled = false;
      _pendingFinalAssistantRevealAttempts = 0;
      _messageRevealAnchorKeysByMessageId.clear();
      if (!_autoFollowToLatest ||
          _showScrollToLatestFab ||
          _hasUnreadMessagesBelow ||
          _showScrollToFirstFab) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _setState(() {
            _autoFollowToLatest = true;
            _showScrollToLatestFab = false;
            _hasUnreadMessagesBelow = false;
            _showScrollToFirstFab = false;
          });
        });
      } else {
        _autoFollowToLatest = true;
        _showScrollToFirstFab = false;
        _manualScrollFollowPaused = false;
      }
    }

    if (sessionId == null) {
      _pendingInitialScrollSessionId = null;
      _pendingCachedViewportRestoreTarget = _CachedViewportRestoreTarget.none;
      _autoFollowToLatest = true;
      _showScrollToFirstFab = false;
      _expandedCollapsedHistoryGroupId = null;
      _expandedAssistantWorkGroupId = null;
      _frozenCompactionBoundaryId = null;
      _wasCompactingContext = false;
      _nextFrozenCompactionBoundaryId = null;
      _nextWasCompactingContext = false;
      _wasCurrentSessionActivelyResponding = false;
      _deferAssistantWorkCollapse = false;
      _suppressPostCompletionAutoSnap = false;
      _setScrollOwner(_ScrollOwner.none);
      _shouldRevealFinalAssistantOnCompletion = false;
      _pendingFinalAssistantRevealMessageId = null;
      _finalAssistantRevealSettledMessageId = null;
      _settledLatestAssistantWorkGroupId = null;
      _finalAssistantRevealScheduled = false;
      _pendingFinalAssistantRevealAttempts = 0;
      _messageRevealAnchorKeysByMessageId.clear();
      return;
    }

    if (_pendingInitialScrollSessionId == sessionId &&
        chatProvider.state != ChatState.loading) {
      _consumeQueuedCachedViewportRestore(
        chatProvider,
        reason: 'session-ready',
      );
    }
  }

  void _syncResponseViewportPolicy(ChatProvider chatProvider) {
    final sessionId = chatProvider.currentSession?.id;
    if (sessionId == null) {
      return;
    }

    final isResponding = chatProvider.isCurrentSessionActivelyResponding;
    final compactionDecision = _resolveAssistantWorkCompactionDecision(
      messages: chatProvider.messages,
      isResponding: isResponding,
    );
    final latestRevealableAssistantMessageId =
        compactionDecision.latestRevealableAssistantMessageId;
    final latestSettledAssistantWorkGroupId =
        compactionDecision.settledLatestAssistantWorkGroupId;
    final latestTimelineMessageId = chatProvider.messages.isEmpty
        ? null
        : chatProvider.messages.last.id;

    if (isResponding &&
        _pendingFinalAssistantRevealMessageId == null &&
        !compactionDecision.shouldDeferLatestCollapse &&
        (_settledLatestAssistantWorkGroupId == null ||
            _finalAssistantRevealSettledMessageId == null)) {
      _settledLatestAssistantWorkGroupId = latestSettledAssistantWorkGroupId;
      _finalAssistantRevealSettledMessageId =
          latestRevealableAssistantMessageId;
      _wasCurrentSessionActivelyResponding = false;
      _traceFinalUi(
        'viewport-policy-restore-settled-work-ownership',
        details:
            'latestRevealableAssistantMessageId=$latestRevealableAssistantMessageId latestSettledAssistantWorkGroupId=$latestSettledAssistantWorkGroupId',
      );
      return;
    }

    if (isResponding) {
      final hasSettledFinalMessage =
          _finalAssistantRevealSettledMessageId != null &&
          _finalAssistantRevealSettledMessageId!.isNotEmpty;
      final hasSettledLatestWorkGroup =
          compactionDecision.hasSettledLatestWorkGroup &&
          latestSettledAssistantWorkGroupId ==
              _settledLatestAssistantWorkGroupId;
      final shouldIgnoreTransientRespondingPulse =
          _pendingFinalAssistantRevealMessageId == null &&
          ((hasSettledFinalMessage &&
                  latestRevealableAssistantMessageId ==
                      _finalAssistantRevealSettledMessageId) ||
              hasSettledLatestWorkGroup);
      if (shouldIgnoreTransientRespondingPulse) {
        _traceFinalUi(
          'viewport-policy-ignore-transient-responding-pulse',
          details:
              'latestTimelineMessageId=${latestTimelineMessageId ?? "-"} latestRevealableAssistantMessageId=${latestRevealableAssistantMessageId ?? "-"} latestSettledAssistantWorkGroupId=${latestSettledAssistantWorkGroupId ?? "-"}',
        );
        return;
      }
      _traceFinalUi(
        'viewport-policy-responding',
        details:
            'latestTimelineMessageId=${latestTimelineMessageId ?? "-"} latestRevealableAssistantMessageId=${latestRevealableAssistantMessageId ?? "-"}',
      );
      _wasCurrentSessionActivelyResponding = true;
      _deferAssistantWorkCollapse =
          compactionDecision.shouldDeferLatestCollapse;
      _suppressPostCompletionAutoSnap = false;
      _shouldRevealFinalAssistantOnCompletion = _autoFollowToLatest;
      _pendingFinalAssistantRevealMessageId = null;
      _finalAssistantRevealSettledMessageId = null;
      _settledLatestAssistantWorkGroupId = null;
      _pendingFinalAssistantRevealAttempts = 0;
      return;
    }

    if (_wasCurrentSessionActivelyResponding) {
      _wasCurrentSessionActivelyResponding = false;
      _beginResponseSettleWindow();
      final shouldRevealFinalAssistant =
          _shouldRevealFinalAssistantOnCompletion && _autoFollowToLatest;
      _deferAssistantWorkCollapse = false;
      _suppressPostCompletionAutoSnap = shouldRevealFinalAssistant;
      _finalAssistantRevealSettledMessageId = null;
      _settledLatestAssistantWorkGroupId = latestSettledAssistantWorkGroupId;
      _pendingFinalAssistantRevealAttempts = 0;
      if (shouldRevealFinalAssistant) {
        _pendingFinalAssistantRevealMessageId =
            latestRevealableAssistantMessageId;
        _traceFinalUi(
          'viewport-policy-finished-schedule-final-reveal',
          details:
              'latestRevealableAssistantMessageId=${latestRevealableAssistantMessageId ?? "-"}',
        );
        _scheduleFinalAssistantReveal();
      } else {
        _traceFinalUi(
          'viewport-policy-finished-without-final-reveal',
          details:
              'latestRevealableAssistantMessageId=${latestRevealableAssistantMessageId ?? "-"}',
        );
        _pendingFinalAssistantRevealMessageId = null;
      }
      return;
    }

    if (_pendingFinalAssistantRevealMessageId != null) {
      _traceFinalUi(
        'viewport-policy-pending-final-reveal-reschedule',
        details: 'pending=${_pendingFinalAssistantRevealMessageId ?? "-"}',
      );
      _scheduleFinalAssistantReveal();
      return;
    }

    _settledLatestAssistantWorkGroupId =
        compactionDecision.settledLatestAssistantWorkGroupId;

    if (_shouldRevealFinalAssistantOnCompletion &&
        _suppressPostCompletionAutoSnap &&
        latestRevealableAssistantMessageId != null &&
        latestRevealableAssistantMessageId.isNotEmpty &&
        latestRevealableAssistantMessageId !=
            _finalAssistantRevealSettledMessageId) {
      _traceFinalUi(
        'viewport-policy-post-completion-resume-reveal',
        details:
            'latestRevealableAssistantMessageId=$latestRevealableAssistantMessageId settled=${_finalAssistantRevealSettledMessageId ?? "-"}',
      );
      _deferAssistantWorkCollapse = false;
      _pendingFinalAssistantRevealMessageId =
          latestRevealableAssistantMessageId;
      _pendingFinalAssistantRevealAttempts = 0;
      _scheduleFinalAssistantReveal();
    }
  }

  GlobalKey _messageRevealAnchorKey(String messageId) {
    return _messageRevealAnchorKeysByMessageId.putIfAbsent(
      messageId,
      () => GlobalKey(debugLabel: 'message_reveal_anchor_$messageId'),
    );
  }

  void _pruneMessageRevealAnchorKeys(List<ChatMessage> messages) {
    if (_messageRevealAnchorKeysByMessageId.isEmpty) {
      return;
    }
    final visibleMessageIds = messages.map((message) => message.id).toSet();
    _messageRevealAnchorKeysByMessageId.removeWhere(
      (messageId, _) => !visibleMessageIds.contains(messageId),
    );
  }

  void _revealLatestMessageForCachedRestore(
    ChatProvider chatProvider, {
    required String reason,
  }) {
    final sessionId = chatProvider.currentSession?.id;
    if (sessionId == null ||
        sessionId.isEmpty ||
        chatProvider.messages.isEmpty) {
      return;
    }

    final latestAssistantMessageId = _resolveLatestRevealableAssistantMessageId(
      chatProvider.messages,
    );
    if (latestAssistantMessageId == null || latestAssistantMessageId.isEmpty) {
      return;
    }
    _scrollToBottomRequestToken += 1;
    _scheduleLatestMessageReturnReveal(
      sessionId: sessionId,
      messageId: latestAssistantMessageId,
      reason: reason,
    );
  }

  void _scheduleLatestMessageReturnReveal({
    required String sessionId,
    required String messageId,
    required String reason,
    int attempt = 0,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        _runLatestMessageReturnReveal(
          sessionId: sessionId,
          messageId: messageId,
          reason: reason,
          attempt: attempt,
        ),
      );
    });
  }

  Future<void> _runLatestMessageReturnReveal({
    required String sessionId,
    required String messageId,
    required String reason,
    required int attempt,
  }) async {
    if (!mounted) {
      return;
    }

    final chatProvider = _chatProvider;
    if (chatProvider == null || chatProvider.currentSession?.id != sessionId) {
      return;
    }

    if (chatProvider.isCurrentSessionActivelyResponding) {
      _scrollToBottom(force: false);
      return;
    }

    if (chatProvider.messages.isEmpty) {
      return;
    }

    final latestRevealableAssistantMessageId =
        _resolveLatestRevealableAssistantMessageId(chatProvider.messages);
    if (latestRevealableAssistantMessageId == null ||
        latestRevealableAssistantMessageId.isEmpty) {
      return;
    }
    if (latestRevealableAssistantMessageId != messageId) {
      _scheduleLatestMessageReturnReveal(
        sessionId: sessionId,
        messageId: latestRevealableAssistantMessageId,
        reason: reason,
      );
      return;
    }

    if (!_scrollController.hasClients) {
      if (attempt + 1 < _ChatPageState._maxReturnLatestRevealAttempts) {
        _scheduleLatestMessageReturnReveal(
          sessionId: sessionId,
          messageId: messageId,
          reason: reason,
          attempt: attempt + 1,
        );
      }
      return;
    }

    final anchorContext =
        _messageRevealAnchorKeysByMessageId[messageId]?.currentContext;
    if (anchorContext == null) {
      if (attempt + 1 < _ChatPageState._maxReturnLatestRevealAttempts) {
        _scheduleLatestMessageReturnReveal(
          sessionId: sessionId,
          messageId: messageId,
          reason: reason,
          attempt: attempt + 1,
        );
      }
      return;
    }

    _setScrollOwner(_ScrollOwner.returnReveal);
    try {
      await Scrollable.ensureVisible(
        anchorContext,
        alignment: _ChatPageState._returnLatestRevealAlignment,
        duration: Duration.zero,
      );
    } catch (error, stackTrace) {
      AppLogger.debug(
        'Failed to reveal latest message after $reason for session=$sessionId message=$messageId',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        _setScrollOwner(_ScrollOwner.none);
      }
    }

    if (!mounted || _chatProvider?.currentSession?.id != sessionId) {
      return;
    }

    final shouldAutoFollow = _isNearBottom();
    final shouldShowLatestFab = !shouldAutoFollow;
    final shouldShowFirstFab =
        shouldShowLatestFab && _shouldShowJumpToFirstFab();
    if (_autoFollowToLatest == shouldAutoFollow &&
        _showScrollToLatestFab == shouldShowLatestFab &&
        !_hasUnreadMessagesBelow &&
        _showScrollToFirstFab == shouldShowFirstFab) {
      return;
    }

    _setState(() {
      _autoFollowToLatest = shouldAutoFollow;
      _showScrollToLatestFab = shouldShowLatestFab;
      _hasUnreadMessagesBelow = false;
      _showScrollToFirstFab = shouldShowFirstFab;
    });
  }

  void _scheduleFinalAssistantReveal() {
    final messageId = _pendingFinalAssistantRevealMessageId;
    if (_finalAssistantRevealScheduled) {
      _traceFinalUi('final-reveal-skip-already-scheduled');
      return;
    }
    if (messageId == null || messageId.isEmpty) {
      _traceFinalUi('final-reveal-skip-missing-message-id');
      return;
    }

    _finalAssistantRevealScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _finalAssistantRevealScheduled = false;
      if (!mounted ||
          !_shouldRevealFinalAssistantOnCompletion ||
          _pendingFinalAssistantRevealMessageId != messageId) {
        _traceFinalUi(
          'final-reveal-cancelled-before-run',
          details: 'messageId=$messageId',
        );
        return;
      }
      _traceFinalUi('final-reveal-run', details: 'messageId=$messageId');
      unawaited(_revealFinalAssistantMessageStart(messageId));
    });
  }

  Future<void> _revealFinalAssistantMessageStart(String messageId) async {
    if (!mounted ||
        !_shouldRevealFinalAssistantOnCompletion ||
        _pendingFinalAssistantRevealMessageId != messageId) {
      _traceFinalUi(
        'final-reveal-ignored-gate',
        details: 'messageId=$messageId',
      );
      return;
    }

    if (!_scrollController.hasClients) {
      _traceFinalUi(
        'final-reveal-no-scroll-clients',
        details:
            'messageId=$messageId attempt=$_pendingFinalAssistantRevealAttempts',
      );
      _pendingFinalAssistantRevealAttempts += 1;
      if (_pendingFinalAssistantRevealAttempts <
          _ChatPageState._maxFinalAssistantRevealAttempts) {
        _scheduleFinalAssistantReveal();
      } else {
        _finalizeFinalAssistantReveal(messageId);
      }
      return;
    }

    final anchorContext =
        _messageRevealAnchorKeysByMessageId[messageId]?.currentContext;
    if (anchorContext == null) {
      _traceFinalUi(
        'final-reveal-no-anchor',
        details:
            'messageId=$messageId attempt=$_pendingFinalAssistantRevealAttempts',
      );
      _pendingFinalAssistantRevealAttempts += 1;
      if (_pendingFinalAssistantRevealAttempts <
          _ChatPageState._maxFinalAssistantRevealAttempts) {
        _scheduleFinalAssistantReveal();
      } else {
        _finalizeFinalAssistantReveal(messageId);
      }
      return;
    }

    _isProgrammaticScrollInFlight = true;
    try {
      await Scrollable.ensureVisible(
        anchorContext,
        alignment: _ChatPageState._finalAssistantRevealAlignment,
        duration: _ChatPageState._finalAssistantRevealDuration,
        curve: Curves.easeOutCubic,
      );
    } catch (error, stackTrace) {
      AppLogger.debug(
        'Failed to reveal final assistant message id=$messageId',
        error: error,
        stackTrace: stackTrace,
      );
      _traceFinalUi(
        'final-reveal-scroll-error',
        details: 'messageId=$messageId error=${error.runtimeType}',
      );
    } finally {
      if (mounted) {
        _isProgrammaticScrollInFlight = false;
      }
    }

    if (!mounted || _pendingFinalAssistantRevealMessageId != messageId) {
      _traceFinalUi(
        'final-reveal-cancelled-after-scroll',
        details: 'messageId=$messageId',
      );
      return;
    }

    _finalizeFinalAssistantReveal(messageId);
  }

  void _finalizeFinalAssistantReveal(String messageId) {
    _traceFinalUi('final-reveal-finalize', details: 'messageId=$messageId');
    final shouldShowLatestFab =
        _scrollController.hasClients && !_isNearBottom();
    _setState(() {
      _autoFollowToLatest = false;
      _showScrollToLatestFab = shouldShowLatestFab;
      _hasUnreadMessagesBelow = false;
      _showScrollToFirstFab =
          shouldShowLatestFab && _shouldShowJumpToFirstFab();
      _deferAssistantWorkCollapse = false;
      _pendingFinalAssistantRevealMessageId = null;
      _finalAssistantRevealSettledMessageId = messageId;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_scrollController.hasClients ||
          !_shouldRevealFinalAssistantOnCompletion ||
          _finalAssistantRevealSettledMessageId != messageId ||
          _autoFollowToLatest) {
        return;
      }
      final anchorContext =
          _messageRevealAnchorKeysByMessageId[messageId]?.currentContext;
      if (anchorContext == null) {
        return;
      }
      unawaited(
        Scrollable.ensureVisible(
          anchorContext,
          alignment: _ChatPageState._finalAssistantRevealAlignment,
          duration: Duration.zero,
        ),
      );

      if (_isNearBottom() &&
          (!_autoFollowToLatest ||
              _showScrollToLatestFab ||
              _hasUnreadMessagesBelow ||
              _showScrollToFirstFab)) {
        _setState(() {
          _autoFollowToLatest = true;
          _showScrollToLatestFab = false;
          _hasUnreadMessagesBelow = false;
          _showScrollToFirstFab = false;
        });
      }
    });
  }

  void _prepareForOutgoingUserMessage() {
    _suppressPostCompletionAutoSnap = false;
    _deferAssistantWorkCollapse = true;
    _shouldRevealFinalAssistantOnCompletion = false;
    _manualScrollFollowPaused = false;
    _pendingFinalAssistantRevealMessageId = null;
    _finalAssistantRevealSettledMessageId = null;
    _settledLatestAssistantWorkGroupId = null;
    _pendingFinalAssistantRevealAttempts = 0;
    if (_autoFollowToLatest &&
        !_showScrollToLatestFab &&
        !_hasUnreadMessagesBelow &&
        !_showScrollToFirstFab) {
      return;
    }
    _setState(() {
      _autoFollowToLatest = true;
      _showScrollToLatestFab = false;
      _hasUnreadMessagesBelow = false;
      _showScrollToFirstFab = false;
    });
  }

  void _jumpToLatestAndResumeAutoFollow() {
    _suppressPostCompletionAutoSnap = false;
    _shouldRevealFinalAssistantOnCompletion = false;
    _pendingFinalAssistantRevealMessageId = null;
    _deferAssistantWorkCollapse = false;
    _manualScrollFollowPaused = false;
    _scrollToBottom(force: true);
  }

  void _markUnreadMessagesBelow() {
    if (!_autoFollowToLatest &&
        _showScrollToLatestFab &&
        _hasUnreadMessagesBelow &&
        _showScrollToFirstFab == _shouldShowJumpToFirstFab()) {
      return;
    }
    _setState(() {
      _autoFollowToLatest = false;
      _showScrollToLatestFab = true;
      _hasUnreadMessagesBelow = true;
      _showScrollToFirstFab = _shouldShowJumpToFirstFab();
    });
  }

  void _scrollToFirstMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _setScrollOwner(_ScrollOwner.newMessage);
      _scrollController
          .animateTo(
            _scrollController.position.minScrollExtent,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOut,
          )
          .whenComplete(() {
            if (!mounted) {
              return;
            }
            _setScrollOwner(_ScrollOwner.none);
            if (_showScrollToFirstFab) {
              _setState(() {
                _showScrollToFirstFab = false;
              });
            }
          });
    });
  }

  void _scrollToBottom({bool force = false, bool animate = true}) {
    if (!force &&
        (_currentScrollOwner == _ScrollOwner.newMessage ||
            _currentScrollOwner == _ScrollOwner.streaming)) {
      _traceFinalUi(
        'scroll-to-bottom-skipped-owner-already-following',
        details: 'owner=${_currentScrollOwner.name}',
      );
      return;
    }
    final requestToken = ++_scrollToBottomRequestToken;
    _traceFinalUi(
      'scroll-to-bottom-request',
      details:
          'requestToken=$requestToken force=$force animate=$animate owner=${_currentScrollOwner.name}',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        _runScrollToBottom(
          requestToken: requestToken,
          force: force,
          animate: animate,
        ),
      );
    });
  }

  Future<void> _refreshData() async {
    final chatProvider = context.read<ChatProvider>();
    await chatProvider.loadSessions(userInitiated: true);
    await chatProvider.refresh();
  }

  bool _supportsInputModality(Model? model, String modality) {
    if (model == null || !model.attachment) {
      return false;
    }
    final normalizedModality = modality.toLowerCase();
    final modalities = model.modalities;
    final input = modalities?['input'];
    if (input is List) {
      final normalized = input
          .whereType<Object>()
          .map((item) => item.toString().toLowerCase())
          .toSet();
      return normalized.contains(normalizedModality);
    }
    if (input is Map) {
      return input[normalizedModality] == true;
    }
    // Backward compatibility for servers that only expose `attachment=true`.
    return true;
  }

  bool _supportsImageAttachments(Model? model) {
    return _supportsInputModality(model, 'image');
  }

  bool _supportsPdfAttachments(Model? model) {
    return _supportsInputModality(model, 'pdf');
  }
}
