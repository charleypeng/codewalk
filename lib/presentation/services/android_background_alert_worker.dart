import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/chat_realtime_model.dart';
import '../../data/models/chat_session_model.dart';
import '../../domain/entities/experience_settings.dart';
import 'android_background_alert_logic.dart';
import 'notification_service.dart';

const String _backgroundAlertWorkUniqueName =
    'codewalk.android.background.alerts';
const String _backgroundAlertOneOffUniqueName =
    'codewalk.android.background.alerts.once';
const String _backgroundAlertTaskName = 'codewalk.background.alerts.poll';
const String _backgroundAlertSnapshotKeyPrefix =
    'codewalk.android.background.alert.snapshot.v1';
const Duration _backgroundAlertFailureRetryInterval = Duration(minutes: 5);

@pragma('vm:entry-point')
void codewalkBackgroundAlertDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    return AndroidBackgroundAlertWorker.executeTask(taskName: task);
  });
}

class AndroidBackgroundAlertWorker {
  static bool _initialized = false;
  static const Duration activeSessionProbeInterval =
      kBackgroundFastProbeInterval;

  static Future<void> ensureRegistered() async {
    if (!_isAndroidRuntime()) {
      return;
    }

    if (!_initialized) {
      try {
        await Workmanager().initialize(codewalkBackgroundAlertDispatcher);
        _initialized = true;
      } catch (error, stackTrace) {
        AppLogger.warn(
          'Failed to initialize Android background alert worker',
          error: error,
          stackTrace: stackTrace,
        );
        return;
      }
    }

    try {
      await Workmanager().registerPeriodicTask(
        _backgroundAlertWorkUniqueName,
        _backgroundAlertTaskName,
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        constraints: Constraints(networkType: NetworkType.connected),
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 15),
      );
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Failed to register Android background alert periodic task',
        error: error,
        stackTrace: stackTrace,
      );
    }

    await scheduleProbe();
  }

  static Future<void> scheduleProbe({
    Duration initialDelay = const Duration(minutes: 1),
    bool ensureInitialized = true,
  }) async {
    if (!_isAndroidRuntime()) {
      return;
    }

    if (ensureInitialized && !_initialized) {
      await ensureRegistered();
      if (!_initialized) {
        return;
      }
    }

    await _registerOneOffTask(initialDelay: initialDelay);
  }

  static Future<void> _registerOneOffTask({
    required Duration initialDelay,
  }) async {
    if (!_isAndroidRuntime()) {
      return;
    }

    try {
      await Workmanager().registerOneOffTask(
        _backgroundAlertOneOffUniqueName,
        _backgroundAlertTaskName,
        initialDelay: initialDelay,
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 15),
      );
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Failed to schedule Android background alert one-off task',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> primeSnapshot({
    required String serverId,
    required Map<String, String> sessionStatusById,
    required Map<String, int> sessionUpdatedAtById,
    required Map<String, String> sessionTitleById,
  }) async {
    if (!_isAndroidRuntime()) {
      return;
    }

    final normalizedServerId = serverId.trim();
    if (normalizedServerId.isEmpty) {
      return;
    }

    final normalizedStatusById = <String, String>{};
    for (final entry in sessionStatusById.entries) {
      final sessionId = entry.key.trim();
      final status = entry.value.trim().toLowerCase();
      if (sessionId.isEmpty || status.isEmpty) {
        continue;
      }
      normalizedStatusById[sessionId] = status;
    }

    if (!hasActiveBackgroundSessions(normalizedStatusById)) {
      return;
    }

    final normalizedUpdatedAtById = <String, int>{};
    for (final entry in sessionUpdatedAtById.entries) {
      final sessionId = entry.key.trim();
      final updatedAt = entry.value;
      if (sessionId.isEmpty || updatedAt <= 0) {
        continue;
      }
      normalizedUpdatedAtById[sessionId] = updatedAt;
    }

    final normalizedTitleById = <String, String>{};
    for (final entry in sessionTitleById.entries) {
      final sessionId = entry.key.trim();
      final title = entry.value.trim();
      if (sessionId.isEmpty || title.isEmpty) {
        continue;
      }
      normalizedTitleById[sessionId] = title;
    }

    final prefs = await SharedPreferences.getInstance();
    final snapshotKey = _backgroundAlertSnapshotStorageKey(normalizedServerId);
    final existingSnapshotRaw = prefs.getString(snapshotKey);
    var existingSnapshot = BackgroundAlertSnapshot.empty();
    if (existingSnapshotRaw != null && existingSnapshotRaw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(existingSnapshotRaw);
        if (decoded is Map<String, dynamic>) {
          existingSnapshot = BackgroundAlertSnapshot.fromJson(decoded);
        } else if (decoded is Map) {
          existingSnapshot = BackgroundAlertSnapshot.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {
        // Falls back to an empty snapshot.
      }
    }

    final primedSnapshot = BackgroundAlertSnapshot(
      sessionStatusById: normalizedStatusById,
      sessionUpdatedAtById: normalizedUpdatedAtById,
      notifiedPermissionRequestIds:
          existingSnapshot.notifiedPermissionRequestIds,
      notifiedQuestionRequestIds: existingSnapshot.notifiedQuestionRequestIds,
      lastPolledAtEpochMs: DateTime.now().millisecondsSinceEpoch,
    );

    await prefs.setString(snapshotKey, jsonEncode(primedSnapshot.toJson()));
  }

  @pragma('vm:entry-point')
  static Future<bool> executeTask({required String taskName}) async {
    if (!_isAndroidRuntime()) {
      return true;
    }

    _initialized = true;

    final runner = _AndroidBackgroundAlertRunner(
      planner: const BackgroundAlertPlanner(),
      notificationDispatcher: _BackgroundNotificationDispatcher(),
    );
    return runner.run(taskName: taskName);
  }
}

