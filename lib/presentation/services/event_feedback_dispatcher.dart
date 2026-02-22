import 'dart:async';

import '../../core/logging/app_logger.dart';
import '../../domain/entities/chat_realtime.dart';
import '../../domain/entities/experience_settings.dart';
import '../providers/settings_provider.dart';
import 'notification_service.dart';
import 'sound_service.dart';

class EventFeedbackDispatcher {
  EventFeedbackDispatcher({
    required SettingsProvider settingsProvider,
    required NotificationService notificationService,
    required SoundService soundService,
  }) : _settingsProvider = settingsProvider,
       _notificationService = notificationService,
       _soundService = soundService;

  final SettingsProvider _settingsProvider;
  final NotificationService _notificationService;
  final SoundService _soundService;
  final Map<String, DateTime> _lastDispatchByCategory = <String, DateTime>{};

  Future<void> handle(
    ChatEvent event, {
    String? sessionTitleHint,
    bool isAppInForeground = true,
    String? currentSessionId,
  }) async {
    final signal = _signalForEvent(event, sessionTitleHint: sessionTitleHint);
    if (signal == null) {
      return;
    }

    final isAnotherSession = _resolveIsAnotherSession(
      eventSessionId: signal.sessionId,
      currentSessionId: currentSessionId,
    );

    final shouldNotify = _settingsProvider.shouldDispatchNotification(
      signal.notificationCategory,
      isAppInForeground: isAppInForeground,
      isAnotherSession: isAnotherSession,
    );
    final shouldSound = _settingsProvider.shouldDispatchSound(
      signal.notificationCategory,
      isAppInForeground: isAppInForeground,
      isAnotherSession: isAnotherSession,
    );
    if (!shouldNotify && !shouldSound) {
      return;
    }

    final now = DateTime.now();
    final last = _lastDispatchByCategory[signal.categoryKey];
    if (last != null && now.difference(last) < const Duration(seconds: 1)) {
      return;
    }
    _lastDispatchByCategory[signal.categoryKey] = now;

    final soundOption = _settingsProvider.soundFor(signal.soundCategory);
    final soundSource = _settingsProvider.soundSourceFor(signal.soundCategory);

    if (shouldNotify) {
      unawaited(
        _notificationService.notify(
          title: signal.title,
          body: signal.body,
          category: signal.categoryKey,
          sessionId: signal.sessionId,
          directory: signal.directory,
          playSound: shouldSound && !isAppInForeground,
          soundOption: soundOption,
          soundSource: soundSource,
        ),
      );
    }

    if (!shouldSound || !isAppInForeground) {
      return;
    }

    final played = await _soundService.play(
      option: soundOption,
      source: soundSource,
    );
    if (!played && soundOption != SoundOption.off) {
      AppLogger.info('Sound fallback active for ${signal.categoryKey}');
    }
  }

  bool _resolveIsAnotherSession({
    required String? eventSessionId,
    required String? currentSessionId,
  }) {
    final eventId = eventSessionId?.trim();
    final currentId = currentSessionId?.trim();
    if (eventId == null || eventId.isEmpty) {
      return true;
    }
    if (currentId == null || currentId.isEmpty) {
      return true;
    }
    return eventId != currentId;
  }

  _FeedbackSignal? _signalForEvent(
    ChatEvent event, {
    String? sessionTitleHint,
  }) {
    final properties = event.properties;
    final sessionId = _extractSessionId(properties);
    final directory = _extractDirectory(properties);
    final sessionTitle = _extractSessionTitle(
      properties,
      sessionTitleHint: sessionTitleHint,
    );
    switch (event.type) {
      case 'permission.asked':
      case 'question.asked':
      case 'question.updated':
        return _FeedbackSignal(
          notificationCategory: NotificationCategory.permissions,
          soundCategory: SoundCategory.permissions,
          categoryKey: 'permissions',
          title: sessionTitle ?? 'Session',
          body: 'A tool permission or question needs your input.',
          sessionId: sessionId,
          directory: directory,
        );
      case 'session.error':
        return _FeedbackSignal(
          notificationCategory: NotificationCategory.errors,
          soundCategory: SoundCategory.errors,
          categoryKey: 'errors',
          title: sessionTitle ?? 'Session',
          body: 'A session reported an error.',
          sessionId: sessionId,
          directory: directory,
        );
      case 'session.idle':
        return _FeedbackSignal(
          notificationCategory: NotificationCategory.agent,
          soundCategory: SoundCategory.agent,
          categoryKey: 'agent',
          title: sessionTitle ?? 'Session',
          body: 'Agent finished the current response.',
          sessionId: sessionId,
          directory: directory,
        );
      default:
        return null;
    }
  }

  String? _extractDirectory(Map<String, dynamic> properties) {
    final direct = properties['directory']?.toString().trim();
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }

    final info = properties['info'];
    if (info is Map) {
      final nested = info['directory']?.toString().trim();
      if (nested != null && nested.isNotEmpty) {
        return nested;
      }
    }

    final session = properties['session'];
    if (session is Map) {
      final nested = session['directory']?.toString().trim();
      if (nested != null && nested.isNotEmpty) {
        return nested;
      }
    }

    final project = properties['project'];
    if (project is Map) {
      final nested = project['directory']?.toString().trim();
      if (nested != null && nested.isNotEmpty) {
        return nested;
      }
    }

    return null;
  }

  String? _extractSessionId(Map<String, dynamic> properties) {
    final direct = properties['sessionID']?.toString().trim();
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }

    final info = properties['info'];
    if (info is Map) {
      final nested = info['sessionID']?.toString().trim();
      if (nested != null && nested.isNotEmpty) {
        return nested;
      }
      final nestedId = info['id']?.toString().trim();
      if (nestedId != null && nestedId.isNotEmpty) {
        return nestedId;
      }
    }
    return null;
  }

  String? _extractSessionTitle(
    Map<String, dynamic> properties, {
    String? sessionTitleHint,
  }) {
    final direct = properties['sessionTitle']?.toString().trim();
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }

    final title = properties['title']?.toString().trim();
    if (title != null && title.isNotEmpty) {
      return title;
    }

    final info = properties['info'];
    if (info is Map) {
      final nestedSessionTitle = info['sessionTitle']?.toString().trim();
      if (nestedSessionTitle != null && nestedSessionTitle.isNotEmpty) {
        return nestedSessionTitle;
      }
      final nestedTitle = info['title']?.toString().trim();
      if (nestedTitle != null && nestedTitle.isNotEmpty) {
        return nestedTitle;
      }
    }

    final normalizedHint = sessionTitleHint?.trim();
    if (normalizedHint != null && normalizedHint.isNotEmpty) {
      return normalizedHint;
    }
    return null;
  }
}

class _FeedbackSignal {
  const _FeedbackSignal({
    required this.notificationCategory,
    required this.soundCategory,
    required this.categoryKey,
    required this.title,
    required this.body,
    this.sessionId,
    this.directory,
  });

  final NotificationCategory notificationCategory;
  final SoundCategory soundCategory;
  final String categoryKey;
  final String title;
  final String body;
  final String? sessionId;
  final String? directory;
}
