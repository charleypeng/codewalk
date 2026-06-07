part of '../chat_provider.dart';

extension ChatProviderLifecycleOps on ChatProvider {

  // Foreground/background lifecycle.
  Future<void> setForegroundActive(bool isActive) async {
    final wasActive = _isForegroundActive;
    _isForegroundActive = isActive;
    _cellularDataSaverService.setAppForeground(isActive);
    if (!isActive) {
      _stopForegroundResumeSyncIndicator(reason: 'background');
    }

    if (isActive && _hasPendingRenderFlush) {
      // Flush accumulated state changes suppressed while in background.
      _hasPendingRenderFlush = false;
      _notifyListeners();
    }

    if (!_refreshlessRealtimeEnabled) {
      return;
    }

    if (!isActive) {
      // Pause automatic network work in background. When cellular data saver is
      // active we also close idle realtime streams so no background downloads continue.
      // Preserve degraded mode state so we can re-enter it immediately on
      // foreground return instead of requiring 3 new SSE failures.
      _wasDegradedModeBeforeBackground = _degradedMode;
      _syncHealthTimer?.cancel();
      _syncHealthTimer = null;
      _degradedPollingTimer?.cancel();
      _degradedPollingTimer = null;
      _degradedMode = false;
      _degradedModeStartedAt = null;
      if (_cellularDataSaverService.shouldDisableBackgroundNetworkTasks) {
        _idleRealtimePausedForDataSaver = true;
        await _stopRealtimeEventSubscriptions(reason: 'background-data-saver');
      }
      return;
    }

    if (!wasActive) {
      _startForegroundResumeSyncIndicator(reason: 'foreground');
    }

    _startSyncHealthMonitor();
    // If degraded mode was active when the app went to background, re-enter
    // it immediately for UI continuity (polling starts right away). Do NOT
    // return early — the realtime subscription must still be started so
    // that _markRealtimeSignal can eventually exit degraded mode when the
    // SSE connection succeeds.
    if (_wasDegradedModeBeforeBackground) {
      _wasDegradedModeBeforeBackground = false;
      _enterDegradedMode(reason: 'foreground-resume-degraded');
    }
    await _syncCellularDataSaverRealtimePolicy(reason: 'foreground-return');
    await _resumeRealtimeAfterForeground();
  }

  // Foreground state setter.
  void setAppInForeground(bool isForeground) {
    _isAppInForeground = isForeground;
  }

  // Chat route state setter.
  void setChatRouteActive(bool isActive) {
    _isChatRouteActive = isActive;
  }

