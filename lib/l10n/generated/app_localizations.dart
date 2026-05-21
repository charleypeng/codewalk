import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('ur'),
    Locale('zh'),
  ];

  /// Title for the app language selector in Behavior settings.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// Description for the app language selector in Behavior settings.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used by CodeWalk. System default follows your device language.'**
  String get settingsLanguageDescription;

  /// Input label for the app language selector.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsLanguageFieldLabel;

  /// Helper text under the app language selector.
  ///
  /// In en, this message translates to:
  /// **'Applies immediately and persists across restarts.'**
  String get settingsLanguageFieldHelper;

  /// Search hint inside the language selector bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Search languages'**
  String get settingsLanguageSearchHint;

  /// Empty state shown when language search has no matches.
  ///
  /// In en, this message translates to:
  /// **'No languages found'**
  String get settingsLanguageEmptyText;

  /// Option that makes CodeWalk follow the platform locale.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystemDefault;

  /// Title for the app version row in About settings.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsAboutVersion;

  /// Loading placeholder while app version information is read.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get settingsAboutLoading;

  /// Version and build number shown in About settings.
  ///
  /// In en, this message translates to:
  /// **'{version} (build {buildNumber})'**
  String settingsAboutVersionBuild(String version, String buildNumber);

  /// Title shown when a newer CodeWalk version is available.
  ///
  /// In en, this message translates to:
  /// **'Update available: v{version}'**
  String settingsAboutUpdateAvailable(String version);

  /// Update download progress label.
  ///
  /// In en, this message translates to:
  /// **'Downloading... {percent}%'**
  String settingsAboutDownloading(String percent);

  /// Update installation progress label.
  ///
  /// In en, this message translates to:
  /// **'Installing...'**
  String get settingsAboutInstalling;

  /// Message shown after an app update was installed.
  ///
  /// In en, this message translates to:
  /// **'Update installed. Restart the app to apply.'**
  String get settingsAboutUpdateInstalled;

  /// Button label to retry a failed update installation.
  ///
  /// In en, this message translates to:
  /// **'Retry install'**
  String get settingsAboutRetryInstall;

  /// Button label to install an available app update.
  ///
  /// In en, this message translates to:
  /// **'Install update'**
  String get settingsAboutInstallUpdate;

  /// Button label to dismiss the available update card.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get settingsAboutDismiss;

  /// Title shown when no app update is available.
  ///
  /// In en, this message translates to:
  /// **'You\'\'re up to date'**
  String get settingsAboutUpToDate;

  /// Subtitle shown when the installed app version is current.
  ///
  /// In en, this message translates to:
  /// **'v{version} is the latest version'**
  String settingsAboutLatestVersion(String version);

  /// Switch title for checking app updates at startup.
  ///
  /// In en, this message translates to:
  /// **'Check for updates on open'**
  String get settingsAboutCheckOnOpen;

  /// Switch subtitle for checking app updates at startup.
  ///
  /// In en, this message translates to:
  /// **'Automatically check when the app starts'**
  String get settingsAboutCheckOnOpenDescription;

  /// List tile title to manually check for app updates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get settingsAboutCheckForUpdates;

  /// Status shown while checking for app updates.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get settingsAboutChecking;

  /// Subtitle for the manual update check action.
  ///
  /// In en, this message translates to:
  /// **'Tap to check for new versions'**
  String get settingsAboutTapToCheck;

  /// About settings action that replays the guided chat tour.
  ///
  /// In en, this message translates to:
  /// **'Replay chat tour'**
  String get settingsAboutReplayChatTour;

  /// Subtitle for the guided chat tour replay action.
  ///
  /// In en, this message translates to:
  /// **'Close settings and show the guided chat walkthrough'**
  String get settingsAboutReplayChatTourDescription;

  /// Danger action title that resets all app data.
  ///
  /// In en, this message translates to:
  /// **'Reset app'**
  String get settingsAboutResetApp;

  /// Subtitle for the reset app danger action.
  ///
  /// In en, this message translates to:
  /// **'Erase all data and restart'**
  String get settingsAboutEraseAllData;

  /// Confirmation dialog title before resetting app data.
  ///
  /// In en, this message translates to:
  /// **'Reset app?'**
  String get settingsAboutResetAppQuestion;

  /// Confirmation dialog warning before resetting app data.
  ///
  /// In en, this message translates to:
  /// **'This will erase all servers, settings, and cached data. This action cannot be undone.'**
  String get settingsAboutResetAppWarning;

  /// Generic cancel button label.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Generic reset button label.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
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
    'ur',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'ur':
      return AppLocalizationsUr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
