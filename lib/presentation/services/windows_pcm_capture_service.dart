import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'windows_microphone_service.dart';

// PCM16 mono 16 kHz microphone capture service.
//
// On Windows this delegates to a native WASAPI capture implemented in
// windows/runner/windows_microphone_plugin.cpp. The native side streams
// PCM16 mono 16 kHz chunks through the EventChannel; this class wraps the
// stream and lets callers start/stop it with a familiar Dart API.
//
// On non-Windows targets the service falls back to an empty stream so unit
// tests and the legacy `record`-based code path can keep working unchanged.
class WindowsPcmCaptureService {
  WindowsPcmCaptureService({WindowsMicrophoneService? service})
      : _service = service ?? const WindowsMicrophoneService();

  final WindowsMicrophoneService _service;
  bool _isCapturing = false;

  bool get isCapturing => _isCapturing;

  bool get isWindowsTarget {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.windows;
  }

  Future<void> start() async {
    if (!isWindowsTarget) {
      return;
    }
    if (_isCapturing) {
      return;
    }
    _isCapturing = true;
  }

  Stream<Uint8List> stream() {
    if (!isWindowsTarget) {
      return const Stream<Uint8List>.empty();
    }
    return _service.pcmStream();
  }

  Future<void> stop() async {
    if (!isWindowsTarget) {
      _isCapturing = false;
      return;
    }
    if (!_isCapturing) {
      return;
    }
    _isCapturing = false;
    await _service.stopStream();
  }
}
