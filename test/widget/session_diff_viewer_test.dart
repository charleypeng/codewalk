import 'package:codewalk/domain/entities/chat_session.dart';
import 'package:codewalk/presentation/widgets/session_diff_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sampleDiff = SessionDiff(
    file: 'lib/main.dart',
    before: 'old line',
    after: 'new line',
    additions: 1,
    deletions: 1,
    status: 'modified',
  );

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }

  testWidgets('compact viewer expands and renders diff preview', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const SessionDiffViewer(
          diffs: <SessionDiff>[sampleDiff],
          compact: true,
          initiallyExpanded: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Review changes'), findsOneWidget);
    expect(find.text('1 file changed'), findsOneWidget);

    await tester.tap(find.text('Review changes'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('session_diff_viewer_dropdown')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('session_diff_preview_list_0_lib/main.dart'),
      ),
      findsOneWidget,
    );
    expect(find.text('--- lib/main.dart'), findsOneWidget);
    expect(find.text('+new line'), findsOneWidget);
  });

  testWidgets('expanded viewer shows file summary and preview', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrap(
        const SessionDiffViewer(
          diffs: <SessionDiff>[sampleDiff],
          compact: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Review changes'), findsOneWidget);
    expect(find.text('lib/main.dart'), findsWidgets);
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('-1'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('session_diff_preview_list_0_lib/main.dart'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('switching files rebuilds the preview for the selected diff', (
    WidgetTester tester,
  ) async {
    const secondDiff = SessionDiff(
      file: 'lib/second.dart',
      before: 'before second',
      after: 'after second',
      additions: 1,
      deletions: 1,
      status: 'modified',
    );

    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrap(
        const SessionDiffViewer(
          diffs: <SessionDiff>[sampleDiff, secondDiff],
          compact: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey<String>('session_diff_preview_list_0_lib/main.dart'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('session_diff_file_1')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey<String>('session_diff_preview_list_1_lib/second.dart'),
      ),
      findsOneWidget,
    );
    expect(find.text('--- lib/second.dart'), findsOneWidget);
  });
}
