import 'package:codewalk/core/i18n/app_locales.dart';
import 'package:codewalk/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpLocalizedApp(
  WidgetTester tester, {
  required Widget child,
  String localeCode = 'en',
}) async {
  await tester.pumpWidget(MaterialApp(
    locale: Locale(localeCode),
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocales.supported,
    home: child,
  ));
}

Widget localizedMaterialApp({required Widget home}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocales.supported,
    home: home,
  );
}
