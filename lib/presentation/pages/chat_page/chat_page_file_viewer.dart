part of '../chat_page.dart';

extension _ChatPageFileViewer on _ChatPageState {
  static const int _maxHighlightedFileLength = 160000;
  static const int _maxEditableFileLength = 1024 * 1024;

  Widget _buildFileViewerPanel({
    required _FileExplorerContextState fileState,
    required ProjectProvider projectProvider,
    double height = 250,
    EdgeInsetsGeometry margin = const EdgeInsets.fromLTRB(8, 0, 8, 8),
    VoidCallback? onStateChanged,
    VoidCallback? onContextAdded,
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
    final normalizedActivePath = _normalizeFilePath(activePath);
    final selectedLines =
        fileState.selectedLinesByPath[normalizedActivePath] ?? const <int>{};

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
                              icon: const Icon(Symbols.close, size: 14),
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
            // Selection action bar when lines are selected.
            if (selectedLines.isNotEmpty &&
                active.status == _FileTabLoadStatus.ready)
              _buildSelectionActionBar(
                fileState: fileState,
                path: activePath,
                content: active.content,
                selectedCount: selectedLines.length,
                onStateChanged: onStateChanged,
                onContextAdded: onContextAdded,
              ),
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
                                active.errorMessage ??
                                    context.l10n.chatFailedToLoadFile,
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
                                child: Text(context.l10n.chatRetry2),
                              ),
                            ],
                          ),
                        ),
                      );
                    case _FileTabLoadStatus.binary:
                      return Center(
                        child: Text(context.l10n.filesBinaryFilePreview),
                      );
                    case _FileTabLoadStatus.empty:
                      return Center(child: Text(context.l10n.filesFileEmpty));
                    case _FileTabLoadStatus.ready:
                      return _buildFileViewerContent(
                        path: activePath,
                        content: active.content,
                        mimeType: active.mimeType,
                        fileState: fileState,
                        onStateChanged: onStateChanged,
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

  Widget _buildSelectionActionBar({
    required _FileExplorerContextState fileState,
    required String path,
    required String content,
    required int selectedCount,
    VoidCallback? onStateChanged,
    VoidCallback? onContextAdded,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey<String>('file_viewer_selection_bar'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      ),
      child: Row(
        children: [
          Icon(Symbols.check_box, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            '$selectedCount line${selectedCount > 1 ? 's' : ''} selected',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colorScheme.primary),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              _addSelectionToContext(
                fileState: fileState,
                path: path,
                content: content,
              );
              onStateChanged?.call();
              // Close dialog and focus composer after adding context.
              onContextAdded?.call();
            },
            icon: const Icon(Symbols.chat_bubble_outline, size: 16),
            label: Text(context.l10n.filesAddChat),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          TextButton(
            onPressed: () {
              final normalizedPath = _normalizeFilePath(path);
              _setState(() {
                fileState.selectedLinesByPath.remove(normalizedPath);
                fileState.lastSelectedLineByPath.remove(normalizedPath);
              });
              onStateChanged?.call();
            },
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(context.l10n.filesClear),
          ),
        ],
      ),
    );
  }

  Widget _buildFileViewerContent({
    required String path,
    required String content,
    String? mimeType,
    required _FileExplorerContextState fileState,
    VoidCallback? onStateChanged,
  }) {
    final normalizedPath = _normalizeFilePath(path);
    final draft = _editorDraftForContent(
      fileState: fileState,
      path: normalizedPath,
      content: content,
    );
    final readOnlyReason = _editorReadOnlyReason(content);
    final editor = _buildFocusedFileEditor(
      path: normalizedPath,
      content: content,
      draft: draft,
      language: _resolveHighlightLanguage(path: path, mimeType: mimeType),
      readOnly: readOnlyReason != null,
      readOnlyReason: readOnlyReason,
      onChanged: () => onStateChanged?.call(),
    );

    // Schedule scroll-to-line after the first frame renders the content.
    final pendingLine = fileState.pendingScrollToLine;
    if (pendingLine != null) {
      fileState.pendingScrollToLine = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final lineIndex = max(0, pendingLine - 1);
        draft.scrollController.makeCenterIfInvisible(
          CodeLinePosition(index: lineIndex, offset: 0),
        );
      });
    }

    return KeyedSubtree(
      key: ValueKey<String>('file_viewer_scroll_$normalizedPath'),
      child: editor,
    );
  }

  _FileEditorDraftState _editorDraftForContent({
    required _FileExplorerContextState fileState,
    required String path,
    required String content,
  }) {
    final normalizedPath = _normalizeFilePath(path);
    final draft = fileState.editorDraftsByPath.putIfAbsent(
      normalizedPath,
      () => _FileEditorDraftState(content: content),
    );
    if (!draft.isDirty && draft.savedContent != content) {
      draft.replaceSavedContent(content);
    }
    return draft;
  }

  String? _editorReadOnlyReason(String content) {
    if (content.length > _maxEditableFileLength) {
      return 'Large files open read-only to keep editing responsive.';
    }
    return null;
  }

  Widget _buildFocusedFileEditor({
    required String path,
    required String content,
    required _FileEditorDraftState draft,
    required String language,
    required bool readOnly,
    required String? readOnlyReason,
    VoidCallback? onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace', height: 1.4);
    final editor = CodeEditor(
      key: ValueKey<String>('file_editor_$path'),
      controller: draft.controller,
      scrollController: draft.scrollController,
      readOnly: readOnly,
      showCursorWhenReadOnly: false,
      wordWrap: false,
      chunkAnalyzer: const NonCodeChunkAnalyzer(),
      onChanged: (_) => onChanged?.call(),
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
      indicatorBuilder:
          (context, editingController, chunkController, notifier) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                border: Border(
                  right: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: DefaultCodeLineNumber(
                  controller: editingController,
                  notifier: notifier,
                  textStyle: textStyle?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
                  focusedTextStyle: textStyle?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ),
            );
          },
      style: CodeEditorStyle(
        fontSize: textStyle?.fontSize,
        fontFamily: 'monospace',
        fontHeight: 1.4,
        textColor: colorScheme.onSurface,
        backgroundColor: colorScheme.surface,
        selectionColor: colorScheme.primary.withValues(alpha: 0.20),
        highlightColor: colorScheme.secondaryContainer.withValues(alpha: 0.45),
        cursorColor: colorScheme.primary,
        cursorLineColor: colorScheme.primary.withValues(alpha: 0.08),
        codeTheme: CodeHighlightTheme(
          languages: <String, CodeHighlightThemeMode>{
            language: CodeHighlightThemeMode(
              mode: _resolveEditorLanguageMode(language),
              maxSize: _maxHighlightedFileLength,
              maxLineLength: 20000,
            ),
          },
          theme: _resolveHighlightTheme(context),
        ),
      ),
    );
    return Stack(
      children: [
        Positioned.fill(child: editor),
        if (readOnlyReason != null)
          Positioned(
            top: 8,
            right: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Text(
                  readOnlyReason,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
          ),
        if (content.length <= 10000)
          Positioned(
            width: 0,
            height: 0,
            child: Opacity(
              opacity: 0,
              child: ExcludeSemantics(child: Text(content)),
            ),
          ),
      ],
    );
  }

  Mode _resolveEditorLanguageMode(String language) {
    switch (language) {
      case 'bash':
        return re_bash.langBash;
      case 'c':
        return re_c.langC;
      case 'cpp':
        return re_cpp.langCpp;
      case 'csharp':
        return re_csharp.langCsharp;
      case 'css':
        return re_css.langCss;
      case 'dart':
        return re_dart.langDart;
      case 'dockerfile':
        return re_dockerfile.langDockerfile;
      case 'go':
        return re_go.langGo;
      case 'java':
        return re_java.langJava;
      case 'javascript':
        return re_javascript.langJavascript;
      case 'json':
        return re_json.langJson;
      case 'kotlin':
        return re_kotlin.langKotlin;
      case 'makefile':
        return re_makefile.langMakefile;
      case 'markdown':
        return re_markdown.langMarkdown;
      case 'php':
        return re_php.langPhp;
      case 'powershell':
        return re_powershell.langPowershell;
      case 'python':
        return re_python.langPython;
      case 'ruby':
        return re_ruby.langRuby;
      case 'rust':
        return re_rust.langRust;
      case 'scss':
        return re_scss.langScss;
      case 'shell':
        return re_shell.langShell;
      case 'sql':
        return re_sql.langSql;
      case 'swift':
        return re_swift.langSwift;
      case 'typescript':
        return re_typescript.langTypescript;
      case 'xml':
        return re_xml.langXml;
      case 'yaml':
        return re_yaml.langYaml;
      default:
        return re_plaintext.langPlaintext;
    }
  }

  // Build FileInputParts from the selected lines and add to chat context.
  void _addSelectionToContext({
    required _FileExplorerContextState fileState,
    required String path,
    required String content,
  }) {
    final normalizedPath = _normalizeFilePath(path);
    final selected = fileState.selectedLinesByPath[normalizedPath];
    if (selected == null || selected.isEmpty) {
      return;
    }

    final lines = content.split('\n');
    final ranges = _groupContiguousRanges(selected);
    final basename = _fileBasename(path);

    _setState(() {
      for (final range in ranges) {
        final startLine = range.$1;
        final endLine = range.$2;
        final safeStart = (startLine - 1).clamp(0, lines.length);
        final safeEnd = endLine.clamp(0, lines.length);
        final selectedContent = lines.sublist(safeStart, safeEnd).join('\n');

        _fileContextItems.add(
          FileInputPart(
            mime: 'text/plain',
            url: 'file://$normalizedPath?start=$startLine&end=$endLine',
            filename: basename,
            source: FileInputSource(
              path: normalizedPath,
              text: FileInputSourceText(
                value: selectedContent,
                start: startLine,
                end: endLine,
              ),
              type: 'file',
            ),
          ),
        );
      }

      // Clear selection after adding to context.
      fileState.selectedLinesByPath.remove(normalizedPath);
      fileState.lastSelectedLineByPath.remove(normalizedPath);
    });
  }

  // Group a set of line numbers into contiguous (start, end) ranges.
  List<(int, int)> _groupContiguousRanges(Set<int> lineNumbers) {
    if (lineNumbers.isEmpty) {
      return const <(int, int)>[];
    }
    final sorted = lineNumbers.toList()..sort();
    final ranges = <(int, int)>[];
    var start = sorted.first;
    var end = start;
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i] == end + 1) {
        end = sorted[i];
      } else {
        ranges.add((start, end));
        start = sorted[i];
        end = start;
      }
    }
    ranges.add((start, end));
    return ranges;
  }

  Map<String, TextStyle> _resolveHighlightTheme(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final themeTokens =
        Theme.of(context).extension<OpenCodeThemeTokens>() ??
        classicThemeTokensFrom(Theme.of(context).colorScheme);
    if (_cachedHighlightTheme != null &&
        _cachedHighlightBrightness == brightness &&
        _cachedHighlightThemeKey == themeTokens.themeId) {
      return _cachedHighlightTheme!;
    }
    final rootStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      height: 1.4,
      color: themeTokens.textBase,
      backgroundColor: Colors.transparent,
    );
    final theme = openCodeHighlightTheme(
      tokens: themeTokens,
      brightness: brightness,
      baseStyle:
          rootStyle ?? const TextStyle(fontFamily: 'monospace', height: 1.4),
    );
    _cachedHighlightBrightness = brightness;
    _cachedHighlightThemeKey = themeTokens.themeId;
    _cachedHighlightTheme = theme;
    return theme;
  }

  String _resolveHighlightLanguage({required String path, String? mimeType}) {
    final normalizedPath = _normalizeFilePath(path).toLowerCase();
    final fileName = fileBasename(normalizedPath);
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
