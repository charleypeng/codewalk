import 'package:codewalk/presentation/widgets/mermaid_diagram_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../support/pump_localized_app.dart';

void main() {
  group('MermaidDiagramWidget', () {
    testWidgets('renders with valid source and copy button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        localizedMaterialApp(
          home: Scaffold(
            body: MermaidDiagramWidget(
              code: 'graph TD\n  A[Start] --> B[End]',
              onCopySource: () {},
            ),
          ),
        ),
      );

      expect(find.text('Mermaid Diagram'), findsOneWidget);
      expect(find.byIcon(Symbols.content_copy), findsOneWidget);
    });

    testWidgets('shows fallback source when source is unparseable', (
      WidgetTester tester,
    ) async {
      const invalidSource = '{{{ totally invalid mermaid source }}}';
      await tester.pumpWidget(
        localizedMaterialApp(
          home: Scaffold(
            body: MermaidDiagramWidget(
              code: invalidSource,
              onCopySource: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header always visible.
      expect(find.text('Mermaid Diagram'), findsOneWidget);
      expect(find.byIcon(Symbols.content_copy), findsOneWidget);
      // Fallback must show the raw source text.
      expect(find.text(invalidSource), findsOneWidget);
    });

    testWidgets('renders empty source without crashing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        localizedMaterialApp(
          home: Scaffold(
            body: MermaidDiagramWidget(
              code: '',
              onCopySource: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Widget should render even with empty code; header always visible.
      expect(find.text('Mermaid Diagram'), findsOneWidget);
    });

    testWidgets('no copy button when onCopySource is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        localizedMaterialApp(
          home: Scaffold(
            body: MermaidDiagramWidget(
              code: 'graph TD\n  A --> B',
            ),
          ),
        ),
      );

      expect(find.text('Mermaid Diagram'), findsOneWidget);
      // No copy button should be rendered.
      expect(find.byIcon(Symbols.content_copy), findsNothing);
    });
  });
}
