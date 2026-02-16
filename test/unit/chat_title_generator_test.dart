import 'dart:convert';

import 'package:codewalk/presentation/services/chat_title_generator.dart';
import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper to build a message envelope matching the real API format:
/// `{ "info": { "role": role, "time": { "completed": ms } }, "parts": [...] }`
Map<String, dynamic> _envelope({
  required String role,
  bool completed = false,
  List<Map<String, dynamic>> parts = const [],
}) {
  return <String, dynamic>{
    'info': <String, dynamic>{
      'role': role,
      'time': <String, dynamic>{
        'created': 1700000000000,
        if (completed) 'completed': 1700000001000,
      },
    },
    'parts': parts,
  };
}

Map<String, dynamic> _textPart(String text) {
  return <String, dynamic>{'type': 'text', 'text': text};
}

void main() {
  group('OpenCodeTitleGenerator', () {
    late Dio dio;
    late _MockDioAdapter adapter;
    late OpenCodeTitleGenerator generator;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:4096'));
      adapter = _MockDioAdapter();
      dio.httpClientAdapter = adapter;
      generator = OpenCodeTitleGenerator(dio: dio);
    });

    tearDown(() {
      ChatTitleGenerator.ephemeralSessionIds.clear();
    });

    test('returns null for empty messages', () async {
      final result = await generator.generateTitle([]);
      expect(result, isNull);
    });

    test('generates title from successful polling', () async {
      adapter.enqueue([
        // POST /session
        _MockResponse(200, <String, dynamic>{'id': 'ses_temp_1'}),
        // POST /session/ses_temp_1/message
        _MockResponse(200, <String, dynamic>{'id': 'msg_1'}),
        // GET /session/ses_temp_1/message (poll 1 - not ready)
        _MockResponse(200, <dynamic>[
          _envelope(
            role: 'user',
            parts: [_textPart('hello')],
          ),
        ]),
        // GET /session/ses_temp_1/message (poll 2 - ready)
        _MockResponse(200, <dynamic>[
          _envelope(role: 'user', parts: [_textPart('hello')]),
          _envelope(
            role: 'assistant',
            completed: true,
            parts: [_textPart('Greeting Conversation')],
          ),
        ]),
        // DELETE /session/ses_temp_1
        _MockResponse(200, null),
      ]);

      final result = await generator.generateTitle([
        const ChatTitleGeneratorMessage(role: 'user', text: 'Hello there!'),
        const ChatTitleGeneratorMessage(
          role: 'assistant',
          text: 'Hi! How can I help?',
        ),
      ]);

      expect(result, equals('Greeting Conversation'));
    });

    test('normalizes quoted title', () async {
      adapter.enqueue([
        _MockResponse(200, <String, dynamic>{'id': 'ses_2'}),
        _MockResponse(200, <String, dynamic>{'id': 'msg_2'}),
        _MockResponse(200, <dynamic>[
          _envelope(
            role: 'assistant',
            completed: true,
            parts: [_textPart('"Quoted Title Here"')],
          ),
        ]),
        _MockResponse(200, null),
      ]);

      final result = await generator.generateTitle([
        const ChatTitleGeneratorMessage(role: 'user', text: 'test'),
      ]);
      expect(result, equals('Quoted Title Here'));
    });

    test('truncates title to 80 characters', () async {
      final longTitle = 'A' * 100;
      adapter.enqueue([
        _MockResponse(200, <String, dynamic>{'id': 'ses_3'}),
        _MockResponse(200, <String, dynamic>{'id': 'msg_3'}),
        _MockResponse(200, <dynamic>[
          _envelope(
            role: 'assistant',
            completed: true,
            parts: [_textPart(longTitle)],
          ),
        ]),
        _MockResponse(200, null),
      ]);

      final result = await generator.generateTitle([
        const ChatTitleGeneratorMessage(role: 'user', text: 'test'),
      ]);
      expect(result, hasLength(80));
    });

    test('returns null when session creation fails', () async {
      adapter.enqueue([
        _MockResponse(500, 'Internal server error', isError: true),
      ]);

      final result = await generator.generateTitle([
        const ChatTitleGeneratorMessage(role: 'user', text: 'test'),
      ]);
      expect(result, isNull);
    });

    test('returns null when session id is missing', () async {
      adapter.enqueue([
        _MockResponse(200, <String, dynamic>{}),
      ]);

      final result = await generator.generateTitle([
        const ChatTitleGeneratorMessage(role: 'user', text: 'test'),
      ]);
      expect(result, isNull);
    });

    test('cleans up session even on error', () async {
      adapter.enqueue([
        _MockResponse(200, <String, dynamic>{'id': 'ses_cleanup'}),
        _MockResponse(500, 'error', isError: true),
        // DELETE should still be called
        _MockResponse(200, null),
      ]);

      final result = await generator.generateTitle([
        const ChatTitleGeneratorMessage(role: 'user', text: 'test'),
      ]);
      expect(result, isNull);
      // Verify delete was attempted (adapter consumed 3 responses)
      expect(adapter.callCount, equals(3));
    });

    test('collapses whitespace in title', () async {
      adapter.enqueue([
        _MockResponse(200, <String, dynamic>{'id': 'ses_ws'}),
        _MockResponse(200, <String, dynamic>{'id': 'msg_ws'}),
        _MockResponse(200, <dynamic>[
          _envelope(
            role: 'assistant',
            completed: true,
            parts: [_textPart('  Hello   World  \n Test  ')],
          ),
        ]),
        _MockResponse(200, null),
      ]);

      final result = await generator.generateTitle([
        const ChatTitleGeneratorMessage(role: 'user', text: 'test'),
      ]);
      expect(result, equals('Hello World Test'));
    });

    test('skips incomplete assistant messages without completedTime', () async {
      adapter.enqueue([
        _MockResponse(200, <String, dynamic>{'id': 'ses_inc'}),
        _MockResponse(200, <String, dynamic>{'id': 'msg_inc'}),
        // Poll 1: assistant without completed time
        _MockResponse(200, <dynamic>[
          _envelope(
            role: 'assistant',
            parts: [_textPart('partial...')],
          ),
        ]),
        // Poll 2: assistant with completed time
        _MockResponse(200, <dynamic>[
          _envelope(
            role: 'assistant',
            completed: true,
            parts: [_textPart('Final Title')],
          ),
        ]),
        _MockResponse(200, null),
      ]);

      final result = await generator.generateTitle([
        const ChatTitleGeneratorMessage(role: 'user', text: 'test'),
      ]);
      expect(result, equals('Final Title'));
    });

    test('message POST sends agent and noReply but no model field', () async {
      adapter.enqueue([
        _MockResponse(200, <String, dynamic>{'id': 'ses_payload'}),
        _MockResponse(200, <String, dynamic>{'id': 'msg_payload'}),
        _MockResponse(200, <dynamic>[
          _envelope(
            role: 'assistant',
            completed: true,
            parts: [_textPart('Title')],
          ),
        ]),
        _MockResponse(200, null),
      ]);

      await generator.generateTitle([
        const ChatTitleGeneratorMessage(role: 'user', text: 'test'),
      ]);

      // Call #1 = POST /session, Call #2 = POST /session/{id}/message
      final messageRequest = adapter.capturedRequests[1];
      expect(messageRequest.path, contains('/session/ses_payload/message'));
      expect(messageRequest.method, equals('POST'));

      final body = messageRequest.data as Map<String, dynamic>;
      expect(body['agent'], equals('title'));
      expect(body['noReply'], isFalse);
      expect(body.containsKey('model'), isFalse);
      expect(body['parts'], isList);
    });

    test('session creation uses ephemeral title', () async {
      adapter.enqueue([
        _MockResponse(200, <String, dynamic>{'id': 'ses_title_check'}),
        _MockResponse(200, <String, dynamic>{'id': 'msg_tc'}),
        _MockResponse(200, <dynamic>[
          _envelope(
            role: 'assistant',
            completed: true,
            parts: [_textPart('Title')],
          ),
        ]),
        _MockResponse(200, null),
      ]);

      await generator.generateTitle([
        const ChatTitleGeneratorMessage(role: 'user', text: 'test'),
      ]);

      // Call #0 = POST /session
      final sessionRequest = adapter.capturedRequests[0];
      final body = sessionRequest.data as Map<String, dynamic>;
      expect(body['title'], equals(ChatTitleGenerator.ephemeralSessionTitle));
    });

    test('ephemeralSessionIds retains ID after completion for trailing events',
        () {
      fakeAsync((async) {
        adapter.enqueue([
          _MockResponse(200, <String, dynamic>{'id': 'ses_delay'}),
          _MockResponse(200, <String, dynamic>{'id': 'msg_delay'}),
          _MockResponse(200, <dynamic>[
            _envelope(
              role: 'assistant',
              completed: true,
              parts: [_textPart('Title')],
            ),
          ]),
          _MockResponse(200, null),
        ]);

        late final Future<String?> future;
        future = generator.generateTitle([
          const ChatTitleGeneratorMessage(role: 'user', text: 'test'),
        ]);

        // Flush microtasks and timers for polling
        async.elapse(const Duration(seconds: 2));

        future.then((_) {
          // Immediately after completion, ID should still be in the set
          expect(
            ChatTitleGenerator.ephemeralSessionIds.contains('ses_delay'),
            isTrue,
            reason: 'ID should remain in set to filter trailing SSE events',
          );
        });

        async.elapse(const Duration(seconds: 1));

        // After 5 seconds total, the delayed removal should fire
        async.elapse(const Duration(seconds: 5));
        expect(
          ChatTitleGenerator.ephemeralSessionIds.contains('ses_delay'),
          isFalse,
          reason: 'ID should be removed after the 5s grace period',
        );
      });
    });

    test('ephemeralSessionTitle constant has expected value', () {
      expect(
        ChatTitleGenerator.ephemeralSessionTitle,
        equals('_title_gen'),
      );
    });
  });
}

class _MockResponse {
  _MockResponse(this.statusCode, this.data, {this.isError = false});
  final int statusCode;
  final dynamic data;
  final bool isError;
}

class _MockDioAdapter implements HttpClientAdapter {
  final List<_MockResponse> _responses = <_MockResponse>[];
  final List<RequestOptions> capturedRequests = <RequestOptions>[];
  int callCount = 0;

  void enqueue(List<_MockResponse> items) {
    _responses.addAll(items);
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    capturedRequests.add(options);

    if (callCount >= _responses.length) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'No more mock responses (call #$callCount)',
      );
    }

    final mock = _responses[callCount];
    callCount += 1;

    if (mock.isError) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: mock.statusCode,
          data: mock.data,
        ),
      );
    }

    final encoded = _encode(mock.data);
    return ResponseBody.fromString(
      encoded,
      mock.statusCode,
      headers: <String, List<String>>{
        'content-type': <String>['application/json'],
      },
    );
  }

  String _encode(dynamic data) {
    if (data == null) return '';
    if (data is String) return data;
    return jsonEncode(data);
  }

  @override
  void close({bool force = false}) {}
}
