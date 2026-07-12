import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../data/session_attention/session_attention_snapshot_store.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/session_attention_overlay/session_attention_models.dart';
import '../../../domain/usecases/get_chat_messages.dart';
import '../tts/read_aloud_text_extractor.dart';

class SessionAttentionCompletionResolver {
  SessionAttentionCompletionResolver({
    required GetChatMessages getChatMessages,
    required SessionAttentionSnapshotStore snapshotStore,
    Future<void> Function(Duration duration)? delay,
  }) : _getChatMessages = getChatMessages,
       _snapshotStore = snapshotStore,
       _delay = delay ?? Future<void>.delayed;

  static const int messageLimit = 20;
  static const int maxDisplayScalars = 4000;
  static const int maxSpeechScalars = 32000;
  static const List<Duration> retryDelays = <Duration>[
    Duration.zero,
    Duration(milliseconds: 500),
    Duration(milliseconds: 1500),
    Duration(seconds: 3),
  ];

  final GetChatMessages _getChatMessages;
  final SessionAttentionSnapshotStore _snapshotStore;
  final Future<void> Function(Duration duration) _delay;
  final Map<String, Future<SessionAttentionItem?>> _inFlight =
      <String, Future<SessionAttentionItem?>>{};
  final Map<String, int> _identityGeneration = <String, int>{};
  final Map<String, int> _serverGeneration = <String, int>{};
  int _globalGeneration = 0;

  Future<SessionAttentionItem?> resolve({
    required SessionAttentionIdentity identity,
    required String title,
    required String projectLabel,
    required DateTime completedAt,
    String? baselineAssistantMessageId,
    SessionAttentionTransportCapability transportCapability =
        SessionAttentionTransportCapability.live,
  }) {
    final normalizedIdentity = identity.normalized();
    if (!normalizedIdentity.isValid ||
        transportCapability ==
            SessionAttentionTransportCapability.reopenRequired) {
      return Future<SessionAttentionItem?>.value();
    }
    final key = normalizedIdentity.key;
    final existing = _inFlight[key];
    if (existing != null) {
      return existing;
    }
    final globalGeneration = _globalGeneration;
    final identityGeneration = _identityGeneration[key] ?? 0;
    final serverGeneration =
        _serverGeneration[normalizedIdentity.serverId] ?? 0;
    late final Future<SessionAttentionItem?> task;
    task =
        _resolve(
          identity: normalizedIdentity,
          title: title,
          projectLabel: projectLabel,
          completedAt: completedAt,
          baselineAssistantMessageId: baselineAssistantMessageId?.trim(),
          transportCapability: transportCapability,
          isStillValid: () =>
              globalGeneration == _globalGeneration &&
              identityGeneration == (_identityGeneration[key] ?? 0) &&
              serverGeneration ==
                  (_serverGeneration[normalizedIdentity.serverId] ?? 0),
        ).whenComplete(() {
          if (identical(_inFlight[key], task)) {
            _inFlight.remove(key);
          }
        });
    _inFlight[key] = task;
    return task;
  }

  Future<void> removeIdentity(SessionAttentionIdentity identity) {
    final normalized = identity.normalized();
    final key = normalized.key;
    _identityGeneration[key] = (_identityGeneration[key] ?? 0) + 1;
    _inFlight.remove(key);
    return _snapshotStore.removeIdentity(normalized);
  }

  Future<void> removeServer(String serverId) {
    final normalized = serverId.trim();
    _serverGeneration[normalized] = (_serverGeneration[normalized] ?? 0) + 1;
    _inFlight.removeWhere((key, _) => key.startsWith('$normalized::'));
    return _snapshotStore.removeServer(normalized);
  }

  Future<void> clear() {
    _globalGeneration += 1;
    _inFlight.clear();
    return _snapshotStore.clear();
  }

