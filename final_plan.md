# Execution Plan — Issue #86: CodeWalk Refined Visual Layer

## Status

Ready.

This plan is self-contained and authoritative for a future implementation session. Execute it without relying on prior chat history, planner outputs, or hidden context.

## Problem

GitHub issue #86 (`https://github.com/verseles/codewalk/issues/86`) asks for a visual revamp of CodeWalk toward a more neutral, lighter, quieter, more refined UI with less default Material Design appearance. The issue explicitly requires research and a developer decision before broad implementation, but the selected implementation direction for this plan is now fixed: deliver a first incremental, reversible `CodeWalk Refined` visual style over the existing Flutter Material stack.

The current app already has a Material/Material You architecture: `MaterialApp`, `ThemeData(useMaterial3: true)`, `ColorScheme.fromSeed`, dynamic color, AMOLED dark mode, OpenCode Web theme presets, Material Symbols, `AppShapes`, `AppDensitySpacing`, and 14 localized languages. The challenge is to reduce the visible Material feel without replacing the app architecture, without imitating iOS, and without breaking mobile, desktop, web, accessibility, focus, keyboard navigation, RTL, OpenCode presets, dynamic color, or AMOLED mode.

## Objective

Implement a first, safe visual-revamp slice named `CodeWalk Refined` that:

- Adds a persisted `VisualStyle` setting with two values: `classic` and `refined`.
- Keeps `classic` as the default and preserves the current look unless the user opts into `refined`.
- Applies `refined` as a token-driven visual layer over the existing Material stack, not as a new design-system package.
- Improves the highest-impact surfaces first: theme-level components, settings appearance controls, chat composer, chat message bubbles, chat chrome/status, and conversation/sidebar/session rows.
- Preserves OpenCode theme presets, dynamic color, AMOLED dark mode, density tiers, Material Symbols, RTL, localization, focus/keyboard states, and accessibility.
- Updates tests and docs so the behavior is durable and understandable.

## Context and Constraints

### Repository and platform context

- Repository root: `/home/ubuntu/MEGA/WORK/codewalk`.
- GitHub repository: `verseles/codewalk`.
- Project: Flutter client for OpenCode-compatible servers.
- Targets: Android, Linux, macOS, Windows, and Web.
- State management: `provider`.
- Dependency injection: `get_it`.
- Architecture: `presentation -> domain -> data`.
- User-facing strings are localized in 14 locales under `lib/l10n/app_*.arb`, with generated files under `lib/l10n/generated/`.

### Mandatory project rules

- Read `BEHAVIOR.md` before substantial implementation work.
- For behavior changes, keep `BEHAVIOR.md` aligned with implemented behavior only.
- Update `ADR.md` when adopting a design-system decision or material visual architecture change.
- Update `CODEBASE.md` when theme/component structure changes.
- Do not run `make precommit`; use focused Flutter validation while iterating and `make check` at the final validation gate.
- For Flutter commands in non-interactive shells, prepend `export PATH="$HOME/flutter/bin:$PATH" && ...`.
- Do not run destructive i18n tooling. In particular, do not run `dart tool/i18n/generate_arb.dart` globally unless `arb_strings.dart` is proven synchronized with every existing ARB key.

### Current relevant files

- `lib/main.dart` — builds light/dark `ThemeData`, resolves dynamic color, OpenCode presets, AMOLED dark, contrast, and theme extensions.
- `lib/domain/entities/experience_settings.dart` — persisted settings model; currently contains `ThemeModeOption`, `OpenCodeThemePreset`, `AppDensity`, `useAmoledDark`, `useDynamicColor`, `customColorSeed`, and `contrastLevel`.
- `lib/presentation/providers/settings_provider.dart` — settings getters/setters/persistence.
- `lib/presentation/theme/app_theme.dart` — `ThemeData` builder and `AppDensitySpacing`.
- `lib/presentation/theme/app_shapes.dart` — MD3 shape constants: `4/8/12/16/28/999`.
- `lib/presentation/theme/app_semantic_colors.dart` — currently centralizes only success colors.
- `lib/presentation/theme/opencode_theme_presets.dart` — OpenCode Web theme preset bridge and `OpenCodeThemeTokens` `ThemeExtension`.
- `lib/presentation/theme/opencode_highlight_theme.dart` — syntax highlighting token mapping.
- `lib/presentation/theme/opencode_web_theme_registry.dart` — generated OpenCode Web theme registry.
- `lib/presentation/pages/settings/sections/appearance_settings_section.dart` — user-facing appearance settings.
- `lib/presentation/widgets/chat_input_widget.dart` — composer surface. Existing hotspots include `Typography.material2021(platform: TargetPlatform.android)` indirectly via `AppTheme`, composer bubble `surfaceContainerHighest` alpha blending, `AppShapes.borderExtraLarge`, hardcoded black shadow alpha `0.07`, and send button elevation `1.5`.
- `lib/presentation/widgets/chat_message/chat_message_content.dart` — message bubbles. Existing hotspots include `AppShapes.borderLarge`, asymmetric `Radius.circular(6)`, user bubble `primaryContainer.withValues(alpha: 0.45)`, assistant bubble `surfaceContainerHigh`.
- `lib/presentation/pages/chat_page/chat_page_chrome.dart` — chat app chrome/status/control surfaces.
- `lib/presentation/pages/chat_page/chat_page_scaffold.dart` — conversation sidebar/project/recent/session surfaces.
- `lib/presentation/pages/chat_page/chat_page_status_presenter.dart` — status chips/menu styling.
- `lib/presentation/widgets/chat_session_list.dart` — session row surfaces and selected affordances.
- `BEHAVIOR.md` — current behavior spec.
- `ADR.md` — active architecture decisions. Latest known index includes ADR-044; add ADR-045 for this work.
- `CODEBASE.md` — code map.

### Current dependencies and explicit exclusions

- Existing relevant dependencies include `dynamic_color`, `material_symbols_icons`, `flutter_svg`, `showcaseview`, `flutter_markdown_plus`, `flutter_mermaid`, `flutter_math_fork`, `re_editor`, and `re_highlight`.
- Do not add `forui`, `mix`, `shadcn_flutter`, `shadcn_ui`, `fluent_ui`, `macos_ui`, or any other visual/design-system package in this implementation.
- Do not remove or replace `material_symbols_icons` in this implementation.
- Do not remove `uses-material-design: true` in this implementation.
- Do not remove `cupertino_icons` in this implementation; it is out of scope even if it appears unused.

## Decisions (Resolved)

