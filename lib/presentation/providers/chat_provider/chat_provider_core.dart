part of '../chat_provider.dart';

extension _ChatProviderCorePart on ChatProvider {
  Future<void> _initializeProvidersInternal() async {
    if (!_featureFlagLogged) {
      _featureFlagLogged = true;
      AppLogger.info(
        'refreshless_feature_enabled=$_refreshlessRealtimeEnabled',
      );
    }
    _setProvidersRefreshState(
      ChatProvidersRefreshState.loading,
      errorMessage: null,
    );
    final fetchId = ++_providersFetchId;
    final serverId = await _resolveServerScopeId();
    final scopeId = _resolveContextScopeId();
    try {
      var failed = false;
      var connected = <String>[];
      final result = await getProviders(
        directory: projectProvider.currentDirectory,
      );
      if (fetchId != _providersFetchId) {
        return;
      }
      result.fold(
        (failure) {
          failed = true;
          AppLogger.warn('Failed to load providers: ${failure.toString()}');
          final message = failure.message.trim();
          _setProvidersRefreshState(
            ChatProvidersRefreshState.failed,
            errorMessage: message.isEmpty
                ? 'Failed to refresh providers and models'
                : message,
          );
        },
        (providersResponse) {
          _providers = providersResponse.providers;
          _defaultModels = providersResponse.defaultModels;
          connected = providersResponse.connected;
        },
      );

      if (failed) {
        return;
      }

      await _refreshAgents(serverId: serverId, scopeId: scopeId);
      await _loadModelPreferenceState(serverId: serverId, scopeId: scopeId);
      await _loadSessionSelectionOverridesState(
        serverId: serverId,
        scopeId: scopeId,
      );

      if (_providers.isNotEmpty) {
        _RemoteChatSelection? remoteSelection;
        if (_isExperimentalMultiDeviceSyncEnabled) {
          remoteSelection = await _loadRemoteChatSelection();
          if (remoteSelection != null) {
            _mergeRemoteSessionSelectionOverrides(
              remoteSelection.sessionOverridesBySessionId,
            );
          }
        }

        final persistedProvider = await localDataSource.getSelectedProvider(
          serverId: serverId,
          scopeId: scopeId,
        );
        final persistedModel = await localDataSource.getSelectedModel(
          serverId: serverId,
          scopeId: scopeId,
        );

        Provider? selectedProvider;

        if (remoteSelection != null && remoteSelection.hasModel) {
          final remote = remoteSelection;
          selectedProvider = _providers
              .where((p) => p.id == remote.providerId)
              .firstOrNull;
          if (selectedProvider != null &&
              !selectedProvider.models.containsKey(remote.modelId)) {
            selectedProvider = null;
          }
        }

        if (selectedProvider == null && persistedProvider != null) {
          selectedProvider = _providers
              .where((p) => p.id == persistedProvider)
              .firstOrNull;
        }

        // Try connected providers first
        if (selectedProvider == null) {
          for (final connectedId in connected) {
            selectedProvider = _providers
                .where((p) => p.id == connectedId)
                .firstOrNull;
            if (selectedProvider != null) break;
          }
        }

        // Then try providers from recent usage.
        if (selectedProvider == null) {
          for (final recentModelKey in _recentModelKeys) {
            final providerId = _providerFromModelKey(recentModelKey);
            if (providerId == null) {
              continue;
            }
            selectedProvider = _providers
                .where((p) => p.id == providerId)
                .firstOrNull;
            if (selectedProvider != null) {
              break;
            }
          }
        }

        // Fall back to first available provider
        selectedProvider ??= _providers.first;
        _selectedProviderId = selectedProvider.id;

        if (remoteSelection != null &&
            remoteSelection.hasModel &&
            remoteSelection.providerId == selectedProvider.id &&
            selectedProvider.models.containsKey(remoteSelection.modelId)) {
          _selectedModelId = remoteSelection.modelId;
        } else if (persistedModel != null &&
            selectedProvider.models.containsKey(persistedModel)) {
          _selectedModelId = persistedModel;
        } else {
          for (final recentModelKey in _recentModelKeys) {
            final providerId = _providerFromModelKey(recentModelKey);
            final modelId = _modelFromModelKey(recentModelKey);
            if (providerId != selectedProvider.id || modelId == null) {
              continue;
            }
            if (selectedProvider.models.containsKey(modelId)) {
              _selectedModelId = modelId;
              break;
            }
          }
        }

        if (_selectedModelId == null &&
            selectedProvider.models.isNotEmpty &&
            _modelUsageCounts.isNotEmpty) {
          String? mostUsedModelId;
          var mostUsedCount = -1;
          for (final modelId in selectedProvider.models.keys) {
            final usage =
                _modelUsageCounts[_modelKey(selectedProvider.id, modelId)] ?? 0;
            if (usage > mostUsedCount) {
              mostUsedCount = usage;
              mostUsedModelId = modelId;
            }
          }
          if (mostUsedModelId != null && mostUsedCount > 0) {
            _selectedModelId = mostUsedModelId;
          }
        }

        if (_selectedModelId == null &&
            _defaultModels.containsKey(selectedProvider.id)) {
          final defaultModelId = _defaultModels[selectedProvider.id];
          if (defaultModelId != null &&
              selectedProvider.models.containsKey(defaultModelId)) {
            _selectedModelId = defaultModelId;
          }
        }

        if (_selectedModelId == null && selectedProvider.models.isNotEmpty) {
          _selectedModelId = selectedProvider.models.keys.first;
        }

        final remoteAgentName = remoteSelection?.agentName;
        if (remoteAgentName != null && remoteAgentName.isNotEmpty) {
          final resolvedAgent = _resolvePreferredAgentName(
            _agents,
            remoteAgentName,
          );
          if (resolvedAgent != null) {
            _selectedAgentName = resolvedAgent;
          }
        }

        _selectedVariantId = _resolveStoredVariantForSelection();
        if (remoteSelection != null) {
          _applyRemoteVariantSelection(remoteSelection);
        }
        _applySelectionPriorityForCurrentSession();

        if (_selectedProviderId != null) {
          await localDataSource.saveSelectedProvider(
            _selectedProviderId!,
            serverId: serverId,
            scopeId: scopeId,
          );
        }
        if (_selectedModelId != null) {
          await localDataSource.saveSelectedModel(
            _selectedModelId!,
            serverId: serverId,
            scopeId: scopeId,
          );
        }
        await localDataSource.saveSelectedAgent(
          _selectedAgentName,
          serverId: serverId,
          scopeId: scopeId,
        );
        await _persistModelPreferenceState(
          serverId: serverId,
          scopeId: scopeId,
        );

        if (_selectedProviderId != null && _selectedModelId != null) {
          _lastSyncedRemoteModelKey = _modelKey(
            _selectedProviderId!,
            _selectedModelId!,
          );
        } else {
          _lastSyncedRemoteModelKey = null;
        }
        _lastSyncedRemoteAgentName = _selectedAgentName;
        if (_lastSyncedRemoteVariantKey == null) {
          final modelKey = _currentModelKey();
          final agentName = _selectedAgentName;
          if (modelKey != null && agentName != null && agentName.isNotEmpty) {
            final variantValue =
                (_selectedVariantId == null || _selectedVariantId!.isEmpty)
                ? ChatProvider._remoteAutoVariantValue
                : _selectedVariantId!;
            _lastSyncedRemoteVariantKey = _remoteVariantSyncKey(
              agentName: agentName,
              modelKey: modelKey,
              variantValue: variantValue,
            );
          }
        }
        _lastSyncedRemoteSessionOverridesSignature = _sessionOverridesSignature(
          _sessionOverridesForContext(_activeContextKey),
        );

        AppLogger.debug(
          'Selected agent=$_selectedAgentName provider=$_selectedProviderId model=$_selectedModelId variant=$_selectedVariantId server=$serverId',
        );
      } else {
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
        _selectionSyncTransactionPhase = _SelectionSyncTransactionPhase.idle;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception while initializing providers',
        error: e,
        stackTrace: stackTrace,
      );
      _setProvidersRefreshState(
        ChatProvidersRefreshState.failed,
        errorMessage: 'Failed to refresh providers and models',
      );
    }
    if (fetchId == _providersFetchId) {
      if (_refreshlessRealtimeEnabled && !_isForegroundActive) {
        _setSyncState(ChatSyncState.reconnecting, reason: 'background-init');
      } else {
        await _startRealtimeEventSubscription();
      }
      await _loadPendingInteractions();
      await refreshSessionStatusSnapshot();
      _setProvidersRefreshState(
        ChatProvidersRefreshState.ready,
        errorMessage: null,
        notify: false,
      );
      _notifyListeners();
    }
  }
}
