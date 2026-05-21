import 'package:codewalk/core/i18n/app_locales.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supports all target locales', () {
    expect(
      AppLocales.supported.map((locale) => locale.languageCode),
      containsAll(<String>[
        'ar',
        'bn',
        'de',
        'en',
        'es',
        'fr',
        'hi',
        'it',
        'ja',
        'ko',
        'pt',
        'ru',
        'zh',
        'ur',
      ]),
    );
  });

  test('marks Arabic and Urdu as RTL', () {
    expect(AppLocales.infoForCode('ar')?.textDirection, TextDirection.rtl);
    expect(AppLocales.infoForCode('ur')?.textDirection, TextDirection.rtl);
  });

  test('falls back to English for unsupported locales', () {
    final resolved = AppLocales.resolutionCallback(
      const Locale('th'),
      AppLocales.supported,
    );

    expect(resolved, AppLocales.english);
  });

  test(
    'resolves Portuguese region variants to Brazilian Portuguese fallback',
    () {
      final resolved = AppLocales.resolutionCallback(
        const Locale('pt', 'BR'),
        AppLocales.supported,
      );

      expect(resolved, const Locale('pt'));
      expect(AppLocales.infoForCode('pt_BR')?.locale, const Locale('pt'));
      expect(
        AppLocales.infoForCode('pt-BR')?.displayName,
        'Português (Brasil) (Brazilian Portuguese)',
      );
    },
  );
}
