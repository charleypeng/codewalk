import 'package:flutter/material.dart';
import 'package:flutter_mermaid/flutter_mermaid.dart';

/// Renders Mermaid diagram source code as a visual diagram.
///
/// Falls back to displaying the raw source in a styled code block when
/// the diagram cannot be parsed or rendered.
class MermaidDiagramWidget extends StatefulWidget {
  const MermaidDiagramWidget({
    super.key,
    required this.code,
    this.onCopySource,
  });

  /// The Mermaid diagram source text.
  final String code;

  /// Called when the user taps the copy source action.
  final VoidCallback? onCopySource;

  @override
  State<MermaidDiagramWidget> createState() => _MermaidDiagramWidgetState();
}

class _MermaidDiagramWidgetState extends State<MermaidDiagramWidget> {
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _hasError = false;
  }

  @override
  void didUpdateWidget(covariant MermaidDiagramWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code) {
      _hasError = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row with diagram type badge and actions
          _buildHeader(context, colorScheme),
          // Diagram or fallback content
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _hasError
                ? _buildFallbackCodeView(context, colorScheme)
                : _buildDiagram(context, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
      child: Row(
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            'Mermaid Diagram',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          if (widget.onCopySource != null)
            IconButton(
              icon: Icon(
                Icons.content_copy,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              onPressed: widget.onCopySource,
              tooltip: 'Copy source',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildDiagram(BuildContext context, ColorScheme colorScheme) {
    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 100, maxHeight: 400),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 200),
                child: MermaidDiagram(
                  code: widget.code,
                  style: _resolveMermaidStyle(
                    Theme.of(context).brightness,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (_) {
      // If MermaidDiagram fails during build, switch to fallback.
      // Use post-frame callback to avoid setState during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _hasError = true);
        }
      });
      return const SizedBox(
        width: double.infinity,
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }
  }

  Widget _buildFallbackCodeView(
      BuildContext context, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 400),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SelectableText(
          widget.code,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
        ),
      ),
    );
  }

  /// Resolves a mermaid theme style based on the app brightness.
  MermaidStyle _resolveMermaidStyle(Brightness brightness) {
    return brightness == Brightness.dark
        ? MermaidStyle.dark()
        : MermaidStyle.neutral();
  }
}