  // Refresh the active session view (messages, status, todo).
  Future<void> refreshActiveSessionView({
    String reason = 'manual',
    bool includeStatus = true,
    bool allowDuringAbortSuppression = false,
    bool preferDelta = true,
  }) async {
    final session = _currentSession;
    if (session == null) {
      return;
    }
    // During abort suppression, polling already delivered fresh data.
    // Loading from server risks showing stale abort content that the
    // suppression window is designed to hide.
    if (!allowDuringAbortSuppression &&
        _isAbortSuppressionActiveForSession(session.id)) {
      _traceFinal(
        'refresh-active-skip-abort-suppression',
        sessionId: session.id,
        details:
            'reason=$reason includeStatus=$includeStatus allowDuringAbortSuppression=$allowDuringAbortSuppression',
      );
      AppLogger.info(
        'Skipping active session refresh during abort suppression session=${session.id} reason=$reason',
      );
      return;
    }
    if (_activeSessionRefreshInFlight) {
      return;
    }

    _activeSessionRefreshInFlight = true;
    _traceFinal(
      'refresh-active-start',
      sessionId: session.id,
      details:
          'reason=$reason includeStatus=$includeStatus allowDuringAbortSuppression=$allowDuringAbortSuppression',
    );
    AppLogger.debug(
      'Refreshing active session view reason=$reason session=${session.id}',
    );

    final refreshStartVersion = _messagesVersion;
    var fallbackToFullFetch = false;

    try {
      final cachedMessages = List<ChatMessage>.from(
        _messages.where((message) => message.sessionId == session.id),
      );
      final previousLatestSessionMessage = cachedMessages.lastOrNull;
      final canUseDelta = preferDelta && cachedMessages.isNotEmpty;
      final messagesResult = await getChatMessages(
        GetChatMessagesParams(
          projectId: projectProvider.currentProjectId,
          sessionId: session.id,
          directory: projectProvider.currentDirectory,
          limit: canUseDelta ? ChatProvider._defaultOlderMessagesChunkSize : null,
        ),
      );

      messagesResult.fold(
        (failure) {
          _traceFinal(
            'refresh-active-failure',
            sessionId: session.id,
            details: 'reason=$reason failure=${failure.runtimeType}',
          );
          AppLogger.warn(
            'Failed to refresh active session messages for ${session.id}: $failure',
          );
        },
        (messages) {
          if (_currentSession?.id != session.id) {
            return;
          }
          if (_messagesVersion != refreshStartVersion) {
            return;
          }
          var serverMessagesForMerge = messages;
          var requiresFullFetch = false;
          var usedGapRecovery = false;
          if (canUseDelta) {
            final deltaResult = _mergeServerTailWithCachedMessages(
              serverMessages: messages,
              cachedMessages: cachedMessages,
              sessionId: session.id,
            );
            serverMessagesForMerge = deltaResult.messages;
            requiresFullFetch = deltaResult.requiresFullFetch;
            usedGapRecovery = deltaResult.usedGapRecovery;
          }
          serverMessagesForMerge = _filterMessagesForPendingReplacementBranch(
            serverMessagesForMerge,
            sessionId: session.id,
          );
          final mergedMessages = _mergeServerMessagesWithActiveLocalTail(
            serverMessagesForMerge,
            sessionId: session.id,
          );
          final nextHasMoreOldMessages =
              usedGapRecovery ||
              serverMessagesForMerge.length >= ChatProvider._defaultOlderMessagesChunkSize;
          final messagesChanged = !_areMessageListsSemanticallyEqual(
            cachedMessages,
            mergedMessages,
          );
          final hasMoreOldMessagesChanged =
              _hasMoreOldMessages != nextHasMoreOldMessages;
          if (!messagesChanged) {
            if (!hasMoreOldMessagesChanged) {
              _traceFinal(
                'refresh-active-noop',
                sessionId: session.id,
                details: 'reason=$reason',
              );
              return;
            }
            _hasMoreOldMessages = nextHasMoreOldMessages;
            notifyListeners();
            return;
          }

          _messages = List<ChatMessage>.from(mergedMessages);
          _cacheSessionMessages(session.id, _messages);
          if (messagesChanged) {
            _messagesVersion++;
          }
          _hasMoreOldMessages = nextHasMoreOldMessages;
          _prunePendingLocalUserMessageIdsToVisibleUsers();
          notifyListeners();
          _traceFinal(
            'refresh-active-merged',
            sessionId: session.id,
            details: 'reason=$reason mergedMessages=${_messages.length}',
          );
          _scheduleAutoTitleRefresh(session.id);
          if (!usedGapRecovery) {
            unawaited(
              _persistSessionMessagesSnapshotBestEffort(session.id, _messages),
            );
          }
          final sessionStatusType = _sessionStatusById[session.id]?.type;
          final hasBusyRefreshStatus =
              sessionStatusType == SessionStatusType.busy ||
              sessionStatusType == SessionStatusType.retry;
          final latestSessionMessage = _messages.lastOrNull;
          final latestSessionMessageChanged =
              latestSessionMessage != previousLatestSessionMessage;
          if (!_isCompactingContext &&
              latestSessionMessageChanged &&
              !hasBusyRefreshStatus &&
              !isSessionActivelyResponding(session.id)) {
            _scheduleScrollToBottom(reason: 'refresh-active-session-view');
          }
          if (requiresFullFetch && _currentSession?.id == session.id) {
            fallbackToFullFetch = true;
          }
        },
      );

      if (includeStatus) {
        await refreshSessionStatusSnapshot();
      }
    } finally {
      _activeSessionRefreshInFlight = false;
      _traceFinal(
        'refresh-active-finished',
        sessionId: session.id,
        details: 'reason=$reason includeStatus=$includeStatus',
      );
    }

    if (fallbackToFullFetch && _currentSession?.id == session.id) {
      unawaited(
        refreshActiveSessionView(
          reason: '$reason:delta-fallback',
          includeStatus: false,
          allowDuringAbortSuppression: allowDuringAbortSuppression,
          preferDelta: false,
        ),
      );
    }
  }

