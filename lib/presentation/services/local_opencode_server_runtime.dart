import 'local_opencode_server_runtime_stub.dart'
    if (dart.library.io) 'local_opencode_server_runtime_io.dart'
    as impl;
import 'local_opencode_server_runtime_types.dart';

LocalOpencodeServerRuntime createLocalOpencodeServerRuntime() {
  return impl.createLocalOpencodeServerRuntime();
}
