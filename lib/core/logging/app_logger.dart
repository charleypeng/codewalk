import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// Centralized logger with debug gating and lightweight redaction.
class AppLogger {
  AppLogger._();

  static const String _name = 'CodeWalk';
  static const int _maxEntries = 1000;
  static final ValueNotifier<UnmodifiableListView<LogEntry>> _entries =
      ValueNotifier<UnmodifiableListView<LogEntry>>(
        UnmodifiableListView<LogEntry>(const <LogEntry>[]),
      );
  static final List<LogEntry> _buffer = <LogEntry>[];
  static DateTime _sessionStartedAt = DateTime.now();
  static bool _globalHandlersInstalled = false;

  static DateTime get sessionStartedAt => _sessionStartedAt;

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

  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    if (kReleaseMode) {
      return;
    }
    _record(
      level: LogLevel.debug,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
    developer.log(
      _sanitize(message),
      name: _name,
      level: 500,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    _record(
      level: LogLevel.info,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
    developer.log(
      _sanitize(message),
      name: _name,
      level: 800,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void warn(String message, {Object? error, StackTrace? stackTrace}) {
    _record(
      level: LogLevel.warn,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
    developer.log(
      _sanitize(message),
      name: _name,
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    _record(
      level: LogLevel.error,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
    developer.log(
      _sanitize(message),
      name: _name,
      level: 1000,
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

  static void _record({
    required LogLevel level,
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: _sanitize(message),
      error: error == null ? null : _sanitize(error.toString()),
      stackTrace: stackTrace?.toString(),
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
    String? query,
  }) {
    final normalizedQuery = query?.trim().toLowerCase() ?? '';
    final activeLevels = levels;
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
          if (normalizedQuery.isEmpty) {
            return true;
          }
          return entry.message.toLowerCase().contains(normalizedQuery) ||
              (entry.error?.toLowerCase().contains(normalizedQuery) ?? false) ||
              (entry.stackTrace?.toLowerCase().contains(normalizedQuery) ??
                  false);
        })
        .toList(growable: false);
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
  });
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? error;
  final String? stackTrace;

  String toExportLine() {
    final base =
        '[${timestamp.toIso8601String()}] ${level.name.toUpperCase()} $message';
    final buffer = StringBuffer(base);
    if (error != null && error!.isNotEmpty) {
      buffer.write('\n  Error: $error');
    }
    if (stackTrace != null && stackTrace!.isNotEmpty) {
      buffer.write('\n  Stack:\n$stackTrace');
    }
    return buffer.toString();
  }
}
