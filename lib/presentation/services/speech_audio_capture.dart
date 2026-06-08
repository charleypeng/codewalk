import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

// Audio capture abstraction for the on-device STT engines.
//
// On Windows the legacy `record` plugin (record_windows 1.0.7) can crash the
// host process with a MediaFoundation segfault (llfbandit/record#453), so the
// on-device engines are not enabled on Windows. The capture wrapper owns
// the [AudioRecorder] lifecycle for the duration of a single session so
// [startPcmStream] and [stop] always reference the same instance; the
// engines no longer create their own recorder.
class SpeechAudioCapture {
  SpeechAudioCapture();

  // On non-Windows, the wrapper owns the AudioRecorder for the duration of
  // a single capture session.
  AudioRecorder? _activeRecorder;

  bool get isWindowsTarget {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.windows;
  }

  Future<bool> hasPermission() async {
    if (isWindowsTarget) {
      // The on-device engines are not enabled on Windows; this branch should
      // be unreachable. Return false to keep the engine's permission check
      // honest until the WASAPI backend lands.
      return false;
    }
    final recorder = AudioRecorder();
    try {
      return await recorder.hasPermission();
    } catch (_) {
      return false;
    } finally {
      // The probe recorder is only used to query permission; dispose it
      // unconditionally so we never leak a plugin instance.
      try {
        await recorder.dispose();
      } catch (_) {
        // Ignore dispose errors during cleanup.
      }
    }
  }

  Future<Stream<Uint8List>> startPcmStream({
    int sampleRate = 16000,
    int numChannels = 1,
  }) async {
    if (isWindowsTarget) {
      throw StateError(
        'SpeechAudioCapture.startPcmStream is not available on Windows; '
        'the on-device engines are disabled there until the WASAPI capture '
        'backend is validated (ADR-039).',
      );
    }
    final recorder = AudioRecorder();
    _activeRecorder = recorder;
    try {
      return recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: numChannels,
        ),
      );
    } catch (error) {
      // startStream failed before returning a live stream; ensure the
      // recorder is cleaned up so we do not leak the underlying
      // record_windows / record_linux / record_macos plugin instance.
      _activeRecorder = null;
      try {
        await recorder.stop();
      } catch (_) {
        // Ignore stop errors during cleanup.
      }
      try {
        await recorder.dispose();
      } catch (_) {
        // Ignore dispose errors during cleanup.
      }
      rethrow;
    }
  }

  Future<void> stop() async {
    if (isWindowsTarget) {
      return;
    }
    final recorder = _activeRecorder;
    _activeRecorder = null;
    if (recorder == null) {
      return;
    }
    try {
      await recorder.stop();
    } catch (_) {
      // Ignore stop errors so callers can always safely stop().
    }
    try {
      await recorder.dispose();
    } catch (_) {
      // Ignore dispose errors.
    }
  }
}
