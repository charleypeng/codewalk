import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// Centralized logger with debug gating and lightweight redaction.
class AppLogger {
  AppLogger._();

  static const String _name = 'CodeWalk';
  static const int _maxEntries = 1000;
  static const String performanceTag = 'performance';
  static final ValueNotifier<UnmodifiableListView<LogEntry>> _entries =
      ValueNotifier<UnmodifiableListView<LogEntry>>(
        UnmodifiableListView<LogEntry>(const <LogEntry>[]),
      );
  static final List<LogEntry> _buffer = <LogEntry>[];
  static DateTime _sessionStartedAt = DateTime.now();
  static bool _globalHandlersInstalled = false;
  static bool _loggingEnabled = false;
  static bool _performanceLoggingEnabled = false;

  static DateTime get sessionStartedAt => _sessionStartedAt;
  static bool get loggingEnabled => _loggingEnabled;
  static bool get performanceLoggingEnabled =>
      _loggingEnabled && _performanceLoggingEnabled;
  static bool get _canRecordLogs => _loggingEnabled;

  static void setLoggingEnabled(bool enabled) {
    if (_loggingEnabled == enabled) {
      return;
    }
    _loggingEnabled = enabled;
    if (!enabled) {
      clearEntries();
    }
  }

  static void setPerformanceLoggingEnabled(bool enabled) {
    _performanceLoggingEnabled = enabled;
  }

