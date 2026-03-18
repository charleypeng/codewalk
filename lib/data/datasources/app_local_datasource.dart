import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../cache/chat_cache_payload_store.dart';

/// Technical comment translated to English.
abstract class AppLocalDataSource {
  /// Technical comment translated to English.
  Future<String?> getServerHost();

  /// Technical comment translated to English.
  Future<void> saveServerHost(String host);

  /// Technical comment translated to English.
  Future<int?> getServerPort();

  /// Technical comment translated to English.
  Future<void> saveServerPort(int port);

  /// Technical comment translated to English.
  Future<String?> getServerProfilesJson();

  /// Technical comment translated to English.
  Future<void> saveServerProfilesJson(String profilesJson);

  /// Technical comment translated to English.
  Future<String?> getActiveServerId();

  /// Technical comment translated to English.
  Future<void> saveActiveServerId(String serverId);

  /// Technical comment translated to English.
  Future<String?> getDefaultServerId();

  /// Technical comment translated to English.
  Future<void> saveDefaultServerId(String? serverId);

  /// Technical comment translated to English.
  Future<String?> getLocalOpencodeCommand();

  /// Technical comment translated to English.
  Future<void> saveLocalOpencodeCommand(String? commandPath);

  /// Technical comment translated to English.
  Future<String?> getApiKey({String? serverId});

  /// Technical comment translated to English.
  Future<void> saveApiKey(String apiKey, {String? serverId});

  /// Technical comment translated to English.
  Future<String?> getSelectedProvider({String? serverId, String? scopeId});

  /// Technical comment translated to English.
  Future<void> saveSelectedProvider(
    String providerId, {
    String? serverId,
    String? scopeId,
  });

  /// Technical comment translated to English.
  Future<String?> getSelectedModel({String? serverId, String? scopeId});

  /// Technical comment translated to English.
  Future<void> saveSelectedModel(
    String modelId, {
    String? serverId,
    String? scopeId,
  });

  /// Technical comment translated to English.
  Future<String?> getSelectedAgent({String? serverId, String? scopeId});

  /// Technical comment translated to English.
  Future<void> saveSelectedAgent(
    String? agentName, {
    String? serverId,
    String? scopeId,
  });

  /// Technical comment translated to English.
  Future<String?> getSelectedVariantMap({String? serverId, String? scopeId});

  /// Technical comment translated to English.
  Future<void> saveSelectedVariantMap(
    String variantMapJson, {
    String? serverId,
    String? scopeId,
  });

  /// Technical comment translated to English.
  Future<String?> getSessionSelectionOverridesJson({
    String? serverId,
    String? scopeId,
  });

  /// Technical comment translated to English.
  Future<void> saveSessionSelectionOverridesJson(
    String overridesJson, {
    String? serverId,
    String? scopeId,
  });

  Future<String?> getAgentSelectionMemoryJson({
    String? serverId,
    String? scopeId,
  });

  Future<void> saveAgentSelectionMemoryJson(
    String agentSelectionMemoryJson, {
    String? serverId,
    String? scopeId,
  });

  Future<String?> getSessionComposerDraftJson({
    required String sessionId,
    String? serverId,
    String? scopeId,
  });

  Future<void> saveSessionComposerDraftJson(
    String? draftJson, {
    required String sessionId,
    String? serverId,
    String? scopeId,
  });

  /// Technical comment translated to English.
  Future<String?> getRecentModelsJson({String? serverId, String? scopeId});

  /// Technical comment translated to English.
  Future<void> saveRecentModelsJson(
    String recentModelsJson, {
    String? serverId,
    String? scopeId,
  });

  /// Retrieve locally-persisted favorite model keys (scoped).
  Future<String?> getFavoriteModelsJson({String? serverId, String? scopeId});

  /// Retrieve legacy project-scoped favorite-model payloads for a server.
  Future<List<String>> getLegacyFavoriteModelsJsonForServer(String serverId);

  /// Delete legacy project-scoped favorite-model payloads for a server.
  Future<void> deleteLegacyFavoriteModelsJsonForServer(String serverId);

  /// Save locally-persisted favorite model keys (scoped).
  Future<void> saveFavoriteModelsJson(
    String favoriteModelsJson, {
    String? serverId,
    String? scopeId,
  });

  /// Retrieve the last successful provider catalog snapshot for a server.
  Future<String?> getProviderCatalogCacheJson({String? serverId});

  /// Save the last successful provider catalog snapshot for a server.
  Future<void> saveProviderCatalogCacheJson(
    String providerCatalogJson, {
    String? serverId,
  });

  /// Retrieve locally-persisted pinned session IDs (scoped).
  Future<String?> getPinnedSessionsJson({String? serverId, String? scopeId});

  /// Save locally-persisted pinned session IDs (scoped).
  Future<void> savePinnedSessionsJson(
    String pinnedSessionsJson, {
    String? serverId,
    String? scopeId,
  });

  /// Retrieve locally-persisted canned answers JSON (scoped).
  Future<String?> getCannedAnswersJson({String? serverId, String? scopeId});

  /// Save locally-persisted canned answers JSON (scoped).
  Future<void> saveCannedAnswersJson(
    String cannedAnswersJson, {
    String? serverId,
    String? scopeId,
  });

  /// Technical comment translated to English.
  Future<String?> getModelUsageCountsJson({String? serverId, String? scopeId});

  /// Technical comment translated to English.
  Future<void> saveModelUsageCountsJson(
    String usageCountsJson, {
    String? serverId,
    String? scopeId,
  });

  /// Technical comment translated to English.
  Future<String?> getThemeMode();

  /// Technical comment translated to English.
  Future<void> saveThemeMode(String themeMode);

