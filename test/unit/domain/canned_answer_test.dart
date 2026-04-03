import 'package:codewalk/domain/entities/canned_answer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CannedAnswer serialization', () {
    test('serializes and deserializes sendAutomatically', () {
      const answer = CannedAnswer(
        id: 'canned-1',
        text: 'Ship it',
        sendAutomatically: true,
        updatedAtEpochMs: 123,
      );

      final json = answer.toJson();
      final restored = CannedAnswer.fromJson(json);

      expect(json['sendAutomatically'], isTrue);
      expect(restored?.sendAutomatically, isTrue);
    });

    test('defaults sendAutomatically to false for legacy JSON', () {
      final restored = CannedAnswer.fromJson(<String, dynamic>{
        'id': 'legacy-1',
        'text': 'Legacy quick reply',
        'insertMode': 'append',
        'scopeMode': 'global',
        'updatedAtEpochMs': 456,
      });

      expect(restored?.sendAutomatically, isFalse);
    });
  });
}
