import 'package:flutter/material.dart';

import '../../domain/entities/experience_settings.dart';

class OpenCodeThemePalette {
  const OpenCodeThemePalette({required this.label, required this.seedColor});

  final String label;
  final Color seedColor;
}

OpenCodeThemePalette? openCodeThemePaletteFor(OpenCodeThemePreset? preset) {
  if (preset == null) {
    return null;
  }
  return switch (preset) {
    OpenCodeThemePreset.system => const OpenCodeThemePalette(
      label: 'System',
      seedColor: Color(0xFF7C8896),
    ),
    OpenCodeThemePreset.tokyonight => const OpenCodeThemePalette(
      label: 'Tokyo Night',
      seedColor: Color(0xFF7AA2F7),
    ),
    OpenCodeThemePreset.everforest => const OpenCodeThemePalette(
      label: 'Everforest',
      seedColor: Color(0xFF83C092),
    ),
    OpenCodeThemePreset.ayu => const OpenCodeThemePalette(
      label: 'Ayu',
      seedColor: Color(0xFFFFB454),
    ),
    OpenCodeThemePreset.catppuccin => const OpenCodeThemePalette(
      label: 'Catppuccin',
      seedColor: Color(0xFF89B4FA),
    ),
    OpenCodeThemePreset.catppuccinMacchiato => const OpenCodeThemePalette(
      label: 'Catppuccin Macchiato',
      seedColor: Color(0xFF8AADF4),
    ),
    OpenCodeThemePreset.gruvbox => const OpenCodeThemePalette(
      label: 'Gruvbox',
      seedColor: Color(0xFFD79921),
    ),
    OpenCodeThemePreset.kanagawa => const OpenCodeThemePalette(
      label: 'Kanagawa',
      seedColor: Color(0xFF7E9CD8),
    ),
    OpenCodeThemePreset.nord => const OpenCodeThemePalette(
      label: 'Nord',
      seedColor: Color(0xFF81A1C1),
    ),
    OpenCodeThemePreset.matrix => const OpenCodeThemePalette(
      label: 'Matrix',
      seedColor: Color(0xFF00C853),
    ),
    OpenCodeThemePreset.oneDark => const OpenCodeThemePalette(
      label: 'One Dark',
      seedColor: Color(0xFF61AFEF),
    ),
  };
}

String openCodeThemePresetLabel(OpenCodeThemePreset preset) {
  return openCodeThemePaletteFor(preset)!.label;
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
