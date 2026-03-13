import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/settings_provider.dart';

class BehaviorSettingsSection extends StatefulWidget {
  const BehaviorSettingsSection({super.key});

  @override
  State<BehaviorSettingsSection> createState() =>
      _BehaviorSettingsSectionState();
}

class _BehaviorSettingsSectionState extends State<BehaviorSettingsSection> {
  bool _syncedServerDefaults = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_syncedServerDefaults) {
      return;
    }
    _syncedServerDefaults = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        context.read<SettingsProvider>().refreshOpenCodeBackedDefaults(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        return ListView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          children: [
            Text('Behavior', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Control shared OpenCode defaults and local composer sync behavior.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildOpenCodeDefaultsCard(context, settingsProvider),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    key: const ValueKey<String>(
                      'settings_toggle_experimental_multi_device_sync',
                    ),
                    title: const Text('Enable experimental multi-device sync'),
                    subtitle: const Text(
                      'Sync composer selection (agent/model/variant) with the active server config.',
                    ),
                    value: settingsProvider.enableExperimentalMultiDeviceSync,
                    onChanged: (value) => unawaited(
                      settingsProvider.setEnableExperimentalMultiDeviceSync(
                        value,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Can abort ongoing sessions when working in more than one session at the same time.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
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

  Widget _buildOpenCodeDefaultsCard(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    final modelOptions = settingsProvider.openCodeDefaultModelOptions;
    final agentOptions = settingsProvider.openCodeDefaultAgentOptions;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OpenCode-backed defaults',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'These values write to `/config` on the active server and match official OpenCode shared config.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh defaults',
                  onPressed: settingsProvider.openCodeDefaultsLoading
                      ? null
                      : () => unawaited(
                          settingsProvider.refreshOpenCodeBackedDefaults(),
                        ),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (settingsProvider.openCodeDefaultsLoading &&
                !settingsProvider.openCodeDefaultsLoaded)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (settingsProvider.openCodeDefaultsError != null) ...[
                Text(
                  settingsProvider.openCodeDefaultsError!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<String>(
                key: const ValueKey<String>('settings_opencode_default_model'),
                value: _selectedDropdownValue(
                  settingsProvider.openCodeDefaultModelKey,
                  modelOptions.map((option) => option.key),
                ),
                decoration: const InputDecoration(
                  labelText: 'Default model',
                  border: OutlineInputBorder(),
                  helperText: 'Shared across OpenCode clients through config.',
                ),
                isExpanded: true,
                items: modelOptions
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option.key,
                        child: Text(
                          option.label,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged:
                    modelOptions.isEmpty ||
                        settingsProvider.openCodeDefaultsLoading
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }
                        unawaited(_applyDefaultModel(context, value));
                      },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const ValueKey<String>('settings_opencode_default_agent'),
                value: _selectedDropdownValue(
                  settingsProvider.openCodeDefaultAgentName,
                  agentOptions,
                ),
                decoration: const InputDecoration(
                  labelText: 'Default agent',
                  border: OutlineInputBorder(),
                  helperText:
                      'Primary agent used when no agent is explicitly chosen.',
                ),
                isExpanded: true,
                items: agentOptions
                    .map(
                      (agentName) => DropdownMenuItem<String>(
                        value: agentName,
                        child: Text(agentName),
                      ),
                    )
                    .toList(growable: false),
                onChanged:
                    agentOptions.isEmpty ||
                        settingsProvider.openCodeDefaultsLoading
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }
                        unawaited(_applyDefaultAgent(context, value));
                      },
              ),
              const SizedBox(height: 12),
              Text(
                'Permissions and variant/reasoning parity stay separate until their UI can preserve advanced config safely.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _selectedDropdownValue(
    String? currentValue,
    Iterable<String> options,
  ) {
    if (currentValue == null) {
      return null;
    }
    for (final option in options) {
      if (option == currentValue) {
        return currentValue;
      }
    }
    return null;
  }

  Future<void> _applyDefaultModel(BuildContext context, String modelKey) async {
    final settingsProvider = context.read<SettingsProvider>();
    final updated = await settingsProvider.setOpenCodeDefaultModel(modelKey);
    if (!context.mounted) {
      return;
    }
    if (!updated) {
      _showFailureSnackBar(
        context,
        'Could not update the OpenCode default model.',
      );
      return;
    }
    await _refreshChatProviderIfAvailable(context);
  }

  Future<void> _applyDefaultAgent(
    BuildContext context,
    String agentName,
  ) async {
    final settingsProvider = context.read<SettingsProvider>();
    final updated = await settingsProvider.setOpenCodeDefaultAgent(agentName);
    if (!context.mounted) {
      return;
    }
    if (!updated) {
      _showFailureSnackBar(
        context,
        'Could not update the OpenCode default agent.',
      );
      return;
    }
    await _refreshChatProviderIfAvailable(context);
  }

  Future<void> _refreshChatProviderIfAvailable(BuildContext context) async {
    try {
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.initializeProviders();
    } on ProviderNotFoundException {
      // Settings tests can render this section without a ChatProvider.
    }
  }

  void _showFailureSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
