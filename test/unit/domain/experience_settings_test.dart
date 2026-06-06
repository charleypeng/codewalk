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
  });
}
