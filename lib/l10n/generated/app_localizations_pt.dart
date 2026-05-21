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

  @override
  String get settingsAboutVersion => 'Versão';

  @override
  String get settingsAboutLoading => 'Carregando...';

  @override
  String settingsAboutVersionBuild(String version, String buildNumber) {
    return '$version (build $buildNumber)';
  }

  @override
  String settingsAboutUpdateAvailable(String version) {
    return 'Atualização disponível: v$version';
  }

  @override
  String settingsAboutDownloading(String percent) {
    return 'Baixando... $percent%';
  }

  @override
  String get settingsAboutInstalling => 'Instalando...';

  @override
  String get settingsAboutUpdateInstalled =>
      'Atualização instalada. Reinicie o app para aplicar.';

  @override
  String get settingsAboutRetryInstall => 'Tentar instalar novamente';

  @override
  String get settingsAboutInstallUpdate => 'Instalar atualização';

  @override
  String get settingsAboutDismiss => 'Dispensar';

  @override
  String get settingsAboutUpToDate => 'Você está em dia';

  @override
  String settingsAboutLatestVersion(String version) {
    return 'v$version é a versão mais recente';
  }

  @override
  String get settingsAboutCheckOnOpen => 'Verificar atualizações ao abrir';

  @override
  String get settingsAboutCheckOnOpenDescription =>
      'Verificar automaticamente quando o app iniciar';

  @override
  String get settingsAboutCheckForUpdates => 'Verificar atualizações';

  @override
  String get settingsAboutChecking => 'Verificando...';

  @override
  String get settingsAboutTapToCheck => 'Toque para buscar novas versões';

  @override
  String get settingsAboutReplayChatTour => 'Repetir tour do chat';

  @override
  String get settingsAboutReplayChatTourDescription =>
      'Fechar configurações e mostrar o guia do chat';

  @override
  String get settingsAboutResetApp => 'Redefinir app';

  @override
  String get settingsAboutEraseAllData => 'Apagar todos os dados e reiniciar';

  @override
  String get settingsAboutResetAppQuestion => 'Redefinir app?';

  @override
  String get settingsAboutResetAppWarning =>
      'Isso apagará todos os servidores, configurações e dados em cache. Esta ação não pode ser desfeita.';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonReset => 'Redefinir';
}
