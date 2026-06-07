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
    final isLatestRevertible =
        message is UserMessage && message.id == latestRevertibleMessageId;
    final isHistoricalUserMessage =
        message is UserMessage &&
        message.id != latestRevertibleMessageId &&
        !message.id.startsWith('local_user_');
    Widget messageWidget = ChatMessageWidget(
      key: ValueKey<String>(
        '${keyPrefix ?? 'chat_message_widget'}_${message.id}',
      ),
      message: message,
      activeReasoningPartKey: latestReasoningPartKey,
      showThinkingBubbles: settingsProvider.showThinkingBubbles,
      showToolCallBubbles: settingsProvider.showToolCallBubbles,
      showInlineUndoAction: isLatestRevertible,
      isSessionActivelyResponding:
          chatProvider.isCurrentSessionActivelyResponding,
      onInlineUndo: isLatestRevertible
          ? () => unawaited(
              _triggerHistoryAction(
                chatProvider,
                action: _HistoryToolbarAction.undo,
              ),
            )
          : null,
      onInlineRevertToHere: isHistoricalUserMessage
          ? () => unawaited(chatProvider.revertToTurn(message.id))
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
      onFileTap: _onFilePathTap,
      taskToolChildSummariesByPartId: taskToolChildSummariesByPartId,
      searchHighlightQuery: _timelineSearchHighlightQuery,
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
    final chatFontScale = settingsProvider.chatFontScale;
    if (chatFontScale != 1.0) {
      final mediaQuery = MediaQuery.of(context);
      final combinedScale = mediaQuery.textScaler.scale(1.0) * chatFontScale;
      messageWidget = MediaQuery(
        key: ValueKey<String>('chat_message_font_scale_${message.id}'),
        data: mediaQuery.copyWith(
          textScaler: TextScaler.linear(combinedScale),
        ),
        child: messageWidget,
      );
    }
    return messageWidget;
  }

  Widget _wrapWithChatFontScale({
    required BuildContext context,
    required SettingsProvider settingsProvider,
    required Widget child,
  }) {
    final chatFontScale = settingsProvider.chatFontScale;
    if (chatFontScale == 1.0) {
      return child;
    }
    final mediaQuery = MediaQuery.of(context);
    final combinedScale = mediaQuery.textScaler.scale(1.0) * chatFontScale;
    return MediaQuery(
      key: const ValueKey<String>('chat_input_font_scale'),
      data: mediaQuery.copyWith(
        textScaler: TextScaler.linear(combinedScale),
      ),
      child: child,
    );
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
      context: context,
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
                                            tooltip:
                                                context.l10n.chatSessionActions,
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
                                                buildActionItem(
                                                  _CurrentSessionAction
                                                      .exportMarkdown,
                                                ),
                                                buildActionItem(
                                                  _CurrentSessionAction
                                                      .exportJson,
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
                                            tooltip:
                                                context.l10n.chatCompactContext,
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
                              !sp.showReviewChanges ||
                              (!isCompactLayout && utilityPaneVisible)) {
                            return const SizedBox.shrink();
                          }
                          return _buildInlineDiffCard(context, chatProvider);
                        },
                      ),
                      // Message list — guarded by Selector to skip rebuild on selection-only changes
                      Expanded(
                        child: Selector<ChatProvider, _ViewportBuildKey>(
                          selector: (_, p) => _ViewportBuildKey(
                            sessionId: p.currentSession?.id,
                            messagesVersion: p.messagesVersion,
                            isActivelyResponding:
                                p.isCurrentSessionActivelyResponding,
                          ),
                          builder: (context, _, __) => _buildMessageViewport(
                            context.read<ChatProvider>(),
                          ),
                        ),
                      ),

                      if (!hideComposerForTerminal)
                        _buildInteractionPrompts(chatProvider),

                      if (!hideComposerForTerminal)
                        _buildComposerReasoningStatusSlot(composerStatus),

                      if (!hideComposerForTerminal)
                        Consumer<ChatProvider>(
                          builder: (_, cp, __) => _buildModelControls(
                            cp,
                            isSubConversation: isSubConversation,
                          ),
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
                            return _wrapWithChatFontScale(
                              context: context,
                              settingsProvider: settingsProvider,
                              child: ChatInputWidget(
                                key: ValueKey(
                                  'chat_input_${currentSessionId ?? 'draft'}',
                                ),
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
                              appDensity: settingsProvider.appDensity,
                              onRemoveContextItem: (index) {
                                if (index >= 0 &&
                                    index < _fileContextItems.length) {
                                  _setState(() {
                                    _fileContextItems.removeAt(index);
                                  });
                                }
                              },
                            ),
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
          label: Text(context.l10n.chatReturnToMainConversation),
        ),
      ),
    );
  }

  Future<void> _returnToMainConversation(ChatProvider chatProvider) async {
    final mainConversation = _resolveMainConversation(chatProvider);
    if (mainConversation == null) {
      _showSubConversationNotice(context.l10n.chatMainConversationUnavailable);
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
            context.l10n.chatFailedToRefreshSubConversations,
          );
          return;
        }
      }
      target = resolveTarget();
    }

    if (target == null) {
      _showSubConversationNotice(context.l10n.chatNoSubConversationFound);
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
}
