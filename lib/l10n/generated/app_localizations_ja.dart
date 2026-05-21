// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get settingsLanguageTitle => '言語';

  @override
  String get settingsLanguageDescription =>
      'CodeWalk で使用する言語を選択します。システム既定ではデバイスの言語に従います。';

  @override
  String get settingsLanguageFieldLabel => 'アプリの言語';

  @override
  String get settingsLanguageFieldHelper => 'すぐに適用され、再起動後も保持されます。';

  @override
  String get settingsLanguageSearchHint => '言語を検索';

  @override
  String get settingsLanguageEmptyText => '言語が見つかりません';

  @override
  String get settingsLanguageSystemDefault => 'システム既定';

  @override
  String get settingsAboutVersion => 'バージョン';

  @override
  String get settingsAboutLoading => '読み込み中...';

  @override
  String settingsAboutVersionBuild(String version, String buildNumber) {
    return '$version (ビルド $buildNumber)';
  }

  @override
  String settingsAboutUpdateAvailable(String version) {
    return 'アップデートがあります: v$version';
  }

  @override
  String settingsAboutDownloading(String percent) {
    return 'ダウンロード中... $percent%';
  }

  @override
  String get settingsAboutInstalling => 'インストール中...';

  @override
  String get settingsAboutUpdateInstalled =>
      'アップデートをインストールしました。適用するにはアプリを再起動してください。';

  @override
  String get settingsAboutRetryInstall => 'インストールを再試行';

  @override
  String get settingsAboutInstallUpdate => 'アップデートをインストール';

  @override
  String get settingsAboutDismiss => '閉じる';

  @override
  String get settingsAboutUpToDate => '最新です';

  @override
  String settingsAboutLatestVersion(String version) {
    return 'v$version が最新バージョンです';
  }

  @override
  String get settingsAboutCheckOnOpen => '起動時にアップデートを確認';

  @override
  String get settingsAboutCheckOnOpenDescription => 'アプリ起動時に自動で確認します';

  @override
  String get settingsAboutCheckForUpdates => 'アップデートを確認';

  @override
  String get settingsAboutChecking => '確認中...';

  @override
  String get settingsAboutTapToCheck => 'タップして新しいバージョンを確認';

  @override
  String get settingsAboutReplayChatTour => 'チャットツアーを再生';

  @override
  String get settingsAboutReplayChatTourDescription => '設定を閉じてチャットのガイドを表示します';

  @override
  String get settingsAboutResetApp => 'アプリをリセット';

  @override
  String get settingsAboutEraseAllData => 'すべてのデータを消去して再起動';

  @override
  String get settingsAboutResetAppQuestion => 'アプリをリセットしますか？';

  @override
  String get settingsAboutResetAppWarning =>
      'すべてのサーバー、設定、キャッシュデータが消去されます。この操作は元に戻せません。';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonReset => 'リセット';
}
