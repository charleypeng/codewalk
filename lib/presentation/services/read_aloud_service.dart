import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/logging/app_logger.dart';

enum ReadAloudState { idle, playing, paused }

class ReadAloudService extends ChangeNotifier {
  ReadAloudService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  ReadAloudState _state = ReadAloudState.idle;
  String? _activeMessageId;

  // Tracks the last spoken character length for progress reporting.
  int _lastSpokenLength = 0;

  // The total character length of the current utterance.
  int _totalUtteranceLength = 0;

  ReadAloudState get state => _state;
  String? get activeMessageId => _activeMessageId;
  bool get isSpeaking => _state == ReadAloudState.playing;

  // Progress as a 0.0–1.0 fraction when playing, null otherwise.
  double? get progress {
    if (_totalUtteranceLength <= 0) {
      return null;
    }
    return (_lastSpokenLength / _totalUtteranceLength).clamp(0.0, 1.0);
  }

  /// Whether the platform has a TTS engine available.
  Future<bool> get isAvailable async {
    try {
      final engines = await _tts.getEngines;
      return engines.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Speak the given [text] for [messageId].
  /// If already speaking, stops current speech first.
  Future<void> speak({
    required String messageId,
    required String text,
    double rate = 0.5,
    double pitch = 1.0,
    String? voice,
  }) async {
    if (text.trim().isEmpty) {
      return;
    }

    await stop();

    try {
      await _tts.setSpeechRate(rate);
      await _tts.setPitch(pitch);
      if (voice != null && voice.isNotEmpty) {
        await _tts.setVoice({'name': voice, 'locale': 'en-US'});
      }

      _activeMessageId = messageId;
      _totalUtteranceLength = text.length;
      _lastSpokenLength = 0;
      _state = ReadAloudState.playing;
      notifyListeners();

      // Set handlers before speaking so we don't miss events.
      _tts.setStartHandler(() {
        _state = ReadAloudState.playing;
        notifyListeners();
      });

      _tts.setCompletionHandler(() {
        _state = ReadAloudState.idle;
        _activeMessageId = null;
        _totalUtteranceLength = 0;
        _lastSpokenLength = 0;
        notifyListeners();
      });

      _tts.setErrorHandler((message) {
        AppLogger.warn('TTS error: $message');
        _state = ReadAloudState.idle;
        _activeMessageId = null;
        _totalUtteranceLength = 0;
        _lastSpokenLength = 0;
        notifyListeners();
      });

      _tts.setCancelHandler(() {
        _state = ReadAloudState.idle;
        _activeMessageId = null;
        _totalUtteranceLength = 0;
        _lastSpokenLength = 0;
        notifyListeners();
      });

      _tts.setPauseHandler(() {
        _state = ReadAloudState.paused;
        notifyListeners();
      });

      _tts.setContinueHandler(() {
        _state = ReadAloudState.playing;
        notifyListeners();
      });

      await _tts.speak(text);
    } catch (error, stackTrace) {
      AppLogger.warn(
        'TTS speak failed',
        error: error,
        stackTrace: stackTrace,
      );
      _state = ReadAloudState.idle;
      _activeMessageId = null;
      _totalUtteranceLength = 0;
      _lastSpokenLength = 0;
      notifyListeners();
    }
  }

  /// Pause current speech. No-op if not playing.
  Future<void> pause() async {
    if (_state != ReadAloudState.playing) {
      return;
    }
    try {
      await _tts.pause();
    } catch (error, stackTrace) {
      AppLogger.warn(
        'TTS pause failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Stop current speech and reset state.
  Future<void> stop() async {
    if (_state == ReadAloudState.idle) {
      return;
    }
    try {
      await _tts.stop();
    } catch (error, stackTrace) {
      AppLogger.warn(
        'TTS stop failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
    _state = ReadAloudState.idle;
    _activeMessageId = null;
    _totalUtteranceLength = 0;
    _lastSpokenLength = 0;
    notifyListeners();
  }

  /// Stop playback if reading the given [messageId].
  /// Used when a message is removed or becomes stale.
  Future<void> stopIfReading(String messageId) async {
    if (_activeMessageId == messageId) {
      await stop();
    }
  }

  /// Release TTS resources. Call when service is no longer needed.
  @override
  Future<void> dispose() async {
    await stop();
    super.dispose();
  }

  // --- Platform capability queries (for settings UI) ---

  /// List of available voices from the platform TTS engine.
  Future<List<Map<String, String>>> getVoices() async {
    try {
      final voices = await _tts.getVoices;
      return voices
          .map((v) => <String, String>{
                'name': v['name']?.toString() ?? '',
                'locale': v['locale']?.toString() ?? '',
              })
          .toList();
    } catch (_) {
      return <Map<String, String>>[];
    }
  }

  /// List of available languages from the platform TTS engine.
  Future<List<String>> getLanguages() async {
    try {
      return await _tts.getLanguages;
    } catch (_) {
      return <String>[];
    }
  }
}
