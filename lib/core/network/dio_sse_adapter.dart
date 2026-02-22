// Conditional export: IO platforms get the real adapter, web gets a no-op.
export 'dio_sse_adapter_stub.dart'
    if (dart.library.io) 'dio_sse_adapter_io.dart';
