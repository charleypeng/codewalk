part of '../chat_page.dart';

extension _ChatPageTimelineRuntime on _ChatPageState {
  Widget _buildInteractionPrompts(ChatProvider chatProvider) {
    final permissionRequests = chatProvider.currentThreadPermissionRequests;
    final subagentPermissionIds =
        chatProvider.currentThreadSubagentPermissionRequestIds;
    final questionRequest = chatProvider.currentQuestionRequest;
    if (permissionRequests.isEmpty && questionRequest == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        for (final permissionRequest in permissionRequests)
          PermissionRequestCard(
            key: ValueKey<String>(
              'interaction_permission_request_${permissionRequest.id}',
            ),
            request: permissionRequest,
            busy: chatProvider.isRespondingInteraction,
            originBadgeLabel:
                subagentPermissionIds.contains(permissionRequest.id)
                ? 'Subagent'
                : null,
            onDecide: (reply) {
              unawaited(
                chatProvider.respondPermissionRequest(
                  requestId: permissionRequest.id,
                  reply: reply,
                ),
              );
            },
          ),
        if (questionRequest != null)
          QuestionRequestCard(
            request: questionRequest,
            busy: chatProvider.isRespondingInteraction,
            onSubmit: (answers) {
              unawaited(
                chatProvider.submitQuestionAnswers(
                  requestId: questionRequest.id,
                  answers: answers,
                ),
              );
            },
            onReject: () {
              unawaited(
                chatProvider.rejectQuestionRequest(
                  requestId: questionRequest.id,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildInlinePermissionPromptEntry(
    _TimelinePermissionPromptEntry entry,
    ChatProvider chatProvider,
  ) {
    return PermissionRequestCard(
      key: ValueKey<String>('timeline_permission_request_${entry.request.id}'),
      request: entry.request,
      busy: chatProvider.isRespondingInteraction,
      originBadgeLabel: entry.fromSubagent ? 'Subagent' : null,
      onDecide: (reply) {
        unawaited(
          chatProvider.respondPermissionRequest(
            requestId: entry.request.id,
            reply: reply,
          ),
        );
      },
    );
  }

  String _sessionStatusLabel(SessionStatusInfo status) {
    switch (status.type) {
      case SessionStatusType.busy:
        return 'Status: Busy';
      case SessionStatusType.retry:
        final attempt = status.attempt ?? 0;
        if (attempt > 0) {
          return 'Status: Retry #$attempt';
        }
        return 'Status: Retry';
      case SessionStatusType.idle:
        return 'Status: Idle';
    }
  }

  String _sessionDisplayTitle(ChatSession session) {
    return SessionTitleFormatter.displayTitle(
      time: session.time,
      title: session.title,
    );
  }

  String _sessionEditingValue(ChatSession session) {
    final raw = session.title?.trim();
    if (raw != null && raw.isNotEmpty) {
      return raw;
    }
    return SessionTitleFormatter.fallbackTitle(time: session.time);
  }

  int? _findTimelineEntryIndexByKey(Key key, List<_TimelineEntry> entries) {
    if (key is! ValueKey<String>) {
      return null;
    }
    final targetKey = key.value;
    for (var index = 0; index < entries.length; index += 1) {
      if (entries[index].key == targetKey) {
        return index;
      }
    }
    return null;
  }

  void _setCollapsedHistoryGroupExpanded({
    required String groupId,
    required bool expanded,
  }) {
    final nextGroupId = expanded ? groupId : null;
    if (_expandedCollapsedHistoryGroupId == nextGroupId) {
      return;
    }
    _setState(() {
      _expandedCollapsedHistoryGroupId = nextGroupId;
    });
  }

  void _setAssistantWorkGroupExpanded({
    required String groupId,
    required bool expanded,
  }) {
    final nextGroupId = expanded ? groupId : null;
    if (_expandedAssistantWorkGroupId == nextGroupId) {
      return;
    }
    _setState(() {
      _expandedAssistantWorkGroupId = nextGroupId;
    });
  }

  Widget _buildCollapsedHistoryEntry(_TimelineCollapsedHistoryEntry entry) {
    final colorScheme = Theme.of(context).colorScheme;
    final group = entry.group;
    final actionLabel = entry.expanded
        ? 'Hide earlier messages'
        : 'Show earlier messages';
    final actionIcon = entry.expanded
        ? Symbols.unfold_less_rounded
        : Symbols.unfold_more_rounded;

    return Padding(
      key: ValueKey<String>(entry.key),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Container(
            key: const ValueKey<String>('timeline_collapsed_history_header'),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Symbols.history_toggle_off_rounded,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Previous history is collapsed',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      key: const ValueKey<String>(
                        'timeline_collapsed_history_toggle',
                      ),
                      onPressed: () => _setCollapsedHistoryGroupExpanded(
                        groupId: group.id,
                        expanded: !entry.expanded,
                      ),
                      icon: Icon(actionIcon, size: 16),
                      label: Text(actionLabel),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${group.messageCount} messages hidden before ${group.compactionLabel} compaction',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedAssistantWorkEntry(
    _TimelineCollapsedAssistantWorkEntry entry,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final group = entry.group;
    final actionLabel = entry.expanded
        ? 'Hide work messages'
        : 'Show work messages';
    final actionIcon = entry.expanded
        ? Symbols.unfold_less_rounded
        : Symbols.unfold_more_rounded;

    return Padding(
      key: ValueKey<String>(entry.key),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Container(
            key: const ValueKey<String>(
              'timeline_collapsed_assistant_work_header',
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Symbols.account_tree_rounded,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Work messages are collapsed',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      key: const ValueKey<String>(
                        'timeline_collapsed_assistant_work_toggle',
                      ),
                      onPressed: () => _setAssistantWorkGroupExpanded(
                        groupId: group.id,
                        expanded: !entry.expanded,
                      ),
                      icon: Icon(actionIcon, size: 16),
                      label: Text(actionLabel),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${group.messageCount} assistant work messages hidden before final response',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int? _findLatestCompactionBoundaryIndex(
    List<ChatMessage> messages, {
    required bool allowInProgressBoundary,
  }) {
    for (var index = messages.length - 1; index >= 0; index -= 1) {
      if (_isCompactionBoundaryMessage(
        messages[index],
        allowInProgressBoundary: allowInProgressBoundary,
      )) {
        return index;
      }
    }
    return null;
  }

  bool _isCompactionBoundaryMessage(
    ChatMessage message, {
    required bool allowInProgressBoundary,
  }) {
    final isBoundary =
        _findCompactionPart(message) != null ||
        _isCompactionSummaryMessage(message);
    if (!isBoundary) {
      return false;
    }
    if (allowInProgressBoundary) {
      return true;
    }
    if (message is AssistantMessage) {
      return message.isCompleted;
    }
    return true;
  }

  bool _isCompactionSummaryMessage(ChatMessage message) {
    return message is AssistantMessage && message.summary == true;
  }

  CompactionPart? _findCompactionPart(ChatMessage message) {
    for (final part in message.parts) {
      if (part is CompactionPart) {
        return part;
      }
    }
    return null;
  }

  Widget _buildRetryingMessageIndicator() {
    return Container(
      key: const ValueKey<String>('timeline_retry_indicator'),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SizedBox(width: 40),
          const SizedBox(width: 12),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            'Retrying model request...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String? _resolveLatestReasoningPartKey(List<ChatMessage> messages) {
    // Cache: skip O(N*M) backward scan when messages haven't changed.
    final lastId = messages.isNotEmpty ? messages.last.id : null;
    if (_cachedReasoningKeyComputed &&
        messages.length == _cachedReasoningKeyMsgCount &&
        lastId == _cachedReasoningKeyLastMsgId) {
      return _cachedReasoningKeyResult;
    }

    String? result;
    for (
      var messageIndex = messages.length - 1;
      messageIndex >= 0;
      messageIndex -= 1
    ) {
      final message = messages[messageIndex];
      for (
        var partIndex = message.parts.length - 1;
        partIndex >= 0;
        partIndex -= 1
      ) {
        final part = message.parts[partIndex];
        if (part is ReasoningPart) {
          result = '${part.messageId}::${part.id}';
          break;
        }
      }
      if (result != null) break;
    }

    _cachedReasoningKeyMsgCount = messages.length;
    _cachedReasoningKeyLastMsgId = lastId;
    _cachedReasoningKeyResult = result;
    _cachedReasoningKeyComputed = true;
    return result;
  }

  String? _resolveLatestReasoningStatusLabel(List<ChatMessage> messages) {
    for (
      var messageIndex = messages.length - 1;
      messageIndex >= 0;
      messageIndex -= 1
    ) {
      final message = messages[messageIndex];
      if (message is! AssistantMessage || message.isCompleted) {
        continue;
      }
      for (
        var partIndex = message.parts.length - 1;
        partIndex >= 0;
        partIndex -= 1
      ) {
        final part = message.parts[partIndex];
        if (part is! ReasoningPart) {
          continue;
        }
        final label = parseReasoningStatusLabel(part.text);
        if (label != null) {
          return label;
        }
      }
    }
    return null;
  }

  _AssistantProgressStage? _resolveAssistantProgressStage(
    ChatProvider chatProvider,
  ) {
    final messages = chatProvider.messages;
    final lastId = messages.isNotEmpty ? messages.last.id : null;
    final isResponding = chatProvider.isCurrentSessionActivelyResponding;

    // Cache: skip O(N) scan when messages and responding state haven't changed.
    if (_cachedProgressStageComputed &&
        messages.length == _cachedProgressStageMsgCount &&
        lastId == _cachedProgressStageLastMsgId &&
        isResponding == _cachedProgressStageResponding) {
      return _cachedProgressStageResult;
    }

    final statusType = chatProvider.currentSessionStatus?.type;
    final hasStreamingAssistantParts = messages
        .whereType<AssistantMessage>()
        .any((message) => !message.isCompleted && message.parts.isNotEmpty);

    _AssistantProgressStage? result;
    if (!isResponding) {
      result = null;
    } else if (statusType == SessionStatusType.retry) {
      result = _AssistantProgressStage.retrying;
    } else if (hasStreamingAssistantParts) {
      result = _AssistantProgressStage.receiving;
    } else {
      result = _AssistantProgressStage.thinking;
    }

    _cachedProgressStageMsgCount = messages.length;
    _cachedProgressStageLastMsgId = lastId;
    _cachedProgressStageResponding = isResponding;
    _cachedProgressStageResult = result;
    _cachedProgressStageComputed = true;
    return result;
  }
}
