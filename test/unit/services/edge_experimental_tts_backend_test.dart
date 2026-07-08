import 'package:codewalk/presentation/services/tts/edge_experimental_tts_backend.dart';
import 'package:codewalk/presentation/services/tts/tts_backend.dart';
import 'package:flutter_test/flutter_test.dart';

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

      expect(ssml, contains('<voice name="en-US-AriaNeural">'));
      expect(ssml, contains('Hello &lt;world&gt; &amp; &quot;friends&quot;'));
      expect(ssml, contains('<prosody rate="+0%" pitch="+0Hz">'));
    });

    test('direct synthesis is explicitly blocked', () async {
      final backend = EdgeExperimentalTtsBackend();

      expect(await backend.isAvailable, isFalse);
      expect(
        () => backend.speakOrSynthesize(
          const TtsSynthesisRequest(text: 'Hello', rate: 0.5, pitch: 1.0),
          const TtsBackendCallbacks(),
        ),
        throwsA(
          isA<TtsBackendException>().having(
            (error) => error.kind,
            'kind',
            TtsBackendErrorKind.providerUnavailable,
          ),
        ),
      );
    });
  });
}
