part of '../chat_message_widget.dart';

/// Tool part rendering: status chip, details toggle, command/output sections,
/// and diff visualization.
extension _ChatMessageToolPartBuilder on _ChatMessageWidgetState {
  Widget _buildToolPart(
    BuildContext context,
    ToolPart part, {
    VoidCallback? onNavigateToSubConversation,
  }) {
    final isCompactToolStatus = MediaQuery.sizeOf(context).width < 600;
    final colorScheme = Theme.of(context).colorScheme;
    final presentation = _toolPresentation(part.tool);
    final descriptionLabel = _resolveToolDescriptionLabel(part);
    final typeLabel = _resolveToolTypeLabel(part);
    final isTaskTool = _normalizeToolName(part.tool) == 'task';
    final hasDetails = part.state.status != ToolStatus.pending;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppShapes.borderSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(presentation.icon, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      descriptionLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (typeLabel.toLowerCase() !=
                        descriptionLabel.toLowerCase()) ...[
                      const SizedBox(height: 2),
                      Text(
                        typeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildToolStatusChip(
                context,
                part.state.status,
                showLabel: !isCompactToolStatus,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isTaskTool && onNavigateToSubConversation != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                key: ValueKey<String>('task_tool_open_session_${part.id}'),
                onPressed: onNavigateToSubConversation,
                icon: const Icon(Symbols.open_in_new_rounded, size: 16),
                label: const Text('Open sub-conversation'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          _ToolPartDetailsToggle(
            key: ValueKey<String>('tool_part_details_toggle_${part.id}'),
            partId: part.id,
            hasDetails: hasDetails,
            details: _buildToolStateDetails(context, part.state, part.tool),
          ),
        ],
      ),
    );
  }

  Widget _buildToolStatusChip(
    BuildContext context,
    ToolStatus status, {
    required bool showLabel,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case ToolStatus.pending:
        color = colorScheme.secondary;
        label = 'Queued';
        icon = Symbols.schedule;
        break;
      case ToolStatus.running:
        color = colorScheme.primary;
        label = 'In progress';
        icon = Symbols.play_arrow;
        break;
      case ToolStatus.completed:
        color = colorScheme.tertiary;
        label = 'Done';
        icon = Symbols.check_circle_outline_rounded;
        break;
      case ToolStatus.error:
        color = colorScheme.error;
        label = 'Needs attention';
        icon = Symbols.warning_amber_rounded;
        break;
    }

    if (!showLabel) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppShapes.borderFull,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 16, color: color),
      );
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: Theme.of(context).visualDensity,
    );
  }

  Widget _buildToolStateDetails(
    BuildContext context,
    ToolState state,
    String toolName,
  ) {
    final command = _extractToolCommand(state);
    switch (state.status) {
      case ToolStatus.running:
        final runningState = state as ToolStateRunning;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (command != null)
              _buildToolCommandSection(
                context,
                toolName: toolName,
                command: command,
              ),
            if (runningState.title != null)
              Text(
                runningState.title!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const LinearProgressIndicator(),
          ],
        );
      case ToolStatus.completed:
        final completedState = state as ToolStateCompleted;
        final resolvedOutput = _resolveToolOutput(
          toolName: toolName,
          state: completedState,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (command != null)
              _buildToolCommandSection(
                context,
                toolName: toolName,
                command: command,
              ),
            if (completedState.title != null)
              Text(
                completedState.title!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            if (resolvedOutput.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: AppShapes.borderExtraSmall,
                ),
                child: _buildToolBodyContent(
                  context,
                  text: resolvedOutput,
                  toolName: toolName,
                  lineKeyPrefix: 'tool_output_diff',
                ),
              ),
          ],
        );
      case ToolStatus.error:
        final errorState = state as ToolStateError;
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: AppShapes.borderExtraSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (command != null)
                _buildToolCommandSection(
                  context,
                  toolName: toolName,
                  command: command,
                  inErrorContainer: true,
                ),
              _buildToolBodyContent(
                context,
                text: errorState.error,
                toolName: toolName,
                lineKeyPrefix: 'tool_error_diff',
                textColor: Theme.of(context).colorScheme.onErrorContainer,
                toggleColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildToolBodyContent(
    BuildContext context, {
    required String text,
    required String toolName,
    required String lineKeyPrefix,
    Color? textColor,
    Color? toggleColor,
  }) {
    final textForRender = _truncatePreview(
      text,
      maxChars: _ChatMessageWidgetState._maxToolOutputPreviewChars,
      reason: 'Large tool output preview truncated for app stability.',
    );
    return _CollapsibleToolContent(
      text: textForRender,
      collapsedMaxLines: _ChatMessageWidgetState._collapsedToolDetailMaxLines,
      toolName: toolName,
      lineKeyPrefix: lineKeyPrefix,
      textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: textColor,
        fontFamily: 'monospace',
      ),
      toggleTextStyle: toggleColor == null
          ? null
          : Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: toggleColor),
    );
  }

  Widget _buildToolCommandSection(
    BuildContext context, {
    required String toolName,
    required String command,
    bool inErrorContainer = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelColor = inErrorContainer
        ? colorScheme.onErrorContainer.withValues(alpha: 0.84)
        : colorScheme.onSurfaceVariant;
    final valueColor = inErrorContainer
        ? colorScheme.onErrorContainer
        : colorScheme.onSurface;
    final backgroundColor = inErrorContainer
        ? colorScheme.onErrorContainer.withValues(alpha: 0.08)
        : colorScheme.surface;
    final prefix = toolName.trim().toLowerCase() == 'bash'
        ? 'Command'
        : 'Input';

    final shouldColorizeInput =
        prefix == 'Input' && _isDiffLikeToolInput(toolName, command);

    if (shouldColorizeInput) {
      final normalizedInput = _normalizeToolInputDiff(command);
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppShapes.borderExtraSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$prefix:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            _buildToolBodyContent(
              context,
              text: normalizedInput,
              toolName: toolName,
              lineKeyPrefix: 'tool_input_diff',
              textColor: valueColor,
              toggleColor: labelColor,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppShapes.borderExtraSmall,
      ),
      child: RichText(
        key: const ValueKey<String>('tool_command_text'),
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          children: [
            TextSpan(
              text: '$prefix: ',
              style: TextStyle(color: labelColor, fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: command,
              style: TextStyle(color: valueColor),
            ),
          ],
        ),
      ),
    );
  }

  bool _isDiffLikeToolInput(String toolName, String command) {
    final toolLower = toolName.trim().toLowerCase();

    if (toolLower.contains('apply_patch') ||
        toolLower.contains('patch') ||
        toolLower == 'edit') {
      return command.contains('*** Begin Patch') ||
          command.contains('\n+') ||
          command.contains('\n-') ||
          command.contains('\n@@') ||
          command.contains('\ndiff --git');
    }

    return isDiffFormat(command);
  }

  String _normalizeToolInputDiff(String command) {
    const markers = <String>['*** Begin Patch', 'diff --git', '--- ', '@@'];

    for (final marker in markers) {
      final index = command.indexOf(marker);
      if (index > 0) {
        return command.substring(index).trimRight();
      }
      if (index == 0) {
        return command;
      }
    }

    return command;
  }

  String? _extractToolCommand(ToolState state) {
    switch (state.status) {
      case ToolStatus.pending:
        return null;
      case ToolStatus.running:
        final runningState = state as ToolStateRunning;
        return _extractCommandFromInputMap(runningState.input);
      case ToolStatus.completed:
        final completedState = state as ToolStateCompleted;
        return _extractCommandFromInputMap(completedState.input);
      case ToolStatus.error:
        final errorState = state as ToolStateError;
        return _extractCommandFromInputMap(errorState.input);
    }
  }

  String? _extractCommandFromInputMap(Map<String, dynamic> input) {
    if (input.isEmpty) {
      return null;
    }

    String? readString(dynamic value) {
      if (value is! String) {
        return null;
      }
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    Map<String, dynamic>? readMap(dynamic value) {
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return null;
    }

    final command = readString(input['command']) ?? readString(input['cmd']);
    if (command != null) {
      return _truncatePreview(
        command,
        maxChars: _ChatMessageWidgetState._maxToolCommandPreviewChars,
        reason: 'Command preview truncated for stability.',
      );
    }

    final nestedInput = readMap(input['input']);
    if (nestedInput != null) {
      final nestedCommand = _extractCommandFromInputMap(nestedInput);
      if (nestedCommand != null) {
        return nestedCommand;
      }
    }

    final fallback = input.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(' | ')
        .trim();
    if (fallback.isEmpty) {
      return null;
    }
    return _truncatePreview(
      fallback,
      maxChars: _ChatMessageWidgetState._maxToolCommandPreviewChars,
      reason: 'Input preview truncated for stability.',
    );
  }

  String _resolveToolOutput({
    required String toolName,
    required ToolStateCompleted state,
  }) {
    final output = state.output.trim();
    if (output.isNotEmpty) {
      return _truncatePreview(
        state.output,
        maxChars: _ChatMessageWidgetState._maxToolOutputPreviewChars,
        reason: 'Tool output preview truncated for app stability.',
      );
    }

    final input = state.input;
    final tool = toolName.toLowerCase();
    final directDiff = _firstInputString(input, const [
      'diff',
      'patch',
      'unified_diff',
      'unifiedDiff',
      'content',
      'text',
    ]);
    if (directDiff != null && directDiff.trim().isNotEmpty) {
      return _truncatePreview(
        directDiff,
        maxChars: _ChatMessageWidgetState._maxToolOutputPreviewChars,
        reason: 'Diff preview truncated for app stability.',
      );
    }

    if (tool == 'edit' || tool.contains('edit') || tool.contains('patch')) {
      final syntheticDiff = _buildSyntheticEditDiff(input);
      if (syntheticDiff != null) {
        return syntheticDiff;
      }
    }

    return '';
  }

  String? _firstInputString(Map<String, dynamic> input, List<String> keys) {
    for (final key in keys) {
      final value = input[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String? _buildSyntheticEditDiff(Map<String, dynamic> input) {
    final before = _firstInputString(input, const [
      'old_string',
      'oldString',
      'before',
      'old',
    ]);
    final after = _firstInputString(input, const [
      'new_string',
      'newString',
      'after',
      'new',
    ]);
    if (before == null || after == null || before == after) {
      return null;
    }

    if (before.length + after.length >
        _ChatMessageWidgetState._maxSyntheticDiffChars) {
      return 'Diff preview omitted: edit payload is too large to render safely on mobile.';
    }

    final path =
        _firstInputString(input, const [
          'file_path',
          'path',
          'file',
          'target',
        ]) ??
        'file';

    final beforeLines = before.split('\n').map((line) => '-$line').join('\n');
    final afterLines = after.split('\n').map((line) => '+$line').join('\n');
    return '--- $path\n+++ $path\n@@\n$beforeLines\n$afterLines';
  }
}

class _ToolPartDetailsToggle extends StatefulWidget {
  const _ToolPartDetailsToggle({
    super.key,
    required this.partId,
    required this.hasDetails,
    required this.details,
  });

  final String partId;
  final bool hasDetails;
  final Widget details;

  @override
  State<_ToolPartDetailsToggle> createState() => _ToolPartDetailsToggleState();
}

class _ToolPartDetailsToggleState extends State<_ToolPartDetailsToggle> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasDetails) {
      return const SizedBox.shrink();
    }
    final compactLayout = MediaQuery.sizeOf(context).width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_expanded) widget.details,
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: ValueKey<String>('tool_part_details_button_${widget.partId}'),
            onPressed: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            ),
            child: Text(
              _expanded ? 'Hide' : (compactLayout ? 'Show' : 'Details'),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
      ],
    );
  }
}

