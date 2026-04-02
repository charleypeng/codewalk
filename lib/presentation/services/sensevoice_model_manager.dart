// Conditional export: stub on web and native implementation on IO platforms.
export 'sensevoice_model_manager_stub.dart'
    if (dart.library.io) 'sensevoice_model_manager_io.dart';
