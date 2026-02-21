import 'chat_cache_payload_store_base.dart';
import 'chat_cache_payload_store_stub.dart'
    if (dart.library.io) 'chat_cache_payload_store_io.dart'
    as implementation;

export 'chat_cache_payload_store_base.dart';

ChatCachePayloadStore? createChatCachePayloadStore() {
  return implementation.createChatCachePayloadStore();
}
