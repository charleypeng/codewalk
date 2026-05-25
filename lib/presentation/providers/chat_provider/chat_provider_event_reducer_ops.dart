part of '../chat_provider.dart';

extension _ChatProviderEventReducerOps on ChatProvider {
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

  void _applyChatEvent(ChatEvent event) {
    if (_isEphemeralTitleEvent(event)) return;
    // Register event in dedup buffer so the global stream skips duplicates.
    final dedupKey = _composeEventDeduplicationKey(event);
    if (dedupKey != null && !_recentEventIds.contains(dedupKey)) {
      _recentEventIds.addLast(dedupKey);
      if (_recentEventIds.length > ChatProvider._maxRecentEventIds) {
        _recentEventIds.removeFirst();
      }
    }
    final eventSessionId = _extractEventSessionId(event.properties);
    // Only dispatch sound/notification feedback for session lifecycle events
    // (idle, error) when the event belongs to the current session.
    // Sub-agent child sessions should not trigger user-facing sounds.
    final isSessionLifecycle =
        event.type == 'session.idle' || event.type == 'session.error';
    final suppressCurrentIdleFeedback =
        event.type == 'session.idle' &&
        eventSessionId != null &&
        _hasInFlightSendTurnForSession(eventSessionId);
    final suppressCurrentErrorFeedback =
        event.type == 'session.error' &&
        eventSessionId != null &&
        (() {
          final payload = _extractSessionErrorMessageAndCode(event.properties);
          if (_shouldSuppressAbortError(
            sessionId: eventSessionId,
            message: payload.message,
            code: payload.code,
          )) {
            return true;
          }
          return _hasInFlightSendTurnForSession(eventSessionId) &&
              _isRemoteAbortError(message: payload.message, code: payload.code);
        })();
    if (!isSessionLifecycle || eventSessionId == _currentSession?.id) {
      if (suppressCurrentIdleFeedback) {
        _traceFinal(
          'event-session-idle-feedback-suppressed-active-send',
          sessionId: eventSessionId,
        );
      } else if (suppressCurrentErrorFeedback) {
        _traceFinal(
          'event-session-error-feedback-suppressed-expected-abort',
          sessionId: eventSessionId,
        );
      } else {
        final sessionTitleHint = _sessionTitleForNotification(eventSessionId);
        unawaited(
          eventFeedbackDispatcher?.handle(
            event,
            sessionTitleHint: sessionTitleHint,
            isRootSession: _isRootSessionId(eventSessionId),
            isAppInForeground: _isAppInForeground,
            currentSessionId: _currentSession?.id,
          ),
        );
      }
    }
    final properties = event.properties;
    if (event.type != 'server.connected' &&
        (event.type == 'session.status' ||
            event.type == 'message.created' ||
            event.type == 'message.updated' ||
            event.type == 'session.updated' ||
            event.type == 'session.created')) {
      unawaited(_syncSelectionFromRemote(reason: 'event-${event.type}'));
    }
    switch (event.type) {
      case 'server.heartbeat':
        break;
      case 'server.connected':
        unawaited(
          refreshActiveSessionView(reason: 'realtime-server-connected'),
        );
        unawaited(
          _syncSelectionFromRemote(
            reason: 'event-server-connected',
            force: true,
          ),
        );
        break;
      case 'session.created':
      case 'session.updated':
        final info = properties['info'];
        if (info is Map<String, dynamic>) {
          final incomingSession = ChatSessionModel.fromJson(info).toDomain();
          if (incomingSession.id.isEmpty) {
            break;
          }
          final existing = _sessionById(incomingSession.id);
          final hasIncomingTime = info.containsKey('time');
          if (existing != null &&
              hasIncomingTime &&
              incomingSession.time.isBefore(existing.time)) {
            AppLogger.debug(
              'Ignoring stale session event for ${incomingSession.id}: incoming=${incomingSession.time.toIso8601String()} existing=${existing.time.toIso8601String()}',
            );
            break;
          }
          final nextSession = _mergeSessionFromEventInfo(
            incoming: incomingSession,
            existing: existing,
            info: info,
          );
          final pendingRename = _pendingRenameTitleBySessionId[nextSession.id];
          if (pendingRename != null) {
            final incomingTitle = nextSession.title?.trim();
            if (incomingTitle == pendingRename) {
              _pendingRenameTitleBySessionId.remove(nextSession.id);
            } else {
              AppLogger.debug(
                'Ignoring conflicting session.updated while rename is pending for ${nextSession.id}',
              );
              break;
            }
          }
          _upsertSession(nextSession);
          if (_currentSession?.id == nextSession.id) {
            final previousRevert = _currentSession?.revert;
            _currentSession = nextSession;
            _threadPermissionsVersion++;
            if (previousRevert != nextSession.revert) {
              _messagesVersion++;
            }
          }
          _notifyListeners();
        }
        break;
      case 'session.deleted':
        final info = properties['info'];
        final sessionId =
            (info is Map<String, dynamic> ? info['id'] as String? : null) ??
            properties['sessionID'] as String? ??
            properties['id'] as String?;
        if (sessionId != null && sessionId.isNotEmpty) {
          final deletedCurrent = _currentSession?.id == sessionId;
          _removeSessionById(sessionId);
          if (deletedCurrent && _currentSession != null) {
            unawaited(loadMessages(_currentSession!.id));
            unawaited(loadSessionInsights(_currentSession!.id, silent: true));
          }
          _notifyListeners();
        }
        break;
      case 'session.status':
        final sessionId = properties['sessionID'] as String?;
        final statusMap = properties['status'];
        if (sessionId != null && statusMap is Map<String, dynamic>) {
          final previousStatusType = _sessionStatusById[sessionId]?.type;
          final status = SessionStatusModel.fromJson(statusMap).toDomain();
          _sessionStatusById[sessionId] = status;
          if (status.type == SessionStatusType.busy ||
              status.type == SessionStatusType.retry) {
            _sessionUnreadCompletionIds.remove(sessionId);
          } else if (status.type == SessionStatusType.idle &&
              sessionId != _currentSession?.id &&
              (previousStatusType == SessionStatusType.busy ||
                  previousStatusType == SessionStatusType.retry)) {
            _markSessionUnreadCompletion(sessionId);
          }
          if (sessionId == _currentSession?.id) {
            _clearSessionAttentionForSession(sessionId);
          }
          _notifyListeners();
          _attemptPendingRemoteSelectionSync(reason: 'event-session.status');
        }
        break;
      case 'session.diff':
        final sessionId = properties['sessionID'] as String?;
        final diffRaw = properties['diff'];
        if (sessionId != null && diffRaw is List) {
          final parsed = diffRaw
              .whereType<Map>()
              .map(
                (item) => SessionDiffModel.fromJson(
                  Map<String, dynamic>.from(item),
                ).toDomain(),
              )
              .toList(growable: false);

          // Merge guard: if incoming SSE item has no content (empty before/after
          // AND no patch), preserve existing non-empty stored content for same file
          final existing = _sessionDiffById[sessionId];
          if (existing != null && existing.isNotEmpty) {
            final merged = <SessionDiff>[];
            final existingByFile = {for (final e in existing) e.file: e};

            for (final incoming in parsed) {
              final prev = existingByFile[incoming.file];
              final incomingHasContent =
                  incoming.patch != null && incoming.patch!.isNotEmpty ||
                  incoming.before.isNotEmpty ||
                  incoming.after.isNotEmpty;
              final prevHasContent =
                  (prev?.patch != null && prev!.patch!.isNotEmpty) ||
                  (prev?.before.isNotEmpty ?? false) ||
                  (prev?.after.isNotEmpty ?? false);
              if (prev != null && !incomingHasContent && prevHasContent) {
                // Keep existing content — incoming SSE has no snapshot or patch
                merged.add(prev);
              } else {
                merged.add(incoming);
              }
            }
            _sessionDiffById[sessionId] = merged;
          } else {
            // Skip overwrite if entire incoming list is empty but existing exists
            if (parsed.isEmpty && existing != null && existing.isNotEmpty) {
              break;
            }
            _sessionDiffById[sessionId] = parsed;
          }
          _notifyListeners();
        }
        break;
      case 'todo.updated':
        final sessionId = properties['sessionID'] as String?;
        final todosRaw = properties['todos'];
        if (sessionId != null && todosRaw is List) {
          final parsed = todosRaw
              .whereType<Map>()
              .map(
                (item) => SessionTodo(
                  id: item['id'] as String? ?? '',
                  content: item['content'] as String? ?? '',
                  status: item['status'] as String? ?? 'pending',
                  priority: item['priority'] as String? ?? 'medium',
                ),
              )
              .toList(growable: false);
          _sessionTodoById[sessionId] = parsed;
          _notifyListeners();
        }
        break;
      case 'session.idle':
        final sessionId = properties['sessionID'] as String?;
        if (sessionId != null) {
          final isCurrentSession = sessionId == _currentSession?.id;
          final hasActiveCurrentSendTurn = _hasInFlightSendTurnForSession(
            sessionId,
          );
          final previousStatusType = _sessionStatusById[sessionId]?.type;
          _sessionStatusById[sessionId] = const SessionStatusInfo(
            type: SessionStatusType.idle,
          );
          _traceFinal(
            'event-session-idle',
            sessionId: sessionId,
            details:
                'isCurrent=$isCurrentSession activeSend=$hasActiveCurrentSendTurn',
          );
          AppLogger.info(
            'session.idle session=$sessionId isCurrent=$isCurrentSession activeSend=$hasActiveCurrentSendTurn',
          );
          if (!hasActiveCurrentSendTurn) {
            _markIncompleteAssistantMessagesAsCompleted(sessionId: sessionId);
          }
          _sessionErrorAttentionIds.remove(sessionId);
          if (isCurrentSession) {
            _clearSessionAttentionForSession(sessionId);
            _clearActiveSendDraft();
            // OpenCode's session.idle is the terminal lifecycle signal for a
            // turn. End the active-send UI immediately even if CodeWalk's
            // fallback stream is still draining in the background; otherwise
            // the composer status can keep showing stale progress after the
            // final assistant response is already visible.
            _activeMessageStreamSessionId = null;
            _markIncompleteAssistantMessagesAsCompleted(sessionId: sessionId);
            if (_state == ChatState.sending) {
              _setState(ChatState.loaded);
            } else {
              _notifyListeners();
            }
          } else {
            final wasBusyBeforeIdle =
                previousStatusType == SessionStatusType.busy ||
                previousStatusType == SessionStatusType.retry;
            if (wasBusyBeforeIdle) {
              _markSessionUnreadCompletion(sessionId);
            }
            _notifyListeners();
          }
          _attemptPendingRemoteSelectionSync(reason: 'event-session.idle');
        }
        break;
      case 'session.error':
        final sessionId = properties['sessionID'] as String?;
        if (sessionId == null) {
          break;
        }
        _traceFinal('event-session-error', sessionId: sessionId);

        if (sessionId != _currentSession?.id) {
          _sessionStatusById[sessionId] = const SessionStatusInfo(
            type: SessionStatusType.idle,
          );
          AppLogger.info('session.error non-current session=$sessionId');
          _markIncompleteAssistantMessagesAsCompleted(sessionId: sessionId);
          _sessionUnreadCompletionIds.remove(sessionId);
          _sessionErrorAttentionIds.add(sessionId);
          _notifyListeners();
          break;
        }

        final payload = _extractSessionErrorMessageAndCode(properties);
        final message = payload.message;
        final code = payload.code;
        final rawError = properties['error'];
        final error = rawError is Map
            ? Map<String, dynamic>.from(rawError)
            : null;
        final dataRaw = error?['data'];
        final data = dataRaw is Map
            ? Map<String, dynamic>.from(dataRaw)
            : const <String, dynamic>{};
        final statusCodeRaw =
            data['statusCode'] ??
            data['status'] ??
            error?['statusCode'] ??
            error?['status'];
        final statusCode = statusCodeRaw is num
            ? statusCodeRaw.toInt()
            : int.tryParse(statusCodeRaw?.toString() ?? '');
        _traceFinal(
          'event-session-error-current-session-payload',
          sessionId: sessionId,
          details: 'code=${code ?? "-"} message=$message',
        );
        AppLogger.info(
          'session.error current session=$sessionId message=$message code=$code',
        );
        final hasActiveCurrentSendTurn = _hasInFlightSendTurnForSession(
          sessionId,
        );
        if (_shouldSuppressAbortError(
          sessionId: sessionId,
          message: message,
          code: code,
        )) {
          if (!hasActiveCurrentSendTurn) {
            _sessionStatusById[sessionId] = const SessionStatusInfo(
              type: SessionStatusType.idle,
            );
          }
          _clearSessionAttentionForSession(sessionId);
          _errorMessage = null;
          if (!hasActiveCurrentSendTurn) {
            _setState(ChatState.loaded);
          }
          break;
        }
        if (_isRemoteAbortError(message: message, code: code)) {
          if (!hasActiveCurrentSendTurn) {
            _sessionStatusById[sessionId] = const SessionStatusInfo(
              type: SessionStatusType.idle,
            );
          }
          _clearSessionAttentionForSession(sessionId);
          _errorMessage = null;
          if (!hasActiveCurrentSendTurn) {
            _markIncompleteAssistantMessagesAsCompleted(sessionId: sessionId);
            _appendInlineAbortMessage(sessionId: sessionId);
            _setState(ChatState.loaded);
          }
          break;
        }
        _presentServerErrorForCurrentSession(
          sessionId: sessionId,
          rawMessage: message,
          code: code,
          statusCode: statusCode,
        );
        break;
      case 'message.updated':
      case 'message.created':
        final info = properties['info'] as Map<String, dynamic>?;
        final sessionId = info?['sessionID'] as String?;
        final messageId = info?['id'] as String?;
        if (sessionId != null && messageId != null) {
          final isCurrentSession = _currentSession?.id == sessionId;
          _traceFinal(
            'event-${event.type}-fallback-fetch',
            sessionId: sessionId,
            details:
                'messageId=$messageId applyToCurrentSession=$isCurrentSession',
          );
          unawaited(
            _fetchMessageFallback(
              sessionId,
              messageId,
              applyToCurrentSession: isCurrentSession,
            ),
          );
        }
        break;
      case 'message.part.updated':
        final partMap = properties['part'] as Map<String, dynamic>?;
        var part = partMap == null
            ? null
            : MessagePartModel.fromJson(partMap).toDomain();
        final sessionId = part?.sessionId;
        final messageId = part?.messageId;
        if (sessionId == null ||
            messageId == null ||
            _currentSession?.id != sessionId) {
          break;
        }

        final partIndex = _messages.indexWhere((item) => item.id == messageId);
        final delta = properties['delta'] as String?;
        if (part == null || partIndex == -1) {
          unawaited(_fetchMessageFallback(sessionId, messageId));
          break;
        }
        final incomingPart = part;
        MessagePart resolvedPart = incomingPart;
        final message = _messages[partIndex];
        final nextParts = List<MessagePart>.from(message.parts);
        final existingPartIndex = nextParts.indexWhere(
          (item) => item.id == incomingPart.id,
        );
        if (existingPartIndex == -1) {
          if (delta != null && delta.isNotEmpty) {
            unawaited(_fetchMessageFallback(sessionId, messageId));
            break;
          }
          nextParts.add(incomingPart);
        } else {
          final partFieldKey = _deltaDedupeFieldKey(incomingPart);
          if (delta != null && delta.isNotEmpty) {
            final preferOverlapDedupe =
                partFieldKey != null &&
                _dedupeNextDeltaFieldKeys.remove(partFieldKey);
            final mergedPart = _mergeIncrementalPartUpdate(
              existingPart: nextParts[existingPartIndex],
              incomingPart: incomingPart,
              delta: delta,
              preferOverlapDedupe: preferOverlapDedupe,
            );
            if (mergedPart == null) {
              unawaited(_fetchMessageFallback(sessionId, messageId));
              break;
            }
            resolvedPart = mergedPart;
          }
          if (partFieldKey != null) {
            if (_shouldMarkNextDeltaDedupe(
              existingPart: nextParts[existingPartIndex],
              incomingPart: incomingPart,
              delta: delta ?? '',
            )) {
              _rememberNextDeltaDedupeField(partFieldKey);
            } else if (delta != null && delta.isNotEmpty) {
              _dedupeNextDeltaFieldKeys.remove(partFieldKey);
            }
          }
          if (nextParts[existingPartIndex] == resolvedPart) {
            break;
          }
          nextParts[existingPartIndex] = resolvedPart;
        }
        _messages[partIndex] = _copyMessageWithParts(message, nextParts);
        _messagesVersion++;
        _notifyListeners();
        final shouldAutoScroll =
            existingPartIndex == -1 ||
            resolvedPart is TextPart ||
            resolvedPart is ReasoningPart;
        if (delta != null && delta.isNotEmpty && message is AssistantMessage) {
          _scheduleDebouncedMessageFallback(sessionId, messageId);
        }
        final updatedMessage = _messages[partIndex];
        if (shouldAutoScroll &&
            isSessionActivelyResponding(sessionId) &&
            _shouldSchedulePassiveAutoScrollForSession(
              sessionId,
              latestMessage: updatedMessage,
            )) {
          _scheduleScrollToBottom(reason: 'event-reducer-message-part-updated');
        }
        break;
      case 'message.part.removed':
        final sessionId = properties['sessionID'] as String?;
        final messageId = properties['messageID'] as String?;
        final partId = properties['partID'] as String?;
        if (sessionId == null ||
            messageId == null ||
            partId == null ||
            _currentSession?.id != sessionId) {
          break;
        }
        final messageIndex = _messages.indexWhere(
          (item) => item.id == messageId,
        );
        if (messageIndex == -1) {
          break;
        }
        final message = _messages[messageIndex];
        final nextParts = message.parts
            .where((part) => part.id != partId)
            .toList(growable: false);
        if (nextParts.length == message.parts.length) {
          break;
        }
        _messages[messageIndex] = _copyMessageWithParts(message, nextParts);
        _messagesVersion++;
        _notifyListeners();
        break;
      case 'message.removed':
        final sessionId = properties['sessionID'] as String?;
        final messageId = properties['messageID'] as String?;
        if (sessionId == null ||
            messageId == null ||
            _currentSession?.id != sessionId) {
          break;
        }
        final removedIndex = _messages.indexWhere(
          (item) => item.id == messageId,
        );
        if (removedIndex == -1) {
          break;
        }
        _messages.removeAt(removedIndex);
        _messagesVersion++;
        _notifyListeners();
        break;
      case 'permission.asked':
      case 'permission.updated':
        final permission = ChatPermissionRequestModel.fromJson(
          properties,
        ).toDomain();
        final sessionPermissions = List<ChatPermissionRequest>.from(
          _pendingPermissionsBySession[permission.sessionId] ??
              const <ChatPermissionRequest>[],
        );
        final existingIndex = sessionPermissions.indexWhere(
          (item) => item.id == permission.id,
        );
        if (existingIndex == -1) {
          sessionPermissions.add(permission);
        } else {
          sessionPermissions[existingIndex] = permission;
        }
        _pendingPermissionsBySession[permission.sessionId] = sessionPermissions;
        _threadPermissionsVersion++;
        _notifyListeners();
        break;
      case 'permission.replied':
        final sessionId = properties['sessionID'] as String?;
        final requestId = properties['requestID'] as String?;
        if (sessionId == null || requestId == null) {
          break;
        }
        final existing = _pendingPermissionsBySession[sessionId];
        if (existing == null) {
          break;
        }
        final filtered = existing
            .where((item) => item.id != requestId)
            .toList(growable: false);
        if (filtered.isEmpty) {
          _pendingPermissionsBySession.remove(sessionId);
        } else {
          _pendingPermissionsBySession[sessionId] = filtered;
        }
        _threadPermissionsVersion++;
        _notifyListeners();
        break;
      case 'question.asked':
      case 'question.updated':
        final question = ChatQuestionRequestModel.fromJson(
          properties,
        ).toDomain();
        final sessionQuestions = List<ChatQuestionRequest>.from(
          _pendingQuestionsBySession[question.sessionId] ??
              const <ChatQuestionRequest>[],
        );
        final existingIndex = sessionQuestions.indexWhere(
          (item) => item.id == question.id,
        );
        if (existingIndex == -1) {
          sessionQuestions.add(question);
        } else {
          sessionQuestions[existingIndex] = question;
        }
        _pendingQuestionsBySession[question.sessionId] = sessionQuestions;
        _threadPermissionsVersion++;
        _notifyListeners();
        break;
      case 'question.replied':
      case 'question.rejected':
        final sessionId = properties['sessionID'] as String?;
        final requestId = properties['requestID'] as String?;
        if (sessionId == null || requestId == null) {
          break;
        }
        final existing = _pendingQuestionsBySession[sessionId];
        if (existing == null) {
          break;
        }
        final filtered = existing
            .where((item) => item.id != requestId)
            .toList(growable: false);
        if (filtered.isEmpty) {
          _pendingQuestionsBySession.remove(sessionId);
        } else {
          _pendingQuestionsBySession[sessionId] = filtered;
        }
        _threadPermissionsVersion++;
        _notifyListeners();
        break;
      default:
        break;
    }
  }

