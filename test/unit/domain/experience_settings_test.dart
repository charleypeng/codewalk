import 'package:codewalk/domain/entities/experience_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
