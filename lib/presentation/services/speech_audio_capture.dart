import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import 'windows_microphone_service.dart';
import 'windows_pcm_capture_service.dart';

// Audio capture abstraction for the on-device STT engines.
//
// On Windows the legacy `record` plugin (record_windows 1.0.7) can crash the
// host process with a MediaFoundation segfault (llfbandit/record#453). This
// abstraction routes capture through:
//   - On Windows: WindowsPcmCaptureService (WASAPI PCM16 mono 16 kHz).
//   - On other platforms: AudioRecorder from `record` (unchanged behavior).
//
// Each capture exposes a permission check, a PCM stream, and a stop method.
// Permission checks return true on Windows when the WASAPI preflight is
// allowed; the engine treats `false` the same way it treats a denied plugin.
class SpeechAudioCapture {
  SpeechAudioCapture({
    WindowsPcmCaptureService? windowsCapture,
    WindowsMicrophoneService? windowsMicrophoneService,
  })  : _windowsCapture = windowsCapture ?? WindowsPcmCaptureService(),
        _windowsMicrophoneService = windowsMicrophoneService ??
            const WindowsMicrophoneService();

  final WindowsPcmCaptureService _windowsCapture;
  final WindowsMicrophoneService _windowsMicrophoneService;

  bool get isWindowsTarget {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.windows;
  }

  Future<bool> hasPermission() async {
    if (!isWindowsTarget) {
      try {
        return await AudioRecorder().hasPermission();
      } catch (_) {
        return false;
      }
    }
    final status = await _windowsMicrophoneService.probe();
    return status == WindowsMicrophoneAccessStatus.allowed;
  }

  Future<Stream<Uint8List>> startPcmStream({
    int sampleRate = 16000,
    int numChannels = 1,
  }) async {
    if (!isWindowsTarget) {
      final recorder = AudioRecorder();
      return recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: numChannels,
        ),
      );
    }
    await _windowsCapture.start();
    return _windowsCapture.stream();
  }

  Future<void> stop() async {
    if (!isWindowsTarget) {
      // The legacy engines own the AudioRecorder lifecycle; nothing to do
      // here for the generic `record` path.
      return;
    }
    await _windowsCapture.stop();
  }
}
