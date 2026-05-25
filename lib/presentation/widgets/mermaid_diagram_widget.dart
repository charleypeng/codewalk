import 'package:flutter/material.dart';
import 'package:flutter_mermaid/flutter_mermaid.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/i18n/l10n_context.dart';
import '../theme/app_shapes.dart';

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
    final isCompact = MediaQuery.of(context).size.width < 600;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppShapes.borderMedium,
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, colorScheme),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _hasError
                ? _buildFallbackCodeView(context, colorScheme)
                : _buildDiagram(context, colorScheme, isCompact: isCompact),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
      child: Row(
        children: [
          Icon(
            Symbols.account_tree,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            l10n.mermaidDiagramLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          if (widget.onCopySource != null)
            IconButton(
              icon: Icon(
                Symbols.content_copy,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              onPressed: widget.onCopySource,
              tooltip: l10n.mermaidCopySourceTooltip,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildDiagram(
    BuildContext context,
    ColorScheme colorScheme, {
    required bool isCompact,
  }) {
    try {
      final maxHeight = isCompact ? 300.0 : 500.0;
      return ClipRRect(
        borderRadius: AppShapes.borderSmall,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: 100, maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: AppShapes.borderSmall,
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _hasError = true);
        }
      });
      return SizedBox(
        width: double.infinity,
        height: 100,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
        ),
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
        borderRadius: AppShapes.borderSmall,
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
