import 'package:codewalk/domain/entities/experience_settings.dart';
import 'package:codewalk/presentation/services/parakeet_model_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ParakeetModelManager selection', () {
    late ParakeetModelManager manager;

    setUp(() {
      manager = ParakeetModelManager();
    });

    test('normalizes unknown ids to the default model', () {
      expect(manager.normalizeModelId('unknown'), kParakeetModelDefault);
      expect(manager.normalizeModelId(null), kParakeetModelDefault);
    });

    test('stores preferred model using normalized id', () {
      manager.setPreferredModelId('PARAKEET-V3');

      expect(manager.getPreferredModelId(), kParakeetModelDefault);
    });
  });
}