1. Keep the existing `MaterialApp` and Material 3 foundation. The first implementation is a custom CodeWalk visual layer, not a third-party component library or platform-mimicking UI kit.
2. Add a persisted `VisualStyle` enum with values `classic` and `refined`; default to `classic` for backward-compatible rollout.
3. Implement `refined` through `ThemeData` adjustments plus a new `ThemeExtension` for CodeWalk surface/radius/treatment tokens.
4. Keep `AppShapes` constants unchanged. Do not globally reduce `AppShapes.large` or `AppShapes.extraLarge`; doing so would alter `classic` and cause avoidable regressions. Refined-specific radii must live in the new token extension.
5. Keep `OpenCodeThemePreset` behavior intact. `refined` changes surface treatment, radii, typography weight/metrics, outlines, shadows, and selected-row/chrome presentation, but it must not replace OpenCode preset color identity or syntax-highlight tokens.
6. Keep dynamic color and AMOLED mode intact. `refined` must work with dynamic `ColorScheme`s and with `_applyAmoledDarkScheme()`.
7. Keep Material Symbols. Icon replacement is a separate high-scope migration and is explicitly out of scope.
8. Avoid blur/vibrancy/backdrop-filter effects in this first implementation. They are visually tempting but risky on Linux desktop and Web.
9. Treat accessibility as a gate, not a preference. Refined focus borders, selection indicators, disabled states, contrast, touch targets, and keyboard navigation must remain visible and usable.
10. Update documentation in the same implementation: add ADR-045, add BEHAVIOR coverage for the Visual Style setting, and update CODEBASE if new theme files are added.

## Why This Plan

The app is already deeply integrated with Flutter Material components, OpenCode preset themes, dynamic color, and CodeWalk-specific density and token systems. Replacing the component library would be a high-risk rewrite that conflicts with issue #86's incremental constraint. A token-first `CodeWalk Refined` layer gives the desired visual direction while preserving current architecture, platform behavior, accessibility guarantees, and rollback safety.

## Overview

Add a new user setting, `Visual style`, under Settings > Appearance. `Classic` preserves the current look. `Refined` applies quieter surfaces, smaller refined radii, reduced surface tint, subtler separators, reduced shadows, and more neutral typography treatment across the highest-impact UI surfaces. The implementation must be opt-in, reversible, localized, tested, and documented.

## Steps

### 1. Add `VisualStyle` to persisted experience settings

- **Files**:
  - `lib/domain/entities/experience_settings.dart`
  - `test/unit/domain/experience_settings_test.dart`

- **Details**:
  1. Add this enum near the existing theme-related enums:

     ```dart
     enum VisualStyle { classic, refined }
     ```

  2. Add conversion helpers near `themeModeOptionKey` / `themeModeOptionFromKey`:

     ```dart
     String visualStyleKey(VisualStyle style) {
       return switch (style) {
         VisualStyle.classic => 'classic',
         VisualStyle.refined => 'refined',
       };
     }

     VisualStyle visualStyleFromKey(String value) {
       return switch (value.trim().toLowerCase()) {
         'refined' => VisualStyle.refined,
         _ => VisualStyle.classic,
       };
     }
     ```

  3. Add `visualStyle: VisualStyle.classic` to `ExperienceSettings.defaults()`.
  4. Add `this.visualStyle = VisualStyle.classic` to the constructor.
  5. Add `final VisualStyle visualStyle;` near `themeMode`, `themePreset`, and appearance fields.
  6. Add `VisualStyle? visualStyle` to `copyWith()` and pass `visualStyle: visualStyle ?? this.visualStyle` into the returned `ExperienceSettings`.
  7. Add `'visualStyle': visualStyleKey(visualStyle),` to `toJson()` near `themeMode` / `themePreset`.
  8. In `fromJson()`, initialize `var visualStyle = defaults.visualStyle;`, parse `json['visualStyle']` when it is a non-empty string using `visualStyleFromKey`, and pass `visualStyle: visualStyle` to the returned `ExperienceSettings`.
  9. Preserve backward compatibility: missing or unknown `visualStyle` must resolve to `VisualStyle.classic`.
  10. Add or update unit tests to verify:
      - default settings use `VisualStyle.classic`;
      - `VisualStyle.refined` round-trips through JSON as `'refined'`;
      - missing `visualStyle` falls back to `classic`;
      - unknown `visualStyle` falls back to `classic`.

- **Risk**: Low. The new field is backward-compatible and defaults to the existing style.
- **Validation**:
  - `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/domain/experience_settings_test.dart`

### 2. Expose `VisualStyle` through `SettingsProvider`

- **Files**:
  - `lib/presentation/providers/settings_provider.dart`
  - `test/unit/providers/settings_provider_test.dart`

- **Details**:
  1. Add getter near other appearance getters:

     ```dart
     VisualStyle get visualStyle => _settings.visualStyle;
     ```

  2. Add setter near `setThemeMode`, `setThemePreset`, and other appearance setters:

     ```dart
     Future<void> setVisualStyle(VisualStyle style) async {
       if (_settings.visualStyle == style) {
         return;
       }
       _settings = _settings.copyWith(visualStyle: style);
       notifyListeners();
       await _persist();
     }
     ```

  3. Add provider tests to verify:
      - the default getter returns `VisualStyle.classic`;
      - `setVisualStyle(VisualStyle.refined)` updates state and persists JSON containing `'visualStyle': 'refined'`;
      - setting the same style is a no-op.

- **Risk**: Low. Follows existing provider patterns.
- **Validation**:
  - `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/providers/settings_provider_test.dart`

### 3. Add CodeWalk visual token extension

- **Files**:
  - Add `lib/presentation/theme/app_visual_style_tokens.dart`
  - `lib/presentation/theme/app_theme.dart`
  - `test/unit/presentation/app_theme_test.dart`

