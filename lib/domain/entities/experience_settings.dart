import 'package:flutter/foundation.dart';

enum NotificationCategory { agent, permissions, errors }

enum SoundCategory { agent, permissions, errors }

enum SoundOption { off, click, alert, systemDefault, systemChoice, customFile }

enum ShortcutAction {
  newChat,
  refresh,
  focusInput,
  toggleVoiceInput,
  quickOpen,
  openSettings,
  cycleRecentModels,
  cycleVariant,
  escape,
  cycleAgentForward,
  cycleAgentBackward,
  closeApp,
  quitApp,
}

enum DesktopPane { conversations, files, utility }

enum AppDensity { extraDense, dense, normal, spacious, extraSpacious }

enum ThemeModeOption { system, light, dark }

enum SpeechToTextEngine { native, sherpa }

enum DesktopCloseBehavior { tray, minimize, close }

const String kSherpaLanguageSystem = 'system';

class ShortcutDefinition {
  const ShortcutDefinition({
    required this.action,
    required this.group,
    required this.label,
    required this.description,
    required this.defaultBinding,
  });

  final ShortcutAction action;
  final String group;
  final String label;
  final String description;
  final String defaultBinding;
}

const List<ShortcutDefinition> kShortcutDefinitions = <ShortcutDefinition>[
  ShortcutDefinition(
    action: ShortcutAction.newChat,
    group: 'Session',
    label: 'New conversation',
    description: 'Create a new chat session',
    defaultBinding: 'mod+n',
  ),
  ShortcutDefinition(
    action: ShortcutAction.refresh,
    group: 'General',
    label: 'Refresh data',
    description: 'Refresh current chat data',
    defaultBinding: 'mod+r',
  ),
  ShortcutDefinition(
    action: ShortcutAction.focusInput,
    group: 'Prompt',
    label: 'Focus input',
    description: 'Move focus to the prompt input',
    defaultBinding: 'mod+l',
  ),
  ShortcutDefinition(
    action: ShortcutAction.toggleVoiceInput,
    group: 'Prompt',
    label: 'Toggle voice input',
    description: 'Start or stop speech-to-text in the composer',
    defaultBinding: 'alt+s',
  ),
  ShortcutDefinition(
    action: ShortcutAction.quickOpen,
    group: 'Navigation',
    label: 'Quick open files',
    description: 'Open file quick search',
    defaultBinding: 'mod+p',
  ),
  ShortcutDefinition(
    action: ShortcutAction.openSettings,
    group: 'Navigation',
    label: 'Open settings',
    description: 'Open settings page',
    defaultBinding: 'mod+,',
  ),
  ShortcutDefinition(
    action: ShortcutAction.cycleRecentModels,
    group: 'Model and agent',
    label: 'Next recent model',
    description: 'Cycle through recently used models',
    defaultBinding: 'mod+m',
  ),
  ShortcutDefinition(
    action: ShortcutAction.cycleVariant,
    group: 'Model and agent',
    label: 'Next variant',
    description: 'Cycle through available model variants',
    defaultBinding: 'mod+t',
  ),
  ShortcutDefinition(
    action: ShortcutAction.escape,
    group: 'Navigation',
    label: 'Focus/close drawer',
    description: 'Focus composer by default, or close drawer when open',
    defaultBinding: 'escape',
  ),
  ShortcutDefinition(
    action: ShortcutAction.cycleAgentForward,
    group: 'Model and agent',
    label: 'Next agent',
    description: 'Cycle to next available agent',
    defaultBinding: 'mod+j',
  ),
  ShortcutDefinition(
    action: ShortcutAction.cycleAgentBackward,
    group: 'Model and agent',
    label: 'Previous agent',
    description: 'Cycle to previous available agent',
    defaultBinding: 'mod+shift+j',
  ),
  ShortcutDefinition(
    action: ShortcutAction.closeApp,
    group: 'Application',
    label: 'Close application',
    description: 'Soft-close the app using platform close behavior',
    defaultBinding: 'mod+w',
  ),
  ShortcutDefinition(
    action: ShortcutAction.quitApp,
    group: 'Application',
    label: 'Quit application',
    description: 'Force-exit the app (bypass soft-close behavior)',
    defaultBinding: 'mod+q',
  ),
];

bool shortcutActionSupportedInRuntime(
  ShortcutAction action, {
  required bool isWeb,
  required TargetPlatform targetPlatform,
  required bool refreshlessRealtimeEnabled,
}) {
  if (isWeb) {
    return switch (action) {
      ShortcutAction.closeApp || ShortcutAction.quitApp => false,
      ShortcutAction.refresh => !refreshlessRealtimeEnabled,
      _ => true,
    };
  }

  return switch (action) {
    ShortcutAction.refresh => !refreshlessRealtimeEnabled,
    ShortcutAction.closeApp ||
    ShortcutAction.quitApp => switch (targetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      _ => false,
    },
    _ => true,
  };
}

