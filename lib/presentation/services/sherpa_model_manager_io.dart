import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

// Native implementation of sherpa-onnx model management for Linux desktop.
// Handles on-demand download of Kroko streaming transducer models from
// HuggingFace, local storage under getApplicationSupportDirectory(), locale
// detection, and model lifecycle (install / check / delete).
class SherpaModelManager {
  static const _availableLangs = ['de', 'en', 'es', 'fr', 'it', 'pt', 'tr'];

  // The 4 files required per language model (INT8 quantized Kroko 64-layer).
  static const _modelFiles = [
    'encoder.int8.onnx',
    'decoder.int8.onnx',
    'joiner.int8.onnx',
    'tokens.txt',
  ];

  static const _huggingFaceBase = 'https://huggingface.co';
  static const _repo = 'hudaiapa88/sherpa-stt-onnx';

  String? _cachedBaseDir;
  final _dio = Dio();

  // Returns true when all 4 model files for [lang] exist on disk.
  Future<bool> hasModel(String lang) async {
    final dir = Directory(await getModelDir(lang));
    if (!dir.existsSync()) return false;
    for (final file in _modelFiles) {
      if (!File('${dir.path}/$file').existsSync()) return false;
    }
    return true;
  }

  // Downloads all 4 model files for [lang] from HuggingFace.
  // [onProgress] receives a value in [0.0, 1.0] aggregated across all files.
  Future<void> downloadModel(
    String lang, {
    void Function(double)? onProgress,
  }) async {
    final dir = Directory(await getModelDir(lang));
    await dir.create(recursive: true);

    final path = '$lang/kroko_64l';
    final base = '$_huggingFaceBase/$_repo/resolve/main/$path';

    for (var i = 0; i < _modelFiles.length; i++) {
      final file = _modelFiles[i];
      final localPath = '${dir.path}/$file';
      await _dio.download(
        '$base/$file',
        localPath,
        options: Options(followRedirects: true, receiveTimeout: const Duration(minutes: 10)),
        onReceiveProgress: onProgress == null
            ? null
            : (received, total) {
                if (total > 0) {
                  // Distribute progress evenly across the 4 files.
                  final fileProgress = received / total;
                  onProgress((i + fileProgress) / _modelFiles.length);
                }
              },
      );
    }
    onProgress?.call(1.0);
  }

  // Removes all model files for [lang] from disk to free space.
  Future<void> deleteModel(String lang) async {
    final dir = Directory(await getModelDir(lang));
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  // Returns the local directory path for [lang] model files.
  Future<String> getModelDir(String lang) async {
    final base = await _getAppSupportDir();
    return '$base/sherpa_models/$lang';
  }

  // Parses the system locale (e.g. 'pt_BR.UTF-8') and returns a matching
  // language code from the available models, falling back to 'en'.
  String detectSystemLanguage() {
    final locale = Platform.localeName;
    // Extract the 2-letter language code (up to first '_', '.', or end).
    final raw = locale.split(RegExp(r'[_.\-]')).first.toLowerCase();
    if (_availableLangs.contains(raw)) return raw;
    return 'en';
  }

  // Returns (and caches) the application support directory path.
  Future<String> _getAppSupportDir() async {
    if (_cachedBaseDir != null) return _cachedBaseDir!;
    final dir = await getApplicationSupportDirectory();
    _cachedBaseDir = dir.path;
    return _cachedBaseDir!;
  }
}
