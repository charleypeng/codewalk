import 'package:codewalk/domain/entities/quota.dart';
import 'package:codewalk/presentation/utils/quota_pace_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'calculatePace returns on-track prediction when usage matches elapsed time',
    () {
      final now = DateTime.utc(2026, 1, 1, 12);
      final pace = calculatePace(
        usedPercent: 50,
        resetAt: now.add(const Duration(hours: 5)).millisecondsSinceEpoch,
        windowSeconds: 10 * 3600,
        now: now,
      );

      expect(pace, isNotNull);
      expect(pace!.predictedFinalPercent.round(), 100);
      expect(pace.status, QuotaPaceStatus.onTrack);
    },
  );

  test('calculatePace returns too-fast when prediction exceeds threshold', () {
    final now = DateTime.utc(2026, 1, 1, 12);
    final pace = calculatePace(
      usedPercent: 80,
      resetAt: now.add(const Duration(hours: 9)).millisecondsSinceEpoch,
      windowSeconds: 10 * 3600,
      now: now,
    );

    expect(pace, isNotNull);
    expect(pace!.predictedFinalPercent, greaterThan(100));
    expect(pace.status, QuotaPaceStatus.tooFast);
  });

  test(
    'formatWindowLabel and inferWindowSeconds follow OpenChamber labels',
    () {
      expect(formatWindowLabel('7d-sonnet'), '7-Day Sonnet Limit');
      expect(inferWindowSeconds('5h'), 18000);
      expect(inferWindowSeconds('weekly'), 604800);
    },
  );
}
