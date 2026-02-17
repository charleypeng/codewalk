import 'notification_sound_source_service_types.dart';

NotificationSoundSourceService createNotificationSoundSourceService() {
  return _NotificationSoundSourceServiceStub();
}

class _NotificationSoundSourceServiceStub
    implements NotificationSoundSourceService {
  @override
  bool get supportsSystemSoundPicker => false;

  @override
  Future<List<SystemSoundChoice>> listSystemSounds() async {
    return const <SystemSoundChoice>[];
  }

  @override
  Future<RegisteredSoundFile?> pickAndRegisterCustomFile() async {
    return null;
  }
}
