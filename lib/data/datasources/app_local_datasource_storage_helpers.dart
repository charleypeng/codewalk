part of 'app_local_datasource.dart';

extension _AppLocalDataSourceStorageHelpers on AppLocalDataSourceImpl {
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
}
