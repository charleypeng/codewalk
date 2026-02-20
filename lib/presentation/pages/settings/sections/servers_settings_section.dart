import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/server_profile.dart';
import '../../../providers/app_provider.dart';
import '../../../services/local_opencode_server_runtime_types.dart';
import '../../onboarding_wizard_page.dart';

class ServersSettingsSection extends StatefulWidget {
  const ServersSettingsSection({super.key});

  @override
  State<ServersSettingsSection> createState() => _ServersSettingsSectionState();
}

enum _ServerAction { activate, setDefault, clearDefault, edit, delete, check }

class _ServersSettingsSectionState extends State<ServersSettingsSection> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    final appProvider = context.read<AppProvider>();
    await appProvider.initialize();
    if (!mounted) return;
    await appProvider.refreshServerHealth();
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final profiles = appProvider.serverProfiles;
        if (_loading && profiles.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _openSetupWizard,
                    icon: const Icon(Icons.auto_fix_high_rounded),
                    label: const Text('Setup Wizard'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.read<AppProvider>().refreshServerHealth(),
                    icon: const Icon(Icons.health_and_safety_outlined),
                    label: const Text('Refresh Health'),
                  ),
                  FilledButton.icon(
                    onPressed: _openCreateDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Server'),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildActiveServerCard(appProvider),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildLocalServerCard(appProvider),
              const SizedBox(height: AppConstants.defaultPadding),
              Expanded(
                child: profiles.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: profiles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) => _buildProfileTile(
                          appProvider: appProvider,
                          profile: profiles[index],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveServerCard(AppProvider appProvider) {
    final activeServer = appProvider.activeServer;
    final activeId = appProvider.activeServerId;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Server',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: activeId,
              items: appProvider.serverProfiles
                  .map(
                    (profile) => DropdownMenuItem<String>(
                      value: profile.id,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _HealthDot(status: appProvider.healthFor(profile.id)),
                          const SizedBox(width: 8),
                          Flexible(
                            fit: FlexFit.loose,
                            child: Text(
                              profile.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (id) async {
                if (id == null || id == activeId) return;
                final status = appProvider.healthFor(id);
                if (status == ServerHealthStatus.unhealthy) {
                  _showMessage(
                    'This server is unhealthy. Use check health or edit settings before activating.',
                  );
                  return;
                }

                final ok = await appProvider.setActiveServer(id);
                if (!ok && mounted) {
                  _showMessage(appProvider.errorMessage);
                }
              },
              decoration: const InputDecoration(
                labelText: 'Choose active server',
                border: OutlineInputBorder(),
              ),
            ),
            if (activeServer != null) ...[
              const SizedBox(height: 10),
              Text(
                activeServer.url,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocalServerCard(AppProvider appProvider) {
    final status = appProvider.localServerStatus;
    final supported = appProvider.localServerSupported;
    final isBusy =
        status == LocalServerRuntimeStatus.starting ||
        status == LocalServerRuntimeStatus.stopping;
    final isRunning = status == LocalServerRuntimeStatus.running;
    final setupBusy = appProvider.localSetupInProgress;

    final (statusColor, statusLabel) = switch (status) {
      LocalServerRuntimeStatus.running => (Colors.green, 'Running'),
      LocalServerRuntimeStatus.starting => (Colors.orange, 'Starting'),
      LocalServerRuntimeStatus.stopping => (Colors.orange, 'Stopping'),
      LocalServerRuntimeStatus.failed => (Colors.red, 'Failed'),
      LocalServerRuntimeStatus.stopped => (Colors.grey, 'Stopped'),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Local OpenCode Server',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Desktop mode can launch and manage `opencode serve` directly from CodeWalk.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
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
            const SizedBox(height: 8),
            Text(
              appProvider.localServerStatusMessage,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (appProvider.localServerCommandPath.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Command: ${appProvider.localServerCommandPath}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (appProvider.localServerLastOutput.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Latest output: ${appProvider.localServerLastOutput}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 10),
            if (!supported)
              Text(
                'This managed mode is available only on desktop builds (Linux/macOS/Windows).',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: (isBusy || isRunning)
                        ? null
                        : () => _startLocalServer(appProvider),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start'),
                  ),
                  OutlinedButton.icon(
                    onPressed: (isBusy || !isRunning)
                        ? null
                        : () => _stopLocalServer(appProvider),
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('Stop'),
                  ),
                  OutlinedButton.icon(
                    onPressed: setupBusy
                        ? null
                        : () => _openLocalServerWizard(appProvider),
                    icon: const Icon(Icons.auto_fix_high_rounded),
                    label: const Text('Setup Wizard'),
                  ),
                ],
              ),
            if (appProvider.localSetupInProgress) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(minHeight: 3),
            ],
            if (appProvider.localSetupMessage.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                appProvider.localSetupMessage,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required AppProvider appProvider,
    required ServerProfile profile,
  }) {
    final isActive = profile.id == appProvider.activeServerId;
    final isDefault = profile.id == appProvider.defaultServerId;

    return Card(
      child: ListTile(
        leading: _HealthDot(status: appProvider.healthFor(profile.id)),
        title: Row(
          children: [
            Expanded(
              child: Text(
                profile.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive) const _MetaChip(label: 'Active'),
            if (isDefault) const _MetaChip(label: 'Default'),
          ],
        ),
        subtitle: Text(
          profile.url,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<_ServerAction>(
          onSelected: (action) => _handleServerAction(
            appProvider: appProvider,
            profile: profile,
            action: action,
          ),
          itemBuilder: (_) => [
            if (!isActive)
              const PopupMenuItem(
                value: _ServerAction.activate,
                child: Text('Set Active'),
              ),
            if (!isDefault)
              const PopupMenuItem(
                value: _ServerAction.setDefault,
                child: Text('Set Default'),
              ),
            if (isDefault)
              const PopupMenuItem(
                value: _ServerAction.clearDefault,
                child: Text('Clear Default'),
              ),
            const PopupMenuItem(
              value: _ServerAction.check,
              child: Text('Check Health'),
            ),
            const PopupMenuItem(value: _ServerAction.edit, child: Text('Edit')),
            const PopupMenuItem(
              value: _ServerAction.delete,
              child: Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  void _openSetupWizard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OnboardingWizardPage(
          onComplete: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.dns_outlined, size: 48),
          const SizedBox(height: 12),
          Text(
            'No servers configured',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Add at least one OpenCode server to start using the app.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _handleServerAction({
    required AppProvider appProvider,
    required ServerProfile profile,
    required _ServerAction action,
  }) async {
    switch (action) {
      case _ServerAction.activate:
        if (appProvider.healthFor(profile.id) == ServerHealthStatus.unhealthy) {
          _showMessage('Cannot activate an unhealthy server');
          return;
        }
        final ok = await appProvider.setActiveServer(profile.id);
        if (!ok) {
          _showMessage(appProvider.errorMessage);
        }
        break;
      case _ServerAction.setDefault:
        final ok = await appProvider.setDefaultServer(profile.id);
        if (!ok) {
          _showMessage(appProvider.errorMessage);
        }
        break;
      case _ServerAction.clearDefault:
        await appProvider.clearDefaultServer();
        break;
      case _ServerAction.edit:
        await _openEditDialog(profile);
        break;
      case _ServerAction.delete:
        await _confirmDelete(profile);
        break;
      case _ServerAction.check:
        await appProvider.refreshServerHealth(serverId: profile.id);
        break;
    }
  }

  Future<void> _startLocalServer(AppProvider appProvider) async {
    final ok = await appProvider.startLocalServer();
    if (!ok) {
      _showMessage(appProvider.errorMessage);
    }
  }

  Future<void> _stopLocalServer(AppProvider appProvider) async {
    final ok = await appProvider.stopLocalServer();
    if (!ok) {
      _showMessage(appProvider.errorMessage);
    }
  }

  Future<void> _openLocalServerWizard(AppProvider appProvider) async {
    await appProvider.runLocalServerDiagnostics();
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Consumer<AppProvider>(
          builder: (context, provider, _) {
            final report = provider.localEnvironmentReport;
            final setupBusy = provider.localSetupInProgress;

            return AlertDialog(
              title: const Text('Local Server Setup Wizard'),
              content: SizedBox(
                width: 640,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This wizard checks required runtimes and installs OpenCode for desktop local mode.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      if (report == null)
                        const Center(child: CircularProgressIndicator())
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
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: setupBusy
                                ? null
                                : () async {
                                    await provider.runLocalServerDiagnostics();
                                  },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Refresh Checks'),
                          ),
                          OutlinedButton.icon(
                            onPressed:
                                setupBusy ||
                                    !(report?.opencode.available ?? false)
                                ? null
                                : () async {
                                    final ok = await provider
                                        .useDetectedLocalServerCommand();
                                    if (!ok) {
                                      _showMessage(provider.errorMessage);
                                      return;
                                    }
                                    _showMessage(
                                      'Using detected OpenCode command.',
                                    );
                                  },
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Use Existing'),
                          ),
                          FilledButton.icon(
                            onPressed: setupBusy
                                ? null
                                : () async {
                                    final ok = await provider
                                        .installLocalServerRequirements(
                                          LocalOpencodeInstallMethod
                                              .bunBootstrapThenInstall,
                                        );
                                    if (!ok) {
                                      _showMessage(provider.errorMessage);
                                    }
                                  },
                            icon: const Icon(Icons.rocket_launch_outlined),
                            label: const Text('Install Bun + OpenCode'),
                          ),
                          OutlinedButton.icon(
                            onPressed: setupBusy
                                ? null
                                : () async {
                                    final ok = await provider
                                        .installLocalServerRequirements(
                                          LocalOpencodeInstallMethod.bunGlobal,
                                        );
                                    if (!ok) {
                                      _showMessage(provider.errorMessage);
                                    }
                                  },
                            icon: const Icon(Icons.bolt_outlined),
                            label: const Text('Install via Bun'),
                          ),
                          OutlinedButton.icon(
                            onPressed: setupBusy
                                ? null
                                : () async {
                                    final ok = await provider
                                        .installLocalServerRequirements(
                                          LocalOpencodeInstallMethod.npmGlobal,
                                        );
                                    if (!ok) {
                                      _showMessage(provider.errorMessage);
                                    }
                                  },
                            icon: const Icon(Icons.inventory_2_outlined),
                            label: const Text('Install via npm'),
                          ),
                          OutlinedButton.icon(
                            onPressed: setupBusy
                                ? null
                                : () async {
                                    final ok = await provider
                                        .installLocalServerRequirements(
                                          LocalOpencodeInstallMethod
                                              .downloadBinary,
                                        );
                                    if (!ok) {
                                      _showMessage(provider.errorMessage);
                                    }
                                  },
                            icon: const Icon(
                              Icons.download_for_offline_outlined,
                            ),
                            label: const Text('Install Binary'),
                          ),
                        ],
                      ),
                      if (provider.localSetupInProgress) ...[
                        const SizedBox(height: 10),
                        const LinearProgressIndicator(minHeight: 3),
                      ],
                      if (provider.localSetupMessage.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          provider.localSetupMessage,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (provider.localSetupLogs.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              'Logs',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: setupBusy
                                  ? null
                                  : provider.clearLocalSetupLogs,
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
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              provider.localSetupLogs.join('\n'),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
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
        ? const Icon(Icons.check_circle, color: Colors.green, size: 16)
        : const Icon(Icons.cancel, color: Colors.red, size: 16);

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

  Future<void> _openCreateDialog() async {
    await _openProfileDialog(initial: null);
  }

  Future<void> _openEditDialog(ServerProfile profile) async {
    await _openProfileDialog(initial: profile);
  }

  static const String _suggestedServerUrl = 'http://127.0.0.1:4096';

  /// Default server URL suggestion, exposed for reuse in onboarding wizard.
  static const String suggestedServerUrl = _suggestedServerUrl;

  Widget _buildServerSetupQuickGuide(BuildContext context) {
    return ServerSetupQuickGuide(onCopy: _copyTextToClipboard);
  }

  void _copyTextToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Command copied')));
  }

  Future<void> _openProfileDialog({ServerProfile? initial}) async {
    final urlController = TextEditingController(
      text: initial?.url ?? _suggestedServerUrl,
    );
    final labelController = TextEditingController(text: initial?.label ?? '');
    final usernameController = TextEditingController(
      text: initial?.basicAuthUsername ?? '',
    );
    final passwordController = TextEditingController(
      text: initial?.basicAuthPassword ?? '',
    );
    var basicAuthEnabled = initial?.basicAuthEnabled ?? false;
    var aiGeneratedTitlesEnabled = initial?.aiGeneratedTitlesEnabled ?? true;
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(initial == null ? 'Add Server' : 'Edit Server'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildServerSetupQuickGuide(context),
                      TextFormField(
                        controller: urlController,
                        onChanged: (_) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          labelText: 'Server URL',
                          hintText: _suggestedServerUrl,
                          suffixIcon: urlController.text.trim().isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear server URL',
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    urlController.clear();
                                    setState(() {});
                                  },
                                ),
                        ),
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
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: labelController,
                        decoration: const InputDecoration(
                          labelText: 'Label (optional)',
                          hintText: 'Office server',
                        ),
                      ),
                      const SizedBox(height: 6),
                      SwitchListTile(
                        value: basicAuthEnabled,
                        onChanged: (value) {
                          setState(() {
                            basicAuthEnabled = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Use Basic Auth'),
                      ),
                      if (basicAuthEnabled) ...[
                        TextFormField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                          ),
                          validator: (value) {
                            if (!basicAuthEnabled) return null;
                            if ((value ?? '').trim().isEmpty) {
                              return 'Enter username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (!basicAuthEnabled) return null;
                            if ((value ?? '').trim().isEmpty) {
                              return 'Enter password';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 6),
                      SwitchListTile(
                        value: aiGeneratedTitlesEnabled,
                        onChanged: (value) {
                          setState(() {
                            aiGeneratedTitlesEnabled = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        title: const Text('AI generated titles'),
                        subtitle: const Text(
                          'Uses your server\'s title agent to name conversations',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) return;
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave != true || !mounted) {
      urlController.dispose();
      labelController.dispose();
      usernameController.dispose();
      passwordController.dispose();
      return;
    }

    final appProvider = context.read<AppProvider>();
    final adjustedUrl = _mapAndroidLoopback(urlController.text.trim());
    final success = initial == null
        ? await appProvider.addServerProfile(
            url: adjustedUrl,
            label: labelController.text.trim(),
            basicAuthEnabled: basicAuthEnabled,
            basicAuthUsername: usernameController.text.trim(),
            basicAuthPassword: passwordController.text.trim(),
            aiGeneratedTitlesEnabled: aiGeneratedTitlesEnabled,
            setAsActive: appProvider.serverProfiles.isEmpty,
          )
        : await appProvider.updateServerProfile(
            id: initial.id,
            url: adjustedUrl,
            label: labelController.text.trim(),
            basicAuthEnabled: basicAuthEnabled,
            basicAuthUsername: usernameController.text.trim(),
            basicAuthPassword: passwordController.text.trim(),
            aiGeneratedTitlesEnabled: aiGeneratedTitlesEnabled,
          );

    if (!success) {
      _showMessage(appProvider.errorMessage);
    } else if (kIsWeb == false &&
        defaultTargetPlatform == TargetPlatform.android &&
        adjustedUrl.contains('10.0.2.2') &&
        urlController.text.contains('localhost')) {
      _showMessage('Android emulator detected: localhost mapped to 10.0.2.2');
    }

    urlController.dispose();
    labelController.dispose();
    usernameController.dispose();
    passwordController.dispose();
  }

  Future<void> _confirmDelete(ServerProfile profile) async {
    final appProvider = context.read<AppProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete server'),
          content: Text('Remove "${profile.displayName}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;
    final ok = await appProvider.removeServerProfile(profile.id);
    if (!ok) {
      _showMessage(appProvider.errorMessage);
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HealthDot extends StatelessWidget {
  const _HealthDot({required this.status});

  final ServerHealthStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, tooltip) = switch (status) {
      ServerHealthStatus.healthy => (Colors.green, 'Healthy'),
      ServerHealthStatus.unhealthy => (Colors.red, 'Unhealthy'),
      ServerHealthStatus.unknown => (Colors.grey, 'Unknown'),
    };

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall),
      ),
    );
  }
}

/// Reusable quick-guide widget for OpenCode server setup instructions.
/// Used in both the Settings > Servers section and the onboarding wizard.
class ServerSetupQuickGuide extends StatelessWidget {
  const ServerSetupQuickGuide({super.key, required this.onCopy});

  /// Command string for starting a local OpenCode server.
  static const String command =
      'opencode serve --hostname 127.0.0.1 --port 4096';

  final void Function(String text) onCopy;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context);
    final isPortuguese =
        locale?.languageCode.toLowerCase().startsWith('pt') ?? false;

    final title = isPortuguese ? 'Configuracao rapida' : 'Quick setup';
    final firstStep = isPortuguese
        ? '1. Instale o OpenCode CLI.'
        : '1. Install OpenCode CLI.';
    final commandLabel = isPortuguese
        ? '2. Execute no terminal:'
        : '2. Run in your terminal:';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(firstStep, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  commandLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextButton.icon(
                onPressed: () => onCopy(command),
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text('Copy'),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: SelectableText(
              command,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
