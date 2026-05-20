import '../../l10n/generated/app_localizations.dart';

class L10nBridge {
  const L10nBridge._();

  static AppLocalizations? _current;

  static AppLocalizations? get current => _current;

  static void update(AppLocalizations? localizations) {
    _current = localizations;
  }
}
