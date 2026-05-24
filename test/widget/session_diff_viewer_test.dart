import 'package:codewalk/domain/entities/chat_session.dart';
import 'package:codewalk/presentation/utils/diff_parser.dart';
import 'package:codewalk/presentation/widgets/session_diff_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../support/pump_localized_app.dart';

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
    return localizedMaterialApp(
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
    // Hunk header with @@ is rendered
    expect(find.textContaining('@@'), findsWidgets);
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

    await tester.tap(find.byKey(const ValueKey<String>('session_diff_tree_file_1')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey<String>('session_diff_preview_list_1_lib/second.dart'),
      ),
      findsOneWidget,
    );
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

  testWidgets('new file diff shows additions with line numbers', (
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

    // Hunk header is rendered
    expect(find.textContaining('@@'), findsWidgets);
    // Addition lines have a "+" prefix marker rendered separately
    expect(find.text('+'), findsWidgets);
  });

  testWidgets('deleted file diff shows removals with line numbers', (
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

    // Hunk header is rendered
    expect(find.textContaining('@@'), findsWidgets);
    // Removal lines have a "-" prefix marker
    expect(find.text('-'), findsWidgets);
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

    // Hunk header and context lines are rendered
    expect(find.textContaining('@@'), findsWidgets);
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

    // Hunk header with @@ is rendered
    expect(find.textContaining('@@'), findsWidgets);
    // Addition and removal prefix markers present
    expect(find.text('-'), findsWidgets);
    expect(find.text('+'), findsWidgets);
  });

  testWidgets('patch field renders server-provided unified diff directly', (
    WidgetTester tester,
  ) async {
    const patchDiff = SessionDiff(
      file: 'lib/patched.dart',
      before: '',
      after: '',
      additions: 1,
      deletions: 1,
      status: 'modified',
      patch: '--- a/lib/patched.dart\n+++ b/lib/patched.dart\n@@ -1,3 +1,4 @@\n void main() {\n- print(\'hello\');\n+ print(\'hello world\');\n }',
    );

    await tester.pumpWidget(
      wrap(
        const SessionDiffViewer(
          diffs: <SessionDiff>[patchDiff],
          compact: true,
          initiallyExpanded: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Hunk header is rendered
    expect(find.textContaining('@@ -1,3 +1,4 @@'), findsOneWidget);
    // Diff prefix markers for add/remove
    expect(find.text('-'), findsWidgets);
    expect(find.text('+'), findsWidgets);
  });

  testWidgets('patch field takes priority over before/after', (
    WidgetTester tester,
  ) async {
    const diffWithBoth = SessionDiff(
      file: 'lib/both.dart',
      before: 'old content',
      after: 'new content',
      additions: 1,
      deletions: 1,
      status: 'modified',
      patch: '--- a/lib/both.dart\n+++ b/lib/both.dart\n@@ -1 +1 @@\n-old content\n+new from patch',
    );

    await tester.pumpWidget(
      wrap(
        const SessionDiffViewer(
          diffs: <SessionDiff>[diffWithBoth],
          compact: true,
          initiallyExpanded: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Patch content wins — hunk header is rendered
    expect(find.textContaining('@@'), findsWidgets);
  });

  testWidgets('empty patch with empty before/after shows fallback', (
    WidgetTester tester,
  ) async {
    const emptyPatchDiff = SessionDiff(
      file: 'lib/nopatch.dart',
      before: '',
      after: '',
      additions: 3,
      deletions: 1,
      status: 'modified',
      patch: '',
    );

    await tester.pumpWidget(
      wrap(
        const SessionDiffViewer(
          diffs: <SessionDiff>[emptyPatchDiff],
          compact: true,
          initiallyExpanded: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Empty patch falls back to LCS with empty before/after → fallback UI
    expect(find.text('+3 lines added -1 lines removed'), findsOneWidget);
    expect(find.text('File content not captured by the server'), findsOneWidget);
  });

  testWidgets('view mode toggle switches between summary, unified, and split', (
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

    // Default is unified mode — preview list is shown
    expect(
      find.byKey(
        const ValueKey<String>('session_diff_preview_list_0_lib/main.dart'),
      ),
      findsOneWidget,
    );

    // Tap summary mode icon (use tooltip to avoid ambiguity with other icons)
    await tester.tap(find.byTooltip('Summary'));
    await tester.pumpAndSettle();

    // Summary mode shows stat badges instead of line-by-line diff
    expect(find.text('modified'), findsAtLeast(1));

    // Tap split mode icon
    await tester.tap(find.byTooltip('Split'));
    await tester.pumpAndSettle();

    // Split mode shows split diff list
    expect(
      find.byKey(
        const ValueKey<String>('session_diff_split_list_0_lib/main.dart'),
      ),
      findsOneWidget,
    );

    // Tap unified mode icon to go back
    await tester.tap(find.byTooltip('Unified'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey<String>('session_diff_preview_list_0_lib/main.dart'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('onFileTap callback fires when file path is tapped in summary', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    String? tappedPath;
    int? tappedLine;

    await tester.pumpWidget(
      wrap(
        SessionDiffViewer(
          diffs: const <SessionDiff>[sampleDiff],
          compact: false,
          onFileTap: (path, line) {
            tappedPath = path;
            tappedLine = line;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to summary mode (use tooltip to target the mode toggle)
    await tester.tap(find.byTooltip('Summary'));
    await tester.pumpAndSettle();

    // Tap the file path in summary
    await tester.tap(find.text('lib/main.dart').first);
    await tester.pumpAndSettle();

    expect(tappedPath, 'lib/main.dart');
    expect(tappedLine, isNull);
  });

  testWidgets('large diff collapses hunks exceeding threshold', (
    WidgetTester tester,
  ) async {
    // Build a patch with 25 content lines in a single hunk to exceed
    // kDefaultCollapseThreshold (20). Using a raw patch ensures the hunk
    // line count is deterministic regardless of LCS context trimming.
    final patchLines = <String>[
      '--- a/lib/large.dart',
      '+++ b/lib/large.dart',
      '@@ -1,25 +1,25 @@',
      for (var i = 1; i <= 24; i++) ' line $i',
      '-old line 25',
      '+new line 25',
    ];
    final largeDiff = SessionDiff(
      file: 'lib/large.dart',
      before: '',
      after: '',
      additions: 1,
      deletions: 1,
      status: 'modified',
      patch: patchLines.join('\n'),
    );

    await tester.pumpWidget(
      wrap(
        SessionDiffViewer(
          diffs: <SessionDiff>[largeDiff],
          compact: true,
          initiallyExpanded: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Large hunk should show collapsed indicator
    expect(find.textContaining('collapsed'), findsOneWidget);
  });

  testWidgets('tapping collapsed hunk expands it', (
    WidgetTester tester,
  ) async {
    final patchLines = <String>[
      '--- a/lib/large.dart',
      '+++ b/lib/large.dart',
      '@@ -1,25 +1,25 @@',
      for (var i = 1; i <= 24; i++) ' line $i',
      '-old line 25',
      '+new line 25',
    ];
    final largeDiff = SessionDiff(
      file: 'lib/large.dart',
      before: '',
      after: '',
      additions: 1,
      deletions: 1,
      status: 'modified',
      patch: patchLines.join('\n'),
    );

    await tester.pumpWidget(
      wrap(
        SessionDiffViewer(
          diffs: <SessionDiff>[largeDiff],
          compact: true,
          initiallyExpanded: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Hunk is collapsed — indicator visible
    expect(find.textContaining('collapsed'), findsOneWidget);

    // Tap the hunk header (contains @@ text) to expand
    await tester.tap(find.textContaining('@@').first);
    await tester.pumpAndSettle();

    // After expanding, the collapsed indicator should be gone
    expect(find.textContaining('collapsed'), findsNothing);
  });

  testWidgets('diff parser utilities work correctly', (
    WidgetTester tester,
  ) async {
    // Test annotateLineNumbers
    const lines = [
      DiffLine('--- a/file.dart', DiffLineType.metadata),
      DiffLine('+++ b/file.dart', DiffLineType.metadata),
      DiffLine('@@ -1,3 +1,4 @@', DiffLineType.hunk),
      DiffLine(' context', DiffLineType.context),
      DiffLine('-old', DiffLineType.remove),
      DiffLine('+new', DiffLineType.add),
    ];
    final annotated = annotateLineNumbers(lines);

    // Context line gets both line numbers
    expect(annotated[3].oldLineNo, 1);
    expect(annotated[3].newLineNo, 1);

    // Remove line gets only old line number
    expect(annotated[4].oldLineNo, 2);
    expect(annotated[4].newLineNo, isNull);

    // Add line gets only new line number
    expect(annotated[5].oldLineNo, isNull);
    expect(annotated[5].newLineNo, 2);

    // Test groupIntoHunks
    final hunks = groupIntoHunks(annotated);
    expect(hunks.length, 1);
    expect(hunks[0].lines.length, 3); // context + remove + add
    expect(hunks[0].oldStart, 1);
    expect(hunks[0].newStart, 1);
  });

  testWidgets('resolveDiffHighlightLanguage returns correct language', (
    WidgetTester tester,
  ) async {
    expect(resolveDiffHighlightLanguage('lib/main.dart'), 'dart');
    expect(resolveDiffHighlightLanguage('app.tsx'), 'typescript');
    expect(resolveDiffHighlightLanguage('style.css'), 'css');
    expect(resolveDiffHighlightLanguage('Dockerfile'), 'dockerfile');
    expect(resolveDiffHighlightLanguage('unknown.xyz'), 'plaintext');
  });
}
