part of '../chat_provider.dart';

extension _ChatProviderCorePart on ChatProvider {
  void _applyProviderCatalogSnapshot(
    _ProviderCatalogSnapshot snapshot, {
    bool notify = true,
  }) {
    _providers = snapshot.providers;
    _defaultModels = snapshot.defaultModels;
    _connectedProviderIds = snapshot.connected;
    if (notify) {
      _notifyListeners();
    }
  }

  String _encodeProviderCatalogSnapshotJson(_ProviderCatalogSnapshot snapshot) {
    final payload = <String, dynamic>{
      'providers': snapshot.providers
          .map(_providerCatalogProviderToJson)
          .toList(),
      'default': snapshot.defaultModels,
      'connected': snapshot.connected,
    };
    return json.encode(payload);
  }

  Map<String, dynamic> _providerCatalogProviderToJson(Provider provider) {
    return <String, dynamic>{
      'id': provider.id,
      'name': provider.name,
      'env': provider.env,
      'api': provider.api,
      'npm': provider.npm,
      'models': provider.models.map(
        (key, value) => MapEntry(key, _providerCatalogModelToJson(value)),
      ),
    };
  }

  Map<String, dynamic> _providerCatalogModelToJson(Model model) {
    return <String, dynamic>{
      'id': model.id,
      'name': model.name,
      'release_date': model.releaseDate,
      'attachment': model.attachment,
      'reasoning': model.reasoning,
      'temperature': model.temperature,
      'tool_call': model.toolCall,
      'cost': <String, dynamic>{
        'input': model.cost.input,
        'output': model.cost.output,
        'cache_read': model.cost.cacheRead,
        'cache_write': model.cost.cacheWrite,
      },
      'limit': <String, dynamic>{
        'context': model.limit.context,
        'output': model.limit.output,
      },
      'options': model.options,
      'variants': model.variants.map(
        (key, value) => MapEntry(key, <String, dynamic>{
          'name': value.name,
          'description': value.description,
          'metadata': value.metadata,
        }),
      ),
      'knowledge': model.knowledge,
      'last_updated': model.lastUpdated,
      'modalities': model.modalities,
      'open_weights': model.openWeights,
    };
  }

  _ProviderCatalogSnapshot? _decodeProviderCatalogSnapshot(String raw) {
    if (raw.trim().isEmpty) {
      return null;
    }
    final decoded = json.decode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final response = ProvidersResponseModel.fromJson(decoded).toDomain();
    return _ProviderCatalogSnapshot(
      providers: response.providers,
      defaultModels: response.defaultModels,
      connected: response.connected,
    );
  }

  Future<bool> _restoreProviderCatalogSnapshot({
    required String serverId,
    bool notify = true,
  }) async {
    final raw = await localDataSource.getProviderCatalogCacheJson(
      serverId: serverId,
    );
    if (raw == null || raw.trim().isEmpty) {
      return false;
    }
    try {
      final snapshot = _decodeProviderCatalogSnapshot(raw);
      if (snapshot == null || snapshot.isEmpty) {
        return false;
      }
      _applyProviderCatalogSnapshot(snapshot, notify: notify);
      return true;
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Failed to restore cached provider catalog',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> _persistProviderCatalogSnapshot({
    required String serverId,
  }) async {
    if (serverId.trim().isEmpty || _providers.isEmpty) {
      return;
    }
    final snapshot = _ProviderCatalogSnapshot(
      providers: _providers,
      defaultModels: _defaultModels,
      connected: _connectedProviderIds,
    );
    await localDataSource.saveProviderCatalogCacheJson(
      _encodeProviderCatalogSnapshotJson(snapshot),
      serverId: serverId,
    );
  }

  Future<void> _initializeProvidersInternal() async {
    if (!_featureFlagLogged) {
      _featureFlagLogged = true;
      AppLogger.info(
        'refreshless_feature_enabled=$_refreshlessRealtimeEnabled',
      );
    }
    final serverId = await _resolveServerScopeId();
    final hadVisibleCatalog =
        _providers.isNotEmpty ||
        await _restoreProviderCatalogSnapshot(serverId: serverId);
    _setProvidersRefreshState(
      ChatProvidersRefreshState.loading,
      errorMessage: null,
      notify: !hadVisibleCatalog,
    );
    final fetchId = ++_providersFetchId;
    final scopeId = _resolveContextScopeId();
    try {
      var failed = false;
      var connected = List<String>.from(_connectedProviderIds);
      final result = await getProviders(
        directory: projectProvider.currentDirectory,
      );
      if (fetchId != _providersFetchId) {
        return;
      }
      result.fold(
        (failure) {
          AppLogger.warn('Failed to load providers: ${failure.toString()}');
          final message = failure.message.trim();
          if (_providers.isEmpty) {
            failed = true;
            _setProvidersRefreshState(
              ChatProvidersRefreshState.failed,
              errorMessage: message.isEmpty
                  ? 'Failed to refresh providers and models'
                  : message,
            );
          }
        },
        (providersResponse) {
          _providers = providersResponse.providers;
          _defaultModels = providersResponse.defaultModels;
          _connectedProviderIds = List<String>.from(
            providersResponse.connected,
          );
          connected = providersResponse.connected;
        },
      );

      if (failed) {
        return;
      }

      if (_providers.isNotEmpty) {
        await _persistProviderCatalogSnapshot(serverId: serverId);
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
            selectedProvider.id == 'opencode' &&
            selectedProvider.models.containsKey('big-pickle')) {
          _selectedModelId = 'big-pickle';
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
        _connectedProviderIds = <String>[];
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
      } else if (_cellularDataSaverService.isDataSaverActive &&
          !_shouldKeepRealtimeActiveForDataSaver) {
        _idleRealtimePausedForDataSaver = true;
        _setSyncState(ChatSyncState.connected, reason: 'data-saver-init');
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
