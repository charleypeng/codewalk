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

  @override
  String get settingsAboutVersion => 'Versione';

  @override
  String get settingsAboutLoading => 'Caricamento...';

  @override
  String settingsAboutVersionBuild(String version, String buildNumber) {
    return '$version (build $buildNumber)';
  }

  @override
  String settingsAboutUpdateAvailable(String version) {
    return 'Aggiornamento disponibile: v$version';
  }

  @override
  String settingsAboutDownloading(String percent) {
    return 'Download... $percent%';
  }

  @override
  String get settingsAboutInstalling => 'Installazione...';

  @override
  String get settingsAboutUpdateInstalled =>
      'Aggiornamento installato. Riavvia CodeWalk per applicarlo.';

  @override
  String get settingsAboutRetryInstall => 'Riprova installazione';

  @override
  String get settingsAboutInstallUpdate => 'Installa aggiornamento';

  @override
  String get settingsAboutDismiss => 'Ignora';

  @override
  String get settingsAboutUpToDate => 'Sei aggiornato';

  @override
  String settingsAboutLatestVersion(String version) {
    return 'v$version è la versione più recente';
  }

  @override
  String get settingsAboutCheckOnOpen => 'Controlla aggiornamenti all’apertura';

  @override
  String get settingsAboutCheckOnOpenDescription =>
      'Controlla automaticamente quando CodeWalk si avvia';

  @override
  String get settingsAboutCheckForUpdates => 'Controlla aggiornamenti';

  @override
  String get settingsAboutChecking => 'Controllo...';

  @override
  String get settingsAboutTapToCheck => 'Tocca per cercare nuove versioni';

  @override
  String get settingsAboutReplayChatTour => 'Ripeti tour della chat';

  @override
  String get settingsAboutReplayChatTourDescription =>
      'Chiudi impostazioni e mostra la guida della chat';

  @override
  String get settingsAboutResetApp => 'Reimposta app';

  @override
  String get settingsAboutEraseAllData => 'Cancella tutti i dati e riavvia';

  @override
  String get settingsAboutResetAppQuestion => 'Reimpostare app?';

  @override
  String get settingsAboutResetAppWarning =>
      'Tutti i server, le impostazioni e i dati in cache saranno cancellati. Questa azione non può essere annullata.';

  @override
  String get commonCancel => 'Annulla';

  @override
  String get commonReset => 'Reimposta';
}