class _AndroidBackgroundAlertRunner {
  const _AndroidBackgroundAlertRunner({
    required BackgroundAlertPlanner planner,
    required _BackgroundNotificationDispatcher notificationDispatcher,
  }) : _planner = planner,
       _notificationDispatcher = notificationDispatcher;

  final BackgroundAlertPlanner _planner;
  final _BackgroundNotificationDispatcher _notificationDispatcher;
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<bool> run({required String taskName}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final server = await _resolveServerConfig(prefs);
      if (server == null) {
        AppLogger.debug('background_alert_worker skipped (no active server)');
        return true;
      }

      final settings = _readSettings(prefs);
      final dio = _createDioClient(server);
      final snapshotKey = _snapshotStorageKey(server.serverId);
      final previousSnapshot = _readSnapshot(prefs, snapshotKey);
      final statusById = await _fetchSessionStatusById(dio);
      if (statusById == null) {
        await _scheduleRetryAfterStatusFailure(previousSnapshot);
        AppLogger.warn(
          'background_alert_worker skipped ($taskName): status fetch failed',
        );
        return true;
      }

      final sessionMetadata = await _fetchSessionMetadata(dio);
      final permissionRequests = await _fetchPermissionRequests(dio);
      final questionRequests = await _fetchQuestionRequests(dio);

      final currentState = BackgroundPollingState(
        sessionStatusById: statusById,
        sessionUpdatedAtById: sessionMetadata.updatedAtBySessionId,
        sessionTitleById: sessionMetadata.titleBySessionId,
        permissionRequests: permissionRequests,
        questionRequests: questionRequests,
      );

      final nowEpochMs = DateTime.now().millisecondsSinceEpoch;
      final plan = _planner.plan(
        previous: previousSnapshot,
        current: currentState,
        settings: settings,
        nowEpochMs: nowEpochMs,
      );

      if (!plan.baselineOnly) {
        for (final signal in plan.signals) {
          await _notificationDispatcher.show(signal: signal);
        }
      }

      await prefs.setString(
        snapshotKey,
        jsonEncode(plan.nextSnapshot.toJson()),
      );

      await _scheduleNextProbe(statusById);

      AppLogger.debug(
        'background_alert_worker task=$taskName baseline=${plan.baselineOnly} alerts=${plan.signals.length}',
      );
      return true;
    } catch (error, stackTrace) {
      AppLogger.warn(
        'background_alert_worker task failure',
        error: error,
        stackTrace: stackTrace,
      );
      return true;
    }
  }

  Future<void> _scheduleNextProbe(Map<String, String> statusById) async {
    if (!hasActiveBackgroundSessions(statusById)) {
      return;
    }

    await _scheduleProbe(
      delay: AndroidBackgroundAlertWorker.activeSessionProbeInterval,
      reason: 'active-session',
    );
  }

  Future<void> _scheduleRetryAfterStatusFailure(
    BackgroundAlertSnapshot previousSnapshot,
  ) async {
    final wasActive = hasActiveBackgroundSessions(
      previousSnapshot.sessionStatusById,
    );
    await _scheduleProbe(
      delay: wasActive
          ? AndroidBackgroundAlertWorker.activeSessionProbeInterval
          : _backgroundAlertFailureRetryInterval,
      reason: wasActive ? 'status-failure-active' : 'status-failure-fallback',
    );
  }

  Future<void> _scheduleProbe({
    required Duration delay,
    required String reason,
  }) async {
    AppLogger.debug(
      'background_alert_worker schedule_probe reason=$reason delay=${delay.inMinutes}m',
    );

    await AndroidBackgroundAlertWorker.scheduleProbe(
      initialDelay: delay,
      ensureInitialized: false,
    );
  }

  Dio _createDioClient(_ResolvedServerConfig server) {
    final headers = <String, Object>{'Content-Type': 'application/json'};
    final authorizationHeader = server.authorizationHeader;
    if (authorizationHeader != null && authorizationHeader.isNotEmpty) {
      headers['Authorization'] = authorizationHeader;
    }

    return Dio(
      BaseOptions(
        baseUrl: server.baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 12),
        sendTimeout: const Duration(seconds: 12),
        headers: headers,
      ),
    );
  }

  ExperienceSettings _readSettings(SharedPreferences prefs) {
    final raw = prefs.getString(AppConstants.experienceSettingsKey);
    if (raw == null || raw.trim().isEmpty) {
      return ExperienceSettings.defaults();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return ExperienceSettings.fromJson(decoded);
      }
      if (decoded is Map) {
        return ExperienceSettings.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // Falls back to defaults.
    }
    return ExperienceSettings.defaults();
  }

  BackgroundAlertSnapshot _readSnapshot(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) {
      return BackgroundAlertSnapshot.empty();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return BackgroundAlertSnapshot.fromJson(decoded);
      }
      if (decoded is Map) {
        return BackgroundAlertSnapshot.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {
      // Falls back to empty snapshot.
    }
    return BackgroundAlertSnapshot.empty();
  }

  String _snapshotStorageKey(String serverId) {
    return _backgroundAlertSnapshotStorageKey(serverId);
  }

  Future<_ResolvedServerConfig?> _resolveServerConfig(
    SharedPreferences prefs,
  ) async {
    final profilesRaw = prefs.getString(AppConstants.serverProfilesKey);
    final activeServerId = prefs.getString(AppConstants.activeServerIdKey);
    final defaultServerId = prefs.getString(AppConstants.defaultServerIdKey);

    if (profilesRaw != null && profilesRaw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(profilesRaw);
        if (decoded is List) {
          final profiles = decoded
              .whereType<Map>()
              .map((item) {
                return Map<String, dynamic>.from(item);
              })
              .toList(growable: false);
          if (profiles.isNotEmpty) {
            final selected = _selectServerProfile(
              profiles: profiles,
              activeServerId: activeServerId,
              defaultServerId: defaultServerId,
            );
            if (selected != null) {
              final baseUrl = selected['url']?.toString().trim() ?? '';
              if (baseUrl.isNotEmpty) {
                final serverId = selected['id']?.toString().trim();
                final basicEnabled = selected['basicAuthEnabled'] == true;
                final legacyUsername =
                    selected['basicAuthUsername']?.toString().trim() ?? '';
                final legacyPassword =
                    selected['basicAuthPassword']?.toString().trim() ?? '';
                final effectiveServerId = (serverId == null || serverId.isEmpty)
                    ? 'profile'
                    : serverId;
                final username = await _resolveProfileCredential(
                  serverId: effectiveServerId,
                  base: AppConstants.secureServerProfileBasicAuthUsernameKey,
                  legacyValue: legacyUsername,
                );
                final password = await _resolveProfileCredential(
                  serverId: effectiveServerId,
                  base: AppConstants.secureServerProfileBasicAuthPasswordKey,
                  legacyValue: legacyPassword,
                );
                return _ResolvedServerConfig(
                  serverId: effectiveServerId,
                  baseUrl: baseUrl,
                  authorizationHeader: basicEnabled
                      ? _buildBasicAuthorizationHeader(
                          username: username,
                          password: password,
                        )
                      : null,
                );
              }
            }
          }
        }
      } catch (_) {
        // Falls back to legacy config.
      }
    }

    final host = prefs.getString(AppConstants.serverHostKey)?.trim();
    final port = prefs.getInt(AppConstants.serverPortKey);
    if (host != null && host.isNotEmpty && port != null) {
      final basicEnabled =
          prefs.getBool(AppConstants.basicAuthEnabledKey) ?? false;
      final username = await _resolveLegacyCredential(
        prefs: prefs,
        base: AppConstants.basicAuthUsernameKey,
      );
      final password = await _resolveLegacyCredential(
        prefs: prefs,
        base: AppConstants.basicAuthPasswordKey,
      );
      return _ResolvedServerConfig(
        serverId: 'legacy',
        baseUrl: 'http://$host:$port',
        authorizationHeader: basicEnabled
            ? _buildBasicAuthorizationHeader(
                username: username,
                password: password,
              )
            : null,
      );
    }

    return null;
  }

  String _serverProfileSecureKey({
    required String serverId,
    required String base,
  }) {
    final encodedServerId = Uri.encodeComponent(serverId.trim());
    return '${AppConstants.secureStorageNamespace}::$base::$encodedServerId';
  }

  String _legacySecureKey(String base) {
    return '${AppConstants.secureStorageNamespace}::$base';
  }

  Future<String> _resolveProfileCredential({
    required String serverId,
    required String base,
    required String legacyValue,
  }) async {
    final secureKey = _serverProfileSecureKey(serverId: serverId, base: base);
    try {
      final secureValue = await _secureStorage.read(key: secureKey);
      if (secureValue != null && secureValue.trim().isNotEmpty) {
        return secureValue;
      }
      if (legacyValue.trim().isEmpty) {
        return '';
      }
      await _secureStorage.write(key: secureKey, value: legacyValue);
      return legacyValue;
    } catch (_) {
      return legacyValue;
    }
  }

  Future<String> _resolveLegacyCredential({
    required SharedPreferences prefs,
    required String base,
  }) async {
    final secureKey = _legacySecureKey(base);
    try {
      final secureValue = await _secureStorage.read(key: secureKey);
      if (secureValue != null && secureValue.trim().isNotEmpty) {
        return secureValue;
      }
      final legacyValue = prefs.getString(base) ?? '';
      if (legacyValue.trim().isNotEmpty) {
        await _secureStorage.write(key: secureKey, value: legacyValue);
      }
      return legacyValue;
    } catch (_) {
      return prefs.getString(base) ?? '';
    }
  }

  Map<String, dynamic>? _selectServerProfile({
    required List<Map<String, dynamic>> profiles,
    required String? activeServerId,
    required String? defaultServerId,
  }) {
    for (final profile in profiles) {
      if (profile['id'] == activeServerId) {
        return profile;
      }
    }
    for (final profile in profiles) {
      if (profile['id'] == defaultServerId) {
        return profile;
      }
    }
    return profiles.first;
  }

  String? _buildBasicAuthorizationHeader({
    required String username,
    required String password,
  }) {
    final trimmedUser = username.trim();
    final trimmedPassword = password.trim();
    if (trimmedUser.isEmpty || trimmedPassword.isEmpty) {
      return null;
    }
    final encoded = base64Encode(utf8.encode('$trimmedUser:$trimmedPassword'));
    return 'Basic $encoded';
  }

  Future<Map<String, String>?> _fetchSessionStatusById(Dio dio) async {
    try {
      final response = await dio.get('/session/status');
      if (response.statusCode != 200) {
        return null;
      }
      final raw = response.data;
      if (raw is! Map) {
        return const <String, String>{};
      }

      final result = <String, String>{};
      raw.forEach((key, value) {
        final sessionId = key.toString().trim();
        if (sessionId.isEmpty || value is! Map) {
          return;
        }
        final status = SessionStatusModel.fromJson(
          Map<String, dynamic>.from(value),
        );
        result[sessionId] = status.type;
      });
      return result;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return const <String, String>{};
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<_SessionMetadata> _fetchSessionMetadata(Dio dio) async {
    try {
      final response = await dio.get('/session');
      if (response.statusCode != 200) {
        return const _SessionMetadata.empty();
      }
      final raw = response.data;
      if (raw is! List) {
        return const _SessionMetadata.empty();
      }

      final titleById = <String, String>{};
      final updatedAtById = <String, int>{};
      for (final item in raw) {
        if (item is! Map) {
          continue;
        }
        final model = ChatSessionModel.fromJson(
          Map<String, dynamic>.from(item),
        );
        final sessionId = model.id.trim();
        if (sessionId.isEmpty) {
          continue;
        }
        final title = model.title?.trim();
        if (title != null && title.isNotEmpty) {
          titleById[sessionId] = title;
        }
        final updatedAt = model.time.updated;
        if (updatedAt > 0) {
          updatedAtById[sessionId] = updatedAt;
        }
      }

      return _SessionMetadata(
        titleBySessionId: titleById,
        updatedAtBySessionId: updatedAtById,
      );
    } catch (_) {
      return const _SessionMetadata.empty();
    }
  }

  Future<List<BackgroundInteractionRequest>> _fetchPermissionRequests(
    Dio dio,
  ) async {
    try {
      final response = await dio.get('/permission');
      if (response.statusCode != 200) {
        return const <BackgroundInteractionRequest>[];
      }
      final raw = response.data;
      if (raw is! List) {
        return const <BackgroundInteractionRequest>[];
      }

      return raw
          .whereType<Map>()
          .map((item) {
            final parsed = ChatPermissionRequestModel.fromJson(
              Map<String, dynamic>.from(item),
            );
            return BackgroundInteractionRequest(
              id: parsed.id,
              sessionId: parsed.sessionId,
            );
          })
          .where((item) {
            return item.id.trim().isNotEmpty &&
                item.sessionId.trim().isNotEmpty;
          })
          .toList(growable: false);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return const <BackgroundInteractionRequest>[];
      }
      return const <BackgroundInteractionRequest>[];
    } catch (_) {
      return const <BackgroundInteractionRequest>[];
    }
  }

  Future<List<BackgroundInteractionRequest>> _fetchQuestionRequests(
    Dio dio,
  ) async {
    try {
      final response = await dio.get('/question');
      if (response.statusCode != 200) {
        return const <BackgroundInteractionRequest>[];
      }
      final raw = response.data;
      if (raw is! List) {
        return const <BackgroundInteractionRequest>[];
      }

      return raw
          .whereType<Map>()
          .map((item) {
            final parsed = ChatQuestionRequestModel.fromJson(
              Map<String, dynamic>.from(item),
            );
            return BackgroundInteractionRequest(
              id: parsed.id,
              sessionId: parsed.sessionId,
            );
          })
          .where((item) {
            return item.id.trim().isNotEmpty &&
                item.sessionId.trim().isNotEmpty;
          })
          .toList(growable: false);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return const <BackgroundInteractionRequest>[];
      }
      return const <BackgroundInteractionRequest>[];
    } catch (_) {
      return const <BackgroundInteractionRequest>[];
    }
  }
}

