import 'package:codewalk/core/logging/app_logger.dart';
import 'package:codewalk/presentation/pages/logs_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_localized_app.dart';

void main() {
  setUp(AppLogger.clearEntries);

  testWidgets('renders, filters, and clears logs', (tester) async {
    AppLogger.info('alpha message');
    AppLogger.warn('beta message');

    await tester.pumpWidget(localizedMaterialApp(home: const LogsPage()));
    await tester.pumpAndSettle();

    expect(find.text('App Logs'), findsOneWidget);
    expect(find.textContaining('Showing 2 of 2 entries'), findsOneWidget);

    await tester.tap(find.byTooltip('Search logs'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'beta');
    await tester.pumpAndSettle();

    expect(find.textContaining('Showing 1 of 2 entries'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear logs'));
    await tester.pumpAndSettle();

    expect(find.text('No logs captured yet.'), findsOneWidget);
  });
}
