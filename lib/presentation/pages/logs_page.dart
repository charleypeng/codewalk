import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/l10n_context.dart';
import '../../core/logging/app_logger.dart';
import '../providers/settings_provider.dart';

enum _LogTimeRange {
  oneMinute(Duration(minutes: 1), '1m'),
  fiveMinutes(Duration(minutes: 5), '5m'),
  fifteenMinutes(Duration(minutes: 15), '15m'),
  oneHour(Duration(hours: 1), '1h'),
  all(null, null);

  const _LogTimeRange(this.duration, this.label);

  final Duration? duration;
  final String? label;
}

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final TextEditingController _searchController = TextEditingController();
  _LogTimeRange _timeRange = _LogTimeRange.fifteenMinutes;
  Set<LogLevel> _levels = LogLevel.values.toSet();
  bool _searchEnabled = false;
  bool _performanceOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LogEntry> _filteredEntries({bool forcePerformance = false}) {
    return AppLogger.filteredEntries(
      timeRange: _timeRange.duration,
      levels: _levels,
      tags: _performanceOnly || forcePerformance
          ? const <String>{AppLogger.performanceTag}
          : null,
      query: _searchController.text,
    );
  }

  List<LogEntry> _slowestPerformanceEntries() {
    final entries = _filteredEntries(
      forcePerformance: true,
    ).where((entry) => entry.elapsedMs != null).toList(growable: false);
    entries.sort((a, b) => b.elapsedMs!.compareTo(a.elapsedMs!));
    return entries;
  }

  bool _hasPerformanceEntries() {
    return _filteredEntries(
      forcePerformance: true,
    ).any((entry) => entry.elapsedMs != null);
  }

  void _showSlowestPerformance(BuildContext context) {
    final entries = _slowestPerformanceEntries();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.logsSlowestPerformance,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (entries.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(context.l10n.logsNoPerformanceData),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: entries.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            final elapsedMs = entry.elapsedMs ?? 0;
                            final operation =
                                entry.performanceOperation ?? entry.message;
                            final status = entry.performanceStatus ?? 'ok';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(operation),
                              subtitle: Text(
                                '${entry.timestamp.toIso8601String()} • $status',
                              ),
                              trailing: Text(
                                context.l10n.logsPerformanceDuration(elapsedMs),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _copyLogs(BuildContext context, List<LogEntry> entries) async {
    final text = AppLogger.exportEntries(entries: entries);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.msgFilteredLogsCopied)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searchEnabled
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: context.l10n.logsSearch,
                ),
                onChanged: (_) => setState(() {}),
              )
            : Text(context.l10n.logsAppLogs),
        actions: [
          if (_searchEnabled)
            IconButton(
              icon: const Icon(Symbols.close),
              tooltip: context.l10n.logsCloseSearch,
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchEnabled = false;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Symbols.search),
              tooltip: context.l10n.logsSearch,
              onPressed: () {
                setState(() {
                  _searchEnabled = true;
                });
              },
            ),
          ValueListenableBuilder<UnmodifiableListView<LogEntry>>(
            valueListenable: AppLogger.entries,
            builder: (context, _, _) {
              final hasPerformanceData = _hasPerformanceEntries();
              return IconButton(
                icon: const Icon(Symbols.timer),
                tooltip: context.l10n.logsSlowestPerformance,
                onPressed: hasPerformanceData
                    ? () => _showSlowestPerformance(context)
                    : null,
              );
            },
          ),
          ValueListenableBuilder<UnmodifiableListView<LogEntry>>(
            valueListenable: AppLogger.entries,
            builder: (context, _, _) {
              final filtered = _filteredEntries();
              return IconButton(
                icon: const Icon(Symbols.copy_all),
                tooltip: context.l10n.logsCopyFiltered,
                onPressed: filtered.isEmpty
                    ? null
                    : () => _copyLogs(context, filtered),
              );
            },
          ),
          IconButton(
            icon: const Icon(Symbols.delete_outline),
            tooltip: context.l10n.logsClear,
            onPressed: AppLogger.clearEntries,
          ),
        ],
      ),
      body: ValueListenableBuilder<UnmodifiableListView<LogEntry>>(
        valueListenable: AppLogger.entries,
        builder: (context, entries, child) {
          final settingsProvider = context.watch<SettingsProvider>();
          final filtered = _filteredEntries();
          final ordered = filtered.reversed.toList(growable: false);

          return Column(
            children: [
              _LogsToolbar(
                selectedRange: _timeRange,
                selectedLevels: _levels,
                performanceLoggingEnabled:
                    settingsProvider.performanceLoggingEnabled,
                performanceFilterOnly: _performanceOnly,
                onRangeChanged: (value) {
                  setState(() {
                    _timeRange = value;
                  });
                },
                onLevelToggled: (level) {
                  setState(() {
                    if (_levels.contains(level)) {
                      if (_levels.length > 1) {
                        _levels = Set<LogLevel>.from(_levels)..remove(level);
                      }
                    } else {
                      _levels = Set<LogLevel>.from(_levels)..add(level);
                    }
                  });
                },
                onPerformanceLoggingChanged: (enabled) {
                  unawaited(
                    context
                        .read<SettingsProvider>()
                        .setPerformanceLoggingEnabled(enabled),
                  );
                },
                onPerformanceFilterToggled: () {
                  setState(() {
                    _performanceOnly = !_performanceOnly;
                  });
                },
              ),
              const Divider(height: 1),
              Expanded(
                child: ordered.isEmpty
                    ? Center(
                        child: Text(
                          entries.isEmpty
                              ? context.l10n.logsNoLogsYet
                              : context.l10n.logsNoMatchingLogs,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: ordered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return _LogTile(entry: ordered[index]);
                        },
                      ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: Text(
                  context.l10n.logsShowingOrderedLength(
                    ordered.length,
                    entries.length,
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LogsToolbar extends StatelessWidget {
  const _LogsToolbar({
    required this.selectedRange,
    required this.selectedLevels,
    required this.performanceLoggingEnabled,
    required this.performanceFilterOnly,
    required this.onRangeChanged,
    required this.onLevelToggled,
    required this.onPerformanceLoggingChanged,
    required this.onPerformanceFilterToggled,
  });

  final _LogTimeRange selectedRange;
  final Set<LogLevel> selectedLevels;
  final bool performanceLoggingEnabled;
  final bool performanceFilterOnly;
  final ValueChanged<_LogTimeRange> onRangeChanged;
  final ValueChanged<LogLevel> onLevelToggled;
  final ValueChanged<bool> onPerformanceLoggingChanged;
  final VoidCallback onPerformanceFilterToggled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.logsTimeRange,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _LogTimeRange.values
                .map(
                  (range) => ChoiceChip(
                    label: Text(range.label ?? context.l10n.logsFilterAll),
                    selected: selectedRange == range,
                    onSelected: (_) => onRangeChanged(range),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.logsLevel,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LogLevel.values
                .map(
                  (level) => FilterChip(
                    label: Text(level.name.toUpperCase()),
                    selected: selectedLevels.contains(level),
                    onSelected: (_) => onLevelToggled(level),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.l10n.logsMeasurePerformance),
            subtitle: Text(context.l10n.logsMeasurePerformanceDescription),
            value: performanceLoggingEnabled,
            onChanged: onPerformanceLoggingChanged,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: Text(context.l10n.logsPerformanceFilter),
                selected: performanceFilterOnly,
                onSelected: (_) => onPerformanceFilterToggled(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry});

  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (entry.level) {
      LogLevel.debug => colorScheme.secondary,
      LogLevel.info => colorScheme.primary,
      LogLevel.warn => Colors.orange.shade300,
      LogLevel.error => colorScheme.error,
    };

    final elapsedMs = entry.elapsedMs;
    final operation = entry.performanceOperation;
    final status = entry.performanceStatus;
    final title = entry.isPerformance
        ? context.l10n.logsPerformanceTileTitle(
            operation ?? entry.message,
            elapsedMs ?? 0,
            status ?? 'ok',
          )
        : entry.level.name.toUpperCase();

    final subtitle = StringBuffer(
      '${entry.timestamp.toIso8601String()}\n${entry.message}',
    );
    if (entry.tags.isNotEmpty) {
      final tags = entry.tags.toList(growable: false)..sort();
      subtitle.write('\n${context.l10n.logsEntryTags}: ${tags.join(', ')}');
    }
    final contextMetrics = entry.metrics?['context'];
    if (contextMetrics is Map && contextMetrics.isNotEmpty) {
      subtitle.write('\n${context.l10n.logsEntryContext}: $contextMetrics');
    }
    if (entry.error != null && entry.error!.isNotEmpty) {
      subtitle.write('\nError: ${entry.error}');
    }
    if (entry.stackTrace != null && entry.stackTrace!.isNotEmpty) {
      subtitle.write('\nStack: ${entry.stackTrace}');
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: ListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle.toString(),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
        ),
      ),
    );
  }
}