- **Details**:
  1. Create `lib/presentation/theme/app_visual_style_tokens.dart` with a `ThemeExtension` named `AppVisualStyleTokens`.
  2. The class must include these fields at minimum:

     ```dart
     final VisualStyle visualStyle;
     final BorderRadius cardRadius;
     final BorderRadius controlRadius;
     final BorderRadius panelRadius;
     final BorderRadius dialogRadius;
     final BorderRadius bubbleRadius;
     final Radius bubbleTightCornerRadius;
     final Color cardSurface;
     final Color panelSurface;
     final Color composerSurface;
     final Color mutedControlSurface;
     final Color selectedSurface;
     final Color separator;
     final Color focusBorder;
     final Color softShadow;
     final double dividerThickness;
     final double focusedBorderWidth;
     final double enabledBorderWidth;
     final List<BoxShadow> composerShadow;
     ```

  3. Implement `copyWith()` and `lerp()` correctly. Use `BorderRadius.lerp`, `Radius.lerp`, `Color.lerp`, numeric interpolation, and choose `visualStyle` from `other` when `t >= 0.5`.
  4. Add factory `AppVisualStyleTokens.classic(ColorScheme colorScheme, Brightness brightness)` with values that preserve current behavior as closely as possible:
      - `visualStyle: VisualStyle.classic`
      - `cardRadius: AppShapes.borderExtraLarge`
      - `controlRadius: AppShapes.borderLarge`
      - `panelRadius: AppShapes.borderLarge`
      - `dialogRadius: AppShapes.borderExtraLarge`
      - `bubbleRadius: AppShapes.borderLarge`
      - `bubbleTightCornerRadius: const Radius.circular(6)`
      - `cardSurface: colorScheme.surfaceContainerLow`
      - `panelSurface: colorScheme.surfaceContainer`
      - `composerSurface`: current composer normal bubble behavior, resolved against `colorScheme.surface` with `surfaceContainerHighest` alpha `0.94` in dark mode and `0.96` in light mode.
      - `mutedControlSurface: colorScheme.surfaceContainerHighest`
      - `selectedSurface: colorScheme.secondaryContainer`
      - `separator: colorScheme.outlineVariant`
      - `focusBorder: colorScheme.primary`
      - `softShadow: Colors.black.withValues(alpha: 0.07)`
      - `dividerThickness: 1`
      - `enabledBorderWidth: 1`
      - `focusedBorderWidth: 2`
      - `composerShadow`: one `BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 12, offset: Offset(0, 2))`
  5. Add factory `AppVisualStyleTokens.refined(ColorScheme colorScheme, Brightness brightness)` with these fixed values:
      - `visualStyle: VisualStyle.refined`
      - `cardRadius: BorderRadius.circular(14)`
      - `controlRadius: BorderRadius.circular(12)`
      - `panelRadius: BorderRadius.circular(14)`
      - `dialogRadius: BorderRadius.circular(20)`
      - `bubbleRadius: BorderRadius.circular(14)`
      - `bubbleTightCornerRadius: const Radius.circular(5)`
      - `cardSurface: Color.alphaBlend(colorScheme.surfaceContainerHighest.withValues(alpha: brightness == Brightness.dark ? 0.18 : 0.14), colorScheme.surface)`
      - `panelSurface: Color.alphaBlend(colorScheme.surfaceContainerHighest.withValues(alpha: brightness == Brightness.dark ? 0.14 : 0.10), colorScheme.surface)`
      - `composerSurface: Color.alphaBlend(colorScheme.surfaceContainerHighest.withValues(alpha: brightness == Brightness.dark ? 0.34 : 0.28), colorScheme.surface)`
      - `mutedControlSurface: Color.alphaBlend(colorScheme.surfaceContainerHighest.withValues(alpha: brightness == Brightness.dark ? 0.28 : 0.22), colorScheme.surface)`
      - `selectedSurface: Color.alphaBlend(colorScheme.primary.withValues(alpha: brightness == Brightness.dark ? 0.18 : 0.12), colorScheme.surface)`
      - `separator: colorScheme.outlineVariant.withValues(alpha: brightness == Brightness.dark ? 0.48 : 0.58)`
      - `focusBorder: colorScheme.primary`
      - `softShadow: Colors.black.withValues(alpha: brightness == Brightness.dark ? 0.16 : 0.035)`
      - `dividerThickness: 0.75`
      - `enabledBorderWidth: 0.75`
      - `focusedBorderWidth: 1.5`
      - `composerShadow`: one `BoxShadow(color: Colors.black.withValues(alpha: brightness == Brightness.dark ? 0.12 : 0.035), blurRadius: 8, offset: Offset(0, 1))`
  6. Add a helper extension for safe access:

     ```dart
     extension AppVisualStyleTokensX on ThemeData {
       AppVisualStyleTokens get visualStyleTokens =>
           extension<AppVisualStyleTokens>() ??
           AppVisualStyleTokens.classic(colorScheme, brightness);
     }
     ```

  7. Export/import this file where needed. Keep imports local and explicit; do not create a barrel unless existing project style strongly prefers it.
  8. Add tests verifying:
      - `AppTheme.lightFrom(..., visualStyle: VisualStyle.classic)` contains `AppVisualStyleTokens` with `VisualStyle.classic`;
      - `AppTheme.lightFrom(..., visualStyle: VisualStyle.refined)` contains `AppVisualStyleTokens` with `VisualStyle.refined`;
      - refined radii differ from classic radii;
      - refined composer shadow is lower opacity than classic in light mode;
      - existing `OpenCodeThemeTokens` remains present when passed in `themeExtensions`.

- **Risk**: Medium. The token layer is foundational; incorrect interpolation or missing extension wiring can affect theme construction.
- **Validation**:
  - `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/presentation/app_theme_test.dart`

### 4. Wire `VisualStyle` into `AppTheme` and `main.dart`

- **Files**:
  - `lib/presentation/theme/app_theme.dart`
  - `lib/main.dart`
  - `test/unit/presentation/app_theme_test.dart`

- **Details**:
  1. In `app_theme.dart`, import:

     ```dart
     import 'package:flutter/foundation.dart';
     import 'app_visual_style_tokens.dart';
     ```

  2. Add a `VisualStyle visualStyle = VisualStyle.classic` named parameter to `AppTheme.lightFrom()` and `AppTheme.darkFrom()`.
  3. Pass `visualStyle` into `_buildTheme()`.
  4. Add `required VisualStyle visualStyle` to `_buildTheme()`.
  5. At the start of `_buildTheme()`, build tokens:

     ```dart
     final visualTokens = visualStyle == VisualStyle.refined
         ? AppVisualStyleTokens.refined(colorScheme, brightness)
         : AppVisualStyleTokens.classic(colorScheme, brightness);
     ```

  6. Ensure `extensions` includes both caller-provided extensions and the visual tokens:

     ```dart
     extensions: <ThemeExtension<dynamic>>[
       ...themeExtensions,
       visualTokens,
     ],
     ```

     Do not drop `OpenCodeThemeTokens` passed by `main.dart`.

  7. Preserve classic behavior by keeping existing values when `visualStyle == VisualStyle.classic`.
  8. For refined only, adjust theme-level components using `visualTokens`:
      - `textTheme`: for `classic`, keep existing `Typography.material2021(platform: TargetPlatform.android, colorScheme: colorScheme).black`. For `refined`, use `Typography.material2021(platform: defaultTargetPlatform, colorScheme: colorScheme).black` and apply the same `bodyColor`/`displayColor`. Do not add a font dependency.
      - `appBarTheme.surfaceTintColor`: use `Colors.transparent` for refined; keep `colorScheme.surfaceTint` for classic.
      - `cardTheme.color`: use `visualTokens.cardSurface` for refined; keep `colorScheme.surfaceContainerLow` for classic.
      - `cardTheme.shape`: use `visualTokens.cardRadius` and add `side: BorderSide(color: visualTokens.separator, width: visualTokens.enabledBorderWidth)` for refined only.
      - `dividerTheme.color`: use `visualTokens.separator` for refined; keep `colorScheme.outlineVariant` for classic.
      - `dividerTheme.thickness`: use `visualTokens.dividerThickness` for refined; keep `1` for classic.
      - `inputDecorationTheme.fillColor`: use `visualTokens.mutedControlSurface` for refined; keep current fill for classic.
      - `inputDecorationTheme.enabledBorder` and `border`: use `visualTokens.controlRadius`, `visualTokens.separator`, and `visualTokens.enabledBorderWidth` for refined.
      - `inputDecorationTheme.focusedBorder`: use `visualTokens.controlRadius`, `visualTokens.focusBorder`, and `visualTokens.focusedBorderWidth` for refined.
      - `listTileTheme.shape`: use `visualTokens.controlRadius` for refined.
      - `navigationBarTheme.backgroundColor`: use `colorScheme.surface` for refined; keep `surfaceContainer` for classic.
      - `navigationBarTheme.indicatorColor`: use `visualTokens.selectedSurface` for refined; keep `secondaryContainer` for classic.
      - `navigationRailTheme.backgroundColor`: use `visualTokens.panelSurface` for refined; keep `surfaceContainerLow` for classic.
      - `navigationRailTheme.indicatorColor`: use `visualTokens.selectedSurface` for refined.
      - `floatingActionButtonTheme`: set `elevation: 0`, `focusElevation: 0`, `hoverElevation: 0`, `highlightElevation: 0`, and shape `RoundedRectangleBorder(borderRadius: AppShapes.borderFull)` for refined.
      - `chipTheme.shape`: use `visualTokens.controlRadius` for refined; keep `AppShapes.borderSmall` for classic.
      - `filledButtonTheme`, `elevatedButtonTheme`, `outlinedButtonTheme`, `textButtonTheme`: use `visualTokens.controlRadius` for refined; keep current shapes for classic.
      - `bottomSheetTheme.shape` and `dialogTheme.shape`: use `visualTokens.dialogRadius` for refined; keep `AppShapes.extraLarge` for classic.
      - `bottomSheetTheme.surfaceTintColor` and `dialogTheme.surfaceTintColor`: use `Colors.transparent` for refined.
  9. In `main.dart`, read `final visualStyle = settingsProvider.visualStyle;` beside existing appearance settings and pass it to both `AppTheme.lightFrom()` and `AppTheme.darkFrom()`.
  10. Do not change `_applyAmoledDarkScheme()`.

