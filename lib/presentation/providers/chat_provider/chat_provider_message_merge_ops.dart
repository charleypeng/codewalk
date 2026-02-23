part of '../chat_provider.dart';

extension _ChatProviderMessageMergeOps on ChatProvider {
  Future<void> _fetchMessageFallback(String sessionId, String messageId) async {
    final result = await getChatMessage(
      GetChatMessageParams(
        projectId: projectProvider.currentProjectId,
        sessionId: sessionId,
        messageId: messageId,
        directory: projectProvider.currentDirectory,
      ),
    );
    result.fold((failure) {
      AppLogger.warn(
        'Message fallback fetch failed for $messageId: ${failure.toString()}',
      );
    }, _updateOrAddMessage);
  }

  /// Merges server messages with any pending local user messages that haven't
  /// been echoed by the server yet. Returns both the merged list and the set of
  /// local IDs that were reconciled (matched to a server message by content
  /// signature), so callers can avoid re-adding them during tail preservation.
  ({List<ChatMessage> messages, Set<String> reconciledLocalIds})
  _mergeServerMessagesWithPendingLocalUsers(
    List<ChatMessage> serverMessages,
  ) {
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
    }

    return (messages: merged, reconciledLocalIds: reconciledLocalIds);
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

    return merged;
  }
}
