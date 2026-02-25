part of '../chat_page.dart';

extension _ChatPageSelectorFlow on _ChatPageState {
  Widget _buildProjectSelectorTitle({
    required bool isMobile,
    required bool isLargeDesktop,
  }) {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        final currentDirectoryFull = _directoryLabel(
          projectProvider.currentDirectory,
        );
        final currentDirectoryChip = isMobile
            ? _directoryBasename(currentDirectoryFull)
            : currentDirectoryFull;

        return Align(
          alignment: Alignment.centerLeft,
          child: Tooltip(
            message: 'Choose Directory',
            child: MenuAnchor(
              controller: _projectSelectorMenuController,
              menuChildren: [
                Builder(
                  builder: (context) {
                    var filterQuery = '';
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return SizedBox(
                          width: 620,
                          height: 620,
                          child: Consumer<ProjectProvider>(
                            builder: (context, provider, _) {
                              return _buildProjectSelectorSurface(
                                projectProvider: provider,
                                isSmallScreen: false,
                                filterQuery: filterQuery,
                                onFilterChanged: (value) {
                                  setState(() {
                                    filterQuery = value;
                                  });
                                },
                                onClose: () {
                                  if (_projectSelectorMenuController.isOpen) {
                                    _projectSelectorMenuController.close();
                                  }
                                },
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
              builder: (context, menuController, _) {
                return InkWell(
                  key: _projectSelectorButtonKey,
                  onTap: () {
                    if (isMobile) {
                      unawaited(_openProjectSelectorSheet());
                      return;
                    }
                    if (menuController.isOpen) {
                      menuController.close();
                    } else {
                      menuController.open();
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    key: const ValueKey<String>('project_selector_button'),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 2 : 4,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isMobile
                                  ? 100
                                  : (isLargeDesktop ? 400 : 300),
                            ),
                            child: Text(
                              currentDirectoryChip,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 1),
                        Icon(
                          menuController.isOpen
                              ? Symbols.arrow_drop_up
                              : Symbols.arrow_drop_down,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _openProjectSelectorSheet() async {
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        var filterQuery = '';
        return StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.9,
              child: Consumer<ProjectProvider>(
                builder: (context, projectProvider, _) {
                  return _buildProjectSelectorSurface(
                    projectProvider: projectProvider,
                    isSmallScreen: true,
                    filterQuery: filterQuery,
                    onFilterChanged: (value) {
                      setState(() {
                        filterQuery = value;
                      });
                    },
                    onClose: () {
                      if (Navigator.of(sheetContext).canPop()) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProjectSelectorSurface({
    required ProjectProvider projectProvider,
    required bool isSmallScreen,
    required String filterQuery,
    required ValueChanged<String> onFilterChanged,
    required VoidCallback onClose,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentProject = projectProvider.currentProject;
    final currentDirectoryFull = _directoryLabel(
      projectProvider.currentDirectory,
    );
    final normalizedFilter = filterQuery.trim().toLowerCase();

    bool matchesProject(Project project) {
      if (normalizedFilter.isEmpty) {
        return true;
      }
      final displayName = _projectDisplayLabel(project).toLowerCase();
      final path = _directoryLabel(project.path).toLowerCase();
      return displayName.contains(normalizedFilter) ||
          path.contains(normalizedFilter);
    }

    final openProjects = projectProvider.openProjects
        .where(matchesProject)
        .toList(growable: false);
    final closedProjects = projectProvider.closedProjects
        .where(matchesProject)
        .toList(growable: false);

    return Material(
      key: const ValueKey<String>('project_selector_dialog_content'),
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isSmallScreen ? 16 : 20,
              isSmallScreen ? 12 : 16,
              isSmallScreen ? 8 : 12,
              8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Project context',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Symbols.close),
                  tooltip: 'Close',
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(isSmallScreen ? 16 : 20, 0, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentProject == null
                      ? 'No active context'
                      : 'Current directory: $currentDirectoryFull',
                ),
                const SizedBox(height: 2),
                Text(
                  'Select a project below.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(isSmallScreen ? 16 : 20, 4, 20, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => unawaited(
                    _openCreateWorkspaceFromSelector(onClose: onClose),
                  ),
                  icon: const Icon(Symbols.add_box),
                  label: const Text('Open project folder...'),
                ),
                if (!FeatureFlags.refreshlessRealtime)
                  FilledButton.tonalIcon(
                    onPressed: () => unawaited(projectProvider.loadProjects()),
                    icon: const Icon(Symbols.refresh_rounded),
                    label: const Text('Refresh projects'),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(isSmallScreen ? 16 : 20, 0, 20, 8),
            child: TextField(
              key: const ValueKey<String>('project_selector_filter_input'),
              onChanged: onFilterChanged,
              decoration: InputDecoration(
                hintText: 'Filter projects',
                prefixIcon: const Icon(Symbols.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              primary: false,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
              children: [
                _buildSelectorSectionHeader(context, 'Open projects'),
                for (final project in openProjects)
                  _buildOpenProjectTile(
                    dialogContext: context,
                    project: project,
                    selected: project.id == currentProject?.id,
                    onSwitch: () => unawaited(
                      _switchProjectFromSelector(
                        projectId: project.id,
                        onClose: onClose,
                      ),
                    ),
                    onClose: () => unawaited(_closeProjectContext(project.id)),
                    closeEnabled:
                        projectProvider.openProjects.length > 1 ||
                        project.id != currentProject?.id,
                  ),
                if (closedProjects.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildSelectorSectionHeader(context, 'Closed projects'),
                  for (final project in closedProjects)
                    Builder(
                      builder: (_) {
                        final displayName = _projectDisplayLabel(project);
                        return ListTile(
                          dense: _useDenseListTiles(context),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          leading: const Icon(Symbols.folder_off, size: 20),
                          title: Text(
                            displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            _directoryLabel(project.path),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Wrap(
                            spacing: 2,
                            children: [
                              IconButton(
                                icon: const Icon(Symbols.undo_rounded),
                                tooltip: 'Reopen $displayName',
                                onPressed: () => unawaited(
                                  _reopenProjectContext(project.id),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Symbols.delete_outline_rounded,
                                ),
                                tooltip: 'Archive closed project $displayName',
                                onPressed: () => unawaited(
                                  _archiveClosedProjectContext(project.id),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
                if (openProjects.isEmpty && closedProjects.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'No projects match your filter.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
