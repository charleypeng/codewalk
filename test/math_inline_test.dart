import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:codewalk/presentation/utils/math_markdown.dart';
import 'package:codewalk/presentation/widgets/math_expression_widget.dart';

void main() {
  testWidgets('inline math renders via MarkdownBody without crash', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownBody(
            data: r'Hello $x^2$ world',
            inlineSyntaxes: [InlineMathSyntax()],
            blockSyntaxes: const [],
            builders: <String, MarkdownElementBuilder>{
              'inlineMath': InlineMathBuilder(),
            },
          ),
        ),
      ),
    );

    // Math widget should render
    expect(find.byType(MathExpressionWidget), findsOneWidget);
    // No layout errors
    expect(tester.takeException(), isNull);
  });

  testWidgets('inline math in standalone paragraph works', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownBody(
            data: r'$E = mc^2$',
            inlineSyntaxes: [InlineMathSyntax()],
            blockSyntaxes: const [],
            builders: <String, MarkdownElementBuilder>{
              'inlineMath': InlineMathBuilder(),
            },
          ),
        ),
      ),
    );

    // Standalone inline math should render
    expect(find.byType(MathExpressionWidget), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-math dollar pattern does not render math widget', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownBody(
            data: r'Price is $5',
            inlineSyntaxes: [InlineMathSyntax()],
            blockSyntaxes: const [],
            builders: <String, MarkdownElementBuilder>{
              'inlineMath': InlineMathBuilder(),
            },
          ),
        ),
      ),
    );

    // No math widget for currency
    expect(find.byType(MathExpressionWidget), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
