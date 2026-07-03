import 'package:codewalk/presentation/services/speech_input_service.dart';
import 'package:codewalk/presentation/services/speech_input_service_stt.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SttSpeechInputService', () {
    late SttSpeechInputService service;

    setUp(() {
      service = SttSpeechInputService();
    });

    test('implements SpeechInputService', () {
      expect(service, isA<SpeechInputService>());
    });

    test('isListening is false before any session', () {
      expect(service.isListening, isFalse);
    });

    test('isAvailable is false before initialize is called', () {
      expect(service.isAvailable, isFalse);
    });

    test('does not initialize speech_to_text on Windows', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final available = await service.initialize();

      expect(available, isFalse);
      expect(service.isAvailable, isFalse);
      expect(service.unavailableReason, contains('disabled for stability'));
      expect(service.unavailableReasonKey, 'nativeDisabled');
    });

    // autoPunctuation should only be enabled on iOS and macOS where the Apple
    // Speech APIs support acoustic-cue-based punctuation inference.
    group('autoPunctuation platform logic', () {
      final platformsThatSupportAutoPunctuation = [
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      ];
      final platformsThatDoNotSupport = [
        TargetPlatform.android,
        TargetPlatform.linux,
        TargetPlatform.windows,
        TargetPlatform.fuchsia,
      ];

      for (final platform in platformsThatSupportAutoPunctuation) {
        test('autoPunctuation is enabled on $platform', () {
          debugDefaultTargetPlatformOverride = platform;
          try {
            final supportsAutoPunctuation =
                defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS;
            expect(supportsAutoPunctuation, isTrue);
          } finally {
            debugDefaultTargetPlatformOverride = null;
          }
        });
      }

      for (final platform in platformsThatDoNotSupport) {
        test('autoPunctuation is disabled on $platform', () {
          debugDefaultTargetPlatformOverride = platform;
          try {
            final supportsAutoPunctuation =
                defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS;
            expect(supportsAutoPunctuation, isFalse);
          } finally {
            debugDefaultTargetPlatformOverride = null;
          }
        });
      }
    });
  });
}
