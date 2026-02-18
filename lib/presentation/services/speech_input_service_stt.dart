import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'speech_input_service.dart';

// speech_to_text backend for iOS, macOS, Web, and Windows.
// Moves the STT logic that previously lived inline in _ChatInputWidgetState.
class SttSpeechInputService implements SpeechInputService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  bool _isAvailable = false;
  bool _isInitializing = false;

  void Function(String status)? _onStatus;
  void Function()? _onError;

  @override
  bool get isListening => _speechToText.isListening;

  @override
  bool get isAvailable => _isAvailable;

  @override
  Future<bool> initialize() async {
    if (_isAvailable) return true;
    if (_isInitializing) return false;

    _isInitializing = true;
    try {
      _isAvailable = await _speechToText.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
      );
      return _isAvailable;
    } catch (_) {
      _isAvailable = false;
      return false;
    } finally {
      _isInitializing = false;
    }
  }

  @override
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function(String status) onStatus,
    required void Function() onError,
    Duration? pauseFor,
    String? localeId,
  }) async {
    _onStatus = onStatus;
    _onError = onError;

    // Enable auto-punctuation (question marks, periods) on platforms that
    // support it via native speech APIs (iOS and macOS only).
    final supportsAutoPunctuation =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    await _speechToText.listen(
      onResult: (result) => onResult(
        result.recognizedWords,
        result.finalResult,
      ),
      // Wait for the specified silence window before auto-stopping.
      // Android enforces a system minimum of ~1-3s regardless of this value.
      pauseFor: pauseFor ?? const Duration(seconds: 5),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
        autoPunctuation: supportsAutoPunctuation,
      ),
      localeId: localeId,
    );
  }

  @override
  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
    } catch (_) {
      // Ignore platform stop errors to keep compose flow resilient.
    }
  }

  void _handleStatus(String status) {
    _onStatus?.call(status);
  }

  void _handleError(SpeechRecognitionError error) {
    _onError?.call();
  }
}
