import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/i18n/l10n_context.dart';
import '../../domain/entities/server_profile.dart';
import '../providers/app_provider.dart';
import '../providers/settings_provider.dart';
import '../services/local_opencode_server_runtime_types.dart';
import '../theme/app_animations.dart';
import '../utils/app_page_route.dart';
import '../widgets/modal_primary_action_shortcuts.dart';
import 'opencode_setup_debug_page.dart';
import 'settings/sections/servers_settings_section.dart';

enum SetupWizardInitialFlow {
  choose,
  connectServer,
  guidedServerSetup,
  managedLocalServer,
}

/// First-run onboarding wizard that guides users through initial server setup.
/// Shown when no server profiles exist and skipOnboardingWizard is false.
class OnboardingWizardPage extends StatefulWidget {
  const OnboardingWizardPage({
    super.key,
    this.onComplete,
    this.showSkipAction = true,
    this.initialFlow = SetupWizardInitialFlow.choose,
    this.initialServerProfile,
  });

  /// Called when the wizard completes (server configured or skipped).
  /// When null, the gate in AppShellPage handles navigation automatically.
  final VoidCallback? onComplete;

  /// Whether the AppBar should expose the onboarding skip action.
  final bool showSkipAction;

  /// Entry flow for this wizard when launched from settings shortcuts.
  final SetupWizardInitialFlow initialFlow;

  /// Optional server profile to edit in-place instead of creating a new one.
  final ServerProfile? initialServerProfile;

  @override
  State<OnboardingWizardPage> createState() => _OnboardingWizardPageState();
}

