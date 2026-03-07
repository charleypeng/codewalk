part of '../chat_provider.dart';

extension _ChatProviderMessageStateOps on ChatProvider {
  ChatMessage _copyMessageWithParts(
    ChatMessage message,
    List<MessagePart> parts,
  ) {
    if (message is AssistantMessage) {
      return AssistantMessage(
        id: message.id,
        sessionId: message.sessionId,
        time: message.time,
        parts: parts,
        completedTime: message.completedTime,
        providerId: message.providerId,
        modelId: message.modelId,
        cost: message.cost,
        tokens: message.tokens,
        error: message.error,
        mode: message.mode,
        summary: message.summary,
      );
    }
    return UserMessage(
      id: message.id,
      sessionId: message.sessionId,
      time: message.time,
      parts: parts,
    );
  }

  bool _hasOfficialTimelineMessageId(ChatMessage message) {
    final id = message.id;
    if (!id.startsWith('msg_') || id.length != 30) {
      return false;
    }

    final timestampSegment = id.substring(4, 16);
    final randomSegment = id.substring(16);
    final isHexTimestamp = RegExp(r'^[0-9a-f]{12}$').hasMatch(timestampSegment);
    final isBase62Suffix = RegExp(r'^[0-9A-Za-z]{14}$').hasMatch(randomSegment);
    return isHexTimestamp && isBase62Suffix;
  }

  void _sortMessagesForTimeline(List<ChatMessage> messages) {
    final allOfficialIds = messages.every(_hasOfficialTimelineMessageId);
    if (allOfficialIds) {
      messages.sort((a, b) => a.id.compareTo(b.id));
      return;
    }

    final hasPendingOptimisticUser = messages.any(
      (message) => _pendingLocalUserMessageIds.contains(message.id),
    );
    if (hasPendingOptimisticUser) {
      return;
    }

    messages.sort((a, b) {
      final byTime = a.time.compareTo(b.time);
      if (byTime != 0) {
        return byTime;
      }
      return a.id.compareTo(b.id);
    });
  }

  String _extractAutoTitleText(ChatMessage message) {
    if (message is AssistantMessage && message.summary == true) {
      return '';
    }
    final text = message.parts
        .whereType<TextPart>()
        .map((part) => part.text.trim())
        .where((part) => part.isNotEmpty)
        .join('\n')
        .trim();
    return text;
  }

  int _resolveAutoTitleMaxWords() {
    final platform = defaultTargetPlatform;
    final isMobile =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;
    if (!isMobile && _isForegroundActive) {
      return 6;
    }
    return 4;
  }

  void _scheduleAutoTitleRefresh(String sessionId) {
    if (titleGenerator == null || sessionId.isEmpty) {
      return;
    }
    final session = _sessionById(sessionId);
    final parentId = session?.parentId?.trim();
    if (parentId != null && parentId.isNotEmpty) {
      return;
    }
    if (_autoTitleConsolidatedSessionIds.contains(sessionId)) {
      return;
    }
    if (_autoTitleInFlightSessionIds.contains(sessionId)) {
      _autoTitleQueuedSessionIds.add(sessionId);
      return;
    }
    unawaited(_processAutoTitleQueue(sessionId));
  }

  String _generateSessionTitle(DateTime time) {
    return SessionTitleFormatter.fallbackTitle(time: time);
  }

  void _markIncompleteAssistantMessagesAsCompleted({String? sessionId}) {
    final now = DateTime.now();
    var changed = false;
    _messages = _messages
        .map((message) {
          if (message is! AssistantMessage || message.isCompleted) {
            return message;
          }
          if (sessionId != null && message.sessionId != sessionId) {
            return message;
          }
          changed = true;
          return AssistantMessage(
            id: message.id,
            sessionId: message.sessionId,
            time: message.time,
            parts: message.parts,
            completedTime: now,
            providerId: message.providerId,
            modelId: message.modelId,
            cost: message.cost,
            tokens: message.tokens,
            error: message.error,
            mode: message.mode,
            summary: message.summary,
          );
        })
        .toList(growable: true);
    if (!changed) {
      return;
    }
    _messagesVersion++;
    // Notify only. Final message reveal/collapse sequencing is coordinated
    // by the chat viewport lifecycle on the page side.
    _notifyListeners();
  }

  void _prunePendingLocalUserMessageIdsToVisibleUsers() {
    if (_pendingLocalUserMessageIds.isEmpty) {
      return;
    }
    final visibleUserIds = _messages
        .whereType<UserMessage>()
        .map((message) => message.id)
        .toSet();
    _pendingLocalUserMessageIds.removeWhere(
      (id) => !visibleUserIds.contains(id),
    );
  }

  void _pruneQueuedLocalUserMessageIdsToVisibleUsers() {
    if (_queuedLocalUserMessageIds.isEmpty) {
      return;
    }
    final visibleUserIds = _messages
        .whereType<UserMessage>()
        .map((message) => message.id)
        .toSet();
    _queuedLocalUserMessageIds.removeWhere(
      (id) => !visibleUserIds.contains(id),
    );
  }

