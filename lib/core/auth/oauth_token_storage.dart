import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_constants.dart';
import 'oauth_credential.dart';

class OAuthTokenStorageException implements Exception {
  const OAuthTokenStorageException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => cause == null
      ? 'OAuthTokenStorageException: $message'
      : 'OAuthTokenStorageException: $message ($cause)';
}

abstract class OAuthTokenStorageBackend {
  Future<void> write({required String key, required String value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
}

class FlutterSecureOAuthTokenStorageBackend implements OAuthTokenStorageBackend {
  const FlutterSecureOAuthTokenStorageBackend([this._secureStorage]);

  final FlutterSecureStorage? _secureStorage;

  FlutterSecureStorage get _storage =>
      _secureStorage ?? const FlutterSecureStorage();

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read({required String key}) {
    return _storage.read(key: key);
  }

  @override
  Future<void> delete({required String key}) {
    return _storage.delete(key: key);
  }
}

class OAuthTokenStorage {
  OAuthTokenStorage({OAuthTokenStorageBackend? backend})
    : _backend = backend ?? const FlutterSecureOAuthTokenStorageBackend();

  final OAuthTokenStorageBackend _backend;

  String _key({required String profileId, required String serverUrl}) {
    final normalizedProfile = Uri.encodeComponent(profileId.trim());
    final normalizedUrl = Uri.encodeComponent(serverUrl.trim());
    return '${AppConstants.secureStorageNamespace}::oauth::'
        '$normalizedProfile::$normalizedUrl';
  }

  Future<void> saveCredential(OAuthCredential credential) async {
    final data = jsonEncode(credential.toJson());
    try {
      await _backend.write(
        key: _key(
          profileId: credential.profileId,
          serverUrl: credential.serverUrl,
        ),
        value: data,
      );
    } catch (error) {
      throw OAuthTokenStorageException(
        'Secure credential storage is unavailable.',
        error,
      );
    }
  }

  Future<OAuthCredential?> loadCredential({
    required String profileId,
    required String serverUrl,
  }) async {
    try {
      final raw = await _backend.read(
        key: _key(profileId: profileId, serverUrl: serverUrl),
      );
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final credential = OAuthCredential.fromJson(map);
        if (credential.profileId != profileId ||
            credential.serverUrl != serverUrl) {
          return null;
        }
        return credential;
      }
    } on FormatException {
      return null;
    } catch (error) {
      throw OAuthTokenStorageException(
        'Secure credential storage is unavailable.',
        error,
      );
    }
    return null;
  }

  Future<void> deleteCredential({
    required String profileId,
    required String serverUrl,
  }) async {
    try {
      await _backend.delete(
        key: _key(profileId: profileId, serverUrl: serverUrl),
      );
    } catch (error) {
      throw OAuthTokenStorageException(
        'Secure credential storage is unavailable.',
        error,
      );
    }
  }

  Future<bool> hasValidCredential({
    required String profileId,
    required String serverUrl,
  }) async {
    final credential = await loadCredential(
      profileId: profileId,
      serverUrl: serverUrl,
    );
    return credential?.isValid ?? false;
  }
}