List<ShortcutAction> shortcutActionsForRuntime({
  required bool isWeb,
  required TargetPlatform targetPlatform,
  required bool refreshlessRealtimeEnabled,
}) {
  return kShortcutDefinitions
      .where(
        (definition) => shortcutActionSupportedInRuntime(
          definition.action,
          isWeb: isWeb,
          targetPlatform: targetPlatform,
          refreshlessRealtimeEnabled: refreshlessRealtimeEnabled,
        ),
      )
      .map((definition) => definition.action)
      .toList(growable: false);
}

List<ShortcutDefinition> shortcutDefinitionsForRuntime({
  required bool isWeb,
  required TargetPlatform targetPlatform,
  required bool refreshlessRealtimeEnabled,
}) {
  final visibleActions = shortcutActionsForRuntime(
    isWeb: isWeb,
    targetPlatform: targetPlatform,
    refreshlessRealtimeEnabled: refreshlessRealtimeEnabled,
  ).toSet();
  return kShortcutDefinitions
      .where((definition) => visibleActions.contains(definition.action))
      .toList(growable: false);
}

String notificationCategoryKey(NotificationCategory category) {
  return switch (category) {
    NotificationCategory.agent => 'agent',
    NotificationCategory.permissions => 'permissions',
    NotificationCategory.errors => 'errors',
  };
}

NotificationCategory? notificationCategoryFromKey(String value) {
  return switch (value) {
    'agent' => NotificationCategory.agent,
    'permissions' => NotificationCategory.permissions,
    'errors' => NotificationCategory.errors,
    _ => null,
  };
}

String soundCategoryKey(SoundCategory category) {
  return switch (category) {
    SoundCategory.agent => 'agent',
    SoundCategory.permissions => 'permissions',
    SoundCategory.errors => 'errors',
  };
}

SoundCategory? soundCategoryFromKey(String value) {
  return switch (value) {
    'agent' => SoundCategory.agent,
    'permissions' => SoundCategory.permissions,
    'errors' => SoundCategory.errors,
    _ => null,
  };
}

String soundOptionKey(SoundOption option) {
  return switch (option) {
    SoundOption.off => 'off',
    SoundOption.click => 'click',
    SoundOption.alert => 'alert',
    SoundOption.systemDefault => 'system_default',
    SoundOption.systemChoice => 'system_choice',
    SoundOption.customFile => 'custom_file',
  };
}

SoundOption soundOptionFromKey(String value) {
  return switch (value) {
    'click' => SoundOption.click,
    'alert' => SoundOption.alert,
    'system_default' => SoundOption.systemDefault,
    'system_choice' => SoundOption.systemChoice,
    'custom_file' => SoundOption.customFile,
    _ => SoundOption.off,
  };
}

String shortcutActionKey(ShortcutAction action) {
  return switch (action) {
    ShortcutAction.newChat => 'new_chat',
    ShortcutAction.refresh => 'refresh',
    ShortcutAction.focusInput => 'focus_input',
    ShortcutAction.toggleVoiceInput => 'toggle_voice_input',
    ShortcutAction.quickOpen => 'quick_open',
    ShortcutAction.openSettings => 'open_settings',
    ShortcutAction.cycleRecentModels => 'cycle_recent_models',
    ShortcutAction.cycleVariant => 'cycle_variant',
    ShortcutAction.escape => 'escape',
    ShortcutAction.cycleAgentForward => 'cycle_agent_forward',
    ShortcutAction.cycleAgentBackward => 'cycle_agent_backward',
    ShortcutAction.closeApp => 'close_app',
    ShortcutAction.quitApp => 'quit_app',
  };
}

ShortcutAction? shortcutActionFromKey(String value) {
  return switch (value) {
    'new_chat' => ShortcutAction.newChat,
    'refresh' => ShortcutAction.refresh,
    'focus_input' => ShortcutAction.focusInput,
    'toggle_voice_input' => ShortcutAction.toggleVoiceInput,
    'quick_open' => ShortcutAction.quickOpen,
    'open_settings' => ShortcutAction.openSettings,
    'cycle_recent_models' => ShortcutAction.cycleRecentModels,
    'cycle_variant' => ShortcutAction.cycleVariant,
    'escape' => ShortcutAction.escape,
    'cycle_agent_forward' => ShortcutAction.cycleAgentForward,
    'cycle_agent_backward' => ShortcutAction.cycleAgentBackward,
    'close_app' => ShortcutAction.closeApp,
    'quit_app' => ShortcutAction.quitApp,
    _ => null,
  };
}

