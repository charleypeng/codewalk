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
}
