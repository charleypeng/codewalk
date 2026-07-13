import 'package:flutter/foundation.dart';

enum RootSessionAttentionKind {
  active,
  receiving,
  delayed,
  completed,
  pendingInteraction,
  error,
}

enum SessionAttentionPauseReason {
  cellularDataSaver,
  oauthReopenRequired,
  tailscaleReopenRequired,
  offline,
  permissionRevoked,
  serviceStopped,
  hostUnavailable,
}

enum SessionAttentionTransportCapability {
  live,
  backgroundPlainOrBasic,
  reopenRequired,
}

int rootSessionAttentionPriority(RootSessionAttentionKind kind) {
  return switch (kind) {
    RootSessionAttentionKind.error => 5,
    RootSessionAttentionKind.pendingInteraction => 4,
    RootSessionAttentionKind.completed => 3,
    RootSessionAttentionKind.delayed => 2,
    RootSessionAttentionKind.receiving => 1,
    RootSessionAttentionKind.active => 0,
  };
}

String sessionAttentionLiveDigest(
  RootSessionAttentionKind kind,
  int observedAtEpochMs,
) => 'live:${kind.name}:$observedAtEpochMs';

@immutable
class SessionAttentionIdentity {
  const SessionAttentionIdentity({
    required this.serverId,
    required this.directory,
    required this.rootSessionId,
  });

  final String serverId;
  final String directory;
  final String rootSessionId;

  String get key => '$serverId::$directory::$rootSessionId';

