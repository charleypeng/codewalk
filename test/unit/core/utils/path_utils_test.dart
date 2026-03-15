import 'package:codewalk/core/utils/path_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('path_utils', () {
    test('normalizeOptionalFilePath trims separators and placeholders', () {
      expect(normalizeOptionalFilePath(' /repo/plain// '), '/repo/plain');
      expect(normalizeOptionalFilePath(r'\repo\plain\'), '/repo/plain');
      expect(normalizeOptionalFilePath('///'), '/');
      expect(normalizeOptionalFilePath('-'), isNull);
      expect(normalizeOptionalFilePath('   '), isNull);
    });

    test('areEquivalentFilePaths compares normalized paths', () {
      expect(areEquivalentFilePaths('/repo/plain/', '/repo/plain'), isTrue);
      expect(areEquivalentFilePaths(r'\repo\plain', '/repo/plain'), isTrue);
      expect(areEquivalentFilePaths('/repo/plain', '/repo/other'), isFalse);
    });
  });
}
