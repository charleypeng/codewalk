import 'package:codewalk/core/auth/oauth_credential.dart';
import 'package:codewalk/core/auth/oauth_token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeOAuthTokenStorageBackend implements OAuthTokenStorageBackend {
  final Map<String, String> values = <String, String>{};
  bool fail = false;

  @override
  Future<void> write({required String key, required String value}) async {
    if (fail) {
      throw StateError('secure storage unavailable');
    }
    values[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    if (fail) {
      throw StateError('secure storage unavailable');
    }
    return values[key];
  }

  @override
  Future<void> delete({required String key}) async {
    if (fail) {
      throw StateError('secure storage unavailable');
    }
    values.remove(key);
  }
}

void main() {
  group('OAuthTokenStorage', () {
    test('stores credentials only under profile-scoped secure keys', () async {
      final backend = _FakeOAuthTokenStorageBackend();
      final storage = OAuthTokenStorage(backend: backend);
      final credential = OAuthCredential(
        profileId: 'profile-a',
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        serverUrl: 'https://code.example.com',
        clientId: 'client-id',
      );

      await storage.saveCredential(credential);

      expect(backend.values, hasLength(1));
      expect(backend.values.keys.single, contains('profile-a'));
      expect(backend.values.keys.single, contains('code.example.com'));
      expect(
        await storage.loadCredential(
          profileId: 'profile-a',
          serverUrl: 'https://code.example.com',
        ),
        isNotNull,
      );
      expect(
        await storage.loadCredential(
          profileId: 'profile-b',
          serverUrl: 'https://code.example.com',
        ),
        isNull,
      );
    });

    test('fails closed when secure storage is unavailable', () async {
      final backend = _FakeOAuthTokenStorageBackend()..fail = true;
      final storage = OAuthTokenStorage(backend: backend);
      final credential = OAuthCredential(
        profileId: 'profile-a',
        accessToken: 'access-token',
        serverUrl: 'https://code.example.com',
      );

      expect(
        () => storage.saveCredential(credential),
        throwsA(isA<OAuthTokenStorageException>()),
      );
      expect(
        () => storage.loadCredential(
          profileId: 'profile-a',
          serverUrl: 'https://code.example.com',
        ),
        throwsA(isA<OAuthTokenStorageException>()),
      );
    });
  });
}