- **Risk**: Medium. This touches global theme construction; classic must remain unchanged.
- **Validation**:
  - `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/presentation/app_theme_test.dart`
  - `export PATH="$HOME/flutter/bin:$PATH" && flutter analyze lib/main.dart lib/presentation/theme/app_theme.dart lib/presentation/theme/app_visual_style_tokens.dart`

### 5. Add the Visual Style control to Settings > Appearance

- **Files**:
  - `lib/presentation/pages/settings/sections/appearance_settings_section.dart`
  - `lib/l10n/app_en.arb`
  - `lib/l10n/app_ar.arb`
  - `lib/l10n/app_bn.arb`
  - `lib/l10n/app_de.arb`
  - `lib/l10n/app_es.arb`
  - `lib/l10n/app_fr.arb`
  - `lib/l10n/app_hi.arb`
  - `lib/l10n/app_it.arb`
  - `lib/l10n/app_ja.arb`
  - `lib/l10n/app_ko.arb`
  - `lib/l10n/app_pt.arb`
  - `lib/l10n/app_ru.arb`
  - `lib/l10n/app_ur.arb`
  - `lib/l10n/app_zh.arb`
  - `lib/l10n/generated/` after `flutter gen-l10n`
  - `test/widget/settings_page_test.dart`

- **Details**:
  1. In `appearance_settings_section.dart`, compute:

     ```dart
     final selectedVisualStyle = settingsProvider.visualStyle;
     ```

  2. Inside the first theme card, after the existing CodeWalk Classic/OpenCode Presets segmented control and before the AMOLED switch, add a new full-width `SegmentedButton<VisualStyle>` with key `ValueKey<String>('settings_visual_style_segmented')`.
  3. Segments:
      - `VisualStyle.classic`, label `context.l10n.settingsAppearanceVisualStyleClassic`, icon `Symbols.dashboard_customize`.
      - `VisualStyle.refined`, label `context.l10n.settingsAppearanceVisualStyleRefined`, icon `Symbols.auto_awesome`.
  4. Add a section title and helper copy immediately above the segmented control:
      - title: `context.l10n.settingsAppearanceVisualStyle`
      - description: `context.l10n.settingsAppearanceVisualStyleDescription`
  5. Use `onSelectionChanged: (selected) => unawaited(settingsProvider.setVisualStyle(selected.first))`.
  6. Do not disable this setting when OpenCode presets are active. Refined must work with both CodeWalk classic palette and OpenCode presets.
  7. Add these ARB keys to every locale file, preserving metadata entries:

     English (`app_en.arb`):
     - `settingsAppearanceVisualStyle`: `Visual style`
     - `settingsAppearanceVisualStyleDescription`: `Choose the surface treatment for CodeWalk chrome and chat without changing your selected color palette.`
     - `settingsAppearanceVisualStyleClassic`: `Classic`
     - `settingsAppearanceVisualStyleRefined`: `Refined`

     Portuguese (`app_pt.arb`):
     - `settingsAppearanceVisualStyle`: `Estilo visual`
     - `settingsAppearanceVisualStyleDescription`: `Escolha o tratamento das superfícies do chrome e do chat do CodeWalk sem mudar a paleta de cores selecionada.`
     - `settingsAppearanceVisualStyleClassic`: `Clássico`
     - `settingsAppearanceVisualStyleRefined`: `Refinado`

     Spanish (`app_es.arb`):
     - `settingsAppearanceVisualStyle`: `Estilo visual`
     - `settingsAppearanceVisualStyleDescription`: `Elige el tratamiento de las superficies del chrome y el chat de CodeWalk sin cambiar la paleta de colores seleccionada.`
     - `settingsAppearanceVisualStyleClassic`: `Clásico`
     - `settingsAppearanceVisualStyleRefined`: `Refinado`

     German (`app_de.arb`):
     - `settingsAppearanceVisualStyle`: `Visueller Stil`
     - `settingsAppearanceVisualStyleDescription`: `Wähle die Oberflächenbehandlung für CodeWalk-Chrome und Chat, ohne die ausgewählte Farbpalette zu ändern.`
     - `settingsAppearanceVisualStyleClassic`: `Klassisch`
     - `settingsAppearanceVisualStyleRefined`: `Verfeinert`

     French (`app_fr.arb`):
     - `settingsAppearanceVisualStyle`: `Style visuel`
     - `settingsAppearanceVisualStyleDescription`: `Choisissez le traitement des surfaces du chrome et du chat CodeWalk sans modifier la palette de couleurs sélectionnée.`
     - `settingsAppearanceVisualStyleClassic`: `Classique`
     - `settingsAppearanceVisualStyleRefined`: `Raffiné`

     Italian (`app_it.arb`):
     - `settingsAppearanceVisualStyle`: `Stile visivo`
     - `settingsAppearanceVisualStyleDescription`: `Scegli il trattamento delle superfici del chrome e della chat di CodeWalk senza modificare la palette di colori selezionata.`
     - `settingsAppearanceVisualStyleClassic`: `Classico`
     - `settingsAppearanceVisualStyleRefined`: `Raffinato`

     Russian (`app_ru.arb`):
     - `settingsAppearanceVisualStyle`: `Визуальный стиль`
     - `settingsAppearanceVisualStyleDescription`: `Выберите оформление поверхностей интерфейса и чата CodeWalk, не меняя выбранную цветовую палитру.`
     - `settingsAppearanceVisualStyleClassic`: `Классический`
     - `settingsAppearanceVisualStyleRefined`: `Сдержанный`

     Chinese Simplified (`app_zh.arb`):
     - `settingsAppearanceVisualStyle`: `视觉风格`
     - `settingsAppearanceVisualStyleDescription`: `选择 CodeWalk 界面和聊天表面的呈现方式，而不更改已选配色。`
     - `settingsAppearanceVisualStyleClassic`: `经典`
     - `settingsAppearanceVisualStyleRefined`: `精致`

     Japanese (`app_ja.arb`):
     - `settingsAppearanceVisualStyle`: `ビジュアルスタイル`
     - `settingsAppearanceVisualStyleDescription`: `選択中のカラーパレットを変えずに、CodeWalk のクロームとチャットの表面表現を選びます。`
     - `settingsAppearanceVisualStyleClassic`: `クラシック`
     - `settingsAppearanceVisualStyleRefined`: `洗練`

     Korean (`app_ko.arb`):
     - `settingsAppearanceVisualStyle`: `시각 스타일`
     - `settingsAppearanceVisualStyleDescription`: `선택한 색상 팔레트를 바꾸지 않고 CodeWalk 크롬과 채팅 표면의 표현 방식을 선택합니다.`
     - `settingsAppearanceVisualStyleClassic`: `클래식`
     - `settingsAppearanceVisualStyleRefined`: `정제됨`

     Hindi (`app_hi.arb`):
     - `settingsAppearanceVisualStyle`: `दृश्य शैली`
     - `settingsAppearanceVisualStyleDescription`: `चुनी गई रंग-पैलेट बदले बिना CodeWalk chrome और chat सतहों का रूप चुनें।`
     - `settingsAppearanceVisualStyleClassic`: `क्लासिक`
     - `settingsAppearanceVisualStyleRefined`: `परिष्कृत`

     Bengali (`app_bn.arb`):
     - `settingsAppearanceVisualStyle`: `ভিজ্যুয়াল শৈলী`
     - `settingsAppearanceVisualStyleDescription`: `নির্বাচিত রঙের প্যালেট না বদলে CodeWalk chrome ও chat পৃষ্ঠের উপস্থাপনা বেছে নিন।`
     - `settingsAppearanceVisualStyleClassic`: `ক্লাসিক`
     - `settingsAppearanceVisualStyleRefined`: `পরিশীলিত`

     Arabic (`app_ar.arb`):
     - `settingsAppearanceVisualStyle`: `النمط المرئي`
     - `settingsAppearanceVisualStyleDescription`: `اختر معالجة أسطح واجهة CodeWalk والدردشة من دون تغيير لوحة الألوان المحددة.`
     - `settingsAppearanceVisualStyleClassic`: `كلاسيكي`
     - `settingsAppearanceVisualStyleRefined`: `مصقول`

     Urdu (`app_ur.arb`):
     - `settingsAppearanceVisualStyle`: `بصری انداز`
     - `settingsAppearanceVisualStyleDescription`: `منتخب رنگ پیلیٹ بدلے بغیر CodeWalk chrome اور chat سطحوں کا انداز منتخب کریں۔`
     - `settingsAppearanceVisualStyleClassic`: `کلاسک`
     - `settingsAppearanceVisualStyleRefined`: `نکھرا ہوا`

  8. For every new ARB key, add a metadata entry of the same style as existing keys, for example:

     ```json
     "@settingsAppearanceVisualStyle": {
       "description": "CodeWalk UI string — settingsAppearanceVisualStyle"
     }
     ```

  9. Run `export PATH="$HOME/flutter/bin:$PATH" && flutter gen-l10n` after ARB edits. Do not run `dart tool/i18n/generate_arb.dart`.
  10. Update `test/widget/settings_page_test.dart` to verify the `settings_visual_style_segmented` control appears and selecting `VisualStyle.refined` calls/persists through `SettingsProvider`.

