import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import 'oauth_credential.dart';

class OAuthTokenStorage {
  OAuthTokenStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;
  String? _tokenDirPath;

  String _key(String serverUrl) {
    final normalized = Uri.encodeComponent(serverUrl.trim());
    return '${AppConstants.secureStorageNamespace}::oauth::$normalized';
  }

  String _fileKey(String serverUrl) {
    final bytes = utf8.encode(serverUrl.trim());
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  Future<Directory> _tokenDir() async {
    if (_tokenDirPath != null) return Directory(_tokenDirPath!);
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory('${supportDir.path}/oauth_tokens');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _tokenDirPath = dir.path;
    return dir;
  }

  Future<File> _tokenFile(String serverUrl) async {
    final dir = await _tokenDir();
    return File('${dir.path}/oauth_${_fileKey(serverUrl)}.json');
  }

  Future<void> saveCredential(OAuthCredential credential) async {
    final data = jsonEncode(credential.toJson());

    try {
      final key = _key(credential.serverUrl);
      await _secureStorage.write(key: key, value: data);
    } catch (_) {
      // FlutterSecureStorage may fail on desktop debug builds.
    }

    final file = await _tokenFile(credential.serverUrl);
    await file.writeAsString(data, flush: true);
  }

  Future<OAuthCredential?> loadCredential(String serverUrl) async {
    try {
      final file = await _tokenFile(serverUrl);
      if (await file.exists()) {
        final raw = await file.readAsString();
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return OAuthCredential.fromJson(map);
      }
    } catch (_) {
      // File may be corrupt or unreadable.
    }

    try {
      final key = _key(serverUrl);
      final raw = await _secureStorage.read(key: key);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return OAuthCredential.fromJson(map);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> deleteCredential(String serverUrl) async {
    try {
      await _secureStorage.delete(key: _key(serverUrl));
    } catch (_) {}

    final file = await _tokenFile(serverUrl);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> hasValidCredential(String serverUrl) async {
    final credential = await loadCredential(serverUrl);
    return credential?.isValid ?? false;
  }
}
