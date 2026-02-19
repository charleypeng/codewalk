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
        _messages[pendingLocalIndex] = message;
        _notifyListeners();
        _attemptPendingRemoteSelectionSync(reason: 'message-user-replaced');
        _scheduleAutoTitleRefresh(message.sessionId);
        _scrollToBottomCallback?.call();
        return;
      }
    }

    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      // Update existing message
      _messages[index] = message;
      if (message is UserMessage) {
        _pendingLocalUserMessageIds.remove(message.id);
      }
      AppLogger.debug(
        'Updated message: ${message.id}, parts=${message.parts.length}',
      );
    } else {
      // Add new message
      _messages.add(message);
      AppLogger.debug('Added new message: ${message.id}, role=${message.role}');
    }

    // Check if there is an unfinished assistant message
    if (message is AssistantMessage) {
      _adoptSelectionFromAssistantMessage(message, reason: 'assistant-message');
      AppLogger.debug(
        'Assistant message status: ${message.isCompleted ? "completed" : "in_progress"}',
      );
      if (message.isCompleted && _state == ChatState.sending) {
        AppLogger.debug('Message completed, setting state to loaded');
        _clearActiveSendDraft();
        _setState(ChatState.loaded);
      }
    }

    _notifyListeners();
    _attemptPendingRemoteSelectionSync(reason: 'message-update');
    _scheduleAutoTitleRefresh(message.sessionId);

    // Trigger auto-scroll (suppressed during compaction to avoid visual jumps).
    if (!_isCompactingContext) {
      _scrollToBottomCallback?.call();
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

  String _normalizedUserMessageSignature(UserMessage message) {
    final textSignature = _normalizedUserTextSignature(message);
    final fileSignature = _normalizedUserFileSignature(message);
    if (fileSignature.isEmpty) {
      return textSignature;
    }
    if (textSignature.isEmpty) {
      return fileSignature;
    }
    return '$textSignature\n$fileSignature'.trim();
  }

  String _normalizedUserTextSignature(UserMessage message) {
    return message.parts
        .whereType<TextPart>()
        .map((part) => part.text.trim())
        .where((text) => text.isNotEmpty)
        .join('\n');
  }

  String _normalizedUserFileSignature(UserMessage message) {
    final fileSignatures =
        message.parts
            .whereType<FilePart>()
            .map(_normalizedFilePartSignature)
            .where((value) => value.isNotEmpty)
            .toList(growable: false)
          ..sort();
    if (fileSignatures.isNotEmpty) {
      return fileSignatures.join('\n');
    }
    return _normalizedUserFileMimeSignature(message);
  }

  String _normalizedUserFileMimeSignature(UserMessage message) {
    final mimeSignatures =
        message.parts
            .whereType<FilePart>()
            .map((part) => part.mime.trim().toLowerCase())
            .where((value) => value.isNotEmpty)
            .toList(growable: false)
          ..sort();
    return mimeSignatures.join('\n');
  }

  String _normalizedFilePartSignature(FilePart part) {
    final mime = part.mime.trim().toLowerCase();
    final sourcePath = (part.fileSource?.path ?? part.symbolSource?.path ?? '')
        .trim();
    final normalizedSourcePath = sourcePath.toLowerCase();
    final normalizedFilename = (part.filename ?? '').trim().toLowerCase();
    final normalizedUrlHint = _normalizedFileUrlHint(part.url);
    final reference = normalizedSourcePath.isNotEmpty
        ? normalizedSourcePath
        : normalizedFilename.isNotEmpty
        ? normalizedFilename
        : normalizedUrlHint;
    if (mime.isEmpty && reference.isEmpty) {
      return '';
    }
    return '$mime|$reference';
  }

  String _normalizedFileUrlHint(String url) {
    final normalized = url.trim().toLowerCase();
    if (normalized.isEmpty) {
      return '';
    }
    if (normalized.startsWith('data:')) {
      final delimiter = normalized.indexOf(';');
      final commaDelimiter = normalized.indexOf(',');
      final endIndex = switch ((delimiter, commaDelimiter)) {
        (>= 0, >= 0) => delimiter < commaDelimiter ? delimiter : commaDelimiter,
        (>= 0, _) => delimiter,
        (_, >= 0) => commaDelimiter,
        _ => normalized.length,
      };
      return normalized.substring(0, endIndex);
    }

    final parsed = Uri.tryParse(normalized);
    if (parsed == null) {
      return normalized;
    }
    if (parsed.pathSegments.isNotEmpty) {
      final basename = parsed.pathSegments.last.trim();
      if (basename.isNotEmpty) {
        return basename;
      }
    }
    final withoutQuery = parsed.replace(query: '', fragment: '').toString();
    return withoutQuery.trim();
  }

  bool _isLikelyPendingLocalUserMatch({
    required UserMessage pending,
    required UserMessage incoming,
  }) {
    final pendingText = _normalizedUserTextSignature(pending);
    final incomingText = _normalizedUserTextSignature(incoming);
    if (pendingText != incomingText) {
      return false;
    }

    final pendingFileCount = pending.parts.whereType<FilePart>().length;
    final incomingFileCount = incoming.parts.whereType<FilePart>().length;
    if (pendingFileCount == 0 || incomingFileCount == 0) {
      return false;
    }
    if (pendingFileCount != incomingFileCount) {
      return false;
    }

    return _normalizedUserFileMimeSignature(pending) ==
        _normalizedUserFileMimeSignature(incoming);
  }

  int _findPendingLocalUserMessageIndex(UserMessage incoming) {
    final incomingSignature = _normalizedUserMessageSignature(incoming);
    if (incomingSignature.isEmpty) {
      return -1;
    }

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
      final currentSignature = _normalizedUserMessageSignature(current);
      if (currentSignature != incomingSignature) {
        if (!_isLikelyPendingLocalUserMatch(
          pending: current,
          incoming: incoming,
        )) {
          continue;
        }
      }
      final delta = incoming.time.difference(current.time).abs();
      if (delta > const Duration(minutes: 5)) {
        continue;
      }
      return index;
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
