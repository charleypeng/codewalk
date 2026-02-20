import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:package_info_plus/package_info_plus.dart';

import '../../core/logging/app_logger.dart';
import '../../core/network/dio_client.dart';
import '../../data/datasources/app_local_datasource.dart';
import '../../domain/entities/experience_settings.dart';
import '../services/sound_service.dart';
import '../services/update_check_service.dart';
import '../utils/shortcut_binding_codec.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    required AppLocalDataSource localDataSource,
    required DioClient dioClient,
    required SoundService soundService,
    UpdateCheckService? updateCheckService,
  }) : _localDataSource = localDataSource,
       _dioClient = dioClient,
       _soundService = soundService,
       _updateCheckService = updateCheckService ?? UpdateCheckService();

  final AppLocalDataSource _localDataSource;
  final DioClient _dioClient;
  final SoundService _soundService;
  final UpdateCheckService _updateCheckService;

  ExperienceSettings _settings = ExperienceSettings.defaults();
  final Map<NotificationCategory, bool> _serverBackedNotifications =
      <NotificationCategory, bool>{
        NotificationCategory.agent: false,
        NotificationCategory.permissions: false,
        NotificationCategory.errors: false,
      };
  final Map<NotificationCategory, String> _serverConfigKeyByCategory =
      <NotificationCategory, String>{};
  UpdateCheckResult? _updateCheckResult;
  String? _dismissedUpdateVersion;
  bool _checkingForUpdate = false;
  bool _lastCheckFoundNoUpdate = false;
  bool _initialized = false;
  Future<void>? _initFuture;

  bool get initialized => _initialized;
  ExperienceSettings get settings => _settings;
  UpdateCheckResult? get updateCheckResult => _updateCheckResult;
  bool get checkingForUpdate => _checkingForUpdate;
  bool get lastCheckFoundNoUpdate => _lastCheckFoundNoUpdate;
  ThemeModeOption get themeMode => _settings.themeMode;
  AppDensity get appDensity => _settings.appDensity;
  bool get showThinkingBubbles => _settings.showThinkingBubbles;
  bool get showToolCallBubbles => _settings.showToolCallBubbles;
  bool get showTaskList => _settings.showTaskList;
  bool get taskListCollapsed => _settings.taskListCollapsed;
  bool get showComposerTips => _settings.showComposerTips;
  bool get keepDesktopRunningInTray => _settings.keepDesktopRunningInTray;
  bool get keepMobileRealtimeForShortPeriod =>
      _settings.keepMobileRealtimeForShortPeriod;
  SpeechToTextEngine get speechToTextEngine => _settings.speechToTextEngine;
  int get speechSilenceTimeoutSeconds => _settings.speechSilenceTimeoutSeconds;
  String get sherpaLanguageCode => _settings.sherpaLanguageCode;
  bool get skipOnboardingWizard => _settings.skipOnboardingWizard;
  bool get hasAnyServerBackedNotificationCategory =>
      _serverBackedNotifications.values.any((value) => value);

  bool notifyOnlyWhenBackground(NotificationCategory category) {
    return _settings.notifyOnlyWhenBackground[category] ?? false;
  }

  bool notifyOnlyWhenAnotherSession(NotificationCategory category) {
    return _settings.notifyOnlyWhenAnotherSession[category] ?? false;
  }

  bool soundOnlyWhenBackground(NotificationCategory category) {
    return _settings.soundOnlyWhenBackground[category] ?? false;
  }

  bool soundOnlyWhenAnotherSession(NotificationCategory category) {
    return _settings.soundOnlyWhenAnotherSession[category] ?? false;
  }

  bool isServerBackedNotification(NotificationCategory category) {
    return _serverBackedNotifications[category] ?? false;
  }

  Future<void> initialize() async {
    _initFuture ??= _initializeInternal();
    await _initFuture;
  }

  Future<void> _initializeInternal() async {
    final raw = await _localDataSource.getExperienceSettingsJson();
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _settings = ExperienceSettings.fromJson(decoded);
        }
      } catch (error, stackTrace) {
        AppLogger.warn(
          'Failed to decode experience settings, using defaults',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    // Platform STT policy migration:
    // - Linux: Native is disabled, force Sherpa.
    // - Android: Sherpa is disabled in slim APK builds, force Native.
    final isLinux = !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (isLinux && _settings.speechToTextEngine == SpeechToTextEngine.native) {
      _settings = _settings.copyWith(
        speechToTextEngine: SpeechToTextEngine.sherpa,
      );
      unawaited(_persist());
    } else if (isAndroid &&
        _settings.speechToTextEngine == SpeechToTextEngine.sherpa) {
      _settings = _settings.copyWith(
        speechToTextEngine: SpeechToTextEngine.native,
      );
      unawaited(_persist());
    }

    _dismissedUpdateVersion = await _localDataSource
        .getDismissedUpdateVersion();
    unawaited(syncNotificationsFromServerConfig());
    _initialized = true;
    notifyListeners();
  }

  bool isNotificationEnabled(NotificationCategory category) {
    return _settings.notifications[category] ?? true;
  }

  SoundCategory soundCategoryForNotification(NotificationCategory category) {
    return switch (category) {
      NotificationCategory.agent => SoundCategory.agent,
      NotificationCategory.permissions => SoundCategory.permissions,
      NotificationCategory.errors => SoundCategory.errors,
    };
  }

  bool isSoundEnabledForNotification(NotificationCategory category) {
    return soundFor(soundCategoryForNotification(category)) != SoundOption.off;
  }

  SoundOption soundFor(SoundCategory category) {
    return _settings.sounds[category] ?? SoundOption.off;
  }

  String? soundSourceFor(SoundCategory category) {
    final value = _settings.soundSources[category]?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? soundLabelFor(SoundCategory category) {
    final value = _settings.soundLabels[category]?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String bindingFor(ShortcutAction action) {
    return _settings.shortcuts[action] ??
        kShortcutDefinitions
            .where((definition) => definition.action == action)
            .first
            .defaultBinding;
  }

  bool isDesktopPaneVisible(DesktopPane pane) {
    return _settings.desktopPanes[pane] ?? true;
  }

  Future<void> setThemeMode(ThemeModeOption mode) async {
    if (_settings.themeMode == mode) {
      return;
    }
    _settings = _settings.copyWith(themeMode: mode);
    notifyListeners();
    await _persist();
  }

  Future<void> setAppDensity(AppDensity density) async {
    if (_settings.appDensity == density) {
      return;
    }
    _settings = _settings.copyWith(appDensity: density);
    notifyListeners();
    await _persist();
  }

  Future<void> setShowThinkingBubbles(bool visible) async {
    if (_settings.showThinkingBubbles == visible) {
      return;
    }
    _settings = _settings.copyWith(showThinkingBubbles: visible);
    notifyListeners();
    await _persist();
  }

  Future<void> setShowToolCallBubbles(bool visible) async {
    if (_settings.showToolCallBubbles == visible) {
      return;
    }
    _settings = _settings.copyWith(showToolCallBubbles: visible);
    notifyListeners();
    await _persist();
  }

  Future<void> setShowTaskList(bool visible) async {
    if (_settings.showTaskList == visible) {
      return;
    }
    _settings = _settings.copyWith(showTaskList: visible);
    notifyListeners();
    await _persist();
  }

  Future<void> setTaskListCollapsed(bool collapsed) async {
    if (_settings.taskListCollapsed == collapsed) {
      return;
    }
    _settings = _settings.copyWith(taskListCollapsed: collapsed);
    notifyListeners();
    await _persist();
  }

  Future<void> setShowComposerTips(bool enabled) async {
    if (_settings.showComposerTips == enabled) {
      return;
    }
    _settings = _settings.copyWith(showComposerTips: enabled);
    notifyListeners();
    await _persist();
  }

  Future<void> setKeepDesktopRunningInTray(bool enabled) async {
    if (_settings.keepDesktopRunningInTray == enabled) {
      return;
    }
    _settings = _settings.copyWith(keepDesktopRunningInTray: enabled);
    notifyListeners();
    await _persist();
  }

  Future<void> setKeepMobileRealtimeForShortPeriod(bool enabled) async {
    if (_settings.keepMobileRealtimeForShortPeriod == enabled) {
      return;
    }
    _settings = _settings.copyWith(keepMobileRealtimeForShortPeriod: enabled);
    notifyListeners();
    await _persist();
  }

  Future<void> setSpeechToTextEngine(SpeechToTextEngine engine) async {
    if (_settings.speechToTextEngine == engine) {
      return;
    }
    _settings = _settings.copyWith(speechToTextEngine: engine);
    notifyListeners();
    await _persist();
  }

  Future<void> setSpeechSilenceTimeoutSeconds(int seconds) async {
    final normalized = seconds.clamp(2, 10).toInt();
    if (_settings.speechSilenceTimeoutSeconds == normalized) {
      return;
    }
    _settings = _settings.copyWith(speechSilenceTimeoutSeconds: normalized);
    notifyListeners();
    await _persist();
  }

  Future<void> setSkipOnboardingWizard(bool value) async {
    if (_settings.skipOnboardingWizard == value) {
      return;
    }
    _settings = _settings.copyWith(skipOnboardingWizard: value);
    notifyListeners();
    await _persist();
  }

  Future<void> setSherpaLanguageCode(String languageCode) async {
    final normalized = languageCode.trim().toLowerCase();
    if (normalized.isEmpty) {
      return;
    }
    if (_settings.sherpaLanguageCode == normalized) {
      return;
    }
    _settings = _settings.copyWith(sherpaLanguageCode: normalized);
    notifyListeners();
    await _persist();
  }

  Future<void> setDesktopPaneVisible(DesktopPane pane, bool visible) async {
    final next = Map<DesktopPane, bool>.from(_settings.desktopPanes);
    next[pane] = visible;
    _settings = _settings.copyWith(desktopPanes: next);
    notifyListeners();
    await _persist();
  }

  Future<void> setNotificationEnabled(
    NotificationCategory category,
    bool value,
  ) async {
    final next = Map<NotificationCategory, bool>.from(_settings.notifications);
    next[category] = value;
    _settings = _settings.copyWith(notifications: next);
    notifyListeners();
    await _persist();
    await _syncNotificationToServer(category, value);
  }

  Future<void> setNotifyOnlyWhenBackground(
    NotificationCategory category,
    bool value,
  ) async {
    final next = Map<NotificationCategory, bool>.from(
      _settings.notifyOnlyWhenBackground,
    );
    next[category] = value;
    _settings = _settings.copyWith(notifyOnlyWhenBackground: next);
    notifyListeners();
    await _persist();
  }

  Future<void> setNotifyOnlyWhenAnotherSession(
    NotificationCategory category,
    bool value,
  ) async {
    final next = Map<NotificationCategory, bool>.from(
      _settings.notifyOnlyWhenAnotherSession,
    );
    next[category] = value;
    _settings = _settings.copyWith(notifyOnlyWhenAnotherSession: next);
    notifyListeners();
    await _persist();
  }

  Future<void> setSoundOnlyWhenBackground(
    NotificationCategory category,
    bool value,
  ) async {
    final next = Map<NotificationCategory, bool>.from(
      _settings.soundOnlyWhenBackground,
    );
    next[category] = value;
    _settings = _settings.copyWith(soundOnlyWhenBackground: next);
    notifyListeners();
    await _persist();
  }

  Future<void> setSoundOnlyWhenAnotherSession(
    NotificationCategory category,
    bool value,
  ) async {
    final next = Map<NotificationCategory, bool>.from(
      _settings.soundOnlyWhenAnotherSession,
    );
    next[category] = value;
    _settings = _settings.copyWith(soundOnlyWhenAnotherSession: next);
    notifyListeners();
    await _persist();
  }

  Future<void> setSoundOption(
    SoundCategory category,
    SoundOption option, {
    String? source,
    String? label,
  }) async {
    final next = Map<SoundCategory, SoundOption>.from(_settings.sounds);
    final nextSources = Map<SoundCategory, String>.from(_settings.soundSources);
    final nextLabels = Map<SoundCategory, String>.from(_settings.soundLabels);
    next[category] = option;

    final normalizedSource = source?.trim();
    final normalizedLabel = label?.trim();
    if (option == SoundOption.systemChoice ||
        option == SoundOption.customFile) {
      if (normalizedSource != null && normalizedSource.isNotEmpty) {
        nextSources[category] = normalizedSource;
      }
      if (normalizedLabel != null && normalizedLabel.isNotEmpty) {
        nextLabels[category] = normalizedLabel;
      }
    }

    if (option == SoundOption.click ||
        option == SoundOption.alert ||
        option == SoundOption.systemDefault ||
        option == SoundOption.off) {
      nextSources.remove(category);
      nextLabels.remove(category);
    }

    _settings = _settings.copyWith(
      sounds: next,
      soundSources: nextSources,
      soundLabels: nextLabels,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> setSoundEnabledForNotification(
    NotificationCategory category,
    bool enabled,
  ) async {
    final soundCategory = soundCategoryForNotification(category);
    final current = soundFor(soundCategory);
    if (enabled) {
      if (current != SoundOption.off) {
        return;
      }
      final fallback =
          ExperienceSettings.defaults().sounds[soundCategory] ??
          SoundOption.alert;
      await setSoundOption(soundCategory, fallback);
      return;
    }
    if (current == SoundOption.off) {
      return;
    }
    await setSoundOption(soundCategory, SoundOption.off);
  }

  Future<void> previewSound(SoundCategory category) async {
    await _soundService.play(
      option: soundFor(category),
      source: soundSourceFor(category),
    );
  }

  bool shouldDispatchNotification(
    NotificationCategory category, {
    required bool isAppInForeground,
    required bool isAnotherSession,
  }) {
    if (!isNotificationEnabled(category)) {
      return false;
    }
    return _matchesOnlyWhenRule(
      onlyWhenBackground: notifyOnlyWhenBackground(category),
      onlyWhenAnotherSession: notifyOnlyWhenAnotherSession(category),
      isAppInForeground: isAppInForeground,
      isAnotherSession: isAnotherSession,
    );
  }

  bool shouldDispatchSound(
    NotificationCategory category, {
    required bool isAppInForeground,
    required bool isAnotherSession,
  }) {
    final soundCategory = soundCategoryForNotification(category);
    if (soundFor(soundCategory) == SoundOption.off) {
      return false;
    }
    return _matchesOnlyWhenRule(
      onlyWhenBackground: soundOnlyWhenBackground(category),
      onlyWhenAnotherSession: soundOnlyWhenAnotherSession(category),
      isAppInForeground: isAppInForeground,
      isAnotherSession: isAnotherSession,
    );
  }

  bool _matchesOnlyWhenRule({
    required bool onlyWhenBackground,
    required bool onlyWhenAnotherSession,
    required bool isAppInForeground,
    required bool isAnotherSession,
  }) {
    if (!onlyWhenBackground && !onlyWhenAnotherSession) {
      return true;
    }
    final backgroundMatch = onlyWhenBackground && !isAppInForeground;
    final anotherSessionMatch = onlyWhenAnotherSession && isAnotherSession;
    return backgroundMatch || anotherSessionMatch;
  }

  String? findShortcutConflict(ShortcutAction action, String binding) {
    final normalized = ShortcutBindingCodec.normalize(binding);
    if (normalized.isEmpty) {
      return null;
    }

    for (final entry in _settings.shortcuts.entries) {
      if (entry.key == action) {
        continue;
      }
      if (ShortcutBindingCodec.normalize(entry.value) == normalized) {
        final label = kShortcutDefinitions
            .where((item) => item.action == entry.key)
            .first
            .label;
        return label;
      }
    }
    return null;
  }

  Future<String?> updateShortcut(ShortcutAction action, String binding) async {
    final normalized = ShortcutBindingCodec.normalize(binding);
    if (normalized.isEmpty) {
      return 'Invalid shortcut';
    }

    final parsed = ShortcutBindingCodec.parse(normalized);
    if (parsed == null) {
      return 'Unsupported shortcut key';
    }

    final conflict = findShortcutConflict(action, normalized);
    if (conflict != null) {
      return 'Conflicts with "$conflict"';
    }

    final next = Map<ShortcutAction, String>.from(_settings.shortcuts);
    next[action] = normalized;
    _settings = _settings.copyWith(shortcuts: next);
    notifyListeners();
    await _persist();
    return null;
  }

  Future<void> clearShortcut(ShortcutAction action) async {
    final definition = kShortcutDefinitions
        .where((item) => item.action == action)
        .first;
    final next = Map<ShortcutAction, String>.from(_settings.shortcuts);
    next[action] = definition.defaultBinding;
    _settings = _settings.copyWith(shortcuts: next);
    notifyListeners();
    await _persist();
  }

  Future<void> resetAllShortcuts() async {
    final defaults = <ShortcutAction, String>{
      for (final definition in kShortcutDefinitions)
        definition.action: definition.defaultBinding,
    };
    _settings = _settings.copyWith(shortcuts: defaults);
    notifyListeners();
    await _persist();
  }

  Future<void> checkForUpdate() async {
    _checkingForUpdate = true;
    _lastCheckFoundNoUpdate = false;
    notifyListeners();
    try {
      final info = await PackageInfo.fromPlatform();
      _updateCheckService.clearCache();
      final result = await _updateCheckService.check(info.version);
      if (result != null &&
          result.isNewer &&
          result.latestVersion != _dismissedUpdateVersion) {
        _updateCheckResult = result;
        _lastCheckFoundNoUpdate = false;
      } else {
        _updateCheckResult = null;
        _lastCheckFoundNoUpdate = result != null;
      }
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Update check failed',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _checkingForUpdate = false;
      notifyListeners();
    }
  }

  Future<void> dismissUpdate(String version) async {
    _dismissedUpdateVersion = version;
    _updateCheckResult = null;
    await _localDataSource.saveDismissedUpdateVersion(version);
    notifyListeners();
  }

  /// Resets in-memory state to defaults (used after clearAll during app reset).
  void resetToDefaults() {
    _settings = ExperienceSettings.defaults();
    _updateCheckResult = null;
    _dismissedUpdateVersion = null;
    _checkingForUpdate = false;
    _lastCheckFoundNoUpdate = false;
    _initialized = false;
    _initFuture = null;
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      await _localDataSource.saveExperienceSettingsJson(
        jsonEncode(_settings.toJson()),
      );
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Failed to persist experience settings',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> syncNotificationsFromServerConfig() async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>('/config');
      final config = response.data;
      if (config == null) {
        return;
      }
      _applyServerNotificationConfig(config);
    } catch (_) {
      // Keep local values when server does not expose /config or fails.
    }
  }

  void _applyServerNotificationConfig(Map<String, dynamic> config) {
    var changed = false;
    final nextNotifications = Map<NotificationCategory, bool>.from(
      _settings.notifications,
    );

    for (final category in NotificationCategory.values) {
      _serverBackedNotifications[category] = false;
    }
    _serverConfigKeyByCategory.clear();

    bool bindDirectKey(NotificationCategory category, String key) {
      if (!config.containsKey(key)) {
        return false;
      }
      final value = config[key];
      if (value is bool) {
        nextNotifications[category] = value;
        changed = true;
      }
      _serverBackedNotifications[category] = true;
      _serverConfigKeyByCategory[category] = key;
      return true;
    }

    bindDirectKey(NotificationCategory.agent, 'settings-notifications-agent');
    bindDirectKey(
      NotificationCategory.permissions,
      'settings-notifications-permissions',
    );
    bindDirectKey(NotificationCategory.errors, 'settings-notifications-errors');

    final notificationsMap = config['notifications'];
    if (notificationsMap is Map) {
      void bindNested(NotificationCategory category, String key) {
        final value = notificationsMap[key];
        if (value is bool) {
          nextNotifications[category] = value;
          changed = true;
          _serverBackedNotifications[category] = true;
          _serverConfigKeyByCategory[category] = 'notifications.$key';
        }
      }

      bindNested(NotificationCategory.agent, 'agent');
      bindNested(NotificationCategory.permissions, 'permissions');
      bindNested(NotificationCategory.errors, 'errors');
    }

    if (changed) {
      _settings = _settings.copyWith(notifications: nextNotifications);
      notifyListeners();
      unawaited(_persist());
    }
  }

  Future<void> _syncNotificationToServer(
    NotificationCategory category,
    bool value,
  ) async {
    final key = _serverConfigKeyByCategory[category];
    if (key == null || key.isEmpty) {
      return;
    }
    try {
      if (key.startsWith('notifications.')) {
        final nested = key.substring('notifications.'.length);
        await _dioClient.patch<void>(
          '/config',
          data: <String, dynamic>{
            'notifications': <String, dynamic>{nested: value},
          },
        );
      } else {
        await _dioClient.patch<void>(
          '/config',
          data: <String, dynamic>{key: value},
        );
      }
    } catch (_) {
      // Server sync is best-effort; local value remains source of truth.
    }
  }
}
