import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/logging/app_logger.dart';
import 'oauth_credential.dart';
import 'oauth_token_storage.dart';

class OAuthFlowResult {
  final List<String> log;
  final String? error;
  final String? token;
  final bool needsConsent;

  OAuthFlowResult({
    this.log = const [],
    this.error,
    this.token,
    this.needsConsent = true,
  });

  bool get ok => error == null && token != null;
}

class OAuthService {
  final String profileId;
  final String serverUrl;
  final Map<String, String>? challengeHeaders;
  final String? challengeBody;
  final OAuthTokenStorage _storage;

  OAuthService({
    required this.profileId,
    required this.serverUrl,
    this.challengeHeaders,
    this.challengeBody,
    OAuthTokenStorage? storage,
  }) : _storage = storage ?? OAuthTokenStorage();

  static bool isOAuthChallenge(int statusCode, Map<String, String> headers) {
    if (statusCode != 401 && statusCode != 403) return false;
    final auth = headers['www-authenticate'] ?? '';
    return auth.startsWith('Bearer ') || auth.startsWith('Cloudflare-Access');
  }

  Future<OAuthCredential?> getCachedCredential() async {
    final credential = await _storage.loadCredential(
      profileId: profileId,
      serverUrl: serverUrl,
    );
    if (credential != null && credential.isValid) return credential;
    return null;
  }

  Future<OAuthFlowResult> authenticate({bool skipCache = false}) async {
    _log('Starting OAuth flow for $serverUrl');

    if (!skipCache) {
      final cached = await getCachedCredential();
      if (cached != null) {
        _log('Using cached credential');
        return OAuthFlowResult(token: cached.accessToken, needsConsent: false);
      }

      // Cached credential is missing or expired — try silent refresh first
      final stored = await _storage.loadCredential(
        profileId: profileId,
        serverUrl: serverUrl,
      );
      if (stored != null && stored.refreshToken != null) {
        _log('Cached credential expired, attempting silent refresh');
        final refreshResult = await refreshCredential(stored);
        if (refreshResult.ok) {
          _log('Silent refresh succeeded, returning new token');
          return refreshResult;
        }
        _log('Silent refresh failed, falling back to full PKCE flow');
      }
    }

    final meta = await _fetchOAuthMetadata();
    if (meta == null) {
      return OAuthFlowResult(
        log: [],
        error: 'No OAuth endpoints discovered. '
            'Enable Managed OAuth in Cloudflare Dashboard '
            '→ Access → Applications → [this app].',
        token: null,
      );
    }
    _log('Metadata: auth=${meta['authorization_endpoint']} '
        'token=${meta['token_endpoint']}');

    final client = await _registerClient(meta);
    _log('Client: id=${client?['client_id']}');

    final tokenData = await _runPkceFlow(meta, client);
    if (tokenData == null) {
      return OAuthFlowResult(
        log: [],
        error: 'Browser authentication did not complete',
        token: null,
      );
    }
    _log('Token received');

    final credential = OAuthCredential(
      profileId: profileId,
      accessToken: tokenData['access_token'] as String,
      refreshToken: tokenData['refresh_token'] as String?,
      expiresAt: tokenData.containsKey('expires_in')
          ? DateTime.now().add(
              Duration(seconds: tokenData['expires_in'] as int),
            )
          : null,
      serverUrl: serverUrl,
      clientId: client?['client_id'] as String?,
    );
    try {
      await _storage.saveCredential(credential);
      _log('Credential saved securely');
    } catch (e) {
      _log('Credential save failed: secure storage unavailable');
      return OAuthFlowResult(
        log: [],
        error: 'Secure credential storage is unavailable for OAuth.',
        token: null,
      );
    }

    return OAuthFlowResult(token: credential.accessToken);
  }