  UserMessage _buildLocalUserMessage({
    required String localMessageId,
    required String sessionId,
    required DateTime time,
    required String text,
    required List<FileInputPart> attachments,
    required bool shellMode,
  }) {
    final userParts = <MessagePart>[];
    if (text.isNotEmpty) {
      userParts.add(
        TextPart(
          id: '${localMessageId}_text',
          messageId: localMessageId,
          sessionId: sessionId,
          text: shellMode ? '!$text' : text,
          time: time,
        ),
      );
    }
    for (var index = 0; index < attachments.length; index += 1) {
      final attachment = attachments[index];
      userParts.add(
        FilePart(
          id: '${localMessageId}_file_$index',
          messageId: localMessageId,
          sessionId: sessionId,
          url: attachment.url,
          mime: attachment.mime,
          filename: attachment.filename,
        ),
      );
    }
    return UserMessage(
      id: localMessageId,
      sessionId: sessionId,
      time: time,
      parts: userParts,
    );
  }

  String _appendLocalUserMessage({
    required String sessionId,
    required String text,
    required List<FileInputPart> attachments,
    required bool shellMode,
  }) {
    final localMessageId = _nextOptimisticMessageId();
    _messages.add(
      _buildLocalUserMessage(
        localMessageId: localMessageId,
        sessionId: sessionId,
        time: DateTime.now(),
        text: text,
        attachments: attachments,
        shellMode: shellMode,
      ),
    );
    _messagesVersion++;
    _pendingLocalUserMessageIds.add(localMessageId);
    return localMessageId;
  }

  String _consolidateQueuedLocalUserMessages({
    required String sessionId,
    required List<_QueuedSendEnvelope> queuedBatch,
    required String mergedText,
    required List<FileInputPart> mergedAttachments,
    required bool shellMode,
  }) {
    final queuedLocalIds = queuedBatch
        .map((item) => item.localMessageId)
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    final queuedLocalIdSet = queuedLocalIds.toSet();
    final anchorLocalId =
        queuedLocalIds.firstOrNull ?? _nextOptimisticMessageId();

    var insertionIndex = -1;
    for (var index = 0; index < _messages.length; index += 1) {
      final message = _messages[index];
      if (message is! UserMessage) {
        continue;
      }
      if (message.sessionId != sessionId) {
        continue;
      }
      if (!queuedLocalIdSet.contains(message.id)) {
        continue;
      }
      insertionIndex = index;
      break;
    }

    _messages.removeWhere(
      (message) =>
          message is UserMessage &&
          message.sessionId == sessionId &&
          queuedLocalIdSet.contains(message.id),
    );

    final consolidatedMessage = _buildLocalUserMessage(
      localMessageId: anchorLocalId,
      sessionId: sessionId,
      time: DateTime.now(),
      text: mergedText,
      attachments: mergedAttachments,
      shellMode: shellMode,
    );
    if (insertionIndex < 0 || insertionIndex > _messages.length) {
      _messages.add(consolidatedMessage);
    } else {
      _messages.insert(insertionIndex, consolidatedMessage);
    }
    _messagesVersion++;
    _pendingLocalUserMessageIds.removeWhere(queuedLocalIdSet.contains);
    _pendingLocalUserMessageIds.add(anchorLocalId);
    _queuedLocalUserMessageIds.removeWhere(queuedLocalIdSet.contains);
    return anchorLocalId;
  }

  void _updateOrAddMessage(ChatMessage message) {
    final currentSessionId = _currentSession?.id;
    if (currentSessionId == null || message.sessionId != currentSessionId) {
      AppLogger.debug(
        'Ignoring off-session message update session=${message.sessionId} current=${currentSessionId ?? "-"}',
      );
      _scheduleAutoTitleRefresh(message.sessionId);
      return;
    }

    if (message is UserMessage) {
      final pendingLocalIndex = _findPendingLocalUserMessageIndex(message);
      if (pendingLocalIndex != -1) {
        final previousId = _messages[pendingLocalIndex].id;
        _pendingLocalUserMessageIds.remove(previousId);
        _queuedLocalUserMessageIds.remove(previousId);
        _messages[pendingLocalIndex] = message;
        _sortMessagesForTimeline(_messages);
        _messagesVersion++;
        _notifyListeners();
        _attemptPendingRemoteSelectionSync(reason: 'message-user-replaced');
        _scheduleAutoTitleRefresh(message.sessionId);
        _scheduleScrollToBottom();
        return;
      }
    }

    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      // Update existing message
      _messages[index] = message;
      _sortMessagesForTimeline(_messages);
      _messagesVersion++;
      if (message is UserMessage) {
        _pendingLocalUserMessageIds.remove(message.id);
        _queuedLocalUserMessageIds.remove(message.id);
      }
      AppLogger.debug(
        'Updated message: ${message.id}, parts=${message.parts.length}',
      );
    } else {
      // Add new message
      _messages.add(message);
      _sortMessagesForTimeline(_messages);
      _messagesVersion++;
      AppLogger.debug('Added new message: ${message.id}, role=${message.role}');
    }

