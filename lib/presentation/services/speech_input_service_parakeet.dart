// Conditional export: stub on web, native implementation on IO platforms.
export 'speech_input_service_parakeet_stub.dart'
    if (dart.library.io) 'speech_input_service_parakeet_io.dart';
