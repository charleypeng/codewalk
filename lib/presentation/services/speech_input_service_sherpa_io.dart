import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'sherpa_model_manager.dart';
import 'speech_input_service.dart';

// Linux STT backend using sherpa_onnx OnlineRecognizer with Kroko streaming
// transducer models and the 'record' package for microphone capture.
// Audio pipeline: AudioRecorder (PCM 16-bit 16kHz mono) → int16→float32
// conversion → sherpa_onnx OnlineStream → partial/final text results.
class SherpaSpeechInputService implements SpeechInputService {
  SherpaSpeechInputService(this._modelManager);

  final SherpaModelManager _modelManager;

  sherpa.OnlineRecognizer? _recognizer;
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _audioSub;
  bool _isListening = false;
  bool _isAvailable = false;

  @override
  bool get isListening => _isListening;

  @override
  bool get isAvailable => _isAvailable;

  @override
  Future<bool> initialize() async {
    final lang = _modelManager.detectSystemLanguage();
    if (!await _modelManager.hasModel(lang)) {
      _isAvailable = false;
      return false;
    }

    final dir = await _modelManager.getModelDir(lang);

    // Free any previous recognizer before reinitializing.
    _recognizer?.free();
    _recognizer = sherpa.OnlineRecognizer(
      sherpa.OnlineRecognizerConfig(
        model: sherpa.OnlineModelConfig(
          transducer: sherpa.OnlineTransducerModelConfig(
            encoder: '$dir/encoder.int8.onnx',
            decoder: '$dir/decoder.int8.onnx',
            joiner: '$dir/joiner.int8.onnx',
          ),
          tokens: '$dir/tokens.txt',
          numThreads: 2,
          provider: 'cpu',
          debug: false,
        ),
        decodingMethod: 'greedy_search',
        enableEndpoint: true,
        // Emit endpoint after 2.4s of trailing silence (applies pauseFor intent).
        rule1MinTrailingSilence: 2.4,
        rule2MinTrailingSilence: 1.2,
        rule3MinUtteranceLength: 20.0,
        maxActivePaths: 4,
      ),
    );

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
    final recognizer = _recognizer;
    if (recognizer == null || !_isAvailable) {
      // Signal the widget to show the model download dialog.
      onStatus('model_required');
      return;
    }

    final recorder = AudioRecorder();
    _recorder = recorder;

    final hasPermission = await recorder.hasPermission();
    if (!hasPermission) {
      await recorder.dispose();
      onError();
      return;
    }

    final stream = recognizer.createStream();
    _isListening = true;
    onStatus('listening');

    final audioStream = await recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    _audioSub = audioStream.listen(
      (chunk) {
        if (!_isListening) return;
        // Convert Int16 PCM bytes to normalized Float32 samples for sherpa.
        final samples = _pcm16ToFloat32(chunk);
        stream.acceptWaveform(samples: samples, sampleRate: 16000);

        // Process all buffered frames.
        while (recognizer.isReady(stream)) {
          recognizer.decode(stream);
        }

        // Emit partial transcript for live feedback.
        final partial = recognizer.getResult(stream).text.trim();
        if (partial.isNotEmpty) {
          onResult(partial, false);
        }

        // Detect utterance endpoint and emit final result.
        if (recognizer.isEndpoint(stream)) {
          final finalText = recognizer.getResult(stream).text.trim();
          if (finalText.isNotEmpty) {
            onResult(finalText, true);
          }
          // Reset stream so the next utterance starts clean.
          recognizer.reset(stream);
        }
      },
      onError: (_) {
        stream.free();
        _isListening = false;
        onError();
      },
      onDone: () {
        // Flush any remaining frames after the recorder closes.
        while (recognizer.isReady(stream)) {
          recognizer.decode(stream);
        }
        final finalText = recognizer.getResult(stream).text.trim();
        if (finalText.isNotEmpty) {
          onResult(finalText, true);
        }
        stream.free();
        _isListening = false;
        onStatus('done');
      },
    );
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

  // Converts raw little-endian Int16 PCM bytes to normalized Float32 samples
  // in the range [-1.0, 1.0] as required by the sherpa_onnx recognizer.
  static Float32List _pcm16ToFloat32(Uint8List bytes) {
    final data = ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);
    final samples = Float32List(bytes.length ~/ 2);
    for (var i = 0; i < samples.length; i++) {
      samples[i] = data.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return samples;
  }
}