  void _handleGlobalEvent(ChatEvent event) {
    if (_isEphemeralTitleEvent(event)) return;

    if (event.type == 'server.heartbeat') {
      return;
    }

    final type = event.type;
    final affectsContext =
        type.startsWith('session.') ||
        type.startsWith('message.') ||
        type.startsWith('project.') ||
        type.startsWith('worktree.') ||
        type.startsWith('todo.') ||
        type.startsWith('permission.') ||
        type.startsWith('question.');
    if (!affectsContext) {
      return;
    }

    final directory = _extractDirectoryFromEvent(event);
    if (directory == null || directory.trim().isEmpty) {
      _dirtyContextKeys.add(_activeContextKey);
      if (_tryApplyGlobalEventIncremental(event)) {
        return;
      }
      final currentSessionId = _currentSession?.id?.trim();
      final eventSessionId = _extractEventSessionId(event.properties)?.trim();
      final refreshVisibleSession =
          event.type.startsWith('message.') &&
          currentSessionId != null &&
          currentSessionId.isNotEmpty &&
          eventSessionId == currentSessionId;
      _scheduleCurrentContextRefresh(
        reason: 'global:$type:no-directory',
        refreshSessions: true,
        refreshStatus: true,
        refreshActiveSession: refreshVisibleSession,
      );
      return;
    }

    final targetContextKey = _composeContextKey(_activeServerId, directory);
    _dirtyContextKeys.add(targetContextKey);

    if (targetContextKey == _activeContextKey) {
      if (_tryApplyGlobalEventIncremental(event)) {
        return;
      }
      _scheduleGlobalFallbackReconcile(event);
      return;
    }

    if (_tryApplyGlobalEventToInactiveSnapshot(targetContextKey, event)) {
      return;
    }

    AppLogger.debug(
      'Marked inactive context dirty and kept cache for SWR restore context=$targetContextKey event=$type',
    );
  }

