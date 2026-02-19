part of '../chat_page.dart';

extension _ChatPageFileViewer on _ChatPageState {
  static const int _maxHighlightedFileLength = 160000;

  Widget _buildFileViewerPanel({
    required _FileExplorerContextState fileState,
    required ProjectProvider projectProvider,
    double height = 250,
    EdgeInsetsGeometry margin = const EdgeInsets.fromLTRB(8, 0, 8, 8),
    VoidCallback? onStateChanged,
  }) {
    if (!fileState.tabSelection.hasOpenTabs) {
      return const SizedBox.shrink();
    }

    final activePath =
        fileState.tabSelection.activePath ??
        fileState.tabSelection.openPaths.first;
    final active =
        fileState.tabsByPath[activePath] ??
        const _FileTabViewState(
          status: _FileTabLoadStatus.loading,
          content: '',
        );

    return Container(
      key: const ValueKey<String>('file_viewer_panel'),
      height: height,
      margin: margin,
      child: Card(
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                children: [
                  for (final path in fileState.tabSelection.openPaths)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Container(
                        key: ValueKey<String>(
                          'file_viewer_tab_${_normalizeFilePath(path)}',
                        ),
                        decoration: BoxDecoration(
                          color: path == activePath
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.14)
                              : Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                _activateFileTab(
                                  fileState: fileState,
                                  path: path,
                                  onUpdated: onStateChanged,
                                );
                              },
                              borderRadius: BorderRadius.circular(999),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_fileIconForPath(path), size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      _fileBasename(path),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              key: ValueKey<String>(
                                'file_viewer_tab_close_${_normalizeFilePath(path)}',
                              ),
                              visualDensity: Theme.of(context).visualDensity,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 22,
                                minHeight: 22,
                              ),
                              icon: const Icon(Icons.close, size: 14),
                              onPressed: () {
                                _closeFileTab(
                                  fileState: fileState,
                                  path: path,
                                  onUpdated: onStateChanged,
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Builder(
                builder: (_) {
                  switch (active.status) {
                    case _FileTabLoadStatus.loading:
                      return const Center(child: CircularProgressIndicator());
                    case _FileTabLoadStatus.error:
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                active.errorMessage ?? 'Failed to load file',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                key: const ValueKey<String>(
                                  'file_viewer_retry_button',
                                ),
                                onPressed: () {
                                  unawaited(
                                    _reloadFileTab(
                                      fileState: fileState,
                                      projectProvider: projectProvider,
                                      path: activePath,
                                      onUpdated: onStateChanged,
                                    ),
                                  );
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    case _FileTabLoadStatus.binary:
                      return const Center(
                        child: Text('Binary file preview is not available.'),
                      );
                    case _FileTabLoadStatus.empty:
                      return const Center(child: Text('File is empty.'));
                    case _FileTabLoadStatus.ready:
                      return _buildFileViewerContent(
                        path: activePath,
                        content: active.content,
                        mimeType: active.mimeType,
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileViewerContent({
    required String path,
    required String content,
    String? mimeType,
  }) {
    final normalizedPath = _normalizeFilePath(path);
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace', height: 1.4);

    final codeWidget = content.length <= _maxHighlightedFileLength
        ? KeyedSubtree(
            key: ValueKey<String>(
              'file_viewer_content_highlight_${_normalizeFilePath(path)}',
            ),
            child: HighlightView(
              content,
              language: _resolveHighlightLanguage(
                path: path,
                mimeType: mimeType,
              ),
              theme: _resolveHighlightTheme(context),
              textStyle: textStyle,
            ),
          )
        : Text(
            content,
            key: const ValueKey<String>('file_viewer_content_text_fallback'),
            style: textStyle,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = constraints.maxWidth.isFinite
            ? (constraints.maxWidth - 24).clamp(0.0, double.infinity)
            : 0.0;
        return SelectionArea(
          child: SingleChildScrollView(
            key: ValueKey<String>('file_viewer_scroll_$normalizedPath'),
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: minWidth),
                child: codeWidget,
              ),
            ),
          ),
        );
      },
    );
  }

  Map<String, TextStyle> _resolveHighlightTheme(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseTheme = Theme.of(context).brightness == Brightness.dark
        ? atomOneDarkTheme
        : githubTheme;
    final rootStyle = (baseTheme['root'] ?? const TextStyle()).copyWith(
      color: colorScheme.onSurface,
      backgroundColor: Colors.transparent,
    );
    return <String, TextStyle>{...baseTheme, 'root': rootStyle};
  }

  String _resolveHighlightLanguage({required String path, String? mimeType}) {
    final normalizedPath = _normalizeFilePath(path).toLowerCase();
    final fileName = _fileNameFromPath(normalizedPath);
    final extension = _fileExtension(fileName);
    final normalizedMimeType = (mimeType ?? '').toLowerCase();

    if (normalizedMimeType.contains('json')) {
      return 'json';
    }
    if (normalizedMimeType.contains('yaml')) {
      return 'yaml';
    }
    if (normalizedMimeType.contains('xml')) {
      return 'xml';
    }
    if (normalizedMimeType.contains('markdown')) {
      return 'markdown';
    }
    if (normalizedMimeType.contains('sql')) {
      return 'sql';
    }

    switch (fileName) {
      case 'dockerfile':
        return 'dockerfile';
      case 'makefile':
        return 'makefile';
      case '.bashrc':
      case '.bash_profile':
      case '.bash_aliases':
      case '.zshrc':
      case '.zprofile':
      case '.zshenv':
      case '.profile':
        return 'bash';
    }

    switch (extension) {
      case 'dart':
        return 'dart';
      case 'js':
      case 'mjs':
      case 'cjs':
      case 'jsx':
        return 'javascript';
      case 'ts':
      case 'mts':
      case 'cts':
      case 'tsx':
        return 'typescript';
      case 'json':
        return 'json';
      case 'yaml':
      case 'yml':
        return 'yaml';
      case 'md':
      case 'mdx':
        return 'markdown';
      case 'sh':
      case 'ash':
      case 'bash':
      case 'zsh':
        return 'bash';
      case 'py':
        return 'python';
      case 'go':
        return 'go';
      case 'rs':
        return 'rust';
      case 'java':
        return 'java';
      case 'kt':
      case 'kts':
        return 'kotlin';
      case 'swift':
        return 'swift';
      case 'php':
        return 'php';
      case 'rb':
        return 'ruby';
      case 'sql':
        return 'sql';
      case 'html':
      case 'htm':
      case 'xml':
      case 'svg':
        return 'xml';
      case 'css':
        return 'css';
      case 'scss':
        return 'scss';
      case 'less':
        return 'less';
      case 'toml':
      case 'ini':
      case 'cfg':
      case 'conf':
      case 'properties':
        return 'ini';
      case 'vue':
        return 'vue';
      default:
        return 'plaintext';
    }
  }
}
