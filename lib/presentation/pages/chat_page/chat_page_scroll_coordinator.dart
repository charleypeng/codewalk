part of '../chat_page.dart';

extension _ChatPageScrollCoordinator on _ChatPageState {
  bool _hasActiveUserScrollActivity() {
    if (!_scrollController.hasClients) {
      return false;
    }
    final activity = _scrollController.position.activity;
    return activity is DragScrollActivity ||
        activity is BallisticScrollActivity;
  }

  void _handleScrollChanged() {
    if (!_scrollController.hasClients) {
      return;
    }

    final userScrollDirection = _scrollController.position.userScrollDirection;
    _maybeLoadOlderMessagesFromTop(userScrollDirection: userScrollDirection);

    if (_isProgrammaticScrollInFlight) {
      return;
    }

    // Set userDrag owner when user is actively dragging
    if (_hasActiveUserScrollActivity() &&
        userScrollDirection != ScrollDirection.idle) {
      _setScrollOwner(_ScrollOwner.userDrag);
    }

    final distance = _distanceToBottom();
    final nearBottom = _isNearBottom();
    final shouldShowJumpToFirst = _shouldShowJumpToFirstFab();

    if (distance <= _ChatPageState._scrollToBottomEpsilon) {
      if (_currentScrollOwner == _ScrollOwner.userDrag) {
        _setScrollOwner(_ScrollOwner.none);
      }
      if (_scrollFollowMode != _ScrollFollowMode.following) {
        _setState(() {
          _scrollFollowMode = _ScrollFollowMode.following;
          _hasUnreadMessagesBelow = false;
          _showScrollToFirstFab = shouldShowJumpToFirst;
        });
      }
      return;
    }

    if (_currentScrollOwner == _ScrollOwner.userDrag &&
        userScrollDirection == ScrollDirection.idle) {
      _setScrollOwner(_ScrollOwner.none);
    }

    // If user dragged/scrolled away from the very bottom, or if they scrolled past 200px
    if (_currentScrollOwner == _ScrollOwner.userDrag || !nearBottom) {
      if (_scrollFollowMode != _ScrollFollowMode.pausedByUser) {
        _setState(() {
          _scrollFollowMode = _ScrollFollowMode.pausedByUser;
          _showScrollToFirstFab = shouldShowJumpToFirst;
        });
      } else {
        if (_showScrollToFirstFab != shouldShowJumpToFirst) {
          _setState(() {
            _showScrollToFirstFab = shouldShowJumpToFirst;
          });
        }
      }
    } else {
      // Not dragging and within 200px (but not at 0px)
      if (_showScrollToFirstFab != shouldShowJumpToFirst) {
        _setState(() {
          _showScrollToFirstFab = shouldShowJumpToFirst;
        });
      }
    }
  }

  void _maybeLoadOlderMessagesFromTop({
    required ScrollDirection userScrollDirection,
  }) {
    final provider = _chatProvider;
    if (provider == null ||
        provider.currentSession == null ||
        !provider.hasMoreOldMessages ||
        provider.isLoadingOlderMessages ||
        _olderMessagesAnchorRestoreInFlight) {
      return;
    }

    final pixels = _scrollController.position.pixels;
    if (pixels > _ChatPageState._olderMessagesTopLoadArmThreshold) {
      _olderMessagesLoadTriggerArmed = true;
      return;
    }

    if (!_olderMessagesLoadTriggerArmed) {
      return;
    }

    if (!_hasActiveUserScrollActivity()) {
      return;
    }

    if (userScrollDirection != ScrollDirection.forward) {
      return;
    }

    if (pixels > _ChatPageState._olderMessagesTopLoadThreshold) {
      return;
    }

    final maxBefore = _scrollController.position.maxScrollExtent;
    _olderMessagesLoadTriggerArmed = false;
    unawaited(
      _loadOlderMessagesAndRestoreAnchor(
        provider: provider,
        maxExtentBefore: maxBefore,
      ),
    );
  }

