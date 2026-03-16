import '../../domain/entities/experience_settings.dart';

// Stub for web platform — Moonshine desktop model management requires dart:io.
class MoonshineModelManager {
  String normalizeModelId(String? modelId) => kMoonshineModelTiny;

  void setPreferredModelId(String modelId) {}

  String getPreferredModelId() => kMoonshineModelTiny;

  Future<String?> findInstalledModelId() async => null;

  Future<bool> hasModel(String modelId) async => false;

  Future<void> downloadModel(
    String modelId, {
    void Function(double)? onProgress,
  }) async {}

  Future<void> deleteModel(String modelId) async {}

  Future<String> getModelDir(String modelId) async => '';
}
