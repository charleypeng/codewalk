import 'package:flutter/material.dart';

import '../../domain/entities/experience_settings.dart';

class OpenCodeThemePalette {
  const OpenCodeThemePalette({required this.label, required this.seedColor});

  final String label;
  final Color seedColor;
}

const Map<OpenCodeThemePreset, OpenCodeThemePalette> _openCodeThemePalettes =
    <OpenCodeThemePreset, OpenCodeThemePalette>{
      OpenCodeThemePreset.system: OpenCodeThemePalette(
        label: 'System',
        seedColor: Color(0xFF7C8896),
      ),
      OpenCodeThemePreset.tokyonight: OpenCodeThemePalette(
        label: 'Tokyo Night',
        seedColor: Color(0xFF7AA2F7),
      ),
      OpenCodeThemePreset.everforest: OpenCodeThemePalette(
        label: 'Everforest',
        seedColor: Color(0xFF83C092),
      ),
      OpenCodeThemePreset.ayu: OpenCodeThemePalette(
        label: 'Ayu',
        seedColor: Color(0xFFFFB454),
      ),
      OpenCodeThemePreset.catppuccin: OpenCodeThemePalette(
        label: 'Catppuccin',
        seedColor: Color(0xFF89B4FA),
      ),
      OpenCodeThemePreset.catppuccinMacchiato: OpenCodeThemePalette(
        label: 'Catppuccin Macchiato',
        seedColor: Color(0xFF8AADF4),
      ),
      OpenCodeThemePreset.gruvbox: OpenCodeThemePalette(
        label: 'Gruvbox',
        seedColor: Color(0xFFD79921),
      ),
      OpenCodeThemePreset.kanagawa: OpenCodeThemePalette(
        label: 'Kanagawa',
        seedColor: Color(0xFF7E9CD8),
      ),
      OpenCodeThemePreset.nord: OpenCodeThemePalette(
        label: 'Nord',
        seedColor: Color(0xFF81A1C1),
      ),
      OpenCodeThemePreset.matrix: OpenCodeThemePalette(
        label: 'Matrix',
        seedColor: Color(0xFF00C853),
      ),
      OpenCodeThemePreset.oneDark: OpenCodeThemePalette(
        label: 'One Dark',
        seedColor: Color(0xFF61AFEF),
      ),
    };

OpenCodeThemePalette? openCodeThemePaletteFor(OpenCodeThemePreset? preset) {
  if (preset == null) {
    return null;
  }
  return _openCodeThemePalettes[preset];
}

String openCodeThemePresetLabel(OpenCodeThemePreset preset) {
  return _openCodeThemePalettes[preset]!.label;
}

ColorScheme? openCodeLightSchemeFor(OpenCodeThemePreset? preset) {
  final palette = openCodeThemePaletteFor(preset);
  if (palette == null) {
    return null;
  }
  return ColorScheme.fromSeed(
    seedColor: palette.seedColor,
    brightness: Brightness.light,
  );
}

ColorScheme? openCodeDarkSchemeFor(OpenCodeThemePreset? preset) {
  final palette = openCodeThemePaletteFor(preset);
  if (palette == null) {
    return null;
  }
  return ColorScheme.fromSeed(
    seedColor: palette.seedColor,
    brightness: Brightness.dark,
  );
}
