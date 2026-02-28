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

  bool _sessionNeedsFinalMessageReconcileOnIdle(String sessionId) {
    if (_currentSession?.id == sessionId) {
      final hasPendingLocalForSession = _messages.whereType<UserMessage>().any(
        (message) =>
            message.sessionId == sessionId &&
            _pendingLocalUserMessageIds.contains(message.id),
      );
      if (_state == ChatState.sending || hasPendingLocalForSession) {
        return true;
      }
    }

    AssistantMessage? latestAssistant;
    for (var index = _messages.length - 1; index >= 0; index -= 1) {
      final message = _messages[index];
      if (message.sessionId != sessionId || message is! AssistantMessage) {
        continue;
      }
      latestAssistant = message;
      break;
    }

    if (latestAssistant == null) {
      return false;
    }

    if (!latestAssistant.isCompleted) {
      return true;
    }

    var hasVisibleText = false;
    var hasToolSurface = false;
    for (final part in latestAssistant.parts) {
      if (part is TextPart && part.text.trim().isNotEmpty) {
        hasVisibleText = true;
      }
      if (part is ToolPart || part is PatchPart) {
        hasToolSurface = true;
      }
    }

    if (hasVisibleText) {
      return false;
    }

    if (latestAssistant.error != null) {
      return false;
    }

    return hasToolSurface || latestAssistant.parts.isEmpty;
  }

  void _recordIdleReconcileTelemetry({
    required String sessionId,
    required bool triggered,
    required String decision,
    required bool isCurrent,
    required bool hasPreserved,
  }) {
    _idleReconcileEvaluations += 1;
    if (triggered) {
      _idleReconcileTriggers += 1;
    } else {
      _idleReconcileSkips += 1;
    }
    AppLogger.info(
      'CW_METRIC idle_reconcile eval=$_idleReconcileEvaluations triggers=$_idleReconcileTriggers skips=$_idleReconcileSkips session=$sessionId decision=$decision current=$isCurrent preserved=$hasPreserved generation=$_messageStreamGeneration',
    );
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
    if (!isSessionLifecycle || eventSessionId == _currentSession?.id) {
      final sessionTitleHint = _sessionTitleForNotification(eventSessionId);
      unawaited(
        eventFeedbackDispatcher?.handle(
          event,
          sessionTitleHint: sessionTitleHint,
          isAppInForeground: _isAppInForeground,
          currentSessionId: _currentSession?.id,
        ),
      );
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
            _currentSession = nextSession;
            _threadPermissionsVersion++;
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
          _sessionStatusById[sessionId] = status;
          if (status.type == SessionStatusType.retry &&
              sessionId != _currentSession?.id) {
            _sessionErrorAttentionIds.add(sessionId);
          } else {
            _sessionErrorAttentionIds.remove(sessionId);
          }
          if (status.type == SessionStatusType.busy ||
              status.type == SessionStatusType.retry) {
            _sessionUnreadCompletionIds.remove(sessionId);
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
                (item) => SessionDiff(
                  file: item['file'] as String? ?? '',
                  before: item['before'] as String? ?? '',
                  after: item['after'] as String? ?? '',
                  additions: (item['additions'] as num?)?.toInt() ?? 0,
                  deletions: (item['deletions'] as num?)?.toInt() ?? 0,
                  status: item['status'] as String?,
                ),
              )
              .toList(growable: false);
          _sessionDiffById[sessionId] = parsed;
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
          final previousStatusType = _sessionStatusById[sessionId]?.type;
          _sessionStatusById[sessionId] = const SessionStatusInfo(
            type: SessionStatusType.idle,
          );
          // Defer completion marking when a preserved stream is still
          // draining for this session — onDone of that stream handles it.
          final hasPreserved = _hasPreservedStreamForSession(sessionId);
          // Build a turn key using the stream generation counter so the guard
          // resets when a new send starts (_messageStreamGeneration increments
          // per send) without being affected by messages from other sessions.
          final idleTurnKey = '$sessionId:$_messageStreamGeneration';
          final shouldReconcileCurrentSession =
              isCurrentSession &&
              !hasPreserved &&
              _lastIdleReconcileSessionTurnKey != idleTurnKey &&
              _sessionNeedsFinalMessageReconcileOnIdle(sessionId);
          String reconcileDecision;
          if (!isCurrentSession) {
            reconcileDecision = 'non_current_session';
          } else if (hasPreserved) {
            reconcileDecision = 'preserved_stream';
          } else if (_lastIdleReconcileSessionTurnKey == idleTurnKey) {
            reconcileDecision = 'already_reconciled_turn';
          } else if (shouldReconcileCurrentSession) {
            reconcileDecision = 'triggered';
          } else {
            reconcileDecision = 'not_needed';
          }
          if (isCurrentSession) {
            _recordIdleReconcileTelemetry(
              sessionId: sessionId,
              triggered: shouldReconcileCurrentSession,
              decision: reconcileDecision,
              isCurrent: isCurrentSession,
              hasPreserved: hasPreserved,
            );
          }
          _traceFinal(
            'event-session-idle',
            sessionId: sessionId,
            details:
                'isCurrent=$isCurrentSession hasPreserved=$hasPreserved shouldReconcile=$shouldReconcileCurrentSession decision=$reconcileDecision idleTurnKey=$idleTurnKey lastIdleTurn=${_lastIdleReconcileSessionTurnKey ?? "-"}',
          );
          AppLogger.info(
            'session.idle session=$sessionId isCurrent=$isCurrentSession hasPreservedStream=$hasPreserved decision=$reconcileDecision',
          );
          if (!hasPreserved) {
            _markIncompleteAssistantMessagesAsCompleted(sessionId: sessionId);
          }
          _sessionErrorAttentionIds.remove(sessionId);
          if (isCurrentSession) {
            _clearSessionAttentionForSession(sessionId);
            _activeMessageStreamSessionId = null;
            _clearActiveSendDraft();
            if (_state == ChatState.sending) {
              _setState(ChatState.loaded);
            } else {
              _notifyListeners();
            }
            if (shouldReconcileCurrentSession) {
              // Mark one-shot so repeated session.idle events in the same
              // turn do not trigger additional reconcile calls.
              _lastIdleReconcileSessionTurnKey = idleTurnKey;
              _traceFinal(
                'event-session-idle-trigger-reconcile',
                sessionId: sessionId,
                details:
                    'reason=session-idle-final-reconcile allowDuringAbortSuppression=true',
              );
              unawaited(
                refreshActiveSessionView(
                  reason: 'session-idle-final-reconcile',
                  includeStatus: false,
                  allowDuringAbortSuppression: true,
                ),
              );
            }
          } else {
            final wasBusyBeforeIdle =
                previousStatusType == SessionStatusType.busy ||
                previousStatusType == SessionStatusType.retry;
            if (hasPreserved || wasBusyBeforeIdle) {
              _sessionUnreadCompletionIds.add(sessionId);
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
          // Defer completion marking when a preserved stream is still
          // draining for this session — onDone of that stream handles it.
          final hasPreservedErr = _hasPreservedStreamForSession(sessionId);
          AppLogger.info(
            'session.error non-current session=$sessionId hasPreservedStream=$hasPreservedErr',
          );
          if (!hasPreservedErr) {
            _markIncompleteAssistantMessagesAsCompleted(sessionId: sessionId);
          }
          _sessionUnreadCompletionIds.remove(sessionId);
          _sessionErrorAttentionIds.add(sessionId);
          _notifyListeners();
          break;
        }

        final rawError = properties['error'];
        final error = rawError is Map
            ? Map<String, dynamic>.from(rawError)
            : null;
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
        _traceFinal(
          'event-session-error-current-session-payload',
          sessionId: sessionId,
          details: 'code=${code ?? "-"} message=$message',
        );
        AppLogger.info(
          'session.error current session=$sessionId message=$message code=$code hasPreservedStream=${_hasPreservedStreamForSession(sessionId)}',
        );
        if (_shouldSuppressAbortError(sessionId: sessionId, message: message)) {
          _sessionStatusById[sessionId] = const SessionStatusInfo(
            type: SessionStatusType.idle,
          );
          _clearSessionAttentionForSession(sessionId);
          _errorMessage = null;
          _setState(ChatState.loaded);
          break;
        }
        if (_isRemoteAbortError(message: message, code: code)) {
          _sessionStatusById[sessionId] = const SessionStatusInfo(
            type: SessionStatusType.idle,
          );
          _clearSessionAttentionForSession(sessionId);
          _errorMessage = null;
          _markIncompleteAssistantMessagesAsCompleted(sessionId: sessionId);
          _appendInlineAbortMessage(sessionId: sessionId);
          _setState(ChatState.loaded);
          break;
        }
        _setError(message);
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
        final part = partMap == null
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
        if (part == null ||
            partIndex == -1 ||
            (delta != null && delta.isNotEmpty)) {
          unawaited(_fetchMessageFallback(sessionId, messageId));
          break;
        }
        final message = _messages[partIndex];
        final nextParts = List<MessagePart>.from(message.parts);
        final existingPartIndex = nextParts.indexWhere(
          (item) => item.id == part.id,
        );
        if (existingPartIndex == -1) {
          nextParts.add(part);
        } else {
          if (nextParts[existingPartIndex] == part) {
            break;
          }
          nextParts[existingPartIndex] = part;
        }
        _messages[partIndex] = _copyMessageWithParts(message, nextParts);
        _messagesVersion++;
        _notifyListeners();
        if (!_isCompactingContext && isSessionActivelyResponding(sessionId)) {
          _scheduleScrollToBottom();
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
        _notifyListeners();
        break;
      default:
        break;
    }
  }

  void _handleGlobalEvent(ChatEvent event) {
    if (_isEphemeralTitleEvent(event)) return;

    final type = event.type;
    final affectsContext =
        type.startsWith('session.') ||
        type.startsWith('message.') ||
        type.startsWith('project.') ||
        type.startsWith('worktree.');
    if (!affectsContext) {
      return;
    }

    final directory = _extractDirectoryFromEvent(event);
    if (directory == null || directory.trim().isEmpty) {
      _dirtyContextKeys.add(_activeContextKey);
      if (_tryApplyGlobalEventIncremental(event)) {
        return;
      }
      _scheduleCurrentContextRefresh(
        reason: 'global:$type:no-directory',
        refreshSessions: true,
        refreshStatus: true,
        refreshActiveSession: true,
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

    _contextSnapshots.remove(targetContextKey);
    unawaited(_clearPersistedContextCache(targetContextKey));
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
    final refreshSessions =
        type.startsWith('session.') ||
        type.startsWith('project.') ||
        type.startsWith('worktree.');
    final refreshActiveSession = type.startsWith('message.');
    _scheduleCurrentContextRefresh(
      reason: 'global:$type:fallback',
      refreshSessions: refreshSessions,
      refreshStatus: refreshSessions || refreshActiveSession,
      refreshActiveSession: refreshActiveSession,
    );
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
