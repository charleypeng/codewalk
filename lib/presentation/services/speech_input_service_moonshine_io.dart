import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../../core/logging/app_logger.dart';
import 'moonshine_model_manager.dart';
import 'speech_input_service.dart';

// Moonshine desktop backend using sherpa_onnx OfflineRecognizer + Silero VAD.
// It keeps the same speech-service contract as Sherpa but processes one VAD
// segmented utterance at a time instead of continuous streaming transducer
// decoding.
class MoonshineSpeechInputService implements SpeechInputService {
  MoonshineSpeechInputService(this._modelManager);

  final MoonshineModelManager _modelManager;
  static const _sampleRate = 16000;
  static bool _bindingsInitialized = false;

  sherpa.OfflineRecognizer? _recognizer;
  sherpa.VoiceActivityDetector? _vad;
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _audioSub;
  String? _activeModelId;
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
      _unavailableReason = 'Moonshine is available on desktop only.';
      _isAvailable = false;
      return false;
    }

    try {
      _ensureBindingsInitialized();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Moonshine bindings initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
      _unavailableReason = 'Moonshine runtime failed to initialize.';
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

    _activeModelId = null;
    _activeModelDir = null;
    _recognizer?.free();
    _recognizer = null;
    _vad?.free();
    _vad = null;
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
      _recreateVad(modelDir, pauseFor ?? const Duration(seconds: 5));
    } catch (error, stackTrace) {
      AppLogger.error(
        'Moonshine recognizer initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
      _isAvailable = false;
      _unavailableReason = 'Moonshine model files are incomplete.';
      onError();
      return;
    }

    final recognizer = _recognizer;
    final vad = _vad;
    if (recognizer == null || vad == null) {
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
    Timer? silenceTimer;
    var completed = false;

    Future<void> finishSession() async {
      if (completed) {
        return;
      }
      completed = true;
      silenceTimer?.cancel();
      await stopListening();
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

    armSilenceTimer();

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
        'Moonshine recorder stream start failed',
        error: error,
        stackTrace: stackTrace,
      );
      _isListening = false;
      await recorder.dispose();
      _recorder = null;
      onError();
      return;
    }

    _audioSub = audioStream.listen(
      (chunk) {
        if (!_isListening) {
          return;
        }
        final samples = _pcm16ToFloat32(chunk);
        vad.acceptWaveform(samples);
        if (!vad.isDetected()) {
          return;
        }
        final segment = vad.front();
        vad.pop();
        if (segment.samples.isEmpty) {
          return;
        }

        final stream = recognizer.createStream();
        try {
          stream.acceptWaveform(
            samples: segment.samples,
            sampleRate: _sampleRate,
          );
          recognizer.decode(stream);
          final text = recognizer.getResult(stream).text.trim();
          if (text.isNotEmpty) {
            onResult(text, true);
          }
        } finally {
          stream.free();
        }

        unawaited(finishSession());
      },
      onError: (_) {
        silenceTimer?.cancel();
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
    _activeModelId = modelId;
    _activeModelDir = await _modelManager.getModelDir(modelId);
    _unavailableReason = null;
    _isAvailable = true;
  }

  void _recreateRecognizer(String modelDir) {
    _recognizer?.free();
    _recognizer = sherpa.OfflineRecognizer(
      sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          moonshine: sherpa.OfflineMoonshineModelConfig(
            preprocessor: '$modelDir/preprocess.onnx',
            encoder: '$modelDir/encode.int8.onnx',
            uncachedDecoder: '$modelDir/uncached_decode.int8.onnx',
            cachedDecoder: '$modelDir/cached_decode.int8.onnx',
          ),
          tokens: '$modelDir/tokens.txt',
          numThreads: 2,
          provider: 'cpu',
          debug: false,
        ),
      ),
    );
  }

  void _recreateVad(String modelDir, Duration pauseFor) {
    _vad?.free();
    _vad = sherpa.VoiceActivityDetector(
      config: sherpa.VadModelConfig(
        sileroVad: sherpa.SileroVadModelConfig(
          model: '$modelDir/silero_vad.onnx',
          minSilenceDuration: pauseFor.inMilliseconds / 1000.0,
          minSpeechDuration: 0.2,
          maxSpeechDuration: 15,
        ),
        sampleRate: _sampleRate,
        numThreads: 1,
        provider: 'cpu',
        debug: false,
      ),
      bufferSizeInSeconds: 30,
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
