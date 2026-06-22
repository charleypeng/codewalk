import 'package:codewalk/presentation/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes and parses notification payload with session id', () {
    const payload = NotificationTapPayload(
      category: 'agent',
      sessionId: 'ses_123',
      directory: '/tmp/workspace',
    );

    final raw = payload.toRaw();
    final parsed = NotificationTapPayload.fromRaw(raw);

    expect(parsed, isNotNull);
    expect(parsed?.category, 'agent');
    expect(parsed?.sessionId, 'ses_123');
    expect(parsed?.directory, '/tmp/workspace');
    expect(parsed?.notificationId, isNull);
  });

  test('serializes and parses notification id metadata', () {
    const payload = NotificationTapPayload(
      category: 'agent',
      sessionId: 'ses_123',
      notificationId: 42,
    );

    final parsed = NotificationTapPayload.fromRaw(payload.toRaw());

    expect(parsed?.notificationId, 42);
  });

  test('keeps notification id zero valid', () {
    const payload = NotificationTapPayload(
      category: 'agent',
      sessionId: 'ses_123',
      notificationId: 0,
    );

    final parsed = NotificationTapPayload.fromRaw(payload.toRaw());

    expect(parsed?.notificationId, 0);
  });

  test(
    'notification tap activates app, emits payload, and clears session',
    () async {
      final calls = <String>[];
      final service = NotificationService(
        activateApp: () async {
          calls.add('activate');
        },
        activeNotificationsReader: () async => const <ActiveNotification>[],
        notificationCanceller: ({required id, tag}) async {
          calls.add('cancel:$id:${tag ?? ''}');
        },
        assumeInitialized: true,
      );
      addTearDown(service.dispose);
      const payload = NotificationTapPayload(
        category: 'agent',
        sessionId: 'ses_1',
        notificationId: 42,
      );

      final emitted = expectLater(
        service.onNotificationTapped,
        emits(
          isA<NotificationTapPayload>()
              .having((item) => item.sessionId, 'sessionId', 'ses_1')
              .having((item) => item.notificationId, 'notificationId', 42),
        ),
      );

      await service.debugHandleRawTap(payload.toRaw());
      await emitted;

      expect(calls.first, 'activate');
      expect(calls, contains('cancel:42:session:ses_1'));
    },
  );

  test(
    'clearNotificationsForSession cancels active notifications by payload',
    () async {
      final cancelled = <int>[];
      final service = NotificationService(
        activeNotificationsReader: () async => <ActiveNotification>[
          ActiveNotification(
            id: 7,
            payload: const NotificationTapPayload(
              category: 'agent',
              sessionId: 'ses_1',
            ).toRaw(),
          ),
          ActiveNotification(
            id: 8,
            payload: const NotificationTapPayload(
              category: 'agent',
              sessionId: 'other',
            ).toRaw(),
          ),
        ],
        notificationCanceller: ({required id, tag}) async {
          cancelled.add(id);
        },
        assumeInitialized: true,
      );
      addTearDown(service.dispose);

      await service.clearNotificationsForSession('ses_1');

      expect(cancelled, contains(7));
      expect(cancelled, isNot(contains(8)));
    },
  );

  test(
    'clearNotificationsForSession broadly clears Windows tracked toasts when history is unavailable',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
      });
      final calls = <String>[];
      final service = NotificationService(
        activeNotificationsReader: () async => const <ActiveNotification>[],
        notificationCanceller: ({required id, tag}) async {
          calls.add('cancel:$id');
        },
        allNotificationsCanceller: () async {
          calls.add('cancelAll');
        },
        assumeInitialized: true,
      );
      addTearDown(service.dispose);

      service.debugTrackNotificationForSession('ses_1', 7);
      await service.clearNotificationsForSession('ses_1');

      expect(calls, contains('cancel:7'));
      expect(calls, contains('cancelAll'));
    },
  );

  test('supports payload without directory metadata', () {
    const payload = NotificationTapPayload(
      category: 'agent',
      sessionId: 'ses_1',
    );

    final raw = payload.toRaw();
    final parsed = NotificationTapPayload.fromRaw(raw);

    expect(parsed, isNotNull);
    expect(parsed?.sessionId, 'ses_1');
    expect(parsed?.directory, isNull);
  });

  test('returns null for invalid payload', () {
    expect(NotificationTapPayload.fromRaw('invalid-json'), isNull);
    expect(NotificationTapPayload.fromRaw('{}'), isNull);
  });
}
