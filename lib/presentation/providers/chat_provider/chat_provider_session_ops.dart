part of '../chat_provider.dart';

extension _ChatProviderSessionOps on ChatProvider {
  Future<void> _switchContext({required String reason}) async {
    _storeCurrentContextSnapshot();

    _providersFetchId += 1;
    _sessionsFetchId += 1;
    _messagesFetchId += 1;
    _eventStreamGeneration += 1;
    await _cancelActiveMessageSubscription(
      reason: 'context-switch',
      invalidateGeneration: true,
    );
    await _cancelSubscriptionSafely(
      _eventSubscription,
      label: 'realtime event',
    );
    await _cancelSubscriptionSafely(
      _globalEventSubscription,
      label: 'global event',
    );
    _eventSubscription = null;
    _globalEventSubscription = null;
    _consecutiveRealtimeFailures = 0;
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

    final serverId = await _resolveServerScopeId();
    final nextScope = _resolveContextScopeId();
    final nextContextKey = _composeContextKey(serverId, nextScope);
    _activeContextKey = nextContextKey;
    _currentProjectId = projectProvider.currentProjectId;
    _restoreContextSnapshot(nextContextKey);

    _errorMessage = null;
    _isLoadingSessionInsights = false;
    _sessionInsightsError = null;
    _isRespondingInteraction = false;
    _providers = <Provider>[];
    _defaultModels = <String, String>{};
    _agents = <Agent>[];
    _providersRefreshTask = null;
    _providersRefreshState = ChatProvidersRefreshState.idle;
    _providersRefreshErrorMessage = null;
    _selectedAgentName = null;
    _selectedProviderId = null;
    _selectedModelId = null;
    _selectedVariantId = null;
    _recentModelKeys = <String>[];
    _modelUsageCounts = <String, int>{};
    _selectedVariantByModel = <String, String>{};
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
    _state = _sessions.isEmpty ? ChatState.initial : ChatState.loaded;
    _notifyListeners();

    AppLogger.info(
      'Switching chat context reason=$reason context=$_activeContextKey',
    );
    unawaited(initializeProviders());

    final contextMarkedDirty = _dirtyContextKeys.remove(nextContextKey);
    if (contextMarkedDirty || _sessions.isEmpty) {
      await loadSessions();
      return;
    }

    await loadLastSession(serverId: serverId, scopeId: nextScope);
  }
}