- **Risk**: Medium because localization/generated files are involved. Mitigate by using `flutter gen-l10n`, not destructive project scripts.
- **Validation**:
  - `export PATH="$HOME/flutter/bin:$PATH" && flutter gen-l10n`
  - `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/settings_page_test.dart`

### 6. Apply refined tokens to chat composer

- **Files**:
  - `lib/presentation/widgets/chat_input_widget.dart`
  - `test/widget/chat_page_test.dart` or the existing composer-focused widget test file if one exists

- **Details**:
  1. Import `AppVisualStyleTokens` if not already available through `ThemeData.visualStyleTokens`.
  2. In `build()`, after resolving `colorScheme` and `isDark`, add:

     ```dart
     final visualTokens = Theme.of(context).visualStyleTokens;
     final refined = visualTokens.visualStyle == VisualStyle.refined;
     ```

  3. Preserve shell-mode colors; shell mode may still use tertiary coloring. Only refine the normal composer bubble treatment.
  4. Replace the normal bubble preferred color calculation so that:
      - classic uses the current `surfaceContainerHighest` alpha `0.94` dark / `0.96` light path;
      - refined uses `visualTokens.composerSurface` as the normal preferred color.
  5. Replace `final inputBubbleBorderRadius = AppShapes.borderExtraLarge;` with:

     ```dart
     final inputBubbleBorderRadius = refined
         ? visualTokens.dialogRadius
         : AppShapes.borderExtraLarge;
     ```

     Use `visualTokens.dialogRadius` here because the composer bubble is a large surface, not a small chip.

  6. Replace the hardcoded composer `boxShadow` with:

     ```dart
     boxShadow: refined ? visualTokens.composerShadow : const <BoxShadow>[...current shadow cannot be const because withValues is runtime...]
     ```

     Implement this cleanly by deriving a `composerShadow` local list before the `BoxDecoration`:

     ```dart
     final composerShadow = refined
         ? visualTokens.composerShadow
         : <BoxShadow>[
             BoxShadow(
               color: Colors.black.withValues(alpha: 0.07),
               blurRadius: 12,
               offset: const Offset(0, 2),
             ),
           ];
     ```

  7. In refined mode, add a subtle border around the composer bubble:

     ```dart
     border: refined
         ? Border.all(
             color: visualTokens.separator,
             width: visualTokens.enabledBorderWidth,
           )
         : null,
     ```

  8. Refine the send button only when `refined` is active:
      - keep the `CircleBorder` and size unchanged;
      - set `elevation: refined ? 0 : (canSend ? 1.5 : 0)`;
      - set `shadowColor: refined ? Colors.transparent : colorScheme.primary.withValues(alpha: 0.3)`;
      - when disabled, use `visualTokens.mutedControlSurface` instead of `colorScheme.surfaceContainerHighest`;
      - keep the same semantics labels and actions.
  9. Do not change attachment, microphone, shell command, send/stop behavior, text input behavior, or keyboard shortcuts.

