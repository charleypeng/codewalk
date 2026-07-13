import 'package:codewalk/data/session_attention/session_attention_snapshot_file_store.dart';
import 'package:codewalk/data/session_attention/session_attention_snapshot_store.dart';
import 'package:codewalk/domain/entities/experience_settings.dart';
import 'package:codewalk/domain/entities/session_attention_overlay/session_attention_models.dart';
import 'package:codewalk/presentation/services/read_aloud_service.dart';
import 'package:codewalk/presentation/services/session_attention/session_attention_host_protocol.dart';
import 'package:codewalk/presentation/services/tts/tts_backend.dart';
import 'package:codewalk/presentation/widgets/session_attention_overlay/session_attention_overlay_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryKeyStorage implements SessionAttentionSnapshotKeyStorage {
  String? value;

  @override
  Future<void> delete() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

class _MemoryFileStore implements SessionAttentionSnapshotFileStore {
  String? value;

  @override
  Future<void> delete() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<T> synchronized<T>(Future<T> Function() operation) => operation();

  @override
  Future<void> writeAtomically(String value) async => this.value = value;
}

SessionAttentionItem _item({
  required String sessionId,
  required RootSessionAttentionKind kind,
  required String digest,
  String? messageId,
}) {
  return SessionAttentionItem(
    schemaVersion: 1,
    revision: 1,
    identity: SessionAttentionIdentity(
      serverId: 'server-a',
      directory: '/repo',
      rootSessionId: sessionId,
    ),
    title: sessionId,
    projectLabel: 'Project',
    kind: kind,
    startedAtEpochMs: 1,
    lastObservedAtEpochMs: 2,
    observableBusyElapsedMs: 1,
    assistantMessageId: messageId,
    displayText: messageId == null ? '' : 'Completed',
    speechText: messageId == null ? '' : 'Completed',
    displayTruncated: false,
    speechTruncated: false,
    completedAtEpochMs: messageId == null ? null : 2,
    opened: false,
    dismissed: false,
    transportCapability: SessionAttentionTransportCapability.live,
    contentDigest: digest,
  );
}

void main() {
  test('durable refresh preserves live items and applies tombstones', () async {
    final store = SessionAttentionSnapshotStore(
      keyStorage: _MemoryKeyStorage(),
      fileStore: _MemoryFileStore(),
    );
    final readAloud = ReadAloudService(
      backends: const <ReadAloudProvider, TtsBackend>{},
    );
    final controller = SessionAttentionOverlayController(
      snapshotStore: store,
      readAloudService: readAloud,
      settings: ExperienceSettings.defaults,
    );
    addTearDown(() async {
      controller.dispose();
      await readAloud.dispose();
    });
    await controller.refresh(activeServerId: 'server-a');
    final live = _item(
      sessionId: 'live-session',
      kind: RootSessionAttentionKind.active,
      digest: 'live:active:1',
    );
    SessionAttentionHostSnapshotBus.emit(
      SessionAttentionHostSnapshot(
        generation: 'main-1',
        revision: 1,
        presentation: SessionAttentionPresentation.bubble,
        activeServerId: 'server-a',
        items: <SessionAttentionItem>[live],
      ),
    );
    await Future<void>.delayed(Duration.zero);

    await store.upsert(
      _item(
        sessionId: 'completed-session',
        kind: RootSessionAttentionKind.completed,
        digest: 'completed-digest',
        messageId: 'message-1',
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(
      controller.items.map((item) => item.identity.rootSessionId),
      containsAll(<String>['live-session', 'completed-session']),
    );

    await store.suppressLive(live);
    await Future<void>.delayed(Duration.zero);

    expect(
      controller.items.map((item) => item.identity.rootSessionId),
      <String>['completed-session'],
    );
  });
}
