// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageDescription =>
      'Escolha o idioma usado pelo CodeWalk. O padrão do sistema segue o idioma do dispositivo.';

  @override
  String get settingsLanguageFieldLabel => 'Idioma do app';

  @override
  String get settingsLanguageFieldHelper =>
      'Aplica imediatamente e persiste após reiniciar.';

  @override
  String get settingsLanguageSearchHint => 'Pesquisar idiomas';

  @override
  String get settingsLanguageEmptyText => 'Nenhum idioma encontrado';

  @override
  String get settingsLanguageSystemDefault => 'Padrão do sistema';
}