- **Risk**: Medium. The composer is core UX. Mitigate by changing only visual decoration, not send logic.
- **Validation**:
  - Existing chat/composer widget tests must pass.
  - Manually inspect compact width and desktop width after implementation.

### 7. Apply refined tokens to message bubbles

- **Files**:
  - `lib/presentation/widgets/chat_message/chat_message_content.dart`
  - `lib/presentation/widgets/chat_message_widget.dart` if imports or helper access are needed
  - `test/widget/chat_message_widget_test.dart`

- **Details**:
  1. In `_buildContent`, add:

     ```dart
     final visualTokens = Theme.of(context).visualStyleTokens;
     final refined = visualTokens.visualStyle == VisualStyle.refined;
     ```

  2. Replace `bubbleBorderRadius` construction with token-aware logic:

     ```dart
     final bubbleBorderRadius = (refined
             ? visualTokens.bubbleRadius
             : AppShapes.borderLarge)
         .copyWith(
           bottomRight: isUser
               ? (refined ? visualTokens.bubbleTightCornerRadius : const Radius.circular(6))
               : null,
           bottomLeft: !isUser
               ? (refined ? visualTokens.bubbleTightCornerRadius : const Radius.circular(6))
               : null,
         );
     ```

  3. Replace bubble colors with token-aware logic:
      - classic user: keep `colorScheme.primaryContainer.withValues(alpha: 0.45)`.
      - classic assistant: keep `colorScheme.surfaceContainerHigh`.
      - refined user: `Color.alphaBlend(colorScheme.primary.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.20 : 0.12), colorScheme.surface)`.
      - refined assistant: `visualTokens.cardSurface`.
  4. In refined mode, add a subtle border to assistant bubbles only:

     ```dart
     border: refined && !isUser
         ? Border.all(
             color: visualTokens.separator,
             width: visualTokens.enabledBorderWidth,
           )
         : null,
     ```

     Do not add a border to user bubbles unless tests or visual review show insufficient separation; the selected user tint is enough.

  5. Keep all message layout constants unchanged: max widths, width factor, padding, copy semantics, long-press behavior, double-tap copy, and header/time display.

- **Risk**: Medium. Message bubble visual changes are highly visible. Behavior remains unchanged.
- **Validation**:
  - `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/chat_message_widget_test.dart`

### 8. Apply refined tokens to chat chrome, status, and sidebar/session surfaces

- **Files**:
  - `lib/presentation/pages/chat_page/chat_page_chrome.dart`
  - `lib/presentation/pages/chat_page/chat_page_scaffold.dart`
  - `lib/presentation/pages/chat_page/chat_page_status_presenter.dart`
  - `lib/presentation/widgets/chat_session_list.dart`
  - `test/widget/chat_page_test.dart`

- **Details**:
  1. Use `Theme.of(context).visualStyleTokens` in these files where local color/radius decisions are made.
  2. Preserve existing layout, navigation, drawer/sidebar behavior, menus, gestures, and selectors.
  3. Replace only visual treatment in refined mode:
      - For sidebar/project/recent/session container backgrounds, prefer `visualTokens.panelSurface` or transparent surfaces with `visualTokens.separator` instead of `surfaceContainerHighest` blocks.
      - For selected/current rows, use `visualTokens.selectedSurface` plus the existing thin selection indicator. Do not reintroduce row-wide heavy filled backgrounds.
      - For dividers, pane dividers, and resize handles, use `visualTokens.separator` and `visualTokens.dividerThickness`.
      - For status chips and compact controls, use `visualTokens.mutedControlSurface`, `visualTokens.controlRadius`, and `visualTokens.separator`.
      - Keep the active server status colors and labels (`Online`, `Delayed`, `Offline`) unchanged; only refine their container treatment.
      - Keep hover/focus/pressed affordances visible. Do not remove focus or hover states.
  4. Do not alter `WindowSizeClass` logic, desktop pane visibility, drawer behavior, project switching, session switching, recent sessions behavior, or status semantics.
  5. Keep RTL-safe padding/directionality. Avoid replacing directional-aware Flutter widgets with manually left/right-biased layout unless existing code already does so.

- **Risk**: Medium-high because these files contain dense responsive UI. Mitigate by limiting changes to colors/radii/borders and running chat widget tests.
- **Validation**:
  - `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/chat_page_test.dart`
  - Manual smoke checks at compact and expanded widths.

### 9. Centralize semantic warning/error/info colors without broad migration

- **Files**:
  - `lib/presentation/theme/app_semantic_colors.dart`
  - Existing tests if any cover semantic colors; otherwise extend `test/unit/presentation/app_theme_test.dart` or add a small semantic color test if project structure supports it.

- **Details**:
  1. Keep existing success methods unchanged.
  2. Add methods:

     ```dart
     static Color warning(BuildContext context)
     static Color warningContainer(BuildContext context)
     static Color info(BuildContext context)
     static Color infoContainer(BuildContext context)
     static Color errorMuted(BuildContext context)
     ```

  3. Implement brightness-specific helpers using `Theme.of(context).colorScheme` for error and stable Flutter `Colors.amber` / `Colors.blue` variants for warning/info. Use alpha values that preserve contrast:
      - warning dark foreground: `Colors.amber.shade300`; warning light foreground: `Colors.amber.shade800`.
      - warning dark container: `Colors.amber.shade900.withValues(alpha: 0.24)`; warning light container: `Colors.amber.shade100`.
      - info dark foreground: `Colors.blue.shade300`; info light foreground: `Colors.blue.shade700`.
      - info dark container: `Colors.blue.shade900.withValues(alpha: 0.24)`; info light container: `Colors.blue.shade50`.
      - error muted: `Theme.of(context).colorScheme.error.withValues(alpha: brightness == Brightness.dark ? 0.32 : 0.20)`.
  4. Do not migrate every existing inline status color in this first pass. Use the new helpers only when touching hotspots in this plan. Leave broad cleanup for a follow-up.

- **Risk**: Low. This is additive if used narrowly.
- **Validation**:
  - Analyzer over `lib/presentation/theme/app_semantic_colors.dart` and touched widgets.

### 10. Update documentation

- **Files**:
  - `BEHAVIOR.md`
  - `ADR.md`
  - `CODEBASE.md`

