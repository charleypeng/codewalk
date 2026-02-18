import 'dart:async';

import 'package:flutter/services.dart';

import 'speech_input_service.dart';

// Android STT backend using a custom platform channel with EXTRA_ENABLE_PUNCTUATION.
// The Kotlin side streams partial and final results via codewalk/speech EventChannel.
// EXTRA_ENABLE_PUNCTUATION is a proprietary Google extra — degrades silently on
// devices without Play Services (STT continues working, just without punctuation).
class AndroidSpeechInputService implements SpeechInputService {
  static const _control = MethodChannel('codewalk/speech_control');
  static const _events = EventChannel('codewalk/speech');

  StreamSubscription<dynamic>? _sub;
  bool _isListening = false;

  @override
  bool get isListening => _isListening;

  @override
  // Android always has SpeechRecognizer available via Play Services.
  bool get isAvailable => true;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function(String status) onStatus,
    required void Function() onError,
    Duration? pauseFor,
    String? localeId,
  }) async {
    await _sub?.cancel();
    _sub = _events.receiveBroadcastStream().listen(
      (event) {
        final map = Map<String, dynamic>.from(event as Map);
        final text = map['text'] as String? ?? '';
        final isFinal = map['isFinal'] as bool? ?? false;
        onResult(text, isFinal);
        if (isFinal) {
          _isListening = false;
          onStatus('done');
        }
      },
      onError: (_) {
        _isListening = false;
        onError();
      },
    );
    await _control.invokeMethod<void>('start', <String, dynamic>{
      if (localeId != null) 'localeId': localeId,
    });
    _isListening = true;
    onStatus('listening');
  }

  @override
  Future<void> stopListening() async {
    try {
      await _control.invokeMethod<void>('stop');
    } catch (_) {
      // Ignore platform stop errors.
    } finally {
      await _sub?.cancel();
      _sub = null;
      _isListening = false;
    }
  }
}