  bool _tryApplyGlobalEventIncremental(ChatEvent event) {
    // Skip events already processed by the session stream to avoid
    // redundant notifyListeners() calls and duplicate state mutations.
    if (_isRecentlyProcessedEvent(event)) return true;

    const supportedTypes = <String>{
      'server.connected',
      'session.created',
      'session.updated',
      'session.deleted',
      'session.status',
      'session.diff',
      'session.idle',
      'session.error',
      'todo.updated',
      'message.created',
      'message.updated',
      'message.part.updated',
      'message.part.removed',
      'message.removed',
      'permission.asked',
      'permission.updated',
      'permission.replied',
      'question.asked',
      'question.updated',
      'question.replied',
      'question.rejected',
    };
    if (!supportedTypes.contains(event.type)) {
      return false;
    }
    _applyChatEvent(event);
    return true;
  }

  void _scheduleGlobalFallbackReconcile(ChatEvent event) {
    final type = event.type;
    final currentSessionId = _currentSession?.id?.trim();
    final eventSessionId = _extractEventSessionId(event.properties)?.trim();
    final refreshSessions =
        type.startsWith('session.') ||
        type.startsWith('project.') ||
        type.startsWith('worktree.');
    final refreshActiveSession =
        type.startsWith('message.') &&
        !_isCompactingContext &&
        _activeMessageStreamSessionId == null &&
        currentSessionId != null &&
        currentSessionId.isNotEmpty &&
        eventSessionId == currentSessionId;
    _scheduleCurrentContextRefresh(
      reason: 'global:$type:fallback',
      refreshSessions: refreshSessions,
      refreshStatus: refreshSessions || refreshActiveSession,
      refreshActiveSession: refreshActiveSession,
    );
  }