  // Warmup providers refresh.
  void warmupProvidersRefresh({String reason = 'startup'}) {
    AppLogger.info('providers_refresh_warmup reason=$reason');
    unawaited(initializeProviders());
  }

  // Config mutation deferral gate.
  bool get shouldDeferConfigMutations =>
      _hasLocalActiveSelectionSyncWork ||
      _hasAnyActiveAbortSuppression ||
      _hasAnyBusySessionStatus;

  /// Clear error
  void clearError() {
    _errorMessage = null;
    if (_state == ChatState.error) {
      _setState(ChatState.loaded);
    }
  }


  /// Delete session
  Future<void> deleteSession(String sessionId) async {
    _currentProjectId = projectProvider.currentProjectId;
    final previousSessions = List<ChatSession>.from(_sessions);
    final previousCurrent = _currentSession;
    final previousMessages = List<ChatMessage>.from(_messages);
    final wasCurrent = previousCurrent?.id == sessionId;

    _removeSessionMessagesCache(sessionId);
    unawaited(_clearSessionMessagesSnapshotBestEffort(sessionId));

    _removeSessionById(sessionId);
    _sortSessionsInPlace();

    if (wasCurrent) {
      _currentSession = _sessions.firstOrNull;
      _threadPermissionsVersion++;
      _messages = <ChatMessage>[];
      _isLoadingOlderMessages = false;
      _hasMoreOldMessages = false;
      _messagesVersion++;
    }
    notifyListeners();

    final result = await deleteChatSession(
      DeleteChatSessionParams(
        projectId: projectProvider.currentProjectId,
        sessionId: sessionId,
        directory: projectProvider.currentDirectory,
      ),
    );

    result.fold(
      (failure) {
        _sessions = previousSessions;
        _currentSession = previousCurrent;
        _threadPermissionsVersion++;
        _messages = List<ChatMessage>.from(previousMessages);
        if (previousCurrent != null) {
          _cacheSessionMessages(previousCurrent.id, previousMessages);
          unawaited(
            _persistSessionMessagesSnapshotBestEffort(
              previousCurrent.id,
              previousMessages,
            ),
          );
        }
        _messagesVersion++;
        _sortSessionsInPlace();
        unawaited(_persistLastSessionSnapshotBestEffort());
        _handleFailure(failure);
      },
      (_) async {
        if (wasCurrent && _currentSession != null) {
          await loadMessages(_currentSession!.id);
          await loadSessionInsights(_currentSession!.id, silent: true);
        }
        if (_currentSession == null) {
          unawaited(_clearLastSessionSnapshotBestEffort());
        } else {
          unawaited(_persistLastSessionSnapshotBestEffort());
        }
        notifyListeners();
      },
    );
  }


  /// Refresh current session
  Future<void> refresh() async {
    _cellularDataSaverService.noteExplicitUserAction(reason: 'manual-refresh');
    await _syncCellularDataSaverRealtimePolicy(
      reason: 'manual-refresh-user',
      forceBurst: true,
    );
    if (_currentSession != null) {
      await refreshActiveSessionView(reason: 'manual-refresh');
    } else {
      // If there is no current session, reload sessions
      if (_sessions.isNotEmpty) {
        // Assume workspaceId exists; in practice it should come from app state
        // Adjust based on actual app behavior
        _setState(ChatState.loaded);
      }
    }
  }

  @visibleForTesting
  void clearSseSettledTimestamps() {
    _sseSettledAtBySessionId.clear();
  }
}
