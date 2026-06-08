import 'dart:convert';

import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/domain/entities/experience_settings.dart';
import 'package:codewalk/presentation/providers/settings_provider.dart';
import 'package:codewalk/presentation/services/sound_service.dart';
import 'package:dio/dio.dart';
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

    test('defaults cellular data saver to enabled', () async {
      final local = InMemoryAppLocalDataSource();
      final provider = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );

      await provider.initialize();

      expect(provider.dataSaverEnabled, isTrue);
    });

    test('persists cellular data saver changes', () async {
      final local = InMemoryAppLocalDataSource();
      final provider = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );

      await provider.initialize();
      await provider.setDataSaverEnabled(false);

      final raw = local.experienceSettingsJson;
      expect(raw, isNotNull);
      final settingsJson = jsonDecode(raw!) as Map<String, dynamic>;
      expect(settingsJson['dataSaverEnabled'], isFalse);
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

    test('persists pending post-onboarding chat tour flag', () async {
      final local = InMemoryAppLocalDataSource();
      final first = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await first.initialize();
      await first.setPendingPostOnboardingChatTour(true);

      final second = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await second.initialize();

      expect(second.pendingPostOnboardingChatTour, isTrue);

      await second.setPendingPostOnboardingChatTour(false);
      final raw = local.experienceSettingsJson;
      expect(raw, isNotNull);
      final settingsJson = jsonDecode(raw!) as Map<String, dynamic>;
      expect(settingsJson['pendingPostOnboardingChatTour'], isFalse);
    });

    test('persists Parakeet engine and selected model', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final local = InMemoryAppLocalDataSource();
      try {
        final first = SettingsProvider(
          localDataSource: local,
          dioClient: DioClient(),
          soundService: _FakeSoundService(),
        );
        await first.initialize();
        await first.setSpeechToTextEngine(SpeechToTextEngine.parakeet);
        await first.setParakeetModelId(kParakeetModelDefault);

        final second = SettingsProvider(
          localDataSource: local,
          dioClient: DioClient(),
          soundService: _FakeSoundService(),
        );
        await second.initialize();

        expect(second.speechToTextEngine, SpeechToTextEngine.parakeet);
        expect(second.parakeetModelId, kParakeetModelDefault);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    test(
      'defaults new Linux installs to Parakeet when native is unavailable',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        try {
          final local = InMemoryAppLocalDataSource();
          final provider = SettingsProvider(
            localDataSource: local,
            dioClient: DioClient(),
            soundService: _FakeSoundService(),
          );

          await provider.initialize();

          expect(provider.speechToTextEngine, SpeechToTextEngine.parakeet);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    test('persists SenseVoice engine and selected model', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final local = InMemoryAppLocalDataSource();
      try {
        final first = SettingsProvider(
          localDataSource: local,
          dioClient: DioClient(),
          soundService: _FakeSoundService(),
        );
        await first.initialize();
        await first.setSpeechToTextEngine(SpeechToTextEngine.sensevoice);
        await first.setSenseVoiceModelId(kSenseVoiceModelDefault);

        final second = SettingsProvider(
          localDataSource: local,
          dioClient: DioClient(),
          soundService: _FakeSoundService(),
        );
        await second.initialize();

        expect(second.speechToTextEngine, SpeechToTextEngine.sensevoice);
        expect(second.senseVoiceModelId, kSenseVoiceModelDefault);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
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

    test('persists review changes visibility toggle', () async {
      final local = InMemoryAppLocalDataSource();
      final first = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await first.initialize();

      expect(first.showReviewChanges, isTrue);

      await first.setShowReviewChanges(false);

      final second = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await second.initialize();

      expect(second.showReviewChanges, isFalse);
    });

    test('persists recent sessions visibility toggle', () async {
      final local = InMemoryAppLocalDataSource();
      final first = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await first.initialize();

      expect(first.showRecentSessions, isTrue);

      await first.setShowRecentSessions(true);

      final second = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await second.initialize();

      expect(second.showRecentSessions, isTrue);
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

    test(
      'persists speech engine, timeout, Sherpa language, and Moonshine model',
      () async {
        final local = InMemoryAppLocalDataSource();
        final first = SettingsProvider(
          localDataSource: local,
          dioClient: DioClient(),
          soundService: _FakeSoundService(),
        );
        await first.initialize();

        await first.setSpeechToTextEngine(SpeechToTextEngine.moonshine);
        await first.setSpeechSilenceTimeoutSeconds(7);
        await first.setSherpaLanguageCode('pt');
        await first.setMoonshineModelId(kMoonshineModelBase);

        final second = SettingsProvider(
          localDataSource: local,
          dioClient: DioClient(),
          soundService: _FakeSoundService(),
        );
        await second.initialize();

        // On Windows the on-device engines (Sherpa/Moonshine/Parakeet/SenseVoice)
        // are migrated to Native because the underlying `record_windows`
        // plugin can hard-crash the app (issue #43). On Linux/macOS the
        // selection persists as-is. On Android, iOS, and web it falls back to
        // Native for the slim-build engines.
        final expectedEngine = defaultTargetPlatform == TargetPlatform.linux ||
                defaultTargetPlatform == TargetPlatform.macOS
            ? SpeechToTextEngine.moonshine
            : SpeechToTextEngine.native;
        expect(second.speechToTextEngine, expectedEngine);
        expect(second.speechSilenceTimeoutSeconds, 7);
        expect(second.sherpaLanguageCode, 'pt');
        expect(second.moonshineModelId, kMoonshineModelBase);
      },
    );

    // Regression coverage for issue #43: the on-device STT engines
    // (Sherpa/Moonshine/Parakeet/SenseVoice) are disabled on Windows because
    // the underlying `record_windows` plugin can hard-crash the app. Existing
    // selections must be migrated to Native on initialize() so the user never
    // lands on a crashing engine selection.
    test(
      'migrates Windows on-device speech engine selections to Native',
      () async {
        for (final engine in const [
          SpeechToTextEngine.sherpa,
          SpeechToTextEngine.moonshine,
          SpeechToTextEngine.parakeet,
          SpeechToTextEngine.sensevoice,
        ]) {
          // Use the real persistence key (`speechToTextEngine`) consumed by
          // `ExperienceSettings.fromJson`; using a wrong key would silently
          // leave the default value in place and the migration branch would
          // never be exercised.
          final local = InMemoryAppLocalDataSource()
            ..experienceSettingsJson = jsonEncode({
              'speechToTextEngine': engine.name,
            });
          final provider = SettingsProvider(
            localDataSource: local,
            dioClient: DioClient(),
            soundService: _FakeSoundService(),
          );
          await provider.initialize();
          // On Windows, every on-device engine must migrate to Native. On
          // Linux/macOS the engines stay (they're supported). On Android/iOS
          // and web the existing platform migrations apply (Android migrates
          // all 4 to Native; iOS/Web keep Sherpa and migrate the rest).
          final expectedEngine = switch (defaultTargetPlatform) {
            TargetPlatform.windows => SpeechToTextEngine.native,
            TargetPlatform.android => SpeechToTextEngine.native,
            TargetPlatform.linux => engine,
            TargetPlatform.macOS => engine,
            // iOS: sherpa stays, others migrate; web: sherpa stays, others migrate.
            TargetPlatform.iOS => engine == SpeechToTextEngine.sherpa
                ? SpeechToTextEngine.sherpa
                : SpeechToTextEngine.native,
            _ => engine == SpeechToTextEngine.sherpa
                ? SpeechToTextEngine.sherpa
                : SpeechToTextEngine.native,
          };
          expect(
            provider.speechToTextEngine,
            expectedEngine,
            reason: 'platform=${defaultTargetPlatform.name} engine=${engine.name}',
          );
        }
      },
    );

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

    test('loads OpenCode-backed default model and agent options', () async {
      final local = InMemoryAppLocalDataSource();
      final adapter = _MockDioAdapter()
        ..enqueue(<_MockResponse>[
          _MockResponse(200, <String, dynamic>{}),
          _MockResponse(200, <String, dynamic>{
            'model': 'anthropic/claude-3-5-sonnet',
            'small_model': 'anthropic/claude-3-5-haiku',
            'default_agent': 'plan',
            'username': 'helio',
            'snapshot': false,
            'autoupdate': 'notify',
            'share': 'auto',
          }),
          _MockResponse(200, <String, dynamic>{
            'all': <dynamic>[
              <String, dynamic>{
                'id': 'anthropic',
                'name': 'Anthropic',
                'env': <String>['ANTHROPIC_API_KEY'],
                'models': <String, dynamic>{
                  'claude-3-5-sonnet': <String, dynamic>{
                    'id': 'claude-3-5-sonnet',
                    'name': 'Claude 3.5 Sonnet',
                    'release_date': '2025-01-01',
                    'capabilities': <String, dynamic>{
                      'attachment': true,
                      'reasoning': true,
                      'temperature': false,
                      'toolcall': true,
                    },
                    'cost': <String, dynamic>{'input': 1, 'output': 2},
                    'limit': <String, dynamic>{'context': 1000, 'output': 100},
                  },
                  'claude-3-5-haiku': <String, dynamic>{
                    'id': 'claude-3-5-haiku',
                    'name': 'Claude 3.5 Haiku',
                    'release_date': '2025-01-01',
                    'capabilities': <String, dynamic>{
                      'attachment': true,
                      'reasoning': true,
                      'temperature': false,
                      'toolcall': true,
                    },
                    'cost': <String, dynamic>{'input': 1, 'output': 2},
                    'limit': <String, dynamic>{'context': 1000, 'output': 100},
                  },
                },
              },
            ],
            'default': <String, String>{'anthropic': 'claude-3-5-sonnet'},
            'connected': <String>['anthropic'],
          }),
          _MockResponse(200, <dynamic>[
            <String, dynamic>{
              'name': 'build',
              'mode': 'primary',
              'hidden': false,
              'native': true,
            },
            <String, dynamic>{
              'name': 'plan',
              'mode': 'primary',
              'hidden': false,
              'native': true,
            },
            <String, dynamic>{
              'name': 'explore',
              'mode': 'subagent',
              'hidden': false,
              'native': true,
            },
          ]),
        ]);
      final dioClient = _buildDioClient(adapter);
      final provider = SettingsProvider(
        localDataSource: local,
        dioClient: dioClient,
        soundService: _FakeSoundService(),
      );

      await provider.initialize();
      await Future<void>.delayed(Duration.zero);
      await provider.refreshOpenCodeBackedDefaults();

      expect(provider.openCodeDefaultModelKey, 'anthropic/claude-3-5-sonnet');
      expect(provider.openCodeSmallModelKey, 'anthropic/claude-3-5-haiku');
      expect(provider.openCodeDefaultAgentName, 'plan');
      expect(provider.openCodeUsername, 'helio');
      expect(provider.openCodeSnapshotEnabled, isFalse);
      expect(provider.openCodeAutoupdateMode, OpenCodeAutoupdateMode.notify);
      expect(provider.openCodeShareMode, OpenCodeShareMode.automatic);
      expect(provider.openCodeDefaultModelOptions, hasLength(2));
      expect(
        provider.openCodeDefaultModelOptions
            .map((option) => option.label)
            .toList(growable: false),
        containsAll(<String>[
          'Anthropic / Claude 3.5 Sonnet',
          'Anthropic / Claude 3.5 Haiku',
        ]),
      );
      expect(
        provider.openCodeDefaultModelOptions
            .map((option) => option.key)
            .toList(growable: false),
        containsAll(<String>[
          'anthropic/claude-3-5-sonnet',
          'anthropic/claude-3-5-haiku',
        ]),
      );
      expect(
        provider.openCodeDefaultModelOptions.any((option) => option.connected),
        isTrue,
      );
      expect(provider.openCodeDefaultAgentOptions, <String>['build', 'plan']);
    });

    test('patches OpenCode-backed default model and agent', () async {
      final local = InMemoryAppLocalDataSource();
      final adapter = _MockDioAdapter()
        ..enqueue(<_MockResponse>[
          _MockResponse(200, <String, dynamic>{}),
          _MockResponse(200, <String, dynamic>{
            'model': 'anthropic/claude-3-5-sonnet',
            'small_model': 'anthropic/claude-3-5-haiku',
            'default_agent': 'plan',
            'username': 'helio',
            'snapshot': false,
            'autoupdate': true,
            'share': 'manual',
          }),
          _MockResponse(200, <String, dynamic>{
            'all': <dynamic>[
              <String, dynamic>{
                'id': 'anthropic',
                'name': 'Anthropic',
                'env': <String>['ANTHROPIC_API_KEY'],
                'models': <String, dynamic>{
                  'claude-3-5-sonnet': <String, dynamic>{
                    'id': 'claude-3-5-sonnet',
                    'name': 'Claude 3.5 Sonnet',
                    'release_date': '2025-01-01',
                    'capabilities': <String, dynamic>{
                      'attachment': true,
                      'reasoning': true,
                      'temperature': false,
                      'toolcall': true,
                    },
                    'cost': <String, dynamic>{'input': 1, 'output': 2},
                    'limit': <String, dynamic>{'context': 1000, 'output': 100},
                  },
                  'claude-3-5-haiku': <String, dynamic>{
                    'id': 'claude-3-5-haiku',
                    'name': 'Claude 3.5 Haiku',
                    'release_date': '2025-01-01',
                    'capabilities': <String, dynamic>{
                      'attachment': true,
                      'reasoning': true,
                      'temperature': false,
                      'toolcall': true,
                    },
                    'cost': <String, dynamic>{'input': 1, 'output': 2},
                    'limit': <String, dynamic>{'context': 1000, 'output': 100},
                  },
                },
              },
              <String, dynamic>{
                'id': 'openai',
                'name': 'OpenAI',
                'env': <String>['OPENAI_API_KEY'],
                'models': <String, dynamic>{
                  'gpt-5': <String, dynamic>{
                    'id': 'gpt-5',
                    'name': 'GPT 5',
                    'release_date': '2025-01-01',
                    'capabilities': <String, dynamic>{
                      'attachment': true,
                      'reasoning': true,
                      'temperature': false,
                      'toolcall': true,
                    },
                    'cost': <String, dynamic>{'input': 1, 'output': 2},
                    'limit': <String, dynamic>{'context': 1000, 'output': 100},
                  },
                },
              },
            ],
            'default': <String, String>{'anthropic': 'claude-3-5-sonnet'},
            'connected': <String>['anthropic', 'openai'],
          }),
          _MockResponse(200, <dynamic>[
            <String, dynamic>{
              'name': 'build',
              'mode': 'primary',
              'hidden': false,
              'native': true,
            },
            <String, dynamic>{
              'name': 'plan',
              'mode': 'primary',
              'hidden': false,
              'native': true,
            },
          ]),
          _MockResponse(200, true),
          _MockResponse(200, true),
          _MockResponse(200, true),
          _MockResponse(200, true),
          _MockResponse(200, true),
          _MockResponse(200, true),
          _MockResponse(200, true),
          _MockResponse(200, true),
          _MockResponse(200, true),
          _MockResponse(200, true),
          _MockResponse(200, true),
        ]);
      final dioClient = _buildDioClient(adapter);
      final provider = SettingsProvider(
        localDataSource: local,
        dioClient: dioClient,
        soundService: _FakeSoundService(),
      );

      await provider.initialize();
      await Future<void>.delayed(Duration.zero);
      await provider.refreshOpenCodeBackedDefaults();
      await provider.setOpenCodeDefaultModel('openai/gpt-5');
      await provider.setOpenCodeDefaultAgent('build');
      await provider.setOpenCodeUsername('codemaster');
      await provider.setOpenCodeSnapshotEnabled(true);
      await provider.setOpenCodeSmallModel('openai/gpt-5');
      await provider.setOpenCodeAutoupdateMode(OpenCodeAutoupdateMode.notify);
      await provider.setOpenCodeAutoupdateMode(OpenCodeAutoupdateMode.disabled);
      await provider.setOpenCodeAutoupdateMode(
        OpenCodeAutoupdateMode.automatic,
      );
      await provider.setOpenCodeShareMode(OpenCodeShareMode.automatic);
      await provider.setOpenCodeShareMode(OpenCodeShareMode.disabled);
      await provider.setOpenCodeShareMode(OpenCodeShareMode.manual);

      expect(provider.openCodeDefaultModelKey, 'openai/gpt-5');
      expect(provider.openCodeDefaultAgentName, 'build');
      expect(provider.openCodeUsername, 'codemaster');
      expect(provider.openCodeSnapshotEnabled, isTrue);
      expect(provider.openCodeSmallModelKey, 'openai/gpt-5');
      expect(provider.openCodeAutoupdateMode, OpenCodeAutoupdateMode.automatic);
      expect(provider.openCodeShareMode, OpenCodeShareMode.manual);

      final modelPatch = adapter.capturedRequests[4];
      expect(modelPatch.method, 'PATCH');
      expect(_decodeRequestData(modelPatch.data), <String, dynamic>{
        'model': 'openai/gpt-5',
      });

      final agentPatch = adapter.capturedRequests[5];
      expect(agentPatch.method, 'PATCH');
      expect(_decodeRequestData(agentPatch.data), <String, dynamic>{
        'default_agent': 'build',
      });

      final usernamePatch = adapter.capturedRequests[6];
      expect(usernamePatch.method, 'PATCH');
      expect(_decodeRequestData(usernamePatch.data), <String, dynamic>{
        'username': 'codemaster',
      });

      final snapshotPatch = adapter.capturedRequests[7];
      expect(snapshotPatch.method, 'PATCH');
      expect(_decodeRequestData(snapshotPatch.data), <String, dynamic>{
        'snapshot': true,
      });

      final smallModelPatch = adapter.capturedRequests[8];
      expect(smallModelPatch.method, 'PATCH');
      expect(_decodeRequestData(smallModelPatch.data), <String, dynamic>{
        'small_model': 'openai/gpt-5',
      });

      final autoupdateNotifyPatch = adapter.capturedRequests[9];
      expect(autoupdateNotifyPatch.method, 'PATCH');
      expect(_decodeRequestData(autoupdateNotifyPatch.data), <String, dynamic>{
        'autoupdate': 'notify',
      });

      final autoupdateDisabledPatch = adapter.capturedRequests[10];
      expect(autoupdateDisabledPatch.method, 'PATCH');
      expect(
        _decodeRequestData(autoupdateDisabledPatch.data),
        <String, dynamic>{'autoupdate': false},
      );

      final autoupdateAutomaticPatch = adapter.capturedRequests[11];
      expect(autoupdateAutomaticPatch.method, 'PATCH');
      expect(
        _decodeRequestData(autoupdateAutomaticPatch.data),
        <String, dynamic>{'autoupdate': true},
      );

      final shareAutomaticPatch = adapter.capturedRequests[12];
      expect(shareAutomaticPatch.method, 'PATCH');
      expect(_decodeRequestData(shareAutomaticPatch.data), <String, dynamic>{
        'share': 'auto',
      });

      final shareDisabledPatch = adapter.capturedRequests[13];
      expect(shareDisabledPatch.method, 'PATCH');
      expect(_decodeRequestData(shareDisabledPatch.data), <String, dynamic>{
        'share': 'disabled',
      });

      final shareManualPatch = adapter.capturedRequests[14];
      expect(shareManualPatch.method, 'PATCH');
      expect(_decodeRequestData(shareManualPatch.data), <String, dynamic>{
        'share': 'manual',
      });
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

    test('persists read-aloud settings with defaults', () async {
      final local = InMemoryAppLocalDataSource();
      final provider = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );

      await provider.initialize();

      expect(provider.readAloudEnabled, isTrue);
      expect(provider.readAloudRate, 0.5);
      expect(provider.readAloudPitch, 1.0);
      expect(provider.readAloudVoice, isNull);
    });

    test('persists read-aloud enabled change', () async {
      final local = InMemoryAppLocalDataSource();
      final first = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await first.initialize();
      await first.setReadAloudEnabled(false);

      final second = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await second.initialize();

      expect(second.readAloudEnabled, isFalse);
    });

    test('persists read-aloud rate change clamped to 0.0-1.0', () async {
      final local = InMemoryAppLocalDataSource();
      final first = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await first.initialize();
      await first.setReadAloudRate(0.75);

      final second = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await second.initialize();

      expect(second.readAloudRate, 0.75);

      await second.setReadAloudRate(1.5);
      expect(second.readAloudRate, 1.0);
      await second.setReadAloudRate(-0.5);
      expect(second.readAloudRate, 0.0);
    });

    test('persists read-aloud pitch change clamped to 0.5-2.0', () async {
      final local = InMemoryAppLocalDataSource();
      final first = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await first.initialize();
      await first.setReadAloudPitch(1.5);

      final second = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await second.initialize();

      expect(second.readAloudPitch, 1.5);

      await second.setReadAloudPitch(3.0);
      expect(second.readAloudPitch, 2.0);
      await second.setReadAloudPitch(0.1);
      expect(second.readAloudPitch, 0.5);
    });

    test('persists read-aloud voice change', () async {
      final local = InMemoryAppLocalDataSource();
      final first = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await first.initialize();
      await first.setReadAloudVoice('en-us-x-tpf');

      final second = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await second.initialize();

      expect(second.readAloudVoice, 'en-us-x-tpf');

      await second.setReadAloudVoice(null);
      expect(second.readAloudVoice, isNull);
    });

    test('read-aloud settings survive JSON roundtrip', () async {
      final local = InMemoryAppLocalDataSource();
      final first = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await first.initialize();
      await first.setReadAloudEnabled(false);
      await first.setReadAloudRate(0.9);
      await first.setReadAloudPitch(1.2);
      await first.setReadAloudVoice('pt-br-x-tpf');

      final raw = local.experienceSettingsJson;
      expect(raw, isNotNull);
      final json = jsonDecode(raw!) as Map<String, dynamic>;
      expect(json['readAloudEnabled'], isFalse);
      expect(json['readAloudRate'], 0.9);
      expect(json['readAloudPitch'], 1.2);
      expect(json['readAloudVoice'], 'pt-br-x-tpf');

      final second = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: _FakeSoundService(),
      );
      await second.initialize();

      expect(second.readAloudEnabled, isFalse);
      expect(second.readAloudRate, 0.9);
      expect(second.readAloudPitch, 1.2);
      expect(second.readAloudVoice, 'pt-br-x-tpf');
    });
  });
}

class _MockResponse {
  _MockResponse(this.statusCode, this.data);

  final int statusCode;
  final dynamic data;
  bool get isError => statusCode >= 400;
}

class _MockDioAdapter implements HttpClientAdapter {
  final List<_MockResponse> _responses = <_MockResponse>[];
  final List<RequestOptions> capturedRequests = <RequestOptions>[];
  int callCount = 0;

  void enqueue(List<_MockResponse> items) {
    _responses.addAll(items);
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    capturedRequests.add(options);

    if (callCount >= _responses.length) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'No more mock responses (call #$callCount)',
      );
    }

    final mock = _responses[callCount];
    callCount += 1;

    if (mock.isError) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: mock.statusCode,
          data: mock.data,
        ),
      );
    }

    return ResponseBody.fromString(
      _encode(mock.data),
      mock.statusCode,
      headers: <String, List<String>>{
        'content-type': <String>['application/json'],
      },
    );
  }

  String _encode(dynamic data) {
    if (data == null) {
      return '';
    }
    if (data is String) {
      return data;
    }
    return jsonEncode(data);
  }

  @override
  void close({bool force = false}) {}
}

DioClient _buildDioClient(_MockDioAdapter adapter) {
  final dioClient = DioClient();
  dioClient.dio.httpClientAdapter = adapter;
  return dioClient;
}


dynamic _decodeRequestData(dynamic data) {
  if (data is String) {
    return jsonDecode(data);
  }
  return data;
}
