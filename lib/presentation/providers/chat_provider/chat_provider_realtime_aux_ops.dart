part of '../chat_provider.dart';

extension _ChatProviderRealtimeAuxOps on ChatProvider {
  void _startForegroundResumeSyncIndicator({required String reason}) {
    if (!_refreshlessRealtimeEnabled) {
      return;
    }
    final shouldNotify = !_isForegroundResumeSyncing;
    _isForegroundResumeSyncing = true;
    if (shouldNotify) {
      _foregroundResumeSyncCycleCount = 0;
      _recoverableSyncAlertEscalated = false;
    }
    _foregroundResumeSyncTimer?.cancel();
    _foregroundResumeSyncTimer = Timer(
      _foregroundResumeSyncIndicatorDuration,
      () {
        _foregroundResumeSyncTimer = null;
        if (!_isForegroundResumeSyncing) {
          return;
        }
        final recoverableSyncPending =
            _syncState == ChatSyncState.reconnecting ||
            _syncState == ChatSyncState.delayed ||
            _degradedMode;
        if (_isForegroundActive && recoverableSyncPending) {
          _foregroundResumeSyncCycleCount += 1;
          if (_foregroundResumeSyncCycleCount <
              _foregroundResumeSyncIndicatorMaxCycles) {
            _startForegroundResumeSyncIndicator(
              reason: 'foreground-resume-pending',
            );
            return;
          }
          _recoverableSyncAlertEscalated = true;
        }
        _foregroundResumeSyncCycleCount = 0;
        _isForegroundResumeSyncing = false;
        _notifyListeners();
      },
    );
    if (shouldNotify) {
      AppLogger.debug('sync_resume_indicator_started reason=$reason');
      _notifyListeners();
    }
  }

  void _stopForegroundResumeSyncIndicator({required String reason}) {
    _foregroundResumeSyncTimer?.cancel();
    _foregroundResumeSyncTimer = null;
    _foregroundResumeSyncCycleCount = 0;
    final wasSyncing = _isForegroundResumeSyncing;
    final wasEscalated = _recoverableSyncAlertEscalated;
    _isForegroundResumeSyncing = false;
    _recoverableSyncAlertEscalated = false;
    if (!wasSyncing && !wasEscalated) {
      return;
    }
    AppLogger.debug('sync_resume_indicator_stopped reason=$reason');
    _notifyListeners();
  }

  Future<void> _cancelSubscriptionSafely(
    StreamSubscription<dynamic>? subscription, {
    required String label,
  }) async {
    if (subscription == null) {
      return;
    }
    try {
      await subscription.cancel().timeout(const Duration(seconds: 2));
    } catch (error) {
      AppLogger.warn('Failed to cancel $label subscription', error: error);
    }
  }

  void _markRealtimeSignal({required String source}) {
    _lastRealtimeSignalAt = DateTime.now();
    _consecutiveRealtimeFailures = 0;
    _stopForegroundResumeSyncIndicator(reason: 'signal:$source');
    if (_degradedMode) {
      _exitDegradedMode(reason: 'signal-restored:$source');
    }
    _setSyncState(ChatSyncState.connected, reason: 'signal:$source');
  }

  void _handleRealtimeStreamFailure({required String source, Object? error}) {
    _consecutiveRealtimeFailures += 1;
    AppLogger.warn(
      'event_stream_reconnecting source=$source attempts=$_consecutiveRealtimeFailures',
      error: error,
    );
    _setSyncState(ChatSyncState.reconnecting, reason: 'stream-failure:$source');
    if (_refreshlessRealtimeEnabled &&
        _consecutiveRealtimeFailures >= _degradedFailureThreshold) {
      _enterDegradedMode(reason: 'stream-failure:$source');
    }
  }

  void _enterDegradedMode({required String reason}) {
    if (!_refreshlessRealtimeEnabled || !_isForegroundActive || _degradedMode) {
      return;
    }
    _degradedMode = true;
    _degradedModeStartedAt = DateTime.now();
    _setSyncState(ChatSyncState.delayed, reason: 'degraded-enter:$reason');
    AppLogger.warn(
      'sync_degraded_entered reason=$reason interval=${_degradedPollingInterval.inSeconds}s',
    );
    _degradedPollingTimer?.cancel();
    _degradedPollingTimer = Timer.periodic(_degradedPollingInterval, (_) {
      unawaited(_runDegradedScopedSync(reason: 'degraded-periodic'));
    });
    unawaited(_runDegradedScopedSync(reason: 'degraded-enter'));
  }

  void _exitDegradedMode({required String reason}) {
    if (!_degradedMode) {
      return;
    }
    _degradedMode = false;
    final startedAt = _degradedModeStartedAt;
    _degradedModeStartedAt = null;
    _degradedPollingTimer?.cancel();
    _degradedPollingTimer = null;
    final durationSeconds = startedAt == null
        ? null
        : DateTime.now().difference(startedAt).inSeconds;
    AppLogger.info(
      'sync_degraded_recovered reason=$reason duration_s=${durationSeconds ?? 0}',
    );
  }

