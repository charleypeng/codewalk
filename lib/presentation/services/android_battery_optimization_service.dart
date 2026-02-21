import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/logging/app_logger.dart';

class AndroidBatteryOptimizationService {
  static const MethodChannel _channel = MethodChannel('codewalk/system');

  bool get isSupported {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android;
  }

  Future<bool?> isIgnoringBatteryOptimizations() async {
    if (!isSupported) {
      return null;
    }
    try {
      final result = await _channel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      return result;
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Failed to query battery optimization state',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<bool> requestDisableBatteryOptimizations() async {
    if (!isSupported) {
      return false;
    }
    try {
      final opened = await _channel.invokeMethod<bool>(
        'requestDisableBatteryOptimizations',
      );
      return opened ?? false;
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Failed to request battery optimization exemption',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
