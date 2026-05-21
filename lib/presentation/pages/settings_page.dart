import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/i18n/l10n_context.dart';
import '../providers/settings_provider.dart';
import '../theme/app_animations.dart';
import '../utils/app_page_route.dart';
import '../utils/window_size_class.dart';
import 'logs_page.dart';
import 'onboarding_wizard_page.dart';
import 'settings/sections/about_settings_section.dart';
import 'settings/sections/appearance_settings_section.dart';
import 'settings/sections/behavior_settings_section.dart';
import 'settings/sections/notifications_settings_section.dart';
import 'settings/sections/servers_settings_section.dart';
import 'settings/sections/shortcuts_settings_section.dart';
import 'settings/sections/speech_settings_section.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.initialSectionId = ''});

  final String initialSectionId;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsSection {
  const _SettingsSection({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.builder,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final WidgetBuilder builder;
}

class _SettingsPageState extends State<SettingsPage> {
  // Split layout when expanded or wider (840dp+)
  static const Duration _doubleEscapeCloseThreshold = Duration(
    milliseconds: 500,
  );

  DateTime? _lastEscapeAt;
  bool _hasPhysicalKeyboard = false;

  _SettingsSection _section({
    required String id,
    required String title,
    required String description,
    required IconData icon,
    required WidgetBuilder builder,
  }) {
    return _SettingsSection(
      id: id,
      title: title,
      description: description,
      icon: icon,
      builder: builder,
    );
  }

  List<_SettingsSection> get _sections => <_SettingsSection>[
    _section(
      id: 'servers',
      title: context.l10n.settingsServersTitle,
      description: context.l10n.settingsServersDescription,
      icon: Symbols.dns,
      builder: (_) => const ServersSettingsSection(),
    ),
    _section(
      id: 'appearance',
      title: context.l10n.settingsAppearanceTitle,
      description: context.l10n.settingsAppearanceDescription,
      icon: Symbols.tune_rounded,
      builder: (_) => const AppearanceSettingsSection(),
    ),
    _section(
      id: 'behavior',
      title: context.l10n.settingsBehaviorTitle,
      description: context.l10n.settingsBehaviorDescription,
      icon: Symbols.settings,
      builder: (_) => const BehaviorSettingsSection(),
    ),
    _section(
      id: 'notifications',
      title: context.l10n.settingsNotificationsTitle,
      description: context.l10n.settingsNotificationsDescription,
      icon: Symbols.notifications_active,
      builder: (_) => const NotificationsSettingsSection(),
    ),
    _section(
      id: 'speech',
      title: context.l10n.settingsSpeechTitle,
      description: context.l10n.settingsSpeechDescription,
      icon: Symbols.mic_none_rounded,
      builder: (_) => const SpeechSettingsSection(),
    ),
    _section(
      id: 'logs',
      title: context.l10n.settingsLogsTitle,
      description: context.l10n.settingsLogsDescription,
      icon: Symbols.receipt_long_rounded,
      builder: (_) => const SizedBox.shrink(),
    ),
    _section(
      id: 'shortcuts',
      title: context.l10n.settingsShortcutsTitle,
      description: context.l10n.settingsShortcutsDescription,
      icon: Symbols.keyboard_command_key_rounded,
      builder: (_) => const ShortcutsSettingsSection(),
    ),
    _section(
      id: 'about',
      title: context.l10n.settingsAboutTitle,
      description: context.l10n.settingsAboutDescription,
      icon: Symbols.info,
      builder: (_) => const AboutSettingsSection(),
    ),
  ];

  bool get _supportsShortcutsSection {
    if (kIsWeb) {
      return true;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      _ => _hasPhysicalKeyboard,
    };
  }

  List<_SettingsSection> get _visibleSections {
    if (_supportsShortcutsSection) {
      return _sections;
    }
    return _sections
        .where((section) => section.id != 'shortcuts')
        .toList(growable: false);
  }

  String? _selectedSectionId;
  bool _showMobileDetail = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
    final initialSectionId = widget.initialSectionId == 'logs'
        ? ''
        : widget.initialSectionId;
    // Section labels depend on Localizations, so the localized section list is
    // resolved during build instead of during initState.
    _selectedSectionId = initialSectionId.isEmpty ? 'servers' : initialSectionId;
    _showMobileDetail = initialSectionId.isNotEmpty;
    if (widget.initialSectionId == 'logs') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _openLogsPage();
      });
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    super.dispose();
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (!mounted) {
      return false;
    }
    if (!_hasPhysicalKeyboard && event is KeyDownEvent) {
      setState(() {
        _hasPhysicalKeyboard = true;
      });
    }
    if (event is! KeyDownEvent) {
      return false;
    }
    if (event.logicalKey != LogicalKeyboardKey.escape) {
      return false;
    }
    if (HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isAltPressed ||
        HardwareKeyboard.instance.isShiftPressed) {
      return false;
    }

    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) {
      return false;
    }

    final now = DateTime.now();
    final shouldClose =
        _lastEscapeAt != null &&
        now.difference(_lastEscapeAt!) <= _doubleEscapeCloseThreshold;
    _lastEscapeAt = now;
    if (!shouldClose) {
      return true;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final visibleSections = _visibleSections;
    if (!visibleSections.any((item) => item.id == _selectedSectionId)) {
      _selectedSectionId = visibleSections.first.id;
    }
    final section = visibleSections
        .where((item) => item.id == _selectedSectionId)
        .firstOrNull;
    final sizeClass = context.windowSizeClass;
    final isSplit = sizeClass.isAtLeastExpanded;

    if (!isSplit) {
      return PopScope(
        canPop: !_showMobileDetail,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop || !_showMobileDetail) {
            return;
          }
          setState(() {
            _showMobileDetail = false;
          });
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              _showMobileDetail ? (section?.title ?? 'Settings') : 'Settings',
            ),
            leading: _showMobileDetail
                ? IconButton(
                    tooltip: context.l10n.permissionBack,
                    onPressed: () {
                      setState(() {
                        _showMobileDetail = false;
                      });
                    },
                    icon: const Icon(Symbols.arrow_back),
                  )
                : null,
          ),
          body: AnimatedSwitcher(
            duration: AppAnimations.emphasized,
            switchInCurve: AppAnimations.emphasizedCurve,
            switchOutCurve: AppAnimations.accelerateCurve,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _showMobileDetail && section != null
                ? KeyedSubtree(
                    key: ValueKey<String>('section_${section.id}'),
                    child: section.builder(context),
                  )
                : KeyedSubtree(
                    key: const ValueKey<String>('section_list'),
                    child: _buildSectionList(isSplit: false),
                  ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Row(
        children: [
          SizedBox(width: 320, child: _buildSectionList(isSplit: true)),
          const VerticalDivider(width: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppAnimations.emphasized,
              switchInCurve: AppAnimations.emphasizedCurve,
              switchOutCurve: AppAnimations.accelerateCurve,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: section == null
                  ? const SizedBox.shrink(
                      key: ValueKey<String>('section_empty'),
                    )
                  : KeyedSubtree(
                      key: ValueKey<String>('section_${section.id}'),
                      child: section.builder(context),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSetupWizard() async {
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => OnboardingWizardPage(
          showSkipAction: false,
          onComplete: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _openLogsPage() async {
    await Navigator.of(
      context,
    ).push(AppPageRoute(builder: (_) => const LogsPage()));
  }

  Future<void> _replayChatTour() async {
    final settingsProvider = context.read<SettingsProvider>();
    if (settingsProvider.pendingPostOnboardingChatTour) {
      await settingsProvider.setPendingPostOnboardingChatTour(false);
    }
    await settingsProvider.setPendingPostOnboardingChatTour(true);
    if (!mounted) {
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Widget _buildSectionList({required bool isSplit}) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      children: [
        FilledButton.icon(
          onPressed: _openSetupWizard,
          icon: const Icon(Symbols.auto_fix_high_rounded),
          label: Text(context.l10n.settingsSetupWizard),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: const ValueKey<String>('settings_replay_chat_tour_button'),
          onPressed: () => unawaited(_replayChatTour()),
          icon: const Icon(Symbols.play_circle_rounded),
          label: Text(context.l10n.settingsAboutReplayChatTour),
        ),
        const SizedBox(height: 12),
        ..._visibleSections.map((section) {
          final selected = section.id == _selectedSectionId;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              selected: selected,
              leading: Icon(section.icon),
              title: Text(section.title),
              subtitle: Text(section.description),
              trailing: const Icon(Symbols.chevron_right),
              onTap: () {
                if (section.id == 'logs') {
                  _openLogsPage();
                  return;
                }
                setState(() {
                  _selectedSectionId = section.id;
                  _showMobileDetail = true;
                });
              },
            ),
          );
        }),
      ],
    );
  }
}
