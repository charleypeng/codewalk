import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../widgets/math_expression_widget.dart';

/// LaTeX command tokens that must appear inside `$...$` or `$$...$$`
/// for the match to be treated as a math expression rather than currency
/// or a shell variable. At least one such token is required.
const _latexCommandPattern =
    r'(?:\\[a-zA-Z]+|[{}\^_~]|\\[\\|!><=])';

/// Inline math syntax: `$...$` (single-dollar, must contain LaTeX tokens).
///
/// Rejects currency patterns like `$5`, `$100`, and shell variables like
/// `$PATH` by requiring at least one LaTeX command token between the
/// delimiters. The markdown parser processes fenced code blocks (```)
/// as block elements before inline parsing, so math inside code blocks
/// is naturally excluded. Inline code (backtick-enclosed) also takes
/// priority over custom inline syntaxes.
class InlineMathSyntax extends md.InlineSyntax {
  InlineMathSyntax() : super(_pattern);

  // Group 1: expression between $ delimiters
  static const _pattern =
      r'(?<!\S)\$(?!\$)([^$\n]+?)(?<=\S)\$(?!\d)';

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final expression = match[1]!;
    if (!_looksLikeLatex(expression)) return false;
    final element = md.Element('inlineMath', <md.Node>[
      md.Text(expression),
    ]);
    parser.addNode(element);
    return true;
  }
}

/// Block math syntax: `$$...$$` on separate lines.
///
/// Matches a `$$` opening on its own line, captures everything until a
/// closing `$$`, and emits a `blockMath` element. This is a BlockSyntax
/// so it participates in the block parser before inline syntaxes run,
/// ensuring fenced code blocks take priority.
class BlockMathSyntax extends md.BlockSyntax {
  const BlockMathSyntax();

  @override
  RegExp get pattern => RegExp(r'^\s*\$\$\s*$');

  @override
  bool canParse(md.BlockParser parser) {
    if (!pattern.hasMatch(parser.current.content)) return false;
    // Peek ahead: there must be a closing $$ within reasonable distance
    for (var i = 1; i <= 50; i++) {
      final line = parser.peek(i);
      if (line == null) return false;
      if (RegExp(r'^\s*\$\$\s*$').hasMatch(line.content)) {
        return i >= 1; // at least one content line between $$ delimiters
      }
    }
    return false;
  }

  @override
  md.Node? parse(md.BlockParser parser) {
    final contentLines = <String>[];
    parser.advance(); // skip opening $$

    while (!parser.isDone) {
      final line = parser.current.content;
      if (RegExp(r'^\s*\$\$\s*$').hasMatch(line)) {
        parser.advance(); // skip closing $$
        break;
      }
      contentLines.add(line);
      parser.advance();
    }

    final expression = contentLines.join('\n').trim();
    if (expression.isEmpty) return null;

    return md.Element('blockMath', <md.Node>[md.Text(expression)]);
  }
}

/// Single-line block math syntax: `$$ E=mc^2 $$` on one line.
///
/// Handles the common pattern where both `$$` delimiters appear on the
/// same line, which BlockMathSyntax cannot match because it expects
/// `$$` on its own line.
class SingleLineBlockMathSyntax extends md.InlineSyntax {
  SingleLineBlockMathSyntax() : super(_pattern);

  // Group 1: expression between $$ delimiters
  static const _pattern = r'\$\$(.+?)\$\$';

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final expression = match[1]!;
    if (!_looksLikeLatex(expression)) return false;
    final element = md.Element('blockMath', <md.Node>[
      md.Text(expression),
    ]);
    parser.addNode(element);
    return true;
  }
}

/// Markdown element builder for `inlineMath` elements.
///
/// Renders inline math expressions using [MathExpressionWidget] in
/// text style (smaller, baseline-aligned).
class InlineMathBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final expression = element.textContent;
    if (expression.trim().isEmpty) return null;

    final textStyle = parentStyle ?? preferredStyle ??
        Theme.of(context).textTheme.bodyMedium ??
        const TextStyle();

    return MathExpressionWidget(
      expression: expression,
      isBlock: false,
      textStyle: textStyle,
    );
  }
}

/// Markdown element builder for `blockMath` elements.
///
/// Renders block math expressions using [MathExpressionWidget] in
/// display style (larger, centered).
class BlockMathBuilder extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final expression = element.textContent;
    if (expression.trim().isEmpty) return null;

    final textStyle = Theme.of(context).textTheme.bodyLarge ??
        const TextStyle();

    return MathExpressionWidget(
      expression: expression,
      isBlock: true,
      textStyle: textStyle,
    );
  }
}

/// Returns true if [text] contains at least one LaTeX command token,
/// indicating it is likely a math expression rather than currency or
/// a shell variable.
bool _looksLikeLatex(String text) {
  return RegExp(_latexCommandPattern).hasMatch(text);
}
