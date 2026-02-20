import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../providers/settings_provider.dart';
import 'settings/sections/servers_settings_section.dart';

/// First-run onboarding wizard that guides users through initial server setup.
/// Shown when no server profiles exist and skipOnboardingWizard is false.
class OnboardingWizardPage extends StatefulWidget {
  const OnboardingWizardPage({super.key, this.onComplete});

  /// Called when the wizard completes (server configured or skipped).
  /// When null, the gate in AppShellPage handles navigation automatically.
  final VoidCallback? onComplete;

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

  final TextEditingController _urlController = TextEditingController(
    text: _ServersSettingsSectionState.suggestedServerUrl,
  );
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _basicAuthEnabled = false;
  bool _aiGeneratedTitlesEnabled = true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
      _handleSkip();
      return;
    }
    setState(() {
      if (_step == 2) {
        _connectionSuccess = false;
        _connectionError = null;
      }
      _step--;
    });
  }

  Future<void> _handleSkip() async {
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
                      context
                          .read<SettingsProvider>()
                          .setSkipOnboardingWizard(true);
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

  Future<void> _testConnection() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _testing = true;
      _connectionError = null;
    });

    final appProvider = context.read<AppProvider>();

    // If we already added a server in a previous attempt, re-check its health
    // instead of trying to add a duplicate profile.
    if (_addedServerId != null) {
      await appProvider.refreshServerHealth(serverId: _addedServerId);
      if (!mounted) return;
      final health = appProvider.healthFor(_addedServerId!);
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

    final adjustedUrl = _mapAndroidLoopback(_urlController.text.trim());

    final success = await appProvider.addServerProfile(
      url: adjustedUrl,
      label: _labelController.text.trim(),
      basicAuthEnabled: _basicAuthEnabled,
      basicAuthUsername: _usernameController.text.trim(),
      basicAuthPassword: _passwordController.text.trim(),
      aiGeneratedTitlesEnabled: _aiGeneratedTitlesEnabled,
      setAsActive: true,
    );

    if (!mounted) return;

    if (success) {
      final serverId = appProvider.serverProfiles.last.id;
      _addedServerId = serverId;
      final health = appProvider.healthFor(serverId);
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

    return Uri(
      scheme: uri.scheme,
      host: '10.0.2.2',
      port: uri.port,
    ).toString();
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Setup'),
          automaticallyImplyLeading: false,
          leading: _step > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _handleBack,
                )
              : null,
          actions: [
            if (_step < 2 || !_connectionSuccess)
              TextButton(
                onPressed: _handleSkip,
                child: const Text('Skip'),
              ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
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

  Widget _buildStep() {
    return switch (_step) {
      0 => _buildWelcomeStep(),
      1 => _buildServerSetupStep(),
      2 => _buildReadyStep(),
      _ => _buildWelcomeStep(),
    };
  }

  // -- Step 0: Welcome --

  Widget _buildWelcomeStep() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      key: const ValueKey('step_welcome'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.code_rounded,
          size: 72,
          color: colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome to ${AppConstants.appName}',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Connect to an OpenCode server to get started',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
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
                      Icons.dns_rounded,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connect to server',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'I already have a server running',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
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
                      Icons.help_outline_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'I need help setting up',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Show me how to install and start a server',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
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
    return SingleChildScrollView(
      key: const ValueKey('step_server_setup'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              'Server connection',
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
                      hintText: _ServersSettingsSectionState.suggestedServerUrl,
                      suffixIcon: _urlController.text.trim().isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear',
                              icon: const Icon(Icons.clear),
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
                      decoration: const InputDecoration(
                        labelText: 'Username',
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
                      decoration: const InputDecoration(
                        labelText: 'Password',
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
                              Icons.error_outline,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _connectionError!,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.link_rounded),
                    label: Text(
                      _testing ? 'Testing...' : 'Test connection',
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

  // -- Step 2: Ready --

  Widget _buildReadyStep() {
    final colorScheme = Theme.of(context).colorScheme;

    if (_connectionSuccess) {
      return Column(
        key: const ValueKey('step_ready_success'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 72,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          Text(
            "You're all set!",
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your server is connected and ready to use.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          FilledButton.icon(
            onPressed: _complete,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text('Start using ${AppConstants.appName}'),
          ),
        ],
      );
    }

    // Connection failed but server was added
    return Column(
      key: const ValueKey('step_ready_failed'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.warning_amber_rounded,
          size: 72,
          color: colorScheme.error,
        ),
        const SizedBox(height: 24),
        Text(
          'Connection issue',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _connectionError ?? 'Could not verify the server connection.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
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
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _complete,
          child: const Text('Skip for now'),
        ),
      ],
    );
  }
}

/// Alias to access the suggested URL constant from the servers settings section.
class _ServersSettingsSectionState {
  static const String suggestedServerUrl = 'http://127.0.0.1:4096';
}
