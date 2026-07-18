import 'package:codewalk/presentation/services/local_opencode_server_runtime_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('selectLocalOpencodeReleaseAssetName', () {
    test('prefers native Windows ARM64 archive', () {
      final selected = selectLocalOpencodeReleaseAssetName(
        availableAssetNames: const <String>[
          'opencode-windows-x64.zip',
          'opencode-windows-arm64.zip',
        ],
        platform: TargetPlatform.windows,
        isArm64: true,
      );

      expect(selected, 'opencode-windows-arm64.zip');
    });

    test('falls back to Windows x64 on ARM64', () {
      final selected = selectLocalOpencodeReleaseAssetName(
        availableAssetNames: const <String>['opencode-windows-x64.zip'],
        platform: TargetPlatform.windows,
        isArm64: true,
      );

      expect(selected, 'opencode-windows-x64.zip');
    });

    test('does not select Windows ARM64 archive for x64', () {
      final selected = selectLocalOpencodeReleaseAssetName(
        availableAssetNames: const <String>['opencode-windows-arm64.zip'],
        platform: TargetPlatform.windows,
        isArm64: false,
      );

      expect(selected, isNull);
    });

    test('preserves macOS archive preferences', () {
      expect(
        selectLocalOpencodeReleaseAssetName(
          availableAssetNames: const <String>[
            'opencode-darwin-x64-baseline.zip',
            'opencode-darwin-x64.zip',
          ],
          platform: TargetPlatform.macOS,
          isArm64: false,
        ),
        'opencode-darwin-x64.zip',
      );
      expect(
        selectLocalOpencodeReleaseAssetName(
          availableAssetNames: const <String>[
            'opencode-darwin-x64.zip',
            'opencode-darwin-arm64.zip',
          ],
          platform: TargetPlatform.macOS,
          isArm64: true,
        ),
        'opencode-darwin-arm64.zip',
      );
    });

    test('preserves Linux archive preferences', () {
      expect(
        selectLocalOpencodeReleaseAssetName(
          availableAssetNames: const <String>[
            'opencode-linux-x64-baseline-musl.tar.gz',
            'opencode-linux-x64-musl.tar.gz',
            'opencode-linux-x64-baseline.tar.gz',
          ],
          platform: TargetPlatform.linux,
          isArm64: false,
        ),
        'opencode-linux-x64-baseline.tar.gz',
      );
      expect(
        selectLocalOpencodeReleaseAssetName(
          availableAssetNames: const <String>[
            'opencode-linux-arm64-musl.tar.gz',
            'opencode-linux-arm64.tar.gz',
          ],
          platform: TargetPlatform.linux,
          isArm64: true,
        ),
        'opencode-linux-arm64.tar.gz',
      );
    });

    test('ignores Desktop installers and unrelated assets', () {
      final selected = selectLocalOpencodeReleaseAssetName(
        availableAssetNames: const <String>[
          'opencode-desktop-win-arm64.exe',
          'checksums.txt',
        ],
        platform: TargetPlatform.windows,
        isArm64: true,
      );

      expect(selected, isNull);
    });

    test('returns null when no CLI archive matches', () {
      final selected = selectLocalOpencodeReleaseAssetName(
        availableAssetNames: const <String>['opencode-windows-x64.zip'],
        platform: TargetPlatform.android,
        isArm64: true,
      );

      expect(selected, isNull);
    });
  });
}
