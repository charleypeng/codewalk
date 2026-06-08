import 'package:codewalk/presentation/utils/windows_settings_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WindowsSettingsLinks', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = null;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('URIs match Microsoft Settings URI scheme (issue #43)', () {
      expect(
        WindowsSettingsLinks.microphonePrivacyUri,
        'ms-settings:privacy-microphone',
      );
      expect(
        WindowsSettingsLinks.speechPrivacyUri,
        'ms-settings:privacy-speech',
      );
      expect(
        WindowsSettingsLinks.speechUri,
        'ms-settings:speech',
      );
    });

    test('isWindowsTarget is false on non-Windows platforms', () {
      for (final platform in const [
        TargetPlatform.iOS,
        TargetPlatform.macOS,
        TargetPlatform.linux,
        TargetPlatform.android,
        TargetPlatform.fuchsia,
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(WindowsSettingsLinks.isWindowsTarget, isFalse);
      }
    });

    test('isWindowsTarget is true on Windows', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(WindowsSettingsLinks.isWindowsTarget, isTrue);
    });

    test('launchers return false on non-Windows without invoking url_launcher',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(await WindowsSettingsLinks.openMicrophonePrivacy(), isFalse);
      expect(await WindowsSettingsLinks.openSpeechPrivacy(), isFalse);
      expect(await WindowsSettingsLinks.openSpeech(), isFalse);
    });
  });
}