class _BackgroundNotificationDispatcher {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _notificationsEnabled = true;

  Future<void> show({required BackgroundAlertSignal signal}) async {
    await _ensureInitialized();
    if (!_initialized || !_notificationsEnabled) {
      return;
    }

    final channel = _channelFor(signal.categoryKey);
    final normalizedSessionId = signal.sessionId.trim();
    final hasSessionId = normalizedSessionId.isNotEmpty;
    final payload = NotificationTapPayload(
      category: signal.categoryKey,
      sessionId: hasSessionId ? normalizedSessionId : null,
    ).toRaw();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.highImportance
            ? Importance.high
            : Importance.defaultImportance,
        priority: channel.highImportance
            ? Priority.high
            : Priority.defaultPriority,
        groupKey: hasSessionId ? _sessionGroupKey(normalizedSessionId) : null,
        tag: hasSessionId ? _sessionTag(normalizedSessionId) : null,
      ),
    );

    try {
      await _plugin.show(
        id: _notificationId(signal),
        title: signal.title,
        body: signal.body,
        notificationDetails: details,
        payload: payload,
      );

      if (hasSessionId) {
        await _plugin.show(
          id: _summaryNotificationId(normalizedSessionId),
          title: 'Conversation updates',
          body: 'Open this conversation to clear related notifications.',
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: channel.highImportance
                  ? Importance.high
                  : Importance.defaultImportance,
              priority: channel.highImportance
                  ? Priority.high
                  : Priority.defaultPriority,
              playSound: false,
              groupKey: _sessionGroupKey(normalizedSessionId),
              setAsGroupSummary: true,
              groupAlertBehavior: GroupAlertBehavior.summary,
              tag: _sessionSummaryTag(normalizedSessionId),
            ),
          ),
          payload: payload,
        );
      }
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Failed to dispatch background alert notification',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }
    try {
      const android = AndroidInitializationSettings('@drawable/ic_stat_codewalk');
      const settings = InitializationSettings(android: android);
      await _plugin.initialize(settings: settings);
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      _notificationsEnabled =
          await androidPlugin?.areNotificationsEnabled() ?? true;
      _initialized = true;
    } catch (error, stackTrace) {
      _notificationsEnabled = false;
      AppLogger.warn(
        'Failed to initialize background notification dispatcher',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  int _notificationId(BackgroundAlertSignal signal) {
    final source =
        '${signal.kind.name}:${signal.sessionId}:${DateTime.now().microsecondsSinceEpoch}';
    return source.hashCode & 0x7fffffff;
  }

  int _summaryNotificationId(String sessionId) {
    return ('summary:$sessionId').hashCode & 0x7fffffff;
  }

  String _sessionGroupKey(String sessionId) => 'codewalk.session.$sessionId';
  String _sessionTag(String sessionId) => 'session:$sessionId';
  String _sessionSummaryTag(String sessionId) => 'session-summary:$sessionId';

  _NotificationChannelConfig _channelFor(String categoryKey) {
    return switch (categoryKey) {
      'errors' => const _NotificationChannelConfig(
        id: 'codewalk_errors',
        name: 'CodeWalk errors',
        description: 'CodeWalk error alerts',
        highImportance: true,
      ),
      'permissions' => const _NotificationChannelConfig(
        id: 'codewalk_permissions',
        name: 'CodeWalk permissions',
        description: 'CodeWalk action required alerts',
        highImportance: true,
      ),
      _ => const _NotificationChannelConfig(
        id: 'codewalk_agent',
        name: 'CodeWalk agent',
        description: 'CodeWalk agent completion alerts',
        highImportance: false,
      ),
    };
  }
}

class _ResolvedServerConfig {
  const _ResolvedServerConfig({
    required this.serverId,
    required this.baseUrl,
    required this.authorizationHeader,
  });

  final String serverId;
  final String baseUrl;
  final String? authorizationHeader;
}

class _SessionMetadata {
  const _SessionMetadata({
    required this.titleBySessionId,
    required this.updatedAtBySessionId,
  });

  const _SessionMetadata.empty()
    : titleBySessionId = const <String, String>{},
      updatedAtBySessionId = const <String, int>{};

  final Map<String, String> titleBySessionId;
  final Map<String, int> updatedAtBySessionId;
}

class _NotificationChannelConfig {
  const _NotificationChannelConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.highImportance,
  });

  final String id;
  final String name;
  final String description;
  final bool highImportance;
}

bool _isAndroidRuntime() {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.android;
}

String _backgroundAlertSnapshotStorageKey(String serverId) {
  final normalized = serverId.trim().isEmpty ? 'legacy' : serverId.trim();
  return '$_backgroundAlertSnapshotKeyPrefix::$normalized';
}
