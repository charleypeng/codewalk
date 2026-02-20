import 'package:flutter/material.dart';

import '../../domain/entities/experience_settings.dart';
import 'app_shapes.dart';

class AppTheme {
  AppTheme._();

  static const Color seedColor = Color(0xFF3A6EA5);

  static ThemeData lightFrom(
    ColorScheme colorScheme, {
    AppDensity appDensity = AppDensity.normal,
  }) {
    return _buildTheme(
      colorScheme: colorScheme,
      brightness: Brightness.light,
      appDensity: appDensity,
    );
  }

  static ThemeData darkFrom(
    ColorScheme colorScheme, {
    AppDensity appDensity = AppDensity.normal,
  }) {
    return _buildTheme(
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      appDensity: appDensity,
    );
  }

  static VisualDensity visualDensityFor(AppDensity density) {
    return switch (density) {
      AppDensity.extraDense => const VisualDensity(
        horizontal: -2,
        vertical: -2,
      ),
      AppDensity.dense => VisualDensity.compact,
      AppDensity.normal => VisualDensity.standard,
      AppDensity.spacious => VisualDensity.comfortable,
      AppDensity.extraSpacious => const VisualDensity(
        horizontal: 2,
        vertical: 2,
      ),
    };
  }

  static bool usesCompactLayout(AppDensity density) {
    return density == AppDensity.extraDense || density == AppDensity.dense;
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Brightness brightness,
    required AppDensity appDensity,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      visualDensity: visualDensityFor(appDensity),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );

    final textTheme = Typography.material2021(
      platform: TargetPlatform.android,
      colorScheme: colorScheme,
    ).black;

    return base.copyWith(
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: colorScheme.surfaceTint,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShapes.extraLarge),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: OutlineInputBorder(
          borderRadius: AppShapes.borderLarge,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppShapes.borderLarge,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppShapes.borderLarge,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppShapes.borderLarge),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedIconTheme: IconThemeData(
          color: colorScheme.onSecondaryContainer,
        ),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
        indicatorColor: colorScheme.secondaryContainer,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: AppShapes.borderSmall),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppShapes.borderLarge),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppShapes.borderLarge),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppShapes.borderLarge),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShapes.medium),
          ),
        ),
      ),
    );
  }
}
