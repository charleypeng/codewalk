// Conditional export: stub on web and native implementation on IO platforms.
export 'moonshine_model_manager_stub.dart'
    if (dart.library.io) 'moonshine_model_manager_io.dart';