  /// Technical comment translated to English.
  Future<String?> getExperienceSettingsJson();

  /// Technical comment translated to English.
  Future<void> saveExperienceSettingsJson(String settingsJson);

  /// Technical comment translated to English.
  Future<String?> getLastSessionId();

  /// Technical comment translated to English.
  Future<void> saveLastSessionId(
    String sessionId, {
    String? serverId,
    String? scopeId,
  });

  /// Technical comment translated to English.
  Future<String?> getCurrentSessionId({String? serverId, String? scopeId});

  /// Technical comment translated to English.
  Future<void> saveCurrentSessionId(
    String sessionId, {
    String? serverId,
    String? scopeId,
  });

  /// Technical comment translated to English.
  Future<String?> getCurrentProjectId({String? serverId});

  /// Technical comment translated to English.
  Future<void> saveCurrentProjectId(String projectId, {String? serverId});

  /// Technical comment translated to English.
  Future<String?> getOpenProjectIdsJson({String? serverId});

  /// Technical comment translated to English.
  Future<void> saveOpenProjectIdsJson(
    String projectIdsJson, {
    String? serverId,
  });

  /// Technical comment translated to English.
  Future<String?> getArchivedProjectIdsJson({String? serverId});

  /// Technical comment translated to English.
  Future<void> saveArchivedProjectIdsJson(
    String projectIdsJson, {
    String? serverId,
  });

  /// Technical comment translated to English.
  Future<String?> getCachedSessions({String? serverId, String? scopeId});

  /// Technical comment translated to English.
  Future<void> saveCachedSessions(
    String sessionsJson, {
    String? serverId,
    String? scopeId,
  });

  /// Technical comment translated to English.
  Future<int?> getCachedSessionsUpdatedAt({String? serverId, String? scopeId});

  /// Technical comment translated to English.
  Future<void> saveCachedSessionsUpdatedAt(
    int epochMs, {
    String? serverId,
    String? scopeId,
  });

  /// Technical comment translated to English.
  Future<String?> getLastSessionSnapshot({String? serverId, String? scopeId});

  /// Technical comment translated to English.
  Future<void> saveLastSessionSnapshot(
    String snapshotJson, {
    String? serverId,
    String? scopeId,
  });

  /// Technical comment translated to English.
  Future<int?> getLastSessionSnapshotUpdatedAt({
    String? serverId,
    String? scopeId,
  });

  /// Technical comment translated to English.
  Future<void> saveLastSessionSnapshotUpdatedAt(
    int epochMs, {
    String? serverId,
    String? scopeId,
  });

  /// Technical comment translated to English.
  Future<void> clearLastSessionSnapshot({String? serverId, String? scopeId});

  /// Persist per-session message snapshot for cache-first session switching.
  Future<String?> getSessionMessagesSnapshot({
    required String sessionId,
    String? serverId,
    String? scopeId,
  });

  /// Persist per-session message snapshot for cache-first session switching.
  Future<void> saveSessionMessagesSnapshot(
    String snapshotJson, {
    required String sessionId,
    String? serverId,
    String? scopeId,
  });

  /// Read the update timestamp for a per-session message snapshot.
  Future<int?> getSessionMessagesSnapshotUpdatedAt({
    required String sessionId,
    String? serverId,
    String? scopeId,
  });

  /// Save the update timestamp for a per-session message snapshot.
  Future<void> saveSessionMessagesSnapshotUpdatedAt(
    int epochMs, {
    required String sessionId,
    String? serverId,
    String? scopeId,
  });

  /// Remove per-session message snapshot and metadata.
  Future<void> clearSessionMessagesSnapshot({
    required String sessionId,
    String? serverId,
    String? scopeId,
  });

  /// Ordered list of recently persisted per-session snapshots (LRU order).
  Future<String?> getSessionMessagesSnapshotIds({
    String? serverId,
    String? scopeId,
  });

  /// Ordered list of recently persisted per-session snapshots (LRU order).
  Future<void> saveSessionMessagesSnapshotIds(
    String snapshotIdsJson, {
    String? serverId,
    String? scopeId,
  });

  /// Technical comment translated to English.
  Future<void> clearChatContextCache({
    required String serverId,
    required String scopeId,
  });

  /// Technical comment translated to English.
  Future<bool?> getBasicAuthEnabled({String? serverId});

  /// Technical comment translated to English.
  Future<void> saveBasicAuthEnabled(bool enabled, {String? serverId});

  /// Technical comment translated to English.
  Future<String?> getBasicAuthUsername({String? serverId});

  /// Technical comment translated to English.
  Future<void> saveBasicAuthUsername(String username, {String? serverId});

  /// Technical comment translated to English.
  Future<String?> getBasicAuthPassword({String? serverId});

  /// Technical comment translated to English.
  Future<void> saveBasicAuthPassword(String password, {String? serverId});

  Future<String?> getDismissedUpdateVersion();

  Future<void> saveDismissedUpdateVersion(String version);

  /// Technical comment translated to English.
  Future<void> clearAll();
}

