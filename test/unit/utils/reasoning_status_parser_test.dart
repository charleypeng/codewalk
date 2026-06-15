import 'package:codewalk/presentation/utils/reasoning_status_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseReasoningStatusLabel', () {
    test('accepts human-readable markdown status labels', () {
      expect(parseReasoningStatusLabel('**Thinking**'), 'Thinking');
      expect(parseReasoningStatusLabel('**OK**'), 'OK');
      expect(parseReasoningStatusLabel('**Pensando...**'), 'Pensando...');
      expect(parseReasoningStatusLabel('**正在思考...**'), '正在思考...');
    });

    test('rejects machine-flavored or invalid labels', () {
      expect(parseReasoningStatusLabel('**[Tt]hinking**'), isNull);
      expect(parseReasoningStatusLabel('**[Rr]eceiving tool call**'), isNull);
      expect(parseReasoningStatusLabel(r'**[a-z]\w+**'), isNull);
      expect(parseReasoningStatusLabel('**x**'), isNull);
      expect(parseReasoningStatusLabel('****'), isNull);
      expect(parseReasoningStatusLabel('**${'x' * 100}**'), isNull);
    });

    test('still identifies rejected markdown labels as status markers', () {
      expect(isReasoningStatusMarker('**[Tt]hinking**'), isTrue);
      expect(isReasoningStatusMarker('****'), isTrue);
      expect(isReasoningStatusMarker('plain reasoning content'), isFalse);
    });
  });
}
