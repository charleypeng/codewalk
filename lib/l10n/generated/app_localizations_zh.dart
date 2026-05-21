// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get settingsLanguageTitle => '语言';

  @override
  String get settingsLanguageDescription => '选择 CodeWalk 使用的语言。系统默认会跟随设备语言。';

  @override
  String get settingsLanguageFieldLabel => '应用语言';

  @override
  String get settingsLanguageFieldHelper => '立即生效，并在重启后保留。';

  @override
  String get settingsLanguageSearchHint => '搜索语言';

  @override
  String get settingsLanguageEmptyText => '未找到语言';

  @override
  String get settingsLanguageSystemDefault => '系统默认';

  @override
  String get settingsAboutVersion => '版本';

  @override
  String get settingsAboutLoading => '正在加载...';

  @override
  String settingsAboutVersionBuild(String version, String buildNumber) {
    return '$version（构建 $buildNumber）';
  }

  @override
  String settingsAboutUpdateAvailable(String version) {
    return '有可用更新：v$version';
  }

  @override
  String settingsAboutDownloading(String percent) {
    return '正在下载... $percent%';
  }

  @override
  String get settingsAboutInstalling => '正在安装...';

  @override
  String get settingsAboutUpdateInstalled => '更新已安装。请重启应用以生效。';

  @override
  String get settingsAboutRetryInstall => '重试安装';

  @override
  String get settingsAboutInstallUpdate => '安装更新';

  @override
  String get settingsAboutDismiss => '忽略';

  @override
  String get settingsAboutUpToDate => '已是最新版本';

  @override
  String settingsAboutLatestVersion(String version) {
    return 'v$version 是最新版本';
  }

  @override
  String get settingsAboutCheckOnOpen => '打开时检查更新';

  @override
  String get settingsAboutCheckOnOpenDescription => '应用启动时自动检查';

  @override
  String get settingsAboutCheckForUpdates => '检查更新';

  @override
  String get settingsAboutChecking => '正在检查...';

  @override
  String get settingsAboutTapToCheck => '点按以检查新版本';

  @override
  String get settingsAboutReplayChatTour => '重播聊天导览';

  @override
  String get settingsAboutReplayChatTourDescription => '关闭设置并显示聊天引导';

  @override
  String get settingsAboutResetApp => '重置应用';

  @override
  String get settingsAboutEraseAllData => '清除所有数据并重启';

  @override
  String get settingsAboutResetAppQuestion => '重置应用？';

  @override
  String get settingsAboutResetAppWarning => '这将清除所有服务器、设置和缓存数据。此操作无法撤销。';

  @override
  String get commonCancel => '取消';

  @override
  String get commonReset => '重置';
}
