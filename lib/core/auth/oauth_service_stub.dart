import 'oauth_credential.dart';
import 'oauth_service_result.dart';
import 'oauth_token_storage.dart';

class OAuthService {
  OAuthService({
    required this.profileId,
    required this.serverUrl,
    this.challengeHeaders,
    this.challengeBody,
    OAuthTokenStorage? storage,
  }) : _storage = storage ?? OAuthTokenStorage();

  final String profileId;
  final String serverUrl;
  final Map<String, String>? challengeHeaders;
  final String? challengeBody;
  final OAuthTokenStorage _storage;

  static bool isOAuthChallenge(int statusCode, Map<String, String> headers) {
    if (statusCode != 401 && statusCode != 403) return false;
    final auth = headers['www-authenticate'] ?? '';
    return auth.startsWith('Bearer ') || auth.startsWith('Cloudflare-Access');
  }

  Future<OAuthCredential?> getCachedCredential() async {
    return _storage.loadCredential(profileId: profileId, serverUrl: serverUrl);
  }

  Future<OAuthFlowResult> authenticate({bool skipCache = false}) async {
    return OAuthFlowResult(
      error: 'Cloudflare Access OAuth is supported on desktop only.',
      token: null,
    );
  }

  Future<OAuthFlowResult> refreshCredential(OAuthCredential credential) async {
    return OAuthFlowResult(
      error: 'Cloudflare Access OAuth is supported on desktop only.',
      token: null,
    );
  }

  Future<void> clearCredential() async {
    await _storage.deleteCredential(profileId: profileId, serverUrl: serverUrl);
  }
}
