// Conditional export: stub on web (no dart:io, no sherpa_onnx),
// native implementation on IO platforms (Android/iOS/Linux/macOS/Windows).
export 'speech_input_service_sherpa_stub.dart'
    if (dart.library.io) 'speech_input_service_sherpa_io.dart';
