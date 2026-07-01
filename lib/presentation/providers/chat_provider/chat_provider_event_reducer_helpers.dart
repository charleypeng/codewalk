part of '../chat_provider.dart';

extension _ChatProviderEventReducerHelpers on ChatProvider {
  bool _eventInfoContainsAny(Map<String, dynamic> info, Iterable<String> keys) {
    for (final key in keys) {
      if (info.containsKey(key)) {
        return true;
      }
    }
    return false;
  }

  ChatSession _mergeSessionFromEventInfo({
    required ChatSession incoming,
    required ChatSession? existing,
    required Map<String, dynamic> info,
  }) {
    if (existing == null) {
      return incoming;
    }

    var merged = existing;
    if (info.containsKey('workspaceId')) {
      merged = merged.copyWith(workspaceId: incoming.workspaceId);
    }
    if (info.containsKey('time')) {
      merged = merged.copyWith(
        time: incoming.time,
        archivedAt: incoming.archivedAt,
      );
    }
    if (_eventInfoContainsAny(info, const <String>[
      'title',
      'name',
      'sessionTitle',
    ])) {
      merged = merged.copyWith(title: incoming.title);
    }
    if (_eventInfoContainsAny(info, const <String>['parentID', 'parentId'])) {
      merged = merged.copyWith(parentId: incoming.parentId);
    }
    if (info.containsKey('directory')) {
      merged = merged.copyWith(directory: incoming.directory);
    }
    if (info.containsKey('summary')) {
      merged = merged.copyWith(summary: incoming.summary);
    }
    if (info.containsKey('path')) {
      merged = merged.copyWith(path: incoming.path);
    }
    if (_eventInfoContainsAny(info, const <String>['share', 'shared'])) {
      merged = merged.copyWith(
        shared: incoming.shared,
        shareUrl: incoming.shareUrl,
      );
    }
    if (info.containsKey('revert')) {
      final pendingBranch = _pendingReplacementBranch;
      final incomingRevertId = incoming.revert?.messageId.trim();
      if (pendingBranch == null ||
          pendingBranch.sessionId != merged.id ||
          incomingRevertId != pendingBranch.revertMessageId) {
        merged = merged.copyWith(revert: incoming.revert);
      }
    }
    return merged;
  }

  Map<String, dynamic> _eventPayloadOrNested(
    Map<String, dynamic> properties,
    Iterable<String> nestedKeys,
  ) {
    for (final key in nestedKeys) {
      final nested = properties[key];
      if (nested is Map) {
        return Map<String, dynamic>.from(nested);
      }
    }
    return properties;
  }

  void _refreshPendingInteractionsForEvent(String type) {
    AppLogger.warn(
      'Refreshing pending interactions after unparseable OpenCode event type=$type',
    );
    unawaited(_loadPendingInteractions());
  }

  /// Compose a dedup key from event type + identifying properties.
  /// Returns null for events that cannot be meaningfully deduplicated.
  String? _composeEventDeduplicationKey(ChatEvent event) {
    final props = event.properties;
    final sessionId =
        props['sessionID'] as String? ??
        (props['info'] is Map
            ? (props['info'] as Map)['sessionID'] as String?
            : null);
    final messageId =
        props['messageID'] as String? ??
        (props['info'] is Map ? (props['info'] as Map)['id'] as String? : null);
    final partId =
        (props['part'] is Map
            ? (props['part'] as Map)['id'] as String?
            : null) ??
        props['partID'] as String?;
    final requestId = props['requestID'] as String?;
    // Build composite key from available identifiers
    final segments = <String>[event.type];
    if (sessionId != null) segments.add(sessionId);
    if (messageId != null) segments.add(messageId);
    if (partId != null) segments.add(partId);
    if (requestId != null) segments.add(requestId);
    // Events with only type+session (e.g. session.status) change over time,
    // so skip dedup for events without a fine-grained identifier.
    if (messageId == null && partId == null && requestId == null) return null;
    return segments.join(':');
  }

  /// Returns true if this event was recently processed (duplicate).
  bool _isRecentlyProcessedEvent(ChatEvent event) {
    final key = _composeEventDeduplicationKey(event);
    if (key == null) return false;
    if (_recentEventIds.contains(key)) return true;
    _recentEventIds.addLast(key);
    if (_recentEventIds.length > ChatProvider._maxRecentEventIds) {
      _recentEventIds.removeFirst();
    }
    return false;
  }

  bool _hasInFlightSendTurnForSession(String sessionId) {
    return _currentSession?.id == sessionId &&
        _activeMessageStreamSessionId == sessionId &&
        (_state == ChatState.sending || _messageSubscription != null);
  }