String desktopPaneKey(DesktopPane pane) {
  return switch (pane) {
    DesktopPane.conversations => 'conversations',
    DesktopPane.files => 'files',
    DesktopPane.utility => 'utility',
  };
}

String desktopCloseBehaviorKey(DesktopCloseBehavior behavior) {
  return switch (behavior) {
    DesktopCloseBehavior.tray => 'tray',
    DesktopCloseBehavior.minimize => 'minimize',
    DesktopCloseBehavior.close => 'close',
  };
}

DesktopCloseBehavior desktopCloseBehaviorFromKey(String value) {
  return switch (value) {
    'minimize' => DesktopCloseBehavior.minimize,
    'close' => DesktopCloseBehavior.close,
    _ => DesktopCloseBehavior.tray,
  };
}

DesktopPane? desktopPaneFromKey(String value) {
  return switch (value) {
    'conversations' => DesktopPane.conversations,
    'files' => DesktopPane.files,
    'utility' => DesktopPane.utility,
    _ => null,
  };
}

String appDensityKey(AppDensity density) {
  return switch (density) {
    AppDensity.extraDense => 'extra_dense',
    AppDensity.dense => 'dense',
    AppDensity.normal => 'normal',
    AppDensity.spacious => 'spacious',
    AppDensity.extraSpacious => 'extra_spacious',
  };
}

String themeModeOptionKey(ThemeModeOption mode) {
  return switch (mode) {
    ThemeModeOption.system => 'system',
    ThemeModeOption.light => 'light',
    ThemeModeOption.dark => 'dark',
  };
}

ThemeModeOption themeModeOptionFromKey(String value) {
  return switch (value) {
    'light' => ThemeModeOption.light,
    'dark' => ThemeModeOption.dark,
    _ => ThemeModeOption.system,
  };
}

String speechToTextEngineKey(SpeechToTextEngine engine) {
  return switch (engine) {
    SpeechToTextEngine.native => 'native',
    SpeechToTextEngine.sherpa => 'sherpa',
  };
}

SpeechToTextEngine speechToTextEngineFromKey(String value) {
  return switch (value) {
    'sherpa' => SpeechToTextEngine.sherpa,
    _ => SpeechToTextEngine.native,
  };
}

AppDensity appDensityFromKey(String value) {
  return switch (value) {
    'extra_dense' => AppDensity.extraDense,
    'dense' => AppDensity.dense,
    'spacious' => AppDensity.spacious,
    'extra_spacious' => AppDensity.extraSpacious,
    _ => AppDensity.normal,
  };
}