  bool _tryApplyGlobalEventToInactiveSnapshot(
    String contextKey,
    ChatEvent event,
  ) {
    final snapshot = _contextSnapshots[contextKey];
    if (snapshot == null) {
      return false;
    }

    List<ChatSession>? nextSessions;
    Map<String, SessionStatusInfo>? nextSessionStatusById;
    Set<String>? nextUnreadCompletionIds;
    Map<String, DateTime>? nextUnreadCompletionTimestamps;
    Set<String>? nextErrorAttentionIds;
    switch (event.type) {
      case 'session.created':
      case 'session.updated':
        final info = event.properties['info'];
        if (info is! Map<String, dynamic>) {
          return false;
        }
        final incomingSession = ChatSessionModel.fromJson(info).toDomain();
        if (incomingSession.id.isEmpty ||
            _isEphemeralTitleSession(incomingSession)) {
          return false;
        }
        nextSessions = List<ChatSession>.from(snapshot.sessions);
        final existingIndex = nextSessions.indexWhere(
          (session) => session.id == incomingSession.id,
        );
        if (existingIndex == -1) {
          nextSessions.add(incomingSession);
        } else {
          nextSessions[existingIndex] = _mergeSessionFromEventInfo(
            incoming: incomingSession,
            existing: nextSessions[existingIndex],
            info: info,
          );
        }
        break;
      case 'session.deleted':
        final sessionId =
            (event.properties['info'] is Map<String, dynamic>
                ? (event.properties['info'] as Map<String, dynamic>)['id']
                      as String?
                : null) ??
            event.properties['sessionID'] as String? ??
            event.properties['id'] as String?;
        if (sessionId == null || sessionId.trim().isEmpty) {
          return false;
        }
        nextSessions = snapshot.sessions
            .where((session) => session.id != sessionId)
            .toList(growable: false);
        if (nextSessions.length == snapshot.sessions.length) {
          return false;
        }
        break;
      case 'session.status':
        final sessionId = event.properties['sessionID'] as String?;
        final statusMap = event.properties['status'];
        if (sessionId == null || statusMap is! Map<String, dynamic>) {
          return false;
        }
        final nextStatus = SessionStatusModel.fromJson(statusMap).toDomain();
        final previousStatus = snapshot.sessionStatusById[sessionId];
        if (previousStatus == nextStatus) {
          return false;
        }
        nextSessionStatusById = Map<String, SessionStatusInfo>.from(
          snapshot.sessionStatusById,
        )..[sessionId] = nextStatus;
        if (nextStatus.type == SessionStatusType.busy ||
            nextStatus.type == SessionStatusType.retry) {
          nextUnreadCompletionIds = Set<String>.from(
            snapshot.sessionUnreadCompletionIds,
          )..remove(sessionId);
          nextUnreadCompletionTimestamps = Map<String, DateTime>.from(
            snapshot.sessionUnreadCompletionTimestamps,
          )..remove(sessionId);
        } else if (nextStatus.type == SessionStatusType.idle &&
            (previousStatus?.type == SessionStatusType.busy ||
                previousStatus?.type == SessionStatusType.retry)) {
          nextUnreadCompletionIds = Set<String>.from(
            snapshot.sessionUnreadCompletionIds,
          )..add(sessionId);
          nextUnreadCompletionTimestamps = Map<String, DateTime>.from(
            snapshot.sessionUnreadCompletionTimestamps,
          )..[sessionId] = DateTime.now();
        }
        break;
      case 'session.idle':
        final sessionId = event.properties['sessionID'] as String?;
        if (sessionId == null || sessionId.trim().isEmpty) {
          return false;
        }
        final previousStatusType = snapshot.sessionStatusById[sessionId]?.type;
        final nextIdleStatus = const SessionStatusInfo(
          type: SessionStatusType.idle,
        );
        nextSessionStatusById = Map<String, SessionStatusInfo>.from(
          snapshot.sessionStatusById,
        )..[sessionId] = nextIdleStatus;
        nextErrorAttentionIds = Set<String>.from(
          snapshot.sessionErrorAttentionIds,
        )..remove(sessionId);
        final wasBusyBeforeIdle =
            previousStatusType == SessionStatusType.busy ||
            previousStatusType == SessionStatusType.retry;
        if (wasBusyBeforeIdle) {
          nextUnreadCompletionIds = Set<String>.from(
            snapshot.sessionUnreadCompletionIds,
          )..add(sessionId);
          nextUnreadCompletionTimestamps = Map<String, DateTime>.from(
            snapshot.sessionUnreadCompletionTimestamps,
          )..[sessionId] = DateTime.now();
        }
        break;
      default:
        return false;
    }

    final effectiveSessions = nextSessions ?? snapshot.sessions;
    final effectiveSessionStatusById =
        nextSessionStatusById ?? snapshot.sessionStatusById;
    final effectiveUnreadCompletionIds =
        nextUnreadCompletionIds ?? snapshot.sessionUnreadCompletionIds;
    final effectiveUnreadCompletionTimestamps =
        nextUnreadCompletionTimestamps ??
        snapshot.sessionUnreadCompletionTimestamps;
    final effectiveErrorAttentionIds =
        nextErrorAttentionIds ?? snapshot.sessionErrorAttentionIds;

    final changed =
        !listEquals(snapshot.sessions, effectiveSessions) ||
        !mapEquals(snapshot.sessionStatusById, effectiveSessionStatusById) ||
        !setEquals(
          snapshot.sessionUnreadCompletionIds,
          effectiveUnreadCompletionIds,
        ) ||
        !mapEquals(
          snapshot.sessionUnreadCompletionTimestamps,
          effectiveUnreadCompletionTimestamps,
        ) ||
        !setEquals(
          snapshot.sessionErrorAttentionIds,
          effectiveErrorAttentionIds,
        );
    if (!changed) {
      return false;
    }

    _contextSnapshots[contextKey] = _ChatContextSnapshot(
      sessions: effectiveSessions,
      currentSession: snapshot.currentSession,
      messages: snapshot.messages,
      sessionStatusById: effectiveSessionStatusById,
      pendingPermissionsBySession: snapshot.pendingPermissionsBySession,
      pendingQuestionsBySession: snapshot.pendingQuestionsBySession,
      sessionUnreadCompletionIds: effectiveUnreadCompletionIds,
      sessionUnreadCompletionTimestamps: effectiveUnreadCompletionTimestamps,
      sessionErrorAttentionIds: effectiveErrorAttentionIds,
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
    _scheduleSessionUnreadHighlightTimer();
    _notifyListeners();
    return true;
  }

  void _scheduleCurrentContextRefresh({
    required String reason,
    bool refreshSessions = false,
    bool refreshStatus = false,
    bool refreshActiveSession = false,
  }) {
    _pendingRefreshSessions = _pendingRefreshSessions || refreshSessions;
    _pendingRefreshStatus = _pendingRefreshStatus || refreshStatus;
    _pendingRefreshActiveSession =
        _pendingRefreshActiveSession || refreshActiveSession;
    _globalRefreshDebounce?.cancel();
    _globalRefreshDebounce = Timer(const Duration(milliseconds: 300), () {
      final shouldRefreshSessions = _pendingRefreshSessions;
      final shouldRefreshStatus = _pendingRefreshStatus;
      final shouldRefreshActiveSession = _pendingRefreshActiveSession;
      _pendingRefreshSessions = false;
      _pendingRefreshStatus = false;
      _pendingRefreshActiveSession = false;

      AppLogger.info(
        'scoped_reconcile_triggered reason=$reason sessions=$shouldRefreshSessions active=$shouldRefreshActiveSession status=$shouldRefreshStatus',
      );

      if (shouldRefreshSessions) {
        unawaited(loadSessions());
      }

      if (shouldRefreshActiveSession) {
        unawaited(
          refreshActiveSessionView(
            reason: 'scoped-reconcile:$reason',
            includeStatus: !shouldRefreshSessions && shouldRefreshStatus,
          ),
        );
        return;
      }

      if (!shouldRefreshSessions && shouldRefreshStatus) {
        unawaited(refreshSessionStatusSnapshot());
      }
    });
  }
}
