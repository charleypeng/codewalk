part of '../chat_page.dart';

extension _ChatPageScrollCoordinator on _ChatPageState {
  void _handleScrollChanged() {
    if (!_scrollController.hasClients) {
      return;
    }

    final nearBottom = _isNearBottom();
    if (nearBottom) {
      if (!_autoFollowToLatest ||
          _showScrollToLatestFab ||
          _hasUnreadMessagesBelow ||
          _showScrollToFirstFab) {
        _setState(() {
          _autoFollowToLatest = true;
          _showScrollToLatestFab = false;
          _hasUnreadMessagesBelow = false;
          _showScrollToFirstFab = false;
        });
      }
      return;
    }

    if (_isProgrammaticScrollInFlight) {
      return;
    }

    final shouldShowJumpToFirst = _shouldShowJumpToFirstFab();
    final userScrollDirection = _scrollController.position.userScrollDirection;
    if (_autoFollowToLatest) {
      // Keep auto-follow enabled for content-size changes (new messages,
      // collapsed/expanded bubbles). We only opt out when the user actually
      // scrolls away from the latest position.
      if (userScrollDirection == ScrollDirection.idle) {
        return;
      }
      _setState(() {
        _autoFollowToLatest = false;
        _showScrollToLatestFab = true;
        _hasUnreadMessagesBelow = false;
        _showScrollToFirstFab = shouldShowJumpToFirst;
      });
      return;
    }

    if (!_showScrollToLatestFab ||
        _showScrollToFirstFab != shouldShowJumpToFirst) {
      _setState(() {
        _showScrollToLatestFab = true;
        _showScrollToFirstFab = shouldShowJumpToFirst;
      });
    }
  }

  Future<void> _runScrollToBottom({
    required int requestToken,
    required bool force,
  }) async {
    if (!_canContinueScrollToBottomRequest(requestToken)) {
      return;
    }

    final shouldScroll = force || _autoFollowToLatest;
    if (!shouldScroll) {
      _markUnreadMessagesBelow();
      return;
    }

    _isProgrammaticScrollInFlight = true;
    try {
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
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
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
    } catch (error, stackTrace) {
      AppLogger.debug(
        'Scroll-to-bottom interrupted for request=$requestToken',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (requestToken == _scrollToBottomRequestToken) {
        _isProgrammaticScrollInFlight = false;
      }
    }

    if (!_canContinueScrollToBottomRequest(requestToken)) {
      return;
    }

    if (!_autoFollowToLatest ||
        _showScrollToLatestFab ||
        _hasUnreadMessagesBelow ||
        _showScrollToFirstFab) {
      _setState(() {
        _autoFollowToLatest = true;
        _showScrollToLatestFab = false;
        _hasUnreadMessagesBelow = false;
        _showScrollToFirstFab = false;
      });
    }
  }
}