class ExperienceSettings {
  factory ExperienceSettings.defaults() {
    final defaultSpeechEngine =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.linux
        ? SpeechToTextEngine.sherpa
        : SpeechToTextEngine.native;
    final shortcuts = <ShortcutAction, String>{
      for (final definition in kShortcutDefinitions)
        definition.action: definition.defaultBinding,
    };
    return ExperienceSettings(
      notifications: const <NotificationCategory, bool>{
        NotificationCategory.agent: true,
        NotificationCategory.permissions: true,
        NotificationCategory.errors: true,
      },
      sounds: const <SoundCategory, SoundOption>{
        SoundCategory.agent: SoundOption.systemDefault,
        SoundCategory.permissions: SoundOption.systemDefault,
        SoundCategory.errors: SoundOption.systemDefault,
      },
      notifyOnlyWhenBackground: const <NotificationCategory, bool>{
        NotificationCategory.agent: false,
        NotificationCategory.permissions: false,
        NotificationCategory.errors: false,
      },
      notifyOnlyWhenAnotherSession: const <NotificationCategory, bool>{
        NotificationCategory.agent: false,
        NotificationCategory.permissions: false,
        NotificationCategory.errors: false,
      },
      soundOnlyWhenBackground: const <NotificationCategory, bool>{
        NotificationCategory.agent: false,
        NotificationCategory.permissions: false,
        NotificationCategory.errors: false,
      },
      soundOnlyWhenAnotherSession: const <NotificationCategory, bool>{
        NotificationCategory.agent: false,
        NotificationCategory.permissions: false,
        NotificationCategory.errors: false,
      },
      soundSources: const <SoundCategory, String>{},
      soundLabels: const <SoundCategory, String>{},
      shortcuts: shortcuts,
      desktopPanes: const <DesktopPane, bool>{
        DesktopPane.conversations: true,
        DesktopPane.files: true,
        DesktopPane.utility: true,
      },
      desktopPaneWidths: const <DesktopPane, double>{},
      appDensity: AppDensity.normal,
      showThinkingBubbles: true,
      showToolCallBubbles: true,
      showTaskList: true,
      taskListCollapsed: false,
      showComposerTips: true,
      desktopCloseBehavior: DesktopCloseBehavior.tray,
      keepMobileRealtimeForShortPeriod: true,
      enableExperimentalMultiDeviceSync: false,
      themeMode: ThemeModeOption.system,
      useAmoledDark: false,
      useDynamicColor: true,
      customColorSeed: null,
      contrastLevel: 0.0,
      speechToTextEngine: defaultSpeechEngine,
      speechSilenceTimeoutSeconds: 5,
      sherpaLanguageCode: kSherpaLanguageSystem,
      checkUpdatesOnOpen: true,
    );
  }
  const ExperienceSettings({
    required this.notifications,
    required this.sounds,
    required this.notifyOnlyWhenBackground,
    required this.notifyOnlyWhenAnotherSession,
    required this.soundOnlyWhenBackground,
    required this.soundOnlyWhenAnotherSession,
    required this.soundSources,
    required this.soundLabels,
    required this.shortcuts,
    required this.desktopPanes,
    this.desktopPaneWidths = const <DesktopPane, double>{},
    required this.appDensity,
    required this.showThinkingBubbles,
    required this.showToolCallBubbles,
    required this.showTaskList,
    required this.taskListCollapsed,
    required this.showComposerTips,
    required this.desktopCloseBehavior,
    required this.keepMobileRealtimeForShortPeriod,
    this.enableExperimentalMultiDeviceSync = false,
    this.themeMode = ThemeModeOption.system,
    this.useAmoledDark = false,
    this.useDynamicColor = true,
    this.customColorSeed,
    this.contrastLevel = 0.0,
    this.speechToTextEngine = SpeechToTextEngine.native,
    this.speechSilenceTimeoutSeconds = 5,
    this.sherpaLanguageCode = kSherpaLanguageSystem,
    this.skipOnboardingWizard = false,
    this.checkUpdatesOnOpen = true,
  });

  final Map<NotificationCategory, bool> notifications;
  final Map<SoundCategory, SoundOption> sounds;
  final Map<NotificationCategory, bool> notifyOnlyWhenBackground;
  final Map<NotificationCategory, bool> notifyOnlyWhenAnotherSession;
  final Map<NotificationCategory, bool> soundOnlyWhenBackground;
  final Map<NotificationCategory, bool> soundOnlyWhenAnotherSession;
  final Map<SoundCategory, String> soundSources;
  final Map<SoundCategory, String> soundLabels;
  final Map<ShortcutAction, String> shortcuts;
  final Map<DesktopPane, bool> desktopPanes;
  final Map<DesktopPane, double> desktopPaneWidths;
  final AppDensity appDensity;
  final bool showThinkingBubbles;
  final bool showToolCallBubbles;
  final bool showTaskList;
  final bool taskListCollapsed;
  final bool showComposerTips;
  final DesktopCloseBehavior desktopCloseBehavior;
  final bool keepMobileRealtimeForShortPeriod;
  final bool enableExperimentalMultiDeviceSync;
  final ThemeModeOption themeMode;
  final bool useAmoledDark;
  final bool useDynamicColor;
  final int? customColorSeed;
  final double contrastLevel;
  final SpeechToTextEngine speechToTextEngine;
  final int speechSilenceTimeoutSeconds;
  final String sherpaLanguageCode;
  final bool skipOnboardingWizard;
  final bool checkUpdatesOnOpen;

