import 'package:codewalk/domain/entities/experience_settings.dart';
import 'package:codewalk/presentation/theme/app_theme.dart';
import 'package:codewalk/presentation/theme/opencode_theme_presets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds light and dark material3 themes', () {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: AppTheme.seedColor,
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: AppTheme.seedColor,
      brightness: Brightness.dark,
    );

    final lightTheme = AppTheme.lightFrom(lightScheme);
    final darkTheme = AppTheme.darkFrom(darkScheme);

    expect(lightTheme.useMaterial3, isTrue);
    expect(darkTheme.useMaterial3, isTrue);
    expect(lightTheme.brightness, Brightness.light);
    expect(darkTheme.brightness, Brightness.dark);
  });

  test('maps density helpers consistently', () {
    expect(AppTheme.usesCompactLayout(AppDensity.extraDense), isTrue);
    expect(AppTheme.usesCompactLayout(AppDensity.dense), isTrue);
    expect(AppTheme.usesCompactLayout(AppDensity.normal), isFalse);

    expect(
      AppTheme.visualDensityFor(AppDensity.extraDense),
      const VisualDensity(horizontal: -2, vertical: -2),
    );
    expect(
      AppTheme.visualDensityFor(AppDensity.extraSpacious),
      const VisualDensity(horizontal: 2, vertical: 2),
    );
  });

  test(
    'resolves OpenCode theme presets without affecting classic fallback',
    () {
      final lightScheme = openCodeLightSchemeFor(OpenCodeThemePreset.nord);
      final darkScheme = openCodeDarkSchemeFor(OpenCodeThemePreset.nord);
      final systemScheme = openCodeLightSchemeFor(OpenCodeThemePreset.system);

      expect(lightScheme, isNotNull);
      expect(darkScheme, isNotNull);
      expect(systemScheme, isNotNull);
      expect(lightScheme!.brightness, Brightness.light);
      expect(darkScheme!.brightness, Brightness.dark);
      expect(openCodeThemePresetLabel(OpenCodeThemePreset.oneDark), 'One Dark');
      expect(openCodeDarkSchemeFor(null), isNull);
    },
  );
}