  bool _isNonCurrentSessionEvent(String? sessionId) {
    final normalizedSessionId = sessionId?.trim();
    final currentSessionId = _currentSession?.id.trim();
    if (normalizedSessionId == null || normalizedSessionId.isEmpty) {
      return false;
    }
    return currentSessionId == null ||
        currentSessionId.isEmpty ||
        normalizedSessionId != currentSessionId;
  }

  bool _shouldHandleFeedbackForEvent(ChatEvent event) {
    switch (event.type) {
      case 'permission.asked':
      case 'permission.updated':
      case 'permission.v2.asked':
      case 'permission.v2.updated':
      case 'question.asked':
      case 'question.updated':
      case 'question.v2.asked':
      case 'question.v2.updated':
      case 'session.error':
      case 'session.idle':
        return true;
      default:
        return false;
    }
  }

  bool _shouldSuppressAggressiveDataSaverEvent(
    ChatEvent event,
    String? sessionId,
  ) {
    if (!_cellularDataSaverService.isAggressiveDataSaverActive) {
      return false;
    }
    if (event.type == 'server.connected' || event.type == 'server.heartbeat') {
      return false;
    }
    final affectsSession =
        event.type.startsWith('session.') ||
        event.type.startsWith('message.') ||
        event.type.startsWith('todo.') ||
        event.type.startsWith('permission.') ||
        event.type.startsWith('question.');
    if (!affectsSession) {
      return false;
    }
    if (!_hasVisibleAggressiveDataSaverSession) {
      return true;
    }
    if (sessionId == null || sessionId.trim().isEmpty) {
      return false;
    }
    return !_isVisibleAggressiveSessionId(sessionId);
  }

  bool _isRootSessionInList(String sessionId, List<ChatSession> sessions) {
    for (final session in sessions) {
      if (session.id != sessionId) {
        continue;
      }
      final parentId = session.parentId?.trim();
      return parentId == null || parentId.isEmpty;
    }
    return false;
  }

  ChatEvent? _feedbackEventForCurrentContext(ChatEvent event) {
    if (event.type == 'session.status') {
      final sessionId = event.properties['sessionID'] as String?;
      final statusMap = event.properties['status'];
      if (sessionId == null || statusMap is! Map<String, dynamic>) {
        return null;
      }
      final status = _parseStatusForFeedback(statusMap);
      if (status?.type != SessionStatusType.idle) {
        return null;
      }
      final isVisibleCurrentSession =
          sessionId == _currentSession?.id && _isChatRouteActive;
      if (isVisibleCurrentSession) {
        return null;
      }
      final previousStatusType = _sessionStatusById[sessionId]?.type;
      final completedFromActiveTurn =
          previousStatusType == null ||
          previousStatusType == SessionStatusType.busy ||
          previousStatusType == SessionStatusType.retry;
      if (!completedFromActiveTurn) {
        return null;
      }
      return _sessionIdleFeedbackEventFromStatus(event);
    }

    if (event.type == 'session.idle') {
      final sessionId = event.properties['sessionID'] as String?;
      if (sessionId != null &&
          _sessionStatusById[sessionId]?.type == SessionStatusType.idle &&
          !_sessionErrorAttentionIds.contains(sessionId)) {
        return null;
      }
    }

    return _shouldHandleFeedbackForEvent(event) ? event : null;
  }

  SessionStatusInfo? _parseStatusForFeedback(Map<String, dynamic> statusMap) {
    try {
      return SessionStatusModel.fromJson(statusMap).toDomain();
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Failed to parse session.status feedback event',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  ChatEvent _sessionIdleFeedbackEventFromStatus(ChatEvent event) {
    final properties = Map<String, dynamic>.from(event.properties)
      ..remove('status');
    return ChatEvent(type: 'session.idle', properties: properties);
  }

  ({String message, String? code}) _extractSessionErrorMessageAndCode(
    Map<String, dynamic> properties,
  ) {
    final rawError = properties['error'];
    final error = rawError is Map ? Map<String, dynamic>.from(rawError) : null;
    final dataRaw = error?['data'];
    final data = dataRaw is Map
        ? Map<String, dynamic>.from(dataRaw)
        : const <String, dynamic>{};
    final messageFromData = data['message']?.toString().trim();
    final messageFromError = error?['message']?.toString().trim();
    final messageFromRawError = rawError is String ? rawError.trim() : null;
    final message = (messageFromData != null && messageFromData.isNotEmpty)
        ? messageFromData
        : (messageFromError != null && messageFromError.isNotEmpty)
        ? messageFromError
        : (messageFromRawError != null && messageFromRawError.isNotEmpty)
        ? messageFromRawError
        : 'Session error';
    final code = data['code']?.toString() ?? error?['code']?.toString();
    return (message: message, code: code);
  }
}