- **Details**:
  1. In `BEHAVIOR.md`, add an implemented behavior section under the visual/settings area, using this wording as the authoritative behavior:

     ```markdown
     ### Visual style selection

     - **Given** the user opens `Settings > Appearance`
     - **When** the user changes `Visual style`
     - **Then** `Classic` preserves the existing CodeWalk Material You-inspired surface treatment
     - **Then** `Refined` applies quieter CodeWalk-specific surface treatment to app chrome, chat composer, message bubbles, status controls, and conversation/sidebar rows without changing the selected color palette
     - **Then** OpenCode theme presets, dynamic color, AMOLED dark mode, density, font scaling, contrast, focus states, keyboard navigation, and RTL layout remain supported
     - **Then** the selected visual style applies immediately and persists across app restarts
     ```

  2. In `ADR.md`, add an index entry and a new ADR after ADR-044:
      - Title: `ADR-045: CodeWalk Refined Visual Layer Over Material Stack`
      - Status: `Accepted`
      - Context: issue #86 wants less default Material Design, no iOS imitation, mobile/desktop/web, accessibility preservation.
      - Decision: keep Material stack, add `VisualStyle`, add `AppVisualStyleTokens`, implement `Classic` and `Refined`, default to `Classic`, no third-party design-system package, no icon replacement.
      - Rationale: lower risk, preserves dynamic color/OpenCode presets/density/accessibility, avoids big-bang rewrite.
      - Consequences: reversible rollout; still visually constrained by Material widgets and Material Symbols; future component library adoption remains separate.
      - Key files: `experience_settings.dart`, `settings_provider.dart`, `app_theme.dart`, `app_visual_style_tokens.dart`, `appearance_settings_section.dart`, `chat_input_widget.dart`, `chat_message_content.dart`, chat chrome/scaffold/status/session files.
  3. In `CODEBASE.md`, update the theme/core modules section to include:
      - `lib/presentation/theme/app_visual_style_tokens.dart` — CodeWalk Classic/Refined visual style ThemeExtension for surface/radius/shadow/separator tokens.
      - Mention `ExperienceSettings.visualStyle` and Settings > Appearance visual style selection in relevant settings/theme descriptions.

- **Risk**: Low. Docs must reflect actual implementation only; write after code behavior exists.
- **Validation**:
  - Manual doc review.

### 11. Run focused validation and final project gate

- **Files**: all touched source, tests, docs.

- **Details**:
  1. Run generated localization after ARB edits:

     ```bash
     export PATH="$HOME/flutter/bin:$PATH" && flutter gen-l10n
     ```

  2. Run focused analyzer:

     ```bash
     export PATH="$HOME/flutter/bin:$PATH" && flutter analyze \
       lib/main.dart \
       lib/domain/entities/experience_settings.dart \
       lib/presentation/providers/settings_provider.dart \
       lib/presentation/theme/app_theme.dart \
       lib/presentation/theme/app_visual_style_tokens.dart \
       lib/presentation/theme/app_semantic_colors.dart \
       lib/presentation/pages/settings/sections/appearance_settings_section.dart \
       lib/presentation/widgets/chat_input_widget.dart \
       lib/presentation/widgets/chat_message/chat_message_content.dart \
       lib/presentation/pages/chat_page/chat_page_chrome.dart \
       lib/presentation/pages/chat_page/chat_page_scaffold.dart \
       lib/presentation/pages/chat_page/chat_page_status_presenter.dart \
       lib/presentation/widgets/chat_session_list.dart
     ```

  3. Run focused tests:

     ```bash
     export PATH="$HOME/flutter/bin:$PATH" && flutter test \
       test/unit/presentation/app_theme_test.dart \
       test/unit/domain/experience_settings_test.dart \
       test/unit/providers/settings_provider_test.dart \
       test/widget/settings_page_test.dart \
       test/widget/chat_message_widget_test.dart \
       test/widget/chat_page_test.dart
     ```

  4. Run the final gate:

     ```bash
     make check
     ```

  5. If `make check` fails for an unrelated pre-existing reason, capture the failing command, file, and error, but do not declare the work complete until the failure is either fixed or explicitly judged unrelated and accepted by the user.

- **Risk**: Medium. Theme and localization changes can affect many generated files and tests.
- **Validation**: All listed commands pass, or any failure is investigated and resolved/explicitly reported.

## Risks & Mitigations

1. **Critical: Classic visual behavior regresses.**
   - Mitigation: default `VisualStyle.classic`; write tests confirming classic tokens and current theme behavior are preserved; branch every refined-only change by `visualTokens.visualStyle == VisualStyle.refined`.

2. **High: OpenCode presets lose their identity.**
   - Mitigation: keep `OpenCodeThemeTokens` unchanged and additive; refined must adjust surface treatment without replacing preset color schemes or syntax tokens.

3. **High: Dynamic color or AMOLED mode conflicts with refined tokens.**
   - Mitigation: build refined tokens from the resolved `ColorScheme` after dynamic color/preset selection and after AMOLED dark scheme application. Do not disable dynamic color.

4. **High: Accessibility/focus/keyboard visibility weakens due to quieter surfaces.**
   - Mitigation: keep focused borders at least `1.5` px in refined mode, keep primary focus color, keep touch target sizes unchanged, run keyboard/focus smoke tests in Settings and Chat.

5. **Medium: RTL/localization layout breaks.**
   - Mitigation: do not replace Directionality-aware widgets; keep `EdgeInsetsDirectional` where existing code uses it; run at least one RTL smoke check with Arabic or Urdu after implementation.

6. **Medium: Web/Linux performance suffers from polish effects.**
   - Mitigation: do not use blur/vibrancy/backdrop filters in this implementation; use static color blends and subtle borders only.

7. **Medium: ThemeExtension interpolation causes runtime errors.**
   - Mitigation: implement `copyWith` and `lerp` fully; add unit tests for classic/refined token presence.

8. **Medium: ARB/generated localization drift.**
   - Mitigation: add all keys to all ARB files; run `flutter gen-l10n`; never run the destructive global ARB generation script.

9. **Low: New setting adds UI complexity.**
   - Mitigation: keep it in the existing Appearance theme card, use two choices only, and keep `Classic` as the default.

## Assumptions to Validate

1. **Assumption**: `ThemeData.extensions` can hold both `OpenCodeThemeTokens` and `AppVisualStyleTokens` simultaneously.
   - Validation: unit test `AppTheme.lightFrom(... themeExtensions: [classicThemeTokensFrom(...)])` and assert both extensions are present.
   - Fallback if false: pass `AppVisualStyleTokens` by a separate helper inherited widget near `MaterialApp`; do not remove `OpenCodeThemeTokens`.

2. **Assumption**: `flutter gen-l10n` is the correct safe generated-localization command.
   - Validation: run it after ARB edits and inspect generated file changes.
   - Fallback if false: use the project's existing non-destructive localization generation path; do not run `tool/i18n/generate_arb.dart` globally.

