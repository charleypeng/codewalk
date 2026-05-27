import 'package:codewalk/core/auth/oauth_service_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OAuthService callback validation', () {
    test('accepts only matching state on the exact callback path', () {
      final accepted = OAuthService.validateCallback(
        uri: Uri.parse('/oauth/callback?code=abc&state=expected'),
        expectedState: 'expected',
        expectedPath: '/oauth/callback',
      );

      expect(accepted.decision, OAuthCallbackDecision.acceptCode);
      expect(accepted.code, 'abc');
    });

    test('rejects mismatched state even when code is present', () {
      final rejected = OAuthService.validateCallback(
        uri: Uri.parse('/oauth/callback?code=abc&state=attacker'),
        expectedState: 'expected',
        expectedPath: '/oauth/callback',
      );

      expect(rejected.decision, OAuthCallbackDecision.rejectTerminal);
      expect(rejected.code, isNull);
    });

    test('ignores callbacks on the wrong path', () {
      final ignored = OAuthService.validateCallback(
        uri: Uri.parse('/favicon.ico?code=abc&state=expected'),
        expectedState: 'expected',
        expectedPath: '/oauth/callback',
      );

      expect(ignored.decision, OAuthCallbackDecision.ignoreWrongPath);
      expect(ignored.isTerminal, isFalse);
    });
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
  });
}