  ExperienceSettings copyWith({
    Map<NotificationCategory, bool>? notifications,
    Map<SoundCategory, SoundOption>? sounds,
    Map<NotificationCategory, bool>? notifyOnlyWhenBackground,
    Map<NotificationCategory, bool>? notifyOnlyWhenAnotherSession,
    Map<NotificationCategory, bool>? soundOnlyWhenBackground,
    Map<NotificationCategory, bool>? soundOnlyWhenAnotherSession,
    Map<SoundCategory, String>? soundSources,
    Map<SoundCategory, String>? soundLabels,
    Map<ShortcutAction, String>? shortcuts,
    Map<DesktopPane, bool>? desktopPanes,
    Map<DesktopPane, double>? desktopPaneWidths,
    AppDensity? appDensity,
    bool? showThinkingBubbles,
    bool? showToolCallBubbles,
    bool? showTaskList,
    bool? taskListCollapsed,
    bool? showComposerTips,
    DesktopCloseBehavior? desktopCloseBehavior,
    bool? keepMobileRealtimeForShortPeriod,
    bool? enableExperimentalMultiDeviceSync,
    ThemeModeOption? themeMode,
    bool? useAmoledDark,
    bool? useDynamicColor,
    int? Function()? customColorSeed,
    double? contrastLevel,
    SpeechToTextEngine? speechToTextEngine,
    int? speechSilenceTimeoutSeconds,
    String? sherpaLanguageCode,
    bool? skipOnboardingWizard,
    bool? checkUpdatesOnOpen,
  }) {
    return ExperienceSettings(
      notifications: notifications ?? this.notifications,
      sounds: sounds ?? this.sounds,
      notifyOnlyWhenBackground:
          notifyOnlyWhenBackground ?? this.notifyOnlyWhenBackground,
      notifyOnlyWhenAnotherSession:
          notifyOnlyWhenAnotherSession ?? this.notifyOnlyWhenAnotherSession,
      soundOnlyWhenBackground:
          soundOnlyWhenBackground ?? this.soundOnlyWhenBackground,
      soundOnlyWhenAnotherSession:
          soundOnlyWhenAnotherSession ?? this.soundOnlyWhenAnotherSession,
      soundSources: soundSources ?? this.soundSources,
      soundLabels: soundLabels ?? this.soundLabels,
      shortcuts: shortcuts ?? this.shortcuts,
      desktopPanes: desktopPanes ?? this.desktopPanes,
      desktopPaneWidths: desktopPaneWidths ?? this.desktopPaneWidths,
      appDensity: appDensity ?? this.appDensity,
      showThinkingBubbles: showThinkingBubbles ?? this.showThinkingBubbles,
      showToolCallBubbles: showToolCallBubbles ?? this.showToolCallBubbles,
      showTaskList: showTaskList ?? this.showTaskList,
      taskListCollapsed: taskListCollapsed ?? this.taskListCollapsed,
      showComposerTips: showComposerTips ?? this.showComposerTips,
      desktopCloseBehavior: desktopCloseBehavior ?? this.desktopCloseBehavior,
      keepMobileRealtimeForShortPeriod:
          keepMobileRealtimeForShortPeriod ??
          this.keepMobileRealtimeForShortPeriod,
      enableExperimentalMultiDeviceSync:
          enableExperimentalMultiDeviceSync ??
          this.enableExperimentalMultiDeviceSync,
      themeMode: themeMode ?? this.themeMode,
      useAmoledDark: useAmoledDark ?? this.useAmoledDark,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      customColorSeed: customColorSeed != null
          ? customColorSeed()
          : this.customColorSeed,
      contrastLevel: contrastLevel ?? this.contrastLevel,
      speechToTextEngine: speechToTextEngine ?? this.speechToTextEngine,
      speechSilenceTimeoutSeconds:
          speechSilenceTimeoutSeconds ?? this.speechSilenceTimeoutSeconds,
      sherpaLanguageCode: sherpaLanguageCode ?? this.sherpaLanguageCode,
      skipOnboardingWizard: skipOnboardingWizard ?? this.skipOnboardingWizard,
      checkUpdatesOnOpen: checkUpdatesOnOpen ?? this.checkUpdatesOnOpen,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'notifications': <String, bool>{
        for (final entry in notifications.entries)
          notificationCategoryKey(entry.key): entry.value,
      },
      'sounds': <String, String>{
        for (final entry in sounds.entries)
          soundCategoryKey(entry.key): soundOptionKey(entry.value),
      },
      'notifyOnlyWhenBackground': <String, bool>{
        for (final entry in notifyOnlyWhenBackground.entries)
          notificationCategoryKey(entry.key): entry.value,
      },
      'notifyOnlyWhenAnotherSession': <String, bool>{
        for (final entry in notifyOnlyWhenAnotherSession.entries)
          notificationCategoryKey(entry.key): entry.value,
      },
      'soundOnlyWhenBackground': <String, bool>{
        for (final entry in soundOnlyWhenBackground.entries)
          notificationCategoryKey(entry.key): entry.value,
      },
      'soundOnlyWhenAnotherSession': <String, bool>{
        for (final entry in soundOnlyWhenAnotherSession.entries)
          notificationCategoryKey(entry.key): entry.value,
      },
      'soundSources': <String, String>{
        for (final entry in soundSources.entries)
          soundCategoryKey(entry.key): entry.value,
      },
      'soundLabels': <String, String>{
        for (final entry in soundLabels.entries)
          soundCategoryKey(entry.key): entry.value,
      },
      'shortcuts': <String, String>{
        for (final entry in shortcuts.entries)
          shortcutActionKey(entry.key): entry.value,
      },
      'desktopPanes': <String, bool>{
        for (final entry in desktopPanes.entries)
          desktopPaneKey(entry.key): entry.value,
      },
      if (desktopPaneWidths.isNotEmpty)
        'desktopPaneWidths': <String, double>{
          for (final entry in desktopPaneWidths.entries)
            desktopPaneKey(entry.key): entry.value,
        },
      'appDensity': appDensityKey(appDensity),
      'showThinkingBubbles': showThinkingBubbles,
      'showToolCallBubbles': showToolCallBubbles,
      'showTaskList': showTaskList,
      'taskListCollapsed': taskListCollapsed,
      'showComposerTips': showComposerTips,
      'desktopCloseBehavior': desktopCloseBehaviorKey(desktopCloseBehavior),
      'keepDesktopRunningInTray':
          desktopCloseBehavior != DesktopCloseBehavior.close,
      'keepMobileRealtimeForShortPeriod': keepMobileRealtimeForShortPeriod,
      'enableExperimentalMultiDeviceSync': enableExperimentalMultiDeviceSync,
      'themeMode': themeModeOptionKey(themeMode),
      'useAmoledDark': useAmoledDark,
      'useDynamicColor': useDynamicColor,
      if (customColorSeed != null) 'customColorSeed': customColorSeed,
      'contrastLevel': contrastLevel,
      'speechToTextEngine': speechToTextEngineKey(speechToTextEngine),
      'speechSilenceTimeoutSeconds': speechSilenceTimeoutSeconds,
      'sherpaLanguageCode': sherpaLanguageCode,
      'skipOnboardingWizard': skipOnboardingWizard,
      'checkUpdatesOnOpen': checkUpdatesOnOpen,
    };
  }

