part of '../chat_provider.dart';

extension _ChatProviderCachePersistenceOps on ChatProvider {
  void _cacheSessionMessages(String sessionId, List<ChatMessage> messages) {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return;
    }
    final filtered = messages
        .where((message) => message.sessionId == normalizedSessionId)
        .toList(growable: false);
    if (filtered.isEmpty) {
      _sessionMessagesLruCache.remove(normalizedSessionId);
      return;
    }

    _sessionMessagesLruCache.remove(normalizedSessionId);
    _sessionMessagesLruCache[normalizedSessionId] = filtered;
    while (_sessionMessagesLruCache.length >
        ChatProvider._maxSessionMessageCacheEntries) {
      _sessionMessagesLruCache.remove(_sessionMessagesLruCache.keys.first);
    }
  }

  List<ChatMessage>? _cachedSessionMessages(String sessionId) {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return null;
    }
    final cached = _sessionMessagesLruCache.remove(normalizedSessionId);
    if (cached == null) {
      return null;
    }
    _sessionMessagesLruCache[normalizedSessionId] = cached;
    return List<ChatMessage>.from(cached);
  }

  void _removeSessionMessagesCache(String sessionId) {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return;
    }
    _sessionMessagesLruCache.remove(normalizedSessionId);
  }

  Future<void> _persistSessionMessagesSnapshotBestEffort(
    String sessionId,
    List<ChatMessage> messages, {
    String? serverId,
    String? scopeId,
  }) async {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return;
    }
    final filteredMessages = messages
        .where((message) => message.sessionId == normalizedSessionId)
        .toList(growable: false);
    if (filteredMessages.isEmpty) {
      return;
    }

    try {
      final resolvedServerId = serverId ?? await _resolveServerIdForStorage();
      final resolvedScopeId = scopeId ?? _resolveContextScopeId();
      final payload = <String, dynamic>{
        'sessionId': normalizedSessionId,
        'messages': filteredMessages
            .map((message) => ChatMessageModel.fromDomain(message).toJson())
            .toList(growable: false),
      };
      await localDataSource.saveSessionMessagesSnapshot(
        json.encode(payload),
        sessionId: normalizedSessionId,
        serverId: resolvedServerId,
        scopeId: resolvedScopeId,
      );
      await localDataSource.saveSessionMessagesSnapshotUpdatedAt(
        DateTime.now().millisecondsSinceEpoch,
        sessionId: normalizedSessionId,
        serverId: resolvedServerId,
        scopeId: resolvedScopeId,
      );

      await _touchPersistedSessionMessagesSnapshotId(
        normalizedSessionId,
        serverId: resolvedServerId,
        scopeId: resolvedScopeId,
      );
    } catch (e, stackTrace) {
      AppLogger.warn(
        'Failed to persist per-session message snapshot session=$normalizedSessionId',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _touchPersistedSessionMessagesSnapshotId(
    String sessionId, {
    required String serverId,
    required String scopeId,
  }) async {
    final existingRaw = await localDataSource.getSessionMessagesSnapshotIds(
      serverId: serverId,
      scopeId: scopeId,
    );
    var existing = <String>[];
    if (existingRaw != null && existingRaw.trim().isNotEmpty) {
      try {
        final decoded = json.decode(existingRaw);
        if (decoded is List) {
          existing = decoded
              .whereType<String>()
              .map((id) => id.trim())
              .where((id) => id.isNotEmpty)
              .toList(growable: true);
        }
      } catch (_) {
        existing = <String>[];
      }
    }

    existing.remove(sessionId);
    existing.add(sessionId);
    while (existing.length >
        ChatProvider._maxPersistedSessionMessageSnapshots) {
      final removed = existing.removeAt(0);
      await localDataSource.clearSessionMessagesSnapshot(
        sessionId: removed,
        serverId: serverId,
        scopeId: scopeId,
      );
    }

    await localDataSource.saveSessionMessagesSnapshotIds(
      json.encode(existing),
      serverId: serverId,
      scopeId: scopeId,
    );
  }

  Future<List<ChatMessage>?> _restoreSessionMessagesSnapshot(
    String sessionId, {
    required String serverId,
    required String scopeId,
  }) async {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return null;
    }

    try {
      final snapshotJson = await localDataSource.getSessionMessagesSnapshot(
        sessionId: normalizedSessionId,
        serverId: serverId,
        scopeId: scopeId,
      );
      if (snapshotJson == null || snapshotJson.trim().isEmpty) {
        return null;
      }

      final updatedAtMs = await localDataSource
          .getSessionMessagesSnapshotUpdatedAt(
            sessionId: normalizedSessionId,
            serverId: serverId,
            scopeId: scopeId,
          );
      final isFresh =
          updatedAtMs != null &&
          DateTime.now().difference(
                DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
              ) <=
              ChatProvider._sessionMessagesSnapshotTtl;

      final decoded = json.decode(snapshotJson);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final messagesJson = decoded['messages'];
      if (messagesJson is! List) {
        return null;
      }
      final messages = messagesJson
          .whereType<Map<String, dynamic>>()
          .map((item) => ChatMessageModel.fromJson(item).toDomain())
          .where((message) => message.sessionId == normalizedSessionId)
          .toList(growable: false);
      if (messages.isEmpty) {
        return null;
      }

      if (!isFresh) {
        AppLogger.info(
          'Per-session message snapshot is stale (> ${ChatProvider._sessionMessagesSnapshotTtl.inDays} days) session=$normalizedSessionId',
        );
      }
      return messages;
    } catch (e, stackTrace) {
      AppLogger.warn(
        'Failed to restore per-session message snapshot session=$normalizedSessionId',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<List<ChatMessage>?> _restoreSessionMessagesFromCache(
    String sessionId, {
    required String serverId,
    required String scopeId,
  }) async {
    final inMemory = _cachedSessionMessages(sessionId);
    if (inMemory != null && inMemory.isNotEmpty) {
      return inMemory;
    }
    final fromDisk = await _restoreSessionMessagesSnapshot(
      sessionId,
      serverId: serverId,
      scopeId: scopeId,
    );
    if (fromDisk == null || fromDisk.isEmpty) {
      return null;
    }
    _cacheSessionMessages(sessionId, fromDisk);
    return fromDisk;
  }

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
      _cacheSessionMessages(selectedSession.id, cachedMessages);
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
      _cacheSessionMessages(current.id, _messages);
      await _persistSessionMessagesSnapshotBestEffort(
        current.id,
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

  Future<void> _clearSessionMessagesSnapshotBestEffort(
    String sessionId, {
    String? serverId,
    String? scopeId,
  }) async {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return;
    }
    try {
      final resolvedServerId = serverId ?? await _resolveServerIdForStorage();
      final resolvedScopeId = scopeId ?? _resolveContextScopeId();
      await localDataSource.clearSessionMessagesSnapshot(
        sessionId: normalizedSessionId,
        serverId: resolvedServerId,
        scopeId: resolvedScopeId,
      );

      final snapshotIdsRaw = await localDataSource
          .getSessionMessagesSnapshotIds(
            serverId: resolvedServerId,
            scopeId: resolvedScopeId,
          );
      if (snapshotIdsRaw != null && snapshotIdsRaw.trim().isNotEmpty) {
        try {
          final decoded = json.decode(snapshotIdsRaw);
          if (decoded is List) {
            final nextIds = decoded
                .whereType<String>()
                .map((id) => id.trim())
                .where((id) => id.isNotEmpty && id != normalizedSessionId)
                .toList(growable: false);
            await localDataSource.saveSessionMessagesSnapshotIds(
              json.encode(nextIds),
              serverId: resolvedServerId,
              scopeId: resolvedScopeId,
            );
          }
        } catch (_) {
          // Ignore malformed snapshot ID payloads during cleanup.
        }
      }
    } catch (e, stackTrace) {
      AppLogger.warn(
        'Failed to clear per-session message snapshot session=$normalizedSessionId',
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
