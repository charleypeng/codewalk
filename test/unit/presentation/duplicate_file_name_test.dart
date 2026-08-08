import 'package:codewalk/presentation/utils/duplicate_file_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('duplicateFileName', () {
    test('appends copy before the extension', () {
      expect(
        duplicateFileName('report.txt', <String>{'report.txt'}),
        'report copy.txt',
      );
    });

    test('numbers further copies instead of overwriting', () {
      expect(
        duplicateFileName('report.txt', <String>{
          'report.txt',
          'report copy.txt',
        }),
        'report copy 2.txt',
      );
      expect(
        duplicateFileName('report.txt', <String>{
          'report.txt',
          'report copy.txt',
          'report copy 2.txt',
        }),
        'report copy 3.txt',
      );
    });

    test('handles names without an extension', () {
      expect(
        duplicateFileName('Makefile', <String>{'Makefile'}),
        'Makefile copy',
      );
    });

    test('treats a leading dot as part of the name', () {
      expect(
        duplicateFileName('.gitignore', <String>{'.gitignore'}),
        '.gitignore copy',
      );
    });

    test('keeps only the last extension segment', () {
      expect(
        duplicateFileName('archive.tar.gz', <String>{'archive.tar.gz'}),
        'archive.tar copy.gz',
      );
    });

    test('never returns a name that already exists', () {
      final existing = <String>{
        'a.txt',
        'a copy.txt',
        'a copy 2.txt',
        'a copy 3.txt',
      };

      final result = duplicateFileName('a.txt', existing);

      expect(existing.contains(result), isFalse);
      expect(result, 'a copy 4.txt');
    });
  });
}
