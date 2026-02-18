// Conditional export: stub on web (dart.library.io unavailable),
// native implementation on Linux/macOS/Windows/Android/iOS.
export 'sherpa_model_manager_stub.dart'
    if (dart.library.io) 'sherpa_model_manager_io.dart';
