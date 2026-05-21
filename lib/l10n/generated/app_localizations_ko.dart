// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get settingsLanguageTitle => '언어';

  @override
  String get settingsLanguageDescription =>
      'CodeWalk에서 사용할 언어를 선택하세요. 시스템 기본값은 기기 언어를 따릅니다.';

  @override
  String get settingsLanguageFieldLabel => '앱 언어';

  @override
  String get settingsLanguageFieldHelper => '즉시 적용되며 다시 시작해도 유지됩니다.';

  @override
  String get settingsLanguageSearchHint => '언어 검색';

  @override
  String get settingsLanguageEmptyText => '언어를 찾을 수 없음';

  @override
  String get settingsLanguageSystemDefault => '시스템 기본값';

  @override
  String get settingsAboutVersion => '버전';

  @override
  String get settingsAboutLoading => '로드 중...';

  @override
  String settingsAboutVersionBuild(String version, String buildNumber) {
    return '$version (빌드 $buildNumber)';
  }

  @override
  String settingsAboutUpdateAvailable(String version) {
    return '업데이트 사용 가능: v$version';
  }

  @override
  String settingsAboutDownloading(String percent) {
    return '다운로드 중... $percent%';
  }

  @override
  String get settingsAboutInstalling => '설치 중...';

  @override
  String get settingsAboutUpdateInstalled =>
      '업데이트가 설치되었습니다. 적용하려면 앱을 다시 시작하세요.';

  @override
  String get settingsAboutRetryInstall => '설치 다시 시도';

  @override
  String get settingsAboutInstallUpdate => '업데이트 설치';

  @override
  String get settingsAboutDismiss => '닫기';

  @override
  String get settingsAboutUpToDate => '최신 상태입니다';

  @override
  String settingsAboutLatestVersion(String version) {
    return 'v$version이 최신 버전입니다';
  }

  @override
  String get settingsAboutCheckOnOpen => '열 때 업데이트 확인';

  @override
  String get settingsAboutCheckOnOpenDescription => '앱 시작 시 자동으로 확인';

  @override
  String get settingsAboutCheckForUpdates => '업데이트 확인';

  @override
  String get settingsAboutChecking => '확인 중...';

  @override
  String get settingsAboutTapToCheck => '새 버전을 확인하려면 탭하세요';

  @override
  String get settingsAboutReplayChatTour => '채팅 둘러보기 다시 보기';

  @override
  String get settingsAboutReplayChatTourDescription => '설정을 닫고 채팅 안내를 표시';

  @override
  String get settingsAboutResetApp => '앱 초기화';

  @override
  String get settingsAboutEraseAllData => '모든 데이터를 지우고 다시 시작';

  @override
  String get settingsAboutResetAppQuestion => '앱을 초기화할까요?';

  @override
  String get settingsAboutResetAppWarning =>
      '모든 서버, 설정, 캐시 데이터가 지워집니다. 이 작업은 되돌릴 수 없습니다.';

  @override
  String get commonCancel => '취소';

  @override
  String get commonReset => '초기화';
}
