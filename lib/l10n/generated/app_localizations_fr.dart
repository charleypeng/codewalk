// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get settingsLanguageTitle => 'Langue';

  @override
  String get settingsLanguageDescription =>
      'Choisissez la langue utilisée par CodeWalk. La valeur par défaut du système suit la langue de votre appareil.';

  @override
  String get settingsLanguageFieldLabel => 'Langue de l’application';

  @override
  String get settingsLanguageFieldHelper =>
      'S’applique immédiatement et persiste après redémarrage.';

  @override
  String get settingsLanguageSearchHint => 'Rechercher des langues';

  @override
  String get settingsLanguageEmptyText => 'Aucune langue trouvée';

  @override
  String get settingsLanguageSystemDefault => 'Valeur par défaut du système';
}
