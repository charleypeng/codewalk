import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/dio_client.dart';
import '../../data/datasources/app_local_datasource.dart';
import '../../domain/entities/app_info.dart';
import '../../domain/entities/server_profile.dart';
import '../../domain/usecases/check_connection.dart';
import '../../domain/usecases/get_app_info.dart';
import '../services/local_opencode_server_runtime.dart';
import '../services/local_opencode_server_runtime_types.dart';

enum AppStatus { initial, loading, loaded, error, disconnected }

enum ServerHealthStatus { unknown, healthy, unhealthy }

enum LocalServerRuntimeStatus { stopped, starting, running, stopping, failed }

class AppProvider extends ChangeNotifier {
  AppProvider({
    required GetAppInfo getAppInfo,
    required CheckConnection checkConnection,
    required AppLocalDataSource localDataSource,
    required DioClient dioClient,
    LocalOpencodeServerRuntime? localServerRuntime,
    Future<ServerHealthStatus> Function(String url)? localServerHealthProbe,
    bool enableHealthPolling = true,
  }) : _getAppInfo = getAppInfo,
       _checkConnection = checkConnection,
       _localDataSource = localDataSource,
       _dioClient = dioClient,
       _localServerRuntime =
           localServerRuntime ?? createLocalOpencodeServerRuntime(),
       _localServerHealthProbe = localServerHealthProbe,
       _enableHealthPolling = enableHealthPolling;

  final GetAppInfo _getAppInfo;
  final CheckConnection _checkConnection;
  final AppLocalDataSource _localDataSource;
  final DioClient _dioClient;
  final LocalOpencodeServerRuntime _localServerRuntime;
  final Future<ServerHealthStatus> Function(String url)?
  _localServerHealthProbe;
  final bool _enableHealthPolling;

  AppStatus _status = AppStatus.initial;
  AppInfo? _appInfo;
  String _errorMessage = '';
  String _serverHost = ApiConstants.defaultHost;
  int _serverPort = ApiConstants.defaultPort;
  bool _isConnected = false;
  bool _initialized = false;
  Future<void>? _initFuture;
  Timer? _healthTimer;
  bool _localServerRuntimeBound = false;
  StreamSubscription<String>? _localServerStdoutSubscription;
  StreamSubscription<String>? _localServerStderrSubscription;
  StreamSubscription<int>? _localServerExitSubscription;
  LocalServerRuntimeStatus _localServerStatus =
      LocalServerRuntimeStatus.stopped;
  String _localServerStatusMessage = 'Local server is stopped.';
  String _localServerLastOutput = '';
  String _localServerCommandPath = '';
  LocalOpencodeEnvironmentReport? _localEnvironmentReport;
  bool _localSetupInProgress = false;
  String _localSetupMessage =
      'Run diagnostics to verify local OpenCode requirements.';
  List<String> _localSetupLogs = <String>[];
  final String _localServerHost = ApiConstants.defaultHost;
  final int _localServerPort = ApiConstants.defaultPort;
  bool _localServerStoppingByRequest = false;

  List<ServerProfile> _serverProfiles = <ServerProfile>[];
  String? _activeServerId;
  String? _defaultServerId;
  final Map<String, ServerHealthStatus> _serverHealthById =
      <String, ServerHealthStatus>{};
  bool _healthCheckInFlight = false;
  bool _queuedHealthRefreshAll = false;
  final Set<String> _queuedHealthServerIds = <String>{};

