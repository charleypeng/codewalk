import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/feature_flags.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/entities/experience_settings.dart';

enum DataSaverTransport { unknown, offline, cellular, other }

class CellularDataSaverService extends ChangeNotifier
    with WidgetsBindingObserver {
  CellularDataSaverService({
    required SharedPreferences sharedPreferences,
    Connectivity? connectivity,
    this.automaticSyncInterval = const Duration(minutes: 1),
    bool startMonitoring = true,
  }) : _sharedPreferences = sharedPreferences,
       _connectivity = connectivity ?? Connectivity(),
       _disabled = false {
    _bootstrapFromPrefs();
    if (!startMonitoring) {
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    _connectivitySubscription = _connectivity!.onConnectivityChanged.listen(
      (results) => _applyConnectivityResults(results, reason: 'stream'),
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.warn(
          'Failed to observe connectivity changes for data saver',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
    unawaited(refreshTransport(reason: 'startup'));
  }

  CellularDataSaverService.disabled()
    : _sharedPreferences = null,
      _connectivity = null,
      automaticSyncInterval = const Duration(minutes: 1),
      _disabled = true;

  static const String persistedTransportKey =
      'codewalk.cellular_data_saver.transport.v1';

  final SharedPreferences? _sharedPreferences;
  final Connectivity? _connectivity;
  final bool _disabled;
  final Duration automaticSyncInterval;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _interactiveBurstTimer;
  DataSaverTransport _transport = DataSaverTransport.unknown;
  bool _dataSaverEnabled = ExperienceSettings.defaults().dataSaverEnabled;
  bool _appInForeground = true;
  DateTime? _lastAutomaticSyncAt;
  DateTime? _interactiveBurstUntil;

  bool get dataSaverEnabled => _dataSaverEnabled;
  bool get isForeground => _appInForeground;
  DataSaverTransport get transport => _transport;
  bool get isCellularConnection => _transport == DataSaverTransport.cellular;
  bool get isDataSaverActive =>
      FeatureFlags.cellularDataSaver &&
      _dataSaverEnabled &&
      isCellularConnection;
  bool get shouldDisableBackgroundNetworkTasks =>
      FeatureFlags.cellularDataSaver &&
      _dataSaverEnabled &&
      isCellularConnection;
  bool get shouldSuppressBackgroundWork =>
      shouldDisableBackgroundNetworkTasks && !_appInForeground;
  bool get shouldThrottleAutomaticForegroundSync =>
      isDataSaverActive && _appInForeground;

  bool get hasInteractiveBurst {
    final until = _interactiveBurstUntil;
    if (until == null) {
      return false;
    }
    return DateTime.now().isBefore(until);
  }

  Duration? get automaticSyncCooldownRemaining {
    if (!shouldThrottleAutomaticForegroundSync) {
      return null;
    }
    final last = _lastAutomaticSyncAt;
    if (last == null) {
      return Duration.zero;
    }
    final elapsed = DateTime.now().difference(last);
    if (elapsed >= automaticSyncInterval) {
      return Duration.zero;
    }
    return automaticSyncInterval - elapsed;
  }

  static DataSaverTransport readPersistedTransport(SharedPreferences prefs) {
    return _transportFromPersistedKey(prefs.getString(persistedTransportKey));
  }

  static DataSaverTransport transportFromConnectivityResults(
    Iterable<ConnectivityResult> results,
  ) {
    final normalized = results.toSet();
    if (normalized.isEmpty || normalized.contains(ConnectivityResult.none)) {
      return normalized.length == 1 &&
              normalized.contains(ConnectivityResult.none)
          ? DataSaverTransport.offline
          : DataSaverTransport.unknown;
    }
    if (normalized.contains(ConnectivityResult.mobile)) {
      return DataSaverTransport.cellular;
    }
    return DataSaverTransport.other;
  }

  Future<void> refreshTransport({required String reason}) async {
    if (_disabled || _connectivity == null) {
      return;
    }
    try {
      final results = await _connectivity.checkConnectivity();
      _applyConnectivityResults(results, reason: reason);
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Failed to refresh connectivity for data saver',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void setDataSaverEnabled(bool enabled) {
    if (_disabled || _dataSaverEnabled == enabled) {
      return;
    }
    _dataSaverEnabled = enabled;
    if (!enabled) {
      _interactiveBurstTimer?.cancel();
      _interactiveBurstTimer = null;
      _interactiveBurstUntil = null;
    }
    AppLogger.info(
      'data_saver_enabled value=$enabled transport=${_transport.name}',
    );
    notifyListeners();
  }

  bool allowAutomaticForegroundSync({required String reason}) {
    if (_disabled || !shouldThrottleAutomaticForegroundSync) {
      return true;
    }
    final now = DateTime.now();
    final last = _lastAutomaticSyncAt;
    if (last != null && now.difference(last) < automaticSyncInterval) {
      AppLogger.debug(
        'data_saver_auto_sync_skipped reason=$reason remaining_ms=${automaticSyncInterval.inMilliseconds - now.difference(last).inMilliseconds}',
      );
      return false;
    }
    _lastAutomaticSyncAt = now;
    AppLogger.info('data_saver_auto_sync_allowed reason=$reason');
    return true;
  }

  void noteExplicitUserAction({
    required String reason,
    Duration? burstDuration,
  }) {
    if (_disabled) {
      return;
    }
    _lastAutomaticSyncAt = DateTime.now();
    if (!isDataSaverActive) {
      return;
    }
    final duration = burstDuration ?? automaticSyncInterval;
    _interactiveBurstUntil = DateTime.now().add(duration);
    _interactiveBurstTimer?.cancel();
    _interactiveBurstTimer = Timer(duration, () {
      _interactiveBurstTimer = null;
      _interactiveBurstUntil = null;
      AppLogger.info('data_saver_interactive_burst_expired');
      notifyListeners();
    });
    AppLogger.info(
      'data_saver_interactive_burst_started reason=$reason duration_s=${duration.inSeconds}',
    );
    notifyListeners();
  }

  void setAppForeground(bool isForeground) {
    if (_disabled || _appInForeground == isForeground) {
      return;
    }
    _appInForeground = isForeground;
    if (!isForeground) {
      _interactiveBurstTimer?.cancel();
      _interactiveBurstTimer = null;
      _interactiveBurstUntil = null;
    }
    AppLogger.info(
      'data_saver_foreground_changed foreground=$_appInForeground transport=${_transport.name}',
    );
    notifyListeners();
  }

  @visibleForTesting
  void debugSetTransport(DataSaverTransport transport) {
    _transport = transport;
    notifyListeners();
  }

  @visibleForTesting
  void debugSetAppInForeground(bool isForeground) {
    _appInForeground = isForeground;
    notifyListeners();
  }

  @visibleForTesting
  void debugSetDataSaverEnabled(bool enabled) {
    _dataSaverEnabled = enabled;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setAppForeground(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    if (!_disabled) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _interactiveBurstTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _bootstrapFromPrefs() {
    final prefs = _sharedPreferences;
    if (prefs == null) {
      return;
    }
    _transport = readPersistedTransport(prefs);
    final rawSettings = prefs.getString(AppConstants.experienceSettingsKey);
    if (rawSettings == null || rawSettings.trim().isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(rawSettings);
      if (decoded is Map<String, dynamic>) {
        _dataSaverEnabled = ExperienceSettings.fromJson(
          decoded,
        ).dataSaverEnabled;
      } else if (decoded is Map) {
        _dataSaverEnabled = ExperienceSettings.fromJson(
          Map<String, dynamic>.from(decoded),
        ).dataSaverEnabled;
      }
    } catch (_) {
      // Falls back to defaults when persisted settings are malformed.
    }
  }

  void _applyConnectivityResults(
    List<ConnectivityResult> results, {
    required String reason,
  }) {
    final nextTransport = transportFromConnectivityResults(results);
    if (_transport == nextTransport) {
      return;
    }
    _transport = nextTransport;
    final prefs = _sharedPreferences;
    if (prefs != null) {
      unawaited(prefs.setString(persistedTransportKey, _transport.name));
    }
    AppLogger.info(
      'data_saver_transport_changed reason=$reason transport=${_transport.name}',
    );
    notifyListeners();
  }

  static DataSaverTransport _transportFromPersistedKey(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'offline' => DataSaverTransport.offline,
      'cellular' => DataSaverTransport.cellular,
      'other' => DataSaverTransport.other,
      _ => DataSaverTransport.unknown,
    };
  }
}
