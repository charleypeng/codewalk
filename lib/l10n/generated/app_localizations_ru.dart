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

  @override
  String get settingsAboutVersion => 'Версия';

  @override
  String get settingsAboutLoading => 'Загрузка...';

  @override
  String settingsAboutVersionBuild(String version, String buildNumber) {
    return '$version (сборка $buildNumber)';
  }

  @override
  String settingsAboutUpdateAvailable(String version) {
    return 'Доступно обновление: v$version';
  }

  @override
  String settingsAboutDownloading(String percent) {
    return 'Загрузка... $percent%';
  }

  @override
  String get settingsAboutInstalling => 'Установка...';

  @override
  String get settingsAboutUpdateInstalled =>
      'Обновление установлено. Перезапустите приложение, чтобы применить его.';

  @override
  String get settingsAboutRetryInstall => 'Повторить установку';

  @override
  String get settingsAboutInstallUpdate => 'Установить обновление';

  @override
  String get settingsAboutDismiss => 'Скрыть';

  @override
  String get settingsAboutUpToDate => 'У вас актуальная версия';

  @override
  String settingsAboutLatestVersion(String version) {
    return 'v$version — последняя версия';
  }

  @override
  String get settingsAboutCheckOnOpen => 'Проверять обновления при запуске';

  @override
  String get settingsAboutCheckOnOpenDescription =>
      'Автоматически проверять при запуске приложения';

  @override
  String get settingsAboutCheckForUpdates => 'Проверить обновления';

  @override
  String get settingsAboutChecking => 'Проверка...';

  @override
  String get settingsAboutTapToCheck => 'Нажмите, чтобы проверить новые версии';

  @override
  String get settingsAboutReplayChatTour => 'Повторить тур по чату';

  @override
  String get settingsAboutReplayChatTourDescription =>
      'Закрыть настройки и показать гид по чату';

  @override
  String get settingsAboutResetApp => 'Сбросить приложение';

  @override
  String get settingsAboutEraseAllData => 'Удалить все данные и перезапустить';

  @override
  String get settingsAboutResetAppQuestion => 'Сбросить приложение?';

  @override
  String get settingsAboutResetAppWarning =>
      'Это удалит все серверы, настройки и кэшированные данные. Это действие нельзя отменить.';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonReset => 'Сбросить';
}
