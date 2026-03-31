part of '../chat_provider.dart';

extension _ChatProviderMessageMergeOps on ChatProvider {
  bool _areMessageListsSemanticallyEqual(
    List<ChatMessage> a,
    List<ChatMessage> b,
  ) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index += 1) {
      if (identical(a[index], b[index])) {
        continue;
      }
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }

  void _scheduleDebouncedMessageFallback(
    String sessionId,
    String messageId, {
    bool applyToCurrentSession = true,
    Duration delay = const Duration(milliseconds: 120),
  }) {
    _messageFallbackDebounceById.remove(messageId)?.cancel();
    _messageFallbackDebounceById[messageId] = Timer(delay, () {
      _messageFallbackDebounceById.remove(messageId);
      unawaited(
        _fetchMessageFallback(
          sessionId,
          messageId,
          applyToCurrentSession: applyToCurrentSession,
        ),
      );
    });
  }

  Future<void> _fetchMessageFallback(
    String sessionId,
    String messageId, {
    bool applyToCurrentSession = true,
  }) async {
    _messageFallbackDebounceById.remove(messageId)?.cancel();
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
          next.sort((a, b) => a.time.compareTo(b.time));
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

  // Determines whether a locally-appended optimistic user bubble should be
  // suppressed because the server has already echoed it in the merged message list.
  //
  // INVARIANT — the prefix check on line below is load-bearing (see ADR-023 Pitfall P-001):
  // Only messages with the `local_user_*` prefix are candidates for echo suppression.
  // If the optimistic ID ever uses a server-format prefix (e.g. `msg_*`), this guard
  // returns `false` immediately, the bubble is treated as a confirmed server message,
  // and subsequent SSE reconciliation silently discards assistant responses. The prefix
  // must always match what `_nextLocalUserMessageId()` produces. (Regression: b0660a2)
  bool _shouldSkipLocalUserAppendAsDuplicateEcho({
    required UserMessage localMessage,
    required List<ChatMessage> mergedMessages,
  }) {
    if (!_isOptimisticLocalUserMessageId(localMessage.id)) {
      return false;
    }
    final localSignature = _normalizedUserMessageSignature(localMessage);
    if (localSignature.isNotEmpty) {
      for (final serverMessage in mergedMessages) {
        if (serverMessage is! UserMessage) {
          continue;
        }
        final serverSignature = _normalizedUserMessageSignature(serverMessage);
        if (serverSignature.isNotEmpty && serverSignature == localSignature) {
          return true;
        }
      }
    }

    UserMessage? latestServerUserMessage;
    var hasInProgressAssistant = false;
    for (final message in mergedMessages) {
      if (message is UserMessage) {
        latestServerUserMessage = message;
      } else if (message is AssistantMessage && !message.isCompleted) {
        hasInProgressAssistant = true;
      }
    }

    if (!hasInProgressAssistant || latestServerUserMessage == null) {
      return false;
    }

    final latestServerSignature = _normalizedUserMessageSignature(
      latestServerUserMessage,
    );
    if (localSignature.isNotEmpty && latestServerSignature.isNotEmpty) {
      final sharesPrefix =
          localSignature.startsWith(latestServerSignature) ||
          latestServerSignature.startsWith(localSignature);
      if (!sharesPrefix) {
        return false;
      }
    }

    final earliestEchoTime = localMessage.time.subtract(
      const Duration(seconds: 2),
    );
    final latestEchoTime = localMessage.time.add(const Duration(seconds: 45));
    final serverTime = latestServerUserMessage.time;
    if (serverTime.isBefore(earliestEchoTime) ||
        serverTime.isAfter(latestEchoTime)) {
      return false;
    }

    return true;
  }

  /// Merges server messages with any pending local user messages that haven't
  /// been echoed by the server yet. Returns both the merged list and the set of
  /// local IDs that were reconciled (matched to a server message by content
  /// signature), so callers can avoid re-adding them during tail preservation.
  ({List<ChatMessage> messages, Set<String> reconciledLocalIds})
  _mergeServerMessagesWithPendingLocalUsers(List<ChatMessage> serverMessages) {
    // Internal provider state appends messages in-place during sends/streaming,
    // so merged results must stay growable even when the source list is not.
    final emptyResult = (
      messages: List<ChatMessage>.from(serverMessages),
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

    final reconciledLocalSignatureCounts = <String, int>{};
    for (final message in _messages) {
      if (message is! UserMessage) {
        continue;
      }
      if (!reconciledLocalIds.contains(message.id)) {
        continue;
      }
      final signature = _normalizedUserMessageSignature(message);
      if (signature.isEmpty) {
        continue;
      }
      reconciledLocalSignatureCounts.update(
        signature,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    for (final message in _messages) {
      if (message is! UserMessage) {
        continue;
      }
      if (!_pendingLocalUserMessageIds.contains(message.id)) {
        continue;
      }
      final localSignature = _normalizedUserMessageSignature(message);
      final signatureAlreadyReconciledThisPass =
          localSignature.isNotEmpty &&
          (reconciledLocalSignatureCounts[localSignature] ?? 0) > 0;
      if (signatureAlreadyReconciledThisPass) {
        merged.add(message);
        continue;
      }
      if (_shouldSkipLocalUserAppendAsDuplicateEcho(
        localMessage: message,
        mergedMessages: merged,
      )) {
        reconciledLocalIds.add(message.id);
        _pendingLocalUserMessageIds.remove(message.id);
        continue;
      }
      if (existingIds.contains(message.id)) {
        continue;
      }
      merged.add(message);
    }

    return (messages: merged, reconciledLocalIds: reconciledLocalIds);
  }

  ({List<ChatMessage> messages, bool requiresFullFetch, bool usedGapRecovery})
  _mergeServerTailWithCachedMessages({
    required List<ChatMessage> serverMessages,
    required List<ChatMessage> cachedMessages,
    required String sessionId,
  }) {
    final serverForSession = serverMessages
        .where((message) => message.sessionId == sessionId)
        .toList(growable: false);
    if (serverForSession.isEmpty) {
      return (
        messages: serverMessages,
        requiresFullFetch: false,
        usedGapRecovery: false,
      );
    }

    final cachedForSession = cachedMessages
        .where((message) => message.sessionId == sessionId)
        .toList(growable: false);
    if (cachedForSession.isEmpty) {
      return (
        messages: serverForSession,
        requiresFullFetch: false,
        usedGapRecovery: false,
      );
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
      final optimisticOverlap = _findOptimisticTailOverlap(
        serverForSession: serverForSession,
        cachedForSession: cachedForSession,
      );
      if (optimisticOverlap != null) {
        overlapServerIndex = optimisticOverlap.serverIndex;
        overlapCachedIndex = optimisticOverlap.cachedIndex;
      }
    }

    if (overlapServerIndex == -1 || overlapCachedIndex == -1) {
      // No safe overlap means the cached snapshot cannot stay authoritative.
      // Surface the server tail immediately, mark the history as incomplete,
      // and let the caller force a full fetch before persisting any snapshot.
      return (
        messages: serverForSession,
        requiresFullFetch: true,
        usedGapRecovery: true,
      );
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

    return (
      messages: deduplicated,
      requiresFullFetch: false,
      usedGapRecovery: false,
    );
  }

  ({int serverIndex, int cachedIndex})? _findOptimisticTailOverlap({
    required List<ChatMessage> serverForSession,
    required List<ChatMessage> cachedForSession,
  }) {
    for (
      var serverIndex = 0;
      serverIndex < serverForSession.length;
      serverIndex += 1
    ) {
      final serverMessage = serverForSession[serverIndex];
      if (serverMessage is! UserMessage) {
        continue;
      }

      final serverSignature = _normalizedUserMessageSignature(serverMessage);
      var matchedCachedIndex = -1;
      Duration? matchedDelta;
      var sawAmbiguousEmptySignatureCandidate = false;
      var sawAmbiguousSignatureCandidate = false;
      var matchedCandidateCount = 0;

      for (
        var cachedIndex = 0;
        cachedIndex < cachedForSession.length;
        cachedIndex += 1
      ) {
        final cachedMessage = cachedForSession[cachedIndex];
        if (cachedMessage is! UserMessage) {
          continue;
        }
        final isOptimisticCandidate =
            _pendingLocalUserMessageIds.contains(cachedMessage.id) ||
            _isOptimisticLocalUserMessageId(cachedMessage.id);
        if (!isOptimisticCandidate) {
          continue;
        }

        final delta = serverMessage.time.difference(cachedMessage.time).abs();
        if (delta > const Duration(minutes: 5)) {
          continue;
        }

        if (serverSignature.isEmpty) {
          if (!_pendingLocalUserMessageIds.contains(cachedMessage.id)) {
            continue;
          }
          if (matchedCachedIndex != -1) {
            sawAmbiguousEmptySignatureCandidate = true;
            break;
          }
          matchedCachedIndex = cachedIndex;
          matchedDelta = delta;
          continue;
        }

        final cachedSignature = _normalizedUserMessageSignature(cachedMessage);
        final signaturesMatch =
            cachedSignature == serverSignature ||
            _isLikelyPendingLocalUserMatch(
              pending: cachedMessage,
              incoming: serverMessage,
            );
        if (!signaturesMatch) {
          continue;
        }

        matchedCandidateCount += 1;
        if (matchedCandidateCount > 1) {
          sawAmbiguousSignatureCandidate = true;
          break;
        }

        if (matchedDelta == null || delta < matchedDelta) {
          matchedCachedIndex = cachedIndex;
          matchedDelta = delta;
        }
      }

      if (sawAmbiguousEmptySignatureCandidate ||
          sawAmbiguousSignatureCandidate) {
        continue;
      }
      if (matchedCachedIndex != -1) {
        return (serverIndex: serverIndex, cachedIndex: matchedCachedIndex);
      }
    }

    return null;
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
      return List<ChatMessage>.from(merged);
    }

    final existingIds = merged.map((message) => message.id).toSet();
    // Treat reconciled local IDs as already present so they are not re-added.
    existingIds.addAll(reconciledLocalIds);
    final localMessages = _messages
        .where((message) => message.sessionId == sessionId)
        .toList(growable: false);
    if (localMessages.isEmpty) {
      return List<ChatMessage>.from(merged);
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
      if (message is UserMessage &&
          _shouldSkipLocalUserAppendAsDuplicateEcho(
            localMessage: message,
            mergedMessages: merged,
          )) {
        _pendingLocalUserMessageIds.remove(message.id);
        continue;
      }
      merged.add(message);
      existingIds.add(message.id);
    }

    return List<ChatMessage>.from(merged);
  }
}