  Future<void> _loadPendingInteractions() async {
    final directory = projectProvider.currentDirectory;

    final permissionsResult = await listPendingPermissions(
      directory: directory,
    );
    permissionsResult.fold(
      (failure) {
        AppLogger.warn('Failed to load pending permissions: $failure');
      },
      (permissions) {
        final grouped = <String, List<ChatPermissionRequest>>{};
        for (final item in permissions) {
          grouped
              .putIfAbsent(item.sessionId, () => <ChatPermissionRequest>[])
              .add(item);
        }
        _pendingPermissionsBySession = grouped;
        _threadPermissionsVersion++;
      },
    );

    final questionsResult = await listPendingQuestions(directory: directory);
    questionsResult.fold(
      (failure) {
        AppLogger.warn('Failed to load pending questions: $failure');
      },
      (questions) {
        final grouped = <String, List<ChatQuestionRequest>>{};
        for (final item in questions) {
          grouped
              .putIfAbsent(item.sessionId, () => <ChatQuestionRequest>[])
              .add(item);
        }
        _pendingQuestionsBySession = grouped;
      },
    );

    _notifyListeners();
  }

  void _upsertSession(ChatSession session) {
    if (_isEphemeralTitleSession(session)) {
      _removeSessionById(session.id);
      return;
    }
    final existingIndex = _sessions.indexWhere((item) => item.id == session.id);
    if (existingIndex == -1) {
      _sessions.add(session);
      _threadPermissionsVersion++;
      _sortSessionsInPlace();
      return;
    }
    _sessions[existingIndex] = session;
    _threadPermissionsVersion++;
    _sortSessionsInPlace();
  }

  void _removeSessionById(String sessionId) {
    _sessions.removeWhere((item) => item.id == sessionId);
    _removeSessionMessagesCache(sessionId);
    unawaited(_clearSessionMessagesSnapshotBestEffort(sessionId));
    _removeSessionSelectionOverride(sessionId);
    _pendingRenameTitleBySessionId.remove(sessionId);
    _autoTitleConsolidatedSessionIds.remove(sessionId);
    _autoTitleLastSignatureBySessionId.remove(sessionId);
    _autoTitleInFlightSessionIds.remove(sessionId);
    _autoTitleQueuedSessionIds.remove(sessionId);
    _queuedSendBySessionId.remove(sessionId);
    _queuedDrainDeferredSessionIds.remove(sessionId);
    _queuedRetryTimersBySessionId.remove(sessionId)?.cancel();
    _queuedRetryAttemptsBySessionId.remove(sessionId);
    _syncQueuedLocalUserMessageIds();
    if (_currentSession?.id == sessionId) {
      _currentSession = _sessions.firstOrNull;
      _messages = <ChatMessage>[];
      _isLoadingOlderMessages = false;
      _hasMoreOldMessages = false;
      _messagesVersion++;
      _pendingLocalUserMessageIds.clear();
      _applySelectionPriorityForCurrentSession();
    }
    _sessionStatusById.remove(sessionId);
    _pendingPermissionsBySession.remove(sessionId);
    _pendingQuestionsBySession.remove(sessionId);
    _sessionUnreadCompletionIds.remove(sessionId);
    _sessionErrorAttentionIds.remove(sessionId);
    _sessionChildrenById.remove(sessionId);
    _sessionTodoById.remove(sessionId);
    _sessionDiffById.remove(sessionId);
    _threadPermissionsVersion++;
  }

  bool _isEphemeralTitleEvent(ChatEvent event) {
    final props = event.properties;
    final sessionId = _extractEventSessionId(props);
    if (sessionId != null &&
        ChatTitleGenerator.ephemeralSessionIds.contains(sessionId)) {
      return true;
    }
    // Fallback: check session title in event payload (covers race condition).
    final info = props['info'];
    if (info is Map<String, dynamic>) {
      final title = info['title'] as String?;
      if (title == ChatTitleGenerator.ephemeralSessionTitle) {
        return true;
      }
    }
    return false;
  }

  String? _extractEventSessionId(Map<String, dynamic> properties) {
    return extractEventSessionId(properties);
  }

  String? _sessionTitleForNotification(String? sessionId) {
    if (sessionId == null || sessionId.isEmpty) {
      return null;
    }
    final session = _sessionById(sessionId);
    if (session == null) {
      return null;
    }
    return SessionTitleFormatter.displayTitle(
      time: session.time,
      title: session.title,
    );
  }

  String? _extractDirectoryFromEvent(ChatEvent event) {
    return extractEventDirectory(event.properties);
  }

  Future<void> _clearPersistedContextCache(String contextKey) async {
    final serverId = _serverIdFromContextKey(contextKey);
    final scopeId = _scopeIdFromContextKey(contextKey);
    if (serverId == null || scopeId == null) {
      return;
    }
    await localDataSource.clearChatContextCache(
      serverId: serverId,
      scopeId: scopeId,
    );
  }
}
