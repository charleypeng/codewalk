part of '../chat_provider.dart';

extension _ChatProviderMessageMergeOps on ChatProvider {
  Future<void> _fetchMessageFallback(
    String sessionId,
    String messageId, {
    bool applyToCurrentSession = true,
  }) async {
    _traceFinal(
      'fetch-message-fallback-start',
      sessionId: sessionId,
      details:
          'messageId=$messageId applyToCurrentSession=$applyToCurrentSession',
    );
    final result = await getChatMessage(
      GetChatMessageParams(
        projectId: projectProvider.currentProjectId,
        sessionId: sessionId,
        messageId: messageId,
        directory: projectProvider.currentDirectory,
      ),
    );
    result.fold(
      (failure) {
        AppLogger.warn(
          'Message fallback fetch failed for $messageId: ${failure.toString()}',
        );
        _traceFinal(
          'fetch-message-fallback-failure',
          sessionId: sessionId,
          details: 'messageId=$messageId failure=${failure.runtimeType}',
        );
      },
      (message) {
        final isAssistant = message is AssistantMessage;
        final isCompleted = isAssistant
            ? (message as AssistantMessage).isCompleted
            : false;
        _traceFinal(
          'fetch-message-fallback-success',
          sessionId: sessionId,
          details:
              'messageId=${message.id} role=${message.role.name} assistantCompleted=$isCompleted applyToCurrentSession=$applyToCurrentSession',
        );
        if (applyToCurrentSession && _currentSession?.id == sessionId) {
          _updateOrAddMessage(message);
          _traceFinal(
            'fetch-message-fallback-applied-current',
            sessionId: sessionId,
            details: 'messageId=${message.id}',
          );
        } else {
          final cached =
              _cachedSessionMessages(sessionId) ?? const <ChatMessage>[];
          final next = List<ChatMessage>.from(cached);
          final existingIndex = next.indexWhere(
            (item) => item.id == message.id,
          );
          if (existingIndex == -1) {
            next.add(message);
          } else {
            next[existingIndex] = message;
          }
          _sortMessagesForTimeline(next);
          _cacheSessionMessages(sessionId, next);
          unawaited(_persistSessionMessagesSnapshotBestEffort(sessionId, next));
          _traceFinal(
            'fetch-message-fallback-applied-cache',
            sessionId: sessionId,
            details: 'messageId=${message.id} cachedCount=${next.length}',
          );
        }
      },
    );
  }

  /// Merges server messages with pending optimistic user messages by exact
  /// `messageId`. Server-authoritative messages always win when IDs overlap.
  ({List<ChatMessage> messages, Set<String> reconciledLocalIds})
  _mergeServerMessagesWithPendingLocalUsers(List<ChatMessage> serverMessages) {
    final emptyResult = (
      messages: serverMessages,
      reconciledLocalIds: const <String>{},
    );
    if (_pendingLocalUserMessageIds.isEmpty) return emptyResult;

    final merged = List<ChatMessage>.from(serverMessages);
    final existingIds = serverMessages.map((message) => message.id).toSet();
    final reconciledLocalIds = <String>{};

    // Track IDs matched by exact server ID before removing from pending.
    for (final id in _pendingLocalUserMessageIds) {
      if (existingIds.contains(id)) reconciledLocalIds.add(id);
    }
    _pendingLocalUserMessageIds.removeWhere(existingIds.contains);

    // Track IDs matched by content signature (different local vs server ID).
    for (final serverMessage in serverMessages) {
      if (serverMessage is! UserMessage) {
        continue;
      }
      final pendingLocalIndex = _findPendingLocalUserMessageIndex(
        serverMessage,
      );
      if (pendingLocalIndex == -1) {
        continue;
      }
      final localId = _messages[pendingLocalIndex].id;
      reconciledLocalIds.add(localId);
      _pendingLocalUserMessageIds.remove(localId);
    }

    if (_pendingLocalUserMessageIds.isEmpty) {
      _sortMessagesForTimeline(merged);
      return (messages: merged, reconciledLocalIds: reconciledLocalIds);
    }

    for (final message in _messages) {
      if (message is! UserMessage) {
        continue;
      }
      if (!_pendingLocalUserMessageIds.contains(message.id)) {
        continue;
      }
      if (existingIds.contains(message.id)) {
        continue;
      }
      merged.add(message);
      existingIds.add(message.id);
    }

    _sortMessagesForTimeline(merged);
    return (messages: merged, reconciledLocalIds: reconciledLocalIds);
  }

