import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/l10n_context.dart';
import '../providers/app_provider.dart';
import '../services/local_opencode_server_runtime_types.dart';

class OpenCodeSetupDebugPage extends StatelessWidget {
  const OpenCodeSetupDebugPage({super.key});

  Future<void> _copyReport(BuildContext context) async {
    final report = context.read<AppProvider>().exportSetupDebugReport();
    await Clipboard.setData(ClipboardData(text: report));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.msgSetupDebugCopied)));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final entries = appProvider.setupDebugEntries.reversed.toList(
          growable: false,
        );
        final setupLogs = appProvider.localSetupLogs.reversed.toList(
          growable: false,
        );
        final hasDebugContent =
            entries.isNotEmpty ||
            setupLogs.isNotEmpty ||
            appProvider.localServerLastOutput.trim().isNotEmpty ||
            appProvider.localEnvironmentReport != null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('OpenCode Setup Debug'),
            actions: [
              IconButton(
                icon: const Icon(Symbols.copy_all),
                tooltip: 'Copy setup debug',
                onPressed: hasDebugContent ? () => _copyReport(context) : null,
              ),
              IconButton(
                icon: const Icon(Symbols.delete_outline),
                tooltip: 'Clear setup debug',
                onPressed: hasDebugContent
                    ? appProvider.clearSetupDebugData
                    : null,
              ),
            ],
          ),
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SetupDebugCard(
                        title: 'Focused on OpenCode setup',
                        icon: Symbols.terminal_rounded,
                        child: Text(
                          'This screen only covers OpenCode installation, diagnostics, and local setup troubleshooting. Use App Logs for general CodeWalk runtime issues.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SetupDebugCard(
                        title: 'Current status',
                        icon: Symbols.info_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(appProvider.localServerStatusMessage),
                            if (appProvider.localSetupMessage
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                appProvider.localSetupMessage,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            if (appProvider.localSetupInProgress) ...[
                              const SizedBox(height: 12),
                              const LinearProgressIndicator(minHeight: 3),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SetupDebugCard(
                        title: 'Environment diagnostics',
                        icon: Symbols.health_and_safety_rounded,
                        child: _EnvironmentDetails(
                          report: appProvider.localEnvironmentReport,
                          commandPath: appProvider.localServerCommandPath,
                        ),
                      ),
                      if (entries.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _SetupDebugCard(
                          title: 'Timeline',
                          icon: Symbols.history_rounded,
                          child: Column(
                            children: [
                              for (var i = 0; i < entries.length; i++) ...[
                                _SetupDebugEntryTile(entry: entries[i]),
                                if (i < entries.length - 1)
                                  const Divider(height: 20),
                              ],
                            ],
                          ),
                        ),
                      ],
                      if (appProvider.localServerLastOutput
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _SetupDebugCard(
                          title: 'Latest local server output',
                          icon: Symbols.speaker_notes_rounded,
                          child: _MonospaceBlock(
                            text: appProvider.localServerLastOutput,
                          ),
                        ),
                      ],
                      if (setupLogs.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _SetupDebugCard(
                          title: 'Captured setup logs',
                          icon: Symbols.article_rounded,
                          child: _MonospaceBlock(text: setupLogs.join('\n')),
                        ),
                      ],
                      if (!hasDebugContent) ...[
                        const SizedBox(height: 12),
                        const _SetupDebugCard(
                          title: 'No captured setup details yet',
                          icon: Symbols.inbox_rounded,
                          child: Text(
                            'Run diagnostics, try an installation method, or attempt a setup flow to capture OpenCode-specific troubleshooting details here.',
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const _SetupDebugCard(
                        title: 'Manual troubleshooting',
                        icon: Symbols.build_circle_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'If CodeWalk did not capture enough context, check the official OpenCode logs and health endpoints directly:',
                            ),
                            SizedBox(height: 8),
                            Text('• Linux logs: ~/.local/share/opencode/log/'),
                            Text(
                              '• Run OpenCode with: opencode --log-level DEBUG',
                            ),
                            Text('• Server health: GET /global/health'),
                            Text('• Server docs: GET /doc'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SetupDebugCard extends StatelessWidget {
  const _SetupDebugCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _EnvironmentDetails extends StatelessWidget {
  const _EnvironmentDetails({required this.report, required this.commandPath});

  final LocalOpencodeEnvironmentReport? report;
  final String commandPath;

  @override
  Widget build(BuildContext context) {
    if (report == null) {
      return const Text('Diagnostics are still loading.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(label: 'Platform', value: report!.platform),
        if (commandPath.trim().isNotEmpty)
          _InfoRow(label: 'Command path', value: commandPath.trim()),
        _ToolStatusRow(label: 'OpenCode', status: report!.opencode),
        _ToolStatusRow(label: 'Node.js', status: report!.node),
        _ToolStatusRow(label: 'npm', status: report!.npm),
        _ToolStatusRow(label: 'Bun', status: report!.bun),
        _ToolStatusRow(label: 'WSL', status: report!.wsl),
        _InfoRow(
          label: 'Network',
          value: report!.hasNetworkAccess ? 'reachable' : 'unreachable',
        ),
        _InfoRow(
          label: 'Install directory',
          value: report!.installDirectoryWritable ? 'writable' : 'not writable',
        ),
        const SizedBox(height: 8),
        Text(
          report!.recommendation,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 124, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ToolStatusRow extends StatelessWidget {
  const _ToolStatusRow({required this.label, required this.status});

  final String label;
  final LocalToolStatus status;

  @override
  Widget build(BuildContext context) {
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

    return _InfoRow(
      label: label,
      value: details.isEmpty
          ? (status.available ? 'available' : 'not available')
          : details.join(' | '),
    );
  }
}

class _SetupDebugEntryTile extends StatelessWidget {
  const _SetupDebugEntryTile({required this.entry});

  final SetupDebugEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = entry.severity == SetupDebugSeverity.error
        ? colorScheme.error
        : colorScheme.primary;
    final time = TimeOfDay.fromDateTime(entry.timestamp).format(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Symbols.circle, size: 10, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$time - ${entry.source}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              Text(entry.message),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonospaceBlock extends StatelessWidget {
  const _MonospaceBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 280),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
        ),
      ),
    );
  }
}
