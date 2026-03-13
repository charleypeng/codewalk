import 'package:flutter/material.dart';

enum SettingsProvenance { opencodeBacked, codewalkLocal, codewalkException }

class SettingsProvenanceChip extends StatelessWidget {
  const SettingsProvenanceChip({super.key, required this.provenance});

  final SettingsProvenance provenance;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, backgroundColor, foregroundColor) = switch (provenance) {
      SettingsProvenance.opencodeBacked => (
        'OpenCode-backed',
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
      SettingsProvenance.codewalkLocal => (
        'CodeWalk-local',
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
      SettingsProvenance.codewalkException => (
        'CodeWalk exception',
        colorScheme.tertiaryContainer,
        colorScheme.onTertiaryContainer,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
