import 'package:codewalk/domain/entities/chat_session.dart';
import 'package:codewalk/presentation/widgets/session_diff_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

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
    // Real diff now: metadata header + hunk + context/remove/add lines
    expect(find.text('--- lib/main.dart'), findsOneWidget);
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

  testWidgets('empty before/after shows fallback widget with stats', (
    WidgetTester tester,
  ) async {
    const emptyDiff = SessionDiff(
      file: 'lib/empty.dart',
      before: '',
      after: '',
      additions: 5,
      deletions: 2,
      status: 'modified',
    );

    await tester.pumpWidget(
      wrap(
        const SessionDiffViewer(
          diffs: <SessionDiff>[emptyDiff],
          compact: true,
          initiallyExpanded: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Fallback shows filename and stats
    expect(find.text('lib/empty.dart'), findsWidgets);
    expect(find.text('+5 lines added -2 lines removed'), findsOneWidget);
    expect(find.text('File content not captured by the server'), findsOneWidget);
    expect(find.byIcon(Symbols.preview_off), findsOneWidget);
  });

  testWidgets('new file diff shows /dev/null header and additions', (
    WidgetTester tester,
  ) async {
    const newFileDiff = SessionDiff(
      file: 'lib/new_file.dart',
      before: '',
      after: 'class Foo {}\n',
      additions: 1,
      deletions: 0,
      status: 'added',
    );

    await tester.pumpWidget(
      wrap(
        const SessionDiffViewer(
          diffs: <SessionDiff>[newFileDiff],
          compact: true,
          initiallyExpanded: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // New file shows /dev/null header
    expect(find.text('--- /dev/null'), findsOneWidget);
    expect(find.text('+++ lib/new_file.dart'), findsOneWidget);
    // Content line is an addition
    expect(find.text('+class Foo {}'), findsOneWidget);
  });

  testWidgets('deleted file diff shows /dev/null header and removals', (
    WidgetTester tester,
  ) async {
    const deletedDiff = SessionDiff(
      file: 'lib/deleted.dart',
      before: 'removed content\n',
      after: '',
      additions: 0,
      deletions: 1,
      status: 'deleted',
    );

    await tester.pumpWidget(
      wrap(
        const SessionDiffViewer(
          diffs: <SessionDiff>[deletedDiff],
          compact: true,
          initiallyExpanded: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('--- lib/deleted.dart'), findsOneWidget);
    expect(find.text('+++ /dev/null'), findsOneWidget);
    expect(find.text('-removed content'), findsOneWidget);
  });

  testWidgets('identical content shows context lines', (
    WidgetTester tester,
  ) async {
    const identicalDiff = SessionDiff(
      file: 'lib/identical.dart',
      before: 'same\ncontent',
      after: 'same\ncontent',
      additions: 0,
      deletions: 0,
      status: 'modified',
    );

    await tester.pumpWidget(
      wrap(
        const SessionDiffViewer(
          diffs: <SessionDiff>[identicalDiff],
          compact: true,
          initiallyExpanded: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Context lines have space prefix
    expect(find.text(' same'), findsOneWidget);
    expect(find.text(' content'), findsOneWidget);
  });

  testWidgets('multi-line diff shows proper hunks with context', (
    WidgetTester tester,
  ) async {
    const multiDiff = SessionDiff(
      file: 'lib/multi.dart',
      before: 'line1\nline2\nline3\nline4\nline5',
      after: 'line1\nchanged2\nline3\nline4\nadded5',
      additions: 2,
      deletions: 1,
      status: 'modified',
    );

    await tester.pumpWidget(
      wrap(
        const SessionDiffViewer(
          diffs: <SessionDiff>[multiDiff],
          compact: true,
          initiallyExpanded: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Should have metadata, hunk header, and mixed content
    expect(find.text('--- lib/multi.dart'), findsOneWidget);
    expect(find.text('+++ lib/multi.dart'), findsOneWidget);
    expect(find.text('-line2'), findsOneWidget);
    expect(find.text('+changed2'), findsOneWidget);
    expect(find.text('+added5'), findsOneWidget);
  });
}
