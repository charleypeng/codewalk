import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'core/constants/app_constants.dart';
import 'domain/entities/experience_settings.dart';
import 'core/di/injection_container.dart' as di;
import 'core/logging/app_logger.dart';
import 'presentation/pages/app_shell_page.dart';
import 'presentation/providers/app_provider.dart';
import 'presentation/providers/chat_provider.dart';
import 'presentation/providers/project_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/services/android_background_alert_worker.dart';
import 'presentation/theme/app_theme.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      AppLogger.installGlobalHandlers();

      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      );

      if (_isDesktopRuntime()) {
        await windowManager.ensureInitialized();
      }

      if (_isAndroidRuntime()) {
        await AndroidBackgroundAlertWorker.ensureRegistered();
      }

      // Initialize dependency injection
      await di.init();

      runApp(const MyApp());
    },
    (error, stackTrace) {
      AppLogger.recordZoneError(error, stackTrace);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = di.sl<AppProvider>();
            unawaited(provider.initialize());
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => di.sl<ProjectProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<ChatProvider>()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = di.sl<SettingsProvider>();
            unawaited(provider.initialize());
            return provider;
          },
        ),
      ],
      child: DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          return Consumer<SettingsProvider>(
            builder: (context, settingsProvider, _) {
              final appDensity = settingsProvider.appDensity;
              final useDynamic = settingsProvider.useDynamicColor;
              final useAmoledDark = settingsProvider.useAmoledDark;
              final customSeed = settingsProvider.customColorSeed;
              final contrastLevel = settingsProvider.contrastLevel;

              // Sync actual dynamic color availability to provider so
              // the settings UI can reflect reality (not just platform
              // heuristic).
              // Consider dynamic color available when the platform provides
              // at least one scheme (light or dark).
              final hasDynamic = lightDynamic != null || darkDynamic != null;
              if (settingsProvider.dynamicColorAvailable != hasDynamic) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  settingsProvider.updateDynamicColorAvailability(
                    available: hasDynamic,
                  );
                });
              }

              // Resolve seed color: custom pick or default brand
              final seedColor = customSeed != null
                  ? Color(customSeed)
                  : AppTheme.seedColor;

              // Use dynamic platform colors when available and enabled
              final lightScheme = useDynamic && lightDynamic != null
                  ? lightDynamic
                  : ColorScheme.fromSeed(
                      seedColor: seedColor,
                      brightness: Brightness.light,
                      contrastLevel: contrastLevel,
                    );
              final darkScheme = useDynamic && darkDynamic != null
                  ? darkDynamic
                  : ColorScheme.fromSeed(
                      seedColor: seedColor,
                      brightness: Brightness.dark,
                      contrastLevel: contrastLevel,
                    );
              final resolvedDarkScheme = useAmoledDark
                  ? _applyAmoledDarkScheme(darkScheme)
                  : darkScheme;

              // Map user theme mode preference to Flutter ThemeMode
              final themeMode = switch (settingsProvider.themeMode) {
                ThemeModeOption.light => ThemeMode.light,
                ThemeModeOption.dark => ThemeMode.dark,
                ThemeModeOption.system => ThemeMode.system,
              };
              return MaterialApp(
                title: AppConstants.appName,
                theme: AppTheme.lightFrom(lightScheme, appDensity: appDensity),
                darkTheme: AppTheme.darkFrom(
                  resolvedDarkScheme,
                  appDensity: appDensity,
                ),
                themeMode: themeMode,
                home: const AppShellPage(),
                debugShowCheckedModeBanner: false,
              );
            },
          );
        },
      ),
    );
  }
}

bool _isDesktopRuntime() {
  if (kIsWeb) {
    return false;
  }
  return switch (defaultTargetPlatform) {
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => true,
    _ => false,
  };
}

bool _isAndroidRuntime() {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.android;
}

ColorScheme _applyAmoledDarkScheme(ColorScheme base) {
  const black = Colors.black;
  return base.copyWith(
    surface: black,
    surfaceDim: black,
    surfaceBright: black,
    surfaceContainerLowest: black,
    surfaceContainerLow: black,
    surfaceContainer: black,
    surfaceContainerHigh: black,
    surfaceContainerHighest: black,
  );
}
