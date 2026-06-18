abstract class ChatCachePayloadStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> remove(String key);

  Future<void> clear();
}
