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
      _trackedSessionId = sessionId;
      if (sessionId != null) {
        unawaited(
          _notificationService?.clearNotificationsForSession(sessionId),
        );
      }
      _pendingInitialScrollSessionId = sessionId;
      _expandedCollapsedHistoryGroupId = null;
      _expandedAssistantWorkGroupId = null;
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
        chatProvider.messages.isNotEmpty &&
        chatProvider.state != ChatState.loading) {
      _pendingInitialScrollSessionId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _trackedSessionId != sessionId) {
          return;
        }
        _scrollToBottom(force: true);
      });
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

    if (isResponding) {
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
        _scheduleFinalAssistantReveal();
      } else {
        _pendingFinalAssistantRevealMessageId = null;
      }
      return;
    }

    if (_pendingFinalAssistantRevealMessageId != null) {
      _scheduleFinalAssistantReveal();
      return;
    }

    if (_shouldRevealFinalAssistantOnCompletion &&
        _suppressPostCompletionAutoSnap &&
        latestSuccessfulAssistantMessageId != null &&
        latestSuccessfulAssistantMessageId.isNotEmpty &&
        latestSuccessfulAssistantMessageId !=
            _finalAssistantRevealSettledMessageId) {
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
      () => GlobalKey(debugLabel: 'assistant_final_anchor_$messageId'),
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

  void _scheduleFinalAssistantReveal() {
    final messageId = _pendingFinalAssistantRevealMessageId;
    if (_finalAssistantRevealScheduled) {
      return;
    }
    if (messageId == null || messageId.isEmpty) {
      return;
    }

    _finalAssistantRevealScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _finalAssistantRevealScheduled = false;
      if (!mounted ||
          !_shouldRevealFinalAssistantOnCompletion ||
          _pendingFinalAssistantRevealMessageId != messageId) {
        return;
      }
      unawaited(_revealFinalAssistantMessageStart(messageId));
    });
  }

  Future<void> _revealFinalAssistantMessageStart(String messageId) async {
    if (!mounted ||
        !_shouldRevealFinalAssistantOnCompletion ||
        _pendingFinalAssistantRevealMessageId != messageId) {
      return;
    }

    if (!_scrollController.hasClients) {
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
    } finally {
      _isProgrammaticScrollInFlight = false;
    }

    if (!mounted || _pendingFinalAssistantRevealMessageId != messageId) {
      return;
    }

    _finalizeFinalAssistantReveal(messageId);
  }

  void _finalizeFinalAssistantReveal(String messageId) {
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
