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

  List<ChatSession> _sessionsForScopeId(String scopeId) {
    final normalizedScopeId = scopeId.trim();
    if (normalizedScopeId.isEmpty) {
      return const <ChatSession>[];
    }
    final contextKey = _composeContextKey(_activeServerId, normalizedScopeId);
    if (contextKey == _activeContextKey) {
      return _sessions;
    }
    return _contextSnapshots[contextKey]?.sessions ?? const <ChatSession>[];
  }

  Map<String, bool> _hiddenByArchivedAncestor(
    Map<String, ChatSession> sessionById,
  ) {
    final memo = <String, bool>{};

    bool resolve(String sessionId, Set<String> stack) {
      final cached = memo[sessionId];
      if (cached != null) {
        return cached;
      }
      if (!stack.add(sessionId)) {
        return false;
      }
      final session = sessionById[sessionId];
      final parentId = session?.parentId?.trim();
      if (session == null || parentId == null || parentId.isEmpty) {
        memo[sessionId] = false;
        stack.remove(sessionId);
        return false;
      }
      final parent = sessionById[parentId];
      final hidden =
          parent != null && (parent.archived || resolve(parentId, stack));
      memo[sessionId] = hidden;
      stack.remove(sessionId);
      return hidden;
    }

    for (final sessionId in sessionById.keys) {
      resolve(sessionId, <String>{});
    }
    return memo;
  }

  void _markSessionUnreadCompletion(String sessionId, {DateTime? timestamp}) {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return;
    }
    // Child/task sessions should finish silently; only root sessions own
    // completion attention surfaces such as unread highlights and menu badges.
    final session = _sessionById(normalizedSessionId);
    final parentId = session?.parentId?.trim();
    if (session == null || (parentId != null && parentId.isNotEmpty)) {
      _clearSessionUnreadCompletion(normalizedSessionId);
      return;
    }
    _sessionUnreadCompletionIds.add(normalizedSessionId);
    _sessionUnreadCompletionTimestamps[normalizedSessionId] =
        timestamp ??
        _sessionUnreadCompletionTimestamps[normalizedSessionId] ??
        DateTime.now();
    _scheduleSessionUnreadHighlightTimer();
  }

  void _clearSessionUnreadCompletion(String sessionId) {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return;
    }
    _sessionUnreadCompletionIds.remove(normalizedSessionId);
    _sessionUnreadCompletionTimestamps.remove(normalizedSessionId);
    _scheduleSessionUnreadHighlightTimer();
  }

  void _scheduleSessionUnreadHighlightTimer() {
    _sessionUnreadHighlightTimer?.cancel();
    _sessionUnreadHighlightTimer = null;

    final now = DateTime.now();
    DateTime? nextExpiry;
    for (final entry in _sessionUnreadCompletionTimestamps.entries) {
      final expiresAt = entry.value.add(const Duration(hours: 1));
      if (!expiresAt.isAfter(now)) {
        continue;
      }
      if (nextExpiry == null || expiresAt.isBefore(nextExpiry)) {
        nextExpiry = expiresAt;
      }
    }
    for (final snapshot in _contextSnapshots.values) {
      for (final entry in snapshot.sessionUnreadCompletionTimestamps.entries) {
        final expiresAt = entry.value.add(const Duration(hours: 1));
        if (!expiresAt.isAfter(now)) {
          continue;
        }
        if (nextExpiry == null || expiresAt.isBefore(nextExpiry)) {
          nextExpiry = expiresAt;
        }
      }
    }
    if (nextExpiry == null) {
      return;
    }

    _sessionUnreadHighlightTimer = Timer(nextExpiry.difference(now), () {
      _pruneExpiredUnreadHighlights();
      _notifyListeners();
    });
  }

  void _pruneExpiredUnreadHighlights() {
    final now = DateTime.now();
    _sessionUnreadCompletionTimestamps.removeWhere((sessionId, timestamp) {
      final expired = now.difference(timestamp) >= const Duration(hours: 1);
      if (expired) {
        _sessionUnreadCompletionIds.remove(sessionId);
      }
      return expired;
    });

    final updatedSnapshots = <String, _ChatContextSnapshot>{};
    for (final entry in _contextSnapshots.entries) {
      final snapshot = entry.value;
      final nextTimestamps = Map<String, DateTime>.from(
        snapshot.sessionUnreadCompletionTimestamps,
      );
      final nextIds = Set<String>.from(snapshot.sessionUnreadCompletionIds);
      var changed = false;
      nextTimestamps.removeWhere((sessionId, timestamp) {
        final expired = now.difference(timestamp) >= const Duration(hours: 1);
        if (expired) {
          nextIds.remove(sessionId);
          changed = true;
        }
        return expired;
      });
      if (!changed) {
        continue;
      }
      updatedSnapshots[entry.key] = _ChatContextSnapshot(
        sessions: snapshot.sessions,
        currentSession: snapshot.currentSession,
        messages: snapshot.messages,
        sessionStatusById: snapshot.sessionStatusById,
        pendingPermissionsBySession: snapshot.pendingPermissionsBySession,
        pendingQuestionsBySession: snapshot.pendingQuestionsBySession,
        sessionUnreadCompletionIds: nextIds,
        sessionUnreadCompletionTimestamps: nextTimestamps,
        sessionErrorAttentionIds: snapshot.sessionErrorAttentionIds,
        sessionChildrenById: snapshot.sessionChildrenById,
        sessionTodoById: snapshot.sessionTodoById,
        sessionDiffById: snapshot.sessionDiffById,
        sessionSearchQuery: snapshot.sessionSearchQuery,
        sessionListFilter: snapshot.sessionListFilter,
        sessionListSort: snapshot.sessionListSort,
        pinnedSessionIds: snapshot.pinnedSessionIds,
        sessionVisibleLimit: snapshot.sessionVisibleLimit,
        isNewChatDraftActive: snapshot.isNewChatDraftActive,
        activeSendDraft: snapshot.activeSendDraft,
        rejectedDraft: snapshot.rejectedDraft,
      );
    }
    if (updatedSnapshots.isNotEmpty) {
      _contextSnapshots.addAll(updatedSnapshots);
    }
    _scheduleSessionUnreadHighlightTimer();
  }
}