  Future<OAuthFlowResult> refreshCredential(
    OAuthCredential credential,
  ) async {
    _log('Refreshing credential');

    if (credential.refreshToken == null) {
      _log('No refresh token, re-authenticating');
      return authenticate(skipCache: true);
    }

    final meta = await _fetchOAuthMetadata();
    if (meta == null) {
      _log('Metadata fetch failed, re-authenticating');
      return authenticate(skipCache: true);
    }

    final tokenEp = meta['token_endpoint'] as String?;
    if (tokenEp == null) {
      _log('No token endpoint, re-authenticating');
      return authenticate(skipCache: true);
    }

    try {
      final bodyParams = <String, String>{
        'grant_type': 'refresh_token',
        'refresh_token': credential.refreshToken!,
        'resource': _baseUrl,
      };
      if (credential.clientId != null) {
        bodyParams['client_id'] = credential.clientId!;
      }

      final client = HttpClient();
      final request = await client.postUrl(Uri.parse(tokenEp));
      request.headers.contentType = ContentType(
        'application', 'x-www-form-urlencoded',
      );
      request.write(bodyParams.map((k, v) => MapEntry(k, Uri.encodeQueryComponent(v))).entries.map((e) => '${e.key}=${e.value}').join('&'));
      final response = await request.close().timeout(const Duration(seconds: 15));
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        final newCredential = OAuthCredential(
          profileId: credential.profileId,
          accessToken: data['access_token'] as String,
          refreshToken:
              data['refresh_token'] as String? ?? credential.refreshToken,
          expiresAt: data.containsKey('expires_in')
              ? DateTime.now().add(
                  Duration(seconds: data['expires_in'] as int),
                )
              : null,
          serverUrl: serverUrl,
          clientId: credential.clientId,
        );
        await _storage.saveCredential(newCredential);
        _log('Token refreshed and saved securely');
        return OAuthFlowResult(token: newCredential.accessToken);
      }
      _log('Refresh failed (${response.statusCode}), re-authenticating');
      return authenticate(skipCache: true);
    } catch (e) {
      _log('Refresh error: $e, re-authenticating');
      return authenticate(skipCache: true);
    }
  }

  Future<void> clearCredential() async {
    await _storage.deleteCredential(profileId: profileId, serverUrl: serverUrl);
  }

  Future<Map<String, dynamic>?> _fetchOAuthMetadata() async {
    String? metadataUrl;
    final asUri = _parseWwwAuthenticate(challengeHeaders?['www-authenticate']);
    if (asUri != null) {
      metadataUrl = '$asUri/.well-known/oauth-authorization-server';
    } else {
      metadataUrl = '$_baseUrl/.well-known/oauth-authorization-server';
    }

    _log('Fetching metadata: $metadataUrl');
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(metadataUrl));
      final response = await request.close().timeout(const Duration(seconds: 10));
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final ct = response.headers.contentType?.value ?? '';
        if (ct.contains('json')) {
          return jsonDecode(body) as Map<String, dynamic>;
        }
        final domain = _extractCfDomain(body);
        if (domain != null) return _buildManagedEndpoints(domain);
      }
    } catch (e) {
      _log('Metadata fetch error: $e');
    }

    final redirectDomain = await _discoverCfDomain();
    if (redirectDomain != null) return _buildManagedEndpoints(redirectDomain);

    final login = challengeHeaders?['cf-access-login'];
    if (login != null) {
      _log('Using CF-Access-Login: $login');
      return {
        'authorization_endpoint': '$login/authorize',
        'token_endpoint': '$login/token',
        'registration_endpoint': '$login/register',
      };
    }

    if (challengeBody != null) {
      final htmlDomain = _extractCfDomain(challengeBody!);
      if (htmlDomain != null) return _buildManagedEndpoints(htmlDomain);
    }

    return null;
  }

  Future<Map<String, dynamic>?> _registerClient(
    Map<String, dynamic> meta,
  ) async {
    final regEndpoint = meta['registration_endpoint'] as String?;
    if (regEndpoint == null || regEndpoint.isEmpty) {
      _log('No registration endpoint — proceeding without DCR');
      return null;
    }

    final cbPort = await _findFreePort();
    final redirectUri = _redirectUriFor(cbPort);
    _log('DCR: registering client at $regEndpoint with redirect_uri=$redirectUri');

    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse(regEndpoint));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'redirect_uris': [redirectUri],
        'token_endpoint_auth_method': 'none',
        'grant_types': ['authorization_code', 'refresh_token'],
        'response_types': ['code'],
        'client_name': 'CodeWalk',
        'client_uri': 'https://github.com/charleypeng/codewalk',
      }));
      final response = await request.close().timeout(const Duration(seconds: 15));
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        data['_redirect_uri'] = redirectUri;
        data['_cb_port'] = cbPort;
        _log('DCR succeeded: client_id=${data['client_id']}');
        return data;
      }
      _log('DCR failed: ${response.statusCode} — proceeding without DCR');
    } catch (e) {
      _log('DCR error: $e — proceeding without DCR');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _runPkceFlow(
    Map<String, dynamic> meta,
    Map<String, dynamic>? client,
  ) async {
    final authEp = meta['authorization_endpoint'] as String?;
    final tokenEp = meta['token_endpoint'] as String?;
    if (authEp == null || tokenEp == null) return null;

    final verifier = _generateVerifier();
    final challenge = _generateChallenge(verifier);
    final state = _generateVerifier();

    final clientId = client?['client_id'] as String?;
    final cbPort = client?['_cb_port'] as int?;
    final redirectUri =
        client?['_redirect_uri'] as String? ?? _redirectUriFor(cbPort);

    final params = <String, String>{
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      'state': state,
      'resource': _baseUrl,
    };
    if (clientId != null) params['client_id'] = clientId;

    final authUri = Uri.parse(authEp).replace(queryParameters: params);
    _log('Opening browser: $authEp');

    final code = await _launchAndCapture(authUri, redirectUri, state);
    if (code == null) return null;
    _log('Authorization code received');

    return _exchangeCode(tokenEp, code, verifier, redirectUri, clientId);
  }

  Future<String?> _launchAndCapture(
    Uri authUri,
    String redirectUri,
    String state,
  ) async {
    final port = Uri.parse(redirectUri).port;
    final completer = Completer<String?>();
    HttpServer? server;

    try {
      server = await HttpServer.bind('127.0.0.1', port, shared: true);
      _log('Callback server listening on 127.0.0.1:$port');
      server.listen((req) {
        _log('Callback received: ${req.uri}');
        final code = req.uri.queryParameters['code'];
        final returnedState = req.uri.queryParameters['state'];
        final errorParam = req.uri.queryParameters['error'];

        if (errorParam != null) {
          _log('Auth error from provider: $errorParam');
          completer.complete(null);
        } else if (code != null && returnedState == state) {
          _log('Authorization code received (state matched)');
          completer.complete(code);
        } else if (code != null) {
          _log('State mismatch but code present (expected: $state, got: $returnedState)');
          completer.complete(code);
        } else {
          _log('Callback missing both code and error parameters');
          completer.complete(null);
        }

        req.response.statusCode = 200;
        req.response.headers.contentType = ContentType.html;
        req.response.write(_successPage());
        req.response.close();
      });
    } catch (e) {
      _log('Callback server failed to start on port $port: $e');
      completer.complete(null);
      return completer.future;
    }

    final launched = await launchUrl(
      authUri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      _log('Browser failed to open');
      await server.close();
      completer.complete(null);
      return completer.future;
    }

    _log('Waiting for callback (timeout: 5 min)...');
    final result = await completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        _log('Login timed out after 5 minutes');
        return null;
      },
    );
    await server.close();
    _log('Callback server stopped');
    return result;
  }

  Future<Map<String, dynamic>?> _exchangeCode(
    String tokenEp,
    String code,
    String verifier,
    String redirectUri,
    String? clientId,
  ) async {
    _log('Exchanging authorization code at $tokenEp');
    final bodyParams = <String, String>{
      'grant_type': 'authorization_code',
      'code': code,
      'code_verifier': verifier,
      'redirect_uri': redirectUri,
      'resource': _baseUrl,
    };
    if (clientId != null) bodyParams['client_id'] = clientId;

    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse(tokenEp));
      request.headers.contentType = ContentType(
        'application', 'x-www-form-urlencoded',
      );
      request.write(bodyParams.entries.map((e) =>
        '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}'
      ).join('&'));
      final response = await request.close().timeout(const Duration(seconds: 15));
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        _log('Token exchange failed: ${response.statusCode} body=${body.length > 200 ? '${body.substring(0, 200)}...' : body}');
        return null;
      }
      final data = jsonDecode(body) as Map<String, dynamic>;
      final hasAccess = data.containsKey('access_token');
      final hasRefresh = data.containsKey('refresh_token');
      final expiresIn = data['expires_in'];
      _log('Token exchange OK: access_token=${hasAccess ? 'present' : 'MISSING'}, '
          'refresh_token=${hasRefresh ? 'present' : 'absent'}, '
          'expires_in=$expiresIn');
      return data;
    } catch (e) {
      _log('Token exchange error: $e');
      return null;
    }
  }

  String? _parseWwwAuthenticate(String? header) {
    if (header == null) return null;
    final asUriMatch = RegExp(
      """as_uri=['"]([^'"]+)['"]""",
    ).firstMatch(header);
    if (asUriMatch != null) return asUriMatch.group(1);
    if (header.startsWith('Cloudflare-Access')) return _baseUrl;
    return null;
  }

  Future<String?> _discoverCfDomain() async {
    try {
      final client = HttpClient();
      client.autoUncompress = false;
      final request = await client.getUrl(Uri.parse(_baseUrl));
      final response = await request.close().timeout(const Duration(seconds: 10));
      final location = response.headers.value('location');
      await response.drain<List<int>>();
      if (location != null) {
        final uri = Uri.tryParse(location);
        if (uri != null && uri.host.contains('cloudflareaccess.com')) {
          return uri.host;
        }
      }
    } catch (e) {
      _log('Redirect probe: $e');
    }
    return null;
  }

  Map<String, dynamic> _buildManagedEndpoints(String domain) {
    return {
      'authorization_endpoint':
          'https://$domain/cdn-cgi/access/oauth/managed/authorize',
      'token_endpoint': 'https://$domain/cdn-cgi/access/oauth/managed/token',
      'registration_endpoint':
          'https://$domain/cdn-cgi/access/oauth/managed/register',
    };
  }

  String? _extractCfDomain(String html) {
    final patterns = [
      RegExp(r'''https?://([a-zA-Z0-9][-a-zA-Z0-9]*\.cloudflareaccess\.com)'''),
      RegExp(
        r'''(?:action|src|href|data-url)=["\']https?://([a-zA-Z0-9][-a-zA-Z0-9]*\.cloudflareaccess\.com)''',
      ),
      RegExp(r'''["\'](https?://[^"\']*\.cloudflareaccess\.com[^"\']*)["\']'''),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null) {
        var domain = match.group(1)!;
        if (domain.startsWith('http')) {
          domain = Uri.parse(domain).host;
        }
        if (domain.contains('cloudflareaccess.com')) return domain;
      }
    }
    return null;
  }

  String _generateVerifier() {
    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _generateChallenge(String verifier) {
    final bytes = sha256.convert(utf8.encode(verifier)).bytes;
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  Future<int> _findFreePort() async {
    final s = await ServerSocket.bind('127.0.0.1', 0);
    final port = s.port;
    await s.close();
    return port;
  }

  String _redirectUriFor(int? port) {
    return 'http://127.0.0.1:${port ?? 61308}';
  }

  String get _baseUrl {
    var url = serverUrl.trim();
    if (!url.contains('://')) url = 'http://$url';
    final uri = Uri.parse(url);
    final portStr = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$portStr';
  }

  String _successPage() => '''<!DOCTYPE html>
<html><head><title>Authentication Complete</title>
<style>
  body { font-family: system-ui, -apple-system, sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; background: #f5f5f5 }
  .card { text-align: center; padding: 40px; background: white; border-radius: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.1) }
  .check { width: 64px; height: 64px; margin: 0 auto 16px; border-radius: 50%; background: #10b981; display: flex; align-items: center; justify-content: center }
  .check svg { width: 32px; height: 32px }
  h2 { font-size: 18px; color: #333; margin: 0 0 8px 0; font-weight: 600 }
  p { font-size: 14px; color: #666; margin: 0 }
</style></head>
<body><div class="card">
<div class="check"><svg viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="3"><path d="M20 6L9 17l-5-5"/></svg></div>
<h2>Authentication successful</h2>
<p>You can close this tab and return to the app.</p>
</div></body></html>''';

  void _log(String msg) {
    AppLogger.debug('[OAuth] $msg');
  }
}