/// Technical comment translated to English.
class AppLocalDataSourceImpl implements AppLocalDataSource {
  AppLocalDataSourceImpl({
    required this.sharedPreferences,
    FlutterSecureStorage? secureStorage,
    ChatCachePayloadStore? chatCachePayloadStore,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _chatCachePayloadStore =
           chatCachePayloadStore ?? createChatCachePayloadStore();

  final SharedPreferences sharedPreferences;
  final FlutterSecureStorage _secureStorage;
  final ChatCachePayloadStore? _chatCachePayloadStore;
  final Set<String> _migratedLargeCacheKeys = <String>{};

  String _secureScopedKey(String base, {String? serverId, String? scopeId}) {
    return _scopedKey(
      '${AppConstants.secureStorageNamespace}::$base',
      serverId: serverId,
      scopeId: scopeId,
    );
  }

  String _serverProfileSecureKey({
    required String base,
    required String serverId,
  }) {
    final encodedServer = Uri.encodeComponent(serverId.trim());
    return '${AppConstants.secureStorageNamespace}::$base::$encodedServer';
  }

  Future<String?> _readSecureValue(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeSecureValue(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (_) {
      // Ignore secure storage write failures and keep app functional.
    }
  }

  Future<void> _deleteSecureValue(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (_) {
      // Ignore secure storage delete failures and keep app functional.
    }
  }

  Future<String?> _readSecureWithLegacyFallback({
    required String secureKey,
    required String legacyKey,
  }) async {
    final secureValue = await _readSecureValue(secureKey);
    if (secureValue != null && secureValue.trim().isNotEmpty) {
      return secureValue;
    }
    final legacyValue = sharedPreferences.getString(legacyKey);
    if (legacyValue == null || legacyValue.trim().isEmpty) {
      return null;
    }
    await _writeSecureValue(secureKey, legacyValue);
    await sharedPreferences.remove(legacyKey);
    return legacyValue;
  }

  Future<String?> _readProfileCredential({
    required String serverId,
    required String base,
  }) async {
    final secureKey = _serverProfileSecureKey(base: base, serverId: serverId);
    return _readSecureValue(secureKey);
  }

  Future<void> _writeProfileCredential({
    required String serverId,
    required String base,
    required String value,
  }) async {
    final secureKey = _serverProfileSecureKey(base: base, serverId: serverId);
    if (value.trim().isEmpty) {
      await _deleteSecureValue(secureKey);
      return;
    }
    await _writeSecureValue(secureKey, value);
  }

  String _scopedKey(String base, {String? serverId, String? scopeId}) {
    final scopedServer = serverId?.trim();
    if (scopedServer == null || scopedServer.isEmpty) {
      return base;
    }
    final encodedServer = Uri.encodeComponent(scopedServer);
    final scopedContext = scopeId?.trim();
    if (scopedContext == null || scopedContext.isEmpty) {
      return '$base::$encodedServer';
    }
    final encodedContext = Uri.encodeComponent(scopedContext);
    return '$base::$encodedServer::$encodedContext';
  }

  String _sessionScopedKey(
    String base, {
    required String sessionId,
    String? serverId,
    String? scopeId,
  }) {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return _scopedKey(base, serverId: serverId, scopeId: scopeId);
    }
    final encodedSession = Uri.encodeComponent(normalizedSessionId);
    return _scopedKey(
      '$base::$encodedSession',
      serverId: serverId,
      scopeId: scopeId,
    );
  }

  Future<String?> _readLargeCachePayload(String key) async {
    final store = _chatCachePayloadStore;
    if (store == null) {
      return sharedPreferences.getString(key);
    }

    try {
      final stored = await store.read(key);
      if (stored != null) {
        return stored;
      }
    } catch (_) {
      // Skip the file store on subsequent reads if it is persistently broken.
      _migratedLargeCacheKeys.add(key);
      return sharedPreferences.getString(key);
    }

    if (_migratedLargeCacheKeys.contains(key)) {
      return null;
    }

    final legacy = sharedPreferences.getString(key);
    if (legacy == null || legacy.trim().isEmpty) {
      _migratedLargeCacheKeys.add(key);
      // Return null for both absent and whitespace-only values so first and
      // subsequent reads within the same session are consistent.
      return null;
    }

    try {
      await store.write(key, legacy);
      await sharedPreferences.remove(key);
      _migratedLargeCacheKeys.add(key);
    } catch (_) {
      return legacy;
    }
    return legacy;
  }

  Future<void> _writeLargeCachePayload(String key, String value) async {
    final store = _chatCachePayloadStore;
    if (store == null) {
      await sharedPreferences.setString(key, value);
      return;
    }
    try {
      await store.write(key, value);
      await sharedPreferences.remove(key);
      _migratedLargeCacheKeys.add(key);
    } catch (_) {
      await sharedPreferences.setString(key, value);
    }
  }

  Future<void> _removeLargeCachePayload(String key) async {
    final store = _chatCachePayloadStore;
    if (store != null) {
      try {
        await store.remove(key);
      } catch (_) {}
      _migratedLargeCacheKeys.add(key);
    }
    await sharedPreferences.remove(key);
  }

  Future<void> _clearLargeCachePayloads() async {
    final store = _chatCachePayloadStore;
    if (store != null) {
      try {
        await store.clear();
      } catch (_) {}
    }
    _migratedLargeCacheKeys.clear();
  }

  @override
  Future<String?> getServerHost() async {
    return sharedPreferences.getString(AppConstants.serverHostKey);
  }

  @override
  Future<void> saveServerHost(String host) async {
    await sharedPreferences.setString(AppConstants.serverHostKey, host);
  }

  @override
  Future<int?> getServerPort() async {
    return sharedPreferences.getInt(AppConstants.serverPortKey);
  }

  @override
  Future<void> saveServerPort(int port) async {
    await sharedPreferences.setInt(AppConstants.serverPortKey, port);
  }

  @override
  Future<String?> getServerProfilesJson() async {
    final raw = sharedPreferences.getString(AppConstants.serverProfilesKey);
    if (raw == null || raw.trim().isEmpty) {
      return raw;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return raw;
      }

      final hydratedProfiles = <Map<String, dynamic>>[];
      var shouldPersistSanitized = false;

      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }
        final profile = Map<String, dynamic>.from(item);
        final serverId = profile['id']?.toString().trim() ?? '';
        if (serverId.isEmpty) {
          hydratedProfiles.add(profile);
          continue;
        }

        final legacyUsername = profile['basicAuthUsername']?.toString() ?? '';
        final legacyPassword = profile['basicAuthPassword']?.toString() ?? '';

        var secureUsername = await _readProfileCredential(
          serverId: serverId,
          base: AppConstants.secureServerProfileBasicAuthUsernameKey,
        );
        var securePassword = await _readProfileCredential(
          serverId: serverId,
          base: AppConstants.secureServerProfileBasicAuthPasswordKey,
        );

        if ((secureUsername == null || secureUsername.isEmpty) &&
            legacyUsername.trim().isNotEmpty) {
          secureUsername = legacyUsername;
          await _writeProfileCredential(
            serverId: serverId,
            base: AppConstants.secureServerProfileBasicAuthUsernameKey,
            value: legacyUsername,
          );
          shouldPersistSanitized = true;
        }
        if ((securePassword == null || securePassword.isEmpty) &&
            legacyPassword.trim().isNotEmpty) {
          securePassword = legacyPassword;
          await _writeProfileCredential(
            serverId: serverId,
            base: AppConstants.secureServerProfileBasicAuthPasswordKey,
            value: legacyPassword,
          );
          shouldPersistSanitized = true;
        }

        if (legacyUsername.trim().isNotEmpty ||
            legacyPassword.trim().isNotEmpty) {
          shouldPersistSanitized = true;
        }

        profile['basicAuthUsername'] = secureUsername ?? '';
        profile['basicAuthPassword'] = securePassword ?? '';
        hydratedProfiles.add(profile);
      }

      final hydratedJson = jsonEncode(hydratedProfiles);
      if (shouldPersistSanitized) {
        final sanitizedProfiles = hydratedProfiles
            .map((profile) {
              final copy = Map<String, dynamic>.from(profile);
              copy['basicAuthUsername'] = '';
              copy['basicAuthPassword'] = '';
              return copy;
            })
            .toList(growable: false);
        await sharedPreferences.setString(
          AppConstants.serverProfilesKey,
          jsonEncode(sanitizedProfiles),
        );
      }

      return hydratedJson;
    } catch (_) {
      return raw;
    }
  }

  @override
  Future<void> saveServerProfilesJson(String profilesJson) async {
    try {
      final decoded = jsonDecode(profilesJson);
      if (decoded is! List) {
        await sharedPreferences.setString(
          AppConstants.serverProfilesKey,
          profilesJson,
        );
        return;
      }

      final sanitizedProfiles = <Map<String, dynamic>>[];
      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }
        final profile = Map<String, dynamic>.from(item);
        final serverId = profile['id']?.toString().trim() ?? '';
        final username = profile['basicAuthUsername']?.toString() ?? '';
        final password = profile['basicAuthPassword']?.toString() ?? '';

        if (serverId.isNotEmpty) {
          await _writeProfileCredential(
            serverId: serverId,
            base: AppConstants.secureServerProfileBasicAuthUsernameKey,
            value: username,
          );
          await _writeProfileCredential(
            serverId: serverId,
            base: AppConstants.secureServerProfileBasicAuthPasswordKey,
            value: password,
          );
        }

        profile['basicAuthUsername'] = '';
        profile['basicAuthPassword'] = '';
        sanitizedProfiles.add(profile);
      }

      await sharedPreferences.setString(
        AppConstants.serverProfilesKey,
        jsonEncode(sanitizedProfiles),
      );
    } catch (_) {
      await sharedPreferences.setString(
        AppConstants.serverProfilesKey,
        profilesJson,
      );
    }
  }

  @override
  Future<String?> getActiveServerId() async {
    return sharedPreferences.getString(AppConstants.activeServerIdKey);
  }

  @override
  Future<void> saveActiveServerId(String serverId) async {
    await sharedPreferences.setString(AppConstants.activeServerIdKey, serverId);
  }

  @override
  Future<String?> getDefaultServerId() async {
    return sharedPreferences.getString(AppConstants.defaultServerIdKey);
  }

  @override
  Future<void> saveDefaultServerId(String? serverId) async {
    if (serverId == null || serverId.trim().isEmpty) {
      await sharedPreferences.remove(AppConstants.defaultServerIdKey);
      return;
    }
    await sharedPreferences.setString(
      AppConstants.defaultServerIdKey,
      serverId,
    );
  }

  @override
  Future<String?> getLocalOpencodeCommand() async {
    return sharedPreferences.getString(AppConstants.localOpencodeCommandKey);
  }

  @override
  Future<void> saveLocalOpencodeCommand(String? commandPath) async {
    final normalized = commandPath?.trim() ?? '';
    if (normalized.isEmpty) {
      await sharedPreferences.remove(AppConstants.localOpencodeCommandKey);
      return;
    }
    await sharedPreferences.setString(
      AppConstants.localOpencodeCommandKey,
      normalized,
    );
  }

  @override
  Future<String?> getApiKey({String? serverId}) async {
    final legacyKey = _scopedKey(AppConstants.apiKeyKey, serverId: serverId);
    final secureKey = _secureScopedKey(
      AppConstants.apiKeyKey,
      serverId: serverId,
    );
    return _readSecureWithLegacyFallback(
      secureKey: secureKey,
      legacyKey: legacyKey,
    );
  }

  @override
  Future<void> saveApiKey(String apiKey, {String? serverId}) async {
    final normalizedApiKey = apiKey.trim();
    final legacyKey = _scopedKey(AppConstants.apiKeyKey, serverId: serverId);
    final secureKey = _secureScopedKey(
      AppConstants.apiKeyKey,
      serverId: serverId,
    );
    if (normalizedApiKey.isEmpty) {
      await _deleteSecureValue(secureKey);
      await sharedPreferences.remove(legacyKey);
      return;
    }
    await _writeSecureValue(secureKey, normalizedApiKey);
    await sharedPreferences.remove(legacyKey);
  }

  @override
  Future<String?> getSelectedProvider({
    String? serverId,
    String? scopeId,
  }) async {
    return sharedPreferences.getString(
      _scopedKey(
        AppConstants.selectedProviderKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
    );
  }

  @override
  Future<void> saveSelectedProvider(
    String providerId, {
    String? serverId,
    String? scopeId,
  }) async {
    await sharedPreferences.setString(
      _scopedKey(
        AppConstants.selectedProviderKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
      providerId,
    );
  }

  @override
  Future<String?> getSelectedModel({String? serverId, String? scopeId}) async {
    return sharedPreferences.getString(
      _scopedKey(
        AppConstants.selectedModelKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
    );
  }

  @override
  Future<void> saveSelectedModel(
    String modelId, {
    String? serverId,
    String? scopeId,
  }) async {
    await sharedPreferences.setString(
      _scopedKey(
        AppConstants.selectedModelKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
      modelId,
    );
  }

  @override
  Future<String?> getSelectedAgent({String? serverId, String? scopeId}) async {
    return sharedPreferences.getString(
      _scopedKey(
        AppConstants.selectedAgentKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
    );
  }

  @override
  Future<void> saveSelectedAgent(
    String? agentName, {
    String? serverId,
    String? scopeId,
  }) async {
    final key = _scopedKey(
      AppConstants.selectedAgentKey,
      serverId: serverId,
      scopeId: scopeId,
    );
    if (agentName == null || agentName.trim().isEmpty) {
      await sharedPreferences.remove(key);
      return;
    }
    await sharedPreferences.setString(key, agentName);
  }

  @override
  Future<String?> getSelectedVariantMap({
    String? serverId,
    String? scopeId,
  }) async {
    return sharedPreferences.getString(
      _scopedKey(
        AppConstants.selectedVariantMapKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
    );
  }

  @override
  Future<void> saveSelectedVariantMap(
    String variantMapJson, {
    String? serverId,
    String? scopeId,
  }) async {
    await sharedPreferences.setString(
      _scopedKey(
        AppConstants.selectedVariantMapKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
      variantMapJson,
    );
  }

  @override
  Future<String?> getSessionSelectionOverridesJson({
    String? serverId,
    String? scopeId,
  }) async {
    return sharedPreferences.getString(
      _scopedKey(
        AppConstants.sessionSelectionOverridesKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
    );
  }

  @override
  Future<void> saveSessionSelectionOverridesJson(
    String overridesJson, {
    String? serverId,
    String? scopeId,
  }) async {
    await sharedPreferences.setString(
      _scopedKey(
        AppConstants.sessionSelectionOverridesKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
      overridesJson,
    );
  }

  @override
  Future<String?> getAgentSelectionMemoryJson({
    String? serverId,
    String? scopeId,
  }) async {
    return sharedPreferences.getString(
      _scopedKey(
        AppConstants.agentSelectionMemoryKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
    );
  }

  @override
  Future<void> saveAgentSelectionMemoryJson(
    String agentSelectionMemoryJson, {
    String? serverId,
    String? scopeId,
  }) async {
    await sharedPreferences.setString(
      _scopedKey(
        AppConstants.agentSelectionMemoryKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
      agentSelectionMemoryJson,
    );
  }

  @override
  Future<String?> getSessionComposerDraftJson({
    required String sessionId,
    String? serverId,
    String? scopeId,
  }) async {
    return sharedPreferences.getString(
      _sessionScopedKey(
        AppConstants.sessionComposerDraftKey,
        sessionId: sessionId,
        serverId: serverId,
        scopeId: scopeId,
      ),
    );
  }

  @override
  Future<void> saveSessionComposerDraftJson(
    String? draftJson, {
    required String sessionId,
    String? serverId,
    String? scopeId,
  }) async {
    final key = _sessionScopedKey(
      AppConstants.sessionComposerDraftKey,
      sessionId: sessionId,
      serverId: serverId,
      scopeId: scopeId,
    );
    if (draftJson == null || draftJson.trim().isEmpty) {
      await sharedPreferences.remove(key);
      return;
    }
    await sharedPreferences.setString(key, draftJson);
  }

  @override
  Future<String?> getRecentModelsJson({
    String? serverId,
    String? scopeId,
  }) async {
    return sharedPreferences.getString(
      _scopedKey(
        AppConstants.recentModelsKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
    );
  }

  @override
  Future<void> saveRecentModelsJson(
    String recentModelsJson, {
    String? serverId,
    String? scopeId,
  }) async {
    await sharedPreferences.setString(
      _scopedKey(
        AppConstants.recentModelsKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
      recentModelsJson,
    );
  }

  @override
  Future<String?> getFavoriteModelsJson({
    String? serverId,
    String? scopeId,
  }) async {
    return sharedPreferences.getString(
      _scopedKey(
        AppConstants.favoriteModelsKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
    );
  }

  @override
  Future<List<String>> getLegacyFavoriteModelsJsonForServer(
    String serverId,
  ) async {
    final normalizedServerId = serverId.trim();
    if (normalizedServerId.isEmpty) {
      return const <String>[];
    }
    final prefix =
        '${AppConstants.favoriteModelsKey}::${Uri.encodeComponent(normalizedServerId)}::';
    final values = <String>[];
    for (final key in sharedPreferences.getKeys()) {
      if (!key.startsWith(prefix)) {
        continue;
      }
      final value = sharedPreferences.getString(key);
      if (value == null || value.trim().isEmpty) {
        continue;
      }
      values.add(value);
    }
    return values;
  }

  @override
  Future<void> deleteLegacyFavoriteModelsJsonForServer(String serverId) async {
    final normalizedServerId = serverId.trim();
    if (normalizedServerId.isEmpty) {
      return;
    }
    final prefix =
        '${AppConstants.favoriteModelsKey}::${Uri.encodeComponent(normalizedServerId)}::';
    final keysToDelete = sharedPreferences
        .getKeys()
        .where((key) => key.startsWith(prefix))
        .toList(growable: false);
    for (final key in keysToDelete) {
      await sharedPreferences.remove(key);
    }
  }

  @override
  Future<void> saveFavoriteModelsJson(
    String favoriteModelsJson, {
    String? serverId,
    String? scopeId,
  }) async {
    await sharedPreferences.setString(
      _scopedKey(
        AppConstants.favoriteModelsKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
      favoriteModelsJson,
    );
  }

  @override
  Future<String?> getProviderCatalogCacheJson({String? serverId}) async {
    return sharedPreferences.getString(
      _scopedKey(AppConstants.providerCatalogCacheKey, serverId: serverId),
    );
  }

  @override
  Future<void> saveProviderCatalogCacheJson(
    String providerCatalogJson, {
    String? serverId,
  }) async {
    await sharedPreferences.setString(
      _scopedKey(AppConstants.providerCatalogCacheKey, serverId: serverId),
      providerCatalogJson,
    );
  }

  @override
  Future<String?> getPinnedSessionsJson({
    String? serverId,
    String? scopeId,
  }) async {
    return sharedPreferences.getString(
      _scopedKey(
        AppConstants.pinnedSessionsKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
    );
  }

  @override
  Future<void> savePinnedSessionsJson(
    String pinnedSessionsJson, {
    String? serverId,
    String? scopeId,
  }) async {
    await sharedPreferences.setString(
      _scopedKey(
        AppConstants.pinnedSessionsKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
      pinnedSessionsJson,
    );
  }

  @override
  Future<String?> getCannedAnswersJson({
    String? serverId,
    String? scopeId,
  }) async {
    return sharedPreferences.getString(
      _scopedKey(
        AppConstants.cannedAnswersKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
    );
  }

  @override
  Future<void> saveCannedAnswersJson(
    String cannedAnswersJson, {
    String? serverId,
    String? scopeId,
  }) async {
    await sharedPreferences.setString(
      _scopedKey(
        AppConstants.cannedAnswersKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
      cannedAnswersJson,
    );
  }

  @override
  Future<String?> getModelUsageCountsJson({
    String? serverId,
    String? scopeId,
  }) async {
    return sharedPreferences.getString(
      _scopedKey(
        AppConstants.modelUsageCountsKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
    );
  }

  @override
  Future<void> saveModelUsageCountsJson(
    String usageCountsJson, {
    String? serverId,
    String? scopeId,
  }) async {
    await sharedPreferences.setString(
      _scopedKey(
        AppConstants.modelUsageCountsKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
      usageCountsJson,
    );
  }

  @override
  Future<String?> getThemeMode() async {
    return sharedPreferences.getString(AppConstants.themeKey);
  }

  @override
  Future<void> saveThemeMode(String themeMode) async {
    await sharedPreferences.setString(AppConstants.themeKey, themeMode);
  }

  @override
  Future<String?> getExperienceSettingsJson() async {
    return sharedPreferences.getString(AppConstants.experienceSettingsKey);
  }

  @override
  Future<void> saveExperienceSettingsJson(String settingsJson) async {
    await sharedPreferences.setString(
      AppConstants.experienceSettingsKey,
      settingsJson,
    );
  }

  @override
  Future<String?> getLastSessionId() async {
    return sharedPreferences.getString(AppConstants.lastSessionIdKey);
  }

  @override
  Future<void> saveLastSessionId(
    String sessionId, {
    String? serverId,
    String? scopeId,
  }) async {
    await sharedPreferences.setString(
      _scopedKey(
        AppConstants.lastSessionIdKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
      sessionId,
    );
  }

  @override
  Future<String?> getCurrentSessionId({
    String? serverId,
    String? scopeId,
  }) async {
    return sharedPreferences.getString(
      _scopedKey(
        AppConstants.currentSessionIdKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
    );
  }

  @override
  Future<String?> getCurrentProjectId({String? serverId}) async {
    return sharedPreferences.getString(
      _scopedKey(AppConstants.currentProjectIdKey, serverId: serverId),
    );
  }

  @override
  Future<void> saveCurrentProjectId(
    String projectId, {
    String? serverId,
  }) async {
    await sharedPreferences.setString(
      _scopedKey(AppConstants.currentProjectIdKey, serverId: serverId),
      projectId,
    );
  }

  @override
  Future<String?> getOpenProjectIdsJson({String? serverId}) async {
    return sharedPreferences.getString(
      _scopedKey(AppConstants.openProjectIdsKey, serverId: serverId),
    );
  }

  @override
  Future<void> saveOpenProjectIdsJson(
    String projectIdsJson, {
    String? serverId,
  }) async {
    await sharedPreferences.setString(
      _scopedKey(AppConstants.openProjectIdsKey, serverId: serverId),
      projectIdsJson,
    );
  }

  @override
  Future<String?> getArchivedProjectIdsJson({String? serverId}) async {
    return sharedPreferences.getString(
      _scopedKey(AppConstants.archivedProjectIdsKey, serverId: serverId),
    );
  }

  @override
  Future<void> saveArchivedProjectIdsJson(
    String projectIdsJson, {
    String? serverId,
  }) async {
    await sharedPreferences.setString(
      _scopedKey(AppConstants.archivedProjectIdsKey, serverId: serverId),
      projectIdsJson,
    );
  }

  @override
  Future<void> saveCurrentSessionId(
    String sessionId, {
    String? serverId,
    String? scopeId,
  }) async {
    await sharedPreferences.setString(
      _scopedKey(
        AppConstants.currentSessionIdKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
      sessionId,
    );
  }

  @override
  Future<String?> getCachedSessions({String? serverId, String? scopeId}) async {
    final key = _scopedKey(
      AppConstants.cachedSessionsKey,
      serverId: serverId,
      scopeId: scopeId,
    );
    return _readLargeCachePayload(key);
  }

  @override
  Future<void> saveCachedSessions(
    String sessionsJson, {
    String? serverId,
    String? scopeId,
  }) async {
    final key = _scopedKey(
      AppConstants.cachedSessionsKey,
      serverId: serverId,
      scopeId: scopeId,
    );
    await _writeLargeCachePayload(key, sessionsJson);
  }

  @override
  Future<int?> getCachedSessionsUpdatedAt({
    String? serverId,
    String? scopeId,
  }) async {
    return sharedPreferences.getInt(
      _scopedKey(
        AppConstants.cachedSessionsUpdatedAtKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
    );
  }

  @override
  Future<void> saveCachedSessionsUpdatedAt(
    int epochMs, {
    String? serverId,
    String? scopeId,
  }) async {
    await sharedPreferences.setInt(
      _scopedKey(
        AppConstants.cachedSessionsUpdatedAtKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
      epochMs,
    );
  }

  @override
  Future<String?> getLastSessionSnapshot({
    String? serverId,
    String? scopeId,
  }) async {
    final key = _scopedKey(
      AppConstants.lastSessionSnapshotKey,
      serverId: serverId,
      scopeId: scopeId,
    );
    return _readLargeCachePayload(key);
  }

  @override
  Future<void> saveLastSessionSnapshot(
    String snapshotJson, {
    String? serverId,
    String? scopeId,
  }) async {
    final key = _scopedKey(
      AppConstants.lastSessionSnapshotKey,
      serverId: serverId,
      scopeId: scopeId,
    );
    await _writeLargeCachePayload(key, snapshotJson);
  }

  @override
  Future<int?> getLastSessionSnapshotUpdatedAt({
    String? serverId,
    String? scopeId,
  }) async {
    return sharedPreferences.getInt(
      _scopedKey(
        AppConstants.lastSessionSnapshotUpdatedAtKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
    );
  }

  @override
  Future<void> saveLastSessionSnapshotUpdatedAt(
    int epochMs, {
    String? serverId,
    String? scopeId,
  }) async {
    await sharedPreferences.setInt(
      _scopedKey(
        AppConstants.lastSessionSnapshotUpdatedAtKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
      epochMs,
    );
  }

  @override
  Future<void> clearLastSessionSnapshot({
    String? serverId,
    String? scopeId,
  }) async {
    await _removeLargeCachePayload(
      _scopedKey(
        AppConstants.lastSessionSnapshotKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
    );
    await sharedPreferences.remove(
      _scopedKey(
        AppConstants.lastSessionSnapshotUpdatedAtKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
    );
  }

  @override
  Future<String?> getSessionMessagesSnapshot({
    required String sessionId,
    String? serverId,
    String? scopeId,
  }) async {
    final key = _sessionScopedKey(
      AppConstants.sessionMessagesSnapshotKey,
      sessionId: sessionId,
      serverId: serverId,
      scopeId: scopeId,
    );
    return _readLargeCachePayload(key);
  }

  @override
  Future<void> saveSessionMessagesSnapshot(
    String snapshotJson, {
    required String sessionId,
    String? serverId,
    String? scopeId,
  }) async {
    final key = _sessionScopedKey(
      AppConstants.sessionMessagesSnapshotKey,
      sessionId: sessionId,
      serverId: serverId,
      scopeId: scopeId,
    );
    await _writeLargeCachePayload(key, snapshotJson);
  }

  @override
  Future<int?> getSessionMessagesSnapshotUpdatedAt({
    required String sessionId,
    String? serverId,
    String? scopeId,
  }) async {
    return sharedPreferences.getInt(
      _sessionScopedKey(
        AppConstants.sessionMessagesSnapshotUpdatedAtKey,
        sessionId: sessionId,
        serverId: serverId,
        scopeId: scopeId,
      ),
    );
  }

  @override
  Future<void> saveSessionMessagesSnapshotUpdatedAt(
    int epochMs, {
    required String sessionId,
    String? serverId,
    String? scopeId,
  }) async {
    await sharedPreferences.setInt(
      _sessionScopedKey(
        AppConstants.sessionMessagesSnapshotUpdatedAtKey,
        sessionId: sessionId,
        serverId: serverId,
        scopeId: scopeId,
      ),
      epochMs,
    );
  }

  @override
  Future<void> clearSessionMessagesSnapshot({
    required String sessionId,
    String? serverId,
    String? scopeId,
  }) async {
    await _removeLargeCachePayload(
      _sessionScopedKey(
        AppConstants.sessionMessagesSnapshotKey,
        sessionId: sessionId,
        serverId: serverId,
        scopeId: scopeId,
      ),
    );
    await sharedPreferences.remove(
      _sessionScopedKey(
        AppConstants.sessionMessagesSnapshotUpdatedAtKey,
        sessionId: sessionId,
        serverId: serverId,
        scopeId: scopeId,
      ),
    );
  }

  @override
  Future<String?> getSessionMessagesSnapshotIds({
    String? serverId,
    String? scopeId,
  }) async {
    return sharedPreferences.getString(
      _scopedKey(
        AppConstants.sessionMessagesSnapshotIdsKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
    );
  }

  @override
  Future<void> saveSessionMessagesSnapshotIds(
    String snapshotIdsJson, {
    String? serverId,
    String? scopeId,
  }) async {
    await sharedPreferences.setString(
      _scopedKey(
        AppConstants.sessionMessagesSnapshotIdsKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
      snapshotIdsJson,
    );
  }

  @override
  Future<void> clearChatContextCache({
    required String serverId,
    required String scopeId,
  }) async {
    final snapshotIdsRaw = await getSessionMessagesSnapshotIds(
      serverId: serverId,
      scopeId: scopeId,
    );
    if (snapshotIdsRaw != null && snapshotIdsRaw.trim().isNotEmpty) {
      try {
        final decoded = json.decode(snapshotIdsRaw);
        if (decoded is List) {
          for (final id in decoded.whereType<String>()) {
            if (id.trim().isEmpty) {
              continue;
            }
            await clearSessionMessagesSnapshot(
              sessionId: id,
              serverId: serverId,
              scopeId: scopeId,
            );
          }
        }
      } catch (_) {
        // Ignore malformed snapshot ID payloads during cleanup.
      }
    }

    await _removeLargeCachePayload(
      _scopedKey(
        AppConstants.cachedSessionsKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
    );
    await _removeLargeCachePayload(
      _scopedKey(
        AppConstants.lastSessionSnapshotKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
    );

    final keys = <String>[
      _scopedKey(
        AppConstants.cachedSessionsUpdatedAtKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
      _scopedKey(
        AppConstants.currentSessionIdKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
      _scopedKey(
        AppConstants.lastSessionIdKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
      _scopedKey(
        AppConstants.lastSessionSnapshotUpdatedAtKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
      _scopedKey(
        AppConstants.sessionSelectionOverridesKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
      _scopedKey(
        AppConstants.sessionMessagesSnapshotIdsKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
      _scopedKey(
        AppConstants.pinnedSessionsKey,
        serverId: serverId,
        scopeId: scopeId,
      ),
    ];

    for (final key in keys) {
      await sharedPreferences.remove(key);
    }
  }

  @override
  Future<String?> getDismissedUpdateVersion() async {
    return sharedPreferences.getString(AppConstants.dismissedUpdateVersionKey);
  }

  @override
  Future<void> saveDismissedUpdateVersion(String version) async {
    await sharedPreferences.setString(
      AppConstants.dismissedUpdateVersionKey,
      version,
    );
  }

  @override
  Future<bool?> getBasicAuthEnabled({String? serverId}) async {
    return sharedPreferences.getBool(
      _scopedKey(AppConstants.basicAuthEnabledKey, serverId: serverId),
    );
  }

  @override
  Future<void> saveBasicAuthEnabled(bool enabled, {String? serverId}) async {
    await sharedPreferences.setBool(
      _scopedKey(AppConstants.basicAuthEnabledKey, serverId: serverId),
      enabled,
    );
  }

  @override
  Future<String?> getBasicAuthUsername({String? serverId}) async {
    final legacyKey = _scopedKey(
      AppConstants.basicAuthUsernameKey,
      serverId: serverId,
    );
    final secureKey = _secureScopedKey(
      AppConstants.basicAuthUsernameKey,
      serverId: serverId,
    );
    return _readSecureWithLegacyFallback(
      secureKey: secureKey,
      legacyKey: legacyKey,
    );
  }

  @override
  Future<void> saveBasicAuthUsername(
    String username, {
    String? serverId,
  }) async {
    final legacyKey = _scopedKey(
      AppConstants.basicAuthUsernameKey,
      serverId: serverId,
    );
    final secureKey = _secureScopedKey(
      AppConstants.basicAuthUsernameKey,
      serverId: serverId,
    );
    if (username.trim().isEmpty) {
      await _deleteSecureValue(secureKey);
      await sharedPreferences.remove(legacyKey);
      return;
    }
    await _writeSecureValue(secureKey, username);
    await sharedPreferences.remove(legacyKey);
  }

  @override
  Future<String?> getBasicAuthPassword({String? serverId}) async {
    final legacyKey = _scopedKey(
      AppConstants.basicAuthPasswordKey,
      serverId: serverId,
    );
    final secureKey = _secureScopedKey(
      AppConstants.basicAuthPasswordKey,
      serverId: serverId,
    );
    return _readSecureWithLegacyFallback(
      secureKey: secureKey,
      legacyKey: legacyKey,
    );
  }

  @override
  Future<void> saveBasicAuthPassword(
    String password, {
    String? serverId,
  }) async {
    final legacyKey = _scopedKey(
      AppConstants.basicAuthPasswordKey,
      serverId: serverId,
    );
    final secureKey = _secureScopedKey(
      AppConstants.basicAuthPasswordKey,
      serverId: serverId,
    );
    if (password.trim().isEmpty) {
      await _deleteSecureValue(secureKey);
      await sharedPreferences.remove(legacyKey);
      return;
    }
    await _writeSecureValue(secureKey, password);
    await sharedPreferences.remove(legacyKey);
  }

  @override
  Future<void> clearAll() async {
    await _clearLargeCachePayloads();
    await sharedPreferences.clear();
    try {
      await _secureStorage.deleteAll();
    } catch (_) {
      // Ignore secure storage cleanup failures and keep app functional.
    }
  }
}
