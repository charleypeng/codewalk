import 'package:codewalk/presentation/utils/chat_event_property_extractors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extractEventSessionId prefers direct sessionID and trims', () {
    final value = extractEventSessionId(<String, dynamic>{
      'sessionID': '  ses_direct  ',
      'info': <String, dynamic>{'sessionID': 'ses_nested'},
    });

    expect(value, 'ses_direct');
  });

  test(
    'extractEventSessionId falls back to info.id when sessionID is absent',
    () {
      final value = extractEventSessionId(<String, dynamic>{
        'info': <String, dynamic>{'id': '  ses_from_info_id '},
      });

      expect(value, 'ses_from_info_id');
    },
  );

  test('extractEventDirectory falls back from direct to nested maps', () {
    expect(
      extractEventDirectory(<String, dynamic>{
        'directory': '',
        'info': <String, dynamic>{'directory': '  /tmp/from-info  '},
      }),
      '/tmp/from-info',
    );

    expect(
      extractEventDirectory(<String, dynamic>{
        'session': <String, dynamic>{'directory': '/tmp/from-session'},
      }),
      '/tmp/from-session',
    );

    expect(
      extractEventDirectory(<String, dynamic>{
        'project': <String, dynamic>{'directory': '/tmp/from-project'},
      }),
      '/tmp/from-project',
    );
  });

  test('extractors return null when payload has no usable values', () {
    final properties = <String, dynamic>{
      'sessionID': '   ',
      'info': <String, dynamic>{'sessionID': '', 'id': ' ', 'directory': ''},
    };

    expect(extractEventSessionId(properties), isNull);
    expect(extractEventDirectory(properties), isNull);
  });
}
