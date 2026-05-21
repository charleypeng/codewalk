import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/i18n/l10n_context.dart';
import '../../../../domain/entities/server_profile.dart';
import '../../../providers/app_provider.dart';
import '../../../utils/app_page_route.dart';
import '../../../widgets/searchable_dropdown_form_field.dart';
import '../../onboarding_wizard_page.dart';
import '../../opencode_setup_debug_page.dart';

class ServersSettingsSection extends StatefulWidget {
  const ServersSettingsSection({super.key});

  @override
  State<ServersSettingsSection> createState() => _ServersSettingsSectionState();
}

enum _ServerAction { activate, setDefault, clearDefault, edit, delete, check }

class _ServersSettingsSectionState extends State<ServersSettingsSection> {
  final _activeServerDropdownKey = GlobalKey<FormFieldState<String>>();
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
                    icon: const Icon(Symbols.auto_fix_high_rounded),
                    label: const Text('Setup Wizard'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.read<AppProvider>().refreshServerHealth(),
                    icon: const Icon(Symbols.health_and_safety),
                    label: const Text('Refresh Health'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _openSetupWizard(
                      initialFlow: SetupWizardInitialFlow.connectServer,
                    ),
                    icon: const Icon(Symbols.add),
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
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
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
    final hasActiveInList = appProvider.serverProfiles.any(
      (profile) => profile.id == activeId,
    );
    final dropdownValue = hasActiveInList ? activeId : null;
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
            SearchableDropdownFormField<String>(
              key: _activeServerDropdownKey,
              initialValue: dropdownValue,
              searchHintText: 'Search active server',
              emptyText: 'No servers found',
              searchTermsBuilder: (value) =>
                  _serverSearchTerms(appProvider, value),
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
                final currentActiveId = appProvider.activeServerId;
                if (id == null || id == currentActiveId) return;
                final status = appProvider.healthFor(id);
                if (status == ServerHealthStatus.unhealthy) {
                  // Restore dropdown to the actual active value.
                  _activeServerDropdownKey.currentState?.didChange(
                    dropdownValue,
                  );
                  _showMessage(
                    'This server is unhealthy. Use check health or edit settings before activating.',
                  );
                  return;
                }

                final ok = await appProvider.setActiveServer(id);
                if (!ok && mounted) {
                  // Restore dropdown on API failure.
                  _activeServerDropdownKey.currentState?.didChange(
                    dropdownValue,
                  );
                  _showMessage(appProvider.errorMessage);
                }
              },
              decoration: InputDecoration(
                labelText: context.l10n.settingsServersChooseActive,
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

  List<String> _serverSearchTerms(AppProvider appProvider, String serverId) {
    for (final profile in appProvider.serverProfiles) {
      if (profile.id == serverId) {
        return <String>[profile.displayName, profile.url, profile.id];
      }
    }
    return <String>[serverId];
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
                    icon: const Icon(Symbols.play_arrow_rounded),
                    label: const Text('Start'),
                  ),
                  OutlinedButton.icon(
                    onPressed: (isBusy || !isRunning)
                        ? null
                        : () => _stopLocalServer(appProvider),
                    icon: const Icon(Symbols.stop_rounded),
                    label: const Text('Stop'),
                  ),
                  OutlinedButton.icon(
                    onPressed: setupBusy
                        ? null
                        : () => _openSetupWizard(
                            initialFlow:
                                SetupWizardInitialFlow.managedLocalServer,
                          ),
                    icon: const Icon(Symbols.auto_fix_high_rounded),
                    label: const Text('Setup Wizard'),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey(
                      'open_code_setup_debug_button_settings',
                    ),
                    onPressed: _openSetupDebugPage,
                    icon: const Icon(Symbols.bug_report_rounded),
                    label: const Text('Setup Debug'),
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
          icon: const Icon(Symbols.more_vert),
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

  Future<void> _openSetupWizard({
    SetupWizardInitialFlow initialFlow = SetupWizardInitialFlow.choose,
    ServerProfile? initialServerProfile,
  }) async {
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => OnboardingWizardPage(
          onComplete: () => Navigator.of(context).pop(),
          showSkipAction: false,
          initialFlow: initialFlow,
          initialServerProfile: initialServerProfile,
        ),
      ),
    );
  }

  Future<void> _openSetupDebugPage() async {
    await Navigator.of(
      context,
    ).push(AppPageRoute(builder: (_) => const OpenCodeSetupDebugPage()));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Symbols.dns, size: 48),
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
        await _openSetupWizard(
          initialFlow: SetupWizardInitialFlow.connectServer,
          initialServerProfile: profile,
        );
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
class ServerSetupQuickGuide extends StatefulWidget {
  const ServerSetupQuickGuide({super.key, required this.onCopy});

  final void Function(String text) onCopy;

  @override
  State<ServerSetupQuickGuide> createState() => _ServerSetupQuickGuideState();
}

class _ServerSetupQuickGuideState extends State<ServerSetupQuickGuide> {
  static const String _baseCommand =
      'opencode serve --hostname 0.0.0.0 --port 4096';

  final TextEditingController _passwordController = TextEditingController();
  bool _protectWithPassword = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  String _quotedEnvValue(String value) {
    return "'${value.replaceAll("'", "'\\''")}'";
  }

  String _quotedPowerShellValue(String value) {
    return "'${value.replaceAll("'", "''")}'";
  }

  String _buildCommand() {
    final password = _passwordController.text.trim();
    if (!_protectWithPassword || password.isEmpty) {
      return _baseCommand;
    }

    final isWindows =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    if (isWindows) {
      return "\$env:OPENCODE_SERVER_PASSWORD=${_quotedPowerShellValue(password)}; $_baseCommand";
    }

    return 'OPENCODE_SERVER_PASSWORD=${_quotedEnvValue(password)} $_baseCommand';
  }

  @override
  Widget build(BuildContext context) {
    final isWindows =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    final locale = Localizations.maybeLocaleOf(context);
    final isPortuguese =
        locale?.languageCode.toLowerCase().startsWith('pt') ?? false;

    final title = isPortuguese ? 'Configuracao rapida' : 'Quick setup';
    final intro = isPortuguese
        ? 'CodeWalk e o app. OpenCode e o motor que precisa estar rodando para a conexao funcionar.'
        : 'CodeWalk is the app. OpenCode is the engine that needs to be running before this connection can work.';
    final firstStep = isPortuguese
        ? '1. Instale o OpenCode CLI.'
        : '1. Install OpenCode CLI.';
    final commandLabel = isPortuguese
        ? isWindows
              ? '2. Execute no PowerShell:'
              : '2. Execute no terminal:'
        : isWindows
        ? '2. Run in PowerShell:'
        : '2. Run in your terminal:';
    final passwordToggleLabel = isPortuguese
        ? 'Proteger acesso com senha'
        : 'Protect access with password';
    final passwordHint = isPortuguese ? 'Senha do servidor' : 'Server password';
    final installOptions = isPortuguese
        ? 'Outras opcoes oficiais: script de instalacao, npm, bun, pnpm, Homebrew ou binario do GitHub Releases.'
        : 'Other official install options: install script, npm, bun, pnpm, Homebrew, or a binary from GitHub Releases.';
    final verifyHint = isPortuguese
        ? 'Depois de iniciar o servidor, confirme /global/health ou /doc antes de colar a URL no CodeWalk.'
        : 'After starting the server, confirm /global/health or /doc responds before pasting the URL into CodeWalk.';
    final command = _buildCommand();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Symbols.info,
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
          Text(intro, style: Theme.of(context).textTheme.bodySmall),
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
                onPressed: () => widget.onCopy(command),
                icon: const Icon(Symbols.content_copy_rounded, size: 14),
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
          const SizedBox(height: 6),
          SwitchListTile(
            value: _protectWithPassword,
            onChanged: (value) {
              setState(() {
                _protectWithPassword = value;
              });
            },
            contentPadding: EdgeInsets.zero,
            title: Text(passwordToggleLabel),
          ),
          if (_protectWithPassword) ...[
            const SizedBox(height: 4),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: passwordHint),
              onChanged: (_) => setState(() {}),
            ),
          ],
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
          const SizedBox(height: 8),
          Text(installOptions, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(verifyHint, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
