import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/i18n/l10n_context.dart';
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
            _buildCheckUpdatesOnOpenTile(context, settings),
            _buildCheckForUpdatesTile(context, settings, checking),
            const Divider(height: 32),
            _buildReplayChatTourTile(context, settings),
            _buildResetAppTile(context),
            const Divider(height: 32),
            _buildGitHubTile(context),
          ],
        );
      },
    );
  }

  Widget _buildVersionTile(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      leading: const Icon(Symbols.info),
      title: Text(l10n.settingsAboutVersion),
      subtitle: Text(
        _version.isEmpty
            ? l10n.settingsAboutLoading
            : l10n.settingsAboutVersionBuild(_version, _buildNumber),
      ),
    );
  }

  Widget _buildUpdateAvailableTile(
    BuildContext context,
    SettingsProvider settings,
    UpdateCheckResult result,
  ) {
    final l10n = context.l10n;
    final installState = settings.installState;
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
                    l10n.settingsAboutUpdateAvailable(result.latestVersion),
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
                result.releaseNotes!.length > 400
                    ? '${result.releaseNotes!.substring(0, 400)}...'
                    : result.releaseNotes!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
            const SizedBox(height: 8),
            // Install progress/state widget
            _buildInstallControl(context, settings, result, installState),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallControl(
    BuildContext context,
    SettingsProvider settings,
    UpdateCheckResult result,
    UpdateInstallState installState,
  ) {
    if (installState == UpdateInstallState.downloading) {
      final l10n = context.l10n;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: settings.installProgress > 0
                ? settings.installProgress
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.settingsAboutDownloading(
              (settings.installProgress * 100).toStringAsFixed(0),
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      );
    }

    if (installState == UpdateInstallState.installing) {
      final l10n = context.l10n;
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            l10n.settingsAboutInstalling,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      );
    }

    if (installState == UpdateInstallState.done) {
      return Text(
        context.l10n.settingsAboutUpdateInstalled,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      );
    }

    // idle or failed: show action buttons
    return Wrap(
      spacing: 8,
      children: [
        if (installState == UpdateInstallState.failed)
          FilledButton.icon(
            onPressed: () => unawaited(settings.startInstall()),
            icon: const Icon(Symbols.refresh, size: 16),
            label: Text(context.l10n.settingsAboutRetryInstall),
          )
        else
          FilledButton.icon(
            onPressed: () => unawaited(settings.startInstall()),
            icon: const Icon(Symbols.download, size: 16),
            label: Text(context.l10n.settingsAboutInstallUpdate),
          ),
        OutlinedButton(
          onPressed: () => settings.dismissUpdate(result.latestVersion),
          child: Text(context.l10n.settingsAboutDismiss),
        ),
      ],
    );
  }

  Widget _buildUpToDateTile(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      leading: Icon(
        Symbols.check_circle_outline,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(l10n.settingsAboutUpToDate),
      subtitle: Text(l10n.settingsAboutLatestVersion(_version)),
    );
  }

  Widget _buildCheckUpdatesOnOpenTile(
    BuildContext context,
    SettingsProvider settings,
  ) {
    return SwitchListTile(
      secondary: const Icon(Symbols.update),
      title: Text(context.l10n.settingsAboutCheckOnOpen),
      subtitle: Text(context.l10n.settingsAboutCheckOnOpenDescription),
      value: settings.settings.checkUpdatesOnOpen,
      onChanged: (value) => settings.setCheckUpdatesOnOpen(value),
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
      title: Text(context.l10n.settingsAboutCheckForUpdates),
      subtitle: Text(
        checking
            ? context.l10n.settingsAboutChecking
            : context.l10n.settingsAboutTapToCheck,
      ),
      onTap: checking ? null : () => settings.checkForUpdate(),
    );
  }

  Widget _buildResetAppTile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(Symbols.restart_alt_rounded, color: colorScheme.error),
      title: Text(
        context.l10n.settingsAboutResetApp,
        style: TextStyle(color: colorScheme.error),
      ),
      subtitle: Text(context.l10n.settingsAboutEraseAllData),
      onTap: () => _confirmResetApp(context),
    );
  }

  Widget _buildReplayChatTourTile(
    BuildContext context,
    SettingsProvider settings,
  ) {
    return ListTile(
      key: const ValueKey<String>('about_replay_chat_tour_tile'),
      leading: const Icon(Symbols.play_circle_rounded),
      title: Text(context.l10n.settingsAboutReplayChatTour),
      subtitle: Text(context.l10n.settingsAboutReplayChatTourDescription),
      onTap: () => unawaited(_replayChatTour(context, settings)),
    );
  }

  Future<void> _replayChatTour(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    if (settings.pendingPostOnboardingChatTour) {
      await settings.setPendingPostOnboardingChatTour(false);
    }
    await settings.setPendingPostOnboardingChatTour(true);
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _confirmResetApp(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.l10n.settingsAboutResetAppQuestion),
          content: Text(context.l10n.settingsAboutResetAppWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n.commonReset),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    // Clear all persisted data.
    final localDataSource = di.sl<AppLocalDataSource>();
    await localDataSource.clearAll();

    if (!context.mounted) return;

    // Reset in-memory provider state and re-initialize from (now empty) storage.
    final appProvider = context.read<AppProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    appProvider.resetToDefaults();
    settingsProvider.resetToDefaults();
    await appProvider.initialize();
    await settingsProvider.initialize();

    // Navigate back to AppShellPage, clearing the stack so the
    // onboarding gate re-evaluates with empty server profiles.
    if (!context.mounted) return;
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
