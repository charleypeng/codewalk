// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get settingsLanguageTitle => 'Sprache';

  @override
  String get settingsLanguageDescription =>
      'Wähle die Sprache für CodeWalk. Systemstandard folgt der Gerätesprache.';

  @override
  String get settingsLanguageFieldLabel => 'App-Sprache';

  @override
  String get settingsLanguageFieldHelper =>
      'Wird sofort angewendet und nach Neustarts beibehalten.';

  @override
  String get settingsLanguageSearchHint => 'Sprachen suchen';

  @override
  String get settingsLanguageEmptyText => 'Keine Sprachen gefunden';

  @override
  String get settingsLanguageSystemDefault => 'Systemstandard';
}
