import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
class PersistedSessionTab {
  const PersistedSessionTab({
    required this.directory,
    required this.sessionId,
    required this.title,
    required this.lastOpenedAtMs,
    required this.serverUpdatedAtMs,
    this.projectId,
    this.seenQuestionIds = const <String>[],
    this.seenCompletionToken,
    this.seenErrorToken,
  });

  final String directory;
  final String? projectId;
  final String sessionId;
  final String title;
  final int lastOpenedAtMs;
  final int serverUpdatedAtMs;
  final List<String> seenQuestionIds;
  final String? seenCompletionToken;
  final String? seenErrorToken;

  String get identityKey =>
      '${_normalizeDirectory(directory)}::${sessionId.trim()}';

  bool get isValid =>
      _normalizeDirectory(directory).isNotEmpty && sessionId.trim().isNotEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'directory': _normalizeDirectory(directory),
    'projectId': ?_normalizedOptionalString(projectId),
    'sessionId': sessionId.trim(),
    'title': title.trim(),
    'lastOpenedAtMs': lastOpenedAtMs,
    'serverUpdatedAtMs': serverUpdatedAtMs,
    'seenQuestionIds': seenQuestionIds,
    'seenCompletionToken': ?_normalizedOptionalString(seenCompletionToken),
    'seenErrorToken': ?_normalizedOptionalString(seenErrorToken),
  };

  static PersistedSessionTab? fromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final json = Map<String, dynamic>.from(raw);
    final directory = json['directory'];
    final sessionId = json['sessionId'];
    if (directory is! String || sessionId is! String) {
      return null;
    }
    final tab = PersistedSessionTab(
      directory: _normalizeDirectory(directory),
      projectId: _normalizedOptionalString(json['projectId']),
      sessionId: sessionId.trim(),
      title: json['title'] is String ? (json['title'] as String).trim() : '',
      lastOpenedAtMs: json['lastOpenedAtMs'] is int
          ? json['lastOpenedAtMs'] as int
          : 0,
      serverUpdatedAtMs: json['serverUpdatedAtMs'] is int
          ? json['serverUpdatedAtMs'] as int
          : 0,
      seenQuestionIds: _normalizedStringList(json['seenQuestionIds']),
      seenCompletionToken: _normalizedOptionalString(
        json['seenCompletionToken'],
      ),
      seenErrorToken: _normalizedOptionalString(json['seenErrorToken']),
    );
    return tab.isValid ? tab : null;
  }
}

@immutable
class PersistedClosedSessionTab {
  const PersistedClosedSessionTab({
    required this.directory,
    required this.sessionId,
    required this.closedAtMs,
    required this.observedServerUpdatedAtMs,
    this.projectId,
  });

  final String directory;
  final String? projectId;
  final String sessionId;
  final int closedAtMs;
  final int observedServerUpdatedAtMs;

  String get identityKey =>
      '${_normalizeDirectory(directory)}::${sessionId.trim()}';

  bool get isValid =>
      _normalizeDirectory(directory).isNotEmpty && sessionId.trim().isNotEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'directory': _normalizeDirectory(directory),
    'projectId': ?_normalizedOptionalString(projectId),
    'sessionId': sessionId.trim(),
    'closedAtMs': closedAtMs,
    'observedServerUpdatedAtMs': observedServerUpdatedAtMs,
  };

  static PersistedClosedSessionTab? fromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final json = Map<String, dynamic>.from(raw);
    final directory = json['directory'];
    final sessionId = json['sessionId'];
    if (directory is! String || sessionId is! String) {
      return null;
    }
    final tab = PersistedClosedSessionTab(
      directory: _normalizeDirectory(directory),
      projectId: _normalizedOptionalString(json['projectId']),
      sessionId: sessionId.trim(),
      closedAtMs: json['closedAtMs'] is int ? json['closedAtMs'] as int : 0,
      observedServerUpdatedAtMs: json['observedServerUpdatedAtMs'] is int
          ? json['observedServerUpdatedAtMs'] as int
          : 0,
    );
    return tab.isValid ? tab : null;
  }
}

@immutable
class PersistedSessionTabsState {
  const PersistedSessionTabsState({
    this.open = const <PersistedSessionTab>[],
    this.closed = const <PersistedClosedSessionTab>[],
  });

  static const int currentVersion = 1;

  final List<PersistedSessionTab> open;
  final List<PersistedClosedSessionTab> closed;

  String encode() => jsonEncode(<String, dynamic>{
    'version': currentVersion,
    'open': open.map((tab) => tab.toJson()).toList(growable: false),
    'closed': closed.map((tab) => tab.toJson()).toList(growable: false),
  });

  static PersistedSessionTabsState decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const PersistedSessionTabsState();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const PersistedSessionTabsState();
      }
      final json = Map<String, dynamic>.from(decoded);
      if (json['version'] != currentVersion) {
        return const PersistedSessionTabsState();
      }
      final open = (json['open'] as List? ?? const <Object?>[])
          .map(PersistedSessionTab.fromJson)
          .whereType<PersistedSessionTab>()
          .toList(growable: false);
      final closed = (json['closed'] as List? ?? const <Object?>[])
          .map(PersistedClosedSessionTab.fromJson)
          .whereType<PersistedClosedSessionTab>()
          .toList(growable: false);
      return PersistedSessionTabsState(open: open, closed: closed);
    } catch (_) {
      return const PersistedSessionTabsState();
    }
  }
}

String _normalizeDirectory(String value) {
  var normalized = value.trim().replaceAll('\\', '/');
  if (normalized.length > 1) {
    normalized = normalized.replaceAll(RegExp(r'/+$'), '');
  }
  return normalized;
}

String? _normalizedOptionalString(Object? value) {
  if (value is! String) {
    return null;
  }
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

List<String> _normalizedStringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  return value
      .whereType<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList(growable: false);
}
