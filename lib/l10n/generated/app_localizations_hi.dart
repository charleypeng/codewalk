// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get settingsLanguageTitle => 'भाषा';

  @override
  String get settingsLanguageDescription =>
      'CodeWalk द्वारा उपयोग की जाने वाली भाषा चुनें। सिस्टम डिफ़ॉल्ट आपके डिवाइस की भाषा का अनुसरण करता है।';

  @override
  String get settingsLanguageFieldLabel => 'ऐप भाषा';

  @override
  String get settingsLanguageFieldHelper =>
      'तुरंत लागू होता है और रीस्टार्ट के बाद भी बना रहता है।';

  @override
  String get settingsLanguageSearchHint => 'भाषाएँ खोजें';

  @override
  String get settingsLanguageEmptyText => 'कोई भाषा नहीं मिली';

  @override
  String get settingsLanguageSystemDefault => 'सिस्टम डिफ़ॉल्ट';
}
