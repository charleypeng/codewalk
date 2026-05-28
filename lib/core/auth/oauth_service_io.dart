import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/logging/app_logger.dart';
import 'oauth_credential.dart';
import 'oauth_service_result.dart';
import 'oauth_token_storage.dart';

enum OAuthCallbackDecision { ignoreWrongPath, acceptCode, rejectTerminal }

class OAuthCallbackValidation {
  const OAuthCallbackValidation(this.decision, [this.code]);

  final OAuthCallbackDecision decision;
  final String? code;

  bool get isTerminal => decision != OAuthCallbackDecision.ignoreWrongPath;
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

  static bool isCloudflareAccessHost(String host) {
    final lower = host.toLowerCase();
    return lower == 'cloudflareaccess.com' ||
        lower.endsWith('.cloudflareaccess.com');
  }

  static OAuthCallbackValidation validateCallback({
    required Uri uri,
    required String expectedState,
    required String expectedPath,
  }) {
    if (uri.path != expectedPath) {
      return const OAuthCallbackValidation(
        OAuthCallbackDecision.ignoreWrongPath,
      );
    }
    final code = uri.queryParameters['code'];
    final returnedState = uri.queryParameters['state'];
    final errorParam = uri.queryParameters['error'];
    if (errorParam != null) {
      return const OAuthCallbackValidation(
        OAuthCallbackDecision.rejectTerminal,
      );
    }
    if (code != null && returnedState == expectedState) {
      return OAuthCallbackValidation(OAuthCallbackDecision.acceptCode, code);
    }
    return const OAuthCallbackValidation(OAuthCallbackDecision.rejectTerminal);
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

    final tokenData = await _runPkceFlow(meta);
    if (tokenData == null) {
      return OAuthFlowResult(
        log: [],
        error: 'Browser authentication did not complete',
        token: null,
      );
    }
    _log('Token received');

    final client = tokenData.remove('_client') as Map<String, dynamic>?;
    _log('Client registration ${client == null ? 'not used' : 'completed'}');

    final accessToken = tokenData['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      return OAuthFlowResult(
        log: [],
        error: 'OAuth token response did not include an access token.',
        token: null,
      );
    }

    final credential = OAuthCredential(
      profileId: profileId,
      accessToken: accessToken,
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
    HttpClient? client;
    try {
      client = HttpClient();
      final request = await client.getUrl(Uri.parse(metadataUrl));
      final response = await request.close().timeout(const Duration(seconds: 10));
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final ct = response.headers.contentType?.value ?? '';
        if (ct.contains('json')) {
          final data = jsonDecode(body) as Map<String, dynamic>;
          if (_metadataEndpointsAreTrusted(data)) {
            return data;
          }
          _log('Metadata rejected because endpoint hosts are not trusted');
          return null;
        }
        final domain = _extractCfDomain(body);
        if (domain != null) return _buildManagedEndpoints(domain);
      }
    } catch (e) {
      _log('Metadata fetch error: $e');
    } finally {
      client?.close(force: true);
    }

    final redirectDomain = await _discoverCfDomain();
    if (redirectDomain != null) return _buildManagedEndpoints(redirectDomain);

