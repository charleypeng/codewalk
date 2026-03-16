import 'dart:typed_data';

import 'package:codewalk/presentation/services/speech_input_service_moonshine_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoonshineVadChunker', () {
    test('buffers arbitrary microphone chunks into 512-sample windows', () {
      final chunker = MoonshineVadChunker(windowSize: 4);

      final first = chunker.push(Float32List.fromList(<double>[1, 2, 3]));
      expect(first, isEmpty);

      final second = chunker.push(
        Float32List.fromList(<double>[4, 5, 6, 7, 8]),
      );
      expect(second, hasLength(2));
      expect(second[0], Float32List.fromList(<double>[1, 2, 3, 4]));
      expect(second[1], Float32List.fromList(<double>[5, 6, 7, 8]));
    });

    test('pads the final incomplete frame during flush', () {
      final chunker = MoonshineVadChunker(windowSize: 4);
      chunker.push(Float32List.fromList(<double>[1, 2, 3]));

      final frames = chunker.flushPadded();
      expect(frames, hasLength(1));
      expect(frames[0], Float32List.fromList(<double>[1, 2, 3, 0]));
      expect(chunker.flushPadded(), isEmpty);
    });
  });
}
