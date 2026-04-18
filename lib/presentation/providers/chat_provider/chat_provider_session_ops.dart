part of '../chat_provider.dart';

extension _ChatProviderSessionOps on ChatProvider {
  Future<void> _switchContext({
    required String reason,
    bool waitForRevalidation = true,
  }) async {
    final useFastProjectTransition =
        reason == 'project' && !waitForRevalidation;
    _storeCurrentContextSnapshot();

    _providersFetchId += 1;
    _sessionsFetchId += 1;
    _messagesFetchId += 1;
    _eventStreamGeneration += 1;
    await _cancelActiveMessageSubscription(
      reason: 'context-switch',
      invalidateGeneration: true,
    );
    final eventSubscription = _eventSubscription;
    final globalEventSubscription = _globalEventSubscription;
    _eventSubscription = null;
    _globalEventSubscription = null;
    if (useFastProjectTransition) {
      await Future.wait<void>(<Future<void>>[
        _cancelSubscriptionSafely(
          eventSubscription,
          label: 'realtime event',
          timeout: const Duration(milliseconds: 100),
        ),
        _cancelSubscriptionSafely(
          globalEventSubscription,
          label: 'global event',
          timeout: const Duration(milliseconds: 100),
        ),
      ], eagerError: false);
    } else {
      await _cancelSubscriptionSafely(
        eventSubscription,
        label: 'realtime event',
      );
      await _cancelSubscriptionSafely(
        globalEventSubscription,
        label: 'global event',
      );
    }
    _consecutiveRealtimeFailures = 0;
    _dismissedInteractionTombstones.clear();
    _dedupeNextDeltaFieldKeys.clear();
    _hasLoadedSessionsAuthoritatively = false;
    _lastRealtimeSignalAt = null;
    _degradedMode = false;
    _degradedModeStartedAt = null;
    _foregroundResumeSyncTimer?.cancel();
    _foregroundResumeSyncTimer = null;
    _foregroundResumeSyncCycleCount = 0;
    _isForegroundResumeSyncing = false;
    _recoverableSyncAlertEscalated = false;
    _degradedPollingTimer?.cancel();
    _degradedPollingTimer = null;
    if (_refreshlessRealtimeEnabled) {
      _setSyncState(ChatSyncState.reconnecting, reason: 'context-switch');
    }

    final previousServerId = _activeServerId;
    final serverId = await _resolveServerScopeId();
    final serverChanged = previousServerId != serverId;
    final nextScope = _resolveContextScopeId();
    final nextContextKey = _composeContextKey(serverId, nextScope);
    _lazySessionBootstrapTask = null;
    _activeContextKey = nextContextKey;
    _currentProjectId = projectProvider.currentProjectId;
    _restoreContextSnapshot(nextContextKey);

    _errorMessage = null;
    _isLoadingSessionInsights = false;
    _sessionInsightsError = null;
    _isRespondingInteraction = false;
    _agents = <Agent>[];
    _providersRefreshTask = null;
    _providersRefreshState = ChatProvidersRefreshState.idle;
    _providersRefreshErrorMessage = null;
    _selectedAgentName = null;
    _selectedProviderId = null;
    _selectedModelId = null;
    _selectedVariantId = null;
    _recentModelKeys = <String>[];
    _recentAgentNames = <String>[];
    _recentVariantValuesByModel = <String, List<String>>{};
    _modelUsageCounts = <String, int>{};
    _selectedVariantByModel = <String, String>{};
    _shortcutCycleStateByDomain.clear();
    _lastSyncedRemoteModelKey = null;
    _lastSyncedRemoteAgentName = null;
    _lastSyncedRemoteVariantKey = null;
    _lastSyncedRemoteSessionOverridesSignature = null;
    _pendingRemoteSelectionSync = false;
    _pendingRemoteSelectionSyncSince = null;
    _lastRemoteSelectionSyncAt = null;
    _remoteSelectionSyncInFlight = false;
    _selectionSyncTransactionPhase = _SelectionSyncTransactionPhase.idle;
    _autoTitleConsolidatedSessionIds.clear();
    _autoTitleLastSignatureBySessionId.clear();
    _autoTitleInFlightSessionIds.clear();
    _autoTitleQueuedSessionIds.clear();
    if (serverChanged) {
      _providers = <Provider>[];
      _defaultModels = <String, String>{};
      _connectedProviderIds = <String>[];
      await _restoreProviderCatalogSnapshot(serverId: serverId, notify: false);
    }
    _state = _sessions.isEmpty ? ChatState.initial : ChatState.loaded;
    _notifyListeners();

    AppLogger.info(
      'Switching chat context reason=$reason context=$_activeContextKey',
    );
    final providersRefresh = initializeProviders().catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      AppLogger.warn(
        'Background providers refresh failed during context switch',
        error: error,
        stackTrace: stackTrace,
      );
    });
    if (reason == 'server') {
      await providersRefresh;
    } else {
      unawaited(providersRefresh);
    }

    final contextMarkedDirty = _dirtyContextKeys.remove(nextContextKey);
    if (useFastProjectTransition) {
      if (contextMarkedDirty || _sessions.isEmpty) {
        unawaited(loadSessions(preserveVisibleState: true));
        return;
      }
      unawaited(loadLastSession(serverId: serverId, scopeId: nextScope));
      unawaited(loadSessions(preserveVisibleState: true));
      return;
    }

    if (contextMarkedDirty || _sessions.isEmpty) {
      await loadSessions();
      return;
    }

    await loadLastSession(serverId: serverId, scopeId: nextScope);
  }
}
