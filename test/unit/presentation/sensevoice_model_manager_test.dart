import 'package:codewalk/domain/entities/experience_settings.dart';
import 'package:codewalk/presentation/services/sensevoice_model_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SenseVoiceModelManager selection', () {
    late SenseVoiceModelManager manager;

    setUp(() {
      manager = SenseVoiceModelManager();
    });

    test('normalizes unknown ids to the default model', () {
      expect(manager.normalizeModelId('unknown'), kSenseVoiceModelDefault);
      expect(manager.normalizeModelId(null), kSenseVoiceModelDefault);
    });

    test('stores preferred model using normalized id', () {
      manager.setPreferredModelId('SENSEVOICE-2024-07-17');

      expect(manager.getPreferredModelId(), kSenseVoiceModelDefault);
    });
  });
}