class _CollapsibleToolContent extends StatefulWidget {
  const _CollapsibleToolContent({
    required this.text,
    required this.collapsedMaxLines,
    required this.toolName,
    this.lineKeyPrefix = 'tool_diff_line',
    this.textStyle,
    this.toggleTextStyle,
  });

  final String text;
  final int collapsedMaxLines;
  final String toolName;
  final String lineKeyPrefix;
  final TextStyle? textStyle;
  final TextStyle? toggleTextStyle;

  @override
  State<_CollapsibleToolContent> createState() =>
      _CollapsibleToolContentState();
}

class _DiffLineVisualStyle {
  const _DiffLineVisualStyle({this.textColor, this.backgroundColor});

  final Color? textColor;
  final Color? backgroundColor;
}

class _CollapsibleToolContentState extends State<_CollapsibleToolContent> {
  bool _expanded = false;

  double _expandedToolViewportHeight(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final responsiveCap = viewportHeight * 0.4;
    return math.min(300.0, responsiveCap.clamp(180.0, 300.0));
  }

  bool get _canExpand {
    if (widget.text.trim().isEmpty) {
      return false;
    }
    final lineCount = '\n'.allMatches(widget.text).length + 1;
    return lineCount > widget.collapsedMaxLines || widget.text.length > 160;
  }

