part of '../chat_page.dart';

extension _ChatPageTimelineBuilder on _ChatPageState {
  Widget _buildTimelineMessageWidget({
    required ChatMessage message,
    required ChatProvider chatProvider,
    required SettingsProvider settingsProvider,
    required String? latestReasoningPartKey,
    required String? latestRevertibleMessageId,
    required bool isSubConversation,
    required String? finalAssistantRevealMessageId,
    bool wrapRevealAnchor = true,
    String? keyPrefix,
  }) {
    final taskToolChildSummariesByPartId = _buildTaskToolChildSummaries(
      chatProvider: chatProvider,
      message: message,
    );
    Widget messageWidget = ChatMessageWidget(
      key: ValueKey<String>(
        '${keyPrefix ?? 'chat_message_widget'}_${message.id}',
      ),
      message: message,
      activeReasoningPartKey: latestReasoningPartKey,
      showThinkingBubbles: settingsProvider.showThinkingBubbles,
      showToolCallBubbles: settingsProvider.showToolCallBubbles,
      showInlineUndoAction:
          message is UserMessage && message.id == latestRevertibleMessageId,
      isSessionActivelyResponding:
          chatProvider.isCurrentSessionActivelyResponding,
      onInlineUndo:
          message is UserMessage && message.id == latestRevertibleMessageId
          ? () => unawaited(
              _triggerHistoryAction(
                chatProvider,
                action: _HistoryToolbarAction.undo,
              ),
            )
          : null,
      onBackgroundLongPress: () => _handleMessageBackgroundLongPress(message),
      onBackgroundLongPressEnd: () =>
          _handleMessageBackgroundLongPressEnd(message),
      onSubtaskNavigate: isSubConversation
          ? null
          : (part) => unawaited(
              _openSubConversationFromSubtaskPart(chatProvider, part),
            ),
      onTaskToolNavigate: isSubConversation
          ? null
          : (part) => unawaited(
              _openSubConversationFromTaskToolPart(chatProvider, part),
            ),
      taskToolChildSummariesByPartId: taskToolChildSummariesByPartId,
    );
    if (wrapRevealAnchor && finalAssistantRevealMessageId == message.id) {
      messageWidget = Column(
        key: _messageRevealMeasurementKey(message.id),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            key: _messageRevealAnchorKey(message.id),
            child: SizedBox(
              key: ValueKey<String>('message_reveal_anchor_${message.id}'),
              height: 1,
            ),
          ),
          messageWidget,
        ],
      );
    }
    return messageWidget;
  }

  Map<String, TaskToolChildSummary> _buildTaskToolChildSummaries({
    required ChatProvider chatProvider,
    required ChatMessage message,
  }) {
    final taskParts = message.parts
        .whereType<ToolPart>()
        .where((part) {
          return _normalizeToolNameForSubConversation(part.tool) == 'task';
        })
        .toList(growable: false);
    if (taskParts.isEmpty) {
      return const <String, TaskToolChildSummary>{};
    }

    final output = <String, TaskToolChildSummary>{};
    for (final part in taskParts) {
      final metadataSummary = _taskToolChildSummaryFromStateMetadata(
        part.state,
      );
      final childSession = _resolveSubConversationForTaskToolPart(
        chatProvider,
        part,
      );
      final cachedSummary = childSession == null
          ? null
          : _taskToolChildSummaryFromCachedSession(
              chatProvider,
              childSession.id,
            );
      final mergedSummary = _mergeTaskToolChildSummaries(
        metadataSummary,
        cachedSummary,
      );
      if (mergedSummary != null) {
        output[part.id] = mergedSummary;
      }
    }
    return output;
  }

  TaskToolChildSummary? _mergeTaskToolChildSummaries(
    TaskToolChildSummary? preferred,
    TaskToolChildSummary? fallback,
  ) {
    final latestToolLabel =
        preferred?.latestToolLabel ?? fallback?.latestToolLabel;
    final toolCallCount = preferred?.toolCallCount ?? fallback?.toolCallCount;
    if (latestToolLabel == null && toolCallCount == null) {
      return null;
    }
    return TaskToolChildSummary(
      latestToolLabel: latestToolLabel,
      toolCallCount: toolCallCount,
    );
  }

  TaskToolChildSummary? _taskToolChildSummaryFromStateMetadata(
    ToolState state,
  ) {
    final metadata = toolStateMetadata(state);
    if (metadata == null || metadata.isEmpty) {
      return null;
    }

    String normalizeMetadataKey(String raw) {
      return raw.trim().toLowerCase().replaceAll(RegExp(r'[_\-\s]'), '');
    }

    String? readLabel(dynamic value) {
      if (value is String) {
        return normalizeToolLabel(value);
      }
      if (value is Map) {
        return extractPreferredToolLabel(Map<String, dynamic>.from(value));
      }
      return null;
    }

    int? readCount(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is String) {
        return int.tryParse(value.trim());
      }
      return null;
    }

    const latestToolKeys = <String>{
      'latesttoolcall',
      'latesttoollabel',
      'latesttoolname',
      'currenttoolcall',
      'currenttoollabel',
      'activetoolcall',
      'activetoollabel',
      'lasttoolcall',
      'lasttoollabel',
    };
    const toolCallCountKeys = <String>{
      'toolcallcount',
      'toolcalls',
      'totaltoolcalls',
    };

    String? latestToolLabel;
    int? toolCallCount;

    void visit(dynamic value, {String? key}) {
      if (key != null) {
        final normalizedKey = normalizeMetadataKey(key);
        if (latestToolLabel == null && latestToolKeys.contains(normalizedKey)) {
          latestToolLabel = readLabel(value);
        }
        if (toolCallCount == null &&
            toolCallCountKeys.contains(normalizedKey)) {
          toolCallCount = readCount(value);
        }
      }
      if (value is Map) {
        for (final entry in value.entries) {
          visit(entry.value, key: entry.key.toString());
        }
      } else if (value is List) {
        for (final item in value) {
          visit(item);
        }
      }
    }

    visit(metadata);
    if (latestToolLabel == null && toolCallCount == null) {
      return null;
    }
    return TaskToolChildSummary(
      latestToolLabel: latestToolLabel,
      toolCallCount: toolCallCount,
    );
  }

  TaskToolChildSummary? _taskToolChildSummaryFromCachedSession(
    ChatProvider chatProvider,
    String sessionId,
  ) {
    final messages = chatProvider.cachedMessagesForSession(sessionId);
    if (messages == null || messages.isEmpty) {
      return null;
    }

    final visibleToolParts = <ToolPart>[];
    for (final message in messages) {
      for (final part in message.parts) {
        if (part is! ToolPart) {
          continue;
        }
        final normalized = normalizeToolName(part.tool);
        if (normalized == 'todowrite' || normalized == 'todoread') {
          continue;
        }
        visibleToolParts.add(part);
      }
    }
    if (visibleToolParts.isEmpty) {
      return const TaskToolChildSummary(toolCallCount: 0);
    }

    final latestToolLabel = toolResolveComposerDescriptionLabel(
      visibleToolParts.last,
    );
    return TaskToolChildSummary(
      latestToolLabel: latestToolLabel,
      toolCallCount: visibleToolParts.length,
    );
  }

  Widget _buildChatContent({
    required ChatProvider chatProvider,
    required bool isKeyboardOpen,
    required double maxContentWidth,
    required double horizontalPadding,
    required double verticalPadding,
  }) {
    final currentSession = chatProvider.currentSession;
    final isSubConversation = _isSubConversationSession(currentSession);
    final selectedModel = chatProvider.selectedModel;
    final supportsImages = _supportsImageAttachments(selectedModel);
    final supportsPdf = _supportsPdfAttachments(selectedModel);
    final attachmentsEnabled = supportsImages || supportsPdf;
    final appProvider = context.watch<AppProvider>();
    final composerBlockReason = _resolveComposerBlockReason(
      chatProvider: chatProvider,
      appProvider: appProvider,
    );
    final composerEnabled =
        (chatProvider.currentSession != null ||
            chatProvider.isDraftingNewChat) &&
        composerBlockReason == null;
    final settingsProvider = context.watch<SettingsProvider>();
    final isCompactLayout =
        context.windowSizeClass.isCompact || _isMobileRuntime;
    final showTerminalPanel = settingsProvider.terminalPanelVisible;
    final hideComposerForTerminal = isCompactLayout && showTerminalPanel;
    final composerStatusTarget = _resolveComposerStatusTarget(chatProvider);
    _queueComposerStatusSync(composerStatusTarget);
    final composerStatus = _priorityComposerStatus ?? _visibleComposerStatus;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final titleEditor = SessionTitleInlineEditor(
                                        key: ValueKey<String>(
                                          'chat_header_session_title_editor_${currentSession.id}',
                                        ),
                                        title: _sessionDisplayTitle(
                                          currentSession,
                                        ),
                                        editingValue: _sessionEditingValue(
                                          currentSession,
                                        ),
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                        onRename: (title) =>
                                            chatProvider.renameSession(
                                              currentSession,
                                              title,
                                            ),
                                      );
                                      final sessionActionsButton = Builder(
                                        builder: (context) {
                                          final currentShareUrl = chatProvider
                                              .currentSession
                                              ?.shareUrl
                                              ?.trim();
                                          final hasShareUrl =
                                              currentShareUrl != null &&
                                              currentShareUrl.isNotEmpty;
                                          final canCompact =
                                              !chatProvider
                                                  .isCompactingContext &&
                                              !chatProvider
                                                  .canAbortActiveResponse;

                                          PopupMenuItem<_CurrentSessionAction>
                                          buildActionItem(
                                            _CurrentSessionAction action, {
                                            bool enabled = true,
                                          }) {
                                            return PopupMenuItem<
                                              _CurrentSessionAction
                                            >(
                                              value: action,
                                              enabled: enabled,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    _sessionActionIcon(
                                                      action,
                                                      isShared:
                                                          currentSession.shared,
                                                    ),
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      _sessionActionLabel(
                                                        action,
                                                        isShared: currentSession
                                                            .shared,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }

                                          return PopupMenuButton<
                                            _CurrentSessionAction
                                          >(
                                            key: const ValueKey<String>(
                                              'current_session_actions_button',
                                            ),
                                            tooltip: 'Session actions',
                                            onSelected: (action) => unawaited(
                                              _handleCurrentSessionAction(
                                                chatProvider,
                                                action: action,
                                              ),
                                            ),
                                            itemBuilder: (context) {
                                              return [
                                                buildActionItem(
                                                  _CurrentSessionAction
                                                      .shareToggle,
                                                ),
                                                if (hasShareUrl)
                                                  buildActionItem(
                                                    _CurrentSessionAction
                                                        .copyLink,
                                                  ),
                                                const PopupMenuDivider(),
                                                buildActionItem(
                                                  _CurrentSessionAction
                                                      .viewTasks,
                                                ),
                                                buildActionItem(
                                                  _CurrentSessionAction
                                                      .reviewChanges,
                                                ),
                                                const PopupMenuDivider(),
                                                buildActionItem(
                                                  _CurrentSessionAction.undo,
                                                  enabled: chatProvider
                                                      .canUndoCurrentSession,
                                                ),
                                                buildActionItem(
                                                  _CurrentSessionAction.redo,
                                                  enabled: chatProvider
                                                      .canRedoCurrentSession,
                                                ),
                                                buildActionItem(
                                                  _CurrentSessionAction
                                                      .compactContext,
                                                  enabled: canCompact,
                                                ),
                                              ];
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.all(4),
                                              child: Icon(Symbols.more_horiz),
                                            ),
                                          );
                                        },
                                      );
                                      final contextUsageButton = Builder(
                                        builder: (context) {
                                          final usage =
                                              _resolveSessionContextUsage(
                                                chatProvider,
                                              );
                                          final canCompact =
                                              !chatProvider
                                                  .isCompactingContext &&
                                              !chatProvider
                                                  .canAbortActiveResponse;

                                          return PopupMenuButton<void>(
                                            key: const ValueKey<String>(
                                              'appbar_context_usage_button',
                                            ),
                                            tooltip: 'Compact Context',
                                            padding: EdgeInsets.zero,
                                            itemBuilder: (popupContext) {
                                              final serverId = context
                                                  .read<AppProvider>()
                                                  .activeServer
                                                  ?.id;
                                              context
                                                  .read<QuotaProvider>()
                                                  .ensureLoaded(
                                                    serverId: serverId,
                                                  );
                                              return [
                                                PopupMenuItem<void>(
                                                  enabled: false,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  child: _buildContextUsagePopover(
                                                    context,
                                                    usage: usage,
                                                    isCompacting: chatProvider
                                                        .isCompactingContext,
                                                    canCompact: canCompact,
                                                    onCompactNow: () =>
                                                        _compactCurrentSession(
                                                          chatProvider,
                                                        ),
                                                  ),
                                                ),
                                              ];
                                            },
                                            child: _buildContextUsageControl(
                                              context,
                                              usage: usage,
                                              isCompacting: chatProvider
                                                  .isCompactingContext,
                                              enabled: true,
                                            ),
                                          );
                                        },
                                      );
                                      final actionsRow = Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          sessionActionsButton,
                                          contextUsageButton,
                                        ],
                                      );
                                      final useStackedLayout =
                                          constraints.maxWidth < 320;

                                      if (useStackedLayout) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            titleEditor,
                                            const SizedBox(height: 6),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: actionsRow,
                                            ),
                                          ],
                                        );
                                      }

                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(child: titleEditor),
                                          const SizedBox(width: 4),
                                          actionsRow,
                                        ],
                                      );
                                    },
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
                          final viewKeyboardInset = View.of(
                            context,
                          ).viewInsets.bottom;
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
                      Builder(
                        builder: (context) {
                          final sp = context.watch<SettingsProvider>();
                          final sizeClass = context.windowSizeClass;
                          final utilityPaneVisible =
                              sizeClass.isAtLeastLarge &&
                              sp.isDesktopPaneVisible(DesktopPane.utility);
                          if (chatProvider.currentSessionDiff.isEmpty ||
                              (!isCompactLayout && utilityPaneVisible)) {
                            return const SizedBox.shrink();
                          }
                          return _buildInlineDiffCard(context, chatProvider);
                        },
                      ),
                      // Message list
                      Expanded(child: _buildMessageViewport(chatProvider)),

                      if (!hideComposerForTerminal)
                        _buildInteractionPrompts(chatProvider),

                      if (!hideComposerForTerminal)
                        _buildComposerReasoningStatusSlot(composerStatus),

                      if (!hideComposerForTerminal)
                        _buildModelControls(
                          chatProvider,
                          isSubConversation: isSubConversation,
                        ),

                      // Input field
                      if (isSubConversation)
                        _buildSubConversationReturnButton(chatProvider),
                      if (!hideComposerForTerminal)
                        Builder(
                          builder: (context) {
                            final sentMessageHistory =
                                _collectSentMessageHistory(
                                  chatProvider.messages,
                                );
                            final currentSessionId =
                                chatProvider.currentSession?.id;
                            final projectProvider = context
                                .read<ProjectProvider>();
                            return ChatInputWidget(
                              onSendMessage: (submission) async {
                                Future<void>
                                clearComposerContextIfNeeded() async {
                                  if (_fileContextItems.isNotEmpty) {
                                    _setState(() {
                                      _fileContextItems.clear();
                                    });
                                  }
                                }

                                final slashInvocation =
                                    submission.mode == ChatComposerMode.shell
                                    ? null
                                    : _parseSlashCommandInvocation(
                                        submission.text,
                                      );

                                if (slashInvocation != null) {
                                  final builtinHandled =
                                      await _handleBuiltinSlashCommand(
                                        commandName: slashInvocation.name,
                                        chatProvider: chatProvider,
                                      );
                                  await clearComposerContextIfNeeded();
                                  if (builtinHandled) {
                                    return;
                                  }

                                  _prepareForOutgoingUserMessage();
                                  await chatProvider.submitMessage(
                                    submission.text.trim(),
                                    commandMode: true,
                                  );
                                  _scrollToBottom(force: true);
                                  return;
                                }

                                _prepareForOutgoingUserMessage();
                                await chatProvider.submitMessage(
                                  submission.text,
                                  attachments: submission.attachments,
                                  shellMode:
                                      submission.mode == ChatComposerMode.shell,
                                );
                                await clearComposerContextIfNeeded();
                                _scrollToBottom(force: true);
                              },
                              onStopRequested: () async {
                                await _requestStopActiveResponse(chatProvider);
                              },
                              onStopHintRequested: _showComposerStopHint,
                              onDraftChanged: (draft) {
                                _scheduleComposerDraftPersistence(
                                  sessionId: currentSessionId,
                                  draft: draft,
                                );
                              },
                              onMentionQuery: _queryMentionSuggestions,
                              onSlashQuery: _querySlashSuggestions,
                              onBuiltinSlashCommand: (commandName) =>
                                  _handleBuiltinSlashCommand(
                                    commandName: commandName,
                                    chatProvider: chatProvider,
                                  ),
                              sentMessageHistory: sentMessageHistory,
                              prefilledDraft: _composerPrefilledDraft,
                              prefilledDraftVersion:
                                  _composerPrefilledDraftVersion,
                              enabled: composerEnabled,
                              blockReason: composerBlockReason,
                              isResponding: chatProvider.canAbortActiveResponse,
                              focusNode: _inputFocusNode,
                              controller: _chatInputController,
                              showAttachmentButton: attachmentsEnabled,
                              showInlineAttachmentButton: false,
                              allowImageAttachment: supportsImages,
                              allowPdfAttachment: supportsPdf,
                              cannedAnswersDataSource: di.sl(),
                              cannedAnswersServerId:
                                  projectProvider.activeServerId,
                              cannedAnswersScopeId:
                                  projectProvider.currentScopeId,
                              contextItems: _fileContextItems,
                              composerShowcaseKey: _composerTourKey,
                              composerShowcaseTargetKey: _composerTourTargetKey,
                              sendButtonShowcaseKey: _sendButtonTourKey,
                              sendButtonShowcaseTargetKey:
                                  _sendButtonTourTargetKey,
                              onTourSkip: _handlePostOnboardingTourSkip,
                              onRemoveContextItem: (index) {
                                if (index >= 0 &&
                                    index < _fileContextItems.length) {
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
            ),
          ),
          if (showTerminalPanel) _buildTerminalPanel(settingsProvider),
        ],
      ),
    );
  }

  bool _isSubConversationSession(ChatSession? session) {
    final parentId = session?.parentId?.trim();
    return parentId != null && parentId.isNotEmpty;
  }

  Widget _buildSubConversationReturnButton(ChatProvider chatProvider) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const ValueKey<String>('subconversation_return_main_button'),
          onPressed: () => unawaited(_returnToMainConversation(chatProvider)),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Symbols.arrow_back_rounded),
          label: const Text('Return to main conversation'),
        ),
      ),
    );
  }

  Future<void> _returnToMainConversation(ChatProvider chatProvider) async {
    final mainConversation = _resolveMainConversation(chatProvider);
    if (mainConversation == null) {
      _showSubConversationNotice('Main conversation is not available yet.');
      return;
    }
    if (chatProvider.currentSession?.id == mainConversation.id) {
      return;
    }
    await _handleSessionSwitch(mainConversation);
  }

  ChatSession? _resolveMainConversation(ChatProvider chatProvider) {
    final currentSession = chatProvider.currentSession;
    if (currentSession == null) {
      return null;
    }
    final sessionById = <String, ChatSession>{
      for (final session in chatProvider.sessions) session.id: session,
    };
    var cursor = currentSession;
    final visited = <String>{};
    while (true) {
      if (!visited.add(cursor.id)) {
        return null;
      }
      final parentId = cursor.parentId?.trim();
      if (parentId == null || parentId.isEmpty) {
        return cursor;
      }
      final parent = sessionById[parentId];
      if (parent == null) {
        return null;
      }
      cursor = parent;
    }
  }

  Future<void> _openSubConversationFromSubtaskPart(
    ChatProvider chatProvider,
    SubtaskPart part,
  ) async {
    await _openSubConversationByResolver(
      chatProvider,
      resolveTarget: () =>
          _resolveSubConversationForSubtaskPart(chatProvider, part),
    );
  }

  Future<void> _openSubConversationFromTaskToolPart(
    ChatProvider chatProvider,
    ToolPart part,
  ) async {
    await _openSubConversationByResolver(
      chatProvider,
      resolveTarget: () =>
          _resolveSubConversationForTaskToolPart(chatProvider, part),
    );
  }

  Future<void> _openSubConversationByResolver(
    ChatProvider chatProvider, {
    required ChatSession? Function() resolveTarget,
  }) async {
    var target = resolveTarget();
    if (target == null) {
      final sessionId = chatProvider.currentSession?.id;
      if (sessionId != null && sessionId.isNotEmpty) {
        try {
          await chatProvider.loadSessionInsights(
            sessionId,
            silent: true,
            userInitiated: true,
          );
        } on Exception catch (error, stackTrace) {
          AppLogger.warn(
            'Failed to refresh sub-conversations while opening task',
            error: error,
            stackTrace: stackTrace,
          );
          _showSubConversationNotice(
            'Failed to refresh sub-conversations. Please try again.',
          );
          return;
        }
      }
      target = resolveTarget();
    }

    if (target == null) {
      _showSubConversationNotice('No sub-conversation found for this task.');
      return;
    }
    if (chatProvider.currentSession?.id == target.id) {
      return;
    }
    await _handleSessionSwitch(target);
  }

  ChatSession? _resolveSubConversationForSubtaskPart(
    ChatProvider chatProvider,
    SubtaskPart part,
  ) {
    final currentSessionId = chatProvider.currentSession?.id;
    if (currentSessionId == null || currentSessionId.isEmpty) {
      return null;
    }
    final candidates = _collectChildSessionCandidates(
      chatProvider,
      currentSessionId: currentSessionId,
    );
    if (candidates.isEmpty) {
      return null;
    }
    return _resolveSubConversationFromCandidatesByPartOrder(
      chatProvider,
      candidates: candidates,
      targetPartId: part.id,
      explicitSessionIds: <String>[part.sessionId],
      anchorMatcher: (messagePart) => messagePart is SubtaskPart,
    );
  }

  ChatSession? _resolveSubConversationForTaskToolPart(
    ChatProvider chatProvider,
    ToolPart part,
  ) {
    final currentSessionId = chatProvider.currentSession?.id;
    if (currentSessionId == null || currentSessionId.isEmpty) {
      return null;
    }
    final candidates = _collectChildSessionCandidates(
      chatProvider,
      currentSessionId: currentSessionId,
    );
    if (candidates.isEmpty) {
      return null;
    }
    return _resolveSubConversationFromCandidatesByPartOrder(
      chatProvider,
      candidates: candidates,
      targetPartId: part.id,
      explicitSessionIds: _extractChildSessionIdsFromTaskToolPart(part),
      anchorMatcher: (messagePart) =>
          messagePart is ToolPart &&
          _normalizeToolNameForSubConversation(messagePart.tool) == 'task',
    );
  }

  List<ChatSession> _collectChildSessionCandidates(
    ChatProvider chatProvider, {
    required String currentSessionId,
  }) {
    final candidates = <ChatSession>[];
    final seenIds = <String>{};

    void addCandidate(ChatSession session) {
      if (!seenIds.add(session.id)) {
        return;
      }
      candidates.add(session);
    }

    for (final child in chatProvider.currentSessionChildren) {
      addCandidate(child);
    }
    for (final session in chatProvider.sessions) {
      final parentId = session.parentId?.trim();
      if (parentId == currentSessionId) {
        addCandidate(session);
      }
    }
    return candidates;
  }

  ChatSession? _resolveSubConversationFromCandidatesByPartOrder(
    ChatProvider chatProvider, {
    required List<ChatSession> candidates,
    required String targetPartId,
    required Iterable<String> explicitSessionIds,
    required bool Function(MessagePart part) anchorMatcher,
  }) {
    final sortedCandidates = List<ChatSession>.from(candidates)
      ..sort((a, b) => a.time.compareTo(b.time));
    final candidateIds = sortedCandidates.map((session) => session.id).toSet();

    for (final sessionId in explicitSessionIds) {
      final normalizedSessionId = sessionId.trim();
      if (normalizedSessionId.isEmpty ||
          !candidateIds.contains(normalizedSessionId)) {
        continue;
      }
      for (final session in sortedCandidates) {
        if (session.id == normalizedSessionId) {
          return session;
        }
      }
    }

    if (sortedCandidates.length == 1) {
      return sortedCandidates.first;
    }

    var taskIndex = 0;
    int? selectedTaskIndex;
    for (final message in chatProvider.messages) {
      for (final messagePart in message.parts) {
        if (!anchorMatcher(messagePart)) {
          continue;
        }
        if (messagePart.id == targetPartId) {
          selectedTaskIndex = taskIndex;
          break;
        }
        taskIndex += 1;
      }
      if (selectedTaskIndex != null) {
        break;
      }
    }

    if (selectedTaskIndex != null &&
        selectedTaskIndex >= 0 &&
        selectedTaskIndex < sortedCandidates.length) {
      return sortedCandidates[selectedTaskIndex];
    }

    return sortedCandidates.last;
  }

  String _normalizeToolNameForSubConversation(String rawToolName) {
    final normalized = rawToolName.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'tool';
    }
    final separatorIndex = normalized.lastIndexOf('.');
    final compactName = separatorIndex >= 0
        ? normalized.substring(separatorIndex + 1)
        : normalized;
    return compactName.replaceAll('-', '_');
  }

  List<String> _extractChildSessionIdsFromTaskToolPart(ToolPart part) {
    final ids = <String>[];
    final seen = <String>{};

    bool shouldCaptureKey(String key) {
      final normalized = key
          .trim()
          .toLowerCase()
          .replaceAll('_', '')
          .replaceAll('-', '');
      const candidateKeys = <String>{
        'childsessionid',
        'childsession',
        'subsessionid',
        'subsession',
        'subconversationid',
        'subconversation',
        'sessionid',
      };
      return candidateKeys.contains(normalized);
    }

    void visit(dynamic value, {String? key}) {
      if (value == null) {
        return;
      }
      if (value is String) {
        if (key != null && shouldCaptureKey(key)) {
          final normalized = value.trim();
          if (normalized.isNotEmpty && seen.add(normalized)) {
            ids.add(normalized);
          }
        }
        return;
      }
      if (value is Map) {
        for (final entry in value.entries) {
          final entryKey = entry.key.toString();
          visit(entry.value, key: entryKey);
        }
        return;
      }
      if (value is Iterable) {
        for (final item in value) {
          visit(item, key: key);
        }
      }
    }

    switch (part.state.status) {
      case ToolStatus.running:
        final state = part.state as ToolStateRunning;
        visit(state.input);
        visit(state.metadata);
        break;
      case ToolStatus.completed:
        final state = part.state as ToolStateCompleted;
        visit(state.input);
        visit(state.metadata);
        break;
      case ToolStatus.error:
        final state = part.state as ToolStateError;
        visit(state.input);
        visit(state.metadata);
        break;
      case ToolStatus.pending:
        break;
    }

    return ids;
  }

  void _showSubConversationNotice(String message) {
    if (!mounted) {
      return;
    }
    _showChatPageMessageSnackBar(message, hideCurrent: false);
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
    final appProvider = context.watch<AppProvider>();
    final isSubConversation = _isSubConversationSession(
      chatProvider.currentSession,
    );
    if (chatProvider.state == ChatState.loading &&
        chatProvider.messages.isEmpty &&
        chatProvider.currentSession == null) {
      return const ChatSkeletonShimmer();
    }

    if (chatProvider.state == ChatState.error &&
        chatProvider.currentSession == null) {
      final rawErrorMessage = chatProvider.errorMessage ?? 'An error occurred';
      if (!_shouldInlineOfflineComposerBlock(
        chatProvider: chatProvider,
        appProvider: appProvider,
        rawErrorMessage: rawErrorMessage,
      )) {
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
                normalizeAbortMessageForDisplay(rawErrorMessage),
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
    }

    if (chatProvider.state == ChatState.error &&
        chatProvider.currentSession != null &&
        chatProvider.messages.isEmpty) {
      final rawErrorMessage = chatProvider.errorMessage ?? 'An error occurred';
      if (!_shouldInlineOfflineComposerBlock(
        chatProvider: chatProvider,
        appProvider: appProvider,
        rawErrorMessage: rawErrorMessage,
      )) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Symbols.sync_problem,
                      size: 36,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Could not refresh this conversation',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      normalizeAbortMessageForDisplay(rawErrorMessage),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton(
                          onPressed: chatProvider.clearError,
                          child: const Text('Keep working'),
                        ),
                        FilledButton(
                          onPressed: () {
                            chatProvider.clearError();
                            chatProvider.refresh();
                          },
                          child: const Text('Retry refresh'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    if (chatProvider.currentSession == null &&
        !chatProvider.isDraftingNewChat) {
      final appProvider = context.watch<AppProvider>();
      final hasConfiguredServer = appProvider.activeServer != null;
      if (!hasConfiguredServer) {
        return MessageEntranceAnimation(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Symbols.dns_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No server configured yet',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a server to start chatting.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const ValueKey<String>('no_server_setup_button'),
                    onPressed: () {
                      unawaited(
                        Navigator.of(context).push(
                          AppPageRoute(
                            builder: (_) => OnboardingWizardPage(
                              showSkipAction: false,
                              initialFlow: SetupWizardInitialFlow.connectServer,
                              onComplete: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Symbols.add),
                    label: const Text('Set up server'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

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

    if (chatProvider.messages.isEmpty &&
        chatProvider.isCurrentSessionHydrating) {
      return const Center(
        child: SizedBox.square(
          key: ValueKey<String>('session_hydration_loading_indicator'),
          dimension: 28,
          child: CircularProgressIndicator.adaptive(strokeWidth: 2.5),
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
    final interactionPermissions = chatProvider.currentThreadPermissionRequests;
    final currentSessionId = chatProvider.currentSession?.id;
    final timelineEntries = _buildMessageTimelineEntries(
      sessionId: currentSessionId,
      messages: chatProvider.messages,
      messagesVersion: chatProvider.messagesVersion,
      showRetryIndicator: showMessageProgressIndicator,
      isSessionActivelyResponding:
          chatProvider.isCurrentSessionActivelyResponding,
      isCompactingContext: chatProvider.isCompactingContext,
      interactionPermissions: interactionPermissions,
    );
    final finalAssistantRevealMessageId =
        _resolveLatestRevealableAssistantMessageId(chatProvider.messages);
    final latestRevertibleMessageId = chatProvider.latestRevertibleMessageId;
    _pruneMessageRevealAnchorKeys(chatProvider.messages);

    // Determine which entries are new (for entrance animation.
    // Reset the baseline whenever the active session changes so that loading
    // an existing conversation never animates its full history as "new".
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
                    final messageWidget = _buildTimelineMessageWidget(
                      message: message,
                      chatProvider: chatProvider,
                      settingsProvider: settingsProvider,
                      latestReasoningPartKey: latestReasoningPartKey,
                      latestRevertibleMessageId: latestRevertibleMessageId,
                      isSubConversation: isSubConversation,
                      finalAssistantRevealMessageId:
                          finalAssistantRevealMessageId,
                    );
                    child = KeyedSubtree(
                      key: ValueKey<String>(entry.key),
                      child: messageWidget,
                    );
                  } else if (entry is _TimelineCollapsedHistoryEntry) {
                    child = _buildCollapsedHistoryEntry(entry);
                  } else if (entry is _TimelineCollapsedAssistantWorkEntry) {
                    child = _buildCollapsedAssistantWorkEntry(
                      entry,
                      buildPreviewMessage: (message) =>
                          _buildTimelineMessageWidget(
                            message: message,
                            chatProvider: chatProvider,
                            settingsProvider: settingsProvider,
                            latestReasoningPartKey: latestReasoningPartKey,
                            latestRevertibleMessageId:
                                latestRevertibleMessageId,
                            isSubConversation: isSubConversation,
                            finalAssistantRevealMessageId:
                                finalAssistantRevealMessageId,
                            wrapRevealAnchor: false,
                            keyPrefix: 'assistant_work_preview',
                          ),
                    );
                  } else if (entry is _TimelinePermissionPromptEntry) {
                    child = _buildInlinePermissionPromptEntry(
                      entry,
                      chatProvider,
                    );
                  } else {
                    child = _buildRetryingMessageIndicator();
                  }

                  // Animate only genuinely new entries at the tail.
                  // Pass the message role for role-specific motion profiles.
                  final isNewEntry = animateNewEntries && index >= prevLength;
                  if (isNewEntry) {
                    final shouldSuppressAssistantActiveTurnAnimation =
                        entry is _TimelineMessageEntry &&
                        _isMergeableAssistantToolOnlyMessage(entry.message) &&
                        chatProvider.isCurrentSessionActivelyResponding;
                    if (shouldSuppressAssistantActiveTurnAnimation) {
                      return child;
                    }
                    final role = entry is _TimelineMessageEntry
                        ? entry.message.role
                        : null;
                    final staggerIndex = index - prevLength;
                    return MessageEntranceAnimation(
                      role: role,
                      staggerIndex: staggerIndex < 0 ? 0 : staggerIndex,
                      child: child,
                    );
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

  String? _resolveComposerBlockReason({
    required ChatProvider chatProvider,
    required AppProvider appProvider,
  }) {
    if (appProvider.activeServer == null ||
        _shouldDeferForegroundWarningUi(
          chatProvider: chatProvider,
          appProvider: appProvider,
        )) {
      return null;
    }

    final hasChatError = chatProvider.state == ChatState.error;
    if (_hasConfirmedOfflineComposerBlock(
      chatProvider: chatProvider,
      appProvider: appProvider,
    )) {
      return 'Waiting for network connection...';
    }

    if (_hasConfirmedUnhealthyServerBlock(
      chatProvider: chatProvider,
      appProvider: appProvider,
    )) {
      return 'Active server is unhealthy';
    }

    return null;
  }

  bool _shouldInlineOfflineComposerBlock({
    required ChatProvider chatProvider,
    required AppProvider appProvider,
    required String? rawErrorMessage,
  }) {
    if (_hasConfirmedUnhealthyServerBlock(
      chatProvider: chatProvider,
      appProvider: appProvider,
    )) {
      return true;
    }

    return _hasConfirmedOfflineComposerBlock(
          chatProvider: chatProvider,
          appProvider: appProvider,
        ) &&
        isServerConnectionFailure(rawMessage: rawErrorMessage);
  }

  bool _hasConfirmedOfflineComposerBlock({
    required ChatProvider chatProvider,
    required AppProvider appProvider,
  }) {
    return chatProvider.state == ChatState.error &&
        !appProvider.isConnected &&
        isServerConnectionFailure(rawMessage: chatProvider.errorMessage);
  }

  bool _hasConfirmedUnhealthyServerBlock({
    required ChatProvider chatProvider,
    required AppProvider appProvider,
  }) {
    return chatProvider.state == ChatState.error &&
        appProvider.isConnected &&
        chatProvider.messages.isEmpty &&
        !isServerConnectionFailure(rawMessage: chatProvider.errorMessage) &&
        _activeServerHealth(appProvider) == ServerHealthStatus.unhealthy;
  }

  List<_TimelineEntry> _buildMessageTimelineEntries({
    required String? sessionId,
    required List<ChatMessage> messages,
    required int messagesVersion,
    required bool showRetryIndicator,
    required bool isSessionActivelyResponding,
    required bool isCompactingContext,
    required List<ChatPermissionRequest> interactionPermissions,
  }) {
    final settingsProvider = _settingsProvider;
    final showThinkingBubbles = settingsProvider?.showThinkingBubbles ?? true;
    final showToolCallBubbles = settingsProvider?.showToolCallBubbles ?? true;
    final assistantWorkCompactionDecision =
        _resolveAssistantWorkCompactionDecision(
          messages: messages,
          isResponding: isSessionActivelyResponding,
        );
    final permissionPromptSignature = interactionPermissions
        .map((request) => '${request.id}:${request.sessionId}')
        .join('|');
    final cachedEntry = _consumeSessionTimelineEntriesCache(sessionId);
    if (cachedEntry != null &&
        _canReuseSessionTimelineEntriesCache(
          cachedEntry,
          sourceMessages: messages,
          messagesVersion: messagesVersion,
          isCompactingContext: isCompactingContext,
          isSessionActivelyResponding: isSessionActivelyResponding,
          showRetryIndicator: showRetryIndicator,
          permissionPromptSignature: permissionPromptSignature,
          assistantWorkCompactionDecision: assistantWorkCompactionDecision,
          showThinkingBubbles: showThinkingBubbles,
          showToolCallBubbles: showToolCallBubbles,
        )) {
      return cachedEntry.entries;
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
            assistantWorkCompactionDecision: assistantWorkCompactionDecision,
          );
        }
        _appendTimelineEntriesForRange(
          entries: entries,
          messages: messages,
          startIndex: boundaryIndex,
          endExclusive: messages.length,
          assistantWorkCompactionDecision: assistantWorkCompactionDecision,
        );
      }
    }

    if (entries.isEmpty) {
      _appendTimelineEntriesForRange(
        entries: entries,
        messages: messages,
        startIndex: 0,
        endExclusive: messages.length,
        assistantWorkCompactionDecision: assistantWorkCompactionDecision,
      );
    }

    for (final request in interactionPermissions) {
      entries.add(_TimelinePermissionPromptEntry(request: request));
    }

    if (showRetryIndicator) {
      entries.add(const _TimelineRetryIndicatorEntry());
    }

    _storeSessionTimelineEntriesCache(
      sessionId,
      _SessionTimelineEntriesCacheEntry(
        sourceMessages: List<ChatMessage>.from(messages, growable: false),
        entries: List<_TimelineEntry>.from(entries, growable: false),
        messagesVersion: messagesVersion,
        isCompacting: isCompactingContext,
        isResponding: isSessionActivelyResponding,
        showRetry: showRetryIndicator,
        permissionPromptSignature: permissionPromptSignature,
        assistantWorkCompactionDecision: assistantWorkCompactionDecision,
        expandedHistoryGroupId: _expandedCollapsedHistoryGroupId,
        expandedAssistantWorkGroupId: _expandedAssistantWorkGroupId,
        wasCompactingContext: _wasCompactingContext,
        frozenCompactionBoundaryId: _frozenCompactionBoundaryId,
        showThinkingBubbles: showThinkingBubbles,
        showToolCallBubbles: showToolCallBubbles,
      ),
    );
    return entries;
  }

  bool _canReuseSessionTimelineEntriesCache(
    _SessionTimelineEntriesCacheEntry entry, {
    required List<ChatMessage> sourceMessages,
    required int messagesVersion,
    required bool isCompactingContext,
    required bool isSessionActivelyResponding,
    required bool showRetryIndicator,
    required String permissionPromptSignature,
    required _AssistantWorkCompactionDecision assistantWorkCompactionDecision,
    required bool showThinkingBubbles,
    required bool showToolCallBubbles,
  }) {
    final versionMatch =
        entry.messagesVersion == messagesVersion ||
        _areTimelineSourceMessagesIdentical(
          entry.sourceMessages,
          sourceMessages,
        );
    final compactingMatch = entry.isCompacting == isCompactingContext;
    final respondingMatch =
        entry.isResponding == isSessionActivelyResponding ||
        (entry.assistantWorkCompactionDecision.shouldDeferLatestCollapse ==
                assistantWorkCompactionDecision.shouldDeferLatestCollapse &&
            entry
                    .assistantWorkCompactionDecision
                    .settledLatestAssistantWorkGroupId ==
                assistantWorkCompactionDecision
                    .settledLatestAssistantWorkGroupId);
    final retryMatch = entry.showRetry == showRetryIndicator;
    final permMatch =
        entry.permissionPromptSignature == permissionPromptSignature;
    final compactionMatch =
        entry.assistantWorkCompactionDecision.shouldDeferLatestCollapse ==
            assistantWorkCompactionDecision.shouldDeferLatestCollapse &&
        entry
                .assistantWorkCompactionDecision
                .settledLatestAssistantWorkGroupId ==
            assistantWorkCompactionDecision.settledLatestAssistantWorkGroupId;
    final historyGroupMatch =
        entry.expandedHistoryGroupId == _expandedCollapsedHistoryGroupId;
    final workGroupMatch =
        entry.expandedAssistantWorkGroupId == _expandedAssistantWorkGroupId;
    final wasCompactingMatch =
        entry.wasCompactingContext == _wasCompactingContext;
    final frozenMatch =
        entry.frozenCompactionBoundaryId == _frozenCompactionBoundaryId;
    final thinkingMatch = entry.showThinkingBubbles == showThinkingBubbles;
    final toolMatch = entry.showToolCallBubbles == showToolCallBubbles;

    final canReuse =
        versionMatch &&
        compactingMatch &&
        respondingMatch &&
        retryMatch &&
        permMatch &&
        compactionMatch &&
        historyGroupMatch &&
        workGroupMatch &&
        wasCompactingMatch &&
        frozenMatch &&
        thinkingMatch &&
        toolMatch;

    if (!canReuse) {
      final reasons = <String>[];
      if (!versionMatch) reasons.add('version');
      if (!compactingMatch) reasons.add('compacting');
      if (!respondingMatch) reasons.add('responding');
      if (!retryMatch) reasons.add('retry');
      if (!permMatch) reasons.add('permission');
      if (!compactionMatch) reasons.add('compaction');
      if (!historyGroupMatch) reasons.add('historyGroup');
      if (!workGroupMatch) reasons.add('workGroup');
      if (!wasCompactingMatch) reasons.add('wasCompacting');
      if (!frozenMatch) reasons.add('frozen');
      if (!thinkingMatch) reasons.add('thinking');
      if (!toolMatch) reasons.add('tool');
      AppLogger.debug(
        'CW_CACHE timeline cache invalidated: ${reasons.join(", ")}',
      );
    }

    return canReuse;
  }

  bool _areTimelineSourceMessagesIdentical(
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

  _SessionTimelineEntriesCacheEntry? _consumeSessionTimelineEntriesCache(
    String? sessionId,
  ) {
    if (sessionId == null || sessionId.isEmpty) {
      return null;
    }
    final cachedEntry = _sessionTimelineEntriesCache.remove(sessionId);
    if (cachedEntry == null) {
      return null;
    }
    _sessionTimelineEntriesCache[sessionId] = cachedEntry;
    return cachedEntry;
  }

  void _storeSessionTimelineEntriesCache(
    String? sessionId,
    _SessionTimelineEntriesCacheEntry entry,
  ) {
    if (sessionId == null || sessionId.isEmpty) {
      return;
    }
    _sessionTimelineEntriesCache.remove(sessionId);
    _sessionTimelineEntriesCache[sessionId] = entry;
    while (_sessionTimelineEntriesCache.length >
        _ChatPageState._maxHydratedTimelineCacheEntries) {
      _sessionTimelineEntriesCache.remove(
        _sessionTimelineEntriesCache.keys.first,
      );
    }
  }

  void _appendTimelineEntriesForRange({
    required List<_TimelineEntry> entries,
    required List<ChatMessage> messages,
    required int startIndex,
    required int endExclusive,
    required _AssistantWorkCompactionDecision assistantWorkCompactionDecision,
  }) {
    if (startIndex >= endExclusive) {
      return;
    }

    final settingsProvider = _settingsProvider;
    final showThinkingBubbles = settingsProvider?.showThinkingBubbles ?? true;
    final showToolCallBubbles = settingsProvider?.showToolCallBubbles ?? true;
    final isActivelyResponding =
        assistantWorkCompactionDecision.shouldDeferLatestCollapse;

    var index = startIndex;
    while (index < endExclusive) {
      final current = messages[index];
      if (current is! UserMessage) {
        if (!isActivelyResponding &&
            _isMergeableAssistantToolOnlyMessage(current)) {
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
          assistantRunEnd == endExclusive &&
          assistantWorkCompactionDecision.shouldDeferLatestCollapse;
      if (assistantRunEnd == endExclusive) {
        _traceFinalUi(
          'timeline-current-assistant-run',
          details:
              'finalAssistantId=${finalAssistant.id} completed=${finalAssistant.isCompleted} workMessageCount=$workMessageCount shouldDeferCurrentRunCollapse=$shouldDeferCurrentRunCollapse',
        );
      }
      final visibleWorkPreviewMessages = _visibleAssistantWorkPreviewMessages(
        messages: messages,
        startIndex: assistantRunStart,
        endExclusive: assistantRunEnd - 1,
        showThinkingBubbles: showThinkingBubbles,
        showToolCallBubbles: showToolCallBubbles,
      );
      if (workMessageCount > 0 &&
          visibleWorkPreviewMessages.isNotEmpty &&
          !shouldDeferCurrentRunCollapse &&
          _isSuccessfulFinalAssistantMessage(finalAssistant)) {
        _traceFinalUi(
          'timeline-collapse-assistant-work-run',
          details:
              'workMessageCount=$workMessageCount finalAssistantId=${finalAssistant.id} assistantRunStart=$assistantRunStart assistantRunEnd=$assistantRunEnd',
        );
        final workGroup = _CollapsedAssistantWorkGroup(
          startMessageId: messages[assistantRunStart].id,
          endMessageId: messages[assistantRunEnd - 2].id,
          finalMessageId: finalAssistant.id,
          messageCount: workMessageCount,
          createdAt: finalAssistant.time,
        );
        final expanded = _expandedAssistantWorkGroupId == workGroup.id;
        final showBoundedPreview = assistantRunEnd == endExclusive;
        entries.add(
          _TimelineCollapsedAssistantWorkEntry(
            group: workGroup,
            expanded: expanded,
            showBoundedPreview: showBoundedPreview,
            previewMessages: showBoundedPreview
                ? visibleWorkPreviewMessages
                : const <ChatMessage>[],
          ),
        );
        if (expanded) {
          _appendRangeWithAssistantToolMerging(
            entries: entries,
            messages: messages,
            startIndex: assistantRunStart,
            endExclusive: assistantRunEnd - 1,
            isActivelyResponding: false,
          );
        }
        entries.add(_TimelineMessageEntry(finalAssistant));
        if (assistantRunEnd == endExclusive) {
          _traceFinalUi(
            'timeline-current-assistant-run-collapsed',
            details:
                'finalAssistantId=${finalAssistant.id} workGroupId=${workGroup.id}',
          );
        }
      } else {
        if (shouldDeferCurrentRunCollapse) {
          _traceFinalUi(
            'timeline-defer-assistant-work-collapse',
            details:
                'workMessageCount=$workMessageCount finalAssistantId=${finalAssistant.id} endExclusive=$endExclusive',
          );
        }
        _appendRangeWithAssistantToolMerging(
          entries: entries,
          messages: messages,
          startIndex: assistantRunStart,
          endExclusive: assistantRunEnd,
          isActivelyResponding:
              shouldDeferCurrentRunCollapse && assistantRunEnd == endExclusive,
        );
        if (assistantRunEnd == endExclusive) {
          _traceFinalUi(
            'timeline-current-assistant-run-not-collapsed',
            details:
                'finalAssistantId=${finalAssistant.id} workMessageCount=$workMessageCount',
          );
        }
      }

      index = assistantRunEnd;
    }
  }

  void _appendRangeWithAssistantToolMerging({
    required List<_TimelineEntry> entries,
    required List<ChatMessage> messages,
    required int startIndex,
    required int endExclusive,
    required bool isActivelyResponding,
  }) {
    if (startIndex >= endExclusive) {
      return;
    }

    var index = startIndex;
    while (index < endExclusive) {
      final current = messages[index];
      if (isActivelyResponding ||
          !_isMergeableAssistantToolOnlyMessage(current)) {
        if (isActivelyResponding &&
            _isMergeableAssistantToolOnlyMessage(current)) {
          _traceFinalUi(
            'timeline-tool-merge-deferred-active-turn',
            details: 'messageId=${current.id}',
          );
        }
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

  bool _timelineMessageHasVisibleContent(
    ChatMessage message, {
    required bool showThinkingBubbles,
    required bool showToolCallBubbles,
  }) {
    for (final part in message.parts) {
      switch (part.type) {
        case PartType.reasoning:
          final reasoningPart = part as ReasoningPart;
          if (!showThinkingBubbles) {
            continue;
          }
          if (parseReasoningStatusLabel(reasoningPart.text) == null &&
              reasoningPart.text.trim().isNotEmpty) {
            return true;
          }
          continue;
        case PartType.tool:
          if (!showToolCallBubbles) {
            continue;
          }
          if (part is ToolPart &&
              part.tool.trim().toLowerCase() == 'todowrite') {
            continue;
          }
          return true;
        case PartType.patch:
          if (!showToolCallBubbles) {
            continue;
          }
          return true;
        case PartType.text:
          if ((part as TextPart).text.trim().isNotEmpty) {
            return true;
          }
          continue;
        case PartType.stepStart:
        case PartType.stepFinish:
          continue;
        default:
          return true;
      }
    }
    return false;
  }

  List<ChatMessage> _visibleAssistantWorkPreviewMessages({
    required List<ChatMessage> messages,
    required int startIndex,
    required int endExclusive,
    required bool showThinkingBubbles,
    required bool showToolCallBubbles,
  }) {
    final previewMessages = _buildAssistantWorkPreviewMessages(
      messages: messages,
      startIndex: startIndex,
      endExclusive: endExclusive,
    );
    return previewMessages
        .where(
          (message) => _timelineMessageHasVisibleContent(
            message,
            showThinkingBubbles: showThinkingBubbles,
            showToolCallBubbles: showToolCallBubbles,
          ),
        )
        .toList(growable: false);
  }

  List<ChatMessage> _buildAssistantWorkPreviewMessages({
    required List<ChatMessage> messages,
    required int startIndex,
    required int endExclusive,
  }) {
    final previewEntries = <_TimelineEntry>[];
    _appendRangeWithAssistantToolMerging(
      entries: previewEntries,
      messages: messages,
      startIndex: startIndex,
      endExclusive: endExclusive,
      isActivelyResponding: false,
    );
    return previewEntries
        .whereType<_TimelineMessageEntry>()
        .map((entry) => entry.message)
        .toList(growable: false);
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

  String? _resolveLatestRevealableAssistantMessageId(
    List<ChatMessage> messages,
  ) {
    for (var index = messages.length - 1; index >= 0; index -= 1) {
      final message = messages[index];
      if (message is UserMessage) {
        return null;
      }
      if (message is! AssistantMessage) {
        continue;
      }
      if (message.summary == true) {
        continue;
      }
      return message.id;
    }
    return null;
  }

  String? _resolveLatestSettledAssistantWorkGroupId({
    required List<ChatMessage> messages,
    required bool showThinkingBubbles,
    required bool showToolCallBubbles,
  }) {
    if (messages.isEmpty) {
      return null;
    }

    final endExclusive = messages.length;
    var assistantRunStart = endExclusive;
    while (assistantRunStart > 0 &&
        messages[assistantRunStart - 1] is AssistantMessage) {
      assistantRunStart -= 1;
    }

    if (assistantRunStart <= 0 ||
        assistantRunStart >= endExclusive ||
        messages[assistantRunStart - 1] is! UserMessage) {
      return null;
    }

    final finalAssistant = messages[endExclusive - 1];
    if (finalAssistant is! AssistantMessage ||
        !_isSuccessfulFinalAssistantMessage(finalAssistant)) {
      return null;
    }

    final workMessageCount = endExclusive - assistantRunStart - 1;
    if (workMessageCount <= 0) {
      return null;
    }

    final visibleWorkPreviewMessages = _visibleAssistantWorkPreviewMessages(
      messages: messages,
      startIndex: assistantRunStart,
      endExclusive: endExclusive - 1,
      showThinkingBubbles: showThinkingBubbles,
      showToolCallBubbles: showToolCallBubbles,
    );
    if (visibleWorkPreviewMessages.isEmpty) {
      return null;
    }

    return _CollapsedAssistantWorkGroup(
      startMessageId: messages[assistantRunStart].id,
      endMessageId: messages[endExclusive - 2].id,
      finalMessageId: finalAssistant.id,
      messageCount: workMessageCount,
      createdAt: finalAssistant.time,
    ).id;
  }
}
