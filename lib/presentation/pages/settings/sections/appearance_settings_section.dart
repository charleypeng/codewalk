import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/experience_settings.dart';
import '../../../providers/settings_provider.dart';

class AppearanceSettingsSection extends StatelessWidget {
  const AppearanceSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        final selectedDensity = settingsProvider.appDensity;
        return ListView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          children: [
            Text(
              'Appearance',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Tune visual density and message surfaces for your workflow.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Density',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Apply spacing and component density across the app.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<AppDensity>(
                      key: const ValueKey<String>('settings_density_segmented'),
                      segments: const <ButtonSegment<AppDensity>>[
                        ButtonSegment<AppDensity>(
                          value: AppDensity.dense,
                          label: Text('Dense'),
                        ),
                        ButtonSegment<AppDensity>(
                          value: AppDensity.normal,
                          label: Text('Normal'),
                        ),
                        ButtonSegment<AppDensity>(
                          value: AppDensity.spacious,
                          label: Text('Spacious'),
                        ),
                      ],
                      selected: <AppDensity>{selectedDensity},
                      onSelectionChanged: (selection) {
                        final next = selection.firstOrNull;
                        if (next == null) {
                          return;
                        }
                        unawaited(settingsProvider.setAppDensity(next));
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    key: const ValueKey<String>(
                      'settings_toggle_thinking_bubbles',
                    ),
                    title: const Text('Thinking bubbles'),
                    subtitle: const Text(
                      'Show or hide reasoning blocks in assistant messages.',
                    ),
                    value: settingsProvider.showThinkingBubbles,
                    onChanged: (value) => unawaited(
                      settingsProvider.setShowThinkingBubbles(value),
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    key: const ValueKey<String>(
                      'settings_toggle_tool_call_bubbles',
                    ),
                    title: const Text('Tool call bubbles'),
                    subtitle: const Text(
                      'Show or hide tool execution cards in assistant messages.',
                    ),
                    value: settingsProvider.showToolCallBubbles,
                    onChanged: (value) => unawaited(
                      settingsProvider.setShowToolCallBubbles(value),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
