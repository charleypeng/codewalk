import 'notification_sound_source_service_stub.dart'
    if (dart.library.io) 'notification_sound_source_service_io.dart'
    as impl;
import 'notification_sound_source_service_types.dart';

NotificationSoundSourceService createNotificationSoundSourceService() {
  return impl.createNotificationSoundSourceService();
}
