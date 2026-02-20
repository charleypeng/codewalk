import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/experience_settings.dart';
import '../../../providers/settings_provider.dart';
import '../../../theme/brand_colors.dart';

String _contrastLabel(double level) {
  if (level <= -0.83) return 'Reduced';
  if (level <= -0.17) return 'Low';
  if (level <= 0.17) return 'Standard';
  if (level <= 0.58) return 'Medium';
  if (level <= 0.83) return 'Medium High';
  return 'High';
}

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
            // Theme mode card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose between light, dark, or system theme.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeModeOption>(
                        key: const ValueKey<String>(
                          'settings_theme_mode_segmented',
                        ),
                        segments: const <ButtonSegment<ThemeModeOption>>[
                          ButtonSegment<ThemeModeOption>(
                            value: ThemeModeOption.system,
                            label: Text('System'),
                            icon: Icon(Symbols.brightness_auto),
                          ),
                          ButtonSegment<ThemeModeOption>(
                            value: ThemeModeOption.light,
                            label: Text('Light'),
                            icon: Icon(Symbols.light_mode),
                          ),
                          ButtonSegment<ThemeModeOption>(
                            value: ThemeModeOption.dark,
                            label: Text('Dark'),
                            icon: Icon(Symbols.dark_mode),
                          ),
                        ],
                        selected: <ThemeModeOption>{settingsProvider.themeMode},
                        onSelectionChanged: (selected) => unawaited(
                          settingsProvider.setThemeMode(selected.first),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Color card
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dynamic color toggle — only on platforms that support it
                  if (settingsProvider.dynamicColorAvailable)
                    SwitchListTile.adaptive(
                      key: const ValueKey<String>(
                        'settings_toggle_dynamic_color',
                      ),
                      title: const Text('Use wallpaper colors'),
                      subtitle: const Text(
                        'Extract color scheme from your device wallpaper.',
                      ),
                      value: settingsProvider.useDynamicColor,
                      onChanged: (value) => unawaited(
                        settingsProvider.setUseDynamicColor(value),
                      ),
                    ),
                  if (settingsProvider.dynamicColorAvailable) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Brand color',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          settingsProvider.useDynamicColor &&
                                  settingsProvider.dynamicColorAvailable
                              ? 'Disable wallpaper colors to pick a brand color.'
                              : 'Pick a seed color for the app palette.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          key: const ValueKey<String>(
                            'settings_brand_color_wrap',
                          ),
                          spacing: 10,
                          runSpacing: 10,
                          children: BrandColor.values.map((brand) {
                            final isSelected =
                                settingsProvider.customColorSeed == brand.value;
                            final isDisabled =
                                settingsProvider.useDynamicColor &&
                                settingsProvider.dynamicColorAvailable;
                            return Tooltip(
                              message: brand.label,
                              child: ChoiceChip(
                                key: ValueKey<String>(
                                  'settings_brand_color_${brand.name}',
                                ),
                                label: const SizedBox.shrink(),
                                selected: isSelected,
                                onSelected: isDisabled
                                    ? null
                                    : (_) => unawaited(
                                          settingsProvider.setCustomColorSeed(
                                            isSelected ? null : brand.value,
                                          ),
                                        ),
                                avatar: CircleAvatar(
                                  backgroundColor: brand.seed,
                                ),
                                showCheckmark: isSelected,
                                labelPadding: EdgeInsets.zero,
                                padding: const EdgeInsets.all(4),
                              ),
                            );
                          }).toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Contrast card — disabled when dynamic color is active because
            // contrastLevel only applies to ColorScheme.fromSeed, not to the
            // platform-provided dynamic scheme.
            Builder(
              builder: (context) {
                final isDynamicActive =
                    settingsProvider.useDynamicColor &&
                    settingsProvider.dynamicColorAvailable;
                return Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contrast',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isDynamicActive
                              ? 'Disable wallpaper colors to adjust contrast.'
                              : 'Adjust the contrast level of the color scheme.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Reduced'),
                            Expanded(
                              child: Slider(
                                key: const ValueKey<String>(
                                  'settings_contrast_slider',
                                ),
                                value: settingsProvider.contrastLevel,
                                min: -1.0,
                                max: 1.0,
                                divisions: 6,
                                label: _contrastLabel(
                                  settingsProvider.contrastLevel,
                                ),
                                onChanged: isDynamicActive
                                    ? null
                                    : (value) => unawaited(
                                          settingsProvider
                                              .setContrastLevel(value),
                                        ),
                              ),
                            ),
                            const Text('High'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // Density card
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
