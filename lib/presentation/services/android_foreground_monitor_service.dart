import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/logging/app_logger.dart';

class AndroidForegroundMonitorService {
  static const MethodChannel _channel = MethodChannel('codewalk/system');

  static bool _running = false;
  static int _lastActiveSessionCount = -1;

  static bool get isRunning => _running;

  static Future<void> sync({
    required bool enabled,
    required int activeSessionCount,
  }) async {
    if (!_isAndroidRuntime()) {
      return;
    }

    final normalizedCount = activeSessionCount < 0 ? 0 : activeSessionCount;
    if (!enabled) {
      if (!_running) {
        _lastActiveSessionCount = -1;
        return;
      }
      try {
        await _channel.invokeMethod<void>('stopForegroundService');
        _running = false;
        _lastActiveSessionCount = -1;
      } catch (error, stackTrace) {
        AppLogger.warn(
          'Failed to stop Android foreground monitor service',
          error: error,
          stackTrace: stackTrace,
        );
      }
      return;
    }

    final title = normalizedCount == 1
        ? 'Monitoring one session'
        : 'Monitoring $normalizedCount sessions';
    const body = 'For reliable notifications';

    try {
      if (!_running) {
        await _channel.invokeMethod<void>('startForegroundService');
      }

      if (!_running || _lastActiveSessionCount != normalizedCount) {
        await _channel.invokeMethod<void>(
          'updateForegroundNotification',
          <String, String>{'title': title, 'body': body},
        );
      }

      _running = true;
      _lastActiveSessionCount = normalizedCount;
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Failed to sync Android foreground monitor service',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static bool _isAndroidRuntime() {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android;
  }
}
