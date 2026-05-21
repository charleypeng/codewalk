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

  @override
  String get settingsAboutVersion => 'الإصدار';

  @override
  String get settingsAboutLoading => 'جارٍ التحميل...';

  @override
  String settingsAboutVersionBuild(String version, String buildNumber) {
    return '$version (البناء $buildNumber)';
  }

  @override
  String settingsAboutUpdateAvailable(String version) {
    return 'يتوفر تحديث: v$version';
  }

  @override
  String settingsAboutDownloading(String percent) {
    return 'جارٍ التنزيل... $percent%';
  }

  @override
  String get settingsAboutInstalling => 'جارٍ التثبيت...';

  @override
  String get settingsAboutUpdateInstalled =>
      'تم تثبيت التحديث. أعد تشغيل التطبيق لتطبيقه.';

  @override
  String get settingsAboutRetryInstall => 'إعادة محاولة التثبيت';

  @override
  String get settingsAboutInstallUpdate => 'تثبيت التحديث';

  @override
  String get settingsAboutDismiss => 'تجاهل';

  @override
  String get settingsAboutUpToDate => 'أنت تستخدم أحدث إصدار';

  @override
  String settingsAboutLatestVersion(String version) {
    return 'v$version هو أحدث إصدار';
  }

  @override
  String get settingsAboutCheckOnOpen => 'البحث عن تحديثات عند الفتح';

  @override
  String get settingsAboutCheckOnOpenDescription =>
      'البحث تلقائيًا عند بدء التطبيق';

  @override
  String get settingsAboutCheckForUpdates => 'البحث عن تحديثات';

  @override
  String get settingsAboutChecking => 'جارٍ التحقق...';

  @override
  String get settingsAboutTapToCheck => 'اضغط للبحث عن إصدارات جديدة';

  @override
  String get settingsAboutReplayChatTour => 'إعادة عرض جولة الدردشة';

  @override
  String get settingsAboutReplayChatTourDescription =>
      'إغلاق الإعدادات وعرض دليل الدردشة';

  @override
  String get settingsAboutResetApp => 'إعادة ضبط التطبيق';

  @override
  String get settingsAboutEraseAllData => 'مسح كل البيانات وإعادة التشغيل';

  @override
  String get settingsAboutResetAppQuestion => 'إعادة ضبط التطبيق؟';

  @override
  String get settingsAboutResetAppWarning =>
      'سيؤدي هذا إلى مسح كل الخوادم والإعدادات والبيانات المخزنة مؤقتًا. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonReset => 'إعادة ضبط';
}
