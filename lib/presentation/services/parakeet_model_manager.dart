// Conditional export: stub on web and native implementation on IO platforms.
export 'parakeet_model_manager_stub.dart'
    if (dart.library.io) 'parakeet_model_manager_io.dart';
