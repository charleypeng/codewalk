import 'package:codewalk/presentation/utils/chat_abort_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeAbortMessageForDisplay', () {
    test('maps abort-like technical message to friendly copy', () {
      expect(
        normalizeAbortMessageForDisplay('The operation was aborted.'),
        kChatAbortNoticeMessage,
      );
    });

    test('maps cancel-like error name to friendly copy', () {
      expect(
        normalizeAbortMessageForDisplay(
          'Request failed',
          name: 'MessageCanceledError',
        ),
        kChatAbortNoticeMessage,
      );
    });

    test('preserves non-abort errors', () {
      expect(
        normalizeAbortMessageForDisplay('Rate limit exceeded'),
        'Rate limit exceeded',
      );
    });
  });
}
