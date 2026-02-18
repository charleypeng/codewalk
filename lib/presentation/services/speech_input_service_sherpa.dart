// Conditional export: stub on web (no dart:io, no sherpa_onnx),
// native implementation on Linux (and other native platforms for type safety).
// SherpaSpeechInputService is only *registered* by DI on Linux.
export 'speech_input_service_sherpa_stub.dart'
    if (dart.library.io) 'speech_input_service_sherpa_io.dart';