  AppStatus get status => _status;
  AppInfo? get appInfo => _appInfo;
  String get errorMessage => _errorMessage;
  String get serverHost => _serverHost;
  int get serverPort => _serverPort;
  bool get isConnected => _isConnected;
  bool get initialized => _initialized;
  String get serverUrl => 'http://$_serverHost:$_serverPort';
  bool get localServerSupported => _localServerRuntime.isSupported;
  LocalServerRuntimeStatus get localServerStatus => _localServerStatus;
  String get localServerStatusMessage => _localServerStatusMessage;
  String get localServerLastOutput => _localServerLastOutput;
  String get localServerUrl => 'http://$_localServerHost:$_localServerPort';
  String get localServerCommandPath => _localServerCommandPath;
  LocalOpencodeEnvironmentReport? get localEnvironmentReport =>
      _localEnvironmentReport;
  bool get localSetupInProgress => _localSetupInProgress;
  String get localSetupMessage => _localSetupMessage;
  List<String> get localSetupLogs => List<String>.unmodifiable(_localSetupLogs);
  List<ServerProfile> get serverProfiles =>
      List<ServerProfile>.unmodifiable(_serverProfiles);
  String? get activeServerId => _activeServerId;
  String? get defaultServerId => _defaultServerId;
  ServerProfile? get activeServer => _findById(_activeServerId);

  ServerHealthStatus healthFor(String serverId) {
    return _serverHealthById[serverId] ?? ServerHealthStatus.unknown;
  }

  static String normalizeServerUrl(
    String rawUrl, {
    int fallbackPort = ApiConstants.defaultPort,
  }) {
    var normalized = rawUrl.trim();
    if (normalized.isEmpty) {
      throw const FormatException('Server URL is required');
    }

    if (!normalized.contains('://')) {
      normalized = 'http://$normalized';
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.isEmpty) {
      throw const FormatException('Invalid server URL');
    }

    final scheme = uri.scheme.isEmpty ? 'http' : uri.scheme.toLowerCase();
    final port = uri.hasPort
        ? uri.port
        : (scheme == 'https' ? 443 : fallbackPort);

    final compact = Uri(scheme: scheme, host: uri.host, port: port).toString();
    return compact.endsWith('/')
        ? compact.substring(0, compact.length - 1)
        : compact;
  }

  Future<void> initialize() async {
    _initFuture ??= _initializeInternal();
    await _initFuture;
  }

  Future<void> _initializeInternal() async {
    await _loadServerProfiles();
    await _ensureActiveSelection();
    await _loadLocalServerCommandConfig();
    _applyActiveServerToClient();
    _bindLocalServerRuntimeEvents();
    _initialized = true;
    unawaited(refreshServerHealth());
    unawaited(runLocalServerDiagnostics(notify: false));
    if (_enableHealthPolling) {
      _startHealthPolling();
    }
    notifyListeners();
  }

