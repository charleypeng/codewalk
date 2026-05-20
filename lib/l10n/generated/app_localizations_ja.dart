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
}
