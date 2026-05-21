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

  @override
  String get settingsAboutVersion => 'Version';

  @override
  String get settingsAboutLoading => 'Chargement...';

  @override
  String settingsAboutVersionBuild(String version, String buildNumber) {
    return '$version (build $buildNumber)';
  }

  @override
  String settingsAboutUpdateAvailable(String version) {
    return 'Mise à jour disponible : v$version';
  }

  @override
  String settingsAboutDownloading(String percent) {
    return 'Téléchargement... $percent%';
  }

  @override
  String get settingsAboutInstalling => 'Installation...';

  @override
  String get settingsAboutUpdateInstalled =>
      'Mise à jour installée. Redémarrez CodeWalk pour appliquer le changement.';

  @override
  String get settingsAboutRetryInstall => 'Réessayer installation';

  @override
  String get settingsAboutInstallUpdate => 'Installer la mise à jour';

  @override
  String get settingsAboutDismiss => 'Ignorer';

  @override
  String get settingsAboutUpToDate => 'Vous êtes à jour';

  @override
  String settingsAboutLatestVersion(String version) {
    return 'v$version est la version la plus récente';
  }

  @override
  String get settingsAboutCheckOnOpen =>
      'Chercher les mises à jour au démarrage';

  @override
  String get settingsAboutCheckOnOpenDescription =>
      'Vérifier automatiquement au lancement de CodeWalk';

  @override
  String get settingsAboutCheckForUpdates => 'Chercher les mises à jour';

  @override
  String get settingsAboutChecking => 'Vérification...';

  @override
  String get settingsAboutTapToCheck =>
      'Touchez pour chercher de nouvelles versions';

  @override
  String get settingsAboutReplayChatTour => 'Rejouer le tour du chat';

  @override
  String get settingsAboutReplayChatTourDescription =>
      'Fermer les réglages et afficher le guide du chat';

  @override
  String get settingsAboutResetApp => 'Réinitialiser CodeWalk';

  @override
  String get settingsAboutEraseAllData =>
      'Effacer toutes les données et redémarrer';

  @override
  String get settingsAboutResetAppQuestion => 'Réinitialiser CodeWalk ?';

  @override
  String get settingsAboutResetAppWarning =>
      'Tous les serveurs, réglages et données en cache seront effacés. Cette action est irréversible.';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonReset => 'Réinitialiser';
}
