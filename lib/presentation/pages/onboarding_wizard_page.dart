import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/server_profile.dart';
import '../providers/app_provider.dart';
import '../providers/settings_provider.dart';
import '../services/local_opencode_server_runtime_types.dart';
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
  static const String _suggestedServerUrl = 'http://127.0.0.1:4096';

  int _step = 0;
  bool _showQuickGuide = false;
  bool _connectionSuccess = false;
  String? _connectionError;
  bool _testing = false;
  // ID of the server profile added during this wizard session, so "Try again"
  // re-tests health instead of attempting a duplicate addServerProfile.
  String? _addedServerId;
  String? _editingServerId;

  final TextEditingController _urlController = TextEditingController(
    text: _suggestedServerUrl,
  );
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _basicAuthEnabled = false;
  bool _aiGeneratedTitlesEnabled = true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _configureInitialFlow();
  }

  void _configureInitialFlow() {
    final initialProfile = widget.initialServerProfile;
    if (initialProfile != null) {
      _editingServerId = initialProfile.id;
      _urlController.text = initialProfile.url;
      _labelController.text = initialProfile.label ?? '';
      _usernameController.text = initialProfile.basicAuthUsername;
      _passwordController.text = initialProfile.basicAuthPassword;
      _basicAuthEnabled = initialProfile.basicAuthEnabled;
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
      _complete();
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
      _complete();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        var dontShowAgain = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
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
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (dontShowAgain) {
                      context.read<SettingsProvider>().setSkipOnboardingWizard(
                        true,
                      );
                    }
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Skip'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      _complete();
    }
  }

  void _complete() {
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
    setState(() {
      _showQuickGuide = false;
      _step = 1;
    });
  }

  void _goToNeedHelp() {
    setState(() {
      _showQuickGuide = true;
      _step = 1;
    });
  }

  void _goToLocalManagedSetup() {
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

  Future<void> _testConnection() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _testing = true;
      _connectionError = null;
    });

    final appProvider = context.read<AppProvider>();
    final adjustedUrl = _mapAndroidLoopback(_urlController.text.trim());
    final label = _labelController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

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
        aiGeneratedTitlesEnabled: _aiGeneratedTitlesEnabled,
      );
      if (!mounted) return;
      if (!updated) {
        setState(() {
          _testing = false;
          _connectionError = appProvider.errorMessage;
        });
        return;
      }

      final health = appProvider.healthFor(trackedServerId);
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
      setState(() {
        _testing = false;
        _connectionSuccess = health != ServerHealthStatus.unhealthy;
        _connectionError = health == ServerHealthStatus.unhealthy
            ? 'Server added but health check failed. It may still be starting up.'
            : null;
        _step = 2;
      });
    } else {
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
    ).showSnackBar(const SnackBar(content: Text('Command copied')));
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
              TextButton(onPressed: _handleSkip, child: const Text('Skip')),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: AnimatedSwitcher(
                duration: AppConstants.shortAnimation,
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
        ? 'Connect to an OpenCode server to get started'
        : 'Pick the best path for your current setup';

    return Column(
      key: const ValueKey('step_welcome'),
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
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        // Recommended card: connect to server
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
                            'Connect to server',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'I already have a server running',
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

        // Alternative card: need help
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
                            'I need help setting up',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: colorScheme.onSurface),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Show me how to install and start a server',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
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
                            'Use managed local server',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: colorScheme.onSurface),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            supportsLocalManaged
                                ? 'Install, diagnose and run OpenCode locally'
                                : 'Available only on desktop (Linux/macOS/Windows)',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
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
      ],
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
            ServerSetupQuickGuide(onCopy: _copyToClipboard),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () {
                setState(() {
                  _showQuickGuide = false;
                });
              },
              child: const Text('Continue to server URL'),
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
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'Server URL',
                      hintText: _suggestedServerUrl,
                      suffixIcon: _urlController.text.trim().isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear',
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
                    decoration: const InputDecoration(
                      labelText: 'Label (optional)',
                      hintText: 'My server',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _basicAuthEnabled,
                    onChanged: (value) {
                      setState(() {
                        _basicAuthEnabled = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Use Basic Auth'),
                  ),
                  if (_basicAuthEnabled) ...[
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
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
                      decoration: const InputDecoration(labelText: 'Password'),
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
              if (appProvider.localSetupLogs.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Logs', style: Theme.of(context).textTheme.titleSmall),
                    const Spacer(),
                    TextButton(
                      onPressed: setupBusy
                          ? null
                          : appProvider.clearLocalSetupLogs,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 220),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      appProvider.localSetupLogs.join('\n'),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _complete,
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
            onPressed: _complete,
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
          label: const Text('Try again'),
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
        OutlinedButton(onPressed: _complete, child: const Text('Skip for now')),
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
