// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get settingsLanguageTitle => 'زبان';

  @override
  String get settingsLanguageDescription =>
      'CodeWalk کے لیے استعمال ہونے والی زبان منتخب کریں۔ سسٹم ڈیفالٹ آپ کے آلے کی زبان کی پیروی کرتا ہے۔';

  @override
  String get settingsLanguageFieldLabel => 'ایپ کی زبان';

  @override
  String get settingsLanguageFieldHelper =>
      'فوراً لاگو ہوتا ہے اور دوبارہ شروع کرنے کے بعد بھی محفوظ رہتا ہے۔';

  @override
  String get settingsLanguageSearchHint => 'زبانیں تلاش کریں';

  @override
  String get settingsLanguageEmptyText => 'کوئی زبان نہیں ملی';

  @override
  String get settingsLanguageSystemDefault => 'سسٹم ڈیفالٹ';
}
