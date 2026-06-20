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

  test('scales composer model controls by density', () {
    expect(
      AppDensitySpacing.composerModelControlsPadding(AppDensity.normal),
      const EdgeInsets.fromLTRB(8, 0, 8, 2),
    );
    expect(AppDensitySpacing.composerModelControlGap(AppDensity.normal), 8);
    expect(
      AppDensitySpacing.composerModelControlChipPadding(AppDensity.normal),
      const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
    expect(
      AppDensitySpacing.composerModelControlButtonPadding(AppDensity.normal),
      const EdgeInsets.all(8),
    );
    expect(
      AppDensitySpacing.composerModelControlButtonSize(AppDensity.normal),
      const Size.square(40),
    );

    expect(
      AppDensitySpacing.composerModelControlGap(AppDensity.extraDense),
      lessThan(AppDensitySpacing.composerModelControlGap(AppDensity.normal)),
    );
    expect(
      AppDensitySpacing.composerModelControlGap(AppDensity.extraSpacious),
      greaterThan(AppDensitySpacing.composerModelControlGap(AppDensity.normal)),
    );
    expect(
      AppDensitySpacing.composerModelControlButtonSize(
        AppDensity.extraDense,
      ).width,
      lessThan(
        AppDensitySpacing.composerModelControlButtonSize(
          AppDensity.normal,
        ).width,
      ),
    );
    expect(
      AppDensitySpacing.composerModelControlButtonSize(
        AppDensity.extraSpacious,
      ).width,
      greaterThan(
        AppDensitySpacing.composerModelControlButtonSize(
          AppDensity.normal,
        ).width,
      ),
    );
  });

  test(
    'resolves OpenCode theme presets without affecting classic fallback',
    () {
      final lightScheme = openCodeLightSchemeFor(OpenCodeThemePreset.nord);
      final darkScheme = openCodeDarkSchemeFor(OpenCodeThemePreset.nord);
      final oc2Scheme = openCodeLightSchemeFor(OpenCodeThemePreset.oc2);
      final auraTokens = openCodeThemeTokensFor(
        OpenCodeThemePreset.aura,
        Brightness.dark,
      );

      expect(lightScheme, isNotNull);
      expect(darkScheme, isNotNull);
      expect(oc2Scheme, isNotNull);
      expect(auraTokens, isNotNull);
      expect(lightScheme!.brightness, Brightness.light);
      expect(darkScheme!.brightness, Brightness.dark);
      expect(auraTokens!.themeId, 'aura');
      expect(openCodeThemePresetOptions(), hasLength(37));
      expect(openCodeThemePresetLabel(OpenCodeThemePreset.oneDark), 'One Dark');
      expect(openCodeDarkSchemeFor(null), isNull);
    },
  );

  test('resolves theme-specific markdown and syntax tokens', () {
    final oc2Tokens = openCodeThemeTokensFor(
      OpenCodeThemePreset.oc2,
      Brightness.dark,
    );
    final githubTokens = openCodeThemeTokensFor(
      OpenCodeThemePreset.github,
      Brightness.light,
    );

    expect(oc2Tokens, isNotNull);
    expect(githubTokens, isNotNull);
    expect(
      oc2Tokens!.markdownInlineCode,
      isNot(githubTokens!.markdownInlineCode),
    );
    expect(
      oc2Tokens.codeBlockBackground,
      isNot(githubTokens.codeBlockBackground),
    );
    expect(oc2Tokens.syntaxKeyword, isNot(githubTokens.syntaxKeyword));
  });
}
