import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/logging/app_logger.dart';
import '../providers/app_provider.dart';
import '../providers/settings_provider.dart';
import '../services/desktop_tray_service.dart';
import '../services/desktop_tray_service_types.dart';
import 'chat_page.dart';
import 'onboarding_wizard_page.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  final DesktopTrayService _desktopTrayService = createDesktopTrayService();
  SettingsProvider? _settingsProvider;
  // Tracks whether the wizard was dismissed this session (without persisting
  // the preference). Resets on app restart, unlike skipOnboardingWizard.
  bool _wizardDismissedThisSession = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextSettingsProvider = context.read<SettingsProvider>();
    if (identical(_settingsProvider, nextSettingsProvider)) {
      return;
    }
    _settingsProvider?.removeListener(_handleSettingsChanged);
    _settingsProvider = nextSettingsProvider;
    _settingsProvider?.addListener(_handleSettingsChanged);
    unawaited(_configureDesktopTray());
  }

  @override
  void dispose() {
    _settingsProvider?.removeListener(_handleSettingsChanged);
    unawaited(_desktopTrayService.dispose());
    super.dispose();
  }

  void _handleSettingsChanged() {
    unawaited(_configureDesktopTray());
  }

  Future<void> _configureDesktopTray() async {
    final settingsProvider = _settingsProvider;
    if (settingsProvider == null) {
      return;
    }
    try {
      await _desktopTrayService.initialize(
        closeBehavior: settingsProvider.desktopCloseBehavior,
      );
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Desktop tray configuration failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, SettingsProvider>(
      builder: (context, appProvider, settingsProvider, _) {
        // Wait until both providers have loaded persisted state.
        if (!appProvider.initialized || !settingsProvider.initialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Show onboarding wizard when no server is configured, unless user
        // opted out permanently or dismissed it this session.
        final needsOnboarding =
            appProvider.serverProfiles.isEmpty &&
            !settingsProvider.skipOnboardingWizard &&
            !_wizardDismissedThisSession;
        if (needsOnboarding) {
          return OnboardingWizardPage(
            onComplete: () {
              setState(() {
                _wizardDismissedThisSession = true;
              });
            },
          );
        }
        return const ChatPage();
      },
    );
  }
}
