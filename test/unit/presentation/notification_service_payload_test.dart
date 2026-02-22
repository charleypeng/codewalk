import 'package:codewalk/presentation/services/notification_service.dart';
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
  });

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
