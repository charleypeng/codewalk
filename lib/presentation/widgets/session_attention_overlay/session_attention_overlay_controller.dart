import 'package:flutter/foundation.dart';

import '../../../data/session_attention/session_attention_snapshot_store.dart';
import '../../../domain/entities/experience_settings.dart';
import '../../../domain/entities/session_attention_overlay/session_attention_models.dart';
import '../../services/read_aloud_service.dart';
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
  }

  final SessionAttentionSnapshotStore _snapshotStore;
  final ReadAloudService _readAloudService;
  final ExperienceSettings Function() _settings;
  final void Function(String reason)? _noteExplicitUserAction;

  List<SessionAttentionItem> _items = const <SessionAttentionItem>[];
  bool _recoveredFromCorruption = false;

  List<SessionAttentionItem> get items => _items;
  bool get recoveredFromCorruption => _recoveredFromCorruption;
  String? get activeSpeechSnapshotId => _readAloudService.activeMessageId;

  Future<void> refresh({String? activeServerId}) async {
    final read = await _snapshotStore.read();
    _recoveredFromCorruption = read.recoveredFromCorruption;
    _items = List<SessionAttentionItem>.unmodifiable(
      read.payload.items.where(
        (item) =>
            !item.opened &&
            !item.dismissed &&
            (activeServerId == null ||
                item.identity.serverId == activeServerId),
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
      await _snapshotStore.removeIdentity(item.identity);
    } else {
      await _snapshotStore.dismiss(
        identity: item.identity,
        assistantMessageId: messageId,
      );
    }
    await refresh(activeServerId: item.identity.serverId);
  }

  Future<void> opened(SessionAttentionItem item) async {
    _noteExplicitUserAction?.call('session-attention-open');
    await _readAloudService.stopIfReading(item.snapshotId);
    await _snapshotStore.removeIdentity(item.identity);
    await refresh(activeServerId: item.identity.serverId);
  }

  void _handleSpeechChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _readAloudService.removeListener(_handleSpeechChanged);
    super.dispose();
  }
}
