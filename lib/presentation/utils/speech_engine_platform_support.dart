import 'package:flutter/foundation.dart';

// Centralized platform support for speech-to-text engines.
//
// On Windows, the `record: ^6.0.0` plugin's MediaFoundation implementation can
// hard-crash the host process (EXCEPTION_ACCESS_VIOLATION in `record_windows`
// during stream start — see llfbandit/record#453) when used by the on-device
// STT engines (Sherpa, Moonshine, Parakeet, SenseVoice). To prevent the app
// from closing unexpectedly, those engines are reported as unsupported on
// Windows. The Native engine (UWP speech recognition via `speech_to_text`)
// remains available and is the only working option on Windows.
//
// See ADR-038 for the full rationale.
class SpeechEnginePlatformSupport {
  const SpeechEnginePlatformSupport._();

  // Hide on web — no native STT runtime.
  static bool get isNativeSupported {
    if (kIsWeb) {
      return true;
    }
    return defaultTargetPlatform != TargetPlatform.linux;
  }

  // Android slim APK builds exclude sherpa_onnx; allow everywhere else except
  // Windows (where the underlying microphone plugin can crash the app).
  static bool get isSherpaSupported {
    if (kIsWeb) {
      return false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return false;
    }
    return defaultTargetPlatform != TargetPlatform.windows;
  }

  // Desktop only — uses sherpa_onnx + record for microphone capture. Windows
  // is excluded because the `record_windows` plugin can hard-crash the app.
  static bool get isMoonshineSupported {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static bool get isParakeetSupported {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static bool get isSenseVoiceSupported {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  // True when at least one on-device engine (Sherpa/Moonshine/Parakeet/
  // SenseVoice) is supported. Used to decide whether to show the on-device
  // STT disabled info card on Windows.
  static bool get hasAnyOnDeviceEngine {
    return isSherpaSupported ||
        isMoonshineSupported ||
        isParakeetSupported ||
        isSenseVoiceSupported;
  }
}
