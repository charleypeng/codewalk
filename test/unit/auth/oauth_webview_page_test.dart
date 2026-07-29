import 'package:codewalk/presentation/pages/oauth_webview_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OAuthWebViewPage.isLoopbackCallback', () {
    test('matches 127.0.0.1 with the expected callback path', () {
      final uri = Uri.parse(
        'http://127.0.0.1:61308/oauth/callback?code=abc&state=xyz',
      );
      expect(
        OAuthWebViewPage.isLoopbackCallback(uri, '/oauth/callback'),
        isTrue,
      );
    });

    test('matches localhost host variant', () {
      final uri = Uri.parse('http://localhost/oauth/callback?code=abc');
      expect(
        OAuthWebViewPage.isLoopbackCallback(uri, '/oauth/callback'),
        isTrue,
      );
    });

    test('rejects non-loopback hosts', () {
      final uri = Uri.parse('https://example.com/oauth/callback?code=abc');
      expect(
        OAuthWebViewPage.isLoopbackCallback(uri, '/oauth/callback'),
        isFalse,
      );
    });

    test('rejects loopback host with a different path', () {
      final uri = Uri.parse('http://127.0.0.1:61308/favicon.ico');
      expect(
        OAuthWebViewPage.isLoopbackCallback(uri, '/oauth/callback'),
        isFalse,
      );
    });
  });
}
