import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/experience_settings.dart';

class _ParakeetModelSpec {
  const _ParakeetModelSpec({
    required this.id,
    required this.label,
    required this.sizeMb,
    required this.packageName,
    required this.files,
  });

  final String id;
  final String label;
  final int sizeMb;
  final String packageName;
  final List<String> files;
}

// Desktop Parakeet models are downloaded on demand from official sherpa-onnx
// release archives, mirroring the Moonshine manager flow to keep the runtime
// isolated from the existing Kroko-only Sherpa manager.
class ParakeetModelManager {
  static const _releaseBase =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models';
  static const _models = <String, _ParakeetModelSpec>{
    kParakeetModelDefault: _ParakeetModelSpec(
      id: kParakeetModelDefault,
      label: 'Parakeet V3 (25 European languages)',
      sizeMb: 640,
      packageName: 'sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8',
      files: <String>[
        'encoder.int8.onnx',
        'decoder.int8.onnx',
        'joiner.int8.onnx',
        'tokens.txt',
      ],
    ),
  };

  String? _cachedBaseDir;
  String? _preferredModelId;
  final Dio _dio = Dio();

  String normalizeModelId(String? modelId) {
    final raw = modelId?.trim().toLowerCase();
    if (raw != null && _models.containsKey(raw)) {
      return raw;
    }
    return kParakeetModelDefault;
  }

  void setPreferredModelId(String modelId) {
    _preferredModelId = normalizeModelId(modelId);
  }

  String getPreferredModelId() {
    return normalizeModelId(_preferredModelId);
  }

  Future<String?> findInstalledModelId() async {
    for (final id in _models.keys) {
      if (await hasModel(id)) {
        return id;
      }
    }
    return null;
  }

  Future<bool> hasModel(String modelId) async {
    final spec = _specFor(modelId);
    final dir = Directory(await getModelDir(spec.id));
    if (!dir.existsSync()) {
      return false;
    }
    for (final file in spec.files) {
      if (!File('${dir.path}/$file').existsSync()) {
        return false;
      }
    }
    return true;
  }

  Future<void> downloadModel(
    String modelId, {
    void Function(double)? onProgress,
  }) async {
    final spec = _specFor(modelId);
    final dir = Directory(await getModelDir(spec.id));
    await dir.create(recursive: true);

    final archiveUrl = '$_releaseBase/${spec.packageName}.tar.bz2';
    final archiveResponse = await _dio.get<List<int>>(
      archiveUrl,
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: onProgress == null
          ? null
          : (received, total) {
              if (total > 0) {
                onProgress(received / total);
              }
            },
    );

    final archiveBytes = Uint8List.fromList(archiveResponse.data ?? <int>[]);
    final tarBytes = BZip2Decoder().decodeBytes(archiveBytes);
    final archive = TarDecoder().decodeBytes(tarBytes);
    for (final entry in archive) {
      if (!entry.isFile) {
        continue;
      }
      final parts = entry.name.split('/');
      final fileName = parts.isEmpty ? entry.name : parts.last;
      if (!spec.files.contains(fileName)) {
        continue;
      }
      final output = File('${dir.path}/$fileName');
      await output.parent.create(recursive: true);
      await output.writeAsBytes(_fileBytes(entry));
    }

    onProgress?.call(1.0);
  }

  Future<void> deleteModel(String modelId) async {
    final dir = Directory(await getModelDir(modelId));
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  Future<String> getModelDir(String modelId) async {
    final base = await _getAppSupportDir();
    final normalized = normalizeModelId(modelId);
    return '$base/parakeet_models/$normalized';
  }

  Future<String> _getAppSupportDir() async {
    if (_cachedBaseDir != null) {
      return _cachedBaseDir!;
    }
    final dir = await getApplicationSupportDirectory();
    _cachedBaseDir = dir.path;
    return _cachedBaseDir!;
  }

  _ParakeetModelSpec _specFor(String modelId) {
    final normalized = normalizeModelId(modelId);
    return _models[normalized]!;
  }

  List<int> _fileBytes(ArchiveFile entry) {
    // archive 4.x: entry.content is now FileContent; use readBytes() instead
    final bytes = entry.readBytes();
    return bytes ?? <int>[];
  }
}
