import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Typed result of a Windows microphone preflight probe.
//
// Windows does not show a runtime microphone permission prompt for unpackaged
// Win32 apps. The realistic signal is the WASAPI HRESULT when initializing
// the capture client:
//
//   - AUDCLNT_E_ACCESSDENIED (0x80070005) -> [denied]   (privacy block)
//   - AUDCLNT_E_DEVICE_INVALIDATED      -> [noInputDevice]
//   - AUDCLNT_E_DEVICE_IN_USE            -> [deviceBusy]
//   - AUDCLNT_E_NOT_INITIALIZED / others -> [unknown]
//   - S_OK                                -> [allowed]
enum WindowsMicrophoneAccessStatus {
  allowed,
  denied,
  noInputDevice,
  deviceBusy,
  unknown,
  notSupported,
}

extension WindowsMicrophoneAccessStatusLabel
    on WindowsMicrophoneAccessStatus {
  String get label {
    switch (this) {
      case WindowsMicrophoneAccessStatus.allowed:
        return 'allowed';
      case WindowsMicrophoneAccessStatus.denied:
        return 'denied';
      case WindowsMicrophoneAccessStatus.noInputDevice:
        return 'noInputDevice';
      case WindowsMicrophoneAccessStatus.deviceBusy:
        return 'deviceBusy';
      case WindowsMicrophoneAccessStatus.unknown:
        return 'unknown';
      case WindowsMicrophoneAccessStatus.notSupported:
        return 'notSupported';
    }
  }
}

// Dart-side bridge for the Windows native microphone channel.
//
// The native side (windows/runner/windows_microphone_plugin.cpp) implements:
//   - `probe()`     -> WindowsMicrophoneAccessStatus
//   - `startStream` -> EventChannel("codewalk/windows_microphone_stream")
//   - `stopStream`  -> MethodChannel call
class WindowsMicrophoneService {
  const WindowsMicrophoneService({
    MethodChannel? probeChannel,
    EventChannel? streamChannel,
  })  : _probeChannel = probeChannel,
        _streamChannel = streamChannel;

  static const String _probeChannelName = 'codewalk/windows_microphone';
  static const String _streamChannelName =
      'codewalk/windows_microphone_stream';

  final MethodChannel? _probeChannel;
  final EventChannel? _streamChannel;

  bool get _isWindowsTarget {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.windows;
  }

  MethodChannel get _channel =>
      _probeChannel ?? const MethodChannel(_probeChannelName);

  EventChannel get _stream =>
      _streamChannel ?? const EventChannel(_streamChannelName);

  // Probes the OS for microphone access. Returns a typed status that the UI
  // can translate into an actionable message + settings link. Never throws:
  // any platform error is mapped to [WindowsMicrophoneAccessStatus.unknown]
  // or [WindowsMicrophoneAccessStatus.notSupported] on non-Windows.
  Future<WindowsMicrophoneAccessStatus> probe() async {
    if (!_isWindowsTarget) {
      return WindowsMicrophoneAccessStatus.notSupported;
    }
    try {
      final result = await _channel.invokeMethod<String>('probe');
      return _parseStatus(result);
    } on PlatformException {
      return WindowsMicrophoneAccessStatus.unknown;
    } on MissingPluginException {
      return WindowsMicrophoneAccessStatus.notSupported;
    }
  }

  // Returns a stream of PCM16 mono 16 kHz chunks when the native backend is
  // active. On non-Windows the stream is empty. Any platform error
  // (including [MissingPluginException] when the native side is not built)
  // is mapped to a synthetic error stream so the engine can fall back to
  // Native instead of crashing.
  Stream<Uint8List> pcmStream() {
    if (!_isWindowsTarget) {
      return const Stream<Uint8List>.empty();
    }
    return _stream
        .receiveBroadcastStream()
        .map<Uint8List>((event) {
          if (event is Uint8List) {
            return event;
          }
          if (event is List<int>) {
            return Uint8List.fromList(event);
          }
          return Uint8List(0);
        })
        .handleError((error) {
          if (error is MissingPluginException) {
            throw const MicrophoneBackendUnavailableException();
          }
          if (error is PlatformException) {
            throw MicrophoneBackendUnavailableException(
              code: error.code,
              message: error.message,
            );
          }
          throw error;
        });
  }

  Future<void> stopStream() async {
    if (!_isWindowsTarget) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException {
      // best-effort stop
    } on MissingPluginException {
      // plugin not registered in this build
    }
  }

  static WindowsMicrophoneAccessStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'allowed':
        return WindowsMicrophoneAccessStatus.allowed;
      case 'denied':
        return WindowsMicrophoneAccessStatus.denied;
      case 'noInputDevice':
        return WindowsMicrophoneAccessStatus.noInputDevice;
      case 'deviceBusy':
        return WindowsMicrophoneAccessStatus.deviceBusy;
      case 'notSupported':
        return WindowsMicrophoneAccessStatus.notSupported;
      case 'unknown':
      case null:
      default:
        return WindowsMicrophoneAccessStatus.unknown;
    }
  }
}

// Sentinel exception raised when the Windows native microphone backend is
// missing or fails to initialize. Engines should map this to the Native
// engine fallback instead of crashing.
class MicrophoneBackendUnavailableException implements Exception {
  const MicrophoneBackendUnavailableException({this.code, this.message});

  final String? code;
  final String? message;

  @override
  String toString() => 'MicrophoneBackendUnavailableException('
      'code: $code, message: $message)';
}