  Future<void> _loadServerProfiles() async {
    final raw = await _localDataSource.getServerProfilesJson();
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final parsed = <ServerProfile>[];
          for (final item in decoded) {
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              parsed.add(ServerProfile.fromJson(map));
            }
          }
          _serverProfiles = parsed
              .where((p) => p.id.isNotEmpty && p.url.isNotEmpty)
              .toList();
        }
      } catch (e, stackTrace) {
        AppLogger.warn(
          'Failed to decode stored server profiles; falling back to migration',
          error: e,
          stackTrace: stackTrace,
        );
        _serverProfiles = <ServerProfile>[];
      }
    }

    if (_serverProfiles.isEmpty) {
      await _migrateLegacySingleServer();
    }

    _activeServerId = await _localDataSource.getActiveServerId();
    _defaultServerId = await _localDataSource.getDefaultServerId();
  }

  Future<void> _migrateLegacySingleServer() async {
    final oldHost = await _localDataSource.getServerHost();
    final oldPort = await _localDataSource.getServerPort();
    final oldBasicEnabled = await _localDataSource.getBasicAuthEnabled();
    final oldBasicUser = await _localDataSource.getBasicAuthUsername();
    final oldBasicPassword = await _localDataSource.getBasicAuthPassword();

    final hasLegacyHost = oldHost != null && oldHost.trim().isNotEmpty;
    final hasLegacyPort = oldPort != null;
    final hasLegacyAuth =
        (oldBasicEnabled ?? false) ||
        (oldBasicUser != null && oldBasicUser.trim().isNotEmpty) ||
        (oldBasicPassword != null && oldBasicPassword.trim().isNotEmpty);
    if (!hasLegacyHost && !hasLegacyPort && !hasLegacyAuth) {
      _serverProfiles = <ServerProfile>[];
      return;
    }

    final host = (oldHost == null || oldHost.trim().isEmpty)
        ? ApiConstants.defaultHost
        : oldHost.trim();
    final port = oldPort ?? ApiConstants.defaultPort;
    final now = DateTime.now().millisecondsSinceEpoch;

    final profile = ServerProfile(
      id: _generateServerId(),
      url: normalizeServerUrl('$host:$port', fallbackPort: port),
      label: 'Primary server',
      basicAuthEnabled: oldBasicEnabled ?? false,
      basicAuthUsername: oldBasicUser ?? '',
      basicAuthPassword: oldBasicPassword ?? '',
      aiGeneratedTitlesEnabled: true,
      createdAt: now,
      updatedAt: now,
    );
    _serverProfiles = <ServerProfile>[profile];
    _activeServerId = profile.id;
    _defaultServerId = profile.id;
    await _persistServerProfiles();
  }

  Future<void> _ensureActiveSelection() async {
    if (_serverProfiles.isEmpty) {
      _activeServerId = null;
      _defaultServerId = null;
      await _localDataSource.saveDefaultServerId(null);
      return;
    }

    final activeExists = _findById(_activeServerId) != null;
    if (!activeExists) {
      _activeServerId =
          (_findById(_defaultServerId)?.id ?? _serverProfiles.first.id);
    }

    if (_defaultServerId != null && _findById(_defaultServerId) == null) {
      _defaultServerId = _activeServerId;
    }

    if (_activeServerId != null) {
      await _localDataSource.saveActiveServerId(_activeServerId!);
    }
    await _localDataSource.saveDefaultServerId(_defaultServerId);
  }

  ServerProfile? _findById(String? serverId) {
    if (serverId == null) {
      return null;
    }
    for (final profile in _serverProfiles) {
      if (profile.id == serverId) {
        return profile;
      }
    }
    return null;
  }

  Future<void> _persistServerProfiles() async {
    final encoded = jsonEncode(_serverProfiles.map((p) => p.toJson()).toList());
    await _localDataSource.saveServerProfilesJson(encoded);
    if (_activeServerId != null) {
      await _localDataSource.saveActiveServerId(_activeServerId!);
    }
    await _localDataSource.saveDefaultServerId(_defaultServerId);
  }

  void _applyActiveServerToClient() {
    final profile = activeServer;
    if (profile == null) {
      _dioClient.clearAuth();
      _serverHost = ApiConstants.defaultHost;
      _serverPort = ApiConstants.defaultPort;
      return;
    }
    _dioClient.updateBaseUrl(profile.url);
    if (profile.basicAuthEnabled &&
        profile.basicAuthUsername.trim().isNotEmpty &&
        profile.basicAuthPassword.trim().isNotEmpty) {
      _dioClient.setBasicAuth(
        profile.basicAuthUsername.trim(),
        profile.basicAuthPassword.trim(),
      );
    } else {
      _dioClient.clearAuth();
    }

    final uri = Uri.tryParse(profile.url);
    if (uri != null) {
      _serverHost = uri.host;
      _serverPort = uri.hasPort ? uri.port : ApiConstants.defaultPort;
    }
  }

  Future<bool> addServerProfile({
    required String url,
    String? label,
    bool basicAuthEnabled = false,
    String basicAuthUsername = '',
    String basicAuthPassword = '',
    bool aiGeneratedTitlesEnabled = true,
    bool setAsActive = false,
  }) async {
    await initialize();
    final normalized = _safeNormalize(url);
    if (normalized == null) {
      _setError('Invalid server URL');
      return false;
    }

    if (_serverProfiles.any((p) => p.url == normalized)) {
      _setError('A server with this URL already exists');
      return false;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final profile = ServerProfile(
      id: _generateServerId(),
      url: normalized,
      label: label?.trim().isEmpty ?? true ? null : label!.trim(),
      basicAuthEnabled: basicAuthEnabled,
      basicAuthUsername: basicAuthUsername.trim(),
      basicAuthPassword: basicAuthPassword.trim(),
      aiGeneratedTitlesEnabled: aiGeneratedTitlesEnabled,
      createdAt: now,
      updatedAt: now,
    );
    _serverProfiles = <ServerProfile>[..._serverProfiles, profile];
    _defaultServerId ??= profile.id;
    if (_activeServerId == null || setAsActive) {
      _activeServerId = profile.id;
    }
    await _persistServerProfiles();
    _applyActiveServerToClient();
    await refreshServerHealth(serverId: profile.id);
    _errorMessage = '';
    notifyListeners();
    return true;
  }

  Future<bool> updateServerProfile({
    required String id,
    required String url,
    String? label,
    required bool basicAuthEnabled,
    required String basicAuthUsername,
    required String basicAuthPassword,
    required bool aiGeneratedTitlesEnabled,
  }) async {
    await initialize();
    final index = _serverProfiles.indexWhere((p) => p.id == id);
    if (index == -1) {
      _setError('Server profile not found');
      return false;
    }

    final normalized = _safeNormalize(url);
    if (normalized == null) {
      _setError('Invalid server URL');
      return false;
    }

    final duplicate = _serverProfiles.any(
      (p) => p.id != id && p.url == normalized,
    );
    if (duplicate) {
      _setError('A server with this URL already exists');
      return false;
    }

    final previous = _serverProfiles[index];
    final updated = previous.copyWith(
      url: normalized,
      label: label?.trim().isEmpty ?? true ? null : label!.trim(),
      basicAuthEnabled: basicAuthEnabled,
      basicAuthUsername: basicAuthUsername.trim(),
      basicAuthPassword: basicAuthPassword.trim(),
      aiGeneratedTitlesEnabled: aiGeneratedTitlesEnabled,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    final copied = List<ServerProfile>.from(_serverProfiles);
    copied[index] = updated;
    _serverProfiles = copied;

    await _persistServerProfiles();
    if (_activeServerId == updated.id) {
      _applyActiveServerToClient();
      await checkConnection();
    }
    await refreshServerHealth(serverId: updated.id);
    _errorMessage = '';
    notifyListeners();
    return true;
  }

  Future<bool> removeServerProfile(String id) async {
    await initialize();
    final exists = _serverProfiles.any((p) => p.id == id);
    if (!exists) {
      _setError('Server profile not found');
      return false;
    }

    _serverProfiles = _serverProfiles.where((p) => p.id != id).toList();
    _serverHealthById.remove(id);

    if (_serverProfiles.isEmpty) {
      _activeServerId = null;
      _defaultServerId = null;
      _isConnected = false;
      _appInfo = null;
      _applyActiveServerToClient();
      await _persistServerProfiles();
      _errorMessage = '';
      notifyListeners();
      return true;
    }

    if (_defaultServerId == id) {
      _defaultServerId = _serverProfiles.first.id;
    }

    if (_activeServerId == id) {
      _activeServerId =
          (_findById(_defaultServerId)?.id ?? _serverProfiles.first.id);
      _applyActiveServerToClient();
      await checkConnection();
    }

    await _persistServerProfiles();
    _errorMessage = '';
    notifyListeners();
    return true;
  }

  Future<bool> setDefaultServer(String id) async {
    await initialize();
    if (_findById(id) == null) {
      _setError('Server profile not found');
      return false;
    }
    _defaultServerId = id;
    await _localDataSource.saveDefaultServerId(id);
    _errorMessage = '';
    notifyListeners();
    return true;
  }

  Future<bool> clearDefaultServer() async {
    await initialize();
    _defaultServerId = null;
    await _localDataSource.saveDefaultServerId(null);
    notifyListeners();
    return true;
  }

  Future<bool> setActiveServer(String id, {bool blockUnhealthy = true}) async {
    await initialize();
    final profile = _findById(id);
    if (profile == null) {
      _setError('Server profile not found');
      return false;
    }

    final health = healthFor(id);
    if (blockUnhealthy && health == ServerHealthStatus.unhealthy) {
      _setError('Cannot activate an unhealthy server');
      return false;
    }

    _activeServerId = id;
    await _localDataSource.saveActiveServerId(id);
    _applyActiveServerToClient();
    _isConnected = false;
    _appInfo = null;
    _errorMessage = '';
    notifyListeners();

    await checkConnection();
    return true;
  }

  Future<void> _loadLocalServerCommandConfig() async {
    final stored = await _localDataSource.getLocalOpencodeCommand();
    _localServerCommandPath = stored?.trim() ?? '';
  }

  Future<LocalOpencodeEnvironmentReport> runLocalServerDiagnostics({
    bool notify = true,
  }) async {
    final report = await _localServerRuntime.diagnose(
      commandPath: _localServerCommandPath.trim().isEmpty
          ? null
          : _localServerCommandPath,
    );
    _localEnvironmentReport = report;

    if (report.opencode.available &&
        _localServerCommandPath.trim().isEmpty &&
        report.opencode.path.trim().isNotEmpty) {
      await _setLocalServerCommandPath(report.opencode.path.trim());
    }

    if (!_localSetupInProgress) {
      _localSetupMessage = report.recommendation;
    }
    if (notify) {
      notifyListeners();
    }
    return report;
  }

  Future<bool> useDetectedLocalServerCommand() async {
    await initialize();
    _localSetupInProgress = true;
    _localSetupLogs = <String>[];
    _localSetupMessage = 'Detecting OpenCode command...';
    _errorMessage = '';
    notifyListeners();

    final report = await _localServerRuntime.diagnose(
      commandPath: _localServerCommandPath.trim().isEmpty
          ? null
          : _localServerCommandPath,
    );
    _localEnvironmentReport = report;

    if (!report.opencode.available || report.opencode.path.trim().isEmpty) {
      const message =
          'OpenCode command was not detected. Run installation from the wizard.';
      _localSetupInProgress = false;
      _localSetupMessage = message;
      _setError(message);
      return false;
    }

    await _setLocalServerCommandPath(report.opencode.path.trim());
    _localSetupInProgress = false;
    _localSetupMessage = 'Using OpenCode command at ${report.opencode.path}';
    _errorMessage = '';
    notifyListeners();
    return true;
  }

  Future<bool> installLocalServerRequirements(
    LocalOpencodeInstallMethod method,
  ) async {
    await initialize();
    if (!_localServerRuntime.isSupported) {
      _setError('Managed local server is available only on desktop.');
      return false;
    }

    _localSetupInProgress = true;
    _localSetupLogs = <String>[];
    _localSetupMessage = 'Installing OpenCode requirements...';
    _errorMessage = '';
    notifyListeners();

    final result = await _localServerRuntime.install(
      method: method,
      onLog: _appendLocalSetupLog,
    );
    if (!result.ok) {
      final message = result.errorMessage?.trim().isNotEmpty == true
          ? result.errorMessage!.trim()
          : 'OpenCode installation failed.';
      _localSetupInProgress = false;
      _localSetupMessage = message;
      _setError(message);
      return false;
    }

    if (result.commandPath?.trim().isNotEmpty == true) {
      await _setLocalServerCommandPath(result.commandPath!.trim());
    }

    await runLocalServerDiagnostics(notify: false);
    _localSetupInProgress = false;
    _localSetupMessage = 'OpenCode requirements installed successfully.';
    _errorMessage = '';
    notifyListeners();
    return true;
  }

  void clearLocalSetupLogs() {
    _localSetupLogs = <String>[];
    notifyListeners();
  }

  void _appendLocalSetupLog(String line) {
    final value = line.trim();
    if (value.isEmpty) {
      return;
    }
    const maxLines = 120;
    _localSetupLogs = <String>[..._localSetupLogs, value];
    if (_localSetupLogs.length > maxLines) {
      _localSetupLogs = _localSetupLogs.sublist(
        _localSetupLogs.length - maxLines,
      );
    }
    notifyListeners();
  }

  Future<void> _setLocalServerCommandPath(String? path) async {
    final normalized = path?.trim() ?? '';
    _localServerCommandPath = normalized;
    await _localDataSource.saveLocalOpencodeCommand(
      normalized.isEmpty ? null : normalized,
    );
  }

  Future<bool> startLocalServer() async {
    await initialize();
    if (!_localServerRuntime.isSupported) {
      _setError('Managed local server is available only on desktop.');
      return false;
    }
    if (_localServerStatus == LocalServerRuntimeStatus.running ||
        _localServerStatus == LocalServerRuntimeStatus.starting) {
      return true;
    }

    _localServerStoppingByRequest = false;
    _localServerStatus = LocalServerRuntimeStatus.starting;
    _localServerStatusMessage = 'Starting local server...';
    _localServerLastOutput = '';
    _errorMessage = '';
    notifyListeners();

    if (_localServerCommandPath.trim().isEmpty) {
      await runLocalServerDiagnostics(notify: false);
    }

    final startResult = await _localServerRuntime.start(
      host: _localServerHost,
      port: _localServerPort,
      commandPath: _localServerCommandPath.trim().isEmpty
          ? null
          : _localServerCommandPath,
    );
    if (!startResult.ok) {
      final details = startResult.errorMessage?.trim();
      final message = details != null && details.isNotEmpty
          ? details
          : 'Failed to start local OpenCode server.';
      _localServerStatus = LocalServerRuntimeStatus.failed;
      _localServerStatusMessage = message;
      _setError(message);
      return false;
    }

    final healthy = await _waitForLocalServerHealth();
    if (!healthy) {
      const message = 'Local server started but health check did not pass.';
      _localServerStatus = LocalServerRuntimeStatus.failed;
      _localServerStatusMessage = message;
      await _localServerRuntime.stop();
      _setError(message);
      return false;
    }

    await _ensureLocalServerProfileActive();

    _localServerStatus = LocalServerRuntimeStatus.running;
    _localServerStatusMessage = 'Running at $localServerUrl';
    _errorMessage = '';
    notifyListeners();
    return true;
  }

  Future<bool> stopLocalServer() async {
    await initialize();
    if (_localServerStatus == LocalServerRuntimeStatus.stopped) {
      return true;
    }

    _localServerStoppingByRequest = true;
    _localServerStatus = LocalServerRuntimeStatus.stopping;
    _localServerStatusMessage = 'Stopping local server...';
    _errorMessage = '';
    notifyListeners();

    await _localServerRuntime.stop();
    if (_localServerStatus == LocalServerRuntimeStatus.stopping) {
      _localServerStatus = LocalServerRuntimeStatus.stopped;
      _localServerStatusMessage = 'Local server is stopped.';
      _localServerStoppingByRequest = false;
      notifyListeners();
    }

    unawaited(refreshServerHealth());
    return true;
  }

  void _bindLocalServerRuntimeEvents() {
    if (_localServerRuntimeBound) {
      return;
    }
    _localServerRuntimeBound = true;
    _localServerStdoutSubscription = _localServerRuntime.stdoutLines.listen(
      _handleLocalServerOutput,
    );
    _localServerStderrSubscription = _localServerRuntime.stderrLines.listen(
      _handleLocalServerOutput,
    );
    _localServerExitSubscription = _localServerRuntime.exitCodes.listen(
      _handleLocalServerExit,
    );
  }

  void _handleLocalServerOutput(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _localServerLastOutput = trimmed;
    notifyListeners();
  }

  void _handleLocalServerExit(int code) {
    if (_localServerStoppingByRequest) {
      _localServerStoppingByRequest = false;
      _localServerStatus = LocalServerRuntimeStatus.stopped;
      _localServerStatusMessage = 'Local server is stopped.';
      notifyListeners();
      unawaited(refreshServerHealth());
      return;
    }
    if (_localServerStatus == LocalServerRuntimeStatus.stopped) {
      return;
    }

    _localServerStatus = LocalServerRuntimeStatus.failed;
    _localServerStatusMessage = 'Local server exited with code $code.';
    notifyListeners();
    unawaited(refreshServerHealth());
  }

  Future<bool> _waitForLocalServerHealth({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final startedAt = DateTime.now();
    while (DateTime.now().difference(startedAt) < timeout) {
      final health = await _probeLocalServerHealth();
      if (health == ServerHealthStatus.healthy) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    return false;
  }

  Future<ServerHealthStatus> _probeLocalServerHealth() async {
    final normalizedUrl = normalizeServerUrl(
      '$_localServerHost:$_localServerPort',
      fallbackPort: _localServerPort,
    );
    final localServerHealthProbe = _localServerHealthProbe;
    if (localServerHealthProbe != null) {
      return localServerHealthProbe(normalizedUrl);
    }

    final probeProfile = ServerProfile(
      id: '_local_server_probe',
      url: normalizedUrl,
      createdAt: 0,
      updatedAt: 0,
    );
    return _checkServerHealth(probeProfile);
  }

  Future<void> _ensureLocalServerProfileActive() async {
    final normalizedUrl = normalizeServerUrl(
      '$_localServerHost:$_localServerPort',
      fallbackPort: _localServerPort,
    );

    ServerProfile? existing;
    for (final profile in _serverProfiles) {
      if (profile.url == normalizedUrl) {
        existing = profile;
        break;
      }
    }

    if (existing == null) {
      await addServerProfile(
        url: normalizedUrl,
        label: 'Local OpenCode (Managed)',
        setAsActive: true,
      );
      return;
    }

    await refreshServerHealth(serverId: existing.id);
    await setActiveServer(existing.id, blockUnhealthy: false);
  }

  Future<void> refreshServerHealth({String? serverId}) async {
    await initialize();
    final normalizedServerId = serverId?.trim();

    if (_healthCheckInFlight) {
      _queueHealthRefresh(serverId: normalizedServerId);
      return;
    }

    _healthCheckInFlight = true;
    var runAll = normalizedServerId == null || normalizedServerId.isEmpty;
    var runServerIds = <String>{};
    if (!runAll) {
      runServerIds = <String>{normalizedServerId};
    }

    try {
      while (true) {
        await _refreshServerHealthTargets(
          runAll: runAll,
          serverIds: runServerIds,
        );

        if (_queuedHealthRefreshAll) {
          _queuedHealthRefreshAll = false;
          _queuedHealthServerIds.clear();
          runAll = true;
          runServerIds = <String>{};
          continue;
        }

        if (_queuedHealthServerIds.isNotEmpty) {
          runAll = false;
          runServerIds = Set<String>.from(_queuedHealthServerIds);
          _queuedHealthServerIds.clear();
          continue;
        }

        break;
      }
    } finally {
      _healthCheckInFlight = false;
      _queuedHealthRefreshAll = false;
      _queuedHealthServerIds.clear();
    }
  }

  void _queueHealthRefresh({String? serverId}) {
    final normalizedServerId = serverId?.trim();
    if (normalizedServerId == null || normalizedServerId.isEmpty) {
      _queuedHealthRefreshAll = true;
      _queuedHealthServerIds.clear();
      return;
    }
    if (_queuedHealthRefreshAll) {
      return;
    }
    _queuedHealthServerIds.add(normalizedServerId);
  }

  Future<void> _refreshServerHealthTargets({
    required bool runAll,
    required Set<String> serverIds,
  }) async {
    final targets = runAll
        ? List<ServerProfile>.from(_serverProfiles)
        : _serverProfiles.where((p) => serverIds.contains(p.id)).toList();
    if (targets.isEmpty) {
      return;
    }

    for (final profile in targets) {
      _serverHealthById[profile.id] = await _checkServerHealth(profile);
    }
    notifyListeners();
  }

  Future<ServerHealthStatus> _checkServerHealth(ServerProfile profile) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: profile.url,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
        sendTimeout: const Duration(seconds: 3),
      ),
    );

    if (profile.basicAuthEnabled &&
        profile.basicAuthUsername.trim().isNotEmpty &&
        profile.basicAuthPassword.trim().isNotEmpty) {
      final auth = base64Encode(
        utf8.encode(
          '${profile.basicAuthUsername.trim()}:${profile.basicAuthPassword.trim()}',
        ),
      );
      dio.options.headers[ApiConstants.authorization] = 'Basic $auth';
    }

    try {
      final global = await dio.get('/global/health');
      if (global.statusCode == 200) {
        return ServerHealthStatus.healthy;
      }
    } catch (_) {
      // Fallback below.
    }

    try {
      final fallback = await dio.get('/path');
      if (fallback.statusCode == 200) {
        return ServerHealthStatus.healthy;
      }
      return ServerHealthStatus.unhealthy;
    } catch (_) {
      return ServerHealthStatus.unhealthy;
    }
  }

  Future<void> getAppInfo({String? directory}) async {
    await initialize();
    _setStatus(AppStatus.loading);

    final result = await _getAppInfo(directory: directory);
    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setStatus(AppStatus.error);
        _isConnected = false;
      },
      (appInfo) {
        _appInfo = appInfo;
        _setStatus(AppStatus.loaded);
        _isConnected = true;
        _errorMessage = '';
      },
    );

    notifyListeners();
  }

  Future<void> checkConnection({String? directory}) async {
    await initialize();
    final result = await _checkConnection(directory: directory);
    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isConnected = false;
      },
      (connected) {
        _isConnected = connected;
        if (connected) {
          _errorMessage = '';
        }
      },
    );
    notifyListeners();
  }

  Future<bool> updateServerConfig(String host, int port) async {
    await initialize();
    final current = activeServer;
    if (current != null) {
      return updateServerProfile(
        id: current.id,
        url: '$host:$port',
        label: current.label,
        basicAuthEnabled: current.basicAuthEnabled,
        basicAuthUsername: current.basicAuthUsername,
        basicAuthPassword: current.basicAuthPassword,
        aiGeneratedTitlesEnabled: current.aiGeneratedTitlesEnabled,
      );
    }

    final created = await addServerProfile(
      url: '$host:$port',
      label: 'Primary server',
      setAsActive: true,
    );
    if (created) {
      _serverHost = host;
      _serverPort = port;
      _errorMessage = '';
      notifyListeners();
    }
    return created;
  }

  void setServerConfig(String host, int port) {
    _serverHost = host;
    _serverPort = port;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  void reset() {
    _status = AppStatus.initial;
    _appInfo = null;
    _errorMessage = '';
    _isConnected = false;
    notifyListeners();
  }

  @visibleForTesting
  void setHealthForTesting(String serverId, ServerHealthStatus status) {
    _serverHealthById[serverId] = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _healthTimer?.cancel();
    _localServerStdoutSubscription?.cancel();
    _localServerStderrSubscription?.cancel();
    _localServerExitSubscription?.cancel();
    unawaited(_localServerRuntime.dispose());
    super.dispose();
  }

  void _startHealthPolling() {
    _healthTimer?.cancel();
    _healthTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      unawaited(refreshServerHealth());
    });
  }

  void _setStatus(AppStatus status) {
    _status = status;
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  String _generateServerId() {
    final epoch = DateTime.now().microsecondsSinceEpoch;
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    return 'srv_${epoch}_$random';
  }

  String? _safeNormalize(String value) {
    try {
      return normalizeServerUrl(value);
    } catch (_) {
      return null;
    }
  }
}
