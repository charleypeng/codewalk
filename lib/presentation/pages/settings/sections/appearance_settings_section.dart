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
        const densityOptions = <({AppDensity value, String label})>[
          (value: AppDensity.extraDense, label: 'Extra Dense'),
          (value: AppDensity.dense, label: 'Dense'),
          (value: AppDensity.normal, label: 'Normal'),
          (value: AppDensity.spacious, label: 'Spacious'),
          (value: AppDensity.extraSpacious, label: 'Extra Spacious'),
        ];
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
                    Wrap(
                      key: const ValueKey<String>(
                        'settings_density_choice_wrap',
                      ),
                      spacing: 8,
                      runSpacing: 8,
                      children: densityOptions
                          .map(
                            (option) => ChoiceChip(
                              key: ValueKey<String>(
                                'settings_density_choice_${option.value.name}',
                              ),
                              label: Text(option.label),
                              selected: selectedDensity == option.value,
                              onSelected: (_) => unawaited(
                                settingsProvider.setAppDensity(option.value),
                              ),
                            ),
                          )
                          .toList(growable: false),
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
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    key: const ValueKey<String>(
                      'settings_toggle_task_list',
                    ),
                    title: const Text('Task list'),
                    subtitle: const Text(
                      'Show or hide the session task list widget.',
                    ),
                    value: settingsProvider.showTaskList,
                    onChanged: (value) => unawaited(
                      settingsProvider.setShowTaskList(value),
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
