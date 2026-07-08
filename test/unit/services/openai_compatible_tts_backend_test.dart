import 'dart:convert';

import 'package:codewalk/presentation/services/tts/openai_compatible_tts_backend.dart';
import 'package:codewalk/presentation/services/tts/tts_backend.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockBinaryResponse {
  _MockBinaryResponse(this.statusCode, this.bytes);

  final int statusCode;
  final List<int> bytes;
}

class _MockBinaryDioAdapter implements HttpClientAdapter {
  final List<_MockBinaryResponse> responses = <_MockBinaryResponse>[];
  final List<RequestOptions> capturedRequests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    capturedRequests.add(options);
    final response = responses.removeAt(0);
    return ResponseBody.fromBytes(
      response.bytes,
      response.statusCode,
      headers: <String, List<String>>{
        'content-type': <String>['audio/mpeg'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('OpenAiCompatibleTtsBackend', () {
    test('maps CodeWalk rate to OpenAI-compatible speed', () {
      expect(openAiSpeedFromReadAloudRate(0.0), 0.5);
      expect(openAiSpeedFromReadAloudRate(0.5), 1.25);
      expect(openAiSpeedFromReadAloudRate(1.0), 2.0);
      expect(openAiSpeedFromReadAloudRate(2.0), 2.0);
    });

    test('normalizes speech endpoint and audio mime type', () {
      expect(
        speechEndpointForOpenAiCompatible('https://tts.example.com/v1///'),
        'https://tts.example.com/v1/audio/speech',
      );
      expect(mimeTypeForOpenAiAudioFormat('wav'), 'audio/wav');
      expect(mimeTypeForOpenAiAudioFormat('mp3'), 'audio/mpeg');
    });

    test('throws missing key before making request', () async {
      final adapter = _MockBinaryDioAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final backend = OpenAiCompatibleTtsBackend(dio: dio);

      expect(
        () => backend.speakOrSynthesize(
          const TtsSynthesisRequest(text: 'Hello', rate: 0.5, pitch: 1.0),
          const TtsBackendCallbacks(),
        ),
        throwsA(
          isA<TtsBackendException>().having(
            (error) => error.kind,
            'kind',
            TtsBackendErrorKind.missingApiKey,
          ),
        ),
      );
      expect(adapter.capturedRequests, isEmpty);
    });

    test(
      'posts OpenAI-compatible speech request and returns audio bytes',
      () async {
        final adapter = _MockBinaryDioAdapter()
          ..responses.add(_MockBinaryResponse(200, <int>[1, 2, 3]));
        final dio = Dio()..httpClientAdapter = adapter;
        final backend = OpenAiCompatibleTtsBackend(dio: dio);

        final result = await backend.speakOrSynthesize(
          const TtsSynthesisRequest(
            text: 'Hello world',
            rate: 0.5,
            pitch: 1.0,
            apiKey: 'sk-test',
            baseUrl: 'https://tts.example.com/v1///',
            model: 'tts-1',
            voiceId: 'coral',
            responseFormat: 'mp3',
          ),
          const TtsBackendCallbacks(),
        );

        expect(result, isA<GeneratedTtsAudio>());
        final audio = result as GeneratedTtsAudio;
        expect(audio.bytes, orderedEquals(<int>[1, 2, 3]));
        expect(audio.mimeType, 'audio/mpeg');

        final request = adapter.capturedRequests.single;
        expect(
          request.uri.toString(),
          'https://tts.example.com/v1/audio/speech',
        );
        expect(request.headers['Authorization'], 'Bearer sk-test');
        expect(request.headers['Accept'], 'audio/mpeg');
        final body = request.data as Map<String, dynamic>;
        expect(body['model'], 'tts-1');
        expect(body['input'], 'Hello world');
        expect(body['voice'], 'coral');
        expect(body['response_format'], 'mp3');
        expect(body['speed'], 1.25);
        expect(jsonEncode(body), isNot(contains('sk-test')));
      },
    );

    test('maps provider status errors', () async {
      final adapter = _MockBinaryDioAdapter()
        ..responses.addAll(<_MockBinaryResponse>[
          _MockBinaryResponse(401, <int>[]),
          _MockBinaryResponse(429, <int>[]),
          _MockBinaryResponse(500, <int>[]),
        ]);
      final dio = Dio()..httpClientAdapter = adapter;
      final backend = OpenAiCompatibleTtsBackend(dio: dio);

      Future<TtsBackendErrorKind> failOnce() async {
        try {
          await backend.speakOrSynthesize(
            const TtsSynthesisRequest(
              text: 'Hello',
              rate: 0.5,
              pitch: 1.0,
              apiKey: 'sk-test',
            ),
            const TtsBackendCallbacks(),
          );
        } on TtsBackendException catch (error) {
          return error.kind;
        }
        fail('Expected backend exception');
      }

      expect(await failOnce(), TtsBackendErrorKind.invalidApiKey);
      expect(await failOnce(), TtsBackendErrorKind.rateLimitedOrQuota);
      expect(await failOnce(), TtsBackendErrorKind.providerUnavailable);
    });
  });
}