    // Check if there is an unfinished assistant message
    if (message is AssistantMessage) {
      _adoptSelectionFromAssistantMessage(message, reason: 'assistant-message');
      AppLogger.debug(
        'Assistant message status: ${message.isCompleted ? "completed" : "in_progress"}',
      );
      final hasActiveStream =
          _messageSubscription != null &&
          _activeMessageStreamSessionId == message.sessionId;
      final sessionStatus = _sessionStatusById[message.sessionId]?.type;
      final hasBusyStatus =
          sessionStatus == SessionStatusType.busy ||
          sessionStatus == SessionStatusType.retry;
      if (message.isCompleted &&
          _state == ChatState.sending &&
          _currentSession?.id == message.sessionId &&
          !hasActiveStream &&
          !hasBusyStatus) {
        AppLogger.debug(
          'Message completed and stream idle, setting state loaded',
        );
        _clearActiveSendDraft();
        _setState(ChatState.loaded);
      }
    }

    _notifyListeners();
    _attemptPendingRemoteSelectionSync(reason: 'message-update');
    _scheduleAutoTitleRefresh(message.sessionId);

    // Trigger auto-scroll only while the current session is actively
    // responding, or when a user message is added/replaced.
    if (!_isCompactingContext &&
        (message is UserMessage ||
            (_currentSession?.id == message.sessionId &&
                isSessionActivelyResponding(message.sessionId)))) {
      _scheduleScrollToBottom();
    }
  }

  void _adoptSelectionFromAssistantMessage(
    AssistantMessage message, {
    required String reason,
  }) {
    if (_isSelectionNeutralAssistantMessage(message)) {
      return;
    }

    var changed = false;

    final providerId = message.providerId?.trim();
    final modelId = message.modelId?.trim();
    if (providerId != null &&
        providerId.isNotEmpty &&
        modelId != null &&
        modelId.isNotEmpty) {
      final provider = _providers.where((p) => p.id == providerId).firstOrNull;
      if (provider != null && provider.models.containsKey(modelId)) {
        if (_selectedProviderId != providerId || _selectedModelId != modelId) {
          _selectedProviderId = providerId;
          _selectedModelId = modelId;
          _selectedVariantId = _resolveStoredVariantForSelection();
          _lastSyncedRemoteVariantKey = null;
          changed = true;
        }
        _lastSyncedRemoteModelKey = _modelKey(providerId, modelId);
      }
    }

    final mode = message.mode?.trim();
    if (mode != null && mode.isNotEmpty && mode.toLowerCase() != 'shell') {
      final resolved = _resolvePreferredAgentName(_agents, mode);
      if (resolved != null) {
        _lastSyncedRemoteAgentName = resolved;
        if (_selectedAgentName != resolved) {
          _selectedAgentName = resolved;
          _lastSyncedRemoteVariantKey = null;
          changed = true;
        }
      }
    }

    if (!changed) {
      return;
    }

    AppLogger.info(
      'Adopted assistant selection reason=$reason agent=${_selectedAgentName ?? "-"} provider=${_selectedProviderId ?? "-"} model=${_selectedModelId ?? "-"}',
    );
    _storeCurrentSessionSelectionOverride();
    unawaited(_persistSelection(syncRemote: false));
  }

  bool _isSelectionNeutralAssistantMessage(AssistantMessage message) {
    if (message.summary == true) {
      return true;
    }
    for (final part in message.parts) {
      if (part is CompactionPart) {
        return true;
      }
    }
    return false;
  }

  int _findPendingLocalUserMessageIndex(UserMessage incoming) {
    for (var index = 0; index < _messages.length; index += 1) {
      final current = _messages[index];
      if (current is! UserMessage) {
        continue;
      }
      if (!_pendingLocalUserMessageIds.contains(current.id)) {
        continue;
      }
      if (current.sessionId != incoming.sessionId) {
        continue;
      }
      if (current.id == incoming.id) {
        return index;
      }
    }
    return -1;
  }

  void _handleFailure(Failure failure) {
    AppLogger.warn(
      'Chat failure handled type=${failure.runtimeType} message=${failure.message}',
    );
    switch (failure) {
      case NetworkFailure _:
        _setError('Network connection failed. Please check network settings');
      case ServerFailure _:
        _setError('Server error. Please try again later');
      case NotFoundFailure _:
        _setError('Resource not found');
      case ValidationFailure _:
        _setError('Invalid input parameters');
      default:
        _setError('Unknown error. Please try again later');
    }
  }

  void _handleSendFailure(Failure failure, {required String sessionId}) {
    if (_currentSession?.id != sessionId) {
      _handleFailure(failure);
      return;
    }
    final statusCode = switch (failure) {
      ServerFailure(code: final code) => code,
      NetworkFailure(code: final code) => code,
      _ => null,
    };
    _presentServerErrorForCurrentSession(
      sessionId: sessionId,
      rawMessage: failure.message,
      statusCode: statusCode,
    );
  }

  ChatSession? _sessionById(String sessionId) {
    return _sessions.where((session) => session.id == sessionId).firstOrNull;
  }

  void _applySessionLocally(ChatSession session) {
    _upsertSession(session);
    if (_currentSession?.id == session.id) {
      _currentSession = session;
    }
  }
}
