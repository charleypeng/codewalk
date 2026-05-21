// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get settingsLanguageTitle => 'ভাষা';

  @override
  String get settingsLanguageDescription =>
      'CodeWalk যে ভাষা ব্যবহার করবে তা বেছে নিন। সিস্টেম ডিফল্ট আপনার ডিভাইসের ভাষা অনুসরণ করে।';

  @override
  String get settingsLanguageFieldLabel => 'অ্যাপের ভাষা';

  @override
  String get settingsLanguageFieldHelper =>
      'তাৎক্ষণিকভাবে প্রয়োগ হয় এবং পুনরায় চালুর পরেও থাকে।';

  @override
  String get settingsLanguageSearchHint => 'ভাষা খুঁজুন';

  @override
  String get settingsLanguageEmptyText => 'কোনো ভাষা পাওয়া যায়নি';

  @override
  String get settingsLanguageSystemDefault => 'সিস্টেম ডিফল্ট';

  @override
  String get settingsAboutVersion => 'সংস্করণ';

  @override
  String get settingsAboutLoading => 'লোড হচ্ছে...';

  @override
  String settingsAboutVersionBuild(String version, String buildNumber) {
    return '$version (বিল্ড $buildNumber)';
  }

  @override
  String settingsAboutUpdateAvailable(String version) {
    return 'আপডেট উপলভ্য: v$version';
  }

  @override
  String settingsAboutDownloading(String percent) {
    return 'ডাউনলোড হচ্ছে... $percent%';
  }

  @override
  String get settingsAboutInstalling => 'ইনস্টল হচ্ছে...';

  @override
  String get settingsAboutUpdateInstalled =>
      'আপডেট ইনস্টল হয়েছে। প্রয়োগ করতে অ্যাপটি পুনরায় চালু করুন।';

  @override
  String get settingsAboutRetryInstall => 'ইনস্টল আবার চেষ্টা করুন';

  @override
  String get settingsAboutInstallUpdate => 'আপডেট ইনস্টল করুন';

  @override
  String get settingsAboutDismiss => 'খারিজ করুন';

  @override
  String get settingsAboutUpToDate => 'আপনি হালনাগাদ আছেন';

  @override
  String settingsAboutLatestVersion(String version) {
    return 'v$version সর্বশেষ সংস্করণ';
  }

  @override
  String get settingsAboutCheckOnOpen => 'খোলার সময় আপডেট দেখুন';

  @override
  String get settingsAboutCheckOnOpenDescription =>
      'অ্যাপ শুরু হলে স্বয়ংক্রিয়ভাবে পরীক্ষা করুন';

  @override
  String get settingsAboutCheckForUpdates => 'আপডেট দেখুন';

  @override
  String get settingsAboutChecking => 'পরীক্ষা করা হচ্ছে...';

  @override
  String get settingsAboutTapToCheck => 'নতুন সংস্করণ দেখতে ট্যাপ করুন';

  @override
  String get settingsAboutReplayChatTour => 'চ্যাট ট্যুর আবার দেখুন';

  @override
  String get settingsAboutReplayChatTourDescription =>
      'সেটিংস বন্ধ করে চ্যাট গাইড দেখান';

  @override
  String get settingsAboutResetApp => 'অ্যাপ রিসেট করুন';

  @override
  String get settingsAboutEraseAllData => 'সব ডেটা মুছে পুনরায় চালু করুন';

  @override
  String get settingsAboutResetAppQuestion => 'অ্যাপ রিসেট করবেন?';

  @override
  String get settingsAboutResetAppWarning =>
      'এটি সব সার্ভার, সেটিংস এবং ক্যাশ ডেটা মুছে দেবে। এই কাজটি পূর্বাবস্থায় ফেরানো যাবে না।';

  @override
  String get commonCancel => 'বাতিল';

  @override
  String get commonReset => 'রিসেট';
}
