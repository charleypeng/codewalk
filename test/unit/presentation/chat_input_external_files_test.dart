import 'dart:typed_data';

import 'package:codewalk/presentation/widgets/chat_input/chat_input_external_files.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _bytes(List<int> values) => Uint8List.fromList(values);

void main() {
  group('composerFileFromPath', () {
    test('accepts the same extensions the picker accepts', () {
      for (final extension in kComposerAttachmentExtensions) {
        final file = composerFileFromPath(
          '/tmp/photo.$extension',
          fallbackName: 'fallback',
        );

        expect(file, isNotNull, reason: '.$extension should be accepted');
        expect(file!.name, 'photo.$extension');
        expect(file.path, '/tmp/photo.$extension');
      }
    });

    test('rejects anything else instead of guessing', () {
      for (final path in <String>[
        '/tmp/notes.txt',
        '/tmp/archive.zip',
        '/tmp/script.sh',
        '/tmp/noextension',
        '   ',
      ]) {
        expect(
          composerFileFromPath(path, fallbackName: 'fallback'),
          isNull,
          reason: '$path should not be attachable',
        );
      }
    });

    test('is case insensitive about the extension', () {
      expect(
        composerFileFromPath('/tmp/SCAN.PDF', fallbackName: 'f'),
        isNotNull,
      );
    });

    test('handles Windows separators', () {
      final file = composerFileFromPath(
        r'C:\Users\me\shot.png',
        fallbackName: 'f',
      );

      expect(file, isNotNull);
      expect(file!.name, 'shot.png');
    });
  });

  group('composerImageExtensionFromBytes', () {
    test('detects formats from their signatures', () {
      expect(
        composerImageExtensionFromBytes(_bytes([0x89, 0x50, 0x4E, 0x47, 0, 0])),
        'png',
      );
      expect(
        composerImageExtensionFromBytes(_bytes([0xFF, 0xD8, 0xFF, 0xE0])),
        'jpg',
      );
      expect(
        composerImageExtensionFromBytes(_bytes([0x47, 0x49, 0x46, 0x38])),
        'gif',
      );
      expect(
        composerImageExtensionFromBytes(_bytes([0x42, 0x4D, 0, 0])),
        'bmp',
      );
      expect(
        composerImageExtensionFromBytes(
          _bytes([
            0x52, 0x49, 0x46, 0x46, //
            0, 0, 0, 0,
            0x57, 0x45, 0x42, 0x50,
          ]),
        ),
        'webp',
      );
    });

    test('falls back to png for unrecognised bytes', () {
      expect(composerImageExtensionFromBytes(_bytes([1, 2, 3, 4])), 'png');
    });
  });

  group('composerFileFromImageBytes', () {
    test('names a pasted screenshot with the detected extension', () {
      final file = composerFileFromImageBytes(
        _bytes([0xFF, 0xD8, 0xFF, 0xE0]),
        baseName: 'Pasted image',
      );

      expect(file, isNotNull);
      expect(file!.name, 'Pasted image.jpg');
      expect(file.size, 4);
      expect(file.bytes, isNotNull);
    });

    test('ignores empty clipboard payloads', () {
      expect(
        composerFileFromImageBytes(_bytes(<int>[]), baseName: 'x'),
        isNull,
      );
    });
  });

  group('composerDedupeFiles', () {
    test('drops repeats while preserving order', () {
      final files = <PlatformFile>[
        PlatformFile(path: '/a.png', name: 'a.png', size: 1),
        PlatformFile(path: '/b.png', name: 'b.png', size: 1),
        PlatformFile(path: '/a.png', name: 'a.png', size: 1),
      ];

      final result = composerDedupeFiles(files);

      expect(result.map((file) => file.name), <String>['a.png', 'b.png']);
    });

    test('separates pathless payloads by name and size', () {
      final files = <PlatformFile>[
        PlatformFile(name: 'shot.png', size: 10, bytes: _bytes([1])),
        PlatformFile(name: 'shot.png', size: 10, bytes: _bytes([1])),
        PlatformFile(name: 'shot.png', size: 20, bytes: _bytes([2])),
      ];

      expect(composerDedupeFiles(files).length, 2);
    });
  });
}
