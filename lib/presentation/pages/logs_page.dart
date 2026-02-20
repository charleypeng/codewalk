import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/services.dart';

import '../../core/logging/app_logger.dart';

enum _LogTimeRange {
  oneMinute(Duration(minutes: 1), '1m'),
  fiveMinutes(Duration(minutes: 5), '5m'),
  fifteenMinutes(Duration(minutes: 15), '15m'),
  oneHour(Duration(hours: 1), '1h'),
  all(null, 'All');

  const _LogTimeRange(this.duration, this.label);

  final Duration? duration;
  final String label;
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LogEntry> _filteredEntries() {
    return AppLogger.filteredEntries(
      timeRange: _timeRange.duration,
      levels: _levels,
      query: _searchController.text,
    );
  }

  Future<void> _copyLogs(BuildContext context, List<LogEntry> entries) async {
    final text = AppLogger.exportEntries(entries: entries);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filtered logs copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searchEnabled
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search logs',
                ),
                onChanged: (_) => setState(() {}),
              )
            : const Text('App Logs'),
        actions: [
          if (_searchEnabled)
            IconButton(
              icon: const Icon(Symbols.close),
              tooltip: 'Close search',
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
              tooltip: 'Search logs',
              onPressed: () {
                setState(() {
                  _searchEnabled = true;
                });
              },
            ),
          ValueListenableBuilder<UnmodifiableListView<LogEntry>>(
            valueListenable: AppLogger.entries,
            builder: (context, _, __) {
              final filtered = _filteredEntries();
              return IconButton(
                icon: const Icon(Symbols.copy_all),
                tooltip: 'Copy filtered logs',
                onPressed: filtered.isEmpty
                    ? null
                    : () => _copyLogs(context, filtered),
              );
            },
          ),
          IconButton(
            icon: const Icon(Symbols.delete_outline),
            tooltip: 'Clear logs',
            onPressed: AppLogger.clearEntries,
          ),
        ],
      ),
      body: ValueListenableBuilder<UnmodifiableListView<LogEntry>>(
        valueListenable: AppLogger.entries,
        builder: (context, entries, child) {
          final filtered = _filteredEntries();
          final ordered = filtered.reversed.toList(growable: false);

          return Column(
            children: [
              _LogsToolbar(
                selectedRange: _timeRange,
                selectedLevels: _levels,
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
              ),
              const Divider(height: 1),
              Expanded(
                child: ordered.isEmpty
                    ? Center(
                        child: Text(
                          entries.isEmpty
                              ? 'No logs captured yet.'
                              : 'No logs match the current filters.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: ordered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                  'Showing ${ordered.length} of ${entries.length} entries',
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
    required this.onRangeChanged,
    required this.onLevelToggled,
  });

  final _LogTimeRange selectedRange;
  final Set<LogLevel> selectedLevels;
  final ValueChanged<_LogTimeRange> onRangeChanged;
  final ValueChanged<LogLevel> onLevelToggled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Time range', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _LogTimeRange.values
                .map(
                  (range) => ChoiceChip(
                    label: Text(range.label),
                    selected: selectedRange == range,
                    onSelected: (_) => onRangeChanged(range),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          Text('Level', style: Theme.of(context).textTheme.labelLarge),
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

    final subtitle = StringBuffer(
      '${entry.timestamp.toIso8601String()}\n${entry.message}',
    );
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
          entry.level.name.toUpperCase(),
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
