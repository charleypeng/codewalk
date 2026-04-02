import 'dart:typed_data';

import 'package:codewalk/presentation/services/speech_input_service_parakeet_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ParakeetAudioBuffer', () {
    test('stores chunks and returns all accumulated samples', () {
      final buffer = ParakeetAudioBuffer();
      buffer.add(Float32List.fromList(<double>[1, 2]));
      buffer.add(Float32List.fromList(<double>[3]));

      expect(buffer.takeAll(), Float32List.fromList(<double>[1, 2, 3]));
      expect(buffer.isEmpty, isTrue);
    });
  });

  group('parakeetChunkHasSpeech', () {
    test('ignores empty and near-silent chunks', () {
      expect(parakeetChunkHasSpeech(Float32List(0)), isFalse);
      expect(
        parakeetChunkHasSpeech(Float32List.fromList(<double>[0.001, 0.002])),
        isFalse,
      );
    });

    test('detects chunks whose average amplitude crosses the threshold', () {
      expect(
        parakeetChunkHasSpeech(Float32List.fromList(<double>[0.02, 0.03])),
        isTrue,
      );
    });
  });
}