class _OnboardingWizardPageState extends State<OnboardingWizardPage> {
  int _step = 0;
  bool _showQuickGuide = false;
  bool _connectionSuccess = false;
  String? _connectionError;
  bool _testing = false;
  // ID of the server profile added during this wizard session, so "Try again"
  // re-tests health instead of attempting a duplicate addServerProfile.
  String? _addedServerId;
  String? _editingServerId;

  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _basicAuthEnabled = false;
  bool _oauthEnabled = false;
  bool _aiGeneratedTitlesEnabled = true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _urlController.text = _suggestedServerUrl;
    _configureInitialFlow();
  }

  String get _suggestedServerUrl {
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return isAndroid ? 'http://10.0.2.2:4096' : 'http://127.0.0.1:4096';
  }

  bool get _oauthSupported => AppProvider.supportsCloudflareAccessOAuth;

  void _configureInitialFlow() {
    final initialProfile = widget.initialServerProfile;
    if (initialProfile != null) {
      _editingServerId = initialProfile.id;
      _urlController.text = initialProfile.url;
      _labelController.text = initialProfile.label ?? '';
      _usernameController.text = initialProfile.basicAuthUsername;
      _passwordController.text = initialProfile.basicAuthPassword;
      _basicAuthEnabled = initialProfile.basicAuthEnabled;
      _oauthEnabled = initialProfile.oauthEnabled;
      _aiGeneratedTitlesEnabled = initialProfile.aiGeneratedTitlesEnabled;
      _step = 1;
      return;
    }

    switch (widget.initialFlow) {
      case SetupWizardInitialFlow.choose:
        _step = 0;
        break;
      case SetupWizardInitialFlow.connectServer:
        _step = 1;
        _showQuickGuide = false;
        break;
      case SetupWizardInitialFlow.guidedServerSetup:
        _step = 1;
        _showQuickGuide = true;
        break;
      case SetupWizardInitialFlow.managedLocalServer:
        _step = 3;
        _scheduleLocalDiagnostics();
        break;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _labelController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (_step == 0) {
      if (widget.showSkipAction) {
        _handleSkip();
        return;
      }
      unawaited(_complete());
      return;
    }
    setState(() {
      if (_step == 2) {
        _connectionSuccess = false;
        _connectionError = null;
      }
      if (_step == 3) {
        _step = 0;
        return;
      }
      _step--;
    });
  }

  Future<void> _handleSkip() async {
    if (!widget.showSkipAction) {
      unawaited(_complete());
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        var dontShowAgain = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void submitSkip() {
              if (dontShowAgain) {
                unawaited(
                  context.read<SettingsProvider>().setSkipOnboardingWizard(
                    true,
                  ),
                );
              }
              Navigator.of(dialogContext).pop(true);
            }

            return ModalPrimaryActionShortcuts(
              autofocus: true,
              onPrimaryAction: submitSkip,
              child: AlertDialog(
                title: const Text('Skip setup?'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'You can add a server later in Settings > Servers.',
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: dontShowAgain,
                      onChanged: (value) {
                        setDialogState(() {
                          dontShowAgain = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text("Don't show again"),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(context.l10n.commonCancel),
                  ),
                  FilledButton(
                    onPressed: submitSkip,
                    child: Text(context.l10n.tourSkip),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed == true) {
      unawaited(_complete());
    }
  }

  Future<void> _complete() async {
    if (_connectionSuccess &&
        widget.showSkipAction &&
        _editingServerId == null) {
      await context.read<SettingsProvider>().setPendingPostOnboardingChatTour(
        true,
      );
      if (!mounted) {
        return;
      }
    }
    if (widget.onComplete != null) {
      widget.onComplete!();
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
    // When launched from AppShellPage gate, navigation happens automatically
    // via the Consumer2 rebuild when server profiles change.
  }

  void _goToConnectServer() {
    context.read<AppProvider>().recordSetupDebugEvent(
      source: 'Onboarding',
      message: 'User chose to connect to an existing OpenCode server.',
    );
    setState(() {
      _showQuickGuide = false;
      _step = 1;
    });
  }

  void _goToNeedHelp() {
    context.read<AppProvider>().recordSetupDebugEvent(
      source: 'Onboarding',
      message: 'User opened the guided OpenCode setup path.',
    );
    setState(() {
      _showQuickGuide = true;
      _step = 1;
    });
  }

  void _goToLocalManagedSetup() {
    context.read<AppProvider>().recordSetupDebugEvent(
      source: 'Onboarding',
      message: 'User opened managed local OpenCode setup.',
    );
    setState(() {
      _step = 3;
      _connectionError = null;
    });
    _scheduleLocalDiagnostics();
  }

  void _scheduleLocalDiagnostics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_runLocalDiagnostics());
    });
  }

  Future<void> _runLocalDiagnostics() async {
    final appProvider = context.read<AppProvider>();
    await appProvider.runLocalServerDiagnostics();
  }

  Future<void> _openSetupDebugPage() async {
    await Navigator.of(
      context,
    ).push(AppPageRoute(builder: (_) => const OpenCodeSetupDebugPage()));
  }

  Future<void> _testConnection() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _testing = true;
      _connectionError = null;
    });

    final appProvider = context.read<AppProvider>();
    final adjustedUrl = _mapAndroidLoopback(_urlController.text.trim());
    final label = _labelController.text.trim();
    appProvider.recordSetupDebugEvent(
      source: 'Manual connection',
      message: 'Testing OpenCode server URL $adjustedUrl from onboarding.',
    );
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final oauthEnabled = _oauthEnabled && _oauthSupported;

    final trackedServerId = _editingServerId ?? _addedServerId;
    final hasTrackedServer =
        trackedServerId != null &&
        appProvider.serverProfiles.any(
          (profile) => profile.id == trackedServerId,
        );

    // If this wizard already created a server profile, update/re-check the same
    // profile instead of attempting to add a duplicate URL.
    if (hasTrackedServer) {
      final updated = await appProvider.updateServerProfile(
        id: trackedServerId,
        url: adjustedUrl,
        label: label,
        basicAuthEnabled: _basicAuthEnabled,
        basicAuthUsername: username,
        basicAuthPassword: password,
        oauthEnabled: oauthEnabled,
        aiGeneratedTitlesEnabled: _aiGeneratedTitlesEnabled,
      );
      if (!mounted) return;
      if (!updated) {
        appProvider.recordSetupDebugEvent(
          source: 'Manual connection',
          message: appProvider.errorMessage,
          severity: SetupDebugSeverity.error,
        );
        setState(() {
          _testing = false;
          _connectionError = appProvider.errorMessage;
        });
        return;
      }

      final health = appProvider.healthFor(trackedServerId);
      final healthMessage = health == ServerHealthStatus.unhealthy
          ? 'Server health check failed. It may still be starting up.'
          : 'Server connection updated successfully.';
      appProvider.recordSetupDebugEvent(
        source: 'Manual connection',
        message: healthMessage,
        severity: health == ServerHealthStatus.unhealthy
            ? SetupDebugSeverity.error
            : SetupDebugSeverity.info,
      );
      setState(() {
        _testing = false;
        _connectionSuccess = health != ServerHealthStatus.unhealthy;
        _connectionError = health == ServerHealthStatus.unhealthy
            ? 'Server health check failed. It may still be starting up.'
            : null;
        _step = 2;
      });
      return;
    }

    final existingServerIds = appProvider.serverProfiles
        .map((profile) => profile.id)
        .toSet();
    final success = await appProvider.addServerProfile(
      url: adjustedUrl,
      label: label,
      basicAuthEnabled: _basicAuthEnabled,
      basicAuthUsername: username,
      basicAuthPassword: password,
      oauthEnabled: oauthEnabled,
      aiGeneratedTitlesEnabled: _aiGeneratedTitlesEnabled,
      setAsActive: true,
    );

    if (!mounted) return;

    if (success) {
      String? serverId;
      for (final profile in appProvider.serverProfiles.reversed) {
        if (!existingServerIds.contains(profile.id)) {
          serverId = profile.id;
          break;
        }
      }
      serverId ??= appProvider.activeServerId;
      serverId ??= appProvider.serverProfiles.isNotEmpty
          ? appProvider.serverProfiles.last.id
          : null;

      if (_editingServerId == null && serverId != null) {
        _addedServerId = serverId;
      }
      final health = serverId == null
          ? ServerHealthStatus.unhealthy
          : appProvider.healthFor(serverId);
      final healthMessage = health == ServerHealthStatus.unhealthy
          ? 'Server added but health check failed. It may still be starting up.'
          : 'Server connection saved successfully.';
      appProvider.recordSetupDebugEvent(
        source: 'Manual connection',
        message: healthMessage,
        severity: health == ServerHealthStatus.unhealthy
            ? SetupDebugSeverity.error
            : SetupDebugSeverity.info,
      );
      setState(() {
        _testing = false;
        _connectionSuccess = health != ServerHealthStatus.unhealthy;
        _connectionError = health == ServerHealthStatus.unhealthy
            ? 'Server added but health check failed. It may still be starting up.'
            : null;
        _step = 2;
      });
    } else {
      appProvider.recordSetupDebugEvent(
        source: 'Manual connection',
        message: appProvider.errorMessage,
        severity: SetupDebugSeverity.error,
      );
      setState(() {
        _testing = false;
        _connectionError = appProvider.errorMessage;
      });
    }
  }

  String _mapAndroidLoopback(String input) {
    var normalized = input.trim();
    try {
      normalized = AppProvider.normalizeServerUrl(normalized);
    } catch (_) {
      return input.trim();
    }

    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (!isAndroid) return normalized;

    final uri = Uri.tryParse(normalized);
    if (uri == null) return normalized;
    final isLoopback =
        uri.host == '127.0.0.1' || uri.host.toLowerCase() == 'localhost';
    if (!isLoopback) return normalized;

    return Uri(scheme: uri.scheme, host: '10.0.2.2', port: uri.port).toString();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.msgCommandCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final canNavigateBack = _step > 0 || !widget.showSkipAction;
    final maxWidth = _step == 3 ? 760.0 : 560.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titleForCurrentStep()),
          automaticallyImplyLeading: false,
          leading: canNavigateBack
              ? IconButton(
                  icon: const Icon(Symbols.arrow_back),
                  onPressed: _handleBack,
                )
              : null,
          actions: [
            if (widget.showSkipAction && (_step < 2 || !_connectionSuccess))
              TextButton(
                onPressed: _handleSkip,
                child: Text(context.l10n.tourSkip),
              ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: AnimatedSwitcher(
                duration: AppAnimations.emphasized,
                switchInCurve: AppAnimations.emphasizedCurve,
                switchOutCurve: AppAnimations.accelerateCurve,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildStep(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _titleForCurrentStep() {
    return switch (_step) {
      0 => widget.showSkipAction ? 'Setup' : 'Setup wizard',
      1 => _editingServerId == null ? 'Server setup' : 'Edit server',
      2 => _connectionSuccess ? 'Ready' : 'Connection issue',
      3 => 'Local server setup',
      _ => 'Setup',
    };
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _buildWelcomeStep(),
      1 => _buildServerSetupStep(),
      2 => _buildReadyStep(),
      3 => _buildLocalSetupStep(),
      _ => _buildWelcomeStep(),
    };
  }

  // -- Step 0: Welcome --

  Widget _buildWelcomeStep() {
    final colorScheme = Theme.of(context).colorScheme;
    final supportsLocalManaged = context.select<AppProvider, bool>(
      (provider) => provider.localServerSupported,
    );

    final title = widget.showSkipAction
        ? 'Welcome to ${AppConstants.appName}'
        : 'Choose how to set up your server';
    final subtitle = widget.showSkipAction
        ? 'CodeWalk needs an OpenCode server before it can help with your code.'
        : 'Pick the setup path that matches your current OpenCode setup.';

    return SingleChildScrollView(
      key: const ValueKey('step_welcome'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Symbols.code_rounded, size: 72, color: colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Card(
            child: ExpansionTile(
              key: const ValueKey('what_is_opencode_tile'),
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              leading: Icon(Symbols.info_rounded, color: colorScheme.primary),
              title: const Text('What is OpenCode?'),
              subtitle: const Text(
                'CodeWalk is the app. OpenCode is the engine it connects to.',
              ),
              children: [
                Text(
                  'OpenCode runs locally or on a server and powers the AI coding features inside CodeWalk. If OpenCode is already running, connect to it. If not, pick one of the guided setup paths below.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Card(
              color: colorScheme.primaryContainer,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                onTap: _goToConnectServer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Symbols.dns_rounded,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connect to a running server',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'I already have OpenCode running on this device or somewhere on my network.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Symbols.arrow_forward_rounded,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              color: colorScheme.surface,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                onTap: _goToNeedHelp,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Symbols.help_outline_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Show me the setup steps',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: colorScheme.onSurface),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Explain how to install OpenCode, start the server, and then connect from CodeWalk.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Symbols.arrow_forward_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              color: supportsLocalManaged
                  ? colorScheme.surfaceContainerHigh
                  : colorScheme.surface,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                onTap: supportsLocalManaged ? _goToLocalManagedSetup : null,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Symbols.computer,
                        color: supportsLocalManaged
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Let CodeWalk set it up locally',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: colorScheme.onSurface),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              supportsLocalManaged
                                  ? 'Desktop only: CodeWalk can diagnose, install, and run OpenCode for you.'
                                  : 'Available only on desktop (Linux/macOS/Windows).',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            if (supportsLocalManaged) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Good first option on desktop',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Symbols.arrow_forward_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Step 1: Server setup --

  Widget _buildServerSetupStep() {
    final hasTrackedServer = _editingServerId != null || _addedServerId != null;

    return SingleChildScrollView(
      key: const ValueKey('step_server_setup'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _step = 0;
                  _connectionError = null;
                });
              },
              icon: const Icon(Symbols.chevron_left_rounded),
              label: const Text('Choose another path'),
            ),
          ),
          const SizedBox(height: 4),
          if (_showQuickGuide) ...[
            Text(
              'You are almost there. Install OpenCode first, then connect CodeWalk to the server URL.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ServerSetupQuickGuide(onCopy: _copyToClipboard),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () {
                    setState(() {
                      _showQuickGuide = false;
                    });
                  },
                  child: const Text('Continue to server URL'),
                ),
                TextButton.icon(
                  key: const ValueKey(
                    'open_code_setup_debug_button_quick_guide',
                  ),
                  onPressed: _openSetupDebugPage,
                  icon: const Icon(Symbols.bug_report_rounded),
                  label: const Text('View setup debug'),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          if (!_showQuickGuide) ...[
            Text(
              _editingServerId == null
                  ? 'Server connection'
                  : 'Edit server connection',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Card(
              child: ExpansionTile(
                key: const ValueKey('server_connection_tips_tile'),
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                leading: const Icon(Symbols.info_rounded),
                title: const Text('Connection tips'),
                subtitle: const Text(
                  'Default URL, emulator loopback, auth, and debug help.',
                ),
                children: [
                  _buildSetupHintRow(
                    icon: Symbols.link,
                    text:
                        'Suggested local OpenCode server URL: $_suggestedServerUrl',
                  ),
                  const SizedBox(height: 8),
                  _buildSetupHintRow(
                    icon: Symbols.phone_android,
                    text:
                        'On Android emulator, localhost and 127.0.0.1 are remapped to 10.0.2.2 automatically.',
                  ),
                  const SizedBox(height: 8),
                  _buildSetupHintRow(
                    icon: Symbols.lock,
                    text:
                        'Enable Basic Auth only if your OpenCode server is password-protected.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  key: const ValueKey(
                    'open_code_setup_debug_button_server_form',
                  ),
                  onPressed: _openSetupDebugPage,
                  icon: const Icon(Symbols.bug_report_rounded),
                  label: const Text('View setup debug'),
                ),
                TextButton.icon(
                  key: const ValueKey('show_setup_steps_button_server_form'),
                  onPressed: () {
                    setState(() {
                      _showQuickGuide = true;
                    });
                  },
                  icon: const Icon(Symbols.menu_book_rounded),
                  label: const Text('Show setup steps'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  TextFormField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: context.l10n.onboardingServerUrl,
                      hintText: _suggestedServerUrl,
                      suffixIcon: _urlController.text.trim().isEmpty
                          ? null
                          : IconButton(
                              tooltip: context.l10n.onboardingClear,
                              icon: const Icon(Symbols.clear),
                              onPressed: () {
                                _urlController.clear();
                                setState(() {});
                              },
                            ),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      final raw = value?.trim() ?? '';
                      if (raw.isEmpty) return 'Enter a server URL';
                      try {
                        AppProvider.normalizeServerUrl(raw);
                        return null;
                      } catch (_) {
                        return 'Invalid URL';
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _labelController,
                    decoration: InputDecoration(
                      labelText: context.l10n.onboardingLabel,
                      hintText: context.l10n.onboardingLabelHint,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _basicAuthEnabled,
                    onChanged: (value) {
                      setState(() {
                        _basicAuthEnabled = value;
                        if (value) _oauthEnabled = false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Use Basic Auth'),
                  ),
                  SwitchListTile(
                    value: _oauthEnabled,
                    onChanged: _oauthSupported
                        ? (value) {
                            setState(() {
                              _oauthEnabled = value;
                              if (value) _basicAuthEnabled = false;
                            });
                          }
                        : null,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Use OAuth (Cloudflare Access)'),
                    subtitle: Text(
                      _oauthSupported
                          ? 'Desktop only. Opens a browser for Cloudflare Access Managed OAuth.'
                          : 'Cloudflare Access OAuth is desktop-only. Use Basic Auth on mobile or web.',
                    ),
                  ),
                  if (_basicAuthEnabled) ...[
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: context.l10n.onboardingUsername,
                      ),
                      validator: (value) {
                        if (!_basicAuthEnabled) return null;
                        if ((value ?? '').trim().isEmpty) {
                          return 'Enter username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: context.l10n.onboardingPassword,
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (!_basicAuthEnabled) return null;
                        if ((value ?? '').trim().isEmpty) {
                          return 'Enter password';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _aiGeneratedTitlesEnabled,
                    onChanged: (value) {
                      setState(() {
                        _aiGeneratedTitlesEnabled = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    title: const Text('AI generated titles'),
                    subtitle: const Text(
                      "Uses your server's title agent to name conversations",
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_connectionError != null) ...[
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Symbols.error_outline,
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _connectionError!,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton.icon(
                    onPressed: _testing ? null : _testConnection,
                    icon: _testing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Symbols.link_rounded),
                    label: Text(
                      _testing
                          ? 'Testing...'
                          : hasTrackedServer
                          ? 'Save and test'
                          : 'Test connection',
                    ),
                  ),
                ],
              ),
            ),
          ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocalSetupStep() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final report = appProvider.localEnvironmentReport;
        final supported = appProvider.localServerSupported;
        final setupBusy = appProvider.localSetupInProgress;
        final status = appProvider.localServerStatus;
        final isBusy =
            status == LocalServerRuntimeStatus.starting ||
            status == LocalServerRuntimeStatus.stopping;
        final isRunning = status == LocalServerRuntimeStatus.running;

        final (statusColor, statusLabel) = switch (status) {
          LocalServerRuntimeStatus.running => (Colors.green, 'Running'),
          LocalServerRuntimeStatus.starting => (Colors.orange, 'Starting'),
          LocalServerRuntimeStatus.stopping => (Colors.orange, 'Stopping'),
          LocalServerRuntimeStatus.failed => (Colors.red, 'Failed'),
          LocalServerRuntimeStatus.stopped => (Colors.grey, 'Stopped'),
        };

        return SingleChildScrollView(
          key: const ValueKey('step_local_setup'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _step = 0;
                    });
                  },
                  icon: const Icon(Symbols.chevron_left_rounded),
                  label: const Text('Choose another path'),
                ),
              ),
              Text(
                'Managed local server',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Install and run OpenCode directly from CodeWalk on desktop.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(statusLabel),
                      const Spacer(),
                      Text(
                        appProvider.localServerUrl,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                appProvider.localServerStatusMessage,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (appProvider.localServerLastOutput.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Latest output: ${appProvider.localServerLastOutput}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              if (!supported)
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Managed local server mode is available only on desktop builds (Linux/macOS/Windows).',
                    ),
                  ),
                )
              else ...[
                if (report == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  _buildDiagnosticRow('Platform', report.platform),
                  _buildToolStatusRow('OpenCode', report.opencode),
                  _buildToolStatusRow('Node.js', report.node),
                  _buildToolStatusRow('npm', report.npm),
                  _buildToolStatusRow('Bun', report.bun),
                  _buildToolStatusRow('WSL', report.wsl),
                  _buildDiagnosticRow(
                    'Network',
                    report.hasNetworkAccess ? 'reachable' : 'unreachable',
                  ),
                  _buildDiagnosticRow(
                    'Install directory',
                    report.installDirectoryWritable
                        ? 'writable'
                        : 'not writable',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.recommendation,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (!kIsWeb &&
                      defaultTargetPlatform == TargetPlatform.windows) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Windows tip: after installing, click Refresh Checks. If detection still fails, reopen CodeWalk to reload PATH changes.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 12),
                Text(
                  'Recommended order: try Install Bun + OpenCode if you want CodeWalk to bootstrap everything for you. Use Existing if OpenCode is already installed.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: setupBusy
                          ? null
                          : () => _runLocalDiagnostics(),
                      icon: const Icon(Symbols.refresh_rounded),
                      label: const Text('Refresh Checks'),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          setupBusy || !(report?.opencode.available ?? false)
                          ? null
                          : () async {
                              final ok = await appProvider
                                  .useDetectedLocalServerCommand();
                              if (!ok) {
                                _showMessage(appProvider.errorMessage);
                                return;
                              }
                              _showMessage('Using detected OpenCode command.');
                            },
                      icon: const Icon(Symbols.check_circle_outline),
                      label: const Text('Use Existing'),
                    ),
                    FilledButton.icon(
                      onPressed: setupBusy
                          ? null
                          : () async {
                              final ok = await appProvider
                                  .installLocalServerRequirements(
                                    LocalOpencodeInstallMethod
                                        .bunBootstrapThenInstall,
                                  );
                              if (!ok) {
                                _showMessage(appProvider.errorMessage);
                              }
                            },
                      icon: const Icon(Symbols.rocket_launch),
                      label: const Text('Install Bun + OpenCode'),
                    ),
                    OutlinedButton.icon(
                      onPressed: setupBusy
                          ? null
                          : () async {
                              final ok = await appProvider
                                  .installLocalServerRequirements(
                                    LocalOpencodeInstallMethod.bunGlobal,
                                  );
                              if (!ok) {
                                _showMessage(appProvider.errorMessage);
                              }
                            },
                      icon: const Icon(Symbols.bolt),
                      label: const Text('Install via Bun'),
                    ),
                    OutlinedButton.icon(
                      onPressed: setupBusy
                          ? null
                          : () async {
                              final ok = await appProvider
                                  .installLocalServerRequirements(
                                    LocalOpencodeInstallMethod.npmGlobal,
                                  );
                              if (!ok) {
                                _showMessage(appProvider.errorMessage);
                              }
                            },
                      icon: const Icon(Symbols.inventory_2),
                      label: const Text('Install via npm'),
                    ),
                    OutlinedButton.icon(
                      onPressed: setupBusy
                          ? null
                          : () async {
                              final ok = await appProvider
                                  .installLocalServerRequirements(
                                    LocalOpencodeInstallMethod.downloadBinary,
                                  );
                              if (!ok) {
                                _showMessage(appProvider.errorMessage);
                              }
                            },
                      icon: const Icon(Symbols.download_for_offline),
                      label: const Text('Install Binary'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: (isBusy || isRunning)
                          ? null
                          : () async {
                              final ok = await appProvider.startLocalServer();
                              if (!ok) {
                                _showMessage(appProvider.errorMessage);
                              }
                            },
                      icon: const Icon(Symbols.play_arrow_rounded),
                      label: const Text('Start'),
                    ),
                    OutlinedButton.icon(
                      onPressed: (isBusy || !isRunning)
                          ? null
                          : () async {
                              final ok = await appProvider.stopLocalServer();
                              if (!ok) {
                                _showMessage(appProvider.errorMessage);
                              }
                            },
                      icon: const Icon(Symbols.stop_rounded),
                      label: const Text('Stop'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const ValueKey('open_code_setup_debug_button_local'),
                    onPressed: _openSetupDebugPage,
                    icon: const Icon(Symbols.bug_report_rounded),
                    label: const Text('View setup debug'),
                  ),
                ),
              ],
              if (appProvider.localSetupInProgress) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(minHeight: 3),
              ],
              if (appProvider.localSetupMessage.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  appProvider.localSetupMessage,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (appProvider.localSetupLogs.isNotEmpty ||
                  appProvider.setupDebugEntries.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detailed setup events were captured for troubleshooting.',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${appProvider.localSetupLogs.length} setup log lines and ${appProvider.setupDebugEntries.length} setup events are available in the separate setup debug screen.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => unawaited(_complete()),
                icon: const Icon(Symbols.check_circle_rounded),
                label: Text(widget.showSkipAction ? 'Continue' : 'Done'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiagnosticRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildToolStatusRow(String label, LocalToolStatus status) {
    final icon = status.available
        ? const Icon(Symbols.check_circle, color: Colors.green, size: 16)
        : const Icon(Symbols.cancel, color: Colors.red, size: 16);

    final details = <String>[];
    if (status.version.trim().isNotEmpty) {
      details.add(status.version.trim());
    }
    if (status.path.trim().isNotEmpty) {
      details.add(status.path.trim());
    }
    if (status.note.trim().isNotEmpty) {
      details.add(status.note.trim());
    }

    final value = details.isEmpty
        ? (status.available ? 'available' : 'not available')
        : details.join('  |  ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Row(
              children: [
                icon,
                const SizedBox(width: 6),
                Expanded(child: Text(label)),
              ],
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // -- Step 2: Ready --

  Widget _buildReadyStep() {
    final colorScheme = Theme.of(context).colorScheme;
    final successTitle = _editingServerId == null
        ? "You're all set!"
        : 'Server updated';
    final successDescription = _editingServerId == null
        ? 'Your server is connected and ready to use.'
        : 'Your server settings were saved and health checks were refreshed.';
    final actionLabel = widget.showSkipAction
        ? 'Start using ${AppConstants.appName}'
        : 'Done';

    if (_connectionSuccess) {
      return Column(
        key: const ValueKey('step_ready_success'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Symbols.check_circle_rounded, size: 72, color: Colors.green),
          const SizedBox(height: 24),
          Text(
            successTitle,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            successDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          FilledButton.icon(
            onPressed: () => unawaited(_complete()),
            icon: const Icon(Symbols.arrow_forward_rounded),
            label: Text(actionLabel),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _step = 0;
                _connectionSuccess = false;
                _connectionError = null;
              });
            },
            icon: const Icon(Symbols.swap_horiz_rounded),
            label: const Text('Choose another path'),
          ),
        ],
      );
    }

    // Connection failed but server was added
    return Column(
      key: const ValueKey('step_ready_failed'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Symbols.warning_amber_rounded, size: 72, color: colorScheme.error),
        const SizedBox(height: 24),
        Text(
          'Connection issue',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _connectionError ?? 'Could not verify the server connection.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        FilledButton.icon(
          onPressed: () {
            setState(() {
              _step = 1;
              _connectionSuccess = false;
              _connectionError = null;
            });
          },
          icon: const Icon(Symbols.refresh_rounded),
          label: Text(context.l10n.terminalTryAgain),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _step = 0;
              _connectionSuccess = false;
              _connectionError = null;
            });
          },
          icon: const Icon(Symbols.swap_horiz_rounded),
          label: const Text('Choose another path'),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          key: const ValueKey('open_code_setup_debug_button_failed'),
          onPressed: _openSetupDebugPage,
          icon: const Icon(Symbols.bug_report_rounded),
          label: const Text('View setup debug'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => unawaited(_complete()),
          child: const Text('Skip for now'),
        ),
      ],
    );
  }

  Widget _buildSetupHintRow({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }

  void _showMessage(String message) {
    if (!mounted || message.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
