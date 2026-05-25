part of '../chat_page.dart';

extension _ChatPageFileViewer on _ChatPageState {
  static const int _maxHighlightedFileLength = 160000;

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
            label: const Text('Add to chat'),
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
            child: const Text('Clear'),
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
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace', height: 1.4);
    final colorScheme = Theme.of(context).colorScheme;

    // Measure actual line height from font metrics for precise alignment.
    final tp = TextPainter(
      text: TextSpan(text: '0', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final lineHeight = tp.preferredLineHeight;
    final charWidth = tp.width;

    final lineCount = '\n'.allMatches(content).length + 1;
    final gutterDigits = lineCount.toString().length;
    final gutterWidth = (gutterDigits * charWidth + 20).ceilToDouble();

    final selectedLines =
        fileState.selectedLinesByPath[normalizedPath] ?? const <int>{};

    final codeWidget = content.length <= _maxHighlightedFileLength
        ? KeyedSubtree(
            key: ValueKey<String>(
              'file_viewer_content_highlight_$normalizedPath',
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

    // Schedule scroll-to-line after the first frame renders the content.
    final pendingLine = fileState.pendingScrollToLine;
    if (pendingLine != null) {
      fileState.pendingScrollToLine = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_fileViewerScrollController.hasClients) return;
      final targetOffset = ((pendingLine - 1) * lineHeight)
          .clamp(0.0, _fileViewerScrollController.position.maxScrollExtent);
      _fileViewerScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableCodeWidth = constraints.maxWidth.isFinite
            ? (constraints.maxWidth - gutterWidth - 20).clamp(
                0.0,
                double.infinity,
              )
            : 0.0;
        // GestureDetector is INSIDE the scroll view so localPosition
        // maps directly to content coordinates (no scroll offset math).
        return SingleChildScrollView(
          controller: _fileViewerScrollController,
          key: ValueKey<String>('file_viewer_scroll_$normalizedPath'),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final lineNumber =
                  (details.localPosition.dy / lineHeight).floor() + 1;
              if (lineNumber < 1 || lineNumber > lineCount) {
                return;
              }
              final isShift = HardwareKeyboard.instance.isShiftPressed;
              _handleGutterLineTap(
                fileState: fileState,
                path: normalizedPath,
                lineNumber: lineNumber,
                lineCount: lineCount,
                isShiftHeld: isShift,
              );
              onStateChanged?.call();
            },
            child: Stack(
              children: [
                // Gutter background strip (behind everything).
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: gutterWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      border: Border(
                        right: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Full-width selection highlights (behind text).
                if (selectedLines.isNotEmpty)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _LineSelectionPainter(
                        selectedLines: selectedLines,
                        lineHeight: lineHeight,
                        color: colorScheme.primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                // Content row: gutter text + code.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gutter line numbers (visual only).
                    SizedBox(
                      width: gutterWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        // Use RichText (not Text.rich) so the gutter
                        // renders without MediaQuery textScaler, matching
                        // HighlightView's RichText for pixel-aligned lines.
                        child: RichText(
                          text: TextSpan(
                            style: textStyle,
                            children: List<InlineSpan>.generate(lineCount, (
                              index,
                            ) {
                              final lineNumber = index + 1;
                              final isSelected = selectedLines.contains(
                                lineNumber,
                              );
                              return TextSpan(
                                text:
                                    '${lineNumber.toString().padLeft(gutterDigits)}${index < lineCount - 1 ? '\n' : ''}',
                                style: textStyle?.copyWith(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant.withValues(
                                          alpha: 0.5,
                                        ),
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : null,
                                ),
                              );
                            }),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                    // Code area with horizontal scroll.
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, right: 12),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: availableCodeWidth,
                            ),
                            child: codeWidget,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Toggle or range-select a line in the gutter.
  void _handleGutterLineTap({
    required _FileExplorerContextState fileState,
    required String path,
    required int lineNumber,
    required int lineCount,
    required bool isShiftHeld,
  }) {
    _setState(() {
      final selected = fileState.selectedLinesByPath.putIfAbsent(
        path,
        () => <int>{},
      );

      if (isShiftHeld) {
        // Range selection from last anchor to current line.
        final anchor = fileState.lastSelectedLineByPath[path] ?? lineNumber;
        final start = anchor < lineNumber ? anchor : lineNumber;
        final end = anchor < lineNumber ? lineNumber : anchor;
        for (var i = start; i <= end; i++) {
          if (i >= 1 && i <= lineCount) {
            selected.add(i);
          }
        }
      } else {
        // Toggle single line.
        if (selected.contains(lineNumber)) {
          selected.remove(lineNumber);
        } else {
          selected.add(lineNumber);
        }
      }

      fileState.lastSelectedLineByPath[path] = lineNumber;
    });
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

/// Paints background rectangles behind selected code lines.
class _LineSelectionPainter extends CustomPainter {
  _LineSelectionPainter({
    required this.selectedLines,
    required this.lineHeight,
    required this.color,
  });

  final Set<int> selectedLines;
  final double lineHeight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedLines.isEmpty) {
      return;
    }
    final paint = Paint()..color = color;
    for (final line in selectedLines) {
      final y = (line - 1) * lineHeight;
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, lineHeight), paint);
    }
  }

  @override
  bool shouldRepaint(_LineSelectionPainter oldDelegate) {
    return !setEquals(oldDelegate.selectedLines, selectedLines) ||
        oldDelegate.lineHeight != lineHeight ||
        oldDelegate.color != color;
  }
}
