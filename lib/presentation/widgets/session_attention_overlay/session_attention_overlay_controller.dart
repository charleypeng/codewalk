import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/session_attention/session_attention_snapshot_store.dart';
import '../../../domain/entities/experience_settings.dart';
import '../../../domain/entities/session_attention_overlay/session_attention_models.dart';
import '../../services/read_aloud_service.dart';
import '../../services/session_attention/session_attention_host_protocol.dart';
import '../../services/tts/tts_executor.dart';

class SessionAttentionOverlayController extends ChangeNotifier {
  SessionAttentionOverlayController({
    required SessionAttentionSnapshotStore snapshotStore,
    required ReadAloudService readAloudService,
    required ExperienceSettings Function() settings,
    void Function(String reason)? noteExplicitUserAction,
  }) : _snapshotStore = snapshotStore,
       _readAloudService = readAloudService,
       _settings = settings,
       _noteExplicitUserAction = noteExplicitUserAction {
    _readAloudService.addListener(_handleSpeechChanged);
    _snapshotSubscription = SessionAttentionSnapshotStore.changes.listen(
      _applyPayload,
    );
    _hostSnapshotSubscription = SessionAttentionHostSnapshotBus.stream.listen((
      snapshot,
    ) {
      if (_activeServerId == null ||
          snapshot.activeServerId == _activeServerId) {
        _liveItems = snapshot.items
            .where((item) => item.kind != RootSessionAttentionKind.completed)
            .toList(growable: false);
        _rebuildItems();
      }
    });
  }

  final SessionAttentionSnapshotStore _snapshotStore;
  final ReadAloudService _readAloudService;
  final ExperienceSettings Function() _settings;
  final void Function(String reason)? _noteExplicitUserAction;
  late final StreamSubscription<SessionAttentionSnapshotPayload>
  _snapshotSubscription;
  late final StreamSubscription<SessionAttentionHostSnapshot>
  _hostSnapshotSubscription;

  List<SessionAttentionItem> _items = const <SessionAttentionItem>[];
  List<SessionAttentionItem> _durableItems = const <SessionAttentionItem>[];
  List<SessionAttentionItem> _liveItems = const <SessionAttentionItem>[];
  Set<String> _dismissalTombstones = const <String>{};
  bool _recoveredFromCorruption = false;
  String? _activeServerId;

  List<SessionAttentionItem> get items => _items;
  bool get recoveredFromCorruption => _recoveredFromCorruption;
  String? get activeSpeechSnapshotId => _readAloudService.activeMessageId;

  Future<void> refresh({String? activeServerId}) async {
    if (_activeServerId != activeServerId) {
      _liveItems = const <SessionAttentionItem>[];
    }
    _activeServerId = activeServerId;
    final read = await _snapshotStore.read();
    _recoveredFromCorruption = read.recoveredFromCorruption;
    _applyPayload(read.payload);
  }

  void _applyPayload(SessionAttentionSnapshotPayload payload) {
    _durableItems = payload.items;
    _dismissalTombstones = payload.dismissalTombstones;
    _rebuildItems();
  }

  void _rebuildItems() {
    final byIdentity = <SessionAttentionIdentity, SessionAttentionItem>{
      for (final item in _durableItems) item.identity: item,
    };
    for (final item in _liveItems) {
      if (_dismissalTombstones.contains(
        '${item.identity.key}::${item.contentDigest}',
      )) {
        continue;
      }
      final current = byIdentity[item.identity];
      if (current == null ||
          rootSessionAttentionPriority(item.kind) >
              rootSessionAttentionPriority(current.kind)) {
        byIdentity[item.identity] = item;
      }
    }
    _items = List<SessionAttentionItem>.unmodifiable(
      byIdentity.values.where(
        (item) =>
            !item.opened &&
            !item.dismissed &&
            (_activeServerId == null ||
                item.identity.serverId == _activeServerId),
      ),
    );
    notifyListeners();
  }

  Future<void> readOrStop(SessionAttentionItem item) async {
    if (_readAloudService.activeMessageId == item.snapshotId) {
      await _readAloudService.stop();
      return;
    }
    if (item.speechText.isEmpty ||
        item.transportCapability ==
            SessionAttentionTransportCapability.reopenRequired) {
      return;
    }
    _noteExplicitUserAction?.call('session-attention-read');
    final configuration = TtsConfiguration.fromSettings(_settings());
    await _readAloudService.speak(
      messageId: item.snapshotId,
      text: item.speechText,
      provider: configuration.provider,
      rate: configuration.rate,
      pitch: configuration.pitch,
      voiceId: configuration.voiceId,
      voiceLocale: configuration.voiceLocale,
      model: configuration.model,
      baseUrl: configuration.baseUrl,
      responseFormat: configuration.responseFormat,
    );
  }

  Future<void> dismiss(SessionAttentionItem item) async {
    await _readAloudService.stopIfReading(item.snapshotId);
    final messageId = item.assistantMessageId;
    if (messageId == null || messageId.trim().isEmpty) {
      await _snapshotStore.suppressLive(item);
    } else {
      await _snapshotStore.dismiss(
        identity: item.identity,
        assistantMessageId: messageId,
      );
    }
    _liveItems = _liveItems
        .where((candidate) => candidate.snapshotId != item.snapshotId)
        .toList(growable: false);
    await refresh(activeServerId: item.identity.serverId);
  }

  Future<void> opened(SessionAttentionItem item) async {
    _noteExplicitUserAction?.call('session-attention-open');
    await _readAloudService.stopIfReading(item.snapshotId);
    await _snapshotStore.consume(item);
    _liveItems = _liveItems
        .where((candidate) => candidate.identity != item.identity)
        .toList(growable: false);
    await refresh(activeServerId: item.identity.serverId);
  }

  void _handleSpeechChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _readAloudService.removeListener(_handleSpeechChanged);
    _snapshotSubscription.cancel();
    _hostSnapshotSubscription.cancel();
    super.dispose();
  }
}
