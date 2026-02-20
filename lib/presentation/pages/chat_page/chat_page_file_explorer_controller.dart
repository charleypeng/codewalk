part of '../chat_page.dart';

extension _ChatPageFileExplorerController on _ChatPageState {
  Widget _buildDesktopFilePane(
    ChatProvider chatProvider, {
    VoidCallback? onCollapseRequested,
  }) {
    return Consumer2<ProjectProvider, AppProvider>(
      builder: (context, projectProvider, appProvider, child) {
        final fileState = _resolveFileContextState(
          projectProvider: projectProvider,
          appProvider: appProvider,
        );
        _reconcileFileContextWithSessionDiff(
          contextKey: projectProvider.contextKey,
          fileState: fileState,
          chatProvider: chatProvider,
          projectProvider: projectProvider,
        );
        return SafeArea(
          child: _buildFileExplorerPanel(
            fileState: fileState,
            projectProvider: projectProvider,
            isMobileLayout: false,
            onCollapseRequested: onCollapseRequested,
          ),
        );
      },
    );
  }

  _FileExplorerContextState _resolveFileContextState({
    required ProjectProvider projectProvider,
    required AppProvider appProvider,
  }) {
    final contextKey = projectProvider.contextKey;
    final rootDirectory = _resolveFileRootDirectory(
      projectProvider: projectProvider,
      appProvider: appProvider,
    );
    final state = _fileContextStates.putIfAbsent(
      contextKey,
      () => _FileExplorerContextState(rootDirectory: rootDirectory),
    );
    if (state.rootDirectory != rootDirectory) {
      state.resetForRoot(rootDirectory);
    }
    _ensureFileRootLoaded(state: state, projectProvider: projectProvider);
    return state;
  }

  Future<void> _loadDirectoryNodes({
    required _FileExplorerContextState state,
    required ProjectProvider projectProvider,
    required String cacheKey,
    required String requestPath,
    bool force = false,
    bool showLoader = true,
  }) async {
    if (state.loadingDirectories.contains(cacheKey)) {
      return;
    }
    if (!force && state.directoryChildren.containsKey(cacheKey)) {
      return;
    }

    if (mounted) {
      _setState(() {
        state.loadingDirectories.add(cacheKey);
      });
    }

    final listed = await _listFilesWithFallback(
      projectProvider: projectProvider,
      requestPath: requestPath,
    );
    if (!mounted) {
      return;
    }

    _setState(() {
      state.loadingDirectories.remove(cacheKey);
      if (listed == null) {
        if (cacheKey == _ChatPageState._rootTreeCacheKey) {
          state.treeError = projectProvider.error ?? 'Failed to load files';
        }
        return;
      }
      state.directoryChildren[cacheKey] = listed;
      if (cacheKey == _ChatPageState._rootTreeCacheKey) {
        state.treeError = null;
      }
      if (showLoader) {
        state.lastLoadedAt = DateTime.now();
      }
    });
  }

  Future<void> _openQuickFileDialogFromCurrentContext() async {
    if (!mounted) {
      return;
    }
    final projectProvider = context.read<ProjectProvider>();
    final appProvider = context.read<AppProvider>();
    final fileState = _resolveFileContextState(
      projectProvider: projectProvider,
      appProvider: appProvider,
    );
    await _openQuickFileDialog(
      fileState: fileState,
      projectProvider: projectProvider,
      openInDialogAfterSelect: true,
      dialogFullscreen:
          context.windowSizeClass.isCompact,
    );
  }

