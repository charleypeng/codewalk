import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../../core/logging/app_logger.dart';
import 'parakeet_model_manager.dart';
import 'speech_input_service.dart';

@visibleForTesting
class ParakeetAudioBuffer {
  final List<double> _samples = <double>[];

  void add(Float32List chunk) {
    _samples.addAll(chunk);
  }

  Float32List takeAll() {
    final data = Float32List.fromList(_samples);
    _samples.clear();
    return data;
  }

  bool get isEmpty => _samples.isEmpty;
}

@visibleForTesting
bool parakeetChunkHasSpeech(Float32List samples, {double threshold = 0.015}) {
  if (samples.isEmpty) {
    return false;
  }
  var sum = 0.0;
  for (final sample in samples) {
    sum += sample.abs();
  }
  return (sum / samples.length) >= threshold;
}

// Parakeet desktop backend uses sherpa_onnx OfflineRecognizer with
// modelType=nemo_transducer. We keep audio collection in Dart and decode after
// VAD-like silence detection to match the officially supported offline flow.
class ParakeetSpeechInputService implements SpeechInputService {
  ParakeetSpeechInputService(this._modelManager);

  final ParakeetModelManager _modelManager;
  static const _sampleRate = 16000;
  static bool _bindingsInitialized = false;

  sherpa.OfflineRecognizer? _recognizer;
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _audioSub;
  String? _activeModelDir;
  bool _isListening = false;
  bool _isAvailable = false;
  String? _unavailableReason;

  @override
  bool get isListening => _isListening;

  @override
  bool get isAvailable => _isAvailable;

  @override
  String? get unavailableReason => _unavailableReason;

  bool get _isDesktopSupported {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  @override
  Future<bool> initialize() async {
    if (!_isDesktopSupported) {
      _unavailableReason = 'Parakeet is available on desktop only.';
      _isAvailable = false;
      return false;
    }

    try {
      _ensureBindingsInitialized();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Parakeet bindings initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
      _unavailableReason = 'Parakeet runtime failed to initialize.';
      _isAvailable = false;
      return false;
    }

    final preferred = _modelManager.getPreferredModelId();
    if (await _modelManager.hasModel(preferred)) {
      await _setActiveModel(preferred);
      return true;
    }

    final installed = await _modelManager.findInstalledModelId();
    if (installed != null) {
      await _setActiveModel(installed);
      return true;
    }

    _activeModelDir = null;
    _recognizer?.free();
    _recognizer = null;
    _unavailableReason = null;
    _isAvailable = false;
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
    final modelDir = _activeModelDir;
    if (modelDir == null || !_isAvailable) {
      onStatus('model_required');
      return;
    }

    try {
      _recreateRecognizer(modelDir);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Parakeet recognizer initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
      _isAvailable = false;
      _unavailableReason = 'Parakeet model files are incomplete.';
      onError();
      return;
    }

    final recognizer = _recognizer;
    if (recognizer == null) {
      onError();
      return;
    }

    final recorder = AudioRecorder();
    _recorder = recorder;
    final hasPermission = await recorder.hasPermission();
    if (!hasPermission) {
      await recorder.dispose();
      _recorder = null;
      _unavailableReason = 'Microphone permission is disabled.';
      onError();
      return;
    }

    _isListening = true;
    onStatus('listening');

    final timeout = pauseFor ?? const Duration(seconds: 5);
    final maxUtteranceDuration = const Duration(seconds: 15);
    final buffer = ParakeetAudioBuffer();
    Timer? silenceTimer;
    Timer? maxDurationTimer;
    var completed = false;

    Future<void> finishSession() async {
      if (completed) {
        return;
      }
      completed = true;
      silenceTimer?.cancel();
      maxDurationTimer?.cancel();
      final utterance = buffer.takeAll();
      await stopListening();
      if (utterance.isNotEmpty) {
        final stream = recognizer.createStream();
        try {
          stream.acceptWaveform(samples: utterance, sampleRate: _sampleRate);
          recognizer.decode(stream);
          final text = recognizer.getResult(stream).text.trim();
          if (text.isNotEmpty) {
            onResult(text, true);
          }
        } catch (error, stackTrace) {
          AppLogger.error(
            'Parakeet offline decode failed',
            error: error,
            stackTrace: stackTrace,
          );
          onError();
          return;
        } finally {
          stream.free();
        }
      }
      onStatus('done');
    }

    void armSilenceTimer() {
      silenceTimer?.cancel();
      silenceTimer = Timer(timeout, () {
        if (!_isListening) {
          return;
        }
        unawaited(finishSession());
      });
    }

    Stream<Uint8List> audioStream;
    try {
      audioStream = await recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Parakeet recorder stream start failed',
        error: error,
        stackTrace: stackTrace,
      );
      _isListening = false;
      await recorder.dispose();
      _recorder = null;
      onError();
      return;
    }

    maxDurationTimer = Timer(maxUtteranceDuration, () {
      if (!_isListening) {
        return;
      }
      unawaited(finishSession());
    });
    armSilenceTimer();

    _audioSub = audioStream.listen(
      (chunk) {
        if (!_isListening) {
          return;
        }
        final samples = _pcm16ToFloat32(chunk);
        buffer.add(samples);
        if (parakeetChunkHasSpeech(samples)) {
          armSilenceTimer();
        }
      },
      onError: (_) {
        silenceTimer?.cancel();
        maxDurationTimer?.cancel();
        if (completed) {
          return;
        }
        completed = true;
        _isListening = false;
        unawaited(stopListening());
        onError();
      },
      onDone: () {
        if (!completed) {
          unawaited(finishSession());
        }
      },
    );
  }

  Future<void> _setActiveModel(String modelId) async {
    _modelManager.setPreferredModelId(modelId);
    _activeModelDir = await _modelManager.getModelDir(modelId);
    _unavailableReason = null;
    _isAvailable = true;
  }

  void _recreateRecognizer(String modelDir) {
    _recognizer?.free();
    _recognizer = sherpa.OfflineRecognizer(
      sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          transducer: sherpa.OfflineTransducerModelConfig(
            encoder: '$modelDir/encoder.int8.onnx',
            decoder: '$modelDir/decoder.int8.onnx',
            joiner: '$modelDir/joiner.int8.onnx',
          ),
          tokens: '$modelDir/tokens.txt',
          modelType: 'nemo_transducer',
          numThreads: 2,
          provider: 'cpu',
          debug: false,
        ),
        decodingMethod: 'greedy_search',
      ),
    );
  }

  void _ensureBindingsInitialized() {
    if (_bindingsInitialized) {
      return;
    }
    sherpa.initBindings();
    _bindingsInitialized = true;
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
    try {
      await _recorder?.stop();
    } catch (_) {
      // Ignore stop errors.
    }
    await _audioSub?.cancel();
    _audioSub = null;
    await _recorder?.dispose();
    _recorder = null;
  }

  static Float32List _pcm16ToFloat32(Uint8List bytes) {
    final data = ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);
    final samples = Float32List(bytes.length ~/ 2);
    for (var i = 0; i < samples.length; i++) {
      samples[i] = data.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return samples;
  }
}
