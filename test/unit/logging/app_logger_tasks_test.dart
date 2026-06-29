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

  test('beginTask records correlated start and end entries', () {
    AppLogger.setLoggingEnabled(true);

    final task = AppLogger.beginTask(
      'select_session',
      tags: const <String>{'chat:settlement'},
      context: const <String, Object?>{'sessionId': 'session-hash'},
    );
    task.end();

    final entries = AppLogger.entries.value;
    expect(entries, hasLength(2));

    final start = entries.first;
    final end = entries.last;

    expect(start.isTaskStart, isTrue);
    expect(
      start.tags,
      containsAll(<String>['task:select_session', 'phase:start']),
    );
    expect(start.taskId, task.taskId);

    expect(end.isTaskEnd, isTrue);
    expect(
      end.tags,
      containsAll(<String>['task:select_session', 'phase:end', 'status:ok']),
    );
    expect(end.taskId, task.taskId);
    expect(end.elapsedMs, isNotNull);
    expect(end.taskOperation, 'select_session');
    expect(end.taskStatus, 'ok');
    expect(end.metrics?['context'], <String, Object?>{
      'sessionId': 'session-hash',
    });
  });

  test('nested tasks inherit a parent tag and metric', () {
    AppLogger.setLoggingEnabled(true);

    late final TaskHandle parent;
    AppLogger.runTask<void>('load_sessions', (task) {
      parent = task;
      final child = AppLogger.beginTask('hydrate_cache');
      child.end();
    });

    final childEnd = AppLogger.entries.value.firstWhere(
      (entry) => entry.isTaskEnd && entry.taskOperation == 'hydrate_cache',
    );

    expect(childEnd.parentTaskId, parent.taskId);
    expect(childEnd.tags, contains('parent:${parent.taskId}'));
  });

  test('runTask records error status and rethrows', () {
    AppLogger.setLoggingEnabled(true);

    expect(
      () => AppLogger.runTask<void>('select_session', (_) {
        throw StateError('boom');
      }),
      throwsStateError,
    );

    final end = AppLogger.entries.value.last;
    expect(end.level, LogLevel.error);
    expect(end.isTaskEnd, isTrue);
    expect(end.taskStatus, 'error');
    expect(end.tags, contains('status:error'));
    expect(end.error, contains('boom'));
  });

  test('runTask waits for async bodies before closing the task', () async {
    AppLogger.setLoggingEnabled(true);

    await AppLogger.runTask<Future<void>>('select_session', (_) async {
      await Future<void>.delayed(Duration.zero);
      AppLogger.beginTask('hydrate_cache').end();
    });

    final parentEnd = AppLogger.entries.value.lastWhere(
      (entry) => entry.isTaskEnd && entry.taskOperation == 'select_session',
    );
    final childEnd = AppLogger.entries.value.firstWhere(
      (entry) => entry.isTaskEnd && entry.taskOperation == 'hydrate_cache',
    );

    expect(parentEnd.taskStatus, 'ok');
    expect(childEnd.parentTaskId, parentEnd.taskId);
  });

  test('runTask records async errors before rethrowing', () async {
    AppLogger.setLoggingEnabled(true);

    await expectLater(
      AppLogger.runTask<Future<void>>('select_session', (_) async {
        await Future<void>.delayed(Duration.zero);
        throw StateError('async boom');
      }),
      throwsStateError,
    );

    final end = AppLogger.entries.value.last;
    expect(end.level, LogLevel.error);
    expect(end.taskStatus, 'error');
    expect(end.error, contains('async boom'));
  });

  test('cancel records canceled status as warning', () {
    AppLogger.setLoggingEnabled(true);

    final task = AppLogger.beginTask('load_messages');
    task.cancel(reason: 'route changed');

    final end = AppLogger.entries.value.last;
    expect(end.level, LogLevel.warn);
    expect(end.taskStatus, 'canceled');
    expect(end.tags, contains('status:canceled'));
    expect(end.metrics?['context'], <String, Object?>{
      'reason': 'route changed',
    });
  });

  test('beginTask is a no-op while logging is disabled', () {
    final task = AppLogger.beginTask('select_session');

    task.end();

    expect(task.isClosed, isTrue);
    expect(AppLogger.entries.value, isEmpty);
  });
}
