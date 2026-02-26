import 'package:codewalk/presentation/services/android_battery_optimization_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns non-android defaults when platform is unsupported', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final service = AndroidBatteryOptimizationService();

    expect(service.isSupported, isFalse);
    expect(await service.isIgnoringBatteryOptimizations(), isNull);
    expect(await service.requestDisableBatteryOptimizations(), isFalse);
  });
}