    final login = challengeHeaders?['cf-access-login'];
    if (login != null) {
      final loginUri = Uri.tryParse(login);
      if (loginUri == null || !isCloudflareAccessHost(loginUri.host)) {
        _log('Ignoring untrusted CF-Access-Login host');
        return null;
      }
      _log('Using CF-Access-Login endpoint');
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
    String redirectUri,
  ) async {
    final regEndpoint = meta['registration_endpoint'] as String?;
    if (regEndpoint == null || regEndpoint.isEmpty) {
      _log('No registration endpoint — proceeding without DCR');
      return null;
    }

    _log('DCR: registering loopback client');

    HttpClient? httpClient;
    try {
      httpClient = HttpClient();
      final request = await httpClient.postUrl(Uri.parse(regEndpoint));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'redirect_uris': [redirectUri],
        'token_endpoint_auth_method': 'none',
        'grant_types': ['authorization_code', 'refresh_token'],
        'response_types': ['code'],
        'client_name': 'CodeWalk',
        'client_uri': 'https://github.com/verseles/codewalk',
        'resource': _baseUrl,
      }));
      final response = await request.close().timeout(const Duration(seconds: 15));
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        _log('DCR succeeded');
        return data;
      }
      _log('DCR failed: ${response.statusCode} — proceeding without DCR');
    } catch (e) {
      _log('DCR error: $e — proceeding without DCR');
    } finally {
      httpClient?.close(force: true);
    }
    return null;
  }

  Future<Map<String, dynamic>?> _runPkceFlow(
    Map<String, dynamic> meta,
  ) async {
    if (Platform.isAndroid) {
      return _runPkceFlowAndroid(meta);
    }

    final authEp = meta['authorization_endpoint'] as String?;
    final tokenEp = meta['token_endpoint'] as String?;
    if (authEp == null || tokenEp == null) return null;

    final callbackServer = await HttpServer.bind('127.0.0.1', 0);
    try {
      final redirectUri = _redirectUriFor(callbackServer.port);
      final client = await _registerClient(meta, redirectUri);

      final verifier = _generateVerifier();
      final challenge = _generateChallenge(verifier);
      final state = _generateVerifier();

      final clientId = client?['client_id'] as String?;

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

      final code = await _launchAndCapture(
        authUri,
        redirectUri,
        state,
        callbackServer,
      );
      if (code == null) return null;
      _log('Authorization code received');

      final data = await _exchangeCode(
        tokenEp,
        code,
        verifier,
        redirectUri,
        clientId,
      );
      if (data != null) {
        data['_client'] = client;
      }
      return data;
    } finally {
      await callbackServer.close(force: true);
    }
  }

  Future<Map<String, dynamic>?> _runPkceFlowAndroid(
    Map<String, dynamic> meta,
  ) async {
    final authEp = meta['authorization_endpoint'] as String?;
    final tokenEp = meta['token_endpoint'] as String?;
    if (authEp == null || tokenEp == null) return null;

    final redirectUri = _redirectUriFor(null);
    final client = await _registerClient(meta, redirectUri);
    final dcrClientId = client?['client_id'] as String?;
    final clientId = dcrClientId ?? 'codewalk';

    final appAuth = FlutterAppAuth();

    try {
      _log('Opening Chrome Custom Tab: $authEp');
      final AuthorizationResponse? result = await appAuth.authorize(
        AuthorizationRequest(
          clientId,
          redirectUri,
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: authEp,
            tokenEndpoint: tokenEp,
          ),
          additionalParameters: {'resource': _baseUrl},
          allowInsecureConnections: true,
        ),
      );

      if (result == null) {
        _log('User cancelled OAuth authorization');
        return null;
      }

      _log('Authorization code received from Chrome Custom Tab');

      final authCode = result.authorizationCode;
      if (authCode == null) {
        _log('flutter_appauth did not return an authorization code');
        return null;
      }
      final codeVerifier = result.codeVerifier;
      if (codeVerifier == null) {
        _log('flutter_appauth did not return a code verifier');
        return null;
      }

      final data = await _exchangeCode(
        tokenEp,
        authCode,
        codeVerifier,
        redirectUri,
        dcrClientId,
      );
      if (data != null) {
        data['_client'] = client;
      }
      return data;
    } catch (e) {
      _log('OAuth authorization failed on Android: $e');
      return null;
    }
  }

  Future<String?> _launchAndCapture(
    Uri authUri,
    String redirectUri,
    String state,
    HttpServer server,
  ) async {
    final callbackPath = Uri.parse(redirectUri).path;
    final completer = Completer<String?>();
    var terminal = false;

    void completeOnce(String? code) {
      if (terminal) return;
      terminal = true;
      completer.complete(code);
    }

    try {
      _log('Callback server listening on loopback');
      server.listen((req) async {
        if (terminal) {
          req.response.statusCode = 409;
          try {
            await req.response.close().timeout(const Duration(seconds: 2));
          } catch (_) {}
          return;
        }
        _log('Callback received on path ${req.uri.path}');
        final validation = validateCallback(
          uri: req.uri,
          expectedState: state,
          expectedPath: callbackPath,
        );
        if (validation.decision == OAuthCallbackDecision.ignoreWrongPath) {
          req.response.statusCode = 404;
          try {
            await req.response.close().timeout(const Duration(seconds: 2));
          } catch (_) {}
          return;
        }

        final accepted = validation.decision == OAuthCallbackDecision.acceptCode;
        if (accepted) {
          _log('Authorization code received (state matched)');
        } else if (req.uri.queryParameters['error'] != null) {
          _log('Auth error from provider');
        } else if (req.uri.queryParameters['code'] != null) {
          _log('State mismatch; rejecting callback');
        } else {
          _log('Callback missing both code and error parameters');
        }

        req.response.statusCode = accepted ? 200 : 400;
        req.response.headers.contentType = ContentType.html;
        req.response.write(accepted ? _successPage() : _errorPage());
        final completionCode = accepted ? validation.code : null;
        terminal = true;
        try {
          await req.response.close().timeout(const Duration(seconds: 2));
        } catch (_) {
          _log('Callback response closed before page flush completed');
        } finally {
          if (!completer.isCompleted) {
            completer.complete(completionCode);
          }
        }
      });
    } catch (e) {
      _log('Callback server failed: $e');
      completeOnce(null);
      return completer.future;
    }

    final launched = await launchUrl(
      authUri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      _log('Browser failed to open');
      completeOnce(null);
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
    await server.close(force: true);
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

    HttpClient? client;
    try {
      client = HttpClient();
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
    } finally {
      client?.close(force: true);
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
    HttpClient? client;
    try {
      client = HttpClient();
      client.autoUncompress = false;
      final request = await client.getUrl(Uri.parse(_baseUrl));
      request.followRedirects = false;
      final response = await request.close().timeout(const Duration(seconds: 10));
      final location = response.headers.value('location');
      await response.drain<List<int>>();
      if (location != null) {
        final uri = Uri.tryParse(location);
        if (uri != null && isCloudflareAccessHost(uri.host)) {
          return uri.host;
        }
      }
    } catch (e) {
      _log('Redirect probe: $e');
    } finally {
      client?.close(force: true);
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
        if (isCloudflareAccessHost(domain)) return domain;
      }
    }
    return null;
  }

  bool _metadataEndpointsAreTrusted(Map<String, dynamic> metadata) {
    final auth = metadata['authorization_endpoint'] as String?;
    final token = metadata['token_endpoint'] as String?;
    final register = metadata['registration_endpoint'] as String?;
    return _isTrustedOAuthEndpoint(auth) &&
        _isTrustedOAuthEndpoint(token) &&
        (register == null || _isTrustedOAuthEndpoint(register));
  }

  bool _isTrustedOAuthEndpoint(String? value) {
    if (value == null || value.isEmpty) return false;
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return false;
    }
    return isCloudflareAccessHost(uri.host);
  }

  String _generateVerifier() {
    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _generateChallenge(String verifier) {
    final bytes = sha256.convert(utf8.encode(verifier)).bytes;
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _redirectUriFor(int? port) {
    return 'http://127.0.0.1:${port ?? 61308}/oauth/callback';
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

  String _errorPage() => '''<!DOCTYPE html>
<html><head><title>Authentication Failed</title>
<style>
  body { font-family: system-ui, -apple-system, sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; background: #f5f5f5 }
  .card { text-align: center; padding: 40px; background: white; border-radius: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.1) }
  h2 { font-size: 18px; color: #991b1b; margin: 0 0 8px 0; font-weight: 600 }
  p { font-size: 14px; color: #666; margin: 0 }
</style></head>
<body><div class="card">
<h2>Authentication failed</h2>
<p>Return to CodeWalk and try again.</p>
</div></body></html>''';

  void _log(String msg) {
    AppLogger.debug('[OAuth] $msg');
  }
}
