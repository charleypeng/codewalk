abstract class SessionAttentionSnapshotFileStore {
  Future<String?> read();
  Future<void> writeAtomically(String value);
  Future<void> delete();
}
