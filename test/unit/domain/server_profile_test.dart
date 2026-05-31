import 'package:codewalk/domain/entities/server_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServerProfile', () {
    test('persists Tailscale transport flag in JSON', () {
      const profile = ServerProfile(
        id: 'server-1',
        url: 'http://codewalk.tailnet.ts.net:4096',
        tailscaleEnabled: true,
        createdAt: 1,
        updatedAt: 2,
      );

      final restored = ServerProfile.fromJson(profile.toJson());

      expect(restored.tailscaleEnabled, isTrue);
      expect(restored, profile);
    });

    test('defaults Tailscale transport to disabled for older profiles', () {
      final profile = ServerProfile.fromJson(const <String, dynamic>{
        'id': 'server-1',
        'url': 'http://127.0.0.1:4096',
        'createdAt': 1,
        'updatedAt': 2,
      });

      expect(profile.tailscaleEnabled, isFalse);
    });
  });
}
