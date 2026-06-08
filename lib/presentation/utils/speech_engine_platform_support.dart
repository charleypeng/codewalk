import 'package:flutter/foundation.dart';

// Centralized platform support for speech-to-text engines.
//
// Windows was previously disabled for on-device engines because the
// `record: ^6.0.0` plugin's MediaFoundation implementation can hard-crash the
// host process (EXCEPTION_ACCESS_VIOLATION in `record_windows` during stream
// start — see llfbandit/record#453). The current build routes Windows capture
// through a WASAPI PCM16 mono 16 kHz backend (see ADR-039) so the on-device
// engines can run safely on Windows without touching `record_windows`.
//
// See ADR-038 for the historical mitigation and ADR-039 for the real fix.
class SpeechEnginePlatformSupport {
  const SpeechEnginePlatformSupport._();

  // Web: true (browser speech via speech_to_text). Linux: false — Linux
  // defaults to on-device engines (Parakeet) per ADR-006.
  static bool get isNativeSupported {
    if (kIsWeb) {
      return true;
    }
    return defaultTargetPlatform != TargetPlatform.linux;
  }

  // Android slim APK builds exclude sherpa_onnx. Linux/macOS/Windows are
  // supported: on Windows capture now uses WASAPI so the on-device engines
  // are no longer blocked by `record_windows`.
  static bool get isSherpaSupported {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform != TargetPlatform.android;
  }

  // Desktop only — uses sherpa_onnx + the platform-appropriate microphone
  // capture path (record on Linux/macOS, WASAPI on Windows).
  static bool get isMoonshineSupported {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  static bool get isParakeetSupported {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  static bool get isSenseVoiceSupported {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  // True when at least one on-device engine (Sherpa/Moonshine/Parakeet/
  // SenseVoice) is supported. Always true across supported IO platforms now
  // that Windows can use the WASAPI backend.
  static bool get hasAnyOnDeviceEngine {
    return isSherpaSupported ||
        isMoonshineSupported ||
        isParakeetSupported ||
        isSenseVoiceSupported;
  }
}
