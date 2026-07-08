import 'dart:async';

import 'package:codewalk/presentation/services/tts/edge_experimental_tts_backend.dart';
import 'package:codewalk/presentation/services/tts/edge_tts_protocol.dart';
import 'package:codewalk/presentation/services/tts/edge_tts_websocket.dart';
import 'package:codewalk/presentation/services/tts/tts_backend.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEdgeTtsConnection implements EdgeTtsWebSocketConnection {
  final StreamController<dynamic> _controller = StreamController<dynamic>();
  final List<String> sentTexts = <String>[];
  bool closed = false;

  @override
  Future<void> get ready async {}

  @override
  Stream<dynamic> get stream => _controller.stream;

  @override
  void sendText(String data) {
    sentTexts.add(data);
  }

  @override
  Future<void> close() async {
    closed = true;
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  void add(dynamic value) {
    _controller.add(value);
  }
}

class _IdSequence {
  _IdSequence(this.values);

  int _index = 0;
  final List<String> values;

  String next() => values[_index++];
}

void main() {
  group('EdgeExperimentalTtsBackend', () {
    test('parses Edge voice catalog entries', () {
      final voices = parseEdgeTtsVoices(<Map<String, String>>[
        <String, String>{
          'ShortName': 'en-US-AriaNeural',
          'FriendlyName': 'Microsoft Aria Online',
          'Locale': 'en-US',
          'Gender': 'Female',
        },
      ]);

      expect(voices, hasLength(1));
      expect(voices.single.id, 'en-US-AriaNeural');
      expect(voices.single.locale, 'en-US');
      expect(voices.single.label, 'Microsoft Aria Online (en-US)');
      expect(voices.single.providerMetadata['gender'], 'Female');
    });

    test('builds escaped Edge SSML envelope', () {
      final ssml = buildEdgeTtsSsml(
        text: 'Hello <world> & "friends"',
        voice: 'en-US-AriaNeural',
      );

      expect(ssml, contains("<voice name='en-US-AriaNeural'>"));
      expect(ssml, contains('Hello &lt;world&gt; &amp; &quot;friends&quot;'));
      expect(ssml, contains("<prosody pitch='+0Hz' rate='+0%' volume='+0%'>"));
    });

    test(
      'direct synthesis returns generated mp3 audio from websocket frames',
      () async {
        final connection = _FakeEdgeTtsConnection();
        late Uri capturedUri;
        final ids = _IdSequence(<String>[
          '11111111111111111111111111111111',
          '22222222222222222222222222222222',
        ]);
        final backend = EdgeExperimentalTtsBackend(
          connector: (uri) {
            capturedUri = uri;
            return connection;
          },
          nowProvider: () => DateTime.utc(2026, 7, 8, 16),
          idProvider: ids.next,
        );

        expect(await backend.isAvailable, isTrue);

        final resultFuture = backend.speakOrSynthesize(
          const TtsSynthesisRequest(text: 'Hello Edge', rate: 0.5, pitch: 1.0),
          const TtsBackendCallbacks(),
        );
        await Future<void>.delayed(Duration.zero);

        expect(
          capturedUri.queryParameters['TrustedClientToken'],
          kEdgeTtsTrustedClientToken,
        );
        expect(
          capturedUri.queryParameters['ConnectionId'],
          '11111111111111111111111111111111',
        );
        expect(connection.sentTexts, hasLength(2));
        expect(connection.sentTexts.first, contains('Path:speech.config\r\n'));
        expect(connection.sentTexts.last, contains('Path:ssml\r\n'));
        expect(connection.sentTexts.last, contains(kDefaultEdgeTtsVoice));

        connection.add(
          buildEdgeTtsBinaryFrameForTest(
            headers: const <String, String>{
              'Path': 'audio',
              'Content-Type': kEdgeTtsAudioMimeType,
            },
            audioBytes: const <int>[1, 2, 3],
          ),
        );
        connection.add('Path:turn.end\r\n\r\n{}');

        final result = await resultFuture;
        expect(result, isA<GeneratedTtsAudio>());
        final audio = result as GeneratedTtsAudio;
        expect(audio.mimeType, kEdgeTtsAudioMimeType);
        expect(audio.bytes, orderedEquals(<int>[1, 2, 3]));
        expect(connection.closed, isTrue);
      },
    );

    test('maps empty Edge audio response to provider unavailable', () async {
      final connection = _FakeEdgeTtsConnection();
      final ids = _IdSequence(<String>[
        '11111111111111111111111111111111',
        '22222222222222222222222222222222',
      ]);
      final backend = EdgeExperimentalTtsBackend(
        connector: (_) => connection,
        idProvider: ids.next,
      );

      final resultFuture = backend.speakOrSynthesize(
        const TtsSynthesisRequest(text: 'Hello Edge', rate: 0.5, pitch: 1.0),
        const TtsBackendCallbacks(),
      );
      await Future<void>.delayed(Duration.zero);
      connection.add('Path:turn.end\r\n\r\n{}');

      await expectLater(
        resultFuture,
        throwsA(
          isA<TtsBackendException>().having(
            (error) => error.kind,
            'kind',
            TtsBackendErrorKind.providerUnavailable,
          ),
        ),
      );
    });

    test(
      'rejects partial audio when Edge stream ends before turn end',
      () async {
        final connection = _FakeEdgeTtsConnection();
        final ids = _IdSequence(<String>[
          '11111111111111111111111111111111',
          '22222222222222222222222222222222',
        ]);
        final backend = EdgeExperimentalTtsBackend(
          connector: (_) => connection,
          idProvider: ids.next,
        );

        final resultFuture = backend.speakOrSynthesize(
          const TtsSynthesisRequest(text: 'Hello Edge', rate: 0.5, pitch: 1.0),
          const TtsBackendCallbacks(),
        );
        await Future<void>.delayed(Duration.zero);
        connection.add(
          buildEdgeTtsBinaryFrameForTest(
            headers: const <String, String>{
              'Path': 'audio',
              'Content-Type': kEdgeTtsAudioMimeType,
            },
            audioBytes: const <int>[1, 2, 3],
          ),
        );
        await connection.close();

        await expectLater(
          resultFuture,
          throwsA(
            isA<TtsBackendException>()
                .having(
                  (error) => error.kind,
                  'kind',
                  TtsBackendErrorKind.providerUnavailable,
                )
                .having(
                  (error) => error.message,
                  'message',
                  'Microsoft Edge Speech ended before synthesis completed.',
                ),
          ),
        );
      },
    );

    test('rejects Edge text over direct protocol limit', () async {
      final backend = EdgeExperimentalTtsBackend();
      final tooLong = List<String>.filled(
        kEdgeTtsMaxInputBytes + 1,
        'a',
      ).join();

      await expectLater(
        backend.speakOrSynthesize(
          TtsSynthesisRequest(text: tooLong, rate: 0.5, pitch: 1.0),
          const TtsBackendCallbacks(),
        ),
        throwsA(
          isA<TtsBackendException>().having(
            (error) => error.kind,
            'kind',
            TtsBackendErrorKind.invalidRequest,
          ),
        ),
      );
    });

    test('stop closes active Edge websocket connection', () async {
      final connection = _FakeEdgeTtsConnection();
      final ids = _IdSequence(<String>[
        '11111111111111111111111111111111',
        '22222222222222222222222222222222',
      ]);
      final backend = EdgeExperimentalTtsBackend(
        connector: (_) => connection,
        idProvider: ids.next,
      );

      final resultFuture = backend.speakOrSynthesize(
        const TtsSynthesisRequest(text: 'Hello Edge', rate: 0.5, pitch: 1.0),
        const TtsBackendCallbacks(),
      );
      await Future<void>.delayed(Duration.zero);

      await backend.stop();

      expect(connection.closed, isTrue);
      await expectLater(
        resultFuture,
        throwsA(
          isA<TtsBackendException>().having(
            (error) => error.message,
            'message',
            'Microsoft Edge Speech was cancelled.',
          ),
        ),
      );
    });
  });
}
