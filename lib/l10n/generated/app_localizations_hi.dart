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

  @override
  String get settingsAboutVersion => 'संस्करण';

  @override
  String get settingsAboutLoading => 'लोड हो रहा है...';

  @override
  String settingsAboutVersionBuild(String version, String buildNumber) {
    return '$version (बिल्ड $buildNumber)';
  }

  @override
  String settingsAboutUpdateAvailable(String version) {
    return 'अपडेट उपलब्ध: v$version';
  }

  @override
  String settingsAboutDownloading(String percent) {
    return 'डाउनलोड हो रहा है... $percent%';
  }

  @override
  String get settingsAboutInstalling => 'इंस्टॉल हो रहा है...';

  @override
  String get settingsAboutUpdateInstalled =>
      'अपडेट इंस्टॉल हो गया। लागू करने के लिए ऐप फिर शुरू करें।';

  @override
  String get settingsAboutRetryInstall => 'इंस्टॉल फिर कोशिश करें';

  @override
  String get settingsAboutInstallUpdate => 'अपडेट इंस्टॉल करें';

  @override
  String get settingsAboutDismiss => 'हटाएँ';

  @override
  String get settingsAboutUpToDate => 'आप अद्यतित हैं';

  @override
  String settingsAboutLatestVersion(String version) {
    return 'v$version नवीनतम संस्करण है';
  }

  @override
  String get settingsAboutCheckOnOpen => 'खुलने पर अपडेट देखें';

  @override
  String get settingsAboutCheckOnOpenDescription =>
      'ऐप शुरू होने पर अपने आप जाँचें';

  @override
  String get settingsAboutCheckForUpdates => 'अपडेट देखें';

  @override
  String get settingsAboutChecking => 'जाँच हो रही है...';

  @override
  String get settingsAboutTapToCheck => 'नए संस्करण देखने के लिए टैप करें';

  @override
  String get settingsAboutReplayChatTour => 'चैट टूर फिर चलाएँ';

  @override
  String get settingsAboutReplayChatTourDescription =>
      'सेटिंग्स बंद करें और चैट गाइड दिखाएँ';

  @override
  String get settingsAboutResetApp => 'ऐप रीसेट करें';

  @override
  String get settingsAboutEraseAllData => 'सारा डेटा मिटाएँ और फिर शुरू करें';

  @override
  String get settingsAboutResetAppQuestion => 'ऐप रीसेट करें?';

  @override
  String get settingsAboutResetAppWarning =>
      'यह सभी सर्वर, सेटिंग्स और कैश डेटा मिटा देगा। यह कार्रवाई वापस नहीं की जा सकती।';

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get commonReset => 'रीसेट';
}
