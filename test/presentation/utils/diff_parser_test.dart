import 'package:codewalk/presentation/utils/diff_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseDiffLines', () {
    test('distingue linhas + vs +++ (metadata)', () {
      const diff = '+added\n+++file.dart\n+another';
      final lines = parseDiffLines(diff);
      expect(lines[0].type, DiffLineType.add);
      expect(lines[1].type, DiffLineType.metadata);
      expect(lines[2].type, DiffLineType.add);
    });

    test('distingue linhas - vs --- (metadata)', () {
      const diff = '-removed\n---file.dart\n-another';
      final lines = parseDiffLines(diff);
      expect(lines[0].type, DiffLineType.remove);
      expect(lines[1].type, DiffLineType.metadata);
      expect(lines[2].type, DiffLineType.remove);
    });

    test('detecta hunk headers @@', () {
      const diff = '@@ -1,3 +1,4 @@\ncontext\n+added';
      final lines = parseDiffLines(diff);
      expect(lines[0].type, DiffLineType.hunk);
      expect(lines[1].type, DiffLineType.context);
      expect(lines[2].type, DiffLineType.add);
    });

    test('detecta metadata completa', () {
      const diff = '''diff --git a/file.dart b/file.dart
index abc123..def456 100644
--- a/file.dart
+++ b/file.dart''';
      final lines = parseDiffLines(diff);
      expect(lines[0].type, DiffLineType.metadata); // diff --git
      expect(lines[1].type, DiffLineType.metadata); // index
      expect(lines[2].type, DiffLineType.metadata); // ---
      expect(lines[3].type, DiffLineType.metadata); // +++
    });

    test('linhas de contexto sem marcadores', () {
      const diff = 'normal line\nanother line\n+added';
      final lines = parseDiffLines(diff);
      expect(lines[0].type, DiffLineType.context);
      expect(lines[1].type, DiffLineType.context);
      expect(lines[2].type, DiffLineType.add);
    });
  });

  group('isDiffFormat', () {
    test('detecta unified diff com 2+ marcadores', () {
      const diff = 'diff --git a/f b/f\n--- a/f\n+++ b/f';
      expect(isDiffFormat(diff), isTrue);
    });

    test('detecta diff com @@ marker', () {
      const diff = 'some text\n@@ -1,2 +1,3 @@\n--- a/file';
      expect(isDiffFormat(diff), isTrue);
    });

    test('rejeita texto normal', () {
      const text = 'Normal output\nwith lines\nno diff';
      expect(isDiffFormat(text), isFalse);
    });

    test('rejeita texto com apenas 1 marcador', () {
      const text = 'Output\n--- something\nbut not real diff';
      expect(isDiffFormat(text), isFalse);
    });

    test('verifica apenas primeiras 20 linhas', () {
      final lines = List.generate(25, (i) => 'line $i');
      lines[22] = 'diff --git a/f b/f';
      lines[23] = '--- a/f';
      final text = lines.join('\n');

      // Marcadores após linha 20 não devem ser detectados
      expect(isDiffFormat(text), isFalse);
    });
  });

  group('computeDiffLines', () {
    test('both empty returns metadata-only placeholder', () {
      final lines = computeDiffLines('', '', 'file.dart');
      expect(lines.length, 3);
      expect(lines[0].type, DiffLineType.metadata);
      expect(lines[0].content, '--- file.dart');
      expect(lines[1].type, DiffLineType.metadata);
      expect(lines[1].content, '+++ file.dart');
      expect(lines[2].type, DiffLineType.hunk);
    });

    test('new file (before empty) shows /dev/null header and all additions', () {
      final lines = computeDiffLines('', 'line1\nline2\nline3', 'new.dart');
      expect(lines[0].content, '--- /dev/null');
      expect(lines[1].content, '+++ new.dart');
      expect(lines[2].type, DiffLineType.hunk);
      expect(lines[2].content, contains('+1,3'));
      // All content lines are additions
      final addLines = lines.where((l) => l.type == DiffLineType.add).toList();
      expect(addLines.length, 3);
      expect(addLines[0].content, '+line1');
      expect(addLines[2].content, '+line3');
    });

    test('deleted file (after empty) shows /dev/null header and all removals', () {
      final lines = computeDiffLines('old1\nold2', '', 'gone.dart');
      expect(lines[0].content, '--- gone.dart');
      expect(lines[1].content, '+++ /dev/null');
      expect(lines[2].type, DiffLineType.hunk);
      final removeLines = lines.where((l) => l.type == DiffLineType.remove).toList();
      expect(removeLines.length, 2);
      expect(removeLines[0].content, '-old1');
    });

    test('identical content shows single context hunk', () {
      final lines = computeDiffLines('same\ncontent', 'same\ncontent', 'file.dart');
      expect(lines[0].type, DiffLineType.metadata);
      expect(lines[1].type, DiffLineType.metadata);
      expect(lines[2].type, DiffLineType.hunk);
      // All content lines are context
      final contextLines = lines.where((l) => l.type == DiffLineType.context).toList();
      expect(contextLines.length, 2);
      expect(contextLines[0].content, ' same');
    });

    test('multi-line diff with additions and removals', () {
      final lines = computeDiffLines(
        'unchanged\nold line\nunchanged2',
        'unchanged\nnew line\nunchanged2',
        'file.dart',
      );
      expect(lines[0].content, '--- file.dart');
      expect(lines[1].content, '+++ file.dart');
      // Must have at least one remove and one add
      expect(lines.any((l) => l.type == DiffLineType.remove), isTrue);
      expect(lines.any((l) => l.type == DiffLineType.add), isTrue);
      // Context lines present
      expect(lines.any((l) => l.type == DiffLineType.context), isTrue);
    });

    test('multi-hunk diff with distant changes', () {
      final before = List.generate(20, (i) => 'line $i');
      final after = List.from(before);
      after[2] = 'changed A';
      after[17] = 'changed B';
      final lines = computeDiffLines(before.join('\n'), after.join('\n'), 'multi.dart');
      // Should produce two hunks
      final hunks = lines.where((l) => l.type == DiffLineType.hunk).toList();
      expect(hunks.length, 2);
    });

    test('line ending normalization (CRLF treated as LF)', () {
      final lines = computeDiffLines('a\r\nb', 'a\nb\nc', 'file.dart');
      // Same first two lines, one addition
      expect(lines.any((l) => l.type == DiffLineType.add), isTrue);
      final addLines = lines.where((l) => l.type == DiffLineType.add).toList();
      expect(addLines.length, 1);
      expect(addLines[0].content, '+c');
    });

    test('trailing newline does not produce phantom empty line', () {
      // "line1\n" split should produce ["line1"], not ["line1", ""]
      final lines = computeDiffLines('line1\n', 'line1\nline2\n', 'file.dart');
      final addLines = lines.where((l) => l.type == DiffLineType.add).toList();
      expect(addLines.length, 1);
      expect(addLines[0].content, '+line2');
    });

    test('large-file guard triggers degenerative diff', () {
      // Create inputs that exceed 4M cells
      final bLines = List.generate(2500, (i) => 'before $i');
      final aLines = List.generate(2500, (i) => 'after $i');
      final lines = computeDiffLines(
        bLines.join('\n'),
        aLines.join('\n'),
        'big.dart',
      );
      // Degenerative diff: all before as remove, all after as add
      expect(lines[0].content, '--- big.dart');
      expect(lines[1].content, '+++ big.dart');
      expect(lines[2].type, DiffLineType.hunk);
      final removeLines = lines.where((l) => l.type == DiffLineType.remove).toList();
      final addLines = lines.where((l) => l.type == DiffLineType.add).toList();
      expect(removeLines.length, 2500);
      expect(addLines.length, 2500);
    });
  });
}
