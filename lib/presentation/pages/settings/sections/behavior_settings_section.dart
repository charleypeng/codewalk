import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../providers/settings_provider.dart';

class BehaviorSettingsSection extends StatelessWidget {
  const BehaviorSettingsSection({super.key});

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
              'Control how composer selections sync across clients and sessions.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
                        'Can abort on-going sessions when working in more than one session at the same time.',
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
}