  SessionAttentionIdentity normalized() {
    var normalizedDirectory = directory.trim().replaceAll('\\', '/');
    if (normalizedDirectory.length > 1) {
      normalizedDirectory = normalizedDirectory.replaceAll(RegExp(r'/+$'), '');
    }
    return SessionAttentionIdentity(
      serverId: serverId.trim(),
      directory: normalizedDirectory,
      rootSessionId: rootSessionId.trim(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'serverId': serverId,
    'directory': directory,
    'sessionId': rootSessionId,
  };

  factory SessionAttentionIdentity.fromJson(Map<String, dynamic> json) {
    return SessionAttentionIdentity(
      serverId: json['serverId'] as String? ?? '',
      directory: json['directory'] as String? ?? '',
      rootSessionId: json['sessionId'] as String? ?? '',
    ).normalized();
  }

  bool get isValid =>
      serverId.trim().isNotEmpty &&
      directory.trim().isNotEmpty &&
      rootSessionId.trim().isNotEmpty;

  @override
  bool operator ==(Object other) {
    return other is SessionAttentionIdentity &&
        other.serverId == serverId &&
        other.directory == directory &&
        other.rootSessionId == rootSessionId;
  }

  @override
  int get hashCode => Object.hash(serverId, directory, rootSessionId);
}

@immutable
class SessionAttentionItem {
  const SessionAttentionItem({
    required this.schemaVersion,
    required this.revision,
    required this.identity,
    required this.title,
    required this.projectLabel,
    required this.kind,
    required this.startedAtEpochMs,
    required this.lastObservedAtEpochMs,
    required this.observableBusyElapsedMs,
    required this.displayText,
    required this.speechText,
    required this.displayTruncated,
    required this.speechTruncated,
    required this.opened,
    required this.dismissed,
    required this.transportCapability,
    required this.contentDigest,
    this.assistantMessageId,
    this.completedAtEpochMs,
    this.pauseReason,
  });

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final int revision;
  final SessionAttentionIdentity identity;
  final String title;
  final String projectLabel;
  final RootSessionAttentionKind kind;
  final int startedAtEpochMs;
  final int lastObservedAtEpochMs;
  final int observableBusyElapsedMs;
  final String? assistantMessageId;
  final String displayText;
  final String speechText;
  final bool displayTruncated;
  final bool speechTruncated;
  final int? completedAtEpochMs;
  final bool opened;
  final bool dismissed;
  final SessionAttentionTransportCapability transportCapability;
  final SessionAttentionPauseReason? pauseReason;
  final String contentDigest;

  String get snapshotId =>
      '${identity.key}::${assistantMessageId ?? contentDigest}';

  SessionAttentionItem withIdentity(SessionAttentionIdentity value) {
    return SessionAttentionItem(
      schemaVersion: schemaVersion,
      revision: revision,
      identity: value,
      title: title,
      projectLabel: projectLabel,
      kind: kind,
      startedAtEpochMs: startedAtEpochMs,
      lastObservedAtEpochMs: lastObservedAtEpochMs,
      observableBusyElapsedMs: observableBusyElapsedMs,
      assistantMessageId: assistantMessageId,
      displayText: displayText,
      speechText: speechText,
      displayTruncated: displayTruncated,
      speechTruncated: speechTruncated,
      completedAtEpochMs: completedAtEpochMs,
      opened: opened,
      dismissed: dismissed,
      transportCapability: transportCapability,
      pauseReason: pauseReason,
      contentDigest: contentDigest,
    );
  }

  SessionAttentionItem withTransport({
    required SessionAttentionTransportCapability capability,
    SessionAttentionPauseReason? reason,
  }) {
    return SessionAttentionItem(
      schemaVersion: schemaVersion,
      revision: revision,
      identity: identity,
      title: title,
      projectLabel: projectLabel,
      kind: kind,
      startedAtEpochMs: startedAtEpochMs,
      lastObservedAtEpochMs: lastObservedAtEpochMs,
      observableBusyElapsedMs: observableBusyElapsedMs,
      assistantMessageId: assistantMessageId,
      displayText: displayText,
      speechText: speechText,
      displayTruncated: displayTruncated,
      speechTruncated: speechTruncated,
      completedAtEpochMs: completedAtEpochMs,
      opened: opened,
      dismissed: dismissed,
      transportCapability: capability,
      pauseReason: reason,
      contentDigest: contentDigest,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schemaVersion': schemaVersion,
    'revision': revision,
    'identity': identity.toJson(),
    'title': title,
    'projectLabel': projectLabel,
    'kind': kind.name,
    'startedAtEpochMs': startedAtEpochMs,
    'lastObservedAtEpochMs': lastObservedAtEpochMs,
    'observableBusyElapsedMs': observableBusyElapsedMs,
    'assistantMessageId': assistantMessageId,
    'displayText': displayText,
    'speechText': speechText,
    'displayTruncated': displayTruncated,
    'speechTruncated': speechTruncated,
    'completedAtEpochMs': completedAtEpochMs,
    'opened': opened,
    'dismissed': dismissed,
    'transportCapability': transportCapability.name,
    'pauseReason': pauseReason?.name,
    'contentDigest': contentDigest,
  };

  factory SessionAttentionItem.fromJson(Map<String, dynamic> json) {
    T enumValue<T extends Enum>(List<T> values, Object? raw, T fallback) {
      for (final value in values) {
        if (value.name == raw) {
          return value;
        }
      }
      return fallback;
    }

    return SessionAttentionItem(
      schemaVersion: json['schemaVersion'] as int? ?? currentSchemaVersion,
      revision: json['revision'] as int? ?? 0,
      identity: SessionAttentionIdentity.fromJson(
        Map<String, dynamic>.from(json['identity'] as Map? ?? const {}),
      ),
      title: json['title'] as String? ?? '',
      projectLabel: json['projectLabel'] as String? ?? '',
      kind: enumValue(
        RootSessionAttentionKind.values,
        json['kind'],
        RootSessionAttentionKind.completed,
      ),
      startedAtEpochMs: json['startedAtEpochMs'] as int? ?? 0,
      lastObservedAtEpochMs: json['lastObservedAtEpochMs'] as int? ?? 0,
      observableBusyElapsedMs: json['observableBusyElapsedMs'] as int? ?? 0,
      assistantMessageId: json['assistantMessageId'] as String?,
      displayText: json['displayText'] as String? ?? '',
      speechText: json['speechText'] as String? ?? '',
      displayTruncated: json['displayTruncated'] as bool? ?? false,
      speechTruncated: json['speechTruncated'] as bool? ?? false,
      completedAtEpochMs: json['completedAtEpochMs'] as int?,
      opened: json['opened'] as bool? ?? false,
      dismissed: json['dismissed'] as bool? ?? false,
      transportCapability: enumValue(
        SessionAttentionTransportCapability.values,
        json['transportCapability'],
        SessionAttentionTransportCapability.live,
      ),
      pauseReason: json['pauseReason'] == null
          ? null
          : enumValue(
              SessionAttentionPauseReason.values,
              json['pauseReason'],
              SessionAttentionPauseReason.hostUnavailable,
            ),
      contentDigest: json['contentDigest'] as String? ?? '',
    );
  }
}

@immutable
class SessionAttentionSnapshotPayload {
  const SessionAttentionSnapshotPayload({
    this.schemaVersion = 1,
    this.revision = 0,
    this.items = const <SessionAttentionItem>[],
    this.dismissalTombstones = const <String>{},
  });

  final int schemaVersion;
  final int revision;
  final List<SessionAttentionItem> items;
  final Set<String> dismissalTombstones;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schemaVersion': schemaVersion,
    'revision': revision,
    'items': items.map((item) => item.toJson()).toList(growable: false),
    'dismissalTombstones': dismissalTombstones.toList(growable: false),
  };

  factory SessionAttentionSnapshotPayload.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (item) =>
              SessionAttentionItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.identity.isValid)
        .toList(growable: false);
    final tombstones = (json['dismissalTombstones'] as List? ?? const [])
        .whereType<String>()
        .toSet();
    return SessionAttentionSnapshotPayload(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      revision: json['revision'] as int? ?? 0,
      items: List<SessionAttentionItem>.unmodifiable(items),
      dismissalTombstones: Set<String>.unmodifiable(tombstones),
    );
  }
}

