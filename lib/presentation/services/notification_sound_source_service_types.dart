class SystemSoundChoice {
  const SystemSoundChoice({
    required this.id,
    required this.label,
    required this.source,
  });

  final String id;
  final String label;
  final String source;
}

class RegisteredSoundFile {
  const RegisteredSoundFile({required this.source, required this.label});

  final String source;
  final String label;
}

abstract class NotificationSoundSourceService {
  bool get supportsSystemSoundPicker;

  Future<List<SystemSoundChoice>> listSystemSounds();

  Future<RegisteredSoundFile?> pickAndRegisterCustomFile();
}
