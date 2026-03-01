part of '../chat_page.dart';

extension _ChatPageScaffold on _ChatPageState {
  Widget _buildSessionDrawer() {
    return Drawer(
      child: SafeArea(
        child: _buildSessionPanel(closeOnSelect: true, isMobileLayout: true),
      ),
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
    required bool isMobileLayout,
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSidebarNavigation(closeOnSelect: closeOnSelect),
            _buildProjectGroupsCard(
              chatProvider: chatProvider,
              projectProvider: projectProvider,
              closeOnSelect: closeOnSelect,
              isMobileLayout: isMobileLayout,
            ),
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
                      sessions: chatProvider.visibleSessions,
                      currentSession: chatProvider.currentSession,
                      isSessionActive: chatProvider.isSessionActivelyResponding,
                      sessionAttentionFor: chatProvider.sessionAttentionFor,
                      isMobileLayout: isMobileLayout,
                      onSessionSelected: (session) async {
                        if (closeOnSelect) {
                          // Allow the gesture arena to fully settle the tap and cancel any drags
                          // before we instruct the drawer to close. This prevents the drawer's
                          // drag-cancel from overriding our close command and snapping back open.
                          unawaited(
                            Future.delayed(
                              const Duration(milliseconds: 50),
                              () {
                                _closeDrawerIfNeeded(
                                  closeOnSelect: closeOnSelect,
                                );
                              },
                            ),
                          );
                          // Await the switch so ChatSessionList's in-flight guard
                          // stays active, preventing double-taps.
                          await _handleSessionSwitch(session);
                          return;
                        }
                        await _handleSessionSwitch(session);
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
                  if (chatProvider.canLoadMoreSessions)
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

  Widget _buildProjectGroupsCard({
    required ChatProvider chatProvider,
    required ProjectProvider projectProvider,
    required bool closeOnSelect,
    required bool isMobileLayout,
  }) {
    final openProjects = projectProvider.openProjects;
    final currentProjectId = projectProvider.currentProject?.id;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Projects',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey<String>('project_groups_open_folder'),
                    icon: const Icon(Symbols.add_box),
                    tooltip: 'Open project folder...',
                    onPressed: () => unawaited(_createWorkspace()),
                  ),
                  if (!FeatureFlags.refreshlessRealtime)
                    IconButton(
                      key: const ValueKey<String>('project_groups_refresh'),
                      icon: const Icon(Symbols.refresh),
                      tooltip: 'Refresh projects',
                      onPressed: () =>
                          unawaited(projectProvider.loadProjects()),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Conversations grouped by open project context.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              for (var index = 0; index < openProjects.length; index += 1) ...[
                _buildProjectGroupTile(
                  chatProvider: chatProvider,
                  projectProvider: projectProvider,
                  project: openProjects[index],
                  selected: openProjects[index].id == currentProjectId,
                  closeOnSelect: closeOnSelect,
                  isMobileLayout: isMobileLayout,
                ),
                if (index < openProjects.length - 1)
                  const Divider(height: 1, indent: 8, endIndent: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectGroupTile({
    required ChatProvider chatProvider,
    required ProjectProvider projectProvider,
    required Project project,
    required bool selected,
    required bool closeOnSelect,
    required bool isMobileLayout,
  }) {
    final scopeId = _scopeIdForProject(project);
    final sessions = chatProvider.visibleSessionsForScopeId(scopeId);
    final preview = sessions.take(selected ? 2 : 1).toList(growable: false);
    final hasSnapshot = chatProvider.hasSnapshotForScopeId(scopeId);
    final displayName = _projectDisplayLabel(project);
    final subtitle = _directoryLabel(project.path);
    final canClose = projectProvider.openProjects.length > 1 || !selected;

    return Column(
      children: [
        ListTile(
          key: ValueKey<String>('project_group_tile_${project.id}'),
          dense: _useDenseListTiles(context),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          leading: Icon(
            selected ? Symbols.radio_button_checked : Symbols.folder_open,
            size: 20,
          ),
          title: Text(displayName, overflow: TextOverflow.ellipsis),
          subtitle: subtitle == displayName
              ? null
              : Text(subtitle, overflow: TextOverflow.ellipsis),
          selected: selected,
          onTap: () => unawaited(
            _switchProjectFromGroup(
              projectId: project.id,
              closeOnSelect: closeOnSelect,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!selected && !hasSnapshot)
                Tooltip(
                  message: 'No cached conversations yet',
                  child: Icon(
                    Symbols.cloud_off,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: selected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Text(
                  '${sessions.length}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              const SizedBox(width: 2),
              IconButton(
                key: ValueKey<String>('project_group_close_${project.id}'),
                icon: const Icon(Symbols.close_rounded),
                tooltip: 'Close $displayName',
                onPressed: canClose
                    ? () => unawaited(_closeProjectContext(project.id))
                    : null,
              ),
            ],
          ),
        ),
        if (preview.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 6),
            child: Column(
              children: [
                for (final session in preview)
                  ListTile(
                    key: ValueKey<String>(
                      'project_group_session_preview_${project.id}_${session.id}',
                    ),
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    visualDensity: VisualDensity.compact,
                    leading: const Icon(Symbols.chat_bubble, size: 16),
                    title: Text(
                      _sessionDisplayTitle(session),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () => unawaited(
                      _openSessionFromProjectGroup(
                        projectId: project.id,
                        sessionId: session.id,
                        closeOnSelect: closeOnSelect,
                      ),
                    ),
                  ),
              ],
            ),
          )
        else if (!selected)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                hasSnapshot
                    ? 'No conversations in this project.'
                    : 'Open project to load conversations.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        if (!isMobileLayout && !selected && !hasSnapshot)
          const SizedBox(height: 2),
      ],
    );
  }

  Future<void> _switchProjectFromGroup({
    required String projectId,
    required bool closeOnSelect,
  }) async {
    await _switchProjectContext(projectId);
    _closeDrawerIfNeeded(closeOnSelect: closeOnSelect);
  }

  Future<void> _openSessionFromProjectGroup({
    required String projectId,
    required String sessionId,
    required bool closeOnSelect,
  }) async {
    await _switchProjectContext(projectId);
    if (!mounted) {
      return;
    }

    final chatProvider = context.read<ChatProvider>();
    ChatSession? target = chatProvider.sessions
        .where((item) => item.id == sessionId)
        .firstOrNull;
    for (var attempt = 0; target == null && attempt < 8; attempt += 1) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) {
        return;
      }
      target = chatProvider.sessions
          .where((item) => item.id == sessionId)
          .firstOrNull;
    }

    if (target == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversation is not available for this project yet'),
        ),
      );
      return;
    }

    await _handleSessionSwitch(target);
    _closeDrawerIfNeeded(closeOnSelect: closeOnSelect);
  }

  String _scopeIdForProject(Project project) {
    final path = project.path.trim();
    if (path.isEmpty || path == '/' || path == '-') {
      return project.id;
    }
    return path;
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

  /// Pure re-entry guard for session switches.
  /// No UI overlay — ChatState.loading in the provider already shows
  /// appropriate visual feedback in the content area.
  Future<void> _handleSessionSwitch(ChatSession session) async {
    if (_isSessionSwitchInFlight) {
      return;
    }
    _isSessionSwitchInFlight = true;
    try {
      await context.read<ChatProvider>().selectSession(session);
    } finally {
      _isSessionSwitchInFlight = false;
    }
  }
}
