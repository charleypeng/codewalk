import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/experience_settings.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/notification_sound_source_service.dart';
import '../../../services/notification_sound_source_service_types.dart';

class NotificationsSettingsSection extends StatefulWidget {
  const NotificationsSettingsSection({super.key});

  @override
  State<NotificationsSettingsSection> createState() =>
      _NotificationsSettingsSectionState();
}

class _NotificationsSettingsSectionState
    extends State<NotificationsSettingsSection> {
  static const int _mobileBackgroundHoldMinutes = 3;

  final NotificationSoundSourceService _soundSourceService =
      createNotificationSoundSourceService();
  bool _synced = false;

  bool get _isDesktopPlatform {
    if (kIsWeb) {
      return false;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      _ => false,
    };
  }

  bool get _isMobilePlatform {
    if (kIsWeb) {
      return false;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_synced) {
      return;
    }
    _synced = true;
    unawaited(
      context.read<SettingsProvider>().syncNotificationsFromServerConfig(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        return ListView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          children: [
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Control when alerts appear and when they can play sound.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildSyncInfoCard(settingsProvider),
            const SizedBox(height: 16),
            _buildCategoryCard(
              context: context,
              settingsProvider: settingsProvider,
              category: NotificationCategory.agent,
              title: 'Agent updates',
              subtitle: 'When a response finishes',
              icon: Icons.smart_toy_outlined,
            ),
            const SizedBox(height: 12),
            _buildCategoryCard(
              context: context,
              settingsProvider: settingsProvider,
              category: NotificationCategory.permissions,
              title: 'Permissions and questions',
              subtitle: 'When tools request your input',
              icon: Icons.rule_folder_outlined,
            ),
            const SizedBox(height: 12),
            _buildCategoryCard(
              context: context,
              settingsProvider: settingsProvider,
              category: NotificationCategory.errors,
              title: 'Errors',
              subtitle: 'When a session reports a failure',
              icon: Icons.error_outline,
            ),
            if (_isDesktopPlatform || _isMobilePlatform) ...[
              const SizedBox(height: 16),
              _buildBackgroundBehaviorCard(settingsProvider),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSyncInfoCard(SettingsProvider settingsProvider) {
    final text = settingsProvider.hasAnyServerBackedNotificationCategory
        ? 'Some category on/off toggles are synced from /config on the active server.'
        : 'Current server does not expose notification toggles in /config; local values are active.';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundBehaviorCard(SettingsProvider settingsProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Background behavior',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Choose how CodeWalk behaves after the app leaves the foreground.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_isDesktopPlatform) ...[
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Close to tray'),
                subtitle: const Text(
                  'Hide to system tray on window close and keep realtime updates active.',
                ),
                value: settingsProvider.keepDesktopRunningInTray,
                onChanged: (value) =>
                    settingsProvider.setKeepDesktopRunningInTray(value),
              ),
            ],
            if (_isMobilePlatform) ...[
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Keep alerts live for $_mobileBackgroundHoldMinutes min',
                ),
                subtitle: const Text(
                  'When a response is running, keep realtime active briefly after you leave the app.',
                ),
                value: settingsProvider.keepMobileRealtimeForShortPeriod,
                onChanged: (value) =>
                    settingsProvider.setKeepMobileRealtimeForShortPeriod(value),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required SettingsProvider settingsProvider,
    required NotificationCategory category,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final notifyEnabled = settingsProvider.isNotificationEnabled(category);
    final soundCategory = settingsProvider.soundCategoryForNotification(
      category,
    );
    final soundEnabled = settingsProvider.isSoundEnabledForNotification(
      category,
    );
    final soundOption = settingsProvider.soundFor(soundCategory);
    final soundLabel = settingsProvider.soundLabelFor(soundCategory);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _buildOriginBadge(
                  serverBacked: settingsProvider.isServerBackedNotification(
                    category,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPrimaryToggles(
              settingsProvider: settingsProvider,
              category: category,
            ),
            if (notifyEnabled) ...[
              const SizedBox(height: 10),
              _buildOnlyWhenChips(
                title: 'Notify only when',
                backgroundEnabled: settingsProvider.notifyOnlyWhenBackground(
                  category,
                ),
                anotherSessionEnabled: settingsProvider
                    .notifyOnlyWhenAnotherSession(category),
                onBackgroundChanged: (value) => settingsProvider
                    .setNotifyOnlyWhenBackground(category, value),
                onAnotherSessionChanged: (value) => settingsProvider
                    .setNotifyOnlyWhenAnotherSession(category, value),
              ),
            ],
            if (soundEnabled) ...[
              const SizedBox(height: 10),
              _buildOnlyWhenChips(
                title: 'Sound only when',
                backgroundEnabled: settingsProvider.soundOnlyWhenBackground(
                  category,
                ),
                anotherSessionEnabled: settingsProvider
                    .soundOnlyWhenAnotherSession(category),
                onBackgroundChanged: (value) => settingsProvider
                    .setSoundOnlyWhenBackground(category, value),
                onAnotherSessionChanged: (value) => settingsProvider
                    .setSoundOnlyWhenAnotherSession(category, value),
              ),
              const SizedBox(height: 10),
              _buildSoundTypeSelector(
                settingsProvider: settingsProvider,
                category: category,
                soundCategory: soundCategory,
                selected: soundOption,
              ),
              if (soundLabel != null && soundLabel.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Selected: $soundLabel',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (soundOption == SoundOption.systemChoice)
                    OutlinedButton.icon(
                      onPressed: () => unawaited(
                        _pickSystemSound(
                          settingsProvider: settingsProvider,
                          soundCategory: soundCategory,
                        ),
                      ),
                      icon: const Icon(Icons.tune),
                      label: const Text('Choose system sound'),
                    ),
                  if (soundOption == SoundOption.customFile)
                    OutlinedButton.icon(
                      onPressed: () => unawaited(
                        _pickCustomFile(
                          settingsProvider: settingsProvider,
                          soundCategory: soundCategory,
                        ),
                      ),
                      icon: const Icon(Icons.library_music_outlined),
                      label: const Text('Choose audio file'),
                    ),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        settingsProvider.previewSound(soundCategory),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Preview'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOriginBadge({required bool serverBacked}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: serverBacked
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        serverBacked ? 'Server' : 'Local',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }

  Widget _buildPrimaryToggles({
    required SettingsProvider settingsProvider,
    required NotificationCategory category,
  }) {
    return Row(
      children: [
        Expanded(
          child: SwitchListTile.adaptive(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Notify'),
            value: settingsProvider.isNotificationEnabled(category),
            onChanged: (value) =>
                settingsProvider.setNotificationEnabled(category, value),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SwitchListTile.adaptive(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Sound'),
            value: settingsProvider.isSoundEnabledForNotification(category),
            onChanged: (value) => settingsProvider
                .setSoundEnabledForNotification(category, value),
          ),
        ),
      ],
    );
  }

  Widget _buildOnlyWhenChips({
    required String title,
    required bool backgroundEnabled,
    required bool anotherSessionEnabled,
    required ValueChanged<bool> onBackgroundChanged,
    required ValueChanged<bool> onAnotherSessionChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('App in background'),
              selected: backgroundEnabled,
              onSelected: onBackgroundChanged,
            ),
            FilterChip(
              label: const Text('Another conversation'),
              selected: anotherSessionEnabled,
              onSelected: onAnotherSessionChanged,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'If no condition is selected, alerts are allowed in any context.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSoundTypeSelector({
    required SettingsProvider settingsProvider,
    required NotificationCategory category,
    required SoundCategory soundCategory,
    required SoundOption selected,
  }) {
    return DropdownButtonFormField<SoundOption>(
      initialValue: selected,
      items: _soundOptions
          .map(
            (option) => DropdownMenuItem<SoundOption>(
              value: option,
              child: Text(_soundLabel(option)),
            ),
          )
          .toList(growable: false),
      onChanged: (value) {
        if (value == null) {
          return;
        }
        unawaited(
          _handleSoundOptionChanged(
            settingsProvider: settingsProvider,
            category: category,
            soundCategory: soundCategory,
            option: value,
          ),
        );
      },
      decoration: const InputDecoration(
        labelText: 'Sound type',
        border: OutlineInputBorder(),
      ),
    );
  }

  Future<void> _handleSoundOptionChanged({
    required SettingsProvider settingsProvider,
    required NotificationCategory category,
    required SoundCategory soundCategory,
    required SoundOption option,
  }) async {
    if (option == SoundOption.systemChoice) {
      final selected = await _showSystemSoundPicker();
      if (selected == null) {
        return;
      }
      await settingsProvider.setSoundOption(
        soundCategory,
        option,
        source: selected.source,
        label: selected.label,
      );
      return;
    }

    if (option == SoundOption.customFile) {
      final file = await _soundSourceService.pickAndRegisterCustomFile();
      if (file == null) {
        return;
      }
      await settingsProvider.setSoundOption(
        soundCategory,
        option,
        source: file.source,
        label: file.label,
      );
      return;
    }

    await settingsProvider.setSoundOption(soundCategory, option);

    if (!settingsProvider.isSoundEnabledForNotification(category)) {
      await settingsProvider.setSoundEnabledForNotification(category, true);
    }
  }

  Future<void> _pickSystemSound({
    required SettingsProvider settingsProvider,
    required SoundCategory soundCategory,
  }) async {
    final selected = await _showSystemSoundPicker();
    if (selected == null) {
      return;
    }
    await settingsProvider.setSoundOption(
      soundCategory,
      SoundOption.systemChoice,
      source: selected.source,
      label: selected.label,
    );
  }

  Future<void> _pickCustomFile({
    required SettingsProvider settingsProvider,
    required SoundCategory soundCategory,
  }) async {
    final file = await _soundSourceService.pickAndRegisterCustomFile();
    if (file == null) {
      return;
    }
    await settingsProvider.setSoundOption(
      soundCategory,
      SoundOption.customFile,
      source: file.source,
      label: file.label,
    );
  }

  Future<SystemSoundChoice?> _showSystemSoundPicker() async {
    if (!_soundSourceService.supportsSystemSoundPicker) {
      _showSnackBar('System sound picker is not available on this platform.');
      return null;
    }

    final sounds = await _soundSourceService.listSystemSounds();
    if (!mounted) {
      return null;
    }
    if (sounds.isEmpty) {
      _showSnackBar('No system sound was found on this device.');
      return null;
    }

    return showModalBottomSheet<SystemSoundChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose system sound',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _systemPickerHint(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: sounds.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = sounds[index];
                    return ListTile(
                      title: Text(item.label),
                      onTap: () => Navigator.of(context).pop(item),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _systemPickerHint() {
    if (kIsWeb) {
      return 'Not available on web.';
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android notification sounds from the system.',
      TargetPlatform.linux =>
        'Freedesktop sounds from /usr/share/sounds/freedesktop/stereo.',
      _ => 'Supported where the operating system exposes system sounds.',
    };
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  static const List<SoundOption> _soundOptions = <SoundOption>[
    SoundOption.systemDefault,
    SoundOption.systemChoice,
    SoundOption.customFile,
    SoundOption.click,
    SoundOption.alert,
  ];

  String _soundLabel(SoundOption option) {
    return switch (option) {
      SoundOption.off => 'Off',
      SoundOption.systemDefault => 'System default',
      SoundOption.systemChoice => 'Pick from system',
      SoundOption.customFile => 'Pick audio file',
      SoundOption.click => 'Built-in click',
      SoundOption.alert => 'Built-in alert',
    };
  }
}
