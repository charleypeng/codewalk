part of '../chat_page.dart';

extension _ChatPageFileRuntime on _ChatPageState {
  String _normalizeFilePath(String value) {
    var normalized = value.trim().replaceAll('\\', '/');
    if (normalized.length > 1) {
      normalized = normalized.replaceAll(RegExp(r'/+$'), '');
    }
    return normalized;
  }

  String _fileBasename(String path) {
    final normalized = _normalizeFilePath(path);
    if (normalized.isEmpty || normalized == '/') {
      return normalized.isEmpty ? 'file' : '/';
    }
    final separator = normalized.lastIndexOf('/');
    if (separator < 0 || separator == normalized.length - 1) {
      return normalized;
    }
    return normalized.substring(separator + 1);
  }

  String _resolveFileRootDirectory({
    required ProjectProvider projectProvider,
    required AppProvider appProvider,
  }) {
    final directory = projectProvider.currentDirectory;
    if (directory != null && directory.trim().isNotEmpty) {
      return _normalizeFilePath(directory);
    }
    final appPath = appProvider.appInfo?.path.data;
    if (appPath != null && appPath.trim().isNotEmpty) {
      return _normalizeFilePath(appPath);
    }
    return '/';
  }

  void _ensureFileRootLoaded({
    required _FileExplorerContextState state,
    required ProjectProvider projectProvider,
  }) {
    if (state.rootLoadScheduled) {
      return;
    }
    if (state.loadingDirectories.contains(_ChatPageState._rootTreeCacheKey)) {
      return;
    }
    if (state.directoryChildren.containsKey(_ChatPageState._rootTreeCacheKey)) {
      return;
    }
    state.rootLoadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      state.rootLoadScheduled = false;
      if (!mounted) {
        return;
      }
      if (state.loadingDirectories.contains(_ChatPageState._rootTreeCacheKey)) {
        return;
      }
      if (state.directoryChildren.containsKey(
        _ChatPageState._rootTreeCacheKey,
      )) {
        return;
      }
      unawaited(
        _loadRootDirectoryNodes(state: state, projectProvider: projectProvider),
      );
    });
  }

  void _reconcileFileContextWithSessionDiff({
    required String contextKey,
    required _FileExplorerContextState fileState,
    required ChatProvider chatProvider,
    required ProjectProvider projectProvider,
  }) {
    final diffFiles =
        chatProvider.currentSessionDiff
            .map((item) => item.file.trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
    final signature = diffFiles.join('|');
    if (_fileDiffSignaturesByContext[contextKey] == signature) {
      return;
    }
    _fileDiffSignaturesByContext[contextKey] = signature;
    if (signature.isEmpty) {
      return;
    }

    final staleDirectoryKeys = fileState.directoryChildren.keys
        .where((key) {
          if (key == _ChatPageState._rootTreeCacheKey) {
            return false;
          }
          final normalizedDirectory = _normalizeFilePath(key);
          return diffFiles.any((diffFile) {
            final absoluteDiff = _resolveDiffAbsolutePath(
              diffFile: diffFile,
              rootDirectory: projectProvider.currentDirectory,
            );
            if (absoluteDiff == null) {
              return false;
            }
            return absoluteDiff == normalizedDirectory ||
                absoluteDiff.startsWith('$normalizedDirectory/');
          });
        })
        .toList(growable: false);
    for (final key in staleDirectoryKeys) {
      fileState.directoryChildren.remove(key);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      for (final tabPath in fileState.tabSelection.openPaths) {
        if (_diffMatchesPath(
          tabPath: tabPath,
          diffFiles: diffFiles,
          rootDirectory: projectProvider.currentDirectory,
        )) {
          unawaited(
            _reloadFileTab(
              fileState: fileState,
              projectProvider: projectProvider,
              path: tabPath,
              silent: true,
            ),
          );
        }
      }

      unawaited(
        _loadRootDirectoryNodes(
          state: fileState,
          projectProvider: projectProvider,
          force: true,
          showLoader: false,
        ),
      );
    });
  }

  bool _diffMatchesPath({
    required String tabPath,
    required List<String> diffFiles,
    required String? rootDirectory,
  }) {
    final normalizedTabPath = _normalizeFilePath(tabPath);
    for (final diffFile in diffFiles) {
      final normalizedDiff = _normalizeFilePath(diffFile);
      if (normalizedDiff.isEmpty) {
        continue;
      }
      if (normalizedTabPath == normalizedDiff ||
          normalizedTabPath.endsWith('/$normalizedDiff')) {
        return true;
      }
      final absoluteDiff = _resolveDiffAbsolutePath(
        diffFile: diffFile,
        rootDirectory: rootDirectory,
      );
      if (absoluteDiff != null && normalizedTabPath == absoluteDiff) {
        return true;
      }
    }
    return false;
  }

  String? _resolveDiffAbsolutePath({
    required String diffFile,
    required String? rootDirectory,
  }) {
    final normalizedDiff = _normalizeFilePath(diffFile);
    if (normalizedDiff.isEmpty) {
      return null;
    }
    if (normalizedDiff.startsWith('/')) {
      return normalizedDiff;
    }
    final normalizedRoot = _normalizeFilePath(rootDirectory ?? '');
    if (normalizedRoot.isEmpty || normalizedRoot == '/') {
      return _normalizeFilePath('/$normalizedDiff');
    }
    return _normalizeFilePath('$normalizedRoot/$normalizedDiff');
  }

  Future<void> _loadRootDirectoryNodes({
    required _FileExplorerContextState state,
    required ProjectProvider projectProvider,
    bool force = false,
    bool showLoader = true,
  }) async {
    final contextDirectory = projectProvider.currentDirectory?.trim();
    final requestPath =
        (contextDirectory != null && contextDirectory.isNotEmpty)
        ? '.'
        : state.rootDirectory;
    await _loadDirectoryNodes(
      state: state,
      projectProvider: projectProvider,
      cacheKey: _ChatPageState._rootTreeCacheKey,
      requestPath: requestPath,
      force: force,
      showLoader: showLoader,
    );
  }

  Future<List<FileNode>?> _listFilesWithFallback({
    required ProjectProvider projectProvider,
    required String requestPath,
  }) async {
    final candidates = _listPathCandidates(
      requestPath: requestPath,
      contextDirectory: projectProvider.currentDirectory,
    );
    List<FileNode>? emptyFallback;
    for (final candidate in candidates) {
      final listed = await projectProvider.listFiles(path: candidate);
      if (listed != null) {
        if (listed.isNotEmpty) {
          return listed;
        }
        emptyFallback ??= listed;
      }
    }
    return emptyFallback;
  }

  List<String> _listPathCandidates({
    required String requestPath,
    required String? contextDirectory,
  }) {
    final normalizedPath = _normalizeFilePath(requestPath);
    final normalizedContext = contextDirectory == null
        ? ''
        : _normalizeFilePath(contextDirectory);
    final candidates = <String>{};

    if (normalizedPath.isEmpty || normalizedPath == '.') {
      candidates.add('.');
    } else {
      candidates.add(normalizedPath);
    }

    if (normalizedContext.isNotEmpty && normalizedPath.isNotEmpty) {
      if (normalizedPath == normalizedContext) {
        candidates.add('.');
      }
      final contextPrefix = '$normalizedContext/';
      if (normalizedPath.startsWith(contextPrefix)) {
        final relative = normalizedPath.substring(contextPrefix.length);
        if (relative.isNotEmpty) {
          candidates.add(relative);
          candidates.add('./$relative');
        }
      }
    }

    return candidates.toList(growable: false);
  }

  List<String> _contentPathCandidates({
    required String path,
    required String? contextDirectory,
  }) {
    final normalizedPath = _normalizeFilePath(path);
    final normalizedContext = contextDirectory == null
        ? ''
        : _normalizeFilePath(contextDirectory);
    final candidates = <String>{normalizedPath};
    if (normalizedContext.isNotEmpty) {
      final contextPrefix = '$normalizedContext/';
      if (normalizedPath.startsWith(contextPrefix)) {
        final relative = normalizedPath.substring(contextPrefix.length);
        if (relative.isNotEmpty) {
          candidates.add(relative);
          candidates.add('./$relative');
        }
      }
    }
    return candidates.toList(growable: false);
  }

  Future<FileContent?> _readFileContentWithFallback({
    required ProjectProvider projectProvider,
    required String path,
  }) async {
    final candidates = _contentPathCandidates(
      path: path,
      contextDirectory: projectProvider.currentDirectory,
    );
    FileContent? emptyFallback;
    for (final candidate in candidates) {
      final content = await projectProvider.readFileContent(path: candidate);
      if (content != null) {
        if (content.isBinary || content.content.isNotEmpty) {
          return content;
        }
        emptyFallback ??= content;
      }
    }
    return emptyFallback;
  }

  Future<void> _openFileAndFocusDialog({
    required _FileExplorerContextState fileState,
    required ProjectProvider projectProvider,
    required String path,
    required bool dialogFullscreen,
    VoidCallback? onUpdated,
  }) async {
    await _openFileInTab(
      fileState: fileState,
      projectProvider: projectProvider,
      path: path,
      onUpdated: onUpdated,
    );
    if (!mounted) {
      return;
    }
    await _openOpenFilesDialog(
      fileState: fileState,
      projectProvider: projectProvider,
      fullscreen: dialogFullscreen,
    );
  }

  void _activateFileTab({
    required _FileExplorerContextState fileState,
    required String path,
    VoidCallback? onUpdated,
  }) {
    _setState(() {
      fileState.tabSelection = activateFileTab(fileState.tabSelection, path);
    });
    onUpdated?.call();
  }

  void _closeFileTab({
    required _FileExplorerContextState fileState,
    required String path,
    VoidCallback? onUpdated,
  }) {
    _setState(() {
      fileState.tabSelection = closeFileTab(fileState.tabSelection, path);
      // Clean up line selection state for the closed tab.
      final normalizedPath = _normalizeFilePath(path);
      fileState.selectedLinesByPath.remove(normalizedPath);
      fileState.lastSelectedLineByPath.remove(normalizedPath);
    });
    onUpdated?.call();
  }

  Future<void> _reloadFileTab({
    required _FileExplorerContextState fileState,
    required ProjectProvider projectProvider,
    required String path,
    bool silent = false,
    VoidCallback? onUpdated,
  }) async {
    final normalizedPath = _normalizeFilePath(path);
    if (!silent && mounted) {
      _setState(() {
        fileState.tabsByPath[normalizedPath] = const _FileTabViewState(
          status: _FileTabLoadStatus.loading,
          content: '',
        );
      });
      onUpdated?.call();
    }

    final content = await _readFileContentWithFallback(
      projectProvider: projectProvider,
      path: normalizedPath,
    );
    if (!mounted) {
      return;
    }
    _setState(() {
      if (content == null) {
        fileState.tabsByPath[normalizedPath] = _FileTabViewState(
          status: _FileTabLoadStatus.error,
          content: '',
          errorMessage: projectProvider.error ?? 'Failed to load file content',
        );
        return;
      }
      if (content.isBinary) {
        fileState.tabsByPath[normalizedPath] = _FileTabViewState(
          status: _FileTabLoadStatus.binary,
          content: '',
          mimeType: content.mimeType,
        );
        return;
      }
      final text = content.content;
      if (text.isEmpty) {
        fileState.tabsByPath[normalizedPath] = _FileTabViewState(
          status: _FileTabLoadStatus.empty,
          content: '',
          mimeType: content.mimeType,
        );
        return;
      }
      fileState.tabsByPath[normalizedPath] = _FileTabViewState(
        status: _FileTabLoadStatus.ready,
        content: text,
        mimeType: content.mimeType,
      );
    });
    onUpdated?.call();
  }

  Future<void> _openOpenFilesDialog({
    required _FileExplorerContextState fileState,
    required ProjectProvider projectProvider,
    required bool fullscreen,
  }) async {
    if (!fileState.tabSelection.hasOpenTabs || !mounted) {
      return;
    }
    final mediaQuery = MediaQuery.of(context);
    final dialogWidth = (mediaQuery.size.width * 0.7).clamp(560.0, 1200.0);
    final dialogHeight = (mediaQuery.size.height * 0.7).clamp(420.0, 900.0);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            if (fullscreen) {
              return Dialog.fullscreen(
                key: const ValueKey<String>('open_files_dialog_fullscreen'),
                child: Scaffold(
                  appBar: AppBar(
                    title: Text(
                      'Open files (${fileState.tabSelection.openPaths.length})',
                    ),
                    leading: IconButton(
                      icon: const Icon(Symbols.close),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ),
                  body: _buildFileViewerPanel(
                    fileState: fileState,
                    projectProvider: projectProvider,
                    height: double.infinity,
                    margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    onStateChanged: () => setDialogState(() {}),
                    onContextAdded: () {
                      // Pop both the file viewer dialog and the mobile
                      // Files dialog behind it (two stacked routes).
                      final navigator = Navigator.of(dialogContext);
                      navigator.pop();
                      navigator.pop();
                      _inputFocusNode.requestFocus();
                    },
                  ),
                ),
              );
            }
            return Dialog(
              key: const ValueKey<String>('open_files_dialog_centered'),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: dialogWidth.toDouble(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: 300,
                    maxHeight: dialogHeight.toDouble(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Open files (${fileState.tabSelection.openPaths.length})',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              icon: const Icon(Symbols.close),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _buildFileViewerPanel(
                          fileState: fileState,
                          projectProvider: projectProvider,
                          height: double.infinity,
                          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                          onStateChanged: () => setDialogState(() {}),
                          onContextAdded: () {
                            Navigator.of(dialogContext).pop();
                            _inputFocusNode.requestFocus();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildFileTreeChildren({
    required _FileExplorerContextState fileState,
    required ProjectProvider projectProvider,
    required bool dialogFullscreen,
    VoidCallback? onStateChanged,
    required String parentCacheKey,
    required int depth,
  }) {
    final nodes =
        fileState.directoryChildren[parentCacheKey] ?? const <FileNode>[];
    final rows = <Widget>[];
    for (final node in nodes) {
      final isExpanded = fileState.expandedDirectories.contains(node.path);
      final isLoading = fileState.loadingDirectories.contains(node.path);
      final isActiveFile = fileState.tabSelection.activePath == node.path;
      rows.add(
        InkWell(
          key: ValueKey<String>(
            'file_tree_item_${_normalizeFilePath(node.path)}',
          ),
          onTap: () {
            if (node.isDirectory) {
              if (isExpanded) {
                _setState(() {
                  fileState.expandedDirectories.remove(node.path);
                });
                return;
              }
              _setState(() {
                fileState.expandedDirectories.add(node.path);
              });
              unawaited(
                _loadDirectoryNodes(
                  state: fileState,
                  projectProvider: projectProvider,
                  cacheKey: node.path,
                  requestPath: node.path,
                ),
              );
              return;
            }
            unawaited(
              _openFileAndFocusDialog(
                fileState: fileState,
                projectProvider: projectProvider,
                path: node.path,
                dialogFullscreen: dialogFullscreen,
                onUpdated: onStateChanged,
              ),
            );
          },
          child: Container(
            color: isActiveFile
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                : null,
            padding: EdgeInsets.fromLTRB(8 + (depth * 14), 6, 8, 6),
            child: Row(
              children: [
                if (node.isDirectory)
                  Icon(
                    isExpanded ? Symbols.expand_more : Symbols.chevron_right,
                    size: 16,
                  )
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 2),
                Icon(
                  _fileIconForNode(node),
                  size: 16,
                  color: node.isDirectory
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.6),
                  ),
              ],
            ),
          ),
        ),
      );
      if (node.isDirectory && isExpanded) {
        rows.addAll(
          _buildFileTreeChildren(
            fileState: fileState,
            projectProvider: projectProvider,
            dialogFullscreen: dialogFullscreen,
            onStateChanged: onStateChanged,
            parentCacheKey: node.path,
            depth: depth + 1,
          ),
        );
      }
    }
    return rows;
  }

  IconData _fileIconForNode(FileNode node) {
    if (node.isDirectory) {
      return _directoryIconForPath(node.path);
    }
    return _fileIconForPath(node.path);
  }

  IconData _directoryIconForPath(String path) {
    final normalizedPath = _normalizeFilePath(path).toLowerCase();
    if (normalizedPath.endsWith('/.github/workflows')) {
      return SimpleIcons.githubactions;
    }
    final folderName = _fileNameFromPath(normalizedPath);
    switch (folderName) {
      case '.github':
        return SimpleIcons.github;
      case '.vscode':
        return SimpleIcons.vscodium;
      case '.idea':
        return SimpleIcons.jetbrains;
      case '.dart_tool':
        return SimpleIcons.dart;
      case '.vite':
        return SimpleIcons.vite;
      case '.husky':
        return SimpleIcons.git;
      case 'android':
        return SimpleIcons.android;
      case 'ios':
        return SimpleIcons.ios;
      case 'macos':
        return SimpleIcons.macos;
      case 'linux':
        return SimpleIcons.linux;
      case '.git':
        return SimpleIcons.git;
      case '.gradle':
        return SimpleIcons.gradle;
      case '.firebase':
        return SimpleIcons.firebase;
      case 'node_modules':
        return SimpleIcons.nodedotjs;
      case 'docker':
        return SimpleIcons.docker;
      case 'scripts':
        return SimpleIcons.iterm2;
      case 'k8s':
      case 'kubernetes':
        return SimpleIcons.kubernetes;
      case 'infra':
      case 'infrastructure':
      case 'terraform':
      case '.terraform':
        return SimpleIcons.terraform;
      case '.next':
        return SimpleIcons.nextdotjs;
      case 'venv':
      case '.venv':
        return SimpleIcons.python;
      default:
        return Symbols.folder;
    }
  }

  IconData _fileIconForPath(String path) {
    final normalizedPath = path.trim().replaceAll('\\', '/').toLowerCase();
    final fileName = _fileNameFromPath(normalizedPath);
    final extension = _fileExtension(fileName);

    // Prefer filename-based mappings for canonical config/build files.
    switch (fileName) {
      case 'package.json':
      case 'package-lock.json':
      case 'npm-shrinkwrap.json':
      case '.npmrc':
        return SimpleIcons.npm;
      case 'pnpm-lock.yaml':
      case 'pnpm-lock.yml':
      case '.pnpmfile.cjs':
        return SimpleIcons.pnpm;
      case 'yarn.lock':
      case '.yarnrc':
      case '.yarnrc.yml':
        return SimpleIcons.yarn;
      case 'bun.lockb':
      case 'bunfig.toml':
        return SimpleIcons.bun;
      case 'dockerfile':
      case '.dockerignore':
      case 'docker-compose.yml':
      case 'docker-compose.yaml':
      case 'compose.yml':
      case 'compose.yaml':
        return SimpleIcons.docker;
      case '.gitignore':
      case '.gitattributes':
      case '.gitmodules':
        return SimpleIcons.git;
      case 'readme.md':
      case 'changelog.md':
      case 'contributing.md':
      case 'license':
      case 'license.md':
        return SimpleIcons.markdown;
      case 'pubspec.yaml':
      case 'pubspec.lock':
      case 'analysis_options.yaml':
        return SimpleIcons.flutter;
      case 'tsconfig.json':
      case 'tsconfig.base.json':
        return SimpleIcons.typescript;
      case 'vite.config.ts':
      case 'vite.config.js':
      case 'vite.config.mjs':
      case 'vite.config.cjs':
      case 'vite.config.mts':
      case 'vite.config.cts':
      case 'vite-env.d.ts':
      case 'vite.svg':
      case 'vitest.config.ts':
      case 'vitest.config.js':
      case 'vitest.config.mjs':
      case 'vitest.config.cjs':
      case 'vitest.config.mts':
      case 'vitest.config.cts':
        return SimpleIcons.vite;
      case 'next.config.ts':
      case 'next.config.js':
      case 'next.config.mjs':
      case 'next.config.cjs':
        return SimpleIcons.nextdotjs;
      case 'webpack.config.ts':
      case 'webpack.config.js':
      case 'webpack.config.mjs':
      case 'webpack.config.cjs':
        return SimpleIcons.webpack;
      case 'rollup.config.ts':
      case 'rollup.config.js':
      case 'rollup.config.mjs':
      case 'rollup.config.cjs':
        return SimpleIcons.rollupdotjs;
      case '.eslintrc':
      case '.eslintrc.js':
      case '.eslintrc.cjs':
      case '.eslintrc.json':
      case '.eslintrc.yml':
      case '.eslintrc.yaml':
      case 'eslint.config.js':
      case 'eslint.config.mjs':
      case 'eslint.config.cjs':
      case 'eslint.config.ts':
        return SimpleIcons.eslint;
      case '.prettierrc':
      case '.prettierrc.js':
      case '.prettierrc.cjs':
      case '.prettierrc.json':
      case '.prettierrc.yml':
      case '.prettierrc.yaml':
      case 'prettier.config.js':
      case 'prettier.config.mjs':
      case 'prettier.config.cjs':
      case 'prettier.config.ts':
        return SimpleIcons.prettier;
      case 'tailwind.config.js':
      case 'tailwind.config.mjs':
      case 'tailwind.config.cjs':
      case 'tailwind.config.ts':
        return SimpleIcons.tailwindcss;
      case 'firebase.json':
      case '.firebaserc':
        return SimpleIcons.firebase;
      case 'go.mod':
      case 'go.sum':
        return SimpleIcons.go;
      case 'cargo.toml':
      case 'cargo.lock':
        return SimpleIcons.rust;
      case 'composer.json':
      case 'composer.lock':
        return SimpleIcons.php;
      case 'requirements.txt':
      case 'pyproject.toml':
        return SimpleIcons.python;
      case 'gemfile':
      case 'gemfile.lock':
        return SimpleIcons.ruby;
      case '.nvmrc':
      case 'nodemon.json':
        return SimpleIcons.nodedotjs;
      case 'jenkinsfile':
      case 'jenkins.yaml':
      case 'jenkins.yml':
        return SimpleIcons.jenkins;
      case 'makefile':
        return Symbols.build;
      case '.bashrc':
      case '.bash_profile':
      case '.bash_aliases':
      case '.zshrc':
      case '.zprofile':
      case '.zshenv':
      case '.profile':
        return SimpleIcons.iterm2;
      case 'id_rsa':
      case 'id_rsa.pub':
      case 'id_dsa':
      case 'id_dsa.pub':
      case 'id_ecdsa':
      case 'id_ecdsa.pub':
      case 'id_ed25519':
      case 'id_ed25519.pub':
        return SimpleIcons.passbolt;
      case '.env':
      case '.env.local':
      case '.env.development':
      case '.env.production':
        return SimpleIcons.dotenv;
    }

    // Then apply extension-based mappings.
    switch (extension) {
      case 'dart':
        return SimpleIcons.dart;
      case 'ts':
      case 'mts':
      case 'cts':
        return SimpleIcons.typescript;
      case 'tsx':
      case 'jsx':
        return SimpleIcons.react;
      case 'js':
      case 'mjs':
      case 'cjs':
        return SimpleIcons.javascript;
      case 'vue':
        return SimpleIcons.vuedotjs;
      case 'html':
      case 'htm':
        return SimpleIcons.html5;
      case 'css':
        return SimpleIcons.css;
      case 'scss':
      case 'sass':
        return SimpleIcons.sass;
      case 'less':
        return SimpleIcons.less;
      case 'styl':
      case 'stylus':
        return SimpleIcons.stylus;
      case 'md':
      case 'mdx':
      case 'rst':
        return SimpleIcons.markdown;
      case 'txt':
        return Symbols.article;
      case 'json':
        return SimpleIcons.json;
      case 'yaml':
      case 'yml':
        return SimpleIcons.yaml;
      case 'toml':
        return SimpleIcons.toml;
      case 'py':
        return SimpleIcons.python;
      case 'go':
        return SimpleIcons.go;
      case 'rs':
        return SimpleIcons.rust;
      case 'java':
        return SimpleIcons.openjdk;
      case 'kt':
      case 'kts':
        return SimpleIcons.kotlin;
      case 'swift':
        return SimpleIcons.swift;
      case 'php':
        return SimpleIcons.php;
      case 'rb':
        return SimpleIcons.ruby;
      case 'lua':
        return SimpleIcons.lua;
      case 'sh':
      case 'ash':
      case 'bash':
      case 'zsh':
        return SimpleIcons.iterm2;
      case 'csv':
        return Symbols.table_chart;
      case 'tsv':
        return Symbols.table_rows;
      case 'sql':
        return SimpleIcons.postgresql;
      case 'pem':
      case 'key':
      case 'crt':
      case 'cer':
      case 'p12':
      case 'pfx':
        return SimpleIcons.passbolt;
      case 'sqlite':
      case 'db':
        return SimpleIcons.sqlite;
      case 'mysql':
        return SimpleIcons.mysql;
      case 'redis':
        return SimpleIcons.redis;
      case 'xml':
      case 'ini':
      case 'cfg':
      case 'conf':
      case 'properties':
        return Symbols.data_object_rounded;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
      case 'bmp':
      case 'tif':
      case 'tiff':
      case 'avif':
      case 'ico':
        return SimpleIcons.googlephotos;
      case 'svg':
        return SimpleIcons.svg;
      case 'svgz':
        return SimpleIcons.inkscape;
      case 'pdf':
        return Symbols.picture_as_pdf;
      default:
        return Symbols.insert_drive_file;
    }
  }

  String _fileNameFromPath(String normalizedPath) {
    if (normalizedPath.isEmpty) {
      return normalizedPath;
    }
    final separator = normalizedPath.lastIndexOf('/');
    if (separator < 0 || separator == normalizedPath.length - 1) {
      return normalizedPath;
    }
    return normalizedPath.substring(separator + 1);
  }

  String _fileExtension(String fileName) {
    final separator = fileName.lastIndexOf('.');
    if (separator <= 0 || separator == fileName.length - 1) {
      return '';
    }
    return fileName.substring(separator + 1);
  }
}
