part of '../chat_provider.dart';

extension _ChatProviderPreferenceOps on ChatProvider {
  void _storeCurrentContextSnapshot() {
    _contextSnapshots[_activeContextKey] = _ChatContextSnapshot(
      sessions: _sessions,
      currentSession: _currentSession,
      messages: _messages,
      sessionStatusById: _sessionStatusById,
      pendingPermissionsBySession: _pendingPermissionsBySession,
      pendingQuestionsBySession: _pendingQuestionsBySession,
      sessionChildrenById: _sessionChildrenById,
      sessionTodoById: _sessionTodoById,
      sessionDiffById: _sessionDiffById,
      sessionSearchQuery: _sessionSearchQuery,
      sessionListFilter: _sessionListFilter,
      sessionListSort: _sessionListSort,
      sessionVisibleLimit: _sessionVisibleLimit,
    );
  }

  void _restoreContextSnapshot(String contextKey) {
    final snapshot = _contextSnapshots[contextKey];
    if (snapshot == null) {
      _sessions = <ChatSession>[];
      _currentSession = null;
      _messages = <ChatMessage>[];
      _sessionStatusById = <String, SessionStatusInfo>{};
      _pendingPermissionsBySession = <String, List<ChatPermissionRequest>>{};
      _pendingQuestionsBySession = <String, List<ChatQuestionRequest>>{};
      _sessionChildrenById = <String, List<ChatSession>>{};
      _sessionTodoById = <String, List<SessionTodo>>{};
      _sessionDiffById = <String, List<SessionDiff>>{};
      _sessionSearchQuery = '';
      _sessionListFilter = SessionListFilter.active;
      _sessionListSort = SessionListSort.recent;
      _sessionVisibleLimit = 40;
      return;
    }

    _sessions = _filterSessionsForCurrentContext(snapshot.sessions);
    _currentSession = snapshot.currentSession;
    _messages = snapshot.messages;
    _pendingLocalUserMessageIds.clear();
    _sessionStatusById = snapshot.sessionStatusById;
    _pendingPermissionsBySession = snapshot.pendingPermissionsBySession;
    _pendingQuestionsBySession = snapshot.pendingQuestionsBySession;
    _sessionChildrenById = snapshot.sessionChildrenById;
    _sessionTodoById = snapshot.sessionTodoById;
    _sessionDiffById = snapshot.sessionDiffById;
    _sessionSearchQuery = snapshot.sessionSearchQuery;
    _sessionListFilter = snapshot.sessionListFilter;
    _sessionListSort = snapshot.sessionListSort;
    _sessionVisibleLimit = snapshot.sessionVisibleLimit;
  }

  Future<void> _loadModelPreferenceState({
    required String serverId,
    required String scopeId,
  }) async {
    _recentModelKeys = <String>[];
    _favoriteModelKeys = <String>[];
    _modelUsageCounts = <String, int>{};
    _selectedVariantByModel = <String, String>{};

    final recentJson = await localDataSource.getRecentModelsJson(
      serverId: serverId,
      scopeId: scopeId,
    );
    if (recentJson != null && recentJson.trim().isNotEmpty) {
      try {
        final decoded = json.decode(recentJson);
        if (decoded is List<dynamic>) {
          _recentModelKeys = decoded
              .whereType<String>()
              .where((value) => value.trim().isNotEmpty)
              .take(ChatProvider._maxRecentModels)
              .toList();
        }
      } catch (_) {
        _recentModelKeys = <String>[];
      }
    }

    final favoritesJson = await localDataSource.getFavoriteModelsJson(
      serverId: serverId,
      scopeId: scopeId,
    );
    if (favoritesJson != null && favoritesJson.trim().isNotEmpty) {
      try {
        final decoded = json.decode(favoritesJson);
        if (decoded is List<dynamic>) {
          _favoriteModelKeys = decoded
              .whereType<String>()
              .where((value) => value.trim().isNotEmpty)
              .toList();
        }
      } catch (_) {
        _favoriteModelKeys = <String>[];
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
