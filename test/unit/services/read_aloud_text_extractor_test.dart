import 'package:codewalk/domain/entities/chat_message.dart';
import 'package:codewalk/presentation/services/tts/read_aloud_text_extractor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReadAloudTextExtractor', () {
    test('strips common markdown while preserving readable labels', () {
      final cleaned = ReadAloudTextExtractor.cleanMarkdown(
        '# Heading\n'
        '> quoted **bold** text\n'
        '- visit [CodeWalk](https://example.com)\n'
        '![Diagram](diagram.png) and `short_code`',
      );

      expect(
        cleaned,
        'Heading quoted bold text visit CodeWalk Diagram and short_code',
      );
    });

    test('omits fenced code blocks and markdown tables', () {
      final cleaned = ReadAloudTextExtractor.cleanMarkdown(
        'Before\n'
        '```dart\nvoid main() {}\n```\n'
        '| Name | Value |\n'
        '| --- | --- |\n'
        '| A | B |\n'
        'After',
      );

      expect(cleaned, 'Before After');
    });

    test('keeps prose with comparison-like angle brackets', () {
      final cleaned = ReadAloudTextExtractor.cleanMarkdown(
        'Use x < y > z but remove <strong>HTML</strong>.',
      );

      expect(cleaned, 'Use x < y > z but remove HTML.');
    });

    test('extracts text parts from assistant messages', () {
      final message = AssistantMessage(
        id: 'msg_1',
        sessionId: 'ses_1',
        time: DateTime(2026),
        parts: const <MessagePart>[
          TextPart(
            id: 'part_1',
            messageId: 'msg_1',
            sessionId: 'ses_1',
            text: 'Hello **world**',
          ),
        ],
      );

      expect(ReadAloudTextExtractor.extract(message), 'Hello world');
    });
  });
}
