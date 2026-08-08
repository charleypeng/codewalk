import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:codewalk/core/auth/oauth_service_io.dart';
import 'package:flutter_test/flutter_test.dart';

final _expectedRedirectUri = Uri.parse('http://127.0.0.1:43123/oauth/callback');

OAuthCallbackValidation _validateCallback(
  String requestTarget, {
  String method = 'GET',
  String requestScheme = 'http',
  String? hostHeader = '127.0.0.1:43123',
  String expectedState = 'expected',
}) {
  return OAuthService.validateCallback(
    method: method,
    requestTarget: Uri.parse(requestTarget),
    requestScheme: requestScheme,
    hostHeader: hostHeader,
    expectedRedirectUri: _expectedRedirectUri,
    expectedState: expectedState,
  );
}

void main() {
  test('one loopback redirect URI is reused by every OAuth request stage', () {
    final redirectUri = OAuthService.loopbackRedirectUriForPort(43123);
    final registration = OAuthService.clientRegistrationPayload(
      redirectUri: redirectUri,
      resource: 'https://code.example.com',
    );
    final authorization = OAuthService.authorizationParameters(
      redirectUri: redirectUri,
      challenge: 'challenge',
      state: 'state',
      resource: 'https://code.example.com',
      clientId: 'client-id',
    );
    final exchange = OAuthService.authorizationCodeParameters(
      code: 'code',
      verifier: 'verifier',
      redirectUri: redirectUri,
      resource: 'https://code.example.com',
      clientId: 'client-id',
    );

    expect(redirectUri, _expectedRedirectUri.toString());
    expect(registration['redirect_uris'], <String>[redirectUri]);
    expect(authorization['redirect_uri'], redirectUri);
    expect(exchange['redirect_uri'], redirectUri);
    expect(authorization['resource'], 'https://code.example.com');
    expect(exchange['resource'], 'https://code.example.com');
  });

  group('OAuth response body limits', () {
    test('reads a response within its byte limit', () async {
      final body = await OAuthService.readBoundedBody(
        Stream<List<int>>.value(utf8.encode('bounded')),
        maxBytes: 7,
      );

      expect(body, 'bounded');
    });

    test('rejects a response that exceeds its byte limit', () async {
      await expectLater(
        OAuthService.readBoundedBody(
          Stream<List<int>>.value(utf8.encode('too-large')),
          maxBytes: 3,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('enforces a total body-read deadline', () async {
      final controller = StreamController<List<int>>();
      addTearDown(controller.close);
      controller.add(utf8.encode('partial'));

      await expectLater(
        OAuthService.readBoundedBody(
          controller.stream,
          timeout: const Duration(milliseconds: 50),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });
  });

  test('authorization code retry stops after a possible request send', () {
    const error = SocketException('network unavailable');

    expect(
      OAuthService.canRetryAuthorizationCodeExchange(
        error: error,
        requestMayHaveBeenSent: false,
      ),
      isTrue,
    );
    expect(
      OAuthService.canRetryAuthorizationCodeExchange(
        error: error,
        requestMayHaveBeenSent: true,
      ),
      isFalse,
    );
    expect(
      OAuthService.canRetryAuthorizationCodeExchange(
        error: const FormatException('bad response'),
        requestMayHaveBeenSent: false,
      ),
      isFalse,
    );
  });

  group('OAuthService callback validation', () {
    test('accepts one code and matching state on the exact callback', () {
      final accepted = _validateCallback(
        '/oauth/callback?code=abc&state=expected',
      );

      expect(accepted.decision, OAuthCallbackDecision.acceptCode);
      expect(accepted.code, 'abc');
    });

    test('ignores unrelated paths without terminating the flow', () {
      final ignored = [
        _validateCallback(
          '/favicon.ico?code=abc&state=expected',
          method: 'POST',
          hostHeader: null,
        ),
        _validateCallback('/oauth%2Fcallback?code=abc&state=expected'),
      ];

      for (final validation in ignored) {
        expect(validation.decision, OAuthCallbackDecision.ignoreWrongPath);
        expect(validation.isTerminal, isFalse);
      }
    });

    test('rejects non-GET requests on the callback path', () {
      final rejected = _validateCallback(
        '/oauth/callback?code=abc&state=expected',
        method: 'POST',
      );

      expect(rejected.decision, OAuthCallbackDecision.rejectTerminal);
    });

    test('rejects callbacks with the wrong scheme, host, or port', () {
      final validations = [
        _validateCallback(
          '/oauth/callback?code=abc&state=expected',
          requestScheme: 'https',
        ),
        _validateCallback(
          '/oauth/callback?code=abc&state=expected',
          hostHeader: 'localhost:43123',
        ),
        _validateCallback(
          '/oauth/callback?code=abc&state=expected',
          hostHeader: '127.0.0.1:43124',
        ),
        _validateCallback(
          '/oauth/callback?code=abc&state=expected',
          hostHeader: null,
        ),
        _validateCallback(
          '/oauth/callback?code=abc&state=expected',
          hostHeader: 'attacker@127.0.0.1:43123',
        ),
      ];

      for (final validation in validations) {
        expect(validation.decision, OAuthCallbackDecision.rejectTerminal);
      }
    });

    test('requires exactly one non-empty matching state', () {
      final validations = [
        _validateCallback('/oauth/callback?code=abc'),
        _validateCallback('/oauth/callback?code=abc&state='),
        _validateCallback('/oauth/callback?code=abc&state=attacker'),
        _validateCallback(
          '/oauth/callback?code=abc&state=expected&state=expected',
        ),
      ];

      for (final validation in validations) {
        expect(validation.decision, OAuthCallbackDecision.rejectTerminal);
      }
    });

    test('requires exactly one non-empty code and no error', () {
      final validations = [
        _validateCallback('/oauth/callback?state=expected'),
        _validateCallback('/oauth/callback?code=&state=expected'),
        _validateCallback('/oauth/callback?code=abc&code=def&state=expected'),
        _validateCallback(
          '/oauth/callback?code=abc&error=denied&state=expected',
        ),
      ];

      for (final validation in validations) {
        expect(validation.decision, OAuthCallbackDecision.rejectTerminal);
        expect(validation.code, isNull);
      }
    });

    test('accepts one provider error only with matching state', () {
      final rejected = _validateCallback(
        '/oauth/callback?error=access_denied&state=expected'
        '&error_description=sensitive',
      );

      expect(rejected.decision, OAuthCallbackDecision.rejectProviderError);
      expect(rejected.code, isNull);
    });

    test('rejects empty or repeated provider errors', () {
      final validations = [
        _validateCallback('/oauth/callback?error=&state=expected'),
        _validateCallback(
          '/oauth/callback?error=denied&error=other&state=expected',
        ),
        _validateCallback('/oauth/callback?error=denied&state=attacker'),
      ];

      for (final validation in validations) {
        expect(validation.decision, OAuthCallbackDecision.rejectTerminal);
      }
    });
  });

  test('OAuth callback completion is single-use', () {
    final guard = OAuthCallbackCompletionGuard();

    expect(guard.tryMarkTerminal(), isTrue);
    expect(guard.isTerminal, isTrue);
    expect(guard.tryMarkTerminal(), isFalse);
  });

  test('token exchange HTTP failures never include response bodies', () {
    final failure = OAuthService.tokenExchangeHttpFailure(400);

    expect(failure, 'Token exchange failed (HTTP 400). Please try again.');
    expect(failure, isNot(contains('body')));
    expect(failure, isNot(contains('token')));
  });

  group('OAuthService Cloudflare host validation', () {
    test('accepts exact Cloudflare Access hosts only', () {
      expect(
        OAuthService.isCloudflareAccessHost('team.cloudflareaccess.com'),
        isTrue,
      );
      expect(
        OAuthService.isCloudflareAccessHost('evilcloudflareaccess.com'),
        isFalse,
      );
      expect(
        OAuthService.isCloudflareAccessHost('cloudflareaccess.com.evil.test'),
        isFalse,
      );
    });

    test('accepts only HTTPS Cloudflare OAuth endpoints', () {
      expect(
        OAuthService.isTrustedOAuthEndpoint(
          'https://team.cloudflareaccess.com/oauth/token',
        ),
        isTrue,
      );
      expect(
        OAuthService.isTrustedOAuthEndpoint(
          'http://team.cloudflareaccess.com/oauth/token',
        ),
        isFalse,
      );
      expect(
        OAuthService.isTrustedOAuthEndpoint(
          'https://attacker@team.cloudflareaccess.com/oauth/token',
        ),
        isFalse,
      );
      expect(
        OAuthService.isTrustedOAuthEndpoint(
          'https://team.cloudflareaccess.com:8443/oauth/token',
        ),
        isFalse,
      );
    });

    test('trusts metadata only on the configured or Cloudflare origin', () {
      const serverUrl = 'https://code.example.com:8443';

      expect(
        OAuthService.isTrustedOAuthMetadataEndpoint(
          value:
              'https://code.example.com:8443/.well-known/'
              'oauth-authorization-server',
          serverUrl: serverUrl,
        ),
        isTrue,
      );
      expect(
        OAuthService.isTrustedOAuthMetadataEndpoint(
          value:
              'https://team.cloudflareaccess.com/.well-known/'
              'oauth-authorization-server',
          serverUrl: serverUrl,
        ),
        isTrue,
      );
      expect(
        OAuthService.isTrustedOAuthMetadataEndpoint(
          value:
              'https://attacker.example/.well-known/'
              'oauth-authorization-server',
          serverUrl: serverUrl,
        ),
        isFalse,
      );
      expect(
        OAuthService.isTrustedOAuthMetadataEndpoint(
          value:
              'http://code.example.com:8443/.well-known/'
              'oauth-authorization-server',
          serverUrl: serverUrl,
        ),
        isFalse,
      );
    });
  });
}
