part of '../chat_provider.dart';

extension ChatProviderSessionAttentionOps on ChatProvider {
  bool isSessionActivelyResponding(String sessionId) {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return false;
    }
    final isCurrentSession = _currentSession?.id == normalizedSessionId;
    final hasInProgressAssistant = _messages.whereType<AssistantMessage>().any(
      (message) =>
          message.sessionId == normalizedSessionId && !message.isCompleted,
    );
    final status = _sessionStatusById[normalizedSessionId]?.type;
    final hasBusyStatus =
        status == SessionStatusType.busy || status == SessionStatusType.retry;
    final hasActiveStream =
        _activeMessageStreamSessionId == normalizedSessionId &&
        _messageSubscription != null;

    if (!isCurrentSession) {
      return hasBusyStatus;
    }

    if (hasActiveStream) {
      return true;
    }

    if (_state == ChatState.sending) {
      return true;
    }

    if (hasInProgressAssistant) {
      return true;
    }

    if (!hasBusyStatus) {
      return false;
    }

    ChatMessage? latestSessionMessage;
    for (var index = _messages.length - 1; index >= 0; index -= 1) {
      final candidate = _messages[index];
      if (candidate.sessionId == normalizedSessionId) {
        latestSessionMessage = candidate;
        break;
      }
    }

    if (latestSessionMessage == null) {
      return false;
    }

    if (latestSessionMessage is UserMessage) {
      return true;
    }

    if (latestSessionMessage is! AssistantMessage) {
      return true;
    }

    final hasToolSurfacePart = latestSessionMessage.parts.any(
      (part) => part is ToolPart || part is PatchPart,
    );

    // Keep the active session in responding mode for busy tool-only turns
    // where step chunks can be emitted as completed assistant messages.
    return hasToolSurfacePart;
  }

  bool get isCurrentSessionActivelyResponding {
    final sessionId = _currentSession?.id;
    if (sessionId == null) {
      return false;
    }
    return isSessionActivelyResponding(sessionId);
  }

  SessionAttentionState sessionAttentionForScope(
    String sessionId, {
    required String scopeId,
  }) {
    final normalizedScopeId = scopeId.trim();
    if (normalizedScopeId.isEmpty) {
      return sessionAttentionFor(sessionId);
    }
    final contextKey = _composeContextKey(_activeServerId, normalizedScopeId);
    if (contextKey == _activeContextKey) {
      return sessionAttentionFor(sessionId);
    }

    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return const SessionAttentionState();
    }

    final snapshot = _contextSnapshots[contextKey];
    if (snapshot == null) {
      return const SessionAttentionState();
    }

    final statusType = snapshot.sessionStatusById[normalizedSessionId]?.type;
    final hasPendingPermission =
        (snapshot
            .pendingPermissionsBySession[normalizedSessionId]
            ?.isNotEmpty ??
        false);
    final hasPendingQuestion =
        (snapshot.pendingQuestionsBySession[normalizedSessionId]?.isNotEmpty ??
        false);

    return SessionAttentionState(
      isActive:
          statusType == SessionStatusType.busy ||
          statusType == SessionStatusType.retry,
      hasPendingInteraction: hasPendingPermission || hasPendingQuestion,
      hasError: snapshot.sessionErrorAttentionIds.contains(normalizedSessionId),
      hasUnreadCompletion: snapshot.sessionUnreadCompletionIds.contains(
        normalizedSessionId,
      ),
      unreadCompletionAt:
          snapshot.sessionUnreadCompletionTimestamps[normalizedSessionId],
    );
  }

  SessionAttentionState sessionAttentionFor(String sessionId) {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return const SessionAttentionState();
    }

    final hasPendingPermission =
        (_pendingPermissionsBySession[normalizedSessionId]?.isNotEmpty ??
        false);
    final hasPendingQuestion =
        (_pendingQuestionsBySession[normalizedSessionId]?.isNotEmpty ?? false);

    return SessionAttentionState(
      isActive: isSessionActivelyResponding(normalizedSessionId),
      hasPendingInteraction: hasPendingPermission || hasPendingQuestion,
      hasError: _sessionErrorAttentionIds.contains(normalizedSessionId),
      hasUnreadCompletion: _sessionUnreadCompletionIds.contains(
        normalizedSessionId,
      ),
      unreadCompletionAt:
          _sessionUnreadCompletionTimestamps[normalizedSessionId],
    );
  }

  bool get hasOutOfFocusAttention => outOfFocusAttentionCount > 0;

  int get outOfFocusAttentionCount {
    final currentSessionId = _currentSession?.id;
    var total = 0;
    for (final session in visibleSessions) {
      if (session.id == currentSessionId) {
        continue;
      }
      final attention = sessionAttentionFor(session.id);
      if (attention.requiresAttention) {
        total += 1;
      }
    }
    return total;
  }

  SessionAttentionKind get outOfFocusAttentionKind {
    final currentSessionId = _currentSession?.id;
    var hasPendingInteraction = false;
    var hasUnreadCompletion = false;

    for (final session in visibleSessions) {
      if (session.id == currentSessionId) {
        continue;
      }
      final attention = sessionAttentionFor(session.id);
      if (!attention.requiresAttention) {
        continue;
      }
      if (attention.hasError) {
        return SessionAttentionKind.error;
      }
      hasPendingInteraction =
          hasPendingInteraction || attention.hasPendingInteraction;
      hasUnreadCompletion =
          hasUnreadCompletion || attention.hasUnreadCompletion;
    }

    if (hasPendingInteraction) {
      return SessionAttentionKind.pendingInteraction;
    }
    if (hasUnreadCompletion) {
      return SessionAttentionKind.unreadCompletion;
    }
    return SessionAttentionKind.none;
  }

  void _clearSessionAttentionForSession(String sessionId) {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return;
    }
    _clearSessionUnreadCompletion(normalizedSessionId);
    _sessionErrorAttentionIds.remove(normalizedSessionId);
  }

  void _pruneSessionAttentionStateToKnownSessions() {
    final knownSessionIds = _sessions.map((session) => session.id).toSet();
    _sessionUnreadCompletionIds.removeWhere(
      (sessionId) => !knownSessionIds.contains(sessionId),
    );
    _sessionErrorAttentionIds.removeWhere(
      (sessionId) => !knownSessionIds.contains(sessionId),
    );
    _sessionUnreadCompletionTimestamps.removeWhere(
      (sessionId, _) => !knownSessionIds.contains(sessionId),
    );

    final currentSessionId = _currentSession?.id;
    if (currentSessionId != null) {
      _clearSessionAttentionForSession(currentSessionId);
    }
    _scheduleSessionUnreadHighlightTimer();
  }

  void _syncAttentionFromStatusMap(Map<String, SessionStatusInfo> statusMap) {
    for (final entry in statusMap.entries) {
      final sessionId = entry.key;
      final statusType = entry.value.type;
      switch (statusType) {
        case SessionStatusType.retry:
          _clearSessionUnreadCompletion(sessionId);
          break;
        case SessionStatusType.busy:
          _clearSessionUnreadCompletion(sessionId);
          break;
        case SessionStatusType.idle:
          // Keep sticky error attention on idle until the user focuses the
          // session or an explicit event clears it, avoiding silent dismissal
          // on snapshot refresh races.
          break;
      }
    }
    _pruneSessionAttentionStateToKnownSessions();
  }
}