  Future<SessionAttentionItem?> _resolve({
    required SessionAttentionIdentity identity,
    required String title,
    required String projectLabel,
    required DateTime completedAt,
    required String? baselineAssistantMessageId,
    required SessionAttentionTransportCapability transportCapability,
    required bool Function() isStillValid,
  }) async {
    final normalizedIdentity = identity.normalized();
    SessionAttentionItem? existing;
    for (final item in (await _snapshotStore.read()).payload.items) {
      if (item.identity == normalizedIdentity) {
        existing = item;
        break;
      }
    }

    AssistantMessage? resolved;
    for (var attempt = 0; attempt < retryDelays.length; attempt += 1) {
      final wait = retryDelays[attempt];
      if (wait > Duration.zero) {
        await _delay(wait);
      }
      if (!isStillValid()) {
        return null;
      }
      final result = await _getChatMessages(
        GetChatMessagesParams(
          projectId: '',
          sessionId: normalizedIdentity.rootSessionId,
          directory: normalizedIdentity.directory,
          limit: messageLimit,
        ),
      );
      result.fold((_) {}, (messages) {
        final candidate = _latestCompletedAssistant(
          messages,
          normalizedIdentity.rootSessionId,
          baselineAssistantMessageId,
        );
        if (candidate == null) {
          return;
        }
        final candidateDisplay = _truncateScalars(
          _displayText(candidate),
          maxDisplayScalars,
        );
        final candidateDigest = sha256
            .convert(utf8.encode(candidateDisplay.value))
            .toString();
        if (candidate.id == existing?.assistantMessageId &&
            candidateDigest == existing?.contentDigest) {
          return;
        }
        resolved = candidate;
      });
      if (resolved != null) {
        break;
      }
    }

    final displaySource = resolved == null ? '' : _displayText(resolved!);
    final speechSource = resolved == null
        ? ''
        : ReadAloudTextExtractor.extract(resolved!);
    final display = _truncateScalars(displaySource, maxDisplayScalars);
    final speech = _truncateScalars(speechSource, maxSpeechScalars);
    final digest = sha256.convert(utf8.encode(display.value)).toString();
    final completedEpoch =
        resolved?.completedTime?.millisecondsSinceEpoch ??
        completedAt.millisecondsSinceEpoch;
    final item = SessionAttentionItem(
      schemaVersion: SessionAttentionItem.currentSchemaVersion,
      revision: completedEpoch,
      identity: normalizedIdentity,
      title: title.trim(),
      projectLabel: projectLabel.trim(),
      kind: RootSessionAttentionKind.completed,
      startedAtEpochMs: completedAt.millisecondsSinceEpoch,
      lastObservedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      observableBusyElapsedMs: 0,
      assistantMessageId: resolved?.id,
      displayText: display.value,
      speechText: speech.value,
      displayTruncated: display.truncated,
      speechTruncated: speech.truncated,
      completedAtEpochMs: completedEpoch,
      opened: false,
      dismissed: false,
      transportCapability: transportCapability,
      contentDigest: digest,
    );
    if (!isStillValid()) {
      return null;
    }
    await _snapshotStore.upsert(item);
    return item;
  }

  AssistantMessage? _latestCompletedAssistant(
    List<ChatMessage> messages,
    String sessionId,
    String? baselineAssistantMessageId,
  ) {
    AssistantMessage? latest;
    DateTime? latestUserTime;
    for (final message in messages.whereType<UserMessage>()) {
      if (message.sessionId == sessionId &&
          (latestUserTime == null || message.time.isAfter(latestUserTime))) {
        latestUserTime = message.time;
      }
    }
    for (final message in messages.whereType<AssistantMessage>()) {
      if (message.sessionId != sessionId ||
          !message.isCompleted ||
          message.id == baselineAssistantMessageId) {
        continue;
      }
      final messageTime = message.completedTime ?? message.time;
      if (latestUserTime != null && messageTime.isBefore(latestUserTime)) {
        continue;
      }
      final latestTime = latest?.completedTime ?? latest?.time;
      if (latestTime == null || messageTime.isAfter(latestTime)) {
        latest = message;
      }
    }
    return latest;
  }

  String _displayText(AssistantMessage message) {
    return message.parts
        .whereType<TextPart>()
        .map((part) => part.text.trim())
        .where((text) => text.isNotEmpty)
        .join('\n\n');
  }

  _TruncatedText _truncateScalars(String value, int maximum) {
    final runes = value.runes;
    if (runes.length <= maximum) {
      return _TruncatedText(value, false);
    }
    return _TruncatedText(String.fromCharCodes(runes.take(maximum)), true);
  }
}

class _TruncatedText {
  const _TruncatedText(this.value, this.truncated);

  final String value;
  final bool truncated;
}
