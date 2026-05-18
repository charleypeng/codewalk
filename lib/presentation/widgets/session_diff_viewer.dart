import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domain/entities/chat_session.dart';
import '../utils/diff_parser.dart';

class SessionDiffViewer extends StatefulWidget {
  const SessionDiffViewer({
    super.key,
    required this.diffs,
    this.compact = false,
    this.initiallyExpanded = true,
    this.title = 'Review changes',
  });

  final List<SessionDiff> diffs;
  final bool compact;
  final bool initiallyExpanded;
  final String title;

  @override
  State<SessionDiffViewer> createState() => _SessionDiffViewerState();
}

class _SessionDiffViewerState extends State<SessionDiffViewer> {
  late bool _expanded;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant SessionDiffViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.diffs.isEmpty) {
      _selectedIndex = 0;
      return;
    }
    if (_selectedIndex >= widget.diffs.length) {
      _selectedIndex = widget.diffs.length - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.diffs.isEmpty) {
      return const SizedBox.shrink();
    }

    return widget.compact
        ? _buildCompactViewer(context)
        : _buildExpandedViewer(context);
  }

  Widget _buildCompactViewer(BuildContext context) {
    final diff = widget.diffs[_selectedIndex];
    return ExpansionTile(
      key: const ValueKey<String>('session_diff_viewer_compact_tile'),
      initiallyExpanded: _expanded,
      onExpansionChanged: (value) => setState(() => _expanded = value),
      leading: const Icon(Symbols.preview),
      title: Text(widget.title),
      subtitle: Text(
        '${widget.diffs.length} file${widget.diffs.length == 1 ? '' : 's'} changed',
      ),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      children: [
        _buildDiffFileDropdown(context),
        const SizedBox(height: 12),
        _buildDiffSummary(context, diff),
        const SizedBox(height: 12),
        SizedBox(height: 220, child: _buildDiffPreview(context, diff)),
      ],
    );
  }

  Widget _buildExpandedViewer(BuildContext context) {
    final diff = widget.diffs[_selectedIndex];
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSplit = constraints.maxWidth >= 560;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.preview, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  '${widget.diffs.length} file${widget.diffs.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (useSplit)
              SizedBox(
                height: 280,
                child: Row(
                  children: [
                    SizedBox(width: 180, child: _buildDiffFileList(context)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDiffSummary(context, diff),
                          const SizedBox(height: 12),
                          Expanded(child: _buildDiffPreview(context, diff)),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              _buildDiffFileDropdown(context),
              const SizedBox(height: 12),
              _buildDiffSummary(context, diff),
              const SizedBox(height: 12),
              SizedBox(height: 220, child: _buildDiffPreview(context, diff)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDiffFileDropdown(BuildContext context) {
    return DropdownButtonFormField<int>(
      key: const ValueKey<String>('session_diff_viewer_dropdown'),
      value: _selectedIndex,
      items: [
        for (var index = 0; index < widget.diffs.length; index += 1)
          DropdownMenuItem<int>(
            value: index,
            child: Text(
              widget.diffs[index].file,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() => _selectedIndex = value);
      },
      decoration: const InputDecoration(
        labelText: 'Changed file',
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _buildDiffFileList(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        itemCount: widget.diffs.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final diff = widget.diffs[index];
          final selected = index == _selectedIndex;
          return ListTile(
            key: ValueKey<String>('session_diff_file_$index'),
            dense: true,
            selected: selected,
            leading: const Icon(Symbols.description, size: 18),
            title: Text(
              diff.file,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('+${diff.additions}  -${diff.deletions}'),
            onTap: () => setState(() => _selectedIndex = index),
          );
        },
      ),
    );
  }

  Widget _buildDiffSummary(BuildContext context, SessionDiff diff) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildSummaryChip(context, Symbols.description, diff.file),
        _buildSummaryChip(context, Symbols.add, '+${diff.additions}'),
        _buildSummaryChip(context, Symbols.remove, '-${diff.deletions}'),
        if ((diff.status ?? '').trim().isNotEmpty)
          _buildSummaryChip(context, Symbols.info, diff.status!.trim()),
      ],
    );
  }

  Widget _buildSummaryChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _buildDiffPreview(BuildContext context, SessionDiff diff) {
  final lines = computeDiffLines(diff.before, diff.after, diff.file);

  // Both before/after were empty — show fallback instead of phantom diff
  if (lines.length <= 3 &&
      lines.every((l) => l.type == DiffLineType.metadata || l.type == DiffLineType.hunk)) {
    return _buildEmptyContentFallback(context, diff);
  }

  return DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(12),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ListView.builder(
        key: ValueKey<String>(
          'session_diff_preview_list_${_selectedIndex}_${diff.file}',
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: lines.length,
        itemBuilder: (context, index) {
          final line = lines[index];
          final style = _lineStyle(context, line.type);
          return Container(
            width: double.infinity,
            color: style.backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: Text(
              line.content,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: style.textColor,
              ),
            ),
          );
        },
      ),
    ),
  );
  }

  /// Fallback widget when server provides no file content (empty before/after).
  Widget _buildEmptyContentFallback(BuildContext context, SessionDiff diff) {
  final theme = Theme.of(context);
  return DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: theme.dividerColor),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.preview_off, size: 32, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            diff.file,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
'+${diff.additions} lines added -${diff.deletions} lines removed',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'File content not captured by the server',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
  }

  _DiffLineStyle _lineStyle(BuildContext context, DiffLineType type) {
    final brightness = Theme.of(context).brightness;
    return switch (type) {
      DiffLineType.add => _DiffLineStyle(
        textColor: brightness == Brightness.dark
            ? Colors.green.shade300
            : Colors.green.shade700,
        backgroundColor: brightness == Brightness.dark
            ? Colors.green.shade900.withValues(alpha: 0.28)
            : Colors.green.shade50,
      ),
      DiffLineType.remove => _DiffLineStyle(
        textColor: brightness == Brightness.dark
            ? Colors.red.shade300
            : Colors.red.shade700,
        backgroundColor: brightness == Brightness.dark
            ? Colors.red.shade900.withValues(alpha: 0.28)
            : Colors.red.shade50,
      ),
      DiffLineType.hunk => _DiffLineStyle(
        textColor: brightness == Brightness.dark
            ? Colors.amber.shade300
            : Colors.orange.shade800,
        backgroundColor: brightness == Brightness.dark
            ? Colors.amber.shade900.withValues(alpha: 0.22)
            : Colors.orange.shade50,
      ),
      DiffLineType.metadata => _DiffLineStyle(
        textColor: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      DiffLineType.context => _DiffLineStyle(
        textColor: Theme.of(context).colorScheme.onSurface,
      ),
    };
  }
}

class _DiffLineStyle {
  const _DiffLineStyle({required this.textColor, this.backgroundColor});

  final Color textColor;
  final Color? backgroundColor;
}
