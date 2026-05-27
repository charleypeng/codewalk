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
            if (closeOnSelect && isMobileLayout)
              _buildHamburgerReasonNotice(
                chatProvider: chatProvider,
                closeOnSelect: closeOnSelect,
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
                              context.l10n.chatConversations,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          _buildTourTarget(
                            showcaseKey: _projectContextTourKey,
                            targetKey: _projectContextTourTargetKey,
                            title: postOnboardingSidebarTourCopy(
                              isMobile: false,
                              showConversationPane: true,
                            ).title,
                            description: postOnboardingSidebarTourCopy(
                              isMobile: false,
                              showConversationPane: true,
                            ).description,
                            tooltipPosition: TooltipPosition.right,
                            child: IconButton(
                              key: const ValueKey<String>(
                                'conversations_project_context_button',
                              ),
                              icon: const Icon(Symbols.folder_open),
                              onPressed: () =>
                                  unawaited(_openProjectSelectorDialog()),
                              tooltip: context.l10n.chatProjectContext,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Symbols.add),
                            onPressed: _createNewSession,
                            tooltip: context.l10n.chatNewChat,
                          ),
                          if (!FeatureFlags.refreshlessRealtime)
                            IconButton(
                              icon: const Icon(Symbols.refresh),
                              onPressed: _refreshData,
                              tooltip: context.l10n.chatRefresh,
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
                              tooltip:
                                  context.l10n.chatHideConversationsSidebar,
                            ),
                        ],
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          PopupMenuButton<SessionListFilter>(
                            tooltip: context.l10n.chatFilterSessions,
                            onSelected: chatProvider.setSessionListFilter,
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: SessionListFilter.active,
                                child: Text(context.l10n.chatFilterActive),
                              ),
                              PopupMenuItem(
                                value: SessionListFilter.archived,
                                child: Text(context.l10n.chatFilterArchived),
                              ),
                              PopupMenuItem(
                                value: SessionListFilter.all,
                                child: Text(context.l10n.chatFilterAll),
                              ),
                            ],
                            child: _headerChip(
                              context,
                              icon: Symbols.filter_list,
                              label: switch (chatProvider.sessionListFilter) {
                                SessionListFilter.active =>
                                  context.l10n.chatFilterActive,
                                SessionListFilter.archived =>
                                  context.l10n.chatFilterArchived,
                                SessionListFilter.all =>
                                  context.l10n.chatFilterAll,
                              },
                            ),
                          ),
                          PopupMenuButton<SessionListSort>(
                            tooltip: context.l10n.chatSortSessions,
                            onSelected: chatProvider.setSessionListSort,
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: SessionListSort.recent,
                                child: Text(context.l10n.chatSortMostRecent),
                              ),
                              PopupMenuItem(
                                value: SessionListSort.oldest,
                                child: Text(context.l10n.chatSortOldest),
                              ),
                              PopupMenuItem(
                                value: SessionListSort.title,
                                child: Text(context.l10n.chatSortTitle),
                              ),
                            ],
                            child: _headerChip(
                              context,
                              icon: Symbols.sort,
                              label: switch (chatProvider.sessionListSort) {
                                SessionListSort.recent =>
                                  context.l10n.chatSortRecent,
                                SessionListSort.oldest =>
                                  context.l10n.chatSortOldest,
                                SessionListSort.title =>
                                  context.l10n.chatSortTitle,
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
                          hintText: context.l10n.chatSearchConversations,
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
              child: _buildGroupedConversationsList(
                chatProvider: chatProvider,
                projectProvider: projectProvider,
                closeOnSelect: closeOnSelect,
                isMobileLayout: isMobileLayout,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHamburgerReasonNotice({
    required ChatProvider chatProvider,
    required bool closeOnSelect,
  }) {
    final appProvider = context.watch<AppProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final badgeReason = _resolveHamburgerBadgeReason(
      chatProvider: chatProvider,
      appProvider: appProvider,
      settingsProvider: settingsProvider,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: !badgeReason.hasBadge
          ? const SizedBox.shrink()
          : Padding(
              key: ValueKey<_HamburgerBadgeReasonKind>(badgeReason.kind),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Card(
                child: InkWell(
                  key: const ValueKey<String>('drawer_hamburger_reason_notice'),
                  onTap: _hamburgerReasonHasAction(badgeReason)
                      ? () => unawaited(
                          _handleHamburgerReasonTap(
                            badgeReason: badgeReason,
                            closeOnSelect: closeOnSelect,
                          ),
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _hamburgerReasonColor(
                              context,
                              badgeReason.kind,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _hamburgerReasonMessage(badgeReason),
                            key: const ValueKey<String>(
                              'drawer_hamburger_reason_notice_text',
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        if (_hamburgerReasonHasAction(badgeReason)) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Symbols.arrow_forward,
                            size: 18,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  String _hamburgerReasonMessage(_HamburgerBadgeReasonState badgeReason) {
    return switch (badgeReason.kind) {
      _HamburgerBadgeReasonKind.serverAlert =>
        'Server connection needs attention.',
      _HamburgerBadgeReasonKind.sessionError =>
        '"${badgeReason.sessionTitle ?? 'Conversation'}" has an error.',
      _HamburgerBadgeReasonKind.sessionPendingInteraction =>
        '"${badgeReason.sessionTitle ?? 'Conversation'}" needs your input.',
      _HamburgerBadgeReasonKind.sessionUnreadCompletion =>
        '"${badgeReason.sessionTitle ?? 'Conversation'}" has a new reply.',
      _HamburgerBadgeReasonKind.syncLoading => 'Syncing conversations...',
      _HamburgerBadgeReasonKind.dataSaver => 'Cellular data saver is active.',
      _HamburgerBadgeReasonKind.none => '',
    };
  }

  bool _hamburgerReasonHasAction(_HamburgerBadgeReasonState badgeReason) {
    return switch (badgeReason.kind) {
      _HamburgerBadgeReasonKind.serverAlert ||
      _HamburgerBadgeReasonKind.sessionError ||
      _HamburgerBadgeReasonKind.sessionPendingInteraction ||
      _HamburgerBadgeReasonKind.sessionUnreadCompletion ||
      _HamburgerBadgeReasonKind.dataSaver => true,
      _HamburgerBadgeReasonKind.syncLoading ||
      _HamburgerBadgeReasonKind.none => false,
    };
  }

  Color _hamburgerReasonColor(
    BuildContext context,
    _HamburgerBadgeReasonKind kind,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (kind) {
      _HamburgerBadgeReasonKind.serverAlert => _serverStatusColor(
        context: context,
        chatProvider: context.read<ChatProvider>(),
        appProvider: context.read<AppProvider>(),
      ),
      _HamburgerBadgeReasonKind.sessionError => colorScheme.error,
      _HamburgerBadgeReasonKind.sessionPendingInteraction =>
        colorScheme.tertiary,
      _HamburgerBadgeReasonKind.sessionUnreadCompletion ||
      _HamburgerBadgeReasonKind.syncLoading => colorScheme.primary,
      _HamburgerBadgeReasonKind.dataSaver => colorScheme.tertiary,
      _HamburgerBadgeReasonKind.none => colorScheme.outline,
    };
  }

  Future<void> _handleHamburgerReasonTap({
    required _HamburgerBadgeReasonState badgeReason,
    required bool closeOnSelect,
  }) async {
    switch (badgeReason.kind) {
      case _HamburgerBadgeReasonKind.serverAlert:
        await _openSettingsPage(
          closeOnSelect: closeOnSelect,
          initialSectionId: 'servers',
        );
        return;
      case _HamburgerBadgeReasonKind.dataSaver:
        await _openSettingsPage(
          closeOnSelect: closeOnSelect,
          initialSectionId: 'behavior',
        );
        return;
      case _HamburgerBadgeReasonKind.sessionError:
      case _HamburgerBadgeReasonKind.sessionPendingInteraction:
      case _HamburgerBadgeReasonKind.sessionUnreadCompletion:
        final sessionId = badgeReason.sessionId?.trim();
        if (sessionId == null || sessionId.isEmpty) {
          return;
        }
        final target = context
            .read<ChatProvider>()
            .visibleSessions
            .where((item) => item.id == sessionId)
            .firstOrNull;
        if (target == null) {
          return;
        }
        await _handleSessionSwitch(target);
        _closeDrawerIfNeeded(closeOnSelect: closeOnSelect);
        return;
      case _HamburgerBadgeReasonKind.syncLoading:
      case _HamburgerBadgeReasonKind.none:
        return;
    }
  }

  Widget _buildGroupedConversationsList({
    required ChatProvider chatProvider,
    required ProjectProvider projectProvider,
    required bool closeOnSelect,
    required bool isMobileLayout,
  }) {
    final settingsProvider = context.watch<SettingsProvider>();
    final openProjects = projectProvider.openProjects;
    final currentProjectId = projectProvider.currentProject?.id;
    final openProjectIds = openProjects.map((project) => project.id).toSet();
    _projectGroupExpandedById.removeWhere(
      (projectId, _) => !openProjectIds.contains(projectId),
    );
    final recentEntries = settingsProvider.showRecentSessions
        ? _recentRootSessionEntries(
            chatProvider: chatProvider,
            openProjects: openProjects,
          )
        : const <MapEntry<Project, ChatSession>>[];

    final children = <Widget>[];
    if (recentEntries.isNotEmpty) {
      children.add(
        _buildRecentSessionsCard(
          chatProvider: chatProvider,
          entries: recentEntries,
          closeOnSelect: closeOnSelect,
          isMobileLayout: isMobileLayout,
        ),
      );
      children.add(SizedBox(height: isMobileLayout ? 6 : 4));
    }

    for (var index = 0; index < openProjects.length; index += 1) {
      final project = openProjects[index];
      final selected = project.id == currentProjectId;
      children.add(
        _buildProjectGroupTile(
          chatProvider: chatProvider,
          project: project,
          selected: selected,
          closeOnSelect: closeOnSelect,
          isMobileLayout: isMobileLayout,
        ),
      );
      if (index != openProjects.length - 1) {
        children.add(SizedBox(height: isMobileLayout ? 6 : 4));
      }
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(8, 0, 8, isMobileLayout ? 8 : 6),
      children: children,
    );
  }

  List<MapEntry<Project, ChatSession>> _recentRootSessionEntries({
    required ChatProvider chatProvider,
    required List<Project> openProjects,
  }) {
    final entries = <MapEntry<Project, ChatSession>>[];
    final seenSessionIds = <String>{};
    for (final project in openProjects) {
      final scopeId = _scopeIdForProject(project);
      for (final session in chatProvider.recentRootSessionsForScopeId(
        scopeId,
      )) {
        if (!seenSessionIds.add(session.id)) {
          continue;
        }
        entries.add(MapEntry<Project, ChatSession>(project, session));
      }
    }
    entries.sort((a, b) => b.value.time.compareTo(a.value.time));
    return entries.take(5).toList(growable: false);
  }

  Widget _buildRecentSessionsCard({
    required ChatProvider chatProvider,
    required List<MapEntry<Project, ChatSession>> entries,
    required bool closeOnSelect,
    required bool isMobileLayout,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, 8, 8, isMobileLayout ? 8 : 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Text(
                context.l10n.chatRecentSessions,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _buildRecentSessionTile(
                  chatProvider: chatProvider,
                  project: entry.key,
                  session: entry.value,
                  closeOnSelect: closeOnSelect,
                  isMobileLayout: isMobileLayout,
                  colorScheme: colorScheme,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSessionTile({
    required ChatProvider chatProvider,
    required Project project,
    required ChatSession session,
    required bool closeOnSelect,
    required bool isMobileLayout,
    required ColorScheme colorScheme,
  }) {
    final attention = chatProvider.sessionAttentionForScope(
      session.id,
      scopeId: _scopeIdForProject(project),
    );
    final isCurrentSession = chatProvider.currentSession?.id == session.id;
    final highlighted = attention.hasRecentUnreadCompletion;
    final isBusy = attention.isActive;
    final showBusySweep = isBusy && !isCurrentSession;
    final tileColor = isCurrentSession
        ? colorScheme.secondaryContainer
        : (highlighted
              ? Color.alphaBlend(
                  colorScheme.primary.withValues(alpha: 0.08),
                  colorScheme.surfaceContainerLow,
                )
              : colorScheme.surfaceContainerLow);
    final titleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: (highlighted || isCurrentSession)
          ? FontWeight.w700
          : FontWeight.w500,
      color: isCurrentSession
          ? colorScheme.onSecondaryContainer
          : (highlighted ? colorScheme.primary : null),
    );
    return Material(
      color: tileColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: ValueKey<String>('recent_session_tile_${session.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => unawaited(
          _openSessionFromProjectGroup(
            projectId: project.id,
            sessionId: session.id,
            closeOnSelect: closeOnSelect,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(10, isMobileLayout ? 8 : 6, 10, 6),
          child: Row(
            children: [
              Expanded(
                child: KeyedSubtree(
                  key: ValueKey<String>('recent_session_title_${session.id}'),
                  child: showBusySweep
                      ? _ComposerStatusLanternText(
                          key: ValueKey<String>(
                            'recent_session_busy_title_${session.id}',
                          ),
                          text: _sessionDisplayTitle(session),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        )
                      : Text(
                          _sessionDisplayTitle(session),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _projectDisplayLabel(project),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isProjectGroupExpanded({
    required String projectId,
    required bool selected,
  }) {
    return _projectGroupExpandedById[projectId] ?? selected;
  }

  void _toggleProjectGroupExpanded({
    required String projectId,
    required bool selected,
  }) {
    final current = _isProjectGroupExpanded(
      projectId: projectId,
      selected: selected,
    );
    _setState(() {
      _projectGroupExpandedById[projectId] = !current;
    });
  }

  Widget _buildProjectGroupTile({
    required ChatProvider chatProvider,
    required Project project,
    required bool selected,
    required bool closeOnSelect,
    required bool isMobileLayout,
  }) {
    final scopeId = _scopeIdForProject(project);
    final sessions = chatProvider.visibleSessionsForScopeId(scopeId);
    final preview = sessions.take(6).toList(growable: false);
    final hasSnapshot = chatProvider.hasSnapshotForScopeId(scopeId);
    final expanded = _isProjectGroupExpanded(
      projectId: project.id,
      selected: selected,
    );
    final displayName = _projectDisplayLabel(project);
    final subtitle = _directoryLabel(project.path);

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            key: ValueKey<String>('project_group_tile_${project.id}'),
            dense: _useDenseListTiles(context),
            visualDensity: isMobileLayout ? VisualDensity.compact : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobileLayout ? 6 : 8,
            ),
            leading: const Icon(Symbols.folder_open, size: 20),
            title: Text(displayName, overflow: TextOverflow.ellipsis),
            subtitle: subtitle == displayName
                ? null
                : Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
            selected: selected,
            onTap: () {
              if (selected) {
                _toggleProjectGroupExpanded(
                  projectId: project.id,
                  selected: selected,
                );
                return;
              }
              unawaited(
                _switchProjectFromGroup(
                  projectId: project.id,
                  closeOnSelect: closeOnSelect,
                ),
              );
            },
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
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
                  key: ValueKey<String>('project_group_expand_${project.id}'),
                  icon: Icon(
                    expanded ? Symbols.expand_less : Symbols.expand_more,
                  ),
                  tooltip: expanded ? 'Collapse group' : 'Expand group',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  onPressed: () => _toggleProjectGroupExpanded(
                    projectId: project.id,
                    selected: selected,
                  ),
                ),
              ],
            ),
          ),
          if (expanded) ...[
            if (selected)
              Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Column(
                  children: [
                    ChatSessionList(
                      sessions: sessions,
                      currentSession: chatProvider.currentSession,
                      pinnedSessionIds: chatProvider.pinnedSessionIds,
                      isSessionActive: chatProvider.isSessionActivelyResponding,
                      sessionAttentionFor: chatProvider.sessionAttentionFor,
                      isMobileLayout: isMobileLayout,
                      onSessionSelected: (session) async {
                        if (closeOnSelect) {
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
                      onSessionPinToggled: (session) {
                        return chatProvider.toggleSessionPinned(session);
                      },
                      onSessionForked: (session) async {
                        final created = await chatProvider.forkSession(session);
                        if (!context.mounted) {
                          return;
                        }
                        if (created == null) {
                          _showChatPageMessageSnackBar(
                            'Failed to fork conversation',
                            hideCurrent: false,
                          );
                          return;
                        }
                        _showChatPageMessageSnackBar(
                          'Conversation forked',
                          hideCurrent: false,
                        );
                        _closeDrawerIfNeeded(closeOnSelect: closeOnSelect);
                      },
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        4,
                        0,
                        4,
                        isMobileLayout ? 4 : 8,
                      ),
                      verticalTilePadding: isMobileLayout ? 3 : 1,
                    ),
                    if (chatProvider.canLoadMoreSessions)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: OutlinedButton.icon(
                          onPressed: chatProvider.loadMoreSessions,
                          icon: const Icon(Symbols.expand_more),
                          label: Text(context.l10n.chatLoadMore),
                        ),
                      ),
                  ],
                ),
              )
            else if (preview.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(isMobileLayout ? 12 : 20, 0, 8, 8),
                child: Column(
                  children: [
                    for (final session in preview)
                      ListTile(
                        key: ValueKey<String>(
                          'project_group_session_preview_${project.id}_${session.id}',
                        ),
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                        ),
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
            else
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobileLayout ? 12 : 20,
                  0,
                  8,
                  12,
                ),
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
          ],
        ],
      ),
    );
  }

  Future<void> _switchProjectFromGroup({
    required String projectId,
    required bool closeOnSelect,
  }) async {
    await _switchProjectContext(projectId);
    if (!mounted) {
      return;
    }
    final openProjects = context.read<ProjectProvider>().openProjects;
    final openProjectIds = openProjects.map((item) => item.id).toSet();
    _setState(() {
      _projectGroupExpandedById.removeWhere(
        (id, _) => !openProjectIds.contains(id),
      );
      for (final id in openProjectIds) {
        _projectGroupExpandedById[id] = id == projectId;
      }
    });
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
      _showChatPageMessageSnackBar(
        context.l10n.sessionNotAvailable,
        hideCurrent: false,
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
                tooltip: context.l10n.chatHideUtilitySidebar,
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
                    context.l10n.sessionKeyboardShortcuts,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final hint in _keyboardShortcutHints(settingsProvider))
                    _buildShortcutHint(hint.shortcut, hint.description),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _createNewSession,
            icon: const Icon(Symbols.add_comment),
            label: Text(context.l10n.chatNewChat),
          ),
          if (!FeatureFlags.refreshlessRealtime) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Symbols.refresh),
              label: Text(context.l10n.chatRefresh),
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
                                  chatProvider.loadSessionInsights(
                                    session.id,
                                    userInitiated: true,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Symbols.sync, size: 18),
                            tooltip: context.l10n.chatRefreshSessionDetails,
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
                    if (settingsProvider.showReviewChanges) ...[
                      if (chatProvider.currentSessionDiff.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SessionDiffViewer(
                          diffs: chatProvider.currentSessionDiff,
                          compact: false,
                          onFileTap: (path, line) =>
                              unawaited(_onFilePathTap(path, line, null)),
                        ),
                      ] else
                        Text(
                          'Diff files: 0',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
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

  Future<void> _handleSessionSwitch(ChatSession session) async {
    if (di.sl.isRegistered<ReadAloudService>()) {
      unawaited(di.sl<ReadAloudService>().stop());
    }
    await context.read<ChatProvider>().selectSession(session);
  }
}
