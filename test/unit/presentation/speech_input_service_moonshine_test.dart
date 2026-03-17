import 'dart:typed_data';

import 'package:codewalk/presentation/services/speech_input_service_moonshine_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoonshineAudioBuffer', () {
    test('stores chunks and returns all accumulated samples', () {
      final buffer = MoonshineAudioBuffer();
      buffer.add(Float32List.fromList(<double>[1, 2]));
      buffer.add(Float32List.fromList(<double>[3]));

      expect(buffer.takeAll(), Float32List.fromList(<double>[1, 2, 3]));
      expect(buffer.isEmpty, isTrue);
    });
  });

  group('moonshineChunkHasSpeech', () {
    test('ignores empty and near-silent chunks', () {
      expect(moonshineChunkHasSpeech(Float32List(0)), isFalse);
      expect(
        moonshineChunkHasSpeech(Float32List.fromList(<double>[0.001, 0.002])),
        isFalse,
      );
    });

    test('detects chunks whose average amplitude crosses the threshold', () {
      expect(
        moonshineChunkHasSpeech(Float32List.fromList(<double>[0.02, 0.03])),
        isTrue,
      );
    });
  });
}
