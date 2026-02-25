part of '../chat_provider.dart';

extension _ChatProviderCachePersistenceOps on ChatProvider {
  void _sortSessionsInPlace() {
    _sessions.sort((a, b) {
      if (_sessionListSort == SessionListSort.oldest) {
        return a.time.compareTo(b.time);
      }
      if (_sessionListSort == SessionListSort.title) {
        return (a.title ?? '').toLowerCase().compareTo(
          (b.title ?? '').toLowerCase(),
        );
      }
      return b.time.compareTo(a.time);
    });
  }

  Future<void> _loadCachedSessions({
    required String serverId,
    required String scopeId,
  }) async {
    try {
      final cachedData = await localDataSource.getCachedSessions(
        serverId: serverId,
        scopeId: scopeId,
      );
      final cachedAtMs = await localDataSource.getCachedSessionsUpdatedAt(
        serverId: serverId,
        scopeId: scopeId,
      );
      final isFresh =
          cachedAtMs != null &&
          DateTime.now().difference(
                DateTime.fromMillisecondsSinceEpoch(cachedAtMs),
              ) <=
              ChatProvider._sessionsCacheTtl;
      if (cachedData != null) {
        final List<dynamic> jsonList = json.decode(cachedData);
        final cachedSessions = _filterSessionsForCurrentContext(
          jsonList
              .map((json) => ChatSessionModel.fromJson(json).toDomain())
              .toList(),
        );

        if (cachedSessions.isNotEmpty) {
          _allSessions = cachedSessions;
          _sessions = cachedSessions;
          _threadPermissionsVersion++;
          _sortSessionsInPlace();
          _setState(ChatState.loaded);
          if (!isFresh) {
            AppLogger.info(
              'Session cache is stale (> ${ChatProvider._sessionsCacheTtl.inDays} days). Refreshing from server.',
            );
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.warn(
        'Failed to load cached sessions',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _saveCachedSessions(
    List<ChatSession> sessions, {
    required String serverId,
    required String scopeId,
  }) async {
    try {
      final jsonList = sessions
          .map((session) => ChatSessionModel.fromDomain(session).toJson())
          .toList();
      final jsonString = json.encode(jsonList);
      await localDataSource.saveCachedSessions(
        jsonString,
        serverId: serverId,
        scopeId: scopeId,
      );
      await localDataSource.saveCachedSessionsUpdatedAt(
        DateTime.now().millisecondsSinceEpoch,
        serverId: serverId,
        scopeId: scopeId,
      );
    } catch (e, stackTrace) {
      AppLogger.warn(
        'Failed to save session cache',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _restoreLastSessionSnapshotFromCache({
    required String serverId,
    required String scopeId,
    required String? preferredSessionId,
  }) async {
    try {
      final snapshotJson = await localDataSource.getLastSessionSnapshot(
        serverId: serverId,
        scopeId: scopeId,
      );
      if (snapshotJson == null || snapshotJson.trim().isEmpty) {
        return;
      }

      final updatedAtMs = await localDataSource.getLastSessionSnapshotUpdatedAt(
        serverId: serverId,
        scopeId: scopeId,
      );
      final isFresh =
          updatedAtMs != null &&
          DateTime.now().difference(
                DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
              ) <=
              ChatProvider._lastSessionSnapshotTtl;

      final decoded = json.decode(snapshotJson);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final sessionJson = decoded['session'];
      final messagesJson = decoded['messages'];
      if (sessionJson is! Map<String, dynamic> || messagesJson is! List) {
        return;
      }

      final session = ChatSessionModel.fromJson(sessionJson).toDomain();
      if (_filterSessionsForCurrentContext(<ChatSession>[session]).isEmpty) {
        return;
      }

      if (preferredSessionId != null &&
          preferredSessionId.trim().isNotEmpty &&
          preferredSessionId != session.id) {
        return;
      }

      // Guard against overwriting a session that was already switched
      // in memory by selectSession() during the async cache read above.
      final inMemoryId = _currentSession?.id;
      if (inMemoryId != null &&
          inMemoryId.trim().isNotEmpty &&
          inMemoryId != session.id) {
        return;
      }

      final selectedSession =
          _sessions.where((item) => item.id == session.id).firstOrNull ??
          session;
      final cachedMessages = messagesJson
          .whereType<Map<String, dynamic>>()
          .map((item) => ChatMessageModel.fromJson(item).toDomain())
          .where((message) => message.sessionId == selectedSession.id)
          .toList(growable: false);
      if (cachedMessages.isEmpty) {
        return;
      }

      _currentSession = selectedSession;
      _threadPermissionsVersion++;
      _messages = cachedMessages;
      _messagesVersion++;
      _pendingLocalUserMessageIds.clear();
      _clearQueuedSendState();
      _setState(ChatState.loaded);

      if (!isFresh) {
        AppLogger.info(
          'Last session snapshot is stale (> ${ChatProvider._lastSessionSnapshotTtl.inDays} days). Revalidating in background.',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.warn(
        'Failed to restore last session snapshot',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _saveLastSessionSnapshot(
    ChatSession session,
    List<ChatMessage> messages, {
    required String serverId,
    required String scopeId,
  }) async {
    final payload = <String, dynamic>{
      'session': ChatSessionModel.fromDomain(session).toJson(),
      'messages': messages
          .map((message) => ChatMessageModel.fromDomain(message).toJson())
          .toList(growable: false),
    };
    await localDataSource.saveLastSessionSnapshot(
      json.encode(payload),
      serverId: serverId,
      scopeId: scopeId,
    );
    await localDataSource.saveLastSessionSnapshotUpdatedAt(
      DateTime.now().millisecondsSinceEpoch,
      serverId: serverId,
      scopeId: scopeId,
    );
  }

  Future<void> _persistLastSessionSnapshotBestEffort({
    String? serverId,
    String? scopeId,
  }) async {
    try {
      final current = _currentSession;
      if (current == null) {
        return;
      }
      final resolvedServerId = serverId ?? await _resolveServerIdForStorage();
      final resolvedScopeId = scopeId ?? _resolveContextScopeId();
      await _saveLastSessionSnapshot(
        current,
        _messages,
        serverId: resolvedServerId,
        scopeId: resolvedScopeId,
      );
    } catch (e, stackTrace) {
      AppLogger.warn(
        'Failed to persist last session snapshot',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _clearLastSessionSnapshotBestEffort({
    String? serverId,
    String? scopeId,
  }) async {
    try {
      final resolvedServerId = serverId ?? await _resolveServerIdForStorage();
      final resolvedScopeId = scopeId ?? _resolveContextScopeId();
      await localDataSource.clearLastSessionSnapshot(
        serverId: resolvedServerId,
        scopeId: resolvedScopeId,
      );
    } catch (e, stackTrace) {
      AppLogger.warn(
        'Failed to clear last session snapshot',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _persistSessionCacheBestEffort() async {
    try {
      final serverId = await _resolveServerIdForStorage();
      final scopeId = _resolveContextScopeId();
      await _saveCachedSessions(
        _sessions,
        serverId: serverId,
        scopeId: scopeId,
      );
    } catch (e, stackTrace) {
      AppLogger.warn(
        'Failed to persist sessions cache',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<String> _resolveServerIdForStorage() async {
    final stored = await localDataSource.getActiveServerId();
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim();
    }
    final current = _activeServerId.trim();
    if (current.isNotEmpty) {
      return current;
    }
    return 'legacy';
  }

  Future<void> _saveCurrentSessionId(
    String sessionId, {
    required String serverId,
    required String scopeId,
  }) async {
    try {
      await localDataSource.saveCurrentSessionId(
        sessionId,
        serverId: serverId,
        scopeId: scopeId,
      );
    } catch (e, stackTrace) {
      AppLogger.warn(
        'Failed to save current session ID',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
