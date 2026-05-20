// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get settingsLanguageTitle => 'Язык';

  @override
  String get settingsLanguageDescription =>
      'Выберите язык CodeWalk. Системный вариант следует языку устройства.';

  @override
  String get settingsLanguageFieldLabel => 'Язык приложения';

  @override
  String get settingsLanguageFieldHelper =>
      'Применяется сразу и сохраняется после перезапуска.';

  @override
  String get settingsLanguageSearchHint => 'Поиск языков';

  @override
  String get settingsLanguageEmptyText => 'Языки не найдены';

  @override
  String get settingsLanguageSystemDefault => 'Системный по умолчанию';
}
