part of 'chat_input_widget.dart';

class _SpeechServiceResolution {
  const _SpeechServiceResolution({
    required this.service,
    required this.engine,
    required this.usedFallback,
  });

  final SpeechInputService service;
  final SpeechToTextEngine engine;
  final bool usedFallback;
}
