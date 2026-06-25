import 'package:codewalk/core/logging/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AppLogger.clearEntries();
    AppLogger.setLoggingEnabled(false);
    AppLogger.setPerformanceLoggingEnabled(false);
  });

  tearDown(() {
    AppLogger.clearEntries();
    AppLogger.setLoggingEnabled(false);
    AppLogger.setPerformanceLoggingEnabled(false);
  });

  test('does not record regular logs while global logging is disabled', () {
    AppLogger.info('regular message');
    AppLogger.warn('warning message');
    AppLogger.error('error message');

    expect(AppLogger.loggingEnabled, isFalse);
    expect(AppLogger.entries.value, isEmpty);
  });

  test('records regular logs while global logging is enabled', () {
    AppLogger.setLoggingEnabled(true);

    AppLogger.info('regular message');

    expect(AppLogger.loggingEnabled, isTrue);
    expect(AppLogger.entries.value.single.message, 'regular message');
  });

  test('does not record performance tasks while disabled', () async {
    AppLogger.setLoggingEnabled(true);

    await AppLogger.runPerformanceTask('load_messages', () async {});

    expect(AppLogger.entries.value, isEmpty);
  });

  test(
    'does not record performance tasks while global logging is disabled',
    () async {
      AppLogger.setPerformanceLoggingEnabled(true);
      var contextBuilt = false;

      await AppLogger.runPerformanceTask(
        'load_messages',
        () async {},
        contextBuilder: () {
          contextBuilt = true;
          return const <String, Object?>{'expensive': true};
        },
      );

      expect(AppLogger.performanceLoggingEnabled, isFalse);
      expect(contextBuilt, isFalse);
      expect(AppLogger.entries.value, isEmpty);
    },
  );

  test('records lazy performance context while enabled', () async {
    AppLogger.setLoggingEnabled(true);
    AppLogger.setPerformanceLoggingEnabled(true);

    await AppLogger.runPerformanceTask(
      'cache_read',
      () async {},
      contextBuilder: () => const <String, Object?>{'keyHash': 'abc123'},
    );

    expect(
      AppLogger.entries.value.single.metrics?['context'],
      <String, Object?>{'keyHash': 'abc123'},
    );
  });

  test('records tags and metrics while enabled', () async {
    AppLogger.setLoggingEnabled(true);
    AppLogger.setPerformanceLoggingEnabled(true);

    await AppLogger.runPerformanceTask(
      'load_messages',
      () async {},
      tags: const <String>{'chat:messages'},
      context: const <String, Object?>{'sessionId': 'ses_123'},
    );

    final entry = AppLogger.entries.value.single;
    expect(entry.isPerformance, isTrue);
    expect(
      entry.tags,
      containsAll(<String>['performance', 'task:load_messages']),
    );
    expect(entry.tags, contains('chat:messages'));
    expect(entry.elapsedMs, isNotNull);
    expect(entry.performanceOperation, 'load_messages');
    expect(entry.performanceStatus, 'ok');
    expect(
      AppLogger.filteredEntries(tags: const <String>{AppLogger.performanceTag}),
      contains(entry),
    );
  });

  test('redacts sensitive metric keys', () async {
    AppLogger.setLoggingEnabled(true);
    AppLogger.setPerformanceLoggingEnabled(true);

    await AppLogger.runPerformanceTask(
      'network_request',
      () async {},
      context: const <String, Object?>{
        'token': 'secret-token',
        'path': '/session',
      },
    );

    final context = AppLogger.entries.value.single.metrics?['context'];
    expect(context, isA<Map>());
    expect((context as Map)['token'], '***');
    expect(context['path'], '/session');
  });

  test('round-trips performance entries through json', () async {
    AppLogger.setLoggingEnabled(true);
    AppLogger.setPerformanceLoggingEnabled(true);

    await AppLogger.runPerformanceTask('cache_read', () async {});

    final restored = LogEntry.fromJson(AppLogger.entries.value.single.toJson());

    expect(restored.isPerformance, isTrue);
    expect(restored.performanceOperation, 'cache_read');
    expect(restored.elapsedMs, isNotNull);
  });
}