  static ExperienceSettings fromJson(Map<String, dynamic> json) {
    final defaults = ExperienceSettings.defaults();

    final notifications = Map<NotificationCategory, bool>.from(
      defaults.notifications,
    );
    final sounds = Map<SoundCategory, SoundOption>.from(defaults.sounds);
    final notifyOnlyWhenBackground = Map<NotificationCategory, bool>.from(
      defaults.notifyOnlyWhenBackground,
    );
    final notifyOnlyWhenAnotherSession = Map<NotificationCategory, bool>.from(
      defaults.notifyOnlyWhenAnotherSession,
    );
    final soundOnlyWhenBackground = Map<NotificationCategory, bool>.from(
      defaults.soundOnlyWhenBackground,
    );
    final soundOnlyWhenAnotherSession = Map<NotificationCategory, bool>.from(
      defaults.soundOnlyWhenAnotherSession,
    );
    final soundSources = Map<SoundCategory, String>.from(defaults.soundSources);
    final soundLabels = Map<SoundCategory, String>.from(defaults.soundLabels);
    final shortcuts = Map<ShortcutAction, String>.from(defaults.shortcuts);
    final desktopPanes = Map<DesktopPane, bool>.from(defaults.desktopPanes);
    final desktopPaneWidths = <DesktopPane, double>{};
    var appDensity = defaults.appDensity;
    var showThinkingBubbles = defaults.showThinkingBubbles;
    var showToolCallBubbles = defaults.showToolCallBubbles;
    var showTaskList = defaults.showTaskList;
    var taskListCollapsed = defaults.taskListCollapsed;
    var showComposerTips = defaults.showComposerTips;
    var desktopCloseBehavior = defaults.desktopCloseBehavior;
    var keepMobileRealtimeForShortPeriod =
        defaults.keepMobileRealtimeForShortPeriod;
    var enableExperimentalMultiDeviceSync =
        defaults.enableExperimentalMultiDeviceSync;
    var speechToTextEngine = defaults.speechToTextEngine;
    var speechSilenceTimeoutSeconds = defaults.speechSilenceTimeoutSeconds;
    var sherpaLanguageCode = defaults.sherpaLanguageCode;

    final notificationsJson = json['notifications'];
    if (notificationsJson is Map) {
      for (final entry in notificationsJson.entries) {
        final category = notificationCategoryFromKey(entry.key.toString());
        if (category == null) {
          continue;
        }
        notifications[category] = entry.value == true;
      }
    }

    final soundsJson = json['sounds'];
    if (soundsJson is Map) {
      for (final entry in soundsJson.entries) {
        final category = soundCategoryFromKey(entry.key.toString());
        if (category == null) {
          continue;
        }
        sounds[category] = soundOptionFromKey(entry.value.toString());
      }
    }

    void parseNotificationRule(
      String jsonKey,
      Map<NotificationCategory, bool> target,
    ) {
      final value = json[jsonKey];
      if (value is! Map) {
        return;
      }
      for (final entry in value.entries) {
        final category = notificationCategoryFromKey(entry.key.toString());
        if (category == null) {
          continue;
        }
        target[category] = entry.value == true;
      }
    }

    parseNotificationRule('notifyOnlyWhenBackground', notifyOnlyWhenBackground);
    parseNotificationRule(
      'notifyOnlyWhenAnotherSession',
      notifyOnlyWhenAnotherSession,
    );
    parseNotificationRule('soundOnlyWhenBackground', soundOnlyWhenBackground);
    parseNotificationRule(
      'soundOnlyWhenAnotherSession',
      soundOnlyWhenAnotherSession,
    );

    void parseSoundStringMap(
      String jsonKey,
      Map<SoundCategory, String> target,
    ) {
      final value = json[jsonKey];
      if (value is! Map) {
        return;
      }
      for (final entry in value.entries) {
        final category = soundCategoryFromKey(entry.key.toString());
        final mapped = entry.value.toString().trim();
        if (category == null || mapped.isEmpty) {
          continue;
        }
        target[category] = mapped;
      }
    }

    parseSoundStringMap('soundSources', soundSources);
    parseSoundStringMap('soundLabels', soundLabels);

    final shortcutsJson = json['shortcuts'];
    if (shortcutsJson is Map) {
      for (final entry in shortcutsJson.entries) {
        final action = shortcutActionFromKey(entry.key.toString());
        if (action == null) {
          continue;
        }
        final value = entry.value.toString().trim().toLowerCase();
        if (value.isNotEmpty) {
          shortcuts[action] = value;
        }
      }
    }

    final desktopPanesJson = json['desktopPanes'];
    if (desktopPanesJson is Map) {
      for (final entry in desktopPanesJson.entries) {
        final pane = desktopPaneFromKey(entry.key.toString());
        if (pane == null) {
          continue;
        }
        desktopPanes[pane] = entry.value == true;
      }
    }

    final desktopPaneWidthsJson = json['desktopPaneWidths'];
    if (desktopPaneWidthsJson is Map) {
      for (final entry in desktopPaneWidthsJson.entries) {
        final pane = desktopPaneFromKey(entry.key.toString());
        if (pane == null) {
          continue;
        }
        final raw = entry.value;
        if (raw is num) {
          desktopPaneWidths[pane] = raw.toDouble().clamp(160.0, 500.0);
        }
      }
    }

    final appDensityJson = json['appDensity'];
    if (appDensityJson is String && appDensityJson.trim().isNotEmpty) {
      appDensity = appDensityFromKey(appDensityJson.trim().toLowerCase());
    }

    final showThinkingBubblesJson = json['showThinkingBubbles'];
    if (showThinkingBubblesJson is bool) {
      showThinkingBubbles = showThinkingBubblesJson;
    }

    final showToolCallBubblesJson = json['showToolCallBubbles'];
    if (showToolCallBubblesJson is bool) {
      showToolCallBubbles = showToolCallBubblesJson;
    }

    final showTaskListJson = json['showTaskList'];
    if (showTaskListJson is bool) {
      showTaskList = showTaskListJson;
    }

    final taskListCollapsedJson = json['taskListCollapsed'];
    if (taskListCollapsedJson is bool) {
      taskListCollapsed = taskListCollapsedJson;
    }

    final showComposerTipsJson = json['showComposerTips'];
    if (showComposerTipsJson is bool) {
      showComposerTips = showComposerTipsJson;
    }

    final desktopCloseBehaviorJson = json['desktopCloseBehavior'];
    if (desktopCloseBehaviorJson is String &&
        desktopCloseBehaviorJson.trim().isNotEmpty) {
      desktopCloseBehavior = desktopCloseBehaviorFromKey(
        desktopCloseBehaviorJson.trim().toLowerCase(),
      );
    } else {
      final keepDesktopRunningInTrayJson = json['keepDesktopRunningInTray'];
      if (keepDesktopRunningInTrayJson is bool) {
        desktopCloseBehavior = keepDesktopRunningInTrayJson
            ? DesktopCloseBehavior.tray
            : DesktopCloseBehavior.close;
      }
    }

    final keepMobileRealtimeForShortPeriodJson =
        json['keepMobileRealtimeForShortPeriod'];
    if (keepMobileRealtimeForShortPeriodJson is bool) {
      keepMobileRealtimeForShortPeriod = keepMobileRealtimeForShortPeriodJson;
    }

    final enableExperimentalMultiDeviceSyncJson =
        json['enableExperimentalMultiDeviceSync'];
    if (enableExperimentalMultiDeviceSyncJson is bool) {
      enableExperimentalMultiDeviceSync = enableExperimentalMultiDeviceSyncJson;
    }

    var themeMode = defaults.themeMode;
    final themeModeJson = json['themeMode'];
    if (themeModeJson is String && themeModeJson.trim().isNotEmpty) {
      themeMode = themeModeOptionFromKey(themeModeJson.trim().toLowerCase());
    }

    var useAmoledDark = defaults.useAmoledDark;
    final useAmoledDarkJson = json['useAmoledDark'];
    if (useAmoledDarkJson is bool) {
      useAmoledDark = useAmoledDarkJson;
    }

    var useDynamicColor = defaults.useDynamicColor;
    final useDynamicColorJson = json['useDynamicColor'];
    if (useDynamicColorJson is bool) {
      useDynamicColor = useDynamicColorJson;
    }

    int? customColorSeed = defaults.customColorSeed;
    final customColorSeedJson = json['customColorSeed'];
    if (customColorSeedJson is num) {
      customColorSeed = customColorSeedJson.toInt();
    }

    var contrastLevel = defaults.contrastLevel;
    final contrastLevelJson = json['contrastLevel'];
    if (contrastLevelJson is num) {
      contrastLevel = contrastLevelJson.toDouble().clamp(-1.0, 1.0);
    }

    final speechToTextEngineJson = json['speechToTextEngine'];
    if (speechToTextEngineJson is String &&
        speechToTextEngineJson.trim().isNotEmpty) {
      speechToTextEngine = speechToTextEngineFromKey(
        speechToTextEngineJson.trim().toLowerCase(),
      );
    }

    final speechSilenceTimeoutSecondsJson = json['speechSilenceTimeoutSeconds'];
    if (speechSilenceTimeoutSecondsJson is num) {
      speechSilenceTimeoutSeconds = speechSilenceTimeoutSecondsJson
          .toInt()
          .clamp(2, 10)
          .toInt();
    }

    final sherpaLanguageCodeJson = json['sherpaLanguageCode'];
    if (sherpaLanguageCodeJson is String &&
        sherpaLanguageCodeJson.trim().isNotEmpty) {
      sherpaLanguageCode = sherpaLanguageCodeJson.trim().toLowerCase();
    }

    var skipOnboardingWizard = defaults.skipOnboardingWizard;
    final skipOnboardingWizardJson = json['skipOnboardingWizard'];
    if (skipOnboardingWizardJson is bool) {
      skipOnboardingWizard = skipOnboardingWizardJson;
    }

    var checkUpdatesOnOpen = defaults.checkUpdatesOnOpen;
    final checkUpdatesOnOpenJson = json['checkUpdatesOnOpen'];
    if (checkUpdatesOnOpenJson is bool) {
      checkUpdatesOnOpen = checkUpdatesOnOpenJson;
    }

    return ExperienceSettings(
      notifications: notifications,
      sounds: sounds,
      notifyOnlyWhenBackground: notifyOnlyWhenBackground,
      notifyOnlyWhenAnotherSession: notifyOnlyWhenAnotherSession,
      soundOnlyWhenBackground: soundOnlyWhenBackground,
      soundOnlyWhenAnotherSession: soundOnlyWhenAnotherSession,
      soundSources: soundSources,
      soundLabels: soundLabels,
      shortcuts: shortcuts,
      desktopPanes: desktopPanes,
      desktopPaneWidths: desktopPaneWidths,
      appDensity: appDensity,
      showThinkingBubbles: showThinkingBubbles,
      showToolCallBubbles: showToolCallBubbles,
      showTaskList: showTaskList,
      taskListCollapsed: taskListCollapsed,
      showComposerTips: showComposerTips,
      desktopCloseBehavior: desktopCloseBehavior,
      keepMobileRealtimeForShortPeriod: keepMobileRealtimeForShortPeriod,
      enableExperimentalMultiDeviceSync: enableExperimentalMultiDeviceSync,
      themeMode: themeMode,
      useAmoledDark: useAmoledDark,
      useDynamicColor: useDynamicColor,
      customColorSeed: customColorSeed,
      contrastLevel: contrastLevel,
      speechToTextEngine: speechToTextEngine,
      speechSilenceTimeoutSeconds: speechSilenceTimeoutSeconds,
      sherpaLanguageCode: sherpaLanguageCode,
      skipOnboardingWizard: skipOnboardingWizard,
      checkUpdatesOnOpen: checkUpdatesOnOpen,
    );
  }
}
