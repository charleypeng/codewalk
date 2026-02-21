import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/entities/experience_settings.dart';
import 'android_foreground_monitor_service.dart';
import 'web_notification_bridge.dart';

class NotificationTapPayload {
  const NotificationTapPayload({required this.category, this.sessionId});

  final String category;
  final String? sessionId;

  String toRaw() {
    return jsonEncode(<String, dynamic>{
      'category': category,
      'sessionId': sessionId,
    });
  }

  static NotificationTapPayload? fromRaw(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final category = decoded['category']?.toString().trim();
      if (category == null || category.isEmpty) {
        return null;
      }
      final sessionId = decoded['sessionId']?.toString().trim();
      return NotificationTapPayload(
        category: category,
        sessionId: (sessionId?.isEmpty ?? true) ? null : sessionId,
      );
    } catch (_) {
      return null;
    }
  }
}

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String _androidSmallIcon = '@drawable/ic_stat_codewalk';

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<NotificationTapPayload> _tapController =
      StreamController<NotificationTapPayload>.broadcast();
  final Map<String, Set<int>> _notificationIdsBySession = <String, Set<int>>{};
  bool _initialized = false;
  NotificationTapPayload? _pendingTap;
  StreamSubscription<String>? _webTapSubscription;

  Stream<NotificationTapPayload> get onNotificationTapped =>
      _tapController.stream;

  NotificationTapPayload? consumePendingTap() {
    final pending = _pendingTap;
    _pendingTap = null;
    return pending;
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      if (kIsWeb) {
        _webTapSubscription ??= webNotificationTapStream.listen(_handleRawTap);
        _initialized = true;
        return;
      }

      const android = AndroidInitializationSettings('@mipmap/launcher_icon');
      const macos = DarwinInitializationSettings();
      const linux = LinuxInitializationSettings(defaultActionName: 'Open');
      const windows = WindowsInitializationSettings(
        appName: 'CodeWalk',
        appUserModelId: 'com.codewalk.app',
        guid: '1f111f3e-6f5e-4fca-9ba2-2c9f8f9ddc7a',
      );
      const settings = InitializationSettings(
        android: android,
        macOS: macos,
        linux: linux,
        windows: windows,
      );

      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (response) {
          _handleRawTap(response.payload);
        },
      );

      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();

      final macOsPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      await macOsPlugin?.requestPermissions(
        alert: true,
        badge: false,
        sound: true,
      );

      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        _handleRawTap(launchDetails?.notificationResponse?.payload);
      }

      _initialized = true;
      await AndroidForegroundMonitorService.sync(
        enabled: true,
        activeSessionCount: 0,
      );
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Notification initialization unavailable on this platform',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> notify({
    required String title,
    required String body,
    required String category,
    String? sessionId,
    bool playSound = true,
    SoundOption soundOption = SoundOption.systemDefault,
    String? soundSource,
  }) async {
    final normalizedSessionId = _normalizeSessionId(sessionId);
    final payload = NotificationTapPayload(
      category: category,
      sessionId: normalizedSessionId,
    ).toRaw();

    if (kIsWeb) {
      await initialize();
      final granted = await requestWebNotificationPermission();
      if (!granted) {
        AppLogger.info('Web notification permission denied: $title');
        return false;
      }
      return showWebNotification(title: title, body: body, payload: payload);
    }

    await initialize();

    if (!_initialized) {
      return false;
    }

    try {
      final notificationId = _nextNotificationId();
      final details = _buildDetails(
        category: category,
        sessionId: normalizedSessionId,
        playSound: playSound,
        soundOption: soundOption,
        soundSource: soundSource,
      );

      await _plugin.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );

      if (normalizedSessionId != null) {
        _notificationIdsBySession
            .putIfAbsent(normalizedSessionId, () => <int>{})
            .add(notificationId);
        await _showAndroidGroupSummary(
          category: category,
          sessionId: normalizedSessionId,
          payload: payload,
        );
        await _syncAndroidForegroundMonitorWithPendingNotifications();
      }

      return true;
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Notification dispatch failed',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> clearNotificationsForSession(String sessionId) async {
    final normalizedSessionId = _normalizeSessionId(sessionId);
    if (normalizedSessionId == null) {
      return;
    }

    await initialize();
    if (!_initialized) {
      return;
    }

    final targets = <_CancelTarget>[];
    final knownIds = _notificationIdsBySession.remove(normalizedSessionId);
    if (knownIds != null) {
      for (final id in knownIds) {
        targets.add(
          _CancelTarget(id: id, tag: _sessionTag(normalizedSessionId)),
        );
      }
    }

    try {
      final active = await _plugin.getActiveNotifications();
      final expectedGroupKey = _sessionGroupKey(normalizedSessionId);
      final expectedTag = _sessionTag(normalizedSessionId);
      final expectedSummaryTag = _sessionSummaryTag(normalizedSessionId);
      for (final notification in active) {
        final id = notification.id;
        if (id == null) {
          continue;
        }
        final payloadSession = NotificationTapPayload.fromRaw(
          notification.payload,
        )?.sessionId;
        final matches =
            payloadSession == normalizedSessionId ||
            notification.groupKey == expectedGroupKey ||
            notification.tag == expectedTag ||
            notification.tag == expectedSummaryTag;
        if (!matches) {
          continue;
        }
        targets.add(_CancelTarget(id: id, tag: notification.tag));
      }
    } catch (_) {
      // Some platforms may not expose active notifications.
    }

    targets.add(
      _CancelTarget(
        id: _summaryNotificationId(normalizedSessionId),
        tag: _sessionSummaryTag(normalizedSessionId),
      ),
    );

    final dedupe = <String>{};
    for (final target in targets) {
      final key = '${target.id}|${target.tag ?? ''}';
      if (!dedupe.add(key)) {
        continue;
      }
      try {
        await _plugin.cancel(id: target.id, tag: target.tag);
      } catch (_) {
        // Best effort cleanup.
      }
    }

    await _syncAndroidForegroundMonitorWithPendingNotifications();
  }

  Future<void> _syncAndroidForegroundMonitorWithPendingNotifications() async {
    if (!_isAndroidRuntime) {
      return;
    }

    final activeSessionIds = await _activeSessionIdsFromSystem();

    if (activeSessionIds != null) {
      if (activeSessionIds.isEmpty) {
        _notificationIdsBySession.clear();
      } else {
        _notificationIdsBySession.removeWhere((sessionId, ids) {
          if (ids.isEmpty) {
            return true;
          }
          return !activeSessionIds.contains(sessionId);
        });
      }
    }

    var pendingSessionCount = 0;
    if (activeSessionIds != null) {
      pendingSessionCount = activeSessionIds.length;
    } else {
      for (final ids in _notificationIdsBySession.values) {
        if (ids.isNotEmpty) {
          pendingSessionCount += 1;
        }
      }
    }

    await AndroidForegroundMonitorService.sync(
      enabled: true,
      activeSessionCount: pendingSessionCount,
    );
  }

  Future<Set<String>?> _activeSessionIdsFromSystem() async {
    final sessionIds = <String>{};
    try {
      final active = await _plugin.getActiveNotifications();
      for (final notification in active) {
        final payloadSession = NotificationTapPayload.fromRaw(
          notification.payload,
        )?.sessionId;
        if (payloadSession != null && payloadSession.isNotEmpty) {
          sessionIds.add(payloadSession);
        }

        final tag = notification.tag?.trim();
        if (tag != null && tag.isNotEmpty) {
          if (tag.startsWith('session:')) {
            final sessionId = tag.substring('session:'.length).trim();
            if (sessionId.isNotEmpty) {
              sessionIds.add(sessionId);
            }
          }
          if (tag.startsWith('session-summary:')) {
            final sessionId = tag.substring('session-summary:'.length).trim();
            if (sessionId.isNotEmpty) {
              sessionIds.add(sessionId);
            }
          }
        }

        final groupKey = notification.groupKey?.trim();
        if (groupKey != null && groupKey.startsWith('codewalk.session.')) {
          final sessionId = groupKey
              .substring('codewalk.session.'.length)
              .trim();
          if (sessionId.isNotEmpty) {
            sessionIds.add(sessionId);
          }
        }
      }
      return sessionIds;
    } catch (_) {
      // Some Android variants may restrict active notification introspection.
      return null;
    }
  }

  NotificationDetails _buildDetails({
    required String category,
    required String? sessionId,
    required bool playSound,
    required SoundOption soundOption,
    required String? soundSource,
  }) {
    final channelId = _androidChannelId(
      category: category,
      playSound: playSound,
      soundOption: soundOption,
      soundSource: soundSource,
    );
    final groupKey = sessionId == null ? null : _sessionGroupKey(sessionId);
    final tag = sessionId == null ? null : _sessionTag(sessionId);

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'CodeWalk $category',
        channelDescription: 'CodeWalk $category notifications',
        importance: _androidImportanceForCategory(category),
        priority: _androidPriorityForCategory(category),
        icon: _androidSmallIcon,
        playSound: playSound,
        sound: _resolveAndroidSound(
          playSound: playSound,
          soundOption: soundOption,
          soundSource: soundSource,
        ),
        groupKey: groupKey,
        tag: tag,
      ),
      macOS: DarwinNotificationDetails(
        presentSound: playSound,
        threadIdentifier: sessionId,
      ),
      linux: LinuxNotificationDetails(
        sound: _resolveLinuxThemeSound(
          playSound: playSound,
          soundOption: soundOption,
          soundSource: soundSource,
        ),
        suppressSound: !playSound,
      ),
      windows: playSound
          ? WindowsNotificationDetails(
              audio: WindowsNotificationAudio.preset(
                sound: WindowsNotificationSound.defaultSound,
              ),
            )
          : WindowsNotificationDetails(
              audio: WindowsNotificationAudio.silent(),
            ),
    );
  }

  Future<void> _showAndroidGroupSummary({
    required String category,
    required String sessionId,
    required String payload,
  }) async {
    if (!_isAndroidRuntime) {
      return;
    }

    final summaryDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId(
          category: category,
          playSound: false,
          soundOption: SoundOption.off,
          soundSource: null,
        ),
        'CodeWalk $category',
        channelDescription: 'CodeWalk $category notifications',
        importance: _androidImportanceForCategory(category),
        priority: _androidPriorityForCategory(category),
        icon: _androidSmallIcon,
        playSound: false,
        groupKey: _sessionGroupKey(sessionId),
        setAsGroupSummary: true,
        groupAlertBehavior: GroupAlertBehavior.summary,
        tag: _sessionSummaryTag(sessionId),
      ),
    );

    await _plugin.show(
      id: _summaryNotificationId(sessionId),
      title: 'Conversation updates',
      body: 'Open this conversation to clear related notifications.',
      notificationDetails: summaryDetails,
      payload: payload,
    );
  }

  Importance _androidImportanceForCategory(String category) {
    return switch (category) {
      'errors' || 'permissions' => Importance.high,
      _ => Importance.defaultImportance,
    };
  }

  Priority _androidPriorityForCategory(String category) {
    return switch (category) {
      'errors' || 'permissions' => Priority.high,
      _ => Priority.defaultPriority,
    };
  }

  AndroidNotificationSound? _resolveAndroidSound({
    required bool playSound,
    required SoundOption soundOption,
    required String? soundSource,
  }) {
    if (!playSound) {
      return null;
    }

    if (soundOption != SoundOption.systemChoice &&
        soundOption != SoundOption.customFile) {
      return null;
    }

    final normalized = _normalizeAndroidSoundSource(soundSource);
    if (normalized == null) {
      return null;
    }
    return UriAndroidNotificationSound(normalized);
  }

  LinuxNotificationSound? _resolveLinuxThemeSound({
    required bool playSound,
    required SoundOption soundOption,
    required String? soundSource,
  }) {
    if (!playSound || soundOption != SoundOption.systemChoice) {
      return null;
    }
    final trimmed = soundSource?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final slashIndex = trimmed.lastIndexOf('/');
    final fileName = slashIndex >= 0
        ? trimmed.substring(slashIndex + 1)
        : trimmed;
    final dotIndex = fileName.lastIndexOf('.');
    final themeName = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
    if (themeName.isEmpty) {
      return null;
    }
    return ThemeLinuxSound(themeName);
  }

  String _androidChannelId({
    required String category,
    required bool playSound,
    required SoundOption soundOption,
    required String? soundSource,
  }) {
    final fingerprint = playSound
        ? '${soundOptionKey(soundOption)}:${soundSource ?? ''}'
        : 'silent';
    final hash = fingerprint.hashCode.abs().toRadixString(16);
    return 'codewalk_${category}_$hash';
  }

  String? _normalizeAndroidSoundSource(String? source) {
    final trimmed = source?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    if (trimmed.startsWith('content://') ||
        trimmed.startsWith('file://') ||
        trimmed.startsWith('android.resource://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return Uri.file(trimmed).toString();
    }
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      return trimmed;
    }
    return null;
  }

  String? _normalizeSessionId(String? sessionId) {
    final trimmed = sessionId?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  int _nextNotificationId() {
    return DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
  }

  int _summaryNotificationId(String sessionId) {
    return ('summary:$sessionId').hashCode & 0x7fffffff;
  }

  String _sessionGroupKey(String sessionId) => 'codewalk.session.$sessionId';
  String _sessionTag(String sessionId) => 'session:$sessionId';
  String _sessionSummaryTag(String sessionId) => 'session-summary:$sessionId';

  bool get _isAndroidRuntime {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android;
  }

  void _handleRawTap(String? rawPayload) {
    final payload = NotificationTapPayload.fromRaw(rawPayload);
    if (payload == null) {
      return;
    }
    _pendingTap = payload;
    if (!_tapController.isClosed) {
      _tapController.add(payload);
    }
  }
}

class _CancelTarget {
  const _CancelTarget({required this.id, this.tag});

  final int id;
  final String? tag;
}
