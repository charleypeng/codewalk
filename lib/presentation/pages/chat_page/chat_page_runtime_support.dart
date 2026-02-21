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
        contentShrank) {
      final gap = _distanceToBottom();
      if (gap > _ChatPageState._scrollToBottomEpsilon) {
        _scrollController.jumpTo(currentMax);
      }
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
    if (!_isChatScreenActive() || chatProvider.state != ChatState.error) {
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