  ({List<ChatMessage> messages, bool requiresFullFetch})
  _mergeServerTailWithCachedMessages({
    required List<ChatMessage> serverMessages,
    required List<ChatMessage> cachedMessages,
    required String sessionId,
  }) {
    final serverForSession = serverMessages
        .where((message) => message.sessionId == sessionId)
        .toList(growable: false);
    if (serverForSession.isEmpty) {
      return (messages: serverMessages, requiresFullFetch: false);
    }

    final cachedForSession = cachedMessages
        .where((message) => message.sessionId == sessionId)
        .toList(growable: false);
    if (cachedForSession.isEmpty) {
      return (messages: serverForSession, requiresFullFetch: false);
    }

    final cachedIndexById = <String, int>{
      for (var index = 0; index < cachedForSession.length; index += 1)
        cachedForSession[index].id: index,
    };

    var overlapServerIndex = -1;
    var overlapCachedIndex = -1;
    for (var index = 0; index < serverForSession.length; index += 1) {
      final cachedIndex = cachedIndexById[serverForSession[index].id];
      if (cachedIndex == null) {
        continue;
      }
      overlapServerIndex = index;
      overlapCachedIndex = cachedIndex;
      break;
    }

    if (overlapServerIndex == -1 || overlapCachedIndex == -1) {
      return (messages: serverForSession, requiresFullFetch: true);
    }

    final prefix = cachedForSession
        .take(overlapCachedIndex)
        .toList(growable: false);
    final merged = <ChatMessage>[...prefix, ...serverForSession];
    final deduplicated = <ChatMessage>[];
    final seen = <String>{};
    for (final message in merged) {
      if (seen.add(message.id)) {
        deduplicated.add(message);
      }
    }

    _sortMessagesForTimeline(deduplicated);

    return (messages: deduplicated, requiresFullFetch: false);
  }

  List<ChatMessage> _mergeServerMessagesWithActiveLocalTail(
    List<ChatMessage> serverMessages, {
    required String sessionId,
  }) {
    final (:messages, :reconciledLocalIds) =
        _mergeServerMessagesWithPendingLocalUsers(serverMessages);
    final merged = messages;
    final currentSessionId = _currentSession?.id;
    final shouldPreserveLocalTail =
        currentSessionId == sessionId && isSessionActivelyResponding(sessionId);
    if (!shouldPreserveLocalTail || _messages.isEmpty) {
      return merged;
    }

    final existingIds = merged.map((message) => message.id).toSet();
    // Treat reconciled local IDs as already present so they are not re-added.
    existingIds.addAll(reconciledLocalIds);
    final localMessages = _messages
        .where((message) => message.sessionId == sessionId)
        .toList(growable: false);
    if (localMessages.isEmpty) {
      return merged;
    }

    var anchorIndex = -1;
    for (var index = localMessages.length - 1; index >= 0; index -= 1) {
      if (existingIds.contains(localMessages[index].id)) {
        anchorIndex = index;
        break;
      }
    }

    // With no overlap, preserve only a bounded recent tail to avoid keeping
    // stale phantom messages from very old local snapshots.
    const maxTailMessagesWithoutAnchor = 12;
    final tailStart = anchorIndex >= 0
        ? anchorIndex + 1
        : (localMessages.length > maxTailMessagesWithoutAnchor
              ? localMessages.length - maxTailMessagesWithoutAnchor
              : 0);
    for (var index = tailStart; index < localMessages.length; index += 1) {
      final message = localMessages[index];
      if (existingIds.contains(message.id)) {
        continue;
      }
      merged.add(message);
      existingIds.add(message.id);
    }

    _sortMessagesForTimeline(merged);
    return merged;
  }
}
