// Abstract interface for speech-to-text input service.
// Platform-specific implementations are resolved at runtime from user settings:
//   Native  → SttSpeechInputService (speech_to_text package)
//   Sherpa  → SherpaSpeechInputService (sherpa_onnx on-device)
abstract class SpeechInputService {
  /// Initializes the speech recognition engine.
  /// Returns true when the backend is usable on this device.
  /// Some backends may still require a downloadable model and can later emit
  /// `model_required` from [startListening].
  Future<bool> initialize();

  /// Starts a listening session and streams results via callbacks.
  /// [onResult] is called with recognized text and whether it is final.
  /// [onStatus] is called with status strings such as 'listening', 'done',
  ///   or the special value 'model_required' emitted by SherpaSpeechInputService
  ///   to signal that a model download is needed before STT can run.
  /// [onError] is called when a non-recoverable recognition error occurs.
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function(String status) onStatus,
    required void Function() onError,
    Duration? pauseFor,
    String? localeId,
  });

  /// Stops the active listening session.
  Future<void> stopListening();

  /// True while the service is actively capturing audio.
  bool get isListening;

  /// True after a successful [initialize] call.
  bool get isAvailable;
}
