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

    test('serializes and deserializes agentName', () {
      const answer = CannedAnswer(
        id: 'canned-agent',
        text: 'Use plan mode',
        agentName: 'plan',
        updatedAtEpochMs: 789,
      );

      final json = answer.toJson();
      final restored = CannedAnswer.fromJson(json);

      expect(json['agentName'], 'plan');
      expect(restored?.agentName, 'plan');
    });

    test('serializes and deserializes auto thinking mode', () {
      const answer = CannedAnswer(
        id: 'canned-auto-thinking',
        text: 'Use auto effort',
        thinkingMode: CannedAnswerThinkingMode.auto,
        thinkingVariantId: 'ignored',
        updatedAtEpochMs: 790,
      );

      final json = answer.toJson();
      final restored = CannedAnswer.fromJson(json);

      expect(json['thinkingMode'], 'auto');
      expect(json.containsKey('thinkingVariantId'), isFalse);
      expect(restored?.thinkingMode, CannedAnswerThinkingMode.auto);
      expect(restored?.thinkingVariantId, isNull);
    });

    test('serializes and deserializes variant thinking mode', () {
      const answer = CannedAnswer(
        id: 'canned-variant-thinking',
        text: 'Think harder',
        thinkingMode: CannedAnswerThinkingMode.variant,
        thinkingVariantId: 'high',
        updatedAtEpochMs: 791,
      );

      final json = answer.toJson();
      final restored = CannedAnswer.fromJson(json);

      expect(json['thinkingMode'], 'variant');
      expect(json['thinkingVariantId'], 'high');
      expect(restored?.thinkingMode, CannedAnswerThinkingMode.variant);
      expect(restored?.thinkingVariantId, 'high');
    });

    test('defaults selection overrides for legacy JSON', () {
      final restored = CannedAnswer.fromJson(<String, dynamic>{
        'id': 'legacy-selection',
        'text': 'Legacy quick reply',
        'insertMode': 'append',
        'scopeMode': 'global',
        'updatedAtEpochMs': 792,
      });

      expect(restored?.agentName, isNull);
      expect(restored?.thinkingMode, CannedAnswerThinkingMode.inherit);
      expect(restored?.thinkingVariantId, isNull);
    });

    test('falls back to inherit when variant mode has no variant id', () {
      final restored = CannedAnswer.fromJson(<String, dynamic>{
        'id': 'missing-variant',
        'text': 'Think somehow',
        'thinkingMode': 'variant',
        'updatedAtEpochMs': 793,
      });

      expect(restored?.thinkingMode, CannedAnswerThinkingMode.inherit);
      expect(restored?.thinkingVariantId, isNull);
    });
  });
}
