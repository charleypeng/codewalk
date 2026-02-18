import 'package:codewalk/presentation/services/sherpa_model_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SherpaModelManager language selection', () {
    late SherpaModelManager manager;

    setUp(() {
      manager = SherpaModelManager();
    });

    test('normalizes supported locale formats to model language code', () {
      expect(manager.normalizeLanguageCode('pt-BR'), 'pt');
      expect(manager.normalizeLanguageCode('fr_FR.UTF-8'), 'fr');
      expect(manager.normalizeLanguageCode('en'), 'en');
    });

    test('stores preferred language using normalized code', () {
      manager.setPreferredLanguage('it_IT');

      expect(manager.getPreferredLanguage(), 'it');
    });

    test('falls back to english for unsupported language codes', () {
      manager.setPreferredLanguage('ja-JP');

      expect(manager.getPreferredLanguage(), 'en');
    });
  });
}
