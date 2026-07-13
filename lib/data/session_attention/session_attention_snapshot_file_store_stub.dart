import 'session_attention_snapshot_file_store_base.dart';

SessionAttentionSnapshotFileStore createSessionAttentionSnapshotFileStore() {
  return _UnsupportedSessionAttentionSnapshotFileStore();
}

class _UnsupportedSessionAttentionSnapshotFileStore
    implements SessionAttentionSnapshotFileStore {
  @override
  Future<T> synchronized<T>(Future<T> Function() operation) => operation();

  @override
  Future<String?> read() async => null;

  @override
  Future<void> writeAtomically(String value) {
    throw UnsupportedError('Encrypted session snapshots are unavailable.');
  }

  @override
  Future<void> delete() async {}
}
