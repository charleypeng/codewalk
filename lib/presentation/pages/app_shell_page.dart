import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/logging/app_logger.dart';
import '../providers/app_provider.dart';
import '../providers/settings_provider.dart';
import '../services/desktop_tray_service.dart';
import '../services/desktop_tray_service_types.dart';
import '../services/update_check_service.dart';
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
  // Ensures the startup update toast is shown at most once per session.
  bool _shownStartupUpdateToast = false;
  // Guards for install-state SnackBars so they are shown at most once each.
  bool _shownProgressSnackBar = false;
  bool _shownDoneSnackBar = false;
  bool _shownFailedSnackBar = false;
  UpdateInstallState _lastObservedInstallState = UpdateInstallState.idle;

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
        // Schedule startup update toast once the main shell is rendered.
        // Only fires for startup-origin checks (pendingStartupUpdateToast),
        // not for manual "Check for updates" presses.
        // Flag is set here (not in the callback) to prevent multiple
        // addPostFrameCallback registrations across rebuilds.
        final updateResult = settingsProvider.updateCheckResult;
        if (!_shownStartupUpdateToast &&
            settingsProvider.pendingStartupUpdateToast &&
            updateResult != null &&
            updateResult.isNewer) {
          _shownStartupUpdateToast = true;
          settingsProvider.acknowledgeStartupUpdateToast();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showUpdateToast(context, settingsProvider, updateResult);
          });
        }

        // React to install state transitions with SnackBars.
        final installState = settingsProvider.installState;
        if (installState != _lastObservedInstallState) {
          _lastObservedInstallState = installState;
          if (installState == UpdateInstallState.idle) {
            // startInstall() briefly resets to idle before starting; clear guards
            // so subsequent state transitions trigger fresh SnackBars.
            _shownProgressSnackBar = false;
            _shownDoneSnackBar = false;
            _shownFailedSnackBar = false;
          } else if (installState == UpdateInstallState.downloading &&
              !_shownProgressSnackBar) {
            _shownProgressSnackBar = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showDownloadingSnackBar(context, settingsProvider);
            });
          } else if (installState == UpdateInstallState.done &&
              !_shownDoneSnackBar) {
            _shownDoneSnackBar = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showDoneSnackBar(context);
            });
          } else if (installState == UpdateInstallState.failed &&
              !_shownFailedSnackBar) {
            _shownFailedSnackBar = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showFailedSnackBar(context, settingsProvider);
            });
          }
        }

        return const ChatPage();
      },
    );
  }

  /// Shows a one-time SnackBar when a startup update check finds a newer version.
  /// The action triggers the in-app install flow instead of opening a browser.
  void _showUpdateToast(
    BuildContext context,
    SettingsProvider settingsProvider,
    UpdateCheckResult result,
  ) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Update available: v${result.latestVersion}'),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Install',
          onPressed: () => unawaited(settingsProvider.startInstall()),
        ),
      ),
    );
  }

  /// Shows a persistent SnackBar while the APK is being downloaded.
  void _showDownloadingSnackBar(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(days: 1), // dismissed programmatically
        content: ListenableBuilder(
          listenable: settingsProvider,
          builder: (_, __) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Downloading update…'),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: settingsProvider.installProgress > 0
                    ? settingsProvider.installProgress
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a SnackBar confirming the desktop update was applied.
  void _showDoneSnackBar(BuildContext context) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Update installed. Restart the app to apply.'),
        duration: Duration(seconds: 8),
      ),
    );
  }

  /// Shows a SnackBar when the install failed, with a retry action.
  void _showFailedSnackBar(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Install failed'),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () {
            // Guards are cleared by the idle→downloading state transition in the builder.
            unawaited(settingsProvider.startInstall());
          },
        ),
      ),
    );
  }
}