  Future<void> _loadOlderMessagesAndRestoreAnchor({
    required ChatProvider provider,
    required double maxExtentBefore,
  }) async {
    _setScrollOwner(_ScrollOwner.paginationRestore);
    try {
      await provider.loadOlderMessages();
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      await Future<void>.microtask(() {});
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      final maxAfter = _scrollController.position.maxScrollExtent;
      final delta = maxAfter - maxExtentBefore;
      if (delta <= 0) {
        return;
      }

      final nextPixels = (_scrollController.position.pixels + delta).clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.jumpTo(nextPixels);
    } finally {
      _setScrollOwner(_ScrollOwner.none);
    }
  }

  Future<void> _runScrollToBottom({
    required int requestToken,
    required bool force,
    required bool animate,
  }) async {
    if (!_canContinueScrollToBottomRequest(requestToken)) {
      return;
    }

    if (_currentScrollOwner == _ScrollOwner.userDrag && !force) {
      _markUnreadMessagesBelow();
      return;
    }

    if (_isReturnRevealInFlight && !force) {
      return;
    }

    if (_olderMessagesAnchorRestoreInFlight && !force) {
      return;
    }

    if (force) {
      _scrollFollowMode = _ScrollFollowMode.following;
    }
    final shouldScroll = force || _scrollFollowMode == _ScrollFollowMode.following;
    if (!shouldScroll) {
      _markUnreadMessagesBelow();
      return;
    }

    _setScrollOwner(force ? _ScrollOwner.newMessage : _ScrollOwner.streaming);
    try {
      if (!animate) {
        for (
          var pass = 0;
          pass < _ChatPageState._maxScrollToBottomPasses;
          pass += 1
        ) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          await WidgetsBinding.instance.endOfFrame;
          if (!_canContinueScrollToBottomRequest(requestToken)) {
            return;
          }
          if (_distanceToBottom() <= _ChatPageState._scrollToBottomEpsilon) {
            break;
          }
        }
        if (_distanceToBottom() > _ChatPageState._scrollToBottomEpsilon) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      } else {
        for (
          var pass = 0;
          pass < _ChatPageState._maxScrollToBottomPasses;
          pass += 1
        ) {
          if (!_canContinueScrollToBottomRequest(requestToken)) {
            return;
          }

          final distance = _distanceToBottom();
          if (distance <= _ChatPageState._scrollToBottomEpsilon) {
            break;
          }

          // During auto-follow (streaming), snap small gaps instantly to avoid
          // animation conflicts from rapid content updates that cancel/restart
          // the 260ms animateTo every frame, causing visible jumps.
          if (!force && distance <= _ChatPageState._nearBottomThreshold) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
            break;
          }

          await _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: pass == 0
                ? _ChatPageState._scrollToBottomFirstPassDuration
                : _ChatPageState._scrollToBottomNextPassDuration,
            curve: Curves.easeOut,
          );

          if (!_canContinueScrollToBottomRequest(requestToken)) {
            return;
          }
          await WidgetsBinding.instance.endOfFrame;
        }

        if (_canContinueScrollToBottomRequest(requestToken) &&
            _distanceToBottom() > _ChatPageState._scrollToBottomEpsilon) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    } catch (error, stackTrace) {
      AppLogger.debug(
        'Scroll-to-bottom interrupted for request=$requestToken',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (requestToken == _scrollToBottomRequestToken) {
        _setScrollOwner(_ScrollOwner.none);
      }
    }

    if (!_canContinueScrollToBottomRequest(requestToken)) {
      return;
    }

    if (_scrollFollowMode != _ScrollFollowMode.following ||
        _hasUnreadMessagesBelow ||
        _showScrollToFirstFab) {
      _setState(() {
        _scrollFollowMode = _ScrollFollowMode.following;
        _hasUnreadMessagesBelow = false;
        _showScrollToFirstFab = false;
      });
    }
  }
}
