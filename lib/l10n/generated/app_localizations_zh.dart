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
}
