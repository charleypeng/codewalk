part of '../chat_page.dart';

extension _ChatPageTimelineBuilder on _ChatPageState {
  Widget _buildChatContent({
    required ChatProvider chatProvider,
    required bool isKeyboardOpen,
    required double maxContentWidth,
    required double horizontalPadding,
    required double verticalPadding,
  }) {
    final selectedModel = chatProvider.selectedModel;
    final supportsImages = _supportsImageAttachments(selectedModel);
    final supportsPdf = _supportsPdfAttachments(selectedModel);
    final attachmentsEnabled = supportsImages || supportsPdf;
    final composerStatusTarget = _resolveComposerStatusTarget(chatProvider);
    _queueComposerStatusSync(composerStatusTarget);
    final composerStatus = _priorityComposerStatus ?? _visibleComposerStatus;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Column(
            children: [
              // Active session header
              if (chatProvider.currentSession != null)
                Builder(
                  builder: (context) {
                    final currentSession = chatProvider.currentSession!;
                    return Container(
                      key: const ValueKey<String>(
                        'chat_compact_session_header',
                      ),
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                      child: Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: SessionTitleInlineEditor(
                                  key: ValueKey<String>(
                                    'chat_header_session_title_editor_${currentSession.id}',
                                  ),
                                  title: _sessionDisplayTitle(currentSession),
                                  editingValue: _sessionEditingValue(
                                    currentSession,
                                  ),
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                  onRename: (title) => chatProvider
                                      .renameSession(currentSession, title),
                                ),
                              ),
                              Builder(
                                builder: (context) {
                                  final usage = _resolveSessionContextUsage(
                                    chatProvider,
                                  );
                                  final canCompact =
                                      !chatProvider.isCompactingContext &&
                                      !chatProvider.canAbortActiveResponse;

                                  return PopupMenuButton<_ContextUsageAction>(
                                    key: const ValueKey<String>(
                                      'appbar_context_usage_button',
                                    ),
                                    tooltip: 'Compact Context',
                                    padding: EdgeInsets.zero,
                                    onSelected: (action) {
                                      if (action ==
                                          _ContextUsageAction.compactNow) {
                                        unawaited(
                                          _compactCurrentSession(chatProvider),
                                        );
                                      }
                                    },
                                    itemBuilder: (context) {
                                      return [
                                        PopupMenuItem<_ContextUsageAction>(
                                          enabled: false,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          child: _buildContextUsagePopover(
                                            context,
                                            usage: usage,
                                            isCompacting: chatProvider
                                                .isCompactingContext,
                                          ),
                                        ),
                                        const PopupMenuDivider(height: 0),
                                        PopupMenuItem<_ContextUsageAction>(
                                          value: _ContextUsageAction.compactNow,
                                          enabled: canCompact,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Symbols.compress,
                                                size: 16,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                chatProvider.isCompactingContext
                                                    ? 'Compacting...'
                                                    : 'Compact now',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ];
                                    },
                                    child: _buildContextUsageControl(
                                      context,
                                      usage: usage,
                                      isCompacting:
                                          chatProvider.isCompactingContext,
                                      enabled: true,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              // Session todo list (mobile or desktop fallback when utility pane hidden)
              Builder(
                builder: (context) {
                  final sp = context.watch<SettingsProvider>();
                  final sizeClass = context.windowSizeClass;
                  final isCompactLayout = sizeClass.isCompact;
                  final mediaKeyboardInset = MediaQuery.viewInsetsOf(
                    context,
                  ).bottom;
                  final viewKeyboardInset = View.of(context).viewInsets.bottom;
                  final effectiveKeyboardOpen =
                      isKeyboardOpen ||
                      mediaKeyboardInset > 0 ||
                      viewKeyboardInset > 0;
                  final shouldForceCollapse =
                      effectiveKeyboardOpen &&
                      (isCompactLayout || _isMobileRuntime);
                  final utilityPaneVisible =
                      sizeClass.isAtLeastLarge &&
                      sp.isDesktopPaneVisible(DesktopPane.utility);
                  if (chatProvider.currentSessionTodo.isEmpty ||
                      !sp.showTaskList ||
                      (!isCompactLayout && utilityPaneVisible)) {
                    return const SizedBox.shrink();
                  }
                  return _buildInlineTodoCard(
                    context,
                    chatProvider,
                    sp,
                    forceCollapsed: shouldForceCollapse,
                  );
                },
              ),
              // Message list
              Expanded(child: _buildMessageViewport(chatProvider)),

              _buildInteractionPrompts(chatProvider),

              _buildComposerReasoningStatusSlot(composerStatus),

              _buildModelControls(
                chatProvider,
                attachmentsEnabled: attachmentsEnabled,
              ),

              // Input field
              Builder(
                builder: (context) {
                  final sentMessageHistory = _collectSentMessageHistory(
                    chatProvider.messages,
                  );
                  return ChatInputWidget(
                    onSendMessage: (submission) async {
                      _prepareForOutgoingUserMessage();
                      await chatProvider.submitMessageWithQueue(
                        submission.text,
                        attachments: submission.attachments,
                        shellMode: submission.mode == ChatComposerMode.shell,
                      );
                      // Clear file line references after sending.
                      if (_fileContextItems.isNotEmpty) {
                        _setState(() {
                          _fileContextItems.clear();
                        });
                      }
                      _scrollToBottom(force: true);
                    },
                    onStopRequested: () async {
                      await _requestStopActiveResponse(chatProvider);
                    },
                    onStopHintRequested: _showComposerStopHint,
                    onMentionQuery: _queryMentionSuggestions,
                    onSlashQuery: _querySlashSuggestions,
                    onBuiltinSlashCommand: (commandName) =>
                        _handleBuiltinSlashCommand(
                          commandName: commandName,
                          chatProvider: chatProvider,
                        ),
                    sentMessageHistory: sentMessageHistory,
                    prefilledDraft: _composerPrefilledDraft,
                    prefilledDraftVersion: _composerPrefilledDraftVersion,
                    enabled: chatProvider.currentSession != null,
                    isResponding: chatProvider.canAbortActiveResponse,
                    focusNode: _inputFocusNode,
                    controller: _chatInputController,
                    showAttachmentButton: attachmentsEnabled,
                    showInlineAttachmentButton: false,
                    allowImageAttachment: supportsImages,
                    allowPdfAttachment: supportsPdf,
                    contextItems: _fileContextItems,
                    onRemoveContextItem: (index) {
                      if (index >= 0 && index < _fileContextItems.length) {
                        _setState(() {
                          _fileContextItems.removeAt(index);
                        });
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageViewport(ChatProvider chatProvider) {
    final showFab =
        _showScrollToLatestFab &&
        chatProvider.currentSession != null &&
        chatProvider.messages.isNotEmpty;
    final showJumpToFirstFab = showFab && _showScrollToFirstFab;
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned.fill(child: _buildMessageList(chatProvider)),
        Positioned(
          right: 16,
          bottom: 16,
          child: AnimatedSwitcher(
            duration: AppAnimations.fabScale,
            switchInCurve: AppAnimations.fabCurve,
            switchOutCurve: AppAnimations.accelerateCurve,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: showFab
                ? Column(
                    key: const ValueKey<String>('message_jump_fabs_visible'),
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AnimatedSwitcher(
                        duration: AppAnimations.fabScale,
                        switchInCurve: AppAnimations.fabCurve,
                        switchOutCurve: AppAnimations.accelerateCurve,
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            ),
                        child: showJumpToFirstFab
                            ? Padding(
                                key: const ValueKey<String>(
                                  'jump_to_first_fab',
                                ),
                                padding: const EdgeInsets.only(bottom: 8),
                                child: FloatingActionButton.small(
                                  heroTag: 'jump_to_first_fab',
                                  tooltip: 'Go to first message',
                                  onPressed: _scrollToFirstMessage,
                                  backgroundColor:
                                      colorScheme.surfaceContainerHigh,
                                  foregroundColor: colorScheme.onSurfaceVariant,
                                  child: const Icon(
                                    Symbols.arrow_upward_rounded,
                                  ),
                                ),
                              )
                            : const SizedBox(
                                key: ValueKey<String>(
                                  'jump_to_first_fab_hidden',
                                ),
                              ),
                      ),
                      FloatingActionButton.small(
                        key: const ValueKey<String>('jump_to_latest_fab'),
                        heroTag: 'jump_to_latest_fab',
                        tooltip: 'Go to latest message',
                        onPressed: _jumpToLatestAndResumeAutoFollow,
                        backgroundColor: _hasUnreadMessagesBelow
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHigh,
                        foregroundColor: _hasUnreadMessagesBelow
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        child: Icon(
                          _hasUnreadMessagesBelow
                              ? Symbols.mark_chat_unread
                              : Symbols.arrow_downward_rounded,
                        ),
                      ),
                    ],
                  )
                : const SizedBox(
                    key: ValueKey<String>('jump_to_latest_fab_hidden'),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageList(ChatProvider chatProvider) {
    final settingsProvider = context.watch<SettingsProvider>();
    if (chatProvider.state == ChatState.loading &&
        chatProvider.messages.isEmpty) {
      return const ChatSkeletonShimmer();
    }

    if (chatProvider.state == ChatState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              chatProvider.errorMessage ?? 'An error occurred',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                chatProvider.clearError();
                chatProvider.refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (chatProvider.currentSession == null) {
      return MessageEntranceAnimation(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Symbols.chat_bubble_outline,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Select or create a conversation to start chatting',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _createNewSession,
                icon: const Icon(Symbols.add),
                label: const Text('New Chat'),
              ),
            ],
          ),
        ),
      );
    }

    if (chatProvider.messages.isEmpty) {
      return MessageEntranceAnimation(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Symbols.waving_hand,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Hello! I am your AI assistant',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'How can I help you?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final progressStage = _resolveAssistantProgressStage(chatProvider);
    final latestReasoningPartKey = _resolveLatestReasoningPartKey(
      chatProvider.messages,
    );
    final showMessageProgressIndicator =
        progressStage == _AssistantProgressStage.retrying;
    final timelineEntries = _buildMessageTimelineEntries(
      messages: chatProvider.messages,
      messagesVersion: chatProvider.messagesVersion,
      showRetryIndicator: showMessageProgressIndicator,
      isSessionActivelyResponding:
          chatProvider.isCurrentSessionActivelyResponding,
      isCompactingContext: chatProvider.isCompactingContext,
    );
    final finalAssistantRevealMessageId =
        _resolveLatestSuccessfulAssistantMessageId(chatProvider.messages);
    _pruneMessageRevealAnchorKeys(chatProvider.messages);

    // Determine which entries are new (for entrance animation.
    // Reset the baseline whenever the active session changes so that loading
    // an existing conversation never animates its full history as "new".
    final currentSessionId = chatProvider.currentSession?.id;
    final currentLength = timelineEntries.length;
    final sessionChanged = currentSessionId != _animationBaselineSessionId;
    if (sessionChanged) {
      // Establish baseline for this session — existing messages are not new.
      _animationBaselineSessionId = currentSessionId;
      _previousTimelineLength = currentLength;
    }
    final prevLength = _previousTimelineLength;
    if (currentLength != prevLength) {
      _previousTimelineLength = currentLength;
    }
    final animateNewEntries =
        !sessionChanged && _autoFollowToLatest && currentLength > prevLength;

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _handleScrollMetricsChanged,
      child: CustomScrollView(
        key: const ValueKey<String>('chat_message_list'),
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = timelineEntries[index];
                  Widget child;
                  if (entry is _TimelineMessageEntry) {
                    final message = entry.message;
                    Widget messageWidget = ChatMessageWidget(
                      key: ValueKey<String>(
                        'chat_message_widget_${message.id}',
                      ),
                      message: message,
                      activeReasoningPartKey: latestReasoningPartKey,
                      showThinkingBubbles: settingsProvider.showThinkingBubbles,
                      showToolCallBubbles: settingsProvider.showToolCallBubbles,
                      isSessionActivelyResponding:
                          chatProvider.isCurrentSessionActivelyResponding,
                      isQueuedUserMessage:
                          message.role == MessageRole.user &&
                          chatProvider.isQueuedUserMessage(message.id),
                      onBackgroundLongPress: () =>
                          _handleMessageBackgroundLongPress(message),
                      onBackgroundLongPressEnd: () =>
                          _handleMessageBackgroundLongPressEnd(message),
                    );
                    if (finalAssistantRevealMessageId == message.id) {
                      messageWidget = KeyedSubtree(
                        key: _messageRevealAnchorKey(message.id),
                        child: messageWidget,
                      );
                    }
                    child = KeyedSubtree(
                      key: ValueKey<String>(entry.key),
                      child: messageWidget,
                    );
                  } else if (entry is _TimelineCollapsedHistoryEntry) {
                    child = _buildCollapsedHistoryEntry(entry);
                  } else if (entry is _TimelineCollapsedAssistantWorkEntry) {
                    child = _buildCollapsedAssistantWorkEntry(entry);
                  } else {
                    child = _buildRetryingMessageIndicator();
                  }

                  // Animate only genuinely new entries at the tail.
                  // Pass the message role for role-specific motion profiles.
                  final isNewEntry = animateNewEntries && index >= prevLength;
                  if (isNewEntry) {
                    final role = entry is _TimelineMessageEntry
                        ? entry.message.role
                        : null;
                    return MessageEntranceAnimation(role: role, child: child);
                  }
                  return child;
                },
                childCount: timelineEntries.length,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                addSemanticIndexes: false,
                findChildIndexCallback: (key) =>
                    _findTimelineEntryIndexByKey(key, timelineEntries),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_TimelineEntry> _buildMessageTimelineEntries({
    required List<ChatMessage> messages,
    required int messagesVersion,
    required bool showRetryIndicator,
    required bool isSessionActivelyResponding,
    required bool isCompactingContext,
  }) {
    if (_cachedTimelineEntries != null &&
        messagesVersion == _cachedTimelineMessagesVersion &&
        isCompactingContext == _cachedTimelineIsCompacting &&
        isSessionActivelyResponding == _cachedTimelineIsResponding &&
        showRetryIndicator == _cachedTimelineShowRetry &&
        _deferAssistantWorkCollapse ==
            _cachedTimelineDeferAssistantWorkCollapse &&
        _expandedCollapsedHistoryGroupId == _cachedTimelineExpandedGroupId &&
        _expandedAssistantWorkGroupId ==
            _cachedTimelineExpandedAssistantWorkGroupId) {
      return _cachedTimelineEntries!;
    }
    final entries = <_TimelineEntry>[];
    final previousWasCompactingContext = _wasCompactingContext;
    var nextFrozenCompactionBoundaryId = _frozenCompactionBoundaryId;

    // Freeze boundary during compaction to prevent premature collapse.
    if (isCompactingContext && !previousWasCompactingContext) {
      // Compaction just started: freeze the current boundary by message ID.
      final currentIdx = _findLatestCompactionBoundaryIndex(
        messages,
        allowInProgressBoundary: true,
      );
      nextFrozenCompactionBoundaryId = currentIdx != null
          ? messages[currentIdx].id
          : null;
    } else if (!isCompactingContext && previousWasCompactingContext) {
      // Compaction finished: unfreeze so the new boundary takes effect.
      nextFrozenCompactionBoundaryId = null;
    }
    _scheduleCompactionStateSync(
      wasCompactingContext: isCompactingContext,
      frozenCompactionBoundaryId: nextFrozenCompactionBoundaryId,
    );

    // Use the latest compaction marker as the visible history boundary.
    int? boundaryIndex;
    if (isCompactingContext && nextFrozenCompactionBoundaryId != null) {
      // During compaction, resolve the frozen boundary by message ID.
      final frozenIdx = messages.indexWhere(
        (m) => m.id == nextFrozenCompactionBoundaryId,
      );
      boundaryIndex = frozenIdx >= 0 ? frozenIdx : null;
    } else {
      boundaryIndex = _findLatestCompactionBoundaryIndex(
        messages,
        allowInProgressBoundary: !isSessionActivelyResponding,
      );
    }
    if (boundaryIndex != null && boundaryIndex > 0) {
      final boundaryMessage = messages[boundaryIndex];
      final boundary = _resolveCompactionBoundary(boundaryMessage);
      if (boundary != null) {
        final group = _CollapsedHistoryGroup(
          startMessageId: messages.first.id,
          endMessageId: messages[boundaryIndex - 1].id,
          messageCount: boundaryIndex,
          createdAt: boundaryMessage.time,
          compactionId: boundary.compactionId,
          compactionLabel: boundary.compactionLabel,
        );
        final expanded = _expandedCollapsedHistoryGroupId == group.id;
        entries.add(
          _TimelineCollapsedHistoryEntry(group: group, expanded: expanded),
        );
        // Build pre-boundary messages only when user expands the group.
        if (expanded) {
          _appendTimelineEntriesForRange(
            entries: entries,
            messages: messages,
            startIndex: 0,
            endExclusive: boundaryIndex,
          );
        }
        _appendTimelineEntriesForRange(
          entries: entries,
          messages: messages,
          startIndex: boundaryIndex,
          endExclusive: messages.length,
        );
      }
    }

    if (entries.isEmpty) {
      _appendTimelineEntriesForRange(
        entries: entries,
        messages: messages,
        startIndex: 0,
        endExclusive: messages.length,
      );
    }

    if (showRetryIndicator) {
      entries.add(const _TimelineRetryIndicatorEntry());
    }

    // Store in cache for subsequent rebuilds with unchanged message list.
    _cachedTimelineMessagesVersion = messagesVersion;
    _cachedTimelineIsCompacting = isCompactingContext;
    _cachedTimelineIsResponding = isSessionActivelyResponding;
    _cachedTimelineShowRetry = showRetryIndicator;
    _cachedTimelineDeferAssistantWorkCollapse = _deferAssistantWorkCollapse;
    _cachedTimelineExpandedGroupId = _expandedCollapsedHistoryGroupId;
    _cachedTimelineExpandedAssistantWorkGroupId = _expandedAssistantWorkGroupId;
    _cachedTimelineEntries = entries;
    return entries;
  }

  void _appendTimelineEntriesForRange({
    required List<_TimelineEntry> entries,
    required List<ChatMessage> messages,
    required int startIndex,
    required int endExclusive,
  }) {
    if (startIndex >= endExclusive) {
      return;
    }

    var index = startIndex;
    while (index < endExclusive) {
      final current = messages[index];
      if (current is! UserMessage) {
        if (_isMergeableAssistantToolOnlyMessage(current)) {
          index = _appendMergedAssistantToolOnlyRun(
            entries: entries,
            messages: messages,
            startIndex: index,
            endExclusive: endExclusive,
          );
        } else {
          entries.add(_TimelineMessageEntry(current));
          index += 1;
        }
        continue;
      }

      entries.add(_TimelineMessageEntry(current));

      final assistantRunStart = index + 1;
      var assistantRunEnd = assistantRunStart;
      while (assistantRunEnd < endExclusive &&
          messages[assistantRunEnd] is AssistantMessage) {
        assistantRunEnd += 1;
      }

      if (assistantRunEnd == assistantRunStart) {
        index += 1;
        continue;
      }

      final finalAssistant = messages[assistantRunEnd - 1] as AssistantMessage;
      final workMessageCount = assistantRunEnd - assistantRunStart - 1;
      final shouldDeferCurrentRunCollapse =
          _deferAssistantWorkCollapse && assistantRunEnd == endExclusive;
      if (workMessageCount > 0 &&
          !shouldDeferCurrentRunCollapse &&
          _isSuccessfulFinalAssistantMessage(finalAssistant)) {
        final workGroup = _CollapsedAssistantWorkGroup(
          startMessageId: messages[assistantRunStart].id,
          endMessageId: messages[assistantRunEnd - 2].id,
          finalMessageId: finalAssistant.id,
          messageCount: workMessageCount,
          createdAt: finalAssistant.time,
        );
        final expanded = _expandedAssistantWorkGroupId == workGroup.id;
        entries.add(
          _TimelineCollapsedAssistantWorkEntry(
            group: workGroup,
            expanded: expanded,
          ),
        );
        if (expanded) {
          _appendRangeWithAssistantToolMerging(
            entries: entries,
            messages: messages,
            startIndex: assistantRunStart,
            endExclusive: assistantRunEnd - 1,
          );
        }
        entries.add(_TimelineMessageEntry(finalAssistant));
      } else {
        _appendRangeWithAssistantToolMerging(
          entries: entries,
          messages: messages,
          startIndex: assistantRunStart,
          endExclusive: assistantRunEnd,
        );
      }

      index = assistantRunEnd;
    }
  }

  void _appendRangeWithAssistantToolMerging({
    required List<_TimelineEntry> entries,
    required List<ChatMessage> messages,
    required int startIndex,
    required int endExclusive,
  }) {
    if (startIndex >= endExclusive) {
      return;
    }

    var index = startIndex;
    while (index < endExclusive) {
      final current = messages[index];
      if (!_isMergeableAssistantToolOnlyMessage(current)) {
        entries.add(_TimelineMessageEntry(current));
        index += 1;
        continue;
      }

      index = _appendMergedAssistantToolOnlyRun(
        entries: entries,
        messages: messages,
        startIndex: index,
        endExclusive: endExclusive,
      );
    }
  }

  int _appendMergedAssistantToolOnlyRun({
    required List<_TimelineEntry> entries,
    required List<ChatMessage> messages,
    required int startIndex,
    required int endExclusive,
  }) {
    var mergeEnd = startIndex + 1;
    while (mergeEnd < endExclusive &&
        _isMergeableAssistantToolOnlyMessage(messages[mergeEnd])) {
      mergeEnd += 1;
    }

    if (mergeEnd - startIndex == 1) {
      entries.add(_TimelineMessageEntry(messages[startIndex]));
      return mergeEnd;
    }

    final mergedMessage = _mergeAssistantToolOnlyMessages(
      messages
          .sublist(startIndex, mergeEnd)
          .cast<AssistantMessage>()
          .toList(growable: false),
    );
    entries.add(_TimelineMessageEntry(mergedMessage));
    return mergeEnd;
  }

  bool _isMergeableAssistantToolOnlyMessage(ChatMessage message) {
    if (message is! AssistantMessage || message.error != null) {
      return false;
    }

    var hasToolSurfacePart = false;
    for (final part in message.parts) {
      switch (part.type) {
        case PartType.tool:
        case PartType.patch:
          hasToolSurfacePart = true;
          break;
        case PartType.stepStart:
        case PartType.stepFinish:
        case PartType.agent:
        case PartType.snapshot:
        case PartType.subtask:
        case PartType.retry:
        case PartType.reasoning:
          break;
        case PartType.text:
          if ((part as TextPart).text.trim().isNotEmpty) {
            return false;
          }
          break;
        default:
          return false;
      }
    }

    return hasToolSurfacePart;
  }

  AssistantMessage _mergeAssistantToolOnlyMessages(
    List<AssistantMessage> messages,
  ) {
    final first = messages.first;
    final last = messages.last;
    final mergedParts = <MessagePart>[
      for (final message in messages) ...message.parts,
    ];

    final mergedTokens = _sumAssistantTokens(messages);
    final mergedCost = _sumAssistantCost(messages);

    return AssistantMessage(
      id: 'merged_tool_run_${first.id}',
      sessionId: first.sessionId,
      time: first.time,
      parts: mergedParts,
      completedTime: last.completedTime,
      providerId: last.providerId ?? first.providerId,
      modelId: last.modelId ?? first.modelId,
      cost: mergedCost,
      tokens: mergedTokens,
      mode: last.mode ?? first.mode,
      summary: false,
    );
  }

  MessageTokens? _sumAssistantTokens(List<AssistantMessage> messages) {
    var input = 0;
    var output = 0;
    var reasoning = 0;
    var cacheRead = 0;
    var cacheWrite = 0;
    var hasTokens = false;

    for (final message in messages) {
      final tokens = message.tokens;
      if (tokens == null) {
        continue;
      }
      hasTokens = true;
      input += tokens.input;
      output += tokens.output;
      reasoning += tokens.reasoning;
      cacheRead += tokens.cacheRead;
      cacheWrite += tokens.cacheWrite;
    }

    if (!hasTokens) {
      return null;
    }

    return MessageTokens(
      input: input,
      output: output,
      reasoning: reasoning,
      cacheRead: cacheRead,
      cacheWrite: cacheWrite,
    );
  }

  double? _sumAssistantCost(List<AssistantMessage> messages) {
    var total = 0.0;
    var hasCost = false;
    for (final message in messages) {
      final cost = message.cost;
      if (cost == null) {
        continue;
      }
      total += cost;
      hasCost = true;
    }
    if (!hasCost) {
      return null;
    }
    return total;
  }

  bool _isSuccessfulFinalAssistantMessage(AssistantMessage message) {
    return message.isCompleted &&
        message.error == null &&
        message.summary != true &&
        !_isMergeableAssistantToolOnlyMessage(message);
  }

  String? _resolveLatestSuccessfulAssistantMessageId(
    List<ChatMessage> messages,
  ) {
    for (var index = messages.length - 1; index >= 0; index -= 1) {
      final message = messages[index];
      if (message is! AssistantMessage) {
        continue;
      }
      if (_isSuccessfulFinalAssistantMessage(message)) {
        return message.id;
      }
    }
    return null;
  }
}
