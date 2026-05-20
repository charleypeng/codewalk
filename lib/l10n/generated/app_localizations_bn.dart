// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get settingsLanguageTitle => 'ভাষা';

  @override
  String get settingsLanguageDescription =>
      'CodeWalk যে ভাষা ব্যবহার করবে তা বেছে নিন। সিস্টেম ডিফল্ট আপনার ডিভাইসের ভাষা অনুসরণ করে।';

  @override
  String get settingsLanguageFieldLabel => 'অ্যাপের ভাষা';

  @override
  String get settingsLanguageFieldHelper =>
      'তাৎক্ষণিকভাবে প্রয়োগ হয় এবং পুনরায় চালুর পরেও থাকে।';

  @override
  String get settingsLanguageSearchHint => 'ভাষা খুঁজুন';

  @override
  String get settingsLanguageEmptyText => 'কোনো ভাষা পাওয়া যায়নি';

  @override
  String get settingsLanguageSystemDefault => 'সিস্টেম ডিফল্ট';
}
