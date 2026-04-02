import 'dart:typed_data';

import 'package:codewalk/presentation/services/speech_input_service_sensevoice_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SenseVoiceAudioBuffer', () {
    test('stores chunks and returns all accumulated samples', () {
      final buffer = SenseVoiceAudioBuffer();
      buffer.add(Float32List.fromList(<double>[1, 2]));
      buffer.add(Float32List.fromList(<double>[3]));

      expect(buffer.takeAll(), Float32List.fromList(<double>[1, 2, 3]));
      expect(buffer.isEmpty, isTrue);
    });
  });

  group('senseVoiceChunkHasSpeech', () {
    test('ignores empty and near-silent chunks', () {
      expect(senseVoiceChunkHasSpeech(Float32List(0)), isFalse);
      expect(
        senseVoiceChunkHasSpeech(Float32List.fromList(<double>[0.001, 0.002])),
        isFalse,
      );
    });

    test('detects chunks whose average amplitude crosses the threshold', () {
      expect(
        senseVoiceChunkHasSpeech(Float32List.fromList(<double>[0.02, 0.03])),
        isTrue,
      );
    });
  });
}