  Future<void> _openQuickFileDialog({
    required _FileExplorerContextState fileState,
    required ProjectProvider projectProvider,
    VoidCallback? onFileOpened,
    required bool openInDialogAfterSelect,
    required bool dialogFullscreen,
  }) async {
    final queryController = TextEditingController();
    var loading = false;
    var errorMessage = '';
    var resultNodes = <FileNode>[];
    var searchRequestId = 0;
    var dialogActive = true;

    resultNodes = fileState.tabSelection.openPaths
        .map(
          (path) => FileNode(
            path: path,
            name: _fileBasename(path),
            type: FileNodeType.file,
          ),
        )
        .toList(growable: false);

    Future<void> runSearch(StateSetter setModalState, String query) async {
      final normalized = query.trim();
      final requestId = ++searchRequestId;

      if (normalized.isEmpty) {
        final recent = fileState.tabSelection.openPaths
            .map(
              (path) => FileNode(
                path: path,
                name: _fileBasename(path),
                type: FileNodeType.file,
              ),
            )
            .toList(growable: false);
        if (!dialogActive) {
          return;
        }
        setModalState(() {
          loading = false;
          errorMessage = '';
          resultNodes = recent;
        });
        return;
      }

      if (!dialogActive) {
        return;
      }
      setModalState(() {
        loading = true;
        errorMessage = '';
      });

      final found = await projectProvider.findFiles(
        query: normalized,
        limit: 120,
      );
      if (!mounted || requestId != searchRequestId || !dialogActive) {
        return;
      }
      if (found == null) {
        setModalState(() {
          loading = false;
          resultNodes = <FileNode>[];
          errorMessage = projectProvider.error ?? 'Failed to search files';
        });
        return;
      }

      final byPath = <String, FileNode>{
        for (final node in found)
          if (node.path.trim().isNotEmpty) _normalizeFilePath(node.path): node,
      };
      final rankedPaths = rankQuickOpenPaths(
        byPath.keys,
        normalized,
        limit: 40,
      );
      setModalState(() {
        loading = false;
        errorMessage = '';
        resultNodes = rankedPaths
            .map((path) {
              final node = byPath[path];
              if (node != null) {
                return node;
              }
              return FileNode(
                path: path,
                name: _fileBasename(path),
                type: FileNodeType.file,
              );
            })
            .where((node) => !node.isDirectory)
            .toList(growable: false);
      });
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            return AlertDialog(
              title: const Text('Quick Open File'),
              content: SizedBox(
                width: 520,
                height: 420,
                child: Column(
                  children: [
                    TextField(
                      key: const ValueKey<String>('quick_open_input'),
                      controller: queryController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search files by name or path',
                        prefixIcon: Icon(Symbols.search),
                      ),
                      onChanged: (value) {
                        unawaited(runSearch(setModalState, value));
                      },
                      onSubmitted: (value) async {
                        if (resultNodes.isEmpty) {
                          return;
                        }
                        final selected = resultNodes.first;
                        dialogActive = false;
                        Navigator.of(dialogContext).pop();
                        await _openFileInTab(
                          fileState: fileState,
                          projectProvider: projectProvider,
                          path: selected.path,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : errorMessage.isNotEmpty
                          ? Center(
                              child: Text(
                                errorMessage,
                                textAlign: TextAlign.center,
                              ),
                            )
                          : resultNodes.isEmpty
                          ? Center(
                              child: Text(
                                queryController.text.trim().isEmpty
                                    ? 'No open files yet. Type to search.'
                                    : 'No files found',
                              ),
                            )
                          : ListView.builder(
                              itemCount: resultNodes.length,
                              itemBuilder: (context, index) {
                                final node = resultNodes[index];
                                final normalizedPath = _normalizeFilePath(
                                  node.path,
                                );
                                return ListTile(
                                  key: ValueKey<String>(
                                    'quick_open_result_$normalizedPath',
                                  ),
                                  dense: _useDenseListTiles(context),
                                  leading: Icon(
                                    _fileIconForNode(node),
                                    size: 18,
                                  ),
                                  title: Text(
                                    node.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    normalizedPath,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () async {
                                    dialogActive = false;
                                    Navigator.of(dialogContext).pop();
                                    if (openInDialogAfterSelect) {
                                      await _openFileAndFocusDialog(
                                        fileState: fileState,
                                        projectProvider: projectProvider,
                                        path: normalizedPath,
                                        dialogFullscreen: dialogFullscreen,
                                        onUpdated: onFileOpened,
                                      );
                                    } else {
                                      await _openFileInTab(
                                        fileState: fileState,
                                        projectProvider: projectProvider,
                                        path: normalizedPath,
                                        onUpdated: onFileOpened,
                                      );
                                      onFileOpened?.call();
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    dialogActive = false;
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
    dialogActive = false;
  }

  Future<void> _openFileInTab({
    required _FileExplorerContextState fileState,
    required ProjectProvider projectProvider,
    required String path,
    VoidCallback? onUpdated,
  }) async {
    final normalizedPath = _normalizeFilePath(path);
    if (normalizedPath.isEmpty) {
      return;
    }
    if (mounted) {
      _setState(() {
        fileState.tabSelection = openFileTab(
          fileState.tabSelection,
          normalizedPath,
        );
      });
      onUpdated?.call();
    }

    final cached = fileState.tabsByPath[normalizedPath];
    if (cached != null &&
        cached.status != _FileTabLoadStatus.error &&
        cached.status != _FileTabLoadStatus.loading) {
      onUpdated?.call();
      return;
    }

    await _reloadFileTab(
      fileState: fileState,
      projectProvider: projectProvider,
      path: normalizedPath,
      onUpdated: onUpdated,
    );
  }

  Widget _buildFileExplorerPanel({
    required _FileExplorerContextState fileState,
    required ProjectProvider projectProvider,
    required bool isMobileLayout,
    VoidCallback? onStateChanged,
    VoidCallback? onCollapseRequested,
  }) {
    final rootNodes =
        fileState.directoryChildren[_ChatPageState._rootTreeCacheKey];
    final rootLoading = fileState.loadingDirectories.contains(
      _ChatPageState._rootTreeCacheKey,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Files',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (fileState.tabSelection.hasOpenTabs)
                    Flexible(
                      child: TextButton(
                        key: const ValueKey<String>(
                          'file_tree_open_files_button',
                        ),
                        style: TextButton.styleFrom(
                          visualDensity: Theme.of(context).visualDensity,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          unawaited(
                            _openOpenFilesDialog(
                              fileState: fileState,
                              projectProvider: projectProvider,
                              fullscreen: isMobileLayout,
                            ),
                          );
                        },
                        child: Text(
                          '${fileState.tabSelection.openPaths.length} open file${fileState.tabSelection.openPaths.length == 1 ? '' : 's'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  IconButton(
                    key: const ValueKey<String>('file_tree_quick_open_button'),
                    tooltip: 'Quick Open',
                    visualDensity: Theme.of(context).visualDensity,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    onPressed: () {
                      unawaited(
                        _openQuickFileDialog(
                          fileState: fileState,
                          projectProvider: projectProvider,
                          onFileOpened: onStateChanged,
                          openInDialogAfterSelect: true,
                          dialogFullscreen: isMobileLayout,
                        ),
                      );
                    },
                    icon: const Icon(Symbols.search),
                  ),
                  IconButton(
                    key: const ValueKey<String>('file_tree_refresh_button'),
                    tooltip: 'Refresh files',
                    visualDensity: Theme.of(context).visualDensity,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    onPressed: () {
                      unawaited(
                        _loadRootDirectoryNodes(
                          state: fileState,
                          projectProvider: projectProvider,
                          force: true,
                        ),
                      );
                    },
                    icon: const Icon(Symbols.refresh_rounded),
                  ),
                  if (onCollapseRequested != null)
                    IconButton(
                      key: const ValueKey<String>('hide_files_sidebar_button'),
                      tooltip: 'Hide Files sidebar',
                      visualDensity: Theme.of(context).visualDensity,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: onCollapseRequested,
                      icon: const Icon(Symbols.left_panel_close_rounded),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                _directoryLabel(projectProvider.currentDirectory),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Builder(
                builder: (_) {
                  if (rootLoading && (rootNodes == null || rootNodes.isEmpty)) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (fileState.treeError != null &&
                      (rootNodes == null || rootNodes.isEmpty)) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              fileState.treeError!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () {
                                unawaited(
                                  _loadRootDirectoryNodes(
                                    state: fileState,
                                    projectProvider: projectProvider,
                                    force: true,
                                  ),
                                );
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (rootNodes == null || rootNodes.isEmpty) {
                    return const Center(child: Text('No files found'));
                  }
                  return ListView(
                    key: const ValueKey<String>('file_tree_list'),
                    children: _buildFileTreeChildren(
                      fileState: fileState,
                      projectProvider: projectProvider,
                      dialogFullscreen: isMobileLayout,
                      onStateChanged: onStateChanged,
                      parentCacheKey: _ChatPageState._rootTreeCacheKey,
                      depth: 0,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
