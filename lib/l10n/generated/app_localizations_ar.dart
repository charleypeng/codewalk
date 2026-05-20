// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get settingsLanguageTitle => 'اللغة';

  @override
  String get settingsLanguageDescription =>
      'اختر اللغة التي يستخدمها CodeWalk. يتبع خيار النظام الافتراضي لغة جهازك.';

  @override
  String get settingsLanguageFieldLabel => 'لغة التطبيق';

  @override
  String get settingsLanguageFieldHelper =>
      'يُطبّق فورًا ويستمر بعد إعادة التشغيل.';

  @override
  String get settingsLanguageSearchHint => 'ابحث عن اللغات';

  @override
  String get settingsLanguageEmptyText => 'لم يتم العثور على لغات';

  @override
  String get settingsLanguageSystemDefault => 'النظام الافتراضي';
}
