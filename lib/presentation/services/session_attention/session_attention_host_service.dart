import 'session_attention_host_contract.dart';
import 'session_attention_host_service_stub.dart'
    if (dart.library.io) 'session_attention_host_service_io.dart'
    as impl;

export 'session_attention_host_contract.dart';

SessionAttentionHostService createSessionAttentionHostService() {
  return impl.createSessionAttentionHostService();
}
