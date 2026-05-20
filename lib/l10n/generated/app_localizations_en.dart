// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageDescription =>
      'Choose the language used by CodeWalk. System default follows your device language.';

  @override
  String get settingsLanguageFieldLabel => 'App language';

  @override
  String get settingsLanguageFieldHelper =>
      'Applies immediately and persists across restarts.';

  @override
  String get settingsLanguageSearchHint => 'Search languages';

  @override
  String get settingsLanguageEmptyText => 'No languages found';

  @override
  String get settingsLanguageSystemDefault => 'System default';
}
