import 'package:flutter/foundation.dart';

enum RootSessionAttentionKind {
  receiving,
  delayed,
  completed,
  pendingInteraction,
  error,
}

enum SessionAttentionPauseReason { cellularDataSaver, offline, hostUnavailable }

int rootSessionAttentionPriority(RootSessionAttentionKind kind) {
  return switch (kind) {
    RootSessionAttentionKind.error => 5,
    RootSessionAttentionKind.pendingInteraction => 4,
    RootSessionAttentionKind.completed => 3,
    RootSessionAttentionKind.delayed => 2,
    RootSessionAttentionKind.receiving => 1,
  };
}

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
