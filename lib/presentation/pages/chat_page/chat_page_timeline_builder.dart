part of '../chat_page.dart';

extension _ChatPageTimelineBuilder on _ChatPageState {
  Widget _buildChatContent({
    required ChatProvider chatProvider,
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
                  final isMobile = sizeClass.isCompact;
                  final utilityPaneVisible =
                      sizeClass.isAtLeastLarge &&
                      sp.isDesktopPaneVisible(DesktopPane.utility);
                  if (chatProvider.currentSessionTodo.isEmpty ||
                      !sp.showTaskList ||
                      (!isMobile && utilityPaneVisible)) {
                    return const SizedBox.shrink();
                  }
                  return _buildInlineTodoCard(context, chatProvider, sp);
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
                      await chatProvider.sendMessage(
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
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: showFab
                ? Column(
                    key: const ValueKey<String>('message_jump_fabs_visible'),
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
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
                                  child: const Icon(Symbols.arrow_upward_rounded),
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
                        onPressed: () => _scrollToBottom(force: true),
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
      return const Center(child: CircularProgressIndicator());
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
      return Center(
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
      );
    }

    if (chatProvider.messages.isEmpty) {
      return Center(
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
      showRetryIndicator: showMessageProgressIndicator,
      isSessionActivelyResponding:
          chatProvider.isCurrentSessionActivelyResponding,
      isCompactingContext: chatProvider.isCompactingContext,
    );

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
                  if (entry is _TimelineMessageEntry) {
                    final message = entry.message;
                    return ChatMessageWidget(
                      key: ValueKey<String>(entry.key),
                      message: message,
                      activeReasoningPartKey: latestReasoningPartKey,
                      showThinkingBubbles: settingsProvider.showThinkingBubbles,
                      showToolCallBubbles: settingsProvider.showToolCallBubbles,
                      isSessionActivelyResponding:
                          chatProvider.isCurrentSessionActivelyResponding,
                      onBackgroundLongPress: () =>
                          _handleMessageBackgroundLongPress(message),
                      onBackgroundLongPressEnd: () =>
                          _handleMessageBackgroundLongPressEnd(message),
                    );
                  }
                  if (entry is _TimelineCollapsedHistoryEntry) {
                    return _buildCollapsedHistoryEntry(entry);
                  }
                  return _buildRetryingMessageIndicator();
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
    required bool showRetryIndicator,
    required bool isSessionActivelyResponding,
    required bool isCompactingContext,
  }) {
    final lastId = messages.isNotEmpty ? messages.last.id : null;
    if (_cachedTimelineEntries != null &&
        messages.length == _cachedTimelineMessageCount &&
        lastId == _cachedTimelineLastMessageId &&
        isCompactingContext == _cachedTimelineIsCompacting &&
        isSessionActivelyResponding == _cachedTimelineIsResponding &&
        showRetryIndicator == _cachedTimelineShowRetry &&
        _expandedCollapsedHistoryGroupId == _cachedTimelineExpandedGroupId) {
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
          for (var index = 0; index < boundaryIndex; index += 1) {
            entries.add(_TimelineMessageEntry(messages[index]));
          }
        }
        for (var index = boundaryIndex; index < messages.length; index += 1) {
          entries.add(_TimelineMessageEntry(messages[index]));
        }
      }
    }

    if (entries.isEmpty) {
      entries.addAll(messages.map<_TimelineEntry>(_TimelineMessageEntry.new));
    }

    if (showRetryIndicator) {
      entries.add(const _TimelineRetryIndicatorEntry());
    }

    // Store in cache for subsequent rebuilds with unchanged message list.
    _cachedTimelineMessageCount = messages.length;
    _cachedTimelineLastMessageId = lastId;
    _cachedTimelineIsCompacting = isCompactingContext;
    _cachedTimelineIsResponding = isSessionActivelyResponding;
    _cachedTimelineShowRetry = showRetryIndicator;
    _cachedTimelineExpandedGroupId = _expandedCollapsedHistoryGroupId;
    _cachedTimelineEntries = entries;
    return entries;
  }
}
