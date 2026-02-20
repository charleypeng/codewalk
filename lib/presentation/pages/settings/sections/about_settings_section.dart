import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../data/datasources/app_local_datasource.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/update_check_service.dart';
import '../../app_shell_page.dart';

class AboutSettingsSection extends StatefulWidget {
  const AboutSettingsSection({super.key});

  @override
  State<AboutSettingsSection> createState() => _AboutSettingsSectionState();
}

class _AboutSettingsSectionState extends State<AboutSettingsSection> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final updateResult = settings.updateCheckResult;
        final checking = settings.checkingForUpdate;
        final upToDate = settings.lastCheckFoundNoUpdate;

        return ListView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          children: [
            _buildVersionTile(context),
            if (updateResult != null && updateResult.isNewer)
              _buildUpdateAvailableTile(context, settings, updateResult),
            if (upToDate && updateResult == null) _buildUpToDateTile(context),
            _buildCheckForUpdatesTile(context, settings, checking),
            const Divider(height: 32),
            _buildResetAppTile(context),
            const Divider(height: 32),
            _buildGitHubTile(context),
          ],
        );
      },
    );
  }

  Widget _buildVersionTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Symbols.info),
      title: const Text('Version'),
      subtitle: Text(
        _version.isEmpty ? 'Loading...' : '$_version (build $_buildNumber)',
      ),
    );
  }

  Widget _buildUpdateAvailableTile(
    BuildContext context,
    SettingsProvider settings,
    UpdateCheckResult result,
  ) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.system_update,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Update available: v${result.latestVersion}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            if (result.releaseNotes != null &&
                result.releaseNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                result.releaseNotes!.length > 200
                    ? '${result.releaseNotes!.substring(0, 200)}...'
                    : result.releaseNotes!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (result.releaseUrl != null)
                  FilledButton.icon(
                    onPressed: () => _openUrl(result.releaseUrl!),
                    icon: const Icon(Symbols.open_in_new, size: 16),
                    label: const Text('View release'),
                  ),
                OutlinedButton(
                  onPressed: () => settings.dismissUpdate(result.latestVersion),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpToDateTile(BuildContext context) {
    return ListTile(
      leading: Icon(
        Symbols.check_circle_outline,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('You\'re up to date'),
      subtitle: Text('v$_version is the latest version'),
    );
  }

  Widget _buildCheckForUpdatesTile(
    BuildContext context,
    SettingsProvider settings,
    bool checking,
  ) {
    return ListTile(
      leading: checking
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Symbols.refresh),
      title: const Text('Check for updates'),
      subtitle: Text(
        checking ? 'Checking...' : 'Tap to check for new versions',
      ),
      onTap: checking ? null : () => settings.checkForUpdate(),
    );
  }

  Widget _buildResetAppTile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(Symbols.restart_alt_rounded, color: colorScheme.error),
      title: Text('Reset app', style: TextStyle(color: colorScheme.error)),
      subtitle: const Text('Erase all data and restart'),
      onTap: () => _confirmResetApp(context),
    );
  }

  Future<void> _confirmResetApp(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset app?'),
          content: const Text(
            'This will erase all servers, settings, and cached data. '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    // Clear all persisted data.
    final localDataSource = di.sl<AppLocalDataSource>();
    await localDataSource.clearAll();

    if (!mounted) return;

    // Reset in-memory provider state and re-initialize from (now empty) storage.
    final appProvider = context.read<AppProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    appProvider.resetToDefaults();
    settingsProvider.resetToDefaults();
    await appProvider.initialize();
    await settingsProvider.initialize();

    // Navigate back to AppShellPage, clearing the stack so the
    // onboarding gate re-evaluates with empty server profiles.
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppShellPage()),
      (_) => false,
    );
  }

  Widget _buildGitHubTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Symbols.code),
      title: const Text('GitHub'),
      subtitle: const Text('verseles/codewalk'),
      trailing: const Icon(Symbols.open_in_new, size: 16),
      onTap: () => _openUrl('https://github.com/verseles/codewalk'),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
