import 'dart:async';

import 'package:flutter/services.dart';

import 'speech_input_service.dart';
import 'speech_input_service_stt.dart';

// Android STT backend using a custom platform channel with EXTRA_ENABLE_FORMATTING.
// The Kotlin side streams partial and final results via codewalk/speech EventChannel.
// When SpeechRecognizer is not backed by Google Play Services (e.g. AOSP devices or
// custom ROMs without Play Services), falls back to SttSpeechInputService which uses
// the speech_to_text package — it supports Android and correctly honours pauseFor.
class AndroidSpeechInputService implements SpeechInputService {
  static const _control = MethodChannel('codewalk/speech_control');
  static const _events = EventChannel('codewalk/speech');

  // Non-null after initialize() when Play Services are unavailable.
  SpeechInputService? _fallback;

  StreamSubscription<dynamic>? _sub;
  bool _isListening = false;
  bool _isAvailable = false;

  @override
  bool get isListening => _fallback?.isListening ?? _isListening;

  @override
  bool get isAvailable => _fallback?.isAvailable ?? _isAvailable;

  @override
  Future<bool> initialize() async {
    // Ask Kotlin whether SpeechRecognizer is backed by Play Services.
    final nativeAvailable =
        await _control.invokeMethod<bool>('isAvailable') ?? false;

    if (!nativeAvailable) {
      // No Play Services — fall back to speech_to_text which supports Android
      // and correctly honours the pauseFor silence timeout.
      final fallback = SttSpeechInputService();
      final ok = await fallback.initialize();
      _fallback = fallback;
      _isAvailable = ok;
      return ok;
    }

    _fallback = null;
    _isAvailable = true;
    return true;
  }

  @override
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function(String status) onStatus,
    required void Function() onError,
    Duration? pauseFor,
    String? localeId,
  }) async {
    // Delegate to fallback when Play Services are unavailable.
    if (_fallback != null) {
      return _fallback!.startListening(
        onResult: onResult,
        onStatus: onStatus,
        onError: onError,
        pauseFor: pauseFor,
        localeId: localeId,
      );
    }

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
      if (pauseFor != null) 'pauseForMs': pauseFor.inMilliseconds,
    });
    _isListening = true;
    onStatus('listening');
  }

  @override
  Future<void> stopListening() async {
    if (_fallback != null) {
      return _fallback!.stopListening();
    }

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