@immutable
class RootSessionAttentionCandidate {
  const RootSessionAttentionCandidate({
    required this.identity,
    required this.kind,
    required this.title,
    required this.projectLabel,
    required this.observedAt,
    this.observableBusyElapsed = Duration.zero,
    this.monitoringPaused = false,
    this.pauseReason,
    this.completionMessageId,
  });

  final SessionAttentionIdentity identity;
  final RootSessionAttentionKind kind;
  final String title;
  final String projectLabel;
  final DateTime observedAt;
  final Duration observableBusyElapsed;
  final bool monitoringPaused;
  final SessionAttentionPauseReason? pauseReason;
  final String? completionMessageId;

  int get priority => rootSessionAttentionPriority(kind);
}

@immutable
class SessionAttentionAggregate {
  const SessionAttentionAggregate({
    required this.generation,
    required this.revision,
    required this.candidates,
    this.isFullResynchronization = false,
  });

  final String generation;
  final int revision;
  final List<RootSessionAttentionCandidate> candidates;
  final bool isFullResynchronization;

  RootSessionAttentionCandidate? get highestPriority => candidates.isEmpty
      ? null
      : candidates.reduce((current, candidate) {
          if (candidate.priority != current.priority) {
            return candidate.priority > current.priority ? candidate : current;
          }
          final timeComparison = candidate.observedAt.compareTo(
            current.observedAt,
          );
          if (timeComparison != 0) {
            return timeComparison > 0 ? candidate : current;
          }
          return candidate.identity.key.compareTo(current.identity.key) < 0
              ? candidate
              : current;
        });

  bool supersedes(SessionAttentionAggregate? current) {
    if (current == null) {
      return true;
    }
    if (generation != current.generation) {
      return isFullResynchronization;
    }
    return revision > current.revision;
  }
}
