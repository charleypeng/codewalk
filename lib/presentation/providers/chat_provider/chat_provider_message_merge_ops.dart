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
}