  static String safeContextId(Object? value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return '<empty>';
    }
    return _shortHash(_sanitize(raw));
  }

  static String safePathShape(Uri uri) {
    if (uri.pathSegments.isEmpty) {
      return '/';
    }
    return '/${uri.pathSegments.map(_safePathSegment).join('/')}';
  }

  static void installGlobalHandlers() {
    if (_globalHandlersInstalled) {
      return;
    }

    _globalHandlersInstalled = true;
    _sessionStartedAt = DateTime.now();

    final previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      previousFlutterHandler?.call(details);
      error(
        'Unhandled Flutter framework exception',
        error: details.exception,
        stackTrace: details.stack,
      );
    };

    final dispatcher = ui.PlatformDispatcher.instance;
    final previousDispatcherHandler = dispatcher.onError;
    dispatcher.onError = (errorObject, stackTrace) {
      error(
        'Unhandled platform exception',
        error: errorObject,
        stackTrace: stackTrace,
      );
      final handledByPrevious =
          previousDispatcherHandler?.call(errorObject, stackTrace) ?? false;
      return handledByPrevious || true;
    };
  }

  static void recordZoneError(Object errorObject, StackTrace stackTrace) {
    error(
      'Unhandled zone exception',
      error: errorObject,
      stackTrace: stackTrace,
    );
  }

  static void debug(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Set<String>? tags,
    Map<String, Object?>? metrics,
  }) {
    if (kReleaseMode || !_canRecordLogs) {
      return;
    }
    _record(
      level: LogLevel.debug,
      message: message,
      error: error,
      stackTrace: stackTrace,
      tags: tags,
      metrics: metrics,
    );
    developer.log(
      _formatDeveloperMessage(_sanitize(message), tags),
      name: _name,
      level: 500,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void info(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Set<String>? tags,
    Map<String, Object?>? metrics,
  }) {
    if (!_canRecordLogs) {
      return;
    }
    _record(
      level: LogLevel.info,
      message: message,
      error: error,
      stackTrace: stackTrace,
      tags: tags,
      metrics: metrics,
    );
    developer.log(
      _formatDeveloperMessage(_sanitize(message), tags),
      name: _name,
      level: 800,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void warn(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Set<String>? tags,
    Map<String, Object?>? metrics,
  }) {
    if (!_canRecordLogs) {
      return;
    }
    _record(
      level: LogLevel.warn,
      message: message,
      error: error,
      stackTrace: stackTrace,
      tags: tags,
      metrics: metrics,
    );
    developer.log(
      _formatDeveloperMessage(_sanitize(message), tags),
      name: _name,
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Set<String>? tags,
    Map<String, Object?>? metrics,
  }) {
    if (!_canRecordLogs) {
      return;
    }
    _record(
      level: LogLevel.error,
      message: message,
      error: error,
      stackTrace: stackTrace,
      tags: tags,
      metrics: metrics,
    );
    developer.log(
      _formatDeveloperMessage(_sanitize(message), tags),
      name: _name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static Future<T> runPerformanceTask<T>(
    String operation,
    Future<T> Function() body, {
    Set<String>? tags,
    Map<String, Object?>? context,
  }) async {
    if (!performanceLoggingEnabled) {
      return body();
    }

    final stopwatch = Stopwatch()..start();
    try {
      final result = await body();
      stopwatch.stop();
      recordPerformanceTask(
        operation: operation,
        elapsed: stopwatch.elapsed,
        status: 'ok',
        tags: tags,
        context: context,
      );
      return result;
    } catch (error, stackTrace) {
      stopwatch.stop();
      recordPerformanceTask(
        operation: operation,
        elapsed: stopwatch.elapsed,
        status: 'error',
        tags: tags,
        context: context,
        error: error,
        stackTrace: stackTrace,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  static T measurePerformance<T>(
    String operation,
    T Function() body, {
    Set<String>? tags,
    Map<String, Object?>? context,
  }) {
    if (!performanceLoggingEnabled) {
      return body();
    }

    final stopwatch = Stopwatch()..start();
    try {
      final result = body();
      stopwatch.stop();
      recordPerformanceTask(
        operation: operation,
        elapsed: stopwatch.elapsed,
        status: 'ok',
        tags: tags,
        context: context,
      );
      return result;
    } catch (error, stackTrace) {
      stopwatch.stop();
      recordPerformanceTask(
        operation: operation,
        elapsed: stopwatch.elapsed,
        status: 'error',
        tags: tags,
        context: context,
        error: error,
        stackTrace: stackTrace,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  static void recordPerformanceTask({
    required String operation,
    required Duration elapsed,
    required String status,
    Set<String>? tags,
    Map<String, Object?>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!performanceLoggingEnabled) {
      return;
    }
    final normalizedOperation = _normalizeTagValue(operation);
    final entryTags = <String>{
      performanceTag,
      'task:$normalizedOperation',
      'status:$status',
      ...?tags,
    };
    final metrics = <String, Object?>{
      'operation': operation,
      'elapsedMs': elapsed.inMilliseconds,
      'status': status,
      if (context != null && context.isNotEmpty) 'context': context,
    };
    final message =
        'performance task=$operation status=$status elapsed=${elapsed.inMilliseconds}ms';
    final level = status == 'error' ? LogLevel.error : LogLevel.debug;
    _record(
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
      tags: entryTags,
      metrics: metrics,
    );
    developer.log(
      _formatDeveloperMessage(_sanitize(message), entryTags),
      name: _name,
      level: status == 'error' ? 1000 : 500,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static String _sanitize(String input) {
    final basicAuth = RegExp(r'(Basic\s+)[A-Za-z0-9+/=]+');
    final bearerAuth = RegExp(r'(Bearer\s+)[A-Za-z0-9\-._~+/=]+');
    return input
        .replaceAllMapped(basicAuth, (m) => '${m.group(1)}***')
        .replaceAllMapped(bearerAuth, (m) => '${m.group(1)}***');
  }

  static String _formatDeveloperMessage(String message, Set<String>? tags) {
    final safeTags = _sanitizeTags(tags);
    if (safeTags.isEmpty) {
      return message;
    }
    return '[${safeTags.join(' ')}] $message';
  }

  static Set<String> _sanitizeTags(Set<String>? tags) {
    if (tags == null || tags.isEmpty) {
      return const <String>{};
    }
    return tags
        .map((tag) => _sanitize(tag.trim()))
        .where((tag) => tag.isNotEmpty)
        .toSet();
  }

  static String _normalizeTagValue(String value) {
    final normalized = value.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9_\-]+'),
      '_',
    );
    return normalized.isEmpty ? 'unknown' : normalized;
  }

  static String _safePathSegment(String segment) {
    final lower = segment.toLowerCase();
    if (lower.startsWith('ses_') ||
        lower.startsWith('msg_') ||
        lower.startsWith('part_') ||
        lower.length > 24 ||
        RegExp(r'^[a-f0-9]{16,}$').hasMatch(lower)) {
      return ':id';
    }
    return _sanitize(segment);
  }

  static String _shortHash(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static Map<String, Object?>? _sanitizeMetrics(Map<String, Object?>? metrics) {
    if (metrics == null || metrics.isEmpty) {
      return null;
    }
    return <String, Object?>{
      for (final entry in metrics.entries)
        entry.key: _sanitizeMetricValue(entry.value, key: entry.key),
    };
  }

  static Object? _sanitizeMetricValue(Object? value, {String? key}) {
    if (key != null && _isSensitiveMetricKey(key)) {
      return '***';
    }
    if (value == null || value is bool || value is num) {
      return value;
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is Uri) {
      return _sanitize(value.toString());
    }
    if (value is Map) {
      return <String, Object?>{
        for (final entry in value.entries)
          entry.key.toString(): _sanitizeMetricValue(
            entry.value,
            key: entry.key.toString(),
          ),
      };
    }
    if (value is Iterable) {
      return value
          .map((item) => _sanitizeMetricValue(item))
          .toList(growable: false);
    }
    return _sanitize(value.toString());
  }

  static bool _isSensitiveMetricKey(String key) {
    final normalized = key.toLowerCase();
    return normalized.contains('authorization') ||
        normalized.contains('token') ||
        normalized.contains('password') ||
        normalized.contains('secret') ||
        normalized.contains('cookie') ||
        normalized.contains('apikey') ||
        normalized.contains('api_key');
  }

  static void _record({
    required LogLevel level,
    required String message,
    Object? error,
    StackTrace? stackTrace,
    Set<String>? tags,
    Map<String, Object?>? metrics,
  }) {
    if (!_canRecordLogs) {
      return;
    }
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: _sanitize(message),
      error: error == null ? null : _sanitize(error.toString()),
      stackTrace: stackTrace?.toString(),
      tags: Set<String>.unmodifiable(_sanitizeTags(tags)),
      metrics: _sanitizeMetrics(metrics),
    );
    _buffer.add(entry);
    if (_buffer.length > _maxEntries) {
      _buffer.removeRange(0, _buffer.length - _maxEntries);
    }
    _entries.value = UnmodifiableListView<LogEntry>(
      List<LogEntry>.from(_buffer),
    );
  }

  static ValueListenable<UnmodifiableListView<LogEntry>> get entries =>
      _entries;

  static List<LogEntry> filteredEntries({
    Duration? timeRange,
    Set<LogLevel>? levels,
    Set<String>? tags,
    String? query,
  }) {
    final normalizedQuery = query?.trim().toLowerCase() ?? '';
    final activeLevels = levels;
    final activeTags = _sanitizeTags(tags);
    final cutoff = timeRange == null
        ? null
        : DateTime.now().subtract(timeRange);
    return _buffer
        .where((entry) {
          if (cutoff != null && entry.timestamp.isBefore(cutoff)) {
            return false;
          }
          if (activeLevels != null &&
              activeLevels.isNotEmpty &&
              !activeLevels.contains(entry.level)) {
            return false;
          }
          if (activeTags.isNotEmpty &&
              entry.tags.intersection(activeTags).isEmpty) {
            return false;
          }
          if (normalizedQuery.isEmpty) {
            return true;
          }
          return entry.message.toLowerCase().contains(normalizedQuery) ||
              (entry.error?.toLowerCase().contains(normalizedQuery) ?? false) ||
              (entry.stackTrace?.toLowerCase().contains(normalizedQuery) ??
                  false) ||
              entry.tags.join(' ').toLowerCase().contains(normalizedQuery) ||
              (entry.metrics == null
                  ? false
                  : entry.metrics.toString().toLowerCase().contains(
                      normalizedQuery,
                    ));
        })
        .toList(growable: false);
  }

  static String _encodeMetrics(Map<String, Object?> metrics) {
    try {
      return jsonEncode(metrics);
    } catch (_) {
      return metrics.toString();
    }
  }

  static String exportEntries({List<LogEntry>? entries}) {
    final exportEntries = entries ?? _buffer;
    final buffer = StringBuffer()
      ..writeln('=== CodeWalk Debug Logs ===')
      ..writeln('Session started: ${_sessionStartedAt.toIso8601String()}')
      ..writeln('Platform: ${_platformLabel()}')
      ..writeln('Exported: ${DateTime.now().toIso8601String()}')
      ..writeln('Total entries: ${exportEntries.length}')
      ..writeln();

    for (final entry in exportEntries) {
      buffer.writeln(entry.toExportLine());
    }
    return buffer.toString();
  }

  static String _platformLabel() {
    if (kIsWeb) {
      return 'web';
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.linux => 'linux',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      _ => 'unknown',
    };
  }

  static void clearEntries() {
    _buffer.clear();
    _entries.value = UnmodifiableListView<LogEntry>(const <LogEntry>[]);
  }
}

enum LogLevel { debug, info, warn, error }

class LogEntry {
  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    this.tags = const <String>{},
    this.metrics,
  });
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? error;
  final String? stackTrace;
  final Set<String> tags;
  final Map<String, Object?>? metrics;

  bool get isPerformance => tags.contains(AppLogger.performanceTag);

  int? get elapsedMs {
    final value = metrics?['elapsedMs'];
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  String? get performanceOperation => metrics?['operation']?.toString();
  String? get performanceStatus => metrics?['status']?.toString();

  Map<String, Object?> toJson() {
    final sortedTags = tags.toList(growable: false)..sort();
    return <String, Object?>{
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      if (error != null) 'error': error,
      if (stackTrace != null) 'stackTrace': stackTrace,
      if (sortedTags.isNotEmpty) 'tags': sortedTags,
      if (metrics != null && metrics!.isNotEmpty) 'metrics': metrics,
    };
  }

  static LogEntry fromJson(Map<String, dynamic> json) {
    final tagsJson = json['tags'];
    final metricsJson = json['metrics'];
    return LogEntry(
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      level: LogLevel.values.firstWhere(
        (level) => level.name == json['level']?.toString(),
        orElse: () => LogLevel.info,
      ),
      message: json['message']?.toString() ?? '',
      error: json['error']?.toString(),
      stackTrace: json['stackTrace']?.toString(),
      tags: tagsJson is Iterable
          ? tagsJson.map((tag) => tag.toString()).toSet()
          : const <String>{},
      metrics: metricsJson is Map
          ? <String, Object?>{
              for (final entry in metricsJson.entries)
                entry.key.toString(): entry.value,
            }
          : null,
    );
  }

  String toExportLine() {
    final base =
        '[${timestamp.toIso8601String()}] ${level.name.toUpperCase()} $message';
    final buffer = StringBuffer(base);
    if (tags.isNotEmpty) {
      final sortedTags = tags.toList(growable: false)..sort();
      buffer.write('\n  Tags: ${sortedTags.join(', ')}');
    }
    if (metrics != null && metrics!.isNotEmpty) {
      buffer.write('\n  Metrics: ${AppLogger._encodeMetrics(metrics!)}');
    }
    if (error != null && error!.isNotEmpty) {
      buffer.write('\n  Error: $error');
    }
    if (stackTrace != null && stackTrace!.isNotEmpty) {
      buffer.write('\n  Stack:\n$stackTrace');
    }
    return buffer.toString();
  }
}
