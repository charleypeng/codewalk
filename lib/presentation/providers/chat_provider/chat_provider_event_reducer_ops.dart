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

  void _applyChatEvent(ChatEvent event) {
    final eventSessionId = _extractEventSessionId(event.properties);
    final task = AppLogger.beginTask(
      'realtime_event',
      tags: const <String>{'chat:realtime'},
      context: <String, Object?>{
        'eventType': event.type,
        if (eventSessionId != null)
          'sessionId': AppLogger.safeContextId(eventSessionId),
      },
    );
    try {
      _applyChatEventInner(event);
      task.end();
    } catch (error, stackTrace) {
      task.end(status: 'error', error: error, stackTrace: stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void _applyChatEventInner(ChatEvent event) {
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
    if (_shouldSuppressAggressiveDataSaverEvent(event, eventSessionId)) {
      _dirtyContextKeys.add(_activeContextKey);
      AppLogger.info(
        'data_saver_aggressive_event_suppressed type=${event.type} session=${eventSessionId ?? "-"}',
      );
      return;
    }
    final feedbackEvent = _feedbackEventForCurrentContext(event);
    final feedbackSessionId = feedbackEvent == null
        ? null
        : _extractEventSessionId(feedbackEvent.properties);
    final visibleCurrentSessionId = _isChatRouteActive
        ? _currentSession?.id
        : null;
    final suppressCurrentIdleFeedback =
        feedbackEvent != null &&
        feedbackEvent.type == 'session.idle' &&
        event.type == 'session.idle' &&
        feedbackSessionId != null &&
        _isChatRouteActive &&
        _hasInFlightSendTurnForSession(feedbackSessionId);
    final suppressCurrentErrorFeedback =
        feedbackEvent != null &&
        feedbackEvent.type == 'session.error' &&
        feedbackSessionId != null &&
        (() {
          final payload = _extractSessionErrorMessageAndCode(
            feedbackEvent.properties,
          );
          if (_shouldSuppressAbortError(
            sessionId: feedbackSessionId,
            message: payload.message,
            code: payload.code,
          )) {
            return true;
          }
          return _isChatRouteActive &&
              _hasInFlightSendTurnForSession(feedbackSessionId) &&
              _isRemoteAbortError(message: payload.message, code: payload.code);
        })();
    if (feedbackEvent != null) {
      if (suppressCurrentIdleFeedback) {
        _traceFinal(
          'event-session-idle-feedback-suppressed-active-send',
          sessionId: feedbackSessionId,
        );
      } else if (suppressCurrentErrorFeedback) {
        _traceFinal(
          'event-session-error-feedback-suppressed-expected-abort',
          sessionId: feedbackSessionId,
        );
      } else {
        final sessionTitleHint = _sessionTitleForNotification(
          feedbackSessionId,
        );
        unawaited(
          eventFeedbackDispatcher?.handle(
            feedbackEvent,
            sessionTitleHint: sessionTitleHint,
            isRootSession: _isRootSessionId(feedbackSessionId),
            isAppInForeground: _isAppInForeground,
            currentSessionId: visibleCurrentSessionId,
          ),
        );
      }
    }
    final properties = event.properties;
    final currentSessionId = _currentSession?.id;
    final eventTargetsCurrentSession =
        eventSessionId != null &&
        (currentSessionId == null || eventSessionId == currentSessionId);
    if (event.type != 'server.connected' &&
        eventTargetsCurrentSession &&
        !_cellularDataSaverService.isAggressiveDataSaverActive &&
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
        if (_cellularDataSaverService.isAggressiveDataSaverActive) {
          if (_hasVisibleAggressiveDataSaverSession) {
            unawaited(
              refreshActiveSessionView(
                reason: 'realtime-server-connected',
                includeStatus: false,
              ),
            );
          }
        } else {
          unawaited(
            refreshActiveSessionView(reason: 'realtime-server-connected'),
          );
          unawaited(
            _syncSelectionFromRemote(
              reason: 'event-server-connected',
              force: true,
            ),
          );
        }
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
          if (existing == nextSession) {
            break;
          }
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
            _dismissNotificationsForSession(nextSession.id);
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
          final status = SessionStatusModel.fromJson(statusMap).toDomain();
          final previousStatus = _sessionStatusById[sessionId];
          final previousStatusType = previousStatus?.type;
          final isNonCurrent = _isNonCurrentSessionEvent(sessionId);
          final isCurrentSession = sessionId == _currentSession?.id;
          final isVisibleCurrentSession =
              isCurrentSession && _isChatRouteActive;
          final changed = isNonCurrent
              ? previousStatusType != status.type
              : previousStatus != status;
          if (!changed) {
            break;
          }
          _sessionStatusById[sessionId] = status;
          if (status.type == SessionStatusType.busy ||
              status.type == SessionStatusType.retry) {
            _sessionUnreadCompletionIds.remove(sessionId);
          } else if (status.type == SessionStatusType.idle &&
              !isVisibleCurrentSession &&
              (previousStatusType == SessionStatusType.busy ||
                  previousStatusType == SessionStatusType.retry)) {
            _markSessionUnreadCompletion(sessionId);
          }
          if (isVisibleCurrentSession) {
            _clearSessionAttentionForSession(sessionId);
          }
          _notifyListeners();
          if (!isNonCurrent || _pendingRemoteSelectionSync) {
            _attemptPendingRemoteSelectionSync(reason: 'event-session.status');
          }
        }
        break;
      case 'session.diff':
        final sessionId = properties['sessionID'] as String?;
        final diffRaw = properties['diff'];
        if (sessionId != null && diffRaw is List) {
          if (_isNonCurrentSessionEvent(sessionId)) {
            break;
          }
          final parsed = diffRaw
              .whereType<Map>()
              .map(
                (item) => SessionDiffModel.fromJson(
                  Map<String, dynamic>.from(item),
                ).toDomain(),
              )
              .toList(growable: false);

          final existing = _sessionDiffById[sessionId];
          // Preserve a known-good diff when the SSE event carries an empty
          // list. The authoritative source for the file list is the
          // turn-by-turn summary in the server, and a transient empty
          // payload from another client must not erase the local view.
          if (parsed.isEmpty && existing != null && existing.isNotEmpty) {
            break;
          }
          // Merge guard: if incoming SSE item has no content (empty before/after
          // AND no patch), preserve existing non-empty stored content for same file
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
            _sessionDiffById[sessionId] = parsed;
          }
          _notifyListeners();
        }
        break;
      case 'todo.updated':
        final sessionId = properties['sessionID'] as String?;
        final todosRaw = properties['todos'];
        if (sessionId != null && todosRaw is List) {
          if (_isNonCurrentSessionEvent(sessionId)) {
            break;
          }
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
          _flushDeltaNotification(reason: 'event-session.idle');
          final isCurrentSession = sessionId == _currentSession?.id;
          final isVisibleCurrentSession =
              isCurrentSession && _isChatRouteActive;
          final hasActiveCurrentSendTurn = _hasInFlightSendTurnForSession(
            sessionId,
          );
          final previousStatusType = _sessionStatusById[sessionId]?.type;
          final wasBusyBeforeIdle =
              previousStatusType == SessionStatusType.busy ||
              previousStatusType == SessionStatusType.retry;
          final hadErrorAttention = _sessionErrorAttentionIds.contains(
            sessionId,
          );
          if (!isCurrentSession &&
              previousStatusType == SessionStatusType.idle &&
              !hadErrorAttention) {
            break;
          }
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
            if (isVisibleCurrentSession) {
              _clearSessionAttentionForSession(sessionId);
              // Reactive dismiss: the user is already viewing this session, so
              // any lingering notification (completion, error, permission) is
              // stale and should be removed immediately.
              unawaited(eventFeedbackDispatcher?.dismissForSession(sessionId));
            } else if (wasBusyBeforeIdle || previousStatusType == null) {
              _markSessionUnreadCompletion(sessionId);
            }
            _clearActiveSendDraft();
            // OpenCode's session.idle is the terminal lifecycle signal for a
            // turn. End the active-send UI immediately even if CodeWalk's
            // fallback stream is still draining in the background; otherwise
            // the composer status can keep showing stale progress after the
            // final assistant response is already visible.
            _activeMessageStreamSessionId = null;
            _markIncompleteAssistantMessagesAsCompleted(sessionId: sessionId);
            // Cancel pending debounced message fallback timers — session.idle is
            // the terminal signal; no further remote resolution is needed. This
            // prevents unnecessary HTTP GETs that the monotonic guard would
            // discard.
            for (final entry in _messageFallbackDebounceById.entries.toList()) {
              final messageId = entry.key;
              final msgIndex = _messages.indexWhere((m) => m.id == messageId);
              if (msgIndex != -1 &&
                  _messages[msgIndex].sessionId == sessionId) {
                entry.value.cancel();
                _messageFallbackDebounceById.remove(messageId);
              }
            }
            if (_state == ChatState.sending) {
              _setState(ChatState.loaded);
            } else {
              _notifyListeners();
            }
          } else {
            if (wasBusyBeforeIdle || previousStatusType == null) {
              _markSessionUnreadCompletion(sessionId);
            }
            _notifyListeners();
          }
          if (isCurrentSession || _pendingRemoteSelectionSync) {
            _attemptPendingRemoteSelectionSync(reason: 'event-session.idle');
          }
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
          if (!isCurrentSession) {
            break;
          }
          final existingIndex = _messages.indexWhere(
            (message) => message.id == messageId,
          );
          if (event.type == 'message.created' && existingIndex != -1) {
            final existing = _messages[existingIndex];
            if (existing is AssistantMessage && existing.isCompleted) {
              _traceFinal(
                'event-${event.type}-fallback-skip-completed-local',
                sessionId: sessionId,
                details: 'messageId=$messageId',
              );
              break;
            }
          }
          _traceFinal(
            'event-${event.type}-fallback-fetch',
            sessionId: sessionId,
            details:
                'messageId=$messageId applyToCurrentSession=$isCurrentSession',
          );
          unawaited(_fetchMessageFallback(sessionId, messageId));
        }
        break;
      case 'message.part.updated':
      case 'message.part.delta':
        final partMap = properties['part'] as Map<String, dynamic>?;
        var part = partMap == null
            ? null
            : MessagePartModel.fromJson(partMap).toDomain();
        final sessionId = part?.sessionId ?? properties['sessionID'] as String?;
        final messageId = part?.messageId ?? properties['messageID'] as String?;
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
          resolvedPart = _preserveNonRegressivePartUpdate(
            existingPart: nextParts[existingPartIndex],
            incomingPart: resolvedPart,
          );
          if (nextParts[existingPartIndex] == resolvedPart) {
            break;
          }
          nextParts[existingPartIndex] = resolvedPart;
        }
        _messages[partIndex] = _copyMessageWithParts(message, nextParts);
        _markLocalMessageDeltaAdvanced(messageId);
        _messagesVersion++;
        if (event.type == 'message.part.delta' &&
            delta != null &&
            delta.isNotEmpty) {
          _scheduleDeltaNotification(reason: 'event-message-part-delta');
        } else {
          _notifyListeners(reason: 'event-message-part-updated');
        }
        final shouldAutoScroll =
            existingPartIndex == -1 ||
            resolvedPart is TextPart ||
            resolvedPart is ReasoningPart;
        if (delta != null && delta.isNotEmpty && message is AssistantMessage) {
          _scheduleDebouncedMessageFallback(
            sessionId,
            messageId,
            expectedLocalDeltaVersion: _messageLocalDeltaVersion(messageId),
          );
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
      case 'permission.v2.asked':
      case 'permission.v2.updated':
        ChatPermissionRequest permission;
        try {
          permission = ChatPermissionRequestModel.fromJson(
            _eventPayloadOrNested(properties, const <String>[
              'permission',
              'request',
              'info',
            ]),
          ).toDomain();
        } catch (error, stackTrace) {
          AppLogger.warn(
            'Failed to parse permission event; falling back to pending list',
            error: error,
            stackTrace: stackTrace,
          );
          _refreshPendingInteractionsForEvent(event.type);
          break;
        }
        if (permission.id.trim().isEmpty ||
            permission.sessionId.trim().isEmpty) {
          _refreshPendingInteractionsForEvent(event.type);
          break;
        }
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
      case 'permission.v2.replied':
        final replyPayload = _eventPayloadOrNested(properties, const <String>[
          'permission',
          'request',
          'info',
        ]);
        final sessionId =
            _extractEventSessionId(replyPayload) ??
            _extractEventSessionId(properties);
        final requestId =
            replyPayload['requestID'] as String? ??
            replyPayload['id'] as String?;
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
        // Reactive dismiss: when no pending permissions AND no pending
        // questions remain for this session, clear its notifications so
        // stale permission/question alerts do not linger.
        final hasRemainingPermissions =
            _pendingPermissionsBySession[sessionId]?.isNotEmpty ?? false;
        final hasRemainingQuestions =
            _pendingQuestionsBySession[sessionId]?.isNotEmpty ?? false;
        if (!hasRemainingPermissions && !hasRemainingQuestions) {
          unawaited(eventFeedbackDispatcher?.dismissForSession(sessionId));
        }
        // Sync background alert snapshot so the background worker does not
        // re-notify about this already-handled permission request.
        unawaited(
          AndroidBackgroundAlertWorker.removeNotifiedRequestIds(
            serverId: _activeServerId,
            permissionRequestIds: [requestId],
          ),
        );
        _notifyListeners();
        break;
      case 'question.asked':
      case 'question.updated':
      case 'question.v2.asked':
      case 'question.v2.updated':
        ChatQuestionRequest question;
        try {
          question = ChatQuestionRequestModel.fromJson(
            _eventPayloadOrNested(properties, const <String>[
              'question',
              'request',
              'info',
            ]),
          ).toDomain();
        } catch (error, stackTrace) {
          AppLogger.warn(
            'Failed to parse question event; falling back to pending list',
            error: error,
            stackTrace: stackTrace,
          );
          _refreshPendingInteractionsForEvent(event.type);
          break;
        }
        if (question.id.trim().isEmpty || question.sessionId.trim().isEmpty) {
          _refreshPendingInteractionsForEvent(event.type);
          break;
        }
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
      case 'question.v2.replied':
      case 'question.v2.rejected':
        final replyPayload = _eventPayloadOrNested(properties, const <String>[
          'question',
          'request',
          'info',
        ]);
        final sessionId =
            _extractEventSessionId(replyPayload) ??
            _extractEventSessionId(properties);
        final requestId =
            replyPayload['requestID'] as String? ??
            replyPayload['id'] as String?;
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
        // Reactive dismiss: when no pending permissions AND no pending
        // questions remain for this session, clear its notifications so
        // stale permission/question alerts do not linger.
        final hasRemainingPermissions =
            _pendingPermissionsBySession[sessionId]?.isNotEmpty ?? false;
        final hasRemainingQuestions =
            _pendingQuestionsBySession[sessionId]?.isNotEmpty ?? false;
        if (!hasRemainingPermissions && !hasRemainingQuestions) {
          unawaited(eventFeedbackDispatcher?.dismissForSession(sessionId));
        }
        // Sync background alert snapshot so the background worker does not
        // re-notify about this already-handled question request.
        unawaited(
          AndroidBackgroundAlertWorker.removeNotifiedRequestIds(
            serverId: _activeServerId,
            questionRequestIds: [requestId],
          ),
        );
        _notifyListeners();
        break;
      case 'session.next.moved':
        _dirtyContextKeys.add(_activeContextKey);
        _scheduleCurrentContextRefresh(
          reason: 'event-session.next.moved',
          refreshSessions: true,
          refreshStatus: true,
          refreshActiveSession: true,
        );
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
      if (_cellularDataSaverService.isAggressiveDataSaverActive) {
        final eventSessionId = _extractEventSessionId(event.properties);
        if (_hasVisibleAggressiveDataSaverSession &&
            _isVisibleAggressiveSessionId(eventSessionId) &&
            _tryApplyGlobalEventIncremental(event)) {
          return;
        }
        AppLogger.debug(
          'Suppressed aggressive data saver global event without directory type=$type',
        );
        return;
      }
      if (_tryApplyGlobalEventIncremental(event)) {
        return;
      }
      final currentSessionId = _currentSession?.id.trim();
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

    if (_cellularDataSaverService.isAggressiveDataSaverActive) {
      final eventSessionId = _extractEventSessionId(event.properties);
      if (targetContextKey == _activeContextKey &&
          _hasVisibleAggressiveDataSaverSession &&
          _isVisibleAggressiveSessionId(eventSessionId) &&
          _tryApplyGlobalEventIncremental(event)) {
        return;
      }
      AppLogger.debug(
        'Marked aggressive data saver context dirty without global reconcile context=$targetContextKey event=$type',
      );
      return;
    }

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
      'session.next.moved',
      'todo.updated',
      'message.created',
      'message.updated',
      'message.part.updated',
      'message.part.delta',
      'message.part.removed',
      'message.removed',
      'permission.asked',
      'permission.updated',
      'permission.replied',
      'permission.v2.asked',
      'permission.v2.updated',
      'permission.v2.replied',
      'question.asked',
      'question.updated',
      'question.replied',
      'question.rejected',
      'question.v2.asked',
      'question.v2.updated',
      'question.v2.replied',
      'question.v2.rejected',
    };
    if (!supportedTypes.contains(event.type)) {
      return false;
    }
    _applyChatEvent(event);
    return true;
  }

  void _scheduleGlobalFallbackReconcile(ChatEvent event) {
    final type = event.type;
    final currentSessionId = _currentSession?.id.trim();
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
    Map<String, List<ChatPermissionRequest>>? nextPendingPermissionsBySession;
    Map<String, List<ChatQuestionRequest>>? nextPendingQuestionsBySession;
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
        if (previousStatus?.type == nextStatus.type) {
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
            _isRootSessionInList(sessionId, snapshot.sessions) &&
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
        final hadErrorAttention = snapshot.sessionErrorAttentionIds.contains(
          sessionId,
        );
        if (previousStatusType == SessionStatusType.idle &&
            !hadErrorAttention) {
          return false;
        }
        const nextIdleStatus = SessionStatusInfo(type: SessionStatusType.idle);
        nextSessionStatusById = Map<String, SessionStatusInfo>.from(
          snapshot.sessionStatusById,
        )..[sessionId] = nextIdleStatus;
        nextErrorAttentionIds = Set<String>.from(
          snapshot.sessionErrorAttentionIds,
        )..remove(sessionId);
        final wasBusyBeforeIdle =
            previousStatusType == SessionStatusType.busy ||
            previousStatusType == SessionStatusType.retry;
        if ((wasBusyBeforeIdle || previousStatusType == null) &&
            _isRootSessionInList(sessionId, snapshot.sessions)) {
          nextUnreadCompletionIds = Set<String>.from(
            snapshot.sessionUnreadCompletionIds,
          )..add(sessionId);
          nextUnreadCompletionTimestamps = Map<String, DateTime>.from(
            snapshot.sessionUnreadCompletionTimestamps,
          )..[sessionId] = DateTime.now();
        }
        break;
      case 'session.error':
        final sessionId = event.properties['sessionID'] as String?;
        if (sessionId == null || sessionId.trim().isEmpty) {
          return false;
        }
        nextSessionStatusById = Map<String, SessionStatusInfo>.from(
          snapshot.sessionStatusById,
        )..[sessionId] = const SessionStatusInfo(type: SessionStatusType.idle);
        nextUnreadCompletionIds = Set<String>.from(
          snapshot.sessionUnreadCompletionIds,
        )..remove(sessionId);
        nextUnreadCompletionTimestamps = Map<String, DateTime>.from(
          snapshot.sessionUnreadCompletionTimestamps,
        )..remove(sessionId);
        nextErrorAttentionIds = Set<String>.from(
          snapshot.sessionErrorAttentionIds,
        )..add(sessionId);
        break;
      case 'permission.asked':
      case 'permission.updated':
      case 'permission.v2.asked':
      case 'permission.v2.updated':
        ChatPermissionRequest permission;
        try {
          permission = ChatPermissionRequestModel.fromJson(
            _eventPayloadOrNested(event.properties, const <String>[
              'permission',
              'request',
              'info',
            ]),
          ).toDomain();
        } catch (error, stackTrace) {
          AppLogger.warn(
            'Failed to parse inactive snapshot permission event',
            error: error,
            stackTrace: stackTrace,
          );
          return false;
        }
        if (permission.id.trim().isEmpty ||
            permission.sessionId.trim().isEmpty) {
          return false;
        }
        nextPendingPermissionsBySession =
            Map<String, List<ChatPermissionRequest>>.from(
              snapshot.pendingPermissionsBySession,
            );
        final sessionPermissions = List<ChatPermissionRequest>.from(
          nextPendingPermissionsBySession[permission.sessionId] ??
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
        nextPendingPermissionsBySession[permission.sessionId] =
            sessionPermissions;
        break;
      case 'permission.replied':
      case 'permission.v2.replied':
        final replyPayload = _eventPayloadOrNested(
          event.properties,
          const <String>['permission', 'request', 'info'],
        );
        final sessionId =
            _extractEventSessionId(replyPayload) ??
            _extractEventSessionId(event.properties);
        final requestId =
            replyPayload['requestID'] as String? ??
            replyPayload['id'] as String?;
        if (sessionId == null || requestId == null) {
          return false;
        }
        final existing = snapshot.pendingPermissionsBySession[sessionId];
        if (existing == null) {
          return false;
        }
        final filtered = existing
            .where((item) => item.id != requestId)
            .toList(growable: false);
        if (filtered.length == existing.length) {
          return false;
        }
        nextPendingPermissionsBySession =
            Map<String, List<ChatPermissionRequest>>.from(
              snapshot.pendingPermissionsBySession,
            );
        if (filtered.isEmpty) {
          nextPendingPermissionsBySession.remove(sessionId);
        } else {
          nextPendingPermissionsBySession[sessionId] = filtered;
        }
        break;
      case 'question.asked':
      case 'question.updated':
      case 'question.v2.asked':
      case 'question.v2.updated':
        ChatQuestionRequest question;
        try {
          question = ChatQuestionRequestModel.fromJson(
            _eventPayloadOrNested(event.properties, const <String>[
              'question',
              'request',
              'info',
            ]),
          ).toDomain();
        } catch (error, stackTrace) {
          AppLogger.warn(
            'Failed to parse inactive snapshot question event',
            error: error,
            stackTrace: stackTrace,
          );
          return false;
        }
        if (question.id.trim().isEmpty || question.sessionId.trim().isEmpty) {
          return false;
        }
        nextPendingQuestionsBySession =
            Map<String, List<ChatQuestionRequest>>.from(
              snapshot.pendingQuestionsBySession,
            );
        final sessionQuestions = List<ChatQuestionRequest>.from(
          nextPendingQuestionsBySession[question.sessionId] ??
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
        nextPendingQuestionsBySession[question.sessionId] = sessionQuestions;
        break;
      case 'question.replied':
      case 'question.rejected':
      case 'question.v2.replied':
      case 'question.v2.rejected':
        final replyPayload = _eventPayloadOrNested(
          event.properties,
          const <String>['question', 'request', 'info'],
        );
        final sessionId =
            _extractEventSessionId(replyPayload) ??
            _extractEventSessionId(event.properties);
        final requestId =
            replyPayload['requestID'] as String? ??
            replyPayload['id'] as String?;
        if (sessionId == null || requestId == null) {
          return false;
        }
        final existing = snapshot.pendingQuestionsBySession[sessionId];
        if (existing == null) {
          return false;
        }
        final filtered = existing
            .where((item) => item.id != requestId)
            .toList(growable: false);
        if (filtered.length == existing.length) {
          return false;
        }
        nextPendingQuestionsBySession =
            Map<String, List<ChatQuestionRequest>>.from(
              snapshot.pendingQuestionsBySession,
            );
        if (filtered.isEmpty) {
          nextPendingQuestionsBySession.remove(sessionId);
        } else {
          nextPendingQuestionsBySession[sessionId] = filtered;
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
    final effectivePendingPermissionsBySession =
        nextPendingPermissionsBySession ?? snapshot.pendingPermissionsBySession;
    final effectivePendingQuestionsBySession =
        nextPendingQuestionsBySession ?? snapshot.pendingQuestionsBySession;

    final changed =
        !listEquals(snapshot.sessions, effectiveSessions) ||
        !mapEquals(snapshot.sessionStatusById, effectiveSessionStatusById) ||
        !mapEquals(
          snapshot.pendingPermissionsBySession,
          effectivePendingPermissionsBySession,
        ) ||
        !mapEquals(
          snapshot.pendingQuestionsBySession,
          effectivePendingQuestionsBySession,
        ) ||
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

    final nextSnapshot = _ChatContextSnapshot(
      sessions: effectiveSessions,
      currentSession: snapshot.currentSession,
      messages: snapshot.messages,
      sessionStatusById: effectiveSessionStatusById,
      pendingPermissionsBySession: effectivePendingPermissionsBySession,
      pendingQuestionsBySession: effectivePendingQuestionsBySession,
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
      questionSubmitFailedRequestIds: snapshot.questionSubmitFailedRequestIds,
    );
    _contextSnapshots[contextKey] = nextSnapshot;
    final feedbackEvent = _feedbackEventForInactiveContext(
      event,
      previousSnapshot: snapshot,
    );
    if (feedbackEvent != null) {
      _dispatchFeedbackForInactiveContextEvent(
        feedbackEvent,
        snapshot: nextSnapshot,
      );
    }
    _dismissResolvedInactiveInteractionFeedback(event, snapshot: nextSnapshot);
    _scheduleSessionUnreadHighlightTimer();
    _notifyListeners();
    return true;
  }

  ChatEvent? _feedbackEventForInactiveContext(
    ChatEvent event, {
    required _ChatContextSnapshot previousSnapshot,
  }) {
    if (_shouldHandleFeedbackForEvent(event)) {
      return event;
    }
    if (event.type != 'session.status') {
      return null;
    }
    final sessionId = event.properties['sessionID'] as String?;
    final statusMap = event.properties['status'];
    if (sessionId == null || statusMap is! Map<String, dynamic>) {
      return null;
    }
    final status = _parseStatusForFeedback(statusMap);
    if (status?.type != SessionStatusType.idle) {
      return null;
    }
    final previousStatusType =
        previousSnapshot.sessionStatusById[sessionId]?.type;
    final completedFromActiveTurn =
        previousStatusType == null ||
        previousStatusType == SessionStatusType.busy ||
        previousStatusType == SessionStatusType.retry;
    if (!completedFromActiveTurn) {
      return null;
    }
    return _sessionIdleFeedbackEventFromStatus(event);
  }

  void _dispatchFeedbackForInactiveContextEvent(
    ChatEvent event, {
    required _ChatContextSnapshot snapshot,
  }) {
    if (!_shouldHandleFeedbackForEvent(event)) {
      return;
    }
    final eventSessionId = _extractEventSessionId(event.properties);
    unawaited(
      eventFeedbackDispatcher?.handle(
        event,
        sessionTitleHint: _sessionTitleForNotificationInList(
          eventSessionId,
          snapshot.sessions,
        ),
        isRootSession:
            eventSessionId == null ||
            _isRootSessionInList(eventSessionId, snapshot.sessions),
        isAppInForeground: _isAppInForeground,
        currentSessionId: _isChatRouteActive ? _currentSession?.id : null,
      ),
    );
  }

  String? _sessionTitleForNotificationInList(
    String? sessionId,
    List<ChatSession> sessions,
  ) {
    final normalizedSessionId = sessionId?.trim();
    if (normalizedSessionId == null || normalizedSessionId.isEmpty) {
      return null;
    }
    for (final session in sessions) {
      if (session.id != normalizedSessionId) {
        continue;
      }
      return SessionTitleFormatter.displayTitle(
        time: session.time,
        title: session.title,
      );
    }
    return null;
  }

  void _dismissResolvedInactiveInteractionFeedback(
    ChatEvent event, {
    required _ChatContextSnapshot snapshot,
  }) {
    switch (event.type) {
      case 'permission.replied':
      case 'permission.v2.replied':
      case 'question.replied':
      case 'question.rejected':
      case 'question.v2.replied':
      case 'question.v2.rejected':
        final replyPayload = _eventPayloadOrNested(
          event.properties,
          const <String>['permission', 'question', 'request', 'info'],
        );
        final sessionId =
            _extractEventSessionId(replyPayload) ??
            _extractEventSessionId(event.properties);
        final normalizedSessionId = sessionId?.trim();
        if (normalizedSessionId == null || normalizedSessionId.isEmpty) {
          return;
        }
        final hasRemainingPermissions =
            snapshot
                .pendingPermissionsBySession[normalizedSessionId]
                ?.isNotEmpty ??
            false;
        final hasRemainingQuestions =
            snapshot
                .pendingQuestionsBySession[normalizedSessionId]
                ?.isNotEmpty ??
            false;
        if (!hasRemainingPermissions && !hasRemainingQuestions) {
          unawaited(
            eventFeedbackDispatcher?.dismissForSession(normalizedSessionId),
          );
        }
    }
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

      final isAggressiveDataSaver =
          _cellularDataSaverService.isAggressiveDataSaverActive;

      if (shouldRefreshSessions && !isAggressiveDataSaver) {
        unawaited(loadSessions());
      }

      if (shouldRefreshActiveSession) {
        unawaited(
          refreshActiveSessionView(
            reason: 'scoped-reconcile:$reason',
            includeStatus:
                !isAggressiveDataSaver &&
                !shouldRefreshSessions &&
                shouldRefreshStatus,
          ),
        );
        return;
      }

      if (!shouldRefreshSessions &&
          shouldRefreshStatus &&
          !isAggressiveDataSaver) {
        unawaited(refreshSessionStatusSnapshot());
      }
    });
  }
}
