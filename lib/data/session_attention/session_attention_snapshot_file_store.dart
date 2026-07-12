import 'session_attention_snapshot_file_store_base.dart';
import 'session_attention_snapshot_file_store_stub.dart'
    if (dart.library.io) 'session_attention_snapshot_file_store_io.dart'
    as implementation;

export 'session_attention_snapshot_file_store_base.dart';

SessionAttentionSnapshotFileStore createSessionAttentionSnapshotFileStore() {
  return implementation.createSessionAttentionSnapshotFileStore();
}
