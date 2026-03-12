part of '../chat_provider.dart';

extension _ChatProviderPreferenceOps on ChatProvider {
  List<String> _decodeStoredModelKeys(String? raw, {int? maxItems}) {
    if (raw == null || raw.trim().isEmpty) {
      return <String>[];
    }
    try {
      final decoded = json.decode(raw);
      if (decoded is! List<dynamic>) {
        return <String>[];
      }
      final values = decoded
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
      return maxItems == null ? values : values.take(maxItems).toList();
    } catch (_) {
      return <String>[];
    }
  }

  void _storeCurrentContextSnapshot() {
    _contextSnapshots[_activeContextKey] = _ChatContextSnapshot(
      sessions: _sessions,
      currentSession: _currentSession,
      messages: _messages,
      sessionStatusById: _sessionStatusById,
      pendingPermissionsBySession: _pendingPermissionsBySession,
      pendingQuestionsBySession: _pendingQuestionsBySession,
      sessionUnreadCompletionIds: _sessionUnreadCompletionIds,
      sessionErrorAttentionIds: _sessionErrorAttentionIds,
      sessionChildrenById: _sessionChildrenById,
      sessionTodoById: _sessionTodoById,
      sessionDiffById: _sessionDiffById,
      sessionSearchQuery: _sessionSearchQuery,
      sessionListFilter: _sessionListFilter,
      sessionListSort: _sessionListSort,
      pinnedSessionIds: Set<String>.from(_pinnedSessionIds),
      sessionVisibleLimit: _sessionVisibleLimit,
      isNewChatDraftActive: _isNewChatDraftActive,
      activeSendDraft: _activeSendDraft,
      rejectedDraft: _rejectedDraft,
    );
  }

  void _restoreContextSnapshot(String contextKey) {
    final snapshot = _contextSnapshots[contextKey];
    if (snapshot == null) {
      _sessions = <ChatSession>[];
      _currentSession = null;
      _messages = <ChatMessage>[];
      _messagesVersion++;
      _sessionStatusById = <String, SessionStatusInfo>{};
      _pendingPermissionsBySession = <String, List<ChatPermissionRequest>>{};
      _pendingQuestionsBySession = <String, List<ChatQuestionRequest>>{};
      _sessionUnreadCompletionIds.clear();
      _sessionErrorAttentionIds.clear();
      _sessionChildrenById = <String, List<ChatSession>>{};
      _sessionTodoById = <String, List<SessionTodo>>{};
      _sessionDiffById = <String, List<SessionDiff>>{};
      _sessionSearchQuery = '';
      _sessionListFilter = SessionListFilter.active;
      _sessionListSort = SessionListSort.recent;
      _pinnedSessionIds = <String>{};
      _sessionVisibleLimit = 40;
      _isNewChatDraftActive = false;
      _clearActiveSendDraft();
      _clearRejectedDraft();
      _threadPermissionsVersion++;
      return;
    }

    _sessions = _filterSessionsForCurrentContext(snapshot.sessions);
    _currentSession = snapshot.currentSession;
    _messages = snapshot.messages;
    final restoredSessionId = _currentSession?.id;
    if (restoredSessionId != null && restoredSessionId.trim().isNotEmpty) {
      _cacheSessionMessages(restoredSessionId, _messages);
    }
    _messagesVersion++;
    _pendingLocalUserMessageIds.clear();
    _sessionStatusById = snapshot.sessionStatusById;
    _pendingPermissionsBySession = snapshot.pendingPermissionsBySession;
    _pendingQuestionsBySession = snapshot.pendingQuestionsBySession;
    _sessionUnreadCompletionIds
      ..clear()
      ..addAll(snapshot.sessionUnreadCompletionIds);
    _sessionErrorAttentionIds
      ..clear()
      ..addAll(snapshot.sessionErrorAttentionIds);
    _sessionChildrenById = snapshot.sessionChildrenById;
    _sessionTodoById = snapshot.sessionTodoById;
    _sessionDiffById = snapshot.sessionDiffById;
    _sessionSearchQuery = snapshot.sessionSearchQuery;
    _sessionListFilter = snapshot.sessionListFilter;
    _sessionListSort = snapshot.sessionListSort;
    _pinnedSessionIds = Set<String>.from(snapshot.pinnedSessionIds);
    _sessionVisibleLimit = snapshot.sessionVisibleLimit;
    _isNewChatDraftActive = snapshot.isNewChatDraftActive;
    _activeSendDraft = snapshot.activeSendDraft;
    _rejectedDraft = snapshot.rejectedDraft;
    _pruneSessionAttentionStateToKnownSessions();
    _threadPermissionsVersion++;
  }

