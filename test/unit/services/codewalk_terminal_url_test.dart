import 'package:codewalk/presentation/services/codewalk_terminal_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildCodewalkTerminalSocketUrl', () {
    test('converts http base url to websocket terminal url', () {
      final url = buildCodewalkTerminalSocketUrl(
        baseUrl: 'http://localhost:4096',
        ptyId: 'pty_1',
        directory: '/repo',
      );

      expect(
        url.toString(),
        'ws://localhost:4096/pty/pty_1/connect?directory=%2Frepo',
      );
    });

    test('preserves base path and secure scheme', () {
      final url = buildCodewalkTerminalSocketUrl(
        baseUrl: 'https://example.com/base/',
        ptyId: 'pty_1',
        directory: '/repo',
        cursor: -1,
      );

      expect(
        url.toString(),
        'wss://example.com/base/pty/pty_1/connect?directory=%2Frepo&cursor=-1',
      );
    });
  });
}
