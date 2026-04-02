// Conditional export: stub on web, native implementation on IO platforms.
export 'speech_input_service_sensevoice_stub.dart'
    if (dart.library.io) 'speech_input_service_sensevoice_io.dart';
