import 'package:flutter/widgets.dart';

class AppLocaleInfo {
  const AppLocaleInfo({
    required this.locale,
    required this.englishName,
    required this.nativeName,
    required this.textDirection,
  });

  final Locale locale;
  final String englishName;
  final String nativeName;
  final TextDirection textDirection;

  String get code => locale.languageCode;

  String get displayName => nativeName == englishName
      ? nativeName
      : '$nativeName ($englishName)';
}

class AppLocales {
  const AppLocales._();

  static const english = Locale('en');

  static const infos = <AppLocaleInfo>[
    AppLocaleInfo(
      locale: Locale('ar'),
      englishName: 'Arabic',
      nativeName: 'العربية',
      textDirection: TextDirection.rtl,
    ),
    AppLocaleInfo(
      locale: Locale('bn'),
      englishName: 'Bengali',
      nativeName: 'বাংলা',
      textDirection: TextDirection.ltr,
    ),
    AppLocaleInfo(
      locale: Locale('de'),
      englishName: 'German',
      nativeName: 'Deutsch',
      textDirection: TextDirection.ltr,
    ),
    AppLocaleInfo(
      locale: english,
      englishName: 'English',
      nativeName: 'English',
      textDirection: TextDirection.ltr,
    ),
    AppLocaleInfo(
      locale: Locale('es'),
      englishName: 'Spanish',
      nativeName: 'Español',
      textDirection: TextDirection.ltr,
    ),
    AppLocaleInfo(
      locale: Locale('fr'),
      englishName: 'French',
      nativeName: 'Français',
      textDirection: TextDirection.ltr,
    ),
    AppLocaleInfo(
      locale: Locale('hi'),
      englishName: 'Hindi',
      nativeName: 'हिन्दी',
      textDirection: TextDirection.ltr,
    ),
    AppLocaleInfo(
      locale: Locale('it'),
      englishName: 'Italian',
      nativeName: 'Italiano',
      textDirection: TextDirection.ltr,
    ),
    AppLocaleInfo(
      locale: Locale('ja'),
      englishName: 'Japanese',
      nativeName: '日本語',
      textDirection: TextDirection.ltr,
    ),
    AppLocaleInfo(
      locale: Locale('ko'),
      englishName: 'Korean',
      nativeName: '한국어',
      textDirection: TextDirection.ltr,
    ),
    AppLocaleInfo(
      locale: Locale('pt'),
      englishName: 'Portuguese',
      nativeName: 'Português',
      textDirection: TextDirection.ltr,
    ),
    AppLocaleInfo(
      locale: Locale('ru'),
      englishName: 'Russian',
      nativeName: 'Русский',
      textDirection: TextDirection.ltr,
    ),
    AppLocaleInfo(
      locale: Locale('zh'),
      englishName: 'Chinese',
      nativeName: '中文',
      textDirection: TextDirection.ltr,
    ),
    AppLocaleInfo(
      locale: Locale('ur'),
      englishName: 'Urdu',
      nativeName: 'اردو',
      textDirection: TextDirection.rtl,
    ),
  ];

  static const supported = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('de'),
    english,
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
    Locale('ur'),
  ];

  static AppLocaleInfo? infoForCode(String? code) {
    final normalized = code?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    for (final info in infos) {
      if (info.code == normalized) {
        return info;
      }
    }
    return null;
  }

  static Locale? localeForCode(String? code) => infoForCode(code)?.locale;

  static Locale resolutionCallback(
    Locale? locale,
    Iterable<Locale> supportedLocales,
  ) {
    if (locale == null) {
      return english;
    }
    for (final supported in supportedLocales) {
      if (supported.languageCode == locale.languageCode &&
          supported.countryCode == locale.countryCode &&
          supported.scriptCode == locale.scriptCode) {
        return supported;
      }
    }
    for (final supported in supportedLocales) {
      if (supported.languageCode == locale.languageCode) {
        return supported;
      }
    }
    return english;
  }
}
