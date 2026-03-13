import 'dart:convert';

import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/domain/entities/experience_settings.dart';
import 'package:codewalk/presentation/providers/settings_provider.dart';
import 'package:codewalk/presentation/services/sound_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

class _FakeSoundService extends SoundService {
  int playCount = 0;

  @override
  Future<bool> play({required SoundOption option, String? source}) async {
    playCount += 1;
    return true;
  }
}

void main() {
  group('SettingsProvider', () {
    test('loads persisted settings and updates notification toggle', () async {
      final local = InMemoryAppLocalDataSource()
        ..experienceSettingsJson = jsonEncode({
          'notifications': {
            'agent': false,
            'permissions': true,
            'errors': true,
          },
          'sounds': {'agent': 'alert', 'permissions': 'click', 'errors': 'off'},
          'shortcuts': {'new_chat': 'mod+n'},
        });
      final soundService = _FakeSoundService();
      final provider = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: soundService,
      );

      await provider.initialize();

      expect(
        provider.isNotificationEnabled(NotificationCategory.agent),
        isFalse,
      );
      await provider.setNotificationEnabled(NotificationCategory.agent, true);
      expect(
        provider.isNotificationEnabled(NotificationCategory.agent),
        isTrue,
      );
      expect(local.experienceSettingsJson, isNotNull);
    });

    test('prevents conflicting shortcut assignments', () async {
      final local = InMemoryAppLocalDataSource();
      final provider = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await provider.initialize();

      final conflict = await provider.updateShortcut(
        ShortcutAction.quickOpen,
        'mod+n',
      );

      expect(conflict, contains('Conflicts with'));
      expect(provider.bindingFor(ShortcutAction.quickOpen), 'mod+p');
    });

    test('plays preview with selected category sound', () async {
      final local = InMemoryAppLocalDataSource();
      final soundService = _FakeSoundService();
      final provider = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: soundService,
      );
      await provider.initialize();

      await provider.setSoundOption(
        SoundCategory.permissions,
        SoundOption.click,
      );
      await provider.previewSound(SoundCategory.permissions);

      expect(soundService.playCount, 1);
    });

    test('defaults composer permission auto-approve to enabled', () async {
      final local = InMemoryAppLocalDataSource();
      final provider = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );

      await provider.initialize();

      expect(provider.composerAutoApprovePermissions, isTrue);
    });

    test('persists composer permission auto-approve changes', () async {
      final local = InMemoryAppLocalDataSource();
      final provider = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );

      await provider.initialize();
      await provider.setComposerAutoApprovePermissions(false);

      final raw = local.experienceSettingsJson;
      expect(raw, isNotNull);
      final settingsJson = jsonDecode(raw!) as Map<String, dynamic>;
      expect(settingsJson['composerAutoApprovePermissions'], isFalse);
    });

    test('allows toggling sound independently from notification', () async {
      final local = InMemoryAppLocalDataSource();
      final provider = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await provider.initialize();

      await provider.setNotificationEnabled(NotificationCategory.agent, false);
      await provider.setSoundEnabledForNotification(
        NotificationCategory.agent,
        true,
      );

      expect(
        provider.isNotificationEnabled(NotificationCategory.agent),
        isFalse,
      );
      expect(
        provider.isSoundEnabledForNotification(NotificationCategory.agent),
        isTrue,
      );

      await provider.setSoundEnabledForNotification(
        NotificationCategory.agent,
        false,
      );
      expect(
        provider.isSoundEnabledForNotification(NotificationCategory.agent),
        isFalse,
      );
    });

    test('persists desktop pane visibility preferences', () async {
      final local = InMemoryAppLocalDataSource();
      final first = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await first.initialize();
      await first.setDesktopPaneVisible(DesktopPane.files, false);

      final second = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await second.initialize();

      expect(second.isDesktopPaneVisible(DesktopPane.files), isFalse);
      expect(second.isDesktopPaneVisible(DesktopPane.conversations), isTrue);
      expect(second.isDesktopPaneVisible(DesktopPane.utility), isTrue);
    });

    test('persists app density and bubble visibility toggles', () async {
      final local = InMemoryAppLocalDataSource();
      final first = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await first.initialize();
      await first.setAppDensity(AppDensity.extraSpacious);
      await first.setShowThinkingBubbles(false);
      await first.setShowToolCallBubbles(false);

      final second = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await second.initialize();

      expect(second.appDensity, AppDensity.extraSpacious);
      expect(second.showThinkingBubbles, isFalse);
      expect(second.showToolCallBubbles, isFalse);

      await second.setAppDensity(AppDensity.extraDense);

      final third = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await third.initialize();

      expect(third.appDensity, AppDensity.extraDense);
    });

    test('persists task list visibility and collapsed state', () async {
      final local = InMemoryAppLocalDataSource();
      final first = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await first.initialize();

      expect(first.showTaskList, isTrue);
      expect(first.taskListCollapsed, isFalse);

      await first.setShowTaskList(false);
      await first.setTaskListCollapsed(true);

      final second = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await second.initialize();

      expect(second.showTaskList, isFalse);
      expect(second.taskListCollapsed, isTrue);
    });

    test('persists background behavior preferences', () async {
      final local = InMemoryAppLocalDataSource();
      final first = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await first.initialize();

      expect(first.keepDesktopRunningInTray, isTrue);
      expect(first.androidBackgroundAlertsEnabled, isTrue);
      expect(first.keepMobileRealtimeForShortPeriod, isTrue);

      await first.setKeepDesktopRunningInTray(false);
      await first.setAndroidBackgroundAlertsEnabled(false);
      await first.setKeepMobileRealtimeForShortPeriod(false);

      final second = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await second.initialize();

      expect(second.keepDesktopRunningInTray, isFalse);
      expect(second.androidBackgroundAlertsEnabled, isFalse);
      expect(second.keepMobileRealtimeForShortPeriod, isFalse);
    });

    test('persists experimental multi-device sync preference', () async {
      final local = InMemoryAppLocalDataSource();
      final first = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await first.initialize();

      expect(first.enableExperimentalMultiDeviceSync, isFalse);

      await first.setEnableExperimentalMultiDeviceSync(true);

      final second = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await second.initialize();

      expect(second.enableExperimentalMultiDeviceSync, isTrue);
    });

    test('persists speech engine, timeout, and Sherpa language', () async {
      final local = InMemoryAppLocalDataSource();
      final first = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await first.initialize();

      await first.setSpeechToTextEngine(SpeechToTextEngine.sherpa);
      await first.setSpeechSilenceTimeoutSeconds(7);
      await first.setSherpaLanguageCode('pt');

      final second = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await second.initialize();

      final expectedEngine =
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? SpeechToTextEngine.native
          : SpeechToTextEngine.sherpa;
      expect(second.speechToTextEngine, expectedEngine);
      expect(second.speechSilenceTimeoutSeconds, 7);
      expect(second.sherpaLanguageCode, 'pt');
    });

    test('persists only-when notification and sound rules', () async {
      final local = InMemoryAppLocalDataSource();
      final first = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await first.initialize();

      await first.setNotifyOnlyWhenBackground(NotificationCategory.agent, true);
      await first.setNotifyOnlyWhenAnotherSession(
        NotificationCategory.agent,
        true,
      );
      await first.setSoundOnlyWhenBackground(NotificationCategory.agent, true);
      await first.setSoundOnlyWhenAnotherSession(
        NotificationCategory.agent,
        false,
      );

      final second = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await second.initialize();

      expect(
        second.notifyOnlyWhenBackground(NotificationCategory.agent),
        isTrue,
      );
      expect(
        second.notifyOnlyWhenAnotherSession(NotificationCategory.agent),
        isTrue,
      );
      expect(
        second.soundOnlyWhenBackground(NotificationCategory.agent),
        isTrue,
      );
      expect(
        second.soundOnlyWhenAnotherSession(NotificationCategory.agent),
        isFalse,
      );
    });

    test('persists theme mode preference', () async {
      final local = InMemoryAppLocalDataSource();
      final first = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await first.initialize();

      expect(first.themeMode, ThemeModeOption.system);

      await first.setThemeMode(ThemeModeOption.dark);

      final second = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await second.initialize();

      expect(second.themeMode, ThemeModeOption.dark);
    });

    test('persists OpenCode theme preset preference', () async {
      final local = InMemoryAppLocalDataSource();
      final first = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await first.initialize();

      expect(first.themePreset, isNull);

      await first.setThemePreset(OpenCodeThemePreset.nord);

      final second = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await second.initialize();

      expect(second.themePreset, OpenCodeThemePreset.nord);

      await second.setThemePreset(null);

      final third = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await third.initialize();

      expect(third.themePreset, isNull);
    });

    test('persists AMOLED dark preference', () async {
      final local = InMemoryAppLocalDataSource();
      final first = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await first.initialize();

      expect(first.useAmoledDark, isFalse);

      await first.setUseAmoledDark(true);

      final second = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await second.initialize();

      expect(second.useAmoledDark, isTrue);
    });

    test('persists dynamic color and custom seed preferences', () async {
      final local = InMemoryAppLocalDataSource();
      final first = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await first.initialize();

      expect(first.useDynamicColor, isTrue);
      expect(first.customColorSeed, isNull);

      await first.setUseDynamicColor(false);
      await first.setCustomColorSeed(0xFF6750A4);

      final second = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await second.initialize();

      expect(second.useDynamicColor, isFalse);
      expect(second.customColorSeed, 0xFF6750A4);

      await second.setCustomColorSeed(null);

      final third = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await third.initialize();

      expect(third.customColorSeed, isNull);
    });

    test('persists contrast level preference', () async {
      final local = InMemoryAppLocalDataSource();
      final first = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await first.initialize();

      expect(first.contrastLevel, 0.0);

      await first.setContrastLevel(0.5);

      final second = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await second.initialize();

      expect(second.contrastLevel, 0.5);
    });

    test('clamps contrast level to valid range', () async {
      final local = InMemoryAppLocalDataSource();
      final provider = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await provider.initialize();

      await provider.setContrastLevel(2.0);
      expect(provider.contrastLevel, 1.0);

      await provider.setContrastLevel(-5.0);
      expect(provider.contrastLevel, -1.0);
    });

    test('persists selected system and file sound sources', () async {
      final local = InMemoryAppLocalDataSource();
      final provider = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await provider.initialize();

      await provider.setSoundOption(
        SoundCategory.permissions,
        SoundOption.systemChoice,
        source: 'content://ringtone/42',
        label: 'Android Bell',
      );

      expect(
        provider.soundSourceFor(SoundCategory.permissions),
        'content://ringtone/42',
      );
      expect(provider.soundLabelFor(SoundCategory.permissions), 'Android Bell');

      await provider.setSoundOption(
        SoundCategory.permissions,
        SoundOption.customFile,
        source: '/tmp/custom-tone.ogg',
        label: 'Custom Tone',
      );

      expect(
        provider.soundSourceFor(SoundCategory.permissions),
        '/tmp/custom-tone.ogg',
      );
      expect(provider.soundLabelFor(SoundCategory.permissions), 'Custom Tone');

      await provider.setSoundOption(
        SoundCategory.permissions,
        SoundOption.systemDefault,
      );

      expect(provider.soundSourceFor(SoundCategory.permissions), isNull);
      expect(provider.soundLabelFor(SoundCategory.permissions), isNull);
    });

    test(
      'starts and stops automatic update timer with setting toggle',
      () async {
        final local = InMemoryAppLocalDataSource();
        final provider = SettingsProvider(
          localDataSource: local,
          dioClient: DioClient(),
          soundService: _FakeSoundService(),
        );
        await provider.initialize();

        expect(provider.hasAutomaticUpdateCheckTimer, isTrue);

        await provider.setCheckUpdatesOnOpen(false);
        expect(provider.hasAutomaticUpdateCheckTimer, isFalse);

        await provider.setCheckUpdatesOnOpen(true);
        expect(provider.hasAutomaticUpdateCheckTimer, isTrue);

        provider.dispose();
        expect(provider.hasAutomaticUpdateCheckTimer, isFalse);
      },
    );
  });
}
