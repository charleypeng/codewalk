import 'package:codewalk/domain/entities/experience_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('data saver serialization', () {
    test('defaults cellular data saver to enabled', () {
      expect(ExperienceSettings.defaults().dataSaverEnabled, isTrue);
    });

    test('serializes and deserializes cellular data saver', () {
      final settings = ExperienceSettings.defaults().copyWith(
        dataSaverEnabled: false,
      );

      final json = settings.toJson();
      final restored = ExperienceSettings.fromJson(json);

      expect(json['dataSaverEnabled'], isFalse);
      expect(restored.dataSaverEnabled, isFalse);
    });
  });

  group('review changes serialization', () {
    test('defaults review changes display to enabled', () {
      expect(ExperienceSettings.defaults().showReviewChanges, isTrue);
    });

    test('serializes and deserializes review changes display', () {
      final settings = ExperienceSettings.defaults().copyWith(
        showReviewChanges: false,
      );

      final json = settings.toJson();
      final restored = ExperienceSettings.fromJson(json);

      expect(json['showReviewChanges'], isFalse);
      expect(restored.showReviewChanges, isFalse);
    });
  });

  group('performance logging serialization', () {
    test('defaults app logging to disabled', () {
      expect(ExperienceSettings.defaults().loggingEnabled, isFalse);
    });

    test('serializes and deserializes app logging', () {
      final settings = ExperienceSettings.defaults().copyWith(
        loggingEnabled: true,
      );

      final json = settings.toJson();
      final restored = ExperienceSettings.fromJson(json);

      expect(json['loggingEnabled'], isTrue);
      expect(restored.loggingEnabled, isTrue);
    });

    test('defaults missing app logging key to disabled', () {
      final restored = ExperienceSettings.fromJson(<String, dynamic>{});

      expect(restored.loggingEnabled, isFalse);
    });

    test('migrates explicit performance logging opt-in to app logging', () {
      final restored = ExperienceSettings.fromJson(<String, dynamic>{
        'performanceLoggingEnabled': true,
      });

      expect(restored.loggingEnabled, isTrue);
      expect(restored.performanceLoggingEnabled, isTrue);
    });

    test('preserves explicit app logging off over performance opt-in', () {
      final restored = ExperienceSettings.fromJson(<String, dynamic>{
        'loggingEnabled': false,
        'performanceLoggingEnabled': true,
      });

      expect(restored.loggingEnabled, isFalse);
      expect(restored.performanceLoggingEnabled, isTrue);
    });

    test('defaults performance logging to disabled', () {
      expect(ExperienceSettings.defaults().performanceLoggingEnabled, isFalse);
    });

    test('serializes and deserializes performance logging', () {
      final settings = ExperienceSettings.defaults().copyWith(
        performanceLoggingEnabled: true,
      );

      final json = settings.toJson();
      final restored = ExperienceSettings.fromJson(json);

      expect(json['performanceLoggingEnabled'], isTrue);
      expect(restored.performanceLoggingEnabled, isTrue);
    });
  });

  group('chat render mode serialization', () {
    test('defaults to live rendering', () {
      expect(ExperienceSettings.defaults().chatRenderMode, ChatRenderMode.live);
    });

    test('serializes and deserializes block rendering', () {
      final settings = ExperienceSettings.defaults().copyWith(
        chatRenderMode: ChatRenderMode.block,
      );

      final json = settings.toJson();
      final restored = ExperienceSettings.fromJson(json);

      expect(json['chatRenderMode'], 'block');
      expect(restored.chatRenderMode, ChatRenderMode.block);
    });

    test('keeps legacy sorted key mapped to block rendering', () {
      final restored = ExperienceSettings.fromJson(<String, dynamic>{
        'chatRenderMode': 'sorted',
      });

      expect(restored.chatRenderMode, ChatRenderMode.block);
    });

    test('falls back to live rendering for unknown keys', () {
      final restored = ExperienceSettings.fromJson(<String, dynamic>{
        'chatRenderMode': 'unknown',
      });

      expect(restored.chatRenderMode, ChatRenderMode.live);
    });
  });

  group('composer spell check serialization', () {
    test('defaults composer spell check to enabled', () {
      expect(ExperienceSettings.defaults().composerSpellCheckEnabled, isTrue);
    });

    test('keeps composer spell check enabled for older settings json', () {
      final restored = ExperienceSettings.fromJson(<String, dynamic>{});

      expect(restored.composerSpellCheckEnabled, isTrue);
    });

    test('serializes and deserializes disabled composer spell check', () {
      final settings = ExperienceSettings.defaults().copyWith(
        composerSpellCheckEnabled: false,
      );

      final json = settings.toJson();
      final restored = ExperienceSettings.fromJson(json);

      expect(json['composerSpellCheckEnabled'], isFalse);
      expect(restored.composerSpellCheckEnabled, isFalse);
    });
  });

  group('locale serialization', () {
    test('defaults to system locale', () {
      expect(ExperienceSettings.defaults().localeCode, isNull);
    });

    test('serializes and deserializes explicit locale code', () {
      final settings = ExperienceSettings.defaults().copyWith(
        localeCode: () => 'ar',
      );

      final json = settings.toJson();
      final restored = ExperienceSettings.fromJson(json);

      expect(json['localeCode'], 'ar');
      expect(restored.localeCode, 'ar');
    });
  });

  group('OpenCodeThemePreset serialization', () {
    test('serializes and deserializes catppuccin-macchiato', () {
      final settings = ExperienceSettings.defaults().copyWith(
        themePreset: () => OpenCodeThemePreset.catppuccinMacchiato,
      );

      final json = settings.toJson();
      final restored = ExperienceSettings.fromJson(json);

      expect(json['themePreset'], 'catppuccin-macchiato');
      expect(restored.themePreset, OpenCodeThemePreset.catppuccinMacchiato);
    });

    test('migrates legacy system preset to oc-2', () {
      final restored = ExperienceSettings.fromJson(<String, dynamic>{
        'themePreset': 'system',
      });

      expect(restored.themePreset, OpenCodeThemePreset.oc2);
    });

    test('keeps classic path when theme preset is absent', () {
      final restored = ExperienceSettings.fromJson(
        ExperienceSettings.defaults().toJson(),
      );

      expect(restored.themePreset, isNull);
    });
  });

  group('visual style serialization', () {
    test('defaults new installs to refined visual style', () {
      expect(ExperienceSettings.defaults().visualStyle, VisualStyle.refined);
    });

    test('serializes and deserializes refined visual style', () {
      final settings = ExperienceSettings.defaults().copyWith(
        visualStyle: VisualStyle.refined,
      );

      final json = settings.toJson();
      final restored = ExperienceSettings.fromJson(json);

      expect(json['visualStyle'], 'refined');
      expect(restored.visualStyle, VisualStyle.refined);
    });

    test('keeps legacy payloads classic when visual style key is missing', () {
      final restored = ExperienceSettings.fromJson(<String, dynamic>{});

      expect(restored.visualStyle, VisualStyle.classic);
    });

    test('falls back to classic for unknown visual style keys', () {
      final restored = ExperienceSettings.fromJson(<String, dynamic>{
        'visualStyle': 'future-style',
      });

      expect(restored.visualStyle, VisualStyle.classic);
    });
  });

  group('read-aloud provider serialization', () {
    test('defaults to native provider and OpenAI-compatible defaults', () {
      final defaults = ExperienceSettings.defaults();

      expect(defaults.readAloudProvider, ReadAloudProvider.native);
      expect(defaults.readAloudVoiceId, isNull);
      expect(defaults.readAloudVoiceLocale, isNull);
      expect(defaults.readAloudModel, kDefaultOpenAiCompatibleTtsModel);
      expect(defaults.readAloudBaseUrl, kDefaultOpenAiCompatibleTtsBaseUrl);
      expect(defaults.readAloudResponseFormat, kDefaultReadAloudResponseFormat);
    });

    test('serializes and deserializes provider fields without secrets', () {
      final settings = ExperienceSettings.defaults().copyWith(
        readAloudProvider: ReadAloudProvider.openAiCompatible,
        readAloudVoiceId: () => 'coral',
        readAloudVoiceLocale: () => 'en-US',
        readAloudModel: 'tts-1',
        readAloudBaseUrl: 'https://tts.example.com/v1',
        readAloudResponseFormat: 'mp3',
      );

      final json = settings.toJson();
      final restored = ExperienceSettings.fromJson(json);

      expect(json['readAloudProvider'], 'openai_compatible');
      expect(json['readAloudVoiceId'], 'coral');
      expect(json['readAloudVoiceLocale'], 'en-US');
      expect(json['readAloudModel'], 'tts-1');
      expect(json['readAloudBaseUrl'], 'https://tts.example.com/v1');
      expect(json['readAloudResponseFormat'], 'mp3');
      expect(json.containsKey('readAloudApiKey'), isFalse);
      expect(json.containsKey('apiKey'), isFalse);
      expect(restored.readAloudProvider, ReadAloudProvider.openAiCompatible);
      expect(restored.readAloudVoiceId, 'coral');
      expect(restored.readAloudVoiceLocale, 'en-US');
      expect(restored.readAloudModel, 'tts-1');
      expect(restored.readAloudBaseUrl, 'https://tts.example.com/v1');
      expect(restored.readAloudResponseFormat, 'mp3');
    });

    test('migrates legacy readAloudVoice to readAloudVoiceId', () {
      final restored = ExperienceSettings.fromJson(<String, dynamic>{
        'readAloudVoice': 'pt-br-x-tpf',
      });

      expect(restored.readAloudVoice, 'pt-br-x-tpf');
      expect(restored.readAloudVoiceId, 'pt-br-x-tpf');
    });

    test('normalizes base URL and response format while parsing', () {
      final restored = ExperienceSettings.fromJson(<String, dynamic>{
        'readAloudBaseUrl': 'https://tts.example.com/v1///',
        'readAloudResponseFormat': 'MP3',
      });

      expect(restored.readAloudBaseUrl, 'https://tts.example.com/v1');
      expect(restored.readAloudResponseFormat, 'mp3');
    });
  });

  group('font size fields', () {
    test('default values match safe scale center and terminal default', () {
      final defaults = ExperienceSettings.defaults();

      expect(defaults.systemFontScale, 1.0);
      expect(defaults.chatFontScale, 1.0);
      expect(defaults.terminalFontSize, kDefaultTerminalFontSize);
    });

    test('toJson emits all three font size fields with numeric values', () {
      final settings = ExperienceSettings.defaults().copyWith(
        systemFontScale: 1.2,
        chatFontScale: 1.4,
        terminalFontSize: 16.0,
      );

      final json = settings.toJson();

      expect(json['systemFontScale'], 1.2);
      expect(json['chatFontScale'], 1.4);
      expect(json['terminalFontSize'], 16.0);
    });

    test('round-trips font sizes through fromJson', () {
      final settings = ExperienceSettings.defaults().copyWith(
        systemFontScale: 0.9,
        chatFontScale: 1.5,
        terminalFontSize: 18.0,
      );

      final restored = ExperienceSettings.fromJson(settings.toJson());

      expect(restored.systemFontScale, 0.9);
      expect(restored.chatFontScale, 1.5);
      expect(restored.terminalFontSize, 18.0);
    });

    test('clamps out-of-range values when parsing from json', () {
      final restored = ExperienceSettings.fromJson(<String, dynamic>{
        'systemFontScale': 5.0,
        'chatFontScale': 0.1,
        'terminalFontSize': 99.0,
      });

      expect(restored.systemFontScale, kMaxSystemFontScale);
      expect(restored.chatFontScale, kMinChatFontScale);
      expect(restored.terminalFontSize, kMaxTerminalFontSize);
    });

    test('falls back to defaults when keys are missing from json', () {
      final restored = ExperienceSettings.fromJson(<String, dynamic>{});

      expect(restored.systemFontScale, 1.0);
      expect(restored.chatFontScale, 1.0);
      expect(restored.terminalFontSize, kDefaultTerminalFontSize);
    });

    test('copyWith changes only the specified field', () {
      final base = ExperienceSettings.defaults().copyWith(
        systemFontScale: 1.2,
        chatFontScale: 1.3,
        terminalFontSize: 15.0,
      );

      final updated = base.copyWith(chatFontScale: 1.0);

      expect(updated.systemFontScale, 1.2);
      expect(updated.chatFontScale, 1.0);
      expect(updated.terminalFontSize, 15.0);
    });

    test('clamp helpers expose the same min/max as the settings fields', () {
      expect(clampSystemFontScale(0.1), kMinSystemFontScale);
      expect(clampSystemFontScale(2.5), kMaxSystemFontScale);
      expect(clampSystemFontScale(1.25), 1.25);

      expect(clampChatFontScale(0.1), kMinChatFontScale);
      expect(clampChatFontScale(2.5), kMaxChatFontScale);
      expect(clampChatFontScale(0.9), 0.9);

      expect(clampTerminalFontSize(2.0), kMinTerminalFontSize);
      expect(clampTerminalFontSize(40.0), kMaxTerminalFontSize);
      expect(clampTerminalFontSize(14.0), 14.0);
    });
  });

  group('shortcutActionsForRuntime', () {
    test('includes soft and hard exit on Android physical-keyboard flows', () {
      final actions = shortcutActionsForRuntime(
        isWeb: false,
        targetPlatform: TargetPlatform.android,
        refreshlessRealtimeEnabled: true,
      );

      expect(actions, contains(ShortcutAction.closeApp));
      expect(actions, contains(ShortcutAction.quitApp));
      expect(actions, isNot(contains(ShortcutAction.refresh)));
    });

    test(
      'keeps soft and hard exit on desktop and restores refresh when enabled',
      () {
        final actions = shortcutActionsForRuntime(
          isWeb: false,
          targetPlatform: TargetPlatform.linux,
          refreshlessRealtimeEnabled: false,
        );

        expect(actions, contains(ShortcutAction.closeApp));
        expect(actions, contains(ShortcutAction.quitApp));
        expect(actions, contains(ShortcutAction.refresh));
      },
    );

    test('removes close and quit shortcuts on web', () {
      final actions = shortcutActionsForRuntime(
        isWeb: true,
        targetPlatform: TargetPlatform.android,
        refreshlessRealtimeEnabled: false,
      );

      expect(actions, isNot(contains(ShortcutAction.closeApp)));
      expect(actions, isNot(contains(ShortcutAction.quitApp)));
      expect(actions, contains(ShortcutAction.refresh));
    });

    test(
      'default bindings keep arrow keys free for native cursor navigation',
      () {
        const disallowedBindings = <String>{
          'mod+arrowup',
          'mod+arrowdown',
          'mod+arrowleft',
          'mod+arrowright',
        };

        for (final definition in kShortcutDefinitions) {
          expect(
            disallowedBindings.contains(
              definition.defaultBinding.toLowerCase(),
            ),
            isFalse,
            reason:
                'Default shortcut `${definition.defaultBinding}` should not consume native arrow navigation.',
          );
        }
      },
    );

    test('agent defaults avoid Ctrl+J line-feed interception', () {
      final defaults = {
        for (final definition in kShortcutDefinitions)
          definition.action: definition.defaultBinding,
      };

      expect(defaults[ShortcutAction.cycleAgentForward], 'alt+shift+j');
      expect(defaults[ShortcutAction.cycleAgentBackward], 'alt+shift+k');
      expect(defaults.values, isNot(contains('mod+j')));
      expect(defaults.values, isNot(contains('mod+shift+j')));
    });

    test('fromJson migrates old Ctrl+J agent bindings', () {
      final restored = ExperienceSettings.fromJson(<String, dynamic>{
        'shortcuts': <String, String>{
          'cycle_agent_forward': 'mod+j',
          'cycle_agent_backward': 'ctrl+shift+j',
        },
      });

      expect(
        restored.shortcuts[ShortcutAction.cycleAgentForward],
        'alt+shift+j',
      );
      expect(
        restored.shortcuts[ShortcutAction.cycleAgentBackward],
        'alt+shift+k',
      );
    });
  });
}
