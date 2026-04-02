import '../../domain/entities/experience_settings.dart';

class SenseVoiceModelManager {
  String normalizeModelId(String? modelId) => kSenseVoiceModelDefault;

  void setPreferredModelId(String modelId) {}

  String getPreferredModelId() => kSenseVoiceModelDefault;

  Future<String?> findInstalledModelId() async => null;

  Future<bool> hasModel(String modelId) async => false;

  Future<void> downloadModel(
    String modelId, {
    void Function(double)? onProgress,
  }) async {}

  Future<void> deleteModel(String modelId) async {}

  Future<String> getModelDir(String modelId) async => '';
}