3. **Assumption**: Refined can use platform-aware `Typography.material2021(platform: defaultTargetPlatform)` without causing unacceptable platform drift.
   - Validation: run widget tests and visually smoke desktop/mobile; confirm no snapshots or tests depend on exact Android typography metrics.
   - Fallback if false: keep classic typography for refined in this first implementation and document typography refinement as a follow-up.

4. **Assumption**: The selected ARB translations are acceptable.
   - Validation: run gen-l10n and verify strings display in Settings.
   - Fallback if false: keep English fallback values in non-English ARBs only with explicit user approval; otherwise correct translations before completion.

5. **Assumption**: Existing tests can be updated without broad golden/snapshot churn.
   - Validation: run focused tests.
   - Fallback if false: adjust tests to assert behavior/token presence rather than brittle exact widget tree details.

## Decisions and Nuances

- Do not change `AppShapes` global constants. Refined radii belong in `AppVisualStyleTokens` so `classic` is preserved.
- Do not introduce a third visual family. `VisualStyle` is orthogonal to the existing theme-family segmented control (`CodeWalk Classic` vs `OpenCode Presets`). Users can choose either color-family path and separately choose Classic/Refined surface treatment.
- Do not disable the contrast slider or dynamic color for refined. Existing disabling rules remain: contrast is disabled for dynamic color and presets because contrast applies only to seed-generated schemes.
- Do not remove Material ripples globally. If a component's ripple looks too strong in refined mode, adjust local overlay colors only after verifying focus/pressed states remain visible.
- Do not add custom fonts or font packages in this first pass. Typography refinement is limited to platform-aware `Typography.material2021` for refined mode.
- Do not use OpenChamber as a binding visual source. It is a secondary reference only; the implemented identity is CodeWalk-specific.
- Do not implement user JSON themes in this task. If future JSON theme work exists, it must later map into the same `AppVisualStyleTokens` shape instead of creating a parallel visual system.
- Do not close issue #86 automatically unless the implementation includes the research summary, selected decision, implementation, docs, and passing validation expected by the issue.

## Blockers and Open Questions

None.

## Testing Strategy

Execute these checks in order:

1. Localization generation:

   ```bash
   export PATH="$HOME/flutter/bin:$PATH" && flutter gen-l10n
   ```

2. Settings model tests:

   ```bash
   export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/domain/experience_settings_test.dart
   ```

3. Settings provider tests:

   ```bash
   export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/providers/settings_provider_test.dart
   ```

4. Theme tests:

   ```bash
   export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/presentation/app_theme_test.dart
   ```

5. Appearance/settings widget tests:

   ```bash
   export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/settings_page_test.dart
   ```

6. Message bubble tests:

   ```bash
   export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/chat_message_widget_test.dart
   ```

7. Chat surface tests:

   ```bash
   export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/chat_page_test.dart
   ```

8. Focused analyzer:

   ```bash
   export PATH="$HOME/flutter/bin:$PATH" && flutter analyze \
     lib/main.dart \
     lib/domain/entities/experience_settings.dart \
     lib/presentation/providers/settings_provider.dart \
     lib/presentation/theme/app_theme.dart \
     lib/presentation/theme/app_visual_style_tokens.dart \
     lib/presentation/theme/app_semantic_colors.dart \
     lib/presentation/pages/settings/sections/appearance_settings_section.dart \
     lib/presentation/widgets/chat_input_widget.dart \
     lib/presentation/widgets/chat_message/chat_message_content.dart \
     lib/presentation/pages/chat_page/chat_page_chrome.dart \
     lib/presentation/pages/chat_page/chat_page_scaffold.dart \
     lib/presentation/pages/chat_page/chat_page_status_presenter.dart \
     lib/presentation/widgets/chat_session_list.dart
   ```

9. Final validation gate:

   ```bash
   make check
   ```

Manual smoke checks after automated validation:

- Settings > Appearance shows `Visual style` with `Classic` and `Refined` in light and dark modes.
- Toggling `Refined` applies immediately and persists after restart/reload.
- Refined works with CodeWalk classic palette, at least one OpenCode preset such as `flexoki` or `github`, Android dynamic color when available, and AMOLED dark mode.
- Chat composer, send/stop button, microphone button, message bubbles, status controls, and sidebar rows remain readable and focusable.
- Keyboard navigation still works in Settings and Chat.
- Compact/mobile width and expanded/desktop width remain usable.
- Arabic or Urdu locale does not break the new visual style control or sidebar/chat layout.

## Execution Handoff

Start here:

1. Inspect current working tree:

   ```bash
   git status --short
   ```

2. Read these files first:
   - `BEHAVIOR.md`
   - `ADR.md`
   - `CODEBASE.md`
   - `lib/domain/entities/experience_settings.dart`
   - `lib/presentation/providers/settings_provider.dart`
   - `lib/presentation/theme/app_theme.dart`
   - `lib/main.dart`
   - `lib/presentation/pages/settings/sections/appearance_settings_section.dart`
   - `lib/presentation/widgets/chat_input_widget.dart`
   - `lib/presentation/widgets/chat_message/chat_message_content.dart`

3. If using the project’s git multi-step workflow, create an immutable `plan:` commit with `AGENT_PLAN_ANCHOR` before implementation, using this `final_plan.md` as the plan source. Then implement as separate step commits.

4. Implement in this exact order:
   1. `VisualStyle` persistence in `ExperienceSettings`.
   2. `SettingsProvider` getter/setter.
   3. `AppVisualStyleTokens` and `AppTheme` wiring.
   4. `main.dart` wiring.
   5. Settings UI + ARB + `flutter gen-l10n`.
   6. Composer visual refinements.
   7. Message bubble refinements.
   8. Chat chrome/sidebar/status refinements.
   9. Semantic color additions.
   10. Tests.
   11. Docs.
   12. `make check`.

5. Keep implementation narrow: if a desired visual refinement requires replacing major components, adding a package, or changing behavior, stop and record it as a follow-up instead of expanding this task.

## Out of Scope

- Adding `forui`, `mix`, `shadcn_flutter`, `shadcn_ui`, `fluent_ui`, `macos_ui`, or any other visual/design-system package.
- Replacing `MaterialApp` or removing `ThemeData(useMaterial3: true)`.
- Replacing Material Symbols or changing the icon system.
- Removing `cupertino_icons`.
- Implementing JSON/user-authored custom themes.
- Changing OpenCode server contracts, OpenCode API payloads, ADR-023 compatibility behavior, chat send/realtime behavior, or backend-related logic.
- Redesigning every screen in the app.
- Adding blur/vibrancy/backdrop-filter effects.
- Reworking all inline colors/radii across the whole repository.
- Changing the app logo, launcher icons, tray icons, or brand assets.
- Creating Android APK builds unless separately requested.
