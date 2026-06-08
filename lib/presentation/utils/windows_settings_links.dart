import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

// Actionable Windows Settings URI helpers for speech-to-text troubleshooting.
//
// Windows does not show a runtime microphone permission prompt for unpackaged
// Win32 apps, so the realistic flow is: detect capture failure, explain what is
// blocked, and open the exact Settings page. The URIs are official Microsoft
// settings URIs (see https://learn.microsoft.com/en-us/windows/apps/develop/launch/launch-settings).
class WindowsSettingsLinks {
  const WindowsSettingsLinks._();

  // Microphone privacy (per-app and "let desktop apps access your microphone").
  // Toggling "Let desktop apps access your microphone" unblocks WASAPI capture
  // for unpackaged Win32 apps.
  static const String microphonePrivacyUri = 'ms-settings:privacy-microphone';

  // Speech, inking, and typing privacy: toggles "Online speech recognition".
  static const String speechPrivacyUri = 'ms-settings:privacy-speech';

  // Speech settings page: install speech language packs and pick the default
  // speech language.
  static const String speechUri = 'ms-settings:speech';

  // Best-effort launcher used by the UI: returns true when the URI was handed
  // to the platform. On non-Windows, the helpers return false so the caller
  // can hide the action button.
  static Future<bool> openMicrophonePrivacy() =>
      _openIfWindows(microphonePrivacyUri);

  static Future<bool> openSpeechPrivacy() => _openIfWindows(speechPrivacyUri);

  static Future<bool> openSpeech() => _openIfWindows(speechUri);

  static Future<bool> _openIfWindows(String uri) async {
    if (!isWindowsTarget) {
      return false;
    }
    final parsed = Uri.tryParse(uri);
    if (parsed == null) {
      return false;
    }
    // mode: externalApplication is required for ms-settings: URIs on Windows.
    return launchUrl(parsed, mode: LaunchMode.externalApplication);
  }

  @visibleForTesting
  static bool get isWindowsTarget {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.windows;
  }
}
