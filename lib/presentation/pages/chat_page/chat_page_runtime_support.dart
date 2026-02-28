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
    // When content shrinks (e.g. bubbles collapse, tool chains hide) and we
    // should be following the latest message, snap to the bottom immediately
    // to prevent void space below the last message.
    if (!_scrollController.hasClients) {
      return false;
    }
    final currentMax = _scrollController.position.maxScrollExtent;
    final contentShrank = currentMax < _lastKnownMaxScrollExtent;
    _lastKnownMaxScrollExtent = currentMax;
    if (_autoFollowToLatest &&
        !_isProgrammaticScrollInFlight &&
        !_suppressPostCompletionAutoSnap &&
        contentShrank) {
      final gap = _distanceToBottom();
      if (gap > _ChatPageState._scrollToBottomEpsilon) {
        _scrollController.jumpTo(currentMax);
      }
    }

    if (!_isProgrammaticScrollInFlight &&
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

    return false;
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
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) {
        return;
      }
      messenger.hideCurrentSnackBar();
      final hasRetryAction =
          notice.type == ChatUiNoticeType.remoteAbort && notice.hasAction;
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
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
        ),
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _inputFocusNode.requestFocus();
      });
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
        _sessionCollapseWorkCache[outgoing] = _expandedAssistantWorkGroupId;
        // Evict oldest entry when cache exceeds 20 sessions.
        if (_sessionCollapseHistoryCache.length > 20) {
          _sessionCollapseHistoryCache.remove(
            _sessionCollapseHistoryCache.keys.first,
          );
          _sessionCollapseWorkCache.remove(
            _sessionCollapseWorkCache.keys.first,
          );
        }
      }
      _trackedSessionId = sessionId;
      if (sessionId != null) {
        unawaited(
          _notificationService?.clearNotificationsForSession(sessionId),
        );
      }
      _pendingInitialScrollSessionId = sessionId;
      _olderMessagesLoadTriggerArmed = true;
      _olderMessagesAnchorRestoreInFlight = false;
      // Restore collapse state for the incoming session (null if not cached).
      _expandedCollapsedHistoryGroupId = sessionId != null
          ? _sessionCollapseHistoryCache[sessionId]
          : null;
      _expandedAssistantWorkGroupId = sessionId != null
          ? _sessionCollapseWorkCache[sessionId]
          : null;
      _frozenCompactionBoundaryId = null;
      _wasCompactingContext = false;
      _nextFrozenCompactionBoundaryId = null;
      _nextWasCompactingContext = false;
      _wasCurrentSessionActivelyResponding =
          chatProvider.isCurrentSessionActivelyResponding;
      _deferAssistantWorkCollapse = false;
      _suppressPostCompletionAutoSnap = false;
      _shouldRevealFinalAssistantOnCompletion = false;
      _pendingFinalAssistantRevealMessageId = null;
      _finalAssistantRevealSettledMessageId = null;
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
      }
    }

    if (sessionId == null) {
      _pendingInitialScrollSessionId = null;
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
      _shouldRevealFinalAssistantOnCompletion = false;
      _pendingFinalAssistantRevealMessageId = null;
      _finalAssistantRevealSettledMessageId = null;
      _finalAssistantRevealScheduled = false;
      _pendingFinalAssistantRevealAttempts = 0;
      _messageRevealAnchorKeysByMessageId.clear();
      return;
    }

    if (_pendingInitialScrollSessionId == sessionId &&
        chatProvider.state != ChatState.loading) {
      _pendingInitialScrollSessionId = null;
      if (chatProvider.messages.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _trackedSessionId != sessionId) {
            return;
          }
          _scrollToBottom(force: true);
        });
      }
    }
  }

  void _syncResponseViewportPolicy(ChatProvider chatProvider) {
    final sessionId = chatProvider.currentSession?.id;
    if (sessionId == null) {
      return;
    }

    final isResponding = chatProvider.isCurrentSessionActivelyResponding;
    final latestSuccessfulAssistantMessageId =
        _resolveLatestSuccessfulAssistantMessageId(chatProvider.messages);
    final latestTimelineMessageId = chatProvider.messages.isEmpty
        ? null
        : chatProvider.messages.last.id;

    if (isResponding) {
      final hasSettledFinalMessage =
          _finalAssistantRevealSettledMessageId != null &&
          _finalAssistantRevealSettledMessageId!.isNotEmpty;
      final shouldIgnoreTransientRespondingPulse =
          hasSettledFinalMessage &&
          _pendingFinalAssistantRevealMessageId == null &&
          !_deferAssistantWorkCollapse &&
          latestTimelineMessageId == _finalAssistantRevealSettledMessageId;
      if (shouldIgnoreTransientRespondingPulse) {
        _traceFinalUi(
          'viewport-policy-ignore-transient-responding-pulse',
          details: 'latestTimelineMessageId=${latestTimelineMessageId ?? "-"}',
        );
        return;
      }
      _traceFinalUi(
        'viewport-policy-responding',
        details:
            'latestTimelineMessageId=${latestTimelineMessageId ?? "-"} latestSuccessfulAssistantMessageId=${latestSuccessfulAssistantMessageId ?? "-"}',
      );
      _wasCurrentSessionActivelyResponding = true;
      _deferAssistantWorkCollapse = true;
      _suppressPostCompletionAutoSnap = false;
      _shouldRevealFinalAssistantOnCompletion = _autoFollowToLatest;
      _pendingFinalAssistantRevealMessageId = null;
      _finalAssistantRevealSettledMessageId = null;
      _pendingFinalAssistantRevealAttempts = 0;
      return;
    }

    if (_wasCurrentSessionActivelyResponding) {
      _wasCurrentSessionActivelyResponding = false;
      final shouldRevealFinalAssistant =
          _shouldRevealFinalAssistantOnCompletion && _autoFollowToLatest;
      _deferAssistantWorkCollapse = shouldRevealFinalAssistant;
      _suppressPostCompletionAutoSnap = shouldRevealFinalAssistant;
      _finalAssistantRevealSettledMessageId = null;
      _pendingFinalAssistantRevealAttempts = 0;
      if (shouldRevealFinalAssistant) {
        _pendingFinalAssistantRevealMessageId =
            latestSuccessfulAssistantMessageId;
        _traceFinalUi(
          'viewport-policy-finished-schedule-final-reveal',
          details:
              'latestSuccessfulAssistantMessageId=${latestSuccessfulAssistantMessageId ?? "-"}',
        );
        _scheduleFinalAssistantReveal();
      } else {
        _traceFinalUi(
          'viewport-policy-finished-without-final-reveal',
          details:
              'latestSuccessfulAssistantMessageId=${latestSuccessfulAssistantMessageId ?? "-"}',
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

    if (_shouldRevealFinalAssistantOnCompletion &&
        _suppressPostCompletionAutoSnap &&
        latestSuccessfulAssistantMessageId != null &&
        latestSuccessfulAssistantMessageId.isNotEmpty &&
        latestSuccessfulAssistantMessageId !=
            _finalAssistantRevealSettledMessageId) {
      _traceFinalUi(
        'viewport-policy-post-completion-resume-reveal',
        details:
            'latestSuccessfulAssistantMessageId=$latestSuccessfulAssistantMessageId settled=${_finalAssistantRevealSettledMessageId ?? "-"}',
      );
      _deferAssistantWorkCollapse = true;
      _pendingFinalAssistantRevealMessageId =
          latestSuccessfulAssistantMessageId;
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

  void _revealLatestMessageStartAfterReturn(
    ChatProvider chatProvider, {
    required String reason,
  }) {
    final sessionId = chatProvider.currentSession?.id;
    if (sessionId == null ||
        sessionId.isEmpty ||
        chatProvider.messages.isEmpty) {
      return;
    }

    final latestMessageId = chatProvider.messages.last.id;
    _scrollToBottomRequestToken += 1;
    _scheduleLatestMessageReturnReveal(
      sessionId: sessionId,
      messageId: latestMessageId,
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
      _scrollToBottom(force: true);
      return;
    }

    if (chatProvider.messages.isEmpty) {
      return;
    }

    final latestMessageId = chatProvider.messages.last.id;
    if (latestMessageId != messageId) {
      _scheduleLatestMessageReturnReveal(
        sessionId: sessionId,
        messageId: latestMessageId,
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

    _isProgrammaticScrollInFlight = true;
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
        _isProgrammaticScrollInFlight = false;
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
    _pendingFinalAssistantRevealMessageId = null;
    _finalAssistantRevealSettledMessageId = null;
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
      _isProgrammaticScrollInFlight = true;
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
            _isProgrammaticScrollInFlight = false;
            if (_showScrollToFirstFab) {
              _setState(() {
                _showScrollToFirstFab = false;
              });
            }
          });
    });
  }

  void _scrollToBottom({bool force = false}) {
    final requestToken = ++_scrollToBottomRequestToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runScrollToBottom(requestToken: requestToken, force: force));
    });
  }

  Future<void> _refreshData() async {
    final chatProvider = context.read<ChatProvider>();
    await chatProvider.loadSessions();
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
