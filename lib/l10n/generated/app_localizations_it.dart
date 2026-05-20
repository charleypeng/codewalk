// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get settingsLanguageTitle => 'Lingua';

  @override
  String get settingsLanguageDescription =>
      'Scegli la lingua usata da CodeWalk. L’impostazione predefinita di sistema segue la lingua del dispositivo.';

  @override
  String get settingsLanguageFieldLabel => 'Lingua dell’app';

  @override
  String get settingsLanguageFieldHelper =>
      'Si applica subito e resta dopo il riavvio.';

  @override
  String get settingsLanguageSearchHint => 'Cerca lingue';

  @override
  String get settingsLanguageEmptyText => 'Nessuna lingua trovata';

  @override
  String get settingsLanguageSystemDefault => 'Predefinita di sistema';
}
