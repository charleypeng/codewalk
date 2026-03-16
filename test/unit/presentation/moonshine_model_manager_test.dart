import 'package:codewalk/domain/entities/experience_settings.dart';
import 'package:codewalk/presentation/services/moonshine_model_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoonshineModelManager selection', () {
    late MoonshineModelManager manager;

    setUp(() {
      manager = MoonshineModelManager();
    });

    test('normalizes unknown model ids to tiny', () {
      expect(manager.normalizeModelId('base'), kMoonshineModelBase);
      expect(manager.normalizeModelId('unknown'), kMoonshineModelTiny);
      expect(manager.normalizeModelId(null), kMoonshineModelTiny);
    });

    test('stores preferred model id using normalized value', () {
      manager.setPreferredModelId('base');

      expect(manager.getPreferredModelId(), kMoonshineModelBase);
    });
  });
}
