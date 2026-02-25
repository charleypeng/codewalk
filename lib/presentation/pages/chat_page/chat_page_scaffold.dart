part of '../chat_page.dart';

extension _ChatPageScaffold on _ChatPageState {
  Widget _buildSessionDrawer() {
    return Drawer(
      child: SafeArea(child: _buildSessionPanel(closeOnSelect: true)),
    );
  }

  Widget _buildSidebarNavigation({required bool closeOnSelect}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildServerStatusControl(
                      closeOnSelect: closeOnSelect,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Settings',
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: FilledButton.tonal(
                        key: const ValueKey<String>(
                          'sidebar_settings_icon_button',
                        ),
                        style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: () => unawaited(
                          _openSettingsPage(closeOnSelect: closeOnSelect),
                        ),
                        child: const Icon(Symbols.settings),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionPanel({
    required bool closeOnSelect,
    VoidCallback? onCollapseRequested,
  }) {
    return Consumer2<ChatProvider, ProjectProvider>(
      builder: (context, chatProvider, projectProvider, child) {
        if (_sessionSearchController.text != chatProvider.sessionSearchQuery) {
          _sessionSearchController.value = TextEditingValue(
            text: chatProvider.sessionSearchQuery,
            selection: TextSelection.collapsed(
              offset: chatProvider.sessionSearchQuery.length,
            ),
          );
        }

        final directoryLabels = <String, String>{
          for (final project in projectProvider.openProjects)
            _directoryLabel(project.path): _projectDisplayLabel(project),
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSidebarNavigation(closeOnSelect: closeOnSelect),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Conversations',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Symbols.add),
                            onPressed: _createNewSession,
                            tooltip: 'New Chat',
                          ),
                          if (!FeatureFlags.refreshlessRealtime)
                            IconButton(
                              icon: const Icon(Symbols.refresh),
                              onPressed: _refreshData,
                              tooltip: 'Refresh',
                            ),
                          if (onCollapseRequested != null)
                            IconButton(
                              key: const ValueKey<String>(
                                'hide_conversations_sidebar_button',
                              ),
                              icon: const Icon(
                                Symbols.left_panel_close_rounded,
                              ),
                              onPressed: onCollapseRequested,
                              tooltip: 'Hide Conversations sidebar',
                            ),
                        ],
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          PopupMenuButton<SessionListFilter>(
                            tooltip: 'Filter sessions',
                            onSelected: chatProvider.setSessionListFilter,
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: SessionListFilter.active,
                                child: Text('Active'),
                              ),
                              PopupMenuItem(
                                value: SessionListFilter.archived,
                                child: Text('Archived'),
                              ),
                              PopupMenuItem(
                                value: SessionListFilter.all,
                                child: Text('All'),
                              ),
                            ],
                            child: _headerChip(
                              context,
                              icon: Symbols.filter_list,
                              label: switch (chatProvider.sessionListFilter) {
                                SessionListFilter.active => 'Active',
                                SessionListFilter.archived => 'Archived',
                                SessionListFilter.all => 'All',
                              },
                            ),
                          ),
                          PopupMenuButton<SessionListSort>(
                            tooltip: 'Sort sessions',
                            onSelected: chatProvider.setSessionListSort,
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: SessionListSort.recent,
                                child: Text('Most Recent'),
                              ),
                              PopupMenuItem(
                                value: SessionListSort.oldest,
                                child: Text('Oldest'),
                              ),
                              PopupMenuItem(
                                value: SessionListSort.title,
                                child: Text('Title'),
                              ),
                            ],
                            child: _headerChip(
                              context,
                              icon: Symbols.sort,
                              label: switch (chatProvider.sessionListSort) {
                                SessionListSort.recent => 'Recent',
                                SessionListSort.oldest => 'Oldest',
                                SessionListSort.title => 'Title',
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _sessionSearchController,
                        onChanged: chatProvider.setSessionSearchQuery,
                        decoration: InputDecoration(
                          hintText: 'Search conversations',
                          prefixIcon: const Icon(Symbols.search),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ChatSessionList(
                      sessions: chatProvider.visibleSidebarSessions,
                      currentSession: chatProvider.currentSession,
                      groupByProject: true,
                      activeDirectory: projectProvider.currentDirectory,
                      directoryLabels: directoryLabels,
                      isSessionActive: chatProvider.isSessionActivelyResponding,
                      onSessionSelected: (session) async {
                        var switchedContext = false;
                        final sessionDirectory =
                            session.directory ??
                            session.path?.workspace ??
                            session.path?.root;
                        if (sessionDirectory != null &&
                            sessionDirectory.trim().isNotEmpty &&
                            sessionDirectory.trim() !=
                                (projectProvider.currentDirectory ?? '')
                                    .trim()) {
                          switchedContext = true;
                          await _switchDirectoryContext(
                            sessionDirectory,
                            preferredSessionId: session.id,
                          );
                        }
                        final activeChatProvider = context.read<ChatProvider>();
                        if (!switchedContext ||
                            activeChatProvider.currentSession?.id !=
                                session.id) {
                          final refreshedSession =
                              activeChatProvider.visibleSidebarSessions
                                  .where((item) => item.id == session.id)
                                  .firstOrNull ??
                              session;
                          await activeChatProvider.selectSession(
                            refreshedSession,
                          );
                        }
                        // Close AFTER selectSession: during its awaits the
                        // second tap's gesture events are fully processed
                        // (including _handleDragCancel which may re-open the
                        // drawer). Closing last ensures the drawer stays shut.
                        _closeDrawerIfNeeded(closeOnSelect: closeOnSelect);
                      },
                      onSessionDeleted: (session) async {
                        await chatProvider.deleteSession(session.id);
                      },
                      onSessionRenamed: (session, title) {
                        return chatProvider.renameSession(session, title);
                      },
                      onSessionShareToggled: (session) {
                        return chatProvider.toggleSessionShare(session);
                      },
                      onSessionArchiveToggled: (session, archived) {
                        return chatProvider.setSessionArchived(
                          session,
                          archived,
                        );
                      },
                      onSessionForked: (session) async {
                        final created = await chatProvider.forkSession(session);
                        if (!context.mounted) {
                          return;
                        }
                        if (created == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to fork conversation'),
                            ),
                          );
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Conversation forked')),
                        );
                        _closeDrawerIfNeeded(closeOnSelect: closeOnSelect);
                      },
                    ),
                  ),
                  if (chatProvider.canLoadMoreSidebarSessions)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: OutlinedButton.icon(
                        onPressed: chatProvider.loadMoreSessions,
                        icon: const Icon(Symbols.expand_more),
                        label: const Text('Load more'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktopUtilityPane(
    ChatProvider chatProvider, {
    required SettingsProvider settingsProvider,
    VoidCallback? onCollapseRequested,
  }) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (onCollapseRequested != null)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                key: const ValueKey<String>('hide_utility_sidebar_button'),
                tooltip: 'Hide Utility sidebar',
                onPressed: onCollapseRequested,
                icon: const Icon(Symbols.right_panel_close_rounded),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keyboard shortcuts',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final hint in _desktopShortcutHints(settingsProvider))
                    _buildShortcutHint(hint.shortcut, hint.description),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _createNewSession,
            icon: const Icon(Symbols.add_comment),
            label: const Text('New Chat'),
          ),
          if (!FeatureFlags.refreshlessRealtime) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Symbols.refresh),
              label: const Text('Refresh'),
            ),
          ],
          const SizedBox(height: 12),
          if (chatProvider.currentSession != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final currentSession =
                                  chatProvider.currentSession!;
                              return SessionTitleInlineEditor(
                                key: ValueKey<String>(
                                  'desktop_session_title_editor_${currentSession.id}',
                                ),
                                title: _sessionDisplayTitle(currentSession),
                                editingValue: _sessionEditingValue(
                                  currentSession,
                                ),
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                                onRename: (title) => chatProvider.renameSession(
                                  currentSession,
                                  title,
                                ),
                              );
                            },
                          ),
                        ),
                        if (!FeatureFlags.refreshlessRealtime)
                          IconButton(
                            onPressed: () {
                              final session = chatProvider.currentSession;
                              if (session != null) {
                                unawaited(
                                  chatProvider.loadSessionInsights(session.id),
                                );
                              }
                            },
                            icon: const Icon(Symbols.sync, size: 18),
                            tooltip: 'Refresh session details',
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _sessionStatusLabel(
                        chatProvider.currentSessionStatus ??
                            const SessionStatusInfo(
                              type: SessionStatusType.idle,
                            ),
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Children: ${chatProvider.currentSessionChildren.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    SessionTodoListWidget(
                      todos: chatProvider.currentSessionTodo,
                      collapsed: settingsProvider.taskListCollapsed,
                      onToggleCollapsed: () => unawaited(
                        settingsProvider.setTaskListCollapsed(
                          !settingsProvider.taskListCollapsed,
                        ),
                      ),
                      maxVisibleItems: 10,
                    ),
                    Text(
                      'Diff files: ${chatProvider.currentSessionDiff.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (chatProvider.isLoadingSessionInsights)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    if (chatProvider.sessionInsightsError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          chatProvider.sessionInsightsError!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
