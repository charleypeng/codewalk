import 'package:codewalk/presentation/services/notification_sound_source_service_types.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNotificationSoundSourceService
    implements NotificationSoundSourceService {
  @override
  bool get supportsSystemSoundPicker => true;

  @override
  Future<List<SystemSoundChoice>> listSystemSounds() async {
    return const <SystemSoundChoice>[
      SystemSoundChoice(
        id: 'default',
        label: 'Default',
        source: 'sys://default',
      ),
    ];
  }

  @override
  Future<RegisteredSoundFile?> pickAndRegisterCustomFile() async {
    return const RegisteredSoundFile(
      source: 'file:///tmp/custom.wav',
      label: 'Custom',
    );
  }
}

void main() {
  test('type containers expose stable fields', () async {
    const choice = SystemSoundChoice(
      id: 'sys-1',
      label: 'System 1',
      source: 'sys://1',
    );
    const file = RegisteredSoundFile(
      source: 'file:///tmp/sound.wav',
      label: 'Sound',
    );
    final service = _FakeNotificationSoundSourceService();

    expect(choice.id, 'sys-1');
    expect(choice.label, 'System 1');
    expect(choice.source, 'sys://1');
    expect(file.source, 'file:///tmp/sound.wav');
    expect(file.label, 'Sound');
    expect(service.supportsSystemSoundPicker, isTrue);
    expect((await service.listSystemSounds()).single.id, 'default');
    expect((await service.pickAndRegisterCustomFile())?.label, 'Custom');
  });
}
