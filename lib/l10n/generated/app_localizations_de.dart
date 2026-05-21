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

  @override
  String get settingsAboutVersion => 'Version';

  @override
  String get settingsAboutLoading => 'Wird geladen...';

  @override
  String settingsAboutVersionBuild(String version, String buildNumber) {
    return '$version (Build $buildNumber)';
  }

  @override
  String settingsAboutUpdateAvailable(String version) {
    return 'Update verfügbar: v$version';
  }

  @override
  String settingsAboutDownloading(String percent) {
    return 'Wird heruntergeladen... $percent%';
  }

  @override
  String get settingsAboutInstalling => 'Wird installiert...';

  @override
  String get settingsAboutUpdateInstalled =>
      'Update installiert. Starte die App neu, um es anzuwenden.';

  @override
  String get settingsAboutRetryInstall => 'Installation erneut versuchen';

  @override
  String get settingsAboutInstallUpdate => 'Update installieren';

  @override
  String get settingsAboutDismiss => 'Ausblenden';

  @override
  String get settingsAboutUpToDate => 'Du bist auf dem neuesten Stand';

  @override
  String settingsAboutLatestVersion(String version) {
    return 'v$version ist die neueste Version';
  }

  @override
  String get settingsAboutCheckOnOpen => 'Beim Öffnen nach Updates suchen';

  @override
  String get settingsAboutCheckOnOpenDescription =>
      'Beim Start der App automatisch prüfen';

  @override
  String get settingsAboutCheckForUpdates => 'Nach Updates suchen';

  @override
  String get settingsAboutChecking => 'Prüfung läuft...';

  @override
  String get settingsAboutTapToCheck =>
      'Tippen, um nach neuen Versionen zu suchen';

  @override
  String get settingsAboutReplayChatTour => 'Chat-Tour erneut abspielen';

  @override
  String get settingsAboutReplayChatTourDescription =>
      'Einstellungen schließen und geführte Chat-Einführung zeigen';

  @override
  String get settingsAboutResetApp => 'App zurücksetzen';

  @override
  String get settingsAboutEraseAllData => 'Alle Daten löschen und neu starten';

  @override
  String get settingsAboutResetAppQuestion => 'App zurücksetzen?';

  @override
  String get settingsAboutResetAppWarning =>
      'Dadurch werden alle Server, Einstellungen und zwischengespeicherten Daten gelöscht. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonReset => 'Zurücksetzen';
}
