import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/entities/experience_settings.dart';

/// Applies the desktop window decoration style selected in the experience
/// settings.
///
/// The integrated mode hides the native title bar so the session tab strip can
/// own the topmost band of the window. It must be applied before the window is
/// first presented, otherwise the native title bar shows up and disappears as a
/// visible flash.
class DesktopWindowChromeService {
  const DesktopWindowChromeService._();

  static DesktopWindowChrome? _appliedChrome;

  /// The style applied before Flutter builds its providers and routes.
  static DesktopWindowChrome? get appliedChrome => _appliedChrome;

  /// Reads the persisted preference directly instead of waiting for
  /// [SettingsProvider], because the provider is only built after the first
  /// frame is scheduled and that is too late to avoid the title bar flash.
  static Future<DesktopWindowChrome> readPersistedChrome() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.experienceSettingsKey);
      if (raw == null || raw.trim().isEmpty) {
        return ExperienceSettings.defaults().desktopWindowChrome;
      }
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return ExperienceSettings.fromJson(
          Map<String, dynamic>.from(decoded),
        ).desktopWindowChrome;
      }
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Failed to read persisted desktop window chrome',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return ExperienceSettings.defaults().desktopWindowChrome;
  }

  /// Applies [chrome] to the current window.
  ///
  /// Uses [TitleBarStyle.hidden] rather than `setAsFrameless()` so the window
  /// keeps native resize borders, snapping and maximize behaviour while the
  /// caption area is drawn by Flutter.
  static Future<void> apply(DesktopWindowChrome chrome) async {
    try {
      switch (chrome) {
        case DesktopWindowChrome.integratedTabs:
          await windowManager.setTitleBarStyle(
            TitleBarStyle.hidden,
            // macOS draws the traffic lights natively; Linux and Windows use
            // the Flutter controls in DesktopWindowTitleBar instead.
            windowButtonVisibility:
                defaultTargetPlatform == TargetPlatform.macOS,
          );
        case DesktopWindowChrome.systemDecoration:
          await windowManager.setTitleBarStyle(
            TitleBarStyle.normal,
            windowButtonVisibility: true,
          );
      }
      _appliedChrome = chrome;
    } catch (error, stackTrace) {
      _appliedChrome = null;
      // A compositor may refuse the requested style; keeping the native
      // decoration is an acceptable degradation and must not block startup.
      AppLogger.warn(
        'Failed to apply desktop window chrome',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Applies the persisted preference during startup.
  static Future<void> applyPersisted() async {
    await apply(await readPersistedChrome());
  }
}
