import 'package:codewalk/presentation/services/windows_microphone_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WindowsMicrophoneService', () {
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('probe() returns notSupported on non-Windows without invoking channel',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final service = const WindowsMicrophoneService();
      expect(await service.probe(), WindowsMicrophoneAccessStatus.notSupported);
    });

    test('probe() parses known status strings on Windows', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      const channel = MethodChannel('codewalk/windows_microphone');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

      Future<WindowsMicrophoneAccessStatus> probeWith(String? raw) async {
        messenger.setMockMethodCallHandler(channel, (call) async => raw);
        return const WindowsMicrophoneService().probe();
      }

      try {
        expect(
          await probeWith('allowed'),
          WindowsMicrophoneAccessStatus.allowed,
        );
        expect(
          await probeWith('denied'),
          WindowsMicrophoneAccessStatus.denied,
        );
        expect(
          await probeWith('noInputDevice'),
          WindowsMicrophoneAccessStatus.noInputDevice,
        );
        expect(
          await probeWith('deviceBusy'),
          WindowsMicrophoneAccessStatus.deviceBusy,
        );
        expect(
          await probeWith('notSupported'),
          WindowsMicrophoneAccessStatus.notSupported,
        );
        expect(
          await probeWith('bogus'),
          WindowsMicrophoneAccessStatus.unknown,
        );
        expect(
          await probeWith(null),
          WindowsMicrophoneAccessStatus.unknown,
        );
      } finally {
        messenger.setMockMethodCallHandler(channel, null);
      }
    });

    test('probe() maps PlatformException to unknown on Windows', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      const channel = MethodChannel('codewalk/windows_microphone');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'E_FAIL', message: 'fail');
      });
      try {
        final status = await const WindowsMicrophoneService().probe();
        expect(status, WindowsMicrophoneAccessStatus.unknown);
      } finally {
        messenger.setMockMethodCallHandler(channel, null);
      }
    });

    test('probe() maps MissingPluginException to notSupported on Windows',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      const channel = MethodChannel('codewalk/windows_microphone');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw MissingPluginException('not registered');
      });
      try {
        final status = await const WindowsMicrophoneService().probe();
        expect(status, WindowsMicrophoneAccessStatus.notSupported);
      } finally {
        messenger.setMockMethodCallHandler(channel, null);
      }
    });
  });
}
