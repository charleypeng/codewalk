import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import 'file_path_detector.dart';

/// Custom markdown inline syntax that detects file paths with optional
/// line:column suffixes and renders them as clickable spans.
///
/// The markdown parser processes fenced code blocks (```) as block elements
/// before reaching inline parsing, so paths inside code blocks are naturally
/// excluded. Inline code (backtick-enclosed) is also handled separately by
/// the markdown parser's code syntax, which takes priority over custom
/// inline syntaxes.
class FilePathSyntax extends md.InlineSyntax {
  FilePathSyntax()
      : super(
          // Match a file path with known extension, optionally followed by
          // :line and :line:col. The pattern requires at least one directory
          // separator (/) to avoid matching bare filenames like "main.dart"
          // which are too likely to be false positives in prose.
          //
          // Negative lookbehind (?<![/\w.:]) prevents matching paths that are
          // part of a URL (e.g. github.com/a/b.dart inside https://...).
          //
          // Group 1: path (with at least one /)
          // Group 2: optional :line
          // Group 3: optional :column
          r'(?<![/\w.:])(?:(?:\.{1,2}/|~/)?(?:[\w.\-]+/)+[\w.\-]+\.(?:'
          '${FilePathDetector.extensionPattern}'
          r'))(?::(\d+))?(?::(\d+))?',
        );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final fullPath = match[0]!;
    // Extract path portion by stripping :line:col suffixes
    final line = match[1] != null ? int.tryParse(match[1]!) : null;
    final col = match[2] != null ? int.tryParse(match[2]!) : null;

    // Compute the path portion by removing :line and :col from the full match
    var pathEnd = fullPath.length;
    if (col != null && line != null) {
      // Remove :line:col (two colons + digits)
      pathEnd = fullPath.lastIndexOf(RegExp(r':\d+:\d+$'));
    } else if (line != null) {
      // Remove :line (one colon + digits)
      pathEnd = fullPath.lastIndexOf(RegExp(r':\d+$'));
    }
    final path = fullPath.substring(0, pathEnd);

    final element = md.Element('filepath', <md.Node>[
      md.Text(fullPath),
    ])
      ..attributes['path'] = path
      ..attributes['line'] = line?.toString() ?? ''
      ..attributes['col'] = col?.toString() ?? '';

    parser.addNode(element);
    return true;
  }
}

/// Markdown element builder that renders <filepath> elements as clickable
/// tappable text spans with a distinct visual style.
///
/// When tapped, invokes [onFileTap] with the extracted path and optional
/// line number. The callback is responsible for opening the file viewer.
class FilePathBuilder extends MarkdownElementBuilder {
  FilePathBuilder({
    required this.onFileTap,
    this.themeColor,
  });

  /// Callback invoked when the file path is tapped.
  /// Receives (filePath, lineNumber?, columnNumber?).
  final void Function(String path, int? line, int? col) onFileTap;

  /// Optional override for the link color. When null, uses the theme's
  /// primary color.
  final Color? themeColor;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final path = element.attributes['path'] ?? '';
    final lineStr = element.attributes['line'] ?? '';
    final colStr = element.attributes['col'] ?? '';
    final line = lineStr.isNotEmpty ? int.tryParse(lineStr) : null;
    final col = colStr.isNotEmpty ? int.tryParse(colStr) : null;

    if (path.isEmpty) return null;

    final colorScheme = Theme.of(context).colorScheme;
    final linkColor = themeColor ?? colorScheme.primary;
    final baseStyle = parentStyle ?? preferredStyle ?? const TextStyle();

    final recognizer = TapGestureRecognizer()
      ..onTap = () => onFileTap(path, line, col);

    return Text.rich(
      TextSpan(
        text: element.textContent,
        style: baseStyle.copyWith(
          color: linkColor,
          decoration: TextDecoration.underline,
          decorationColor: linkColor.withValues(alpha: 0.5),
        ),
        recognizer: recognizer,
      ),
    );
  }
}
