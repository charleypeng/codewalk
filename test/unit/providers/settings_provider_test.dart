import 'dart:convert';

import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/domain/entities/experience_settings.dart';
import 'package:codewalk/presentation/providers/settings_provider.dart';
import 'package:codewalk/presentation/services/sound_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

class _FakeSoundService extends SoundService {
  int playCount = 0;

  @override
  Future<bool> play(SoundOption option) async {
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
  });
}
