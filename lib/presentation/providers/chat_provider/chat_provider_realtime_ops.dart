part of '../chat_provider.dart';

extension _ChatProviderRealtimeOps on ChatProvider {
  Future<void> _cancelPreservedMessageSubscriptions({
    required String reason,
  }) async {
    if (_preservedMessageSubscriptions.isEmpty) {
      return;
    }
    final preserved = List<StreamSubscription<dynamic>>.from(
      _preservedMessageSubscriptions,
    );
    _preservedMessageSubscriptions.clear();
    for (final subscription in preserved) {
      await _cancelSubscriptionSafely(
        subscription,
        label: 'preserved message stream ($reason)',
      );
    }
  }

  Future<void> _cancelActiveMessageSubscription({
    required String reason,
    bool invalidateGeneration = false,
    bool preserveActiveStream = false,
  }) async {
    final active = _messageSubscription;
    if (preserveActiveStream && active != null) {
      _preservedMessageSubscriptions.add(active);
      if (invalidateGeneration) {
        _messageStreamGeneration += 1;
      }
      AppLogger.info('Keeping active message stream reason=$reason');
      return;
    }
    if (invalidateGeneration) {
      _messageStreamGeneration += 1;
    }
    _messageSubscription = null;
    _activeMessageStreamSessionId = null;
    if (active != null) {
      _preservedMessageSubscriptions.remove(active);
    }
    await _cancelSubscriptionSafely(active, label: 'message stream ($reason)');
  }

  void _setSyncState(ChatSyncState nextState, {String? reason}) {
    if (_syncState == nextState) {
      return;
    }
    _syncState = nextState;
    AppLogger.info(
      'sync_state_changed state=${nextState.name} reason=${reason ?? "-"}',
    );
    _notifyListeners();
  }

  void _startSyncHealthMonitor() {
    _syncHealthTimer?.cancel();
    _syncHealthTimer = Timer.periodic(_syncHealthCheckInterval, (_) {
      _evaluateSyncHealth();
    });
  }

  void _evaluateSyncHealth() {
    if (!_isForegroundActive) {
      return;
    }
    unawaited(_syncSelectionFromRemote(reason: 'sync-health-tick'));
    _attemptPendingRemoteSelectionSync(reason: 'sync-health-tick');
    if (!_refreshlessRealtimeEnabled) {
      return;
    }
    final signalAt = _lastRealtimeSignalAt;
    if (signalAt == null) {
      return;
    }
    final stale =
        DateTime.now().difference(signalAt) > _syncSignalStaleThreshold;
    if (!stale) {
      return;
    }
    _setSyncState(ChatSyncState.delayed, reason: 'stale-signal');
    _enterDegradedMode(reason: 'stale-signal');
  }

  Future<void> _runDegradedScopedSync({required String reason}) async {
    if (!_degradedMode || !_isForegroundActive) {
      return;
    }
    AppLogger.info('sync_degraded_poll_tick reason=$reason');
    await loadSessions();
    await refreshActiveSessionView(reason: 'degraded-sync:$reason');
    await _syncSelectionFromRemote(
      reason: 'degraded-sync:$reason',
      force: true,
    );
  }

  Future<void> _resumeRealtimeAfterForeground() async {
    AppLogger.info('sync_resume_reconcile_start');
    await _startRealtimeEventSubscription();
    await _loadPendingInteractions();
    await loadSessions();
    await refreshActiveSessionView(reason: 'foreground-resume');
    final currentSessionId = _currentSession?.id;
    if (currentSessionId != null) {
      await loadSessionInsights(currentSessionId, silent: true);
    }
    await _syncSelectionFromRemote(reason: 'foreground-resume', force: true);
    AppLogger.info('sync_resume_reconcile_complete');
  }

  Future<void> _startRealtimeEventSubscription() async {
    final generation = ++_eventStreamGeneration;
    final previousSubscription = _eventSubscription;
    final previousGlobalSubscription = _globalEventSubscription;
    _eventSubscription = null;
    _globalEventSubscription = null;
    await _cancelSubscriptionSafely(
      previousSubscription,
      label: 'realtime event',
    );
    await _cancelSubscriptionSafely(
      previousGlobalSubscription,
      label: 'global event',
    );
    _setSyncState(ChatSyncState.reconnecting, reason: 'subscription-start');
    _startSyncHealthMonitor();

    final directory = projectProvider.currentDirectory;
    final newSubscription = watchChatEvents(directory: directory).listen(
      (result) {
        if (generation != _eventStreamGeneration) {
          return;
        }
        result.fold(
          (failure) {
            _handleRealtimeStreamFailure(
              source: 'session-stream-failure',
              error: failure,
            );
          },
          (event) {
            _markRealtimeSignal(source: 'session-stream');
            _applyChatEvent(event);
          },
        );
      },
      onError: (error) {
        if (generation != _eventStreamGeneration) {
          return;
        }
        _handleRealtimeStreamFailure(
          source: 'session-stream-exception',
          error: error,
        );
      },
      onDone: () {
        if (generation != _eventStreamGeneration) {
          return;
        }
        _handleRealtimeStreamFailure(source: 'session-stream-done');
      },
    );

    if (generation != _eventStreamGeneration) {
      await newSubscription.cancel();
      return;
    }

    _eventSubscription = newSubscription;

    final globalSubscription = watchGlobalChatEvents().listen(
      (result) {
        if (generation != _eventStreamGeneration) {
          return;
        }
        result.fold(
          (failure) {
            _handleRealtimeStreamFailure(
              source: 'global-stream-failure',
              error: failure,
            );
          },
          (event) {
            _markRealtimeSignal(source: 'global-stream');
            _handleGlobalEvent(event);
          },
        );
      },
      onError: (error) {
        if (generation != _eventStreamGeneration) {
          return;
        }
        _handleRealtimeStreamFailure(
          source: 'global-stream-exception',
          error: error,
        );
      },
      onDone: () {
        if (generation != _eventStreamGeneration) {
          return;
        }
        _handleRealtimeStreamFailure(source: 'global-stream-done');
      },
    );

    if (generation != _eventStreamGeneration) {
      await globalSubscription.cancel();
      return;
    }
    _globalEventSubscription = globalSubscription;
  }
}