  Future<void> _loadModelPreferenceState({
    required String serverId,
    required String scopeId,
  }) async {
    _recentModelKeys = <String>[];
    _favoriteModelKeys = <String>[];
    _pinnedSessionIds = <String>{};
    _modelUsageCounts = <String, int>{};
    _selectedVariantByModel = <String, String>{};

    final recentJson = await localDataSource.getRecentModelsJson(
      serverId: serverId,
      scopeId: scopeId,
    );
    _recentModelKeys = _decodeStoredModelKeys(
      recentJson,
      maxItems: ChatProvider._maxRecentModels,
    );

    final favoritesJson = await localDataSource.getFavoriteModelsJson(
      serverId: serverId,
    );
    _favoriteModelKeys = _decodeStoredModelKeys(favoritesJson);
    if (_favoriteModelKeys.isEmpty) {
      final legacyFavorites = await localDataSource
          .getLegacyFavoriteModelsJsonForServer(serverId);
      if (legacyFavorites.isNotEmpty) {
        final mergedFavorites = <String>{};
        for (final legacyRaw in legacyFavorites) {
          mergedFavorites.addAll(_decodeStoredModelKeys(legacyRaw));
        }
        _favoriteModelKeys = mergedFavorites.toList(growable: false);
        if (_favoriteModelKeys.isNotEmpty) {
          await localDataSource.saveFavoriteModelsJson(
            json.encode(_favoriteModelKeys),
            serverId: serverId,
          );
          await localDataSource.deleteLegacyFavoriteModelsJsonForServer(
            serverId,
          );
        }
      }
    }

    final pinnedJson = await localDataSource.getPinnedSessionsJson(
      serverId: serverId,
      scopeId: scopeId,
    );
    if (pinnedJson != null && pinnedJson.trim().isNotEmpty) {
      try {
        final decoded = json.decode(pinnedJson);
        if (decoded is List<dynamic>) {
          _pinnedSessionIds = decoded
              .whereType<String>()
              .where((value) => value.trim().isNotEmpty)
              .toSet();
        }
      } catch (error, stackTrace) {
        AppLogger.warn(
          'Failed to restore pinned sessions preferences',
          error: error,
          stackTrace: stackTrace,
        );
        _pinnedSessionIds = <String>{};
      }
    }

    final usageJson = await localDataSource.getModelUsageCountsJson(
      serverId: serverId,
      scopeId: scopeId,
    );
    if (usageJson != null && usageJson.trim().isNotEmpty) {
      try {
        final decoded = json.decode(usageJson);
        if (decoded is Map<String, dynamic>) {
          _modelUsageCounts = decoded.map(
            (key, value) => MapEntry(
              key,
              value is num ? value.toInt() : int.tryParse('$value') ?? 0,
            ),
          );
          _modelUsageCounts.removeWhere((_, value) => value <= 0);
        }
      } catch (_) {
        _modelUsageCounts = <String, int>{};
      }
    }

    final variantsJson = await localDataSource.getSelectedVariantMap(
      serverId: serverId,
      scopeId: scopeId,
    );
    if (variantsJson != null && variantsJson.trim().isNotEmpty) {
      try {
        final decoded = json.decode(variantsJson);
        if (decoded is Map<String, dynamic>) {
          _selectedVariantByModel = decoded.map(
            (key, value) => MapEntry(key, '$value'),
          );
          _selectedVariantByModel.removeWhere(
            (_, value) => value.trim().isEmpty,
          );
        }
      } catch (_) {
        _selectedVariantByModel = <String, String>{};
      }
    }
  }

  Future<void> _persistModelPreferenceState({
    required String serverId,
    required String scopeId,
  }) async {
    await localDataSource.saveRecentModelsJson(
      json.encode(_recentModelKeys),
      serverId: serverId,
      scopeId: scopeId,
    );
    await localDataSource.saveFavoriteModelsJson(
      json.encode(_favoriteModelKeys),
      serverId: serverId,
    );
    await localDataSource.savePinnedSessionsJson(
      json.encode(_pinnedSessionIds.toList(growable: false)),
      serverId: serverId,
      scopeId: scopeId,
    );
    await localDataSource.saveModelUsageCountsJson(
      json.encode(_modelUsageCounts),
      serverId: serverId,
      scopeId: scopeId,
    );
    await localDataSource.saveSelectedVariantMap(
      json.encode(_selectedVariantByModel),
      serverId: serverId,
      scopeId: scopeId,
    );
  }

  void _recordModelUsage() {
    final providerId = _selectedProviderId;
    final modelId = _selectedModelId;
    if (providerId == null || modelId == null) {
      return;
    }
    _recentModelKeys = List<String>.from(_recentModelKeys);
    final key = _modelKey(providerId, modelId);
    _recentModelKeys.remove(key);
    _recentModelKeys.insert(0, key);
    if (_recentModelKeys.length > ChatProvider._maxRecentModels) {
      _recentModelKeys = _recentModelKeys
          .take(ChatProvider._maxRecentModels)
          .toList();
    }
    _modelUsageCounts[key] = (_modelUsageCounts[key] ?? 0) + 1;
  }
}
