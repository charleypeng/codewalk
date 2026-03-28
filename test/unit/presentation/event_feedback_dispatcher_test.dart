import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/domain/entities/chat_realtime.dart';
import 'package:codewalk/domain/entities/experience_settings.dart';
import 'package:codewalk/presentation/providers/settings_provider.dart';
import 'package:codewalk/presentation/services/event_feedback_dispatcher.dart';
import 'package:codewalk/presentation/services/notification_service.dart';
import 'package:codewalk/presentation/services/sound_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

class _FakeNotificationService extends NotificationService {
  _FakeNotificationService();

  String? lastTitle;
  String? lastBody;
  String? lastCategory;
  String? lastSessionId;
  String? lastDirectory;
  bool? lastPlaySound;
  SoundOption? lastSoundOption;
  String? lastSoundSource;

  @override
  Future<bool> notify({
    required String title,
    required String body,
    required String category,
    String? sessionId,
    String? directory,
    bool playSound = true,
    SoundOption soundOption = SoundOption.systemDefault,
    String? soundSource,
  }) async {
    lastTitle = title;
    lastBody = body;
    lastCategory = category;
    lastSessionId = sessionId;
    lastDirectory = directory;
    lastPlaySound = playSound;
    lastSoundOption = soundOption;
    lastSoundSource = soundSource;
    return true;
  }
}

class _FakeSoundService extends SoundService {
  int calls = 0;

  @override
  Future<bool> play({required SoundOption option, String? source}) async {
    calls += 1;
    return true;
  }
}

void main() {
  test('formats finished notification title with session hint', () async {
    final settingsProvider = SettingsProvider(
      localDataSource: InMemoryAppLocalDataSource(),
      dioClient: DioClient(),
      soundService: _FakeSoundService(),
    );
    await settingsProvider.initialize();
    final notificationService = _FakeNotificationService();
    final dispatcher = EventFeedbackDispatcher(
      settingsProvider: settingsProvider,
      notificationService: notificationService,
      soundService: _FakeSoundService(),
    );

    await dispatcher.handle(
      const ChatEvent(
        type: 'session.idle',
        properties: <String, dynamic>{'sessionID': 'ses_1'},
      ),
      sessionTitleHint: 'Refactor login flow',
    );

    expect(notificationService.lastCategory, 'agent');
    expect(notificationService.lastSessionId, 'ses_1');
    expect(notificationService.lastTitle, 'Refactor login flow');
  });

  test('propagates directory metadata to notification payload', () async {
    final settingsProvider = SettingsProvider(
      localDataSource: InMemoryAppLocalDataSource(),
      dioClient: DioClient(),
      soundService: _FakeSoundService(),
    );
    await settingsProvider.initialize();

    final notificationService = _FakeNotificationService();
    final dispatcher = EventFeedbackDispatcher(
      settingsProvider: settingsProvider,
      notificationService: notificationService,
      soundService: _FakeSoundService(),
    );

    await dispatcher.handle(
      const ChatEvent(
        type: 'session.idle',
        properties: <String, dynamic>{
          'sessionID': 'ses_dir',
          'directory': '/tmp/workspace-a',
        },
      ),
      isAppInForeground: false,
    );

    expect(notificationService.lastSessionId, 'ses_dir');
    expect(notificationService.lastDirectory, '/tmp/workspace-a');
  });

  test('suppresses child-session completion notifications', () async {
    final settingsProvider = SettingsProvider(
      localDataSource: InMemoryAppLocalDataSource(),
      dioClient: DioClient(),
      soundService: _FakeSoundService(),
    );
    await settingsProvider.initialize();

    final notificationService = _FakeNotificationService();
    final soundService = _FakeSoundService();
    final dispatcher = EventFeedbackDispatcher(
      settingsProvider: settingsProvider,
      notificationService: notificationService,
      soundService: soundService,
    );

    await dispatcher.handle(
      const ChatEvent(
        type: 'session.idle',
        properties: <String, dynamic>{'sessionID': 'ses_child'},
      ),
      sessionTitleHint: 'Child Session',
      isRootSession: false,
    );

    expect(notificationService.lastTitle, isNull);
    expect(soundService.calls, 0);
  });

  test(
    'supports notification disabled and sound enabled independently',
    () async {
      final settingsProvider = SettingsProvider(
        localDataSource: InMemoryAppLocalDataSource(),
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await settingsProvider.initialize();
      await settingsProvider.setNotificationEnabled(
        NotificationCategory.agent,
        false,
      );
      await settingsProvider.setSoundEnabledForNotification(
        NotificationCategory.agent,
        true,
      );

      final notificationService = _FakeNotificationService();
      final soundService = _FakeSoundService();
      final dispatcher = EventFeedbackDispatcher(
        settingsProvider: settingsProvider,
        notificationService: notificationService,
        soundService: soundService,
      );

      await dispatcher.handle(
        const ChatEvent(
          type: 'session.idle',
          properties: <String, dynamic>{'sessionID': 'ses_2'},
        ),
        sessionTitleHint: 'Session Two',
      );

      expect(notificationService.lastTitle, isNull);
      expect(soundService.calls, 1);
    },
  );

  test('respects notify only when app is background', () async {
    final settingsProvider = SettingsProvider(
      localDataSource: InMemoryAppLocalDataSource(),
      dioClient: DioClient(),
      soundService: _FakeSoundService(),
    );
    await settingsProvider.initialize();
    await settingsProvider.setNotifyOnlyWhenBackground(
      NotificationCategory.agent,
      true,
    );
    await settingsProvider.setSoundEnabledForNotification(
      NotificationCategory.agent,
      false,
    );

    final notificationService = _FakeNotificationService();
    final dispatcher = EventFeedbackDispatcher(
      settingsProvider: settingsProvider,
      notificationService: notificationService,
      soundService: _FakeSoundService(),
    );

    await dispatcher.handle(
      const ChatEvent(
        type: 'session.idle',
        properties: <String, dynamic>{'sessionID': 'ses_bg_1'},
      ),
      isAppInForeground: true,
    );
    expect(notificationService.lastTitle, isNull);

    await dispatcher.handle(
      const ChatEvent(
        type: 'session.idle',
        properties: <String, dynamic>{'sessionID': 'ses_bg_2'},
      ),
      isAppInForeground: false,
    );
    expect(notificationService.lastTitle, isNotNull);
  });

  test('respects sound only when another conversation', () async {
    final settingsProvider = SettingsProvider(
      localDataSource: InMemoryAppLocalDataSource(),
      dioClient: DioClient(),
      soundService: _FakeSoundService(),
    );
    await settingsProvider.initialize();
    await settingsProvider.setNotificationEnabled(
      NotificationCategory.agent,
      false,
    );
    await settingsProvider.setSoundOnlyWhenAnotherSession(
      NotificationCategory.agent,
      true,
    );

    final notificationService = _FakeNotificationService();
    final soundService = _FakeSoundService();
    final dispatcher = EventFeedbackDispatcher(
      settingsProvider: settingsProvider,
      notificationService: notificationService,
      soundService: soundService,
    );

    await dispatcher.handle(
      const ChatEvent(
        type: 'session.idle',
        properties: <String, dynamic>{'sessionID': 'ses_same'},
      ),
      currentSessionId: 'ses_same',
      isAppInForeground: true,
    );
    expect(soundService.calls, 0);

    await dispatcher.handle(
      const ChatEvent(
        type: 'session.idle',
        properties: <String, dynamic>{'sessionID': 'ses_other'},
      ),
      currentSessionId: 'ses_same',
      isAppInForeground: true,
    );
    expect(soundService.calls, 1);
  });
}
