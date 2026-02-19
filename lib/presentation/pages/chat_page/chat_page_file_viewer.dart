part of '../chat_page.dart';

extension _ChatPageFileViewer on _ChatPageState {
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
                      return SelectionArea(
                        child: SingleChildScrollView(
                          key: ValueKey<String>(
                            'file_viewer_scroll_${_normalizeFilePath(activePath)}',
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            active.content,
                            key: const ValueKey<String>(
                              'file_viewer_content_text',
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontFamily: 'monospace',
                                  height: 1.4,
                                ),
                          ),
                        ),
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
}
