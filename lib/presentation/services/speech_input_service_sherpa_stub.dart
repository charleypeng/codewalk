import 'speech_input_service.dart';
import 'sherpa_model_manager.dart';

// Stub for web — SherpaSpeechInputService is never instantiated on web because
// the DI registration guard (!kIsWeb && linux) prevents it.
class SherpaSpeechInputService implements SpeechInputService {
  // ignore: avoid_unused_constructor_parameters
  SherpaSpeechInputService(SherpaModelManager modelManager);

  @override
  Future<bool> initialize() async => false;

  @override
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function(String status) onStatus,
    required void Function() onError,
    Duration? pauseFor,
    String? localeId,
  }) async {}

  @override
  Future<void> stopListening() async {}

  @override
  bool get isListening => false;

  @override
  bool get isAvailable => false;
}