  /// Hybrid detection: tool name + content heuristic.
  bool _isDiffContent(String toolName, String text) {
    final toolLower = toolName.toLowerCase();
    if (toolLower.contains('apply_patch') ||
        toolLower.contains('patch') ||
        toolLower == 'edit') {
      return true;
    }

    // Heuristic for bash/others (first 20 lines)
    return isDiffFormat(text);
  }

  DiffLineType _resolveDiffLineType(String line) {
    if (line.isEmpty) {
      return DiffLineType.context;
    }
    return parseDiffLines(line).first.type;
  }

  _DiffLineVisualStyle _resolveDiffVisualStyle(
    BuildContext context,
    DiffLineType lineType,
  ) {
    final brightness = Theme.of(context).brightness;
    switch (lineType) {
      case DiffLineType.add:
        return _DiffLineVisualStyle(
          textColor: brightness == Brightness.dark
              ? Colors.green.shade400
              : Colors.green.shade700,
          backgroundColor: brightness == Brightness.dark
              ? Colors.green.shade800.withValues(alpha: 0.45)
              : Colors.green.shade100,
        );
      case DiffLineType.remove:
        return _DiffLineVisualStyle(
          textColor: brightness == Brightness.dark
              ? Colors.red.shade400
              : Colors.red.shade700,
          backgroundColor: brightness == Brightness.dark
              ? Colors.red.shade800.withValues(alpha: 0.42)
              : Colors.red.shade100,
        );
      case DiffLineType.hunk:
        return _DiffLineVisualStyle(
          textColor: brightness == Brightness.dark
              ? Colors.amber.shade300
              : Colors.orange.shade800,
          backgroundColor: brightness == Brightness.dark
              ? Colors.amber.shade800.withValues(alpha: 0.38)
              : Colors.orange.shade100,
        );
      case DiffLineType.metadata:
        return _DiffLineVisualStyle(
          textColor: Theme.of(context).colorScheme.onSurfaceVariant,
        );
      case DiffLineType.context:
        return const _DiffLineVisualStyle();
    }
  }

