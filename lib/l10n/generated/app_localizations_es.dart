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

  @override
  String get settingsAboutVersion => 'Versión';

  @override
  String get settingsAboutLoading => 'Cargando...';

  @override
  String settingsAboutVersionBuild(String version, String buildNumber) {
    return '$version (compilación $buildNumber)';
  }

  @override
  String settingsAboutUpdateAvailable(String version) {
    return 'Actualización disponible: v$version';
  }

  @override
  String settingsAboutDownloading(String percent) {
    return 'Descargando... $percent%';
  }

  @override
  String get settingsAboutInstalling => 'Instalando...';

  @override
  String get settingsAboutUpdateInstalled =>
      'Actualización instalada. Reinicia la app para aplicarla.';

  @override
  String get settingsAboutRetryInstall => 'Reintentar instalación';

  @override
  String get settingsAboutInstallUpdate => 'Instalar actualización';

  @override
  String get settingsAboutDismiss => 'Descartar';

  @override
  String get settingsAboutUpToDate => 'Estás al día';

  @override
  String settingsAboutLatestVersion(String version) {
    return 'v$version es la versión más reciente';
  }

  @override
  String get settingsAboutCheckOnOpen => 'Buscar actualizaciones al abrir';

  @override
  String get settingsAboutCheckOnOpenDescription =>
      'Comprobar automáticamente cuando inicia la app';

  @override
  String get settingsAboutCheckForUpdates => 'Buscar actualizaciones';

  @override
  String get settingsAboutChecking => 'Comprobando...';

  @override
  String get settingsAboutTapToCheck => 'Toca para buscar nuevas versiones';

  @override
  String get settingsAboutReplayChatTour => 'Repetir recorrido del chat';

  @override
  String get settingsAboutReplayChatTourDescription =>
      'Cerrar ajustes y mostrar la guía del chat';

  @override
  String get settingsAboutResetApp => 'Restablecer app';

  @override
  String get settingsAboutEraseAllData => 'Borrar todos los datos y reiniciar';

  @override
  String get settingsAboutResetAppQuestion => '¿Restablecer app?';

  @override
  String get settingsAboutResetAppWarning =>
      'Esto borrará todos los servidores, ajustes y datos en caché. Esta acción no se puede deshacer.';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonReset => 'Restablecer';
}
