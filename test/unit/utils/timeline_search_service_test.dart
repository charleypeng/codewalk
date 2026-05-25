import 'package:flutter_test/flutter_test.dart';
import 'package:codewalk/core/utils/timeline_search_service.dart';
import 'package:codewalk/domain/entities/chat_message.dart';

void main() {
  const service = TimelineSearchService();

  UserMessage userMessage(String id, List<MessagePart> parts) {
    return UserMessage(
      id: id,
      sessionId: 'session_1',
      time: DateTime(2026),
      parts: parts,
    );
  }

  TextPart textPart(String id, String text) {
    return TextPart(
      id: id,
      messageId: 'message_1',
      sessionId: 'session_1',
      text: text,
    );
  }

  ReasoningPart reasoningPart(String id, String text) {
    return ReasoningPart(
      id: id,
      messageId: 'message_1',
      sessionId: 'session_1',
      text: text,
    );
  }

  SubtaskPart subtaskPart(String id, String prompt, String description) {
    return SubtaskPart(
      id: id,
      messageId: 'message_1',
      sessionId: 'session_1',
      prompt: prompt,
      description: description,
      agent: 'build',
    );
  }

  group('TimelineSearchService', () {
    test('returns empty result for blank query', () {
      final result = service.search(
        messages: [
          userMessage('m1', [textPart('p1', 'hello')]),
        ],
        query: '   ',
      );

      expect(result, same(TimelineSearchResult.empty));
    });

    test('matches text case-insensitively and preserves message order', () {
      final result = service.search(
        messages: [
          userMessage('m1', [textPart('p1', 'Alpha beta alpha')]),
          userMessage('m2', [textPart('p2', 'nothing here')]),
          userMessage('m3', [textPart('p3', 'ALPHA')]),
        ],
        query: 'alpha',
      );

      expect(result.matches, [
        const TimelineSearchMatch(messageId: 'm1', matchCount: 2),
        const TimelineSearchMatch(messageId: 'm3', matchCount: 1),
      ]);
      expect(result.totalMatchCount, 3);
    });

    test('searches reasoning and subtask visible text', () {
      final result = service.search(
        messages: [
          userMessage('m1', [reasoningPart('r1', 'Planning deploy flow')]),
          userMessage('m2', [
            subtaskPart('s1', 'Deploy mobile build', 'Release checklist'),
          ]),
        ],
        query: 'deploy',
      );

      expect(result.matches, [
        const TimelineSearchMatch(messageId: 'm1', matchCount: 1),
        const TimelineSearchMatch(messageId: 'm2', matchCount: 1),
      ]);
    });
  });
}