  Widget _buildDiffLine(
    BuildContext context, {
    required int index,
    required String line,
  }) {
    final lineType = _resolveDiffLineType(line);
    final visualStyle = _resolveDiffVisualStyle(context, lineType);

    return Container(
      key: ValueKey<String>('${widget.lineKeyPrefix}_container_$index'),
      width: double.infinity,
      color: visualStyle.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Text(
        line,
        key: ValueKey<String>('${widget.lineKeyPrefix}_text_$index'),
        style:
            widget.textStyle?.copyWith(color: visualStyle.textColor) ??
            TextStyle(color: visualStyle.textColor, fontFamily: 'monospace'),
      ),
    );
  }

  /// Per-line diff rendering to ensure visible background colors.
  Widget _buildColorizedDiffContent(BuildContext context, String text) {
    final lines = text.split('\n');
    final maxVisibleLines = _expanded ? lines.length : widget.collapsedMaxLines;
    final visibleLines = lines.take(maxVisibleLines).toList(growable: false);
    final hasHiddenLines = lines.length > visibleLines.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < visibleLines.length; i++)
          _buildDiffLine(context, index: i, line: visibleLines[i]),
        if (!_expanded && hasHiddenLines)
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 2),
            child: Text(
              '...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDiff = _isDiffContent(widget.toolName, widget.text);
    final compactLayout = MediaQuery.sizeOf(context).width < 600;

    Widget contentWidget;

    if (isDiff) {
      // Diff should maintain visual semantics in both collapsed and expanded.
      contentWidget = _buildColorizedDiffContent(context, widget.text);
    } else {
      // Not diff — original behavior
      contentWidget = Text(
        widget.text,
        key: const ValueKey<String>('tool_content_text'),
        maxLines: _expanded ? null : widget.collapsedMaxLines,
        overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        style: widget.textStyle,
      );
    }

    if (!_canExpand) {
      return contentWidget;
    }

    final contentViewport = _expanded
        ? ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: _expandedToolViewportHeight(context),
            ),
            child: SingleChildScrollView(
              key: const ValueKey<String>('tool_content_expanded_scroll'),
              primary: false,
              child: contentWidget,
            ),
          )
        : contentWidget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        contentViewport,
        Align(
          alignment: Alignment.center,
          child: TextButton(
            key: const ValueKey<String>('tool_content_toggle_button'),
            onPressed: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            ),
            child: Text(
              _expanded
                  ? (compactLayout ? 'Less' : 'Show less')
                  : (compactLayout ? 'More' : 'Show more'),
              style:
                  widget.toggleTextStyle ??
                  Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
      ],
    );
  }
}
