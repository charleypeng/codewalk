// Stub for web platform — model management is not available without dart:io.
// SherpaSpeechInputService is never registered on web so these methods are
// never called in practice.
class SherpaModelManager {
  String normalizeLanguageCode(String? languageOrLocale) => 'en';

  void setPreferredLanguage(String languageOrLocale) {}

  String getPreferredLanguage() => 'en';

  Future<String?> findInstalledLanguage() async => null;

  Future<bool> hasModel(String lang) async => false;

  Future<void> downloadModel(
    String lang, {
    void Function(double)? onProgress,
  }) async {}

  Future<void> deleteModel(String lang) async {}

  Future<String> getModelDir(String lang) async => '';

  // Returns the best matching language code for the current system locale.
  String detectSystemLanguage() => 'en';
}
