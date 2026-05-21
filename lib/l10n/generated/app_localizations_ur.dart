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

  @override
  String get settingsAboutVersion => 'ورژن';

  @override
  String get settingsAboutLoading => 'لوڈ ہو رہا ہے...';

  @override
  String settingsAboutVersionBuild(String version, String buildNumber) {
    return '$version (بلڈ $buildNumber)';
  }

  @override
  String settingsAboutUpdateAvailable(String version) {
    return 'اپ ڈیٹ دستیاب ہے: v$version';
  }

  @override
  String settingsAboutDownloading(String percent) {
    return 'ڈاؤن لوڈ ہو رہا ہے... $percent%';
  }

  @override
  String get settingsAboutInstalling => 'انسٹال ہو رہا ہے...';

  @override
  String get settingsAboutUpdateInstalled =>
      'اپ ڈیٹ انسٹال ہو گئی۔ لاگو کرنے کے لیے ایپ دوبارہ شروع کریں۔';

  @override
  String get settingsAboutRetryInstall => 'انسٹال دوبارہ کوشش کریں';

  @override
  String get settingsAboutInstallUpdate => 'اپ ڈیٹ انسٹال کریں';

  @override
  String get settingsAboutDismiss => 'نظر انداز کریں';

  @override
  String get settingsAboutUpToDate => 'آپ تازہ ترین ورژن پر ہیں';

  @override
  String settingsAboutLatestVersion(String version) {
    return 'v$version تازہ ترین ورژن ہے';
  }

  @override
  String get settingsAboutCheckOnOpen => 'کھلنے پر اپ ڈیٹس چیک کریں';

  @override
  String get settingsAboutCheckOnOpenDescription =>
      'ایپ شروع ہونے پر خودکار طور پر چیک کریں';

  @override
  String get settingsAboutCheckForUpdates => 'اپ ڈیٹس چیک کریں';

  @override
  String get settingsAboutChecking => 'چیک ہو رہا ہے...';

  @override
  String get settingsAboutTapToCheck => 'نئے ورژن چیک کرنے کے لیے ٹیپ کریں';

  @override
  String get settingsAboutReplayChatTour => 'چیٹ ٹور دوبارہ چلائیں';

  @override
  String get settingsAboutReplayChatTourDescription =>
      'سیٹنگز بند کریں اور چیٹ گائیڈ دکھائیں';

  @override
  String get settingsAboutResetApp => 'ایپ ری سیٹ کریں';

  @override
  String get settingsAboutEraseAllData => 'تمام ڈیٹا مٹا کر دوبارہ شروع کریں';

  @override
  String get settingsAboutResetAppQuestion => 'ایپ ری سیٹ کریں؟';

  @override
  String get settingsAboutResetAppWarning =>
      'یہ تمام سرورز، سیٹنگز اور کیشڈ ڈیٹا مٹا دے گا۔ یہ عمل واپس نہیں کیا جا سکتا۔';

  @override
  String get commonCancel => 'منسوخ کریں';

  @override
  String get commonReset => 'ری سیٹ';
}
