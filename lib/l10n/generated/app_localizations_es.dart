// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageDescription =>
      'Elige el idioma que usa CodeWalk. El valor predeterminado del sistema sigue el idioma del dispositivo.';

  @override
  String get settingsLanguageFieldLabel => 'Idioma de la app';

  @override
  String get settingsLanguageFieldHelper =>
      'Se aplica de inmediato y se mantiene tras reiniciar.';

  @override
  String get settingsLanguageSearchHint => 'Buscar idiomas';

  @override
  String get settingsLanguageEmptyText => 'No se encontraron idiomas';

  @override
  String get settingsLanguageSystemDefault => 'Predeterminado del sistema';
}
