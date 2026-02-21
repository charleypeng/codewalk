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

  List<ChatMessage> _mergeServerMessagesWithPendingLocalUsers(
    List<ChatMessage> serverMessages,
  ) {
    if (_pendingLocalUserMessageIds.isEmpty) {
      return serverMessages;
    }

    final merged = List<ChatMessage>.from(serverMessages);
    final existingIds = serverMessages.map((message) => message.id).toSet();

    _pendingLocalUserMessageIds.removeWhere(existingIds.contains);

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
      _pendingLocalUserMessageIds.remove(_messages[pendingLocalIndex].id);
    }

    if (_pendingLocalUserMessageIds.isEmpty) {
      return merged;
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

    return merged;
  }

  List<ChatMessage> _mergeServerMessagesWithActiveLocalTail(
    List<ChatMessage> serverMessages, {
    required String sessionId,
  }) {
    final merged = _mergeServerMessagesWithPendingLocalUsers(serverMessages);
    final currentSessionId = _currentSession?.id;
    final shouldPreserveLocalTail =
        currentSessionId == sessionId && isSessionActivelyResponding(sessionId);
    if (!shouldPreserveLocalTail || _messages.isEmpty) {
      return merged;
    }

    final existingIds = merged.map((message) => message.id).toSet();
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

    final tailStart = anchorIndex >= 0 ? anchorIndex + 1 : 0;
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
