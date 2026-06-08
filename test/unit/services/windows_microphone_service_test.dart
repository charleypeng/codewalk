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

      Future<WindowsMicrophoneAccessStatus> run(String? raw) async {
        var invocations = 0;
        channel.setMockMethodCallHandler((call) async {
          invocations += 1;
          return raw;
        });
        final result = await const WindowsMicrophoneService().probe();
        expect(invocations, 1);
        return result;
      }

      try {
        // Suppress the framework-level error log from the messenger about a
        // null response for our "unknown" branch by leaving the handler
        // unmapped and overriding per call.
        Future<WindowsMicrophoneAccessStatus> probeWith(String? raw) async {
          channel.setMockMethodCallHandler((call) async => raw);
          return const WindowsMicrophoneService().probe();
        }

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
        channel.setMockMethodCallHandler(null);
        messenger.setMockMessageHandler('codewalk/windows_microphone_stream',
            null);
      }
    });

    test('probe() maps PlatformException to unknown on Windows', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      const channel = MethodChannel('codewalk/windows_microphone');
      channel.setMockMethodCallHandler((call) async {
        throw PlatformException(code: 'E_FAIL', message: 'fail');
      });
      try {
        final status = await const WindowsMicrophoneService().probe();
        expect(status, WindowsMicrophoneAccessStatus.unknown);
      } finally {
        channel.setMockMethodCallHandler(null);
      }
    });
  });
}
