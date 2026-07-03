import 'dart:typed_data';

import 'package:codewalk/presentation/services/speech_audio_capture.dart';
import 'package:codewalk/presentation/services/windows_microphone_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWindowsMicrophoneService extends WindowsMicrophoneService {
  _FakeWindowsMicrophoneService({
    required this.status,
    Stream<Uint8List>? stream,
  }) : stream = stream ?? Stream<Uint8List>.value(Uint8List.fromList([1, 2]));

  final WindowsMicrophoneAccessStatus status;
  final Stream<Uint8List> stream;
  int probeCount = 0;
  int streamCount = 0;
  int stopCount = 0;

  @override
  Future<WindowsMicrophoneAccessStatus> probe() async {
    probeCount += 1;
    return status;
  }

  @override
  Stream<Uint8List> pcmStream() {
    streamCount += 1;
    return stream;
  }

  @override
  Future<void> stopStream() async {
    stopCount += 1;
  }
}

void main() {
  group('SpeechAudioCapture Windows', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('uses Windows probe for permission', () async {
      final allowed = _FakeWindowsMicrophoneService(
        status: WindowsMicrophoneAccessStatus.allowed,
      );
      final denied = _FakeWindowsMicrophoneService(
        status: WindowsMicrophoneAccessStatus.denied,
      );

      expect(
        await SpeechAudioCapture(
          windowsMicrophoneService: allowed,
        ).hasPermission(),
        isTrue,
      );
      expect(
        await SpeechAudioCapture(
          windowsMicrophoneService: denied,
        ).hasPermission(),
        isFalse,
      );
      expect(allowed.probeCount, 1);
      expect(denied.probeCount, 1);
    });

    test('returns the Windows PCM stream for the supported format', () async {
      final service = _FakeWindowsMicrophoneService(
        status: WindowsMicrophoneAccessStatus.allowed,
      );
      final capture = SpeechAudioCapture(windowsMicrophoneService: service);

      final stream = await capture.startPcmStream(
        sampleRate: 16000,
        numChannels: 1,
      );

      expect(await stream.first, orderedEquals([1, 2]));
      expect(service.streamCount, 1);
    });

    test(
      'rejects unsupported Windows stream format before native call',
      () async {
        final service = _FakeWindowsMicrophoneService(
          status: WindowsMicrophoneAccessStatus.allowed,
        );
        final capture = SpeechAudioCapture(windowsMicrophoneService: service);

        expect(
          capture.startPcmStream(sampleRate: 44100, numChannels: 2),
          throwsStateError,
        );
        expect(service.streamCount, 0);
      },
    );

    test('stops the Windows stream through the bridge', () async {
      final service = _FakeWindowsMicrophoneService(
        status: WindowsMicrophoneAccessStatus.allowed,
      );
      final capture = SpeechAudioCapture(windowsMicrophoneService: service);

      await capture.stop();

      expect(service.stopCount, 1);
    });
  });
}
