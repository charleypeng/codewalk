import 'dart:convert';

import 'package:codewalk/core/logging/app_logger.dart';
import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/presentation/pages/logs_page.dart';
import 'package:codewalk/presentation/providers/settings_provider.dart';
import 'package:codewalk/presentation/services/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../support/fakes.dart';
import '../support/pump_localized_app.dart';

void main() {
  setUp(() {
    AppLogger.clearEntries();
    AppLogger.setPerformanceLoggingEnabled(false);
  });

  tearDown(() {
    AppLogger.clearEntries();
    AppLogger.setPerformanceLoggingEnabled(false);
  });

  SettingsProvider buildSettingsProvider(InMemoryAppLocalDataSource local) {
    return SettingsProvider(
      localDataSource: local,
      dioClient: DioClient(),
      soundService: SoundService(),
    );
  }

  Widget logsPageWithProvider(SettingsProvider provider) {
    return ChangeNotifierProvider<SettingsProvider>.value(
      value: provider,
      child: const LogsPage(),
    );
  }

  testWidgets('renders, filters, and clears logs', (tester) async {
    final provider = buildSettingsProvider(InMemoryAppLocalDataSource());
    AppLogger.info('alpha message');
    AppLogger.warn('beta message');

    await tester.pumpWidget(
      localizedMaterialApp(home: logsPageWithProvider(provider)),
    );
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

  testWidgets('toggles, persists, and filters performance logs', (
    tester,
  ) async {
    final local = InMemoryAppLocalDataSource();
    final provider = buildSettingsProvider(local);

    await tester.pumpWidget(
      localizedMaterialApp(home: logsPageWithProvider(provider)),
    );
    await tester.pumpAndSettle();

    expect(provider.performanceLoggingEnabled, isFalse);
    expect(AppLogger.performanceLoggingEnabled, isFalse);

    await tester.tap(find.text('Measure performance'));
    await tester.pumpAndSettle();

    expect(provider.performanceLoggingEnabled, isTrue);
    expect(AppLogger.performanceLoggingEnabled, isTrue);
    final persisted = jsonDecode(local.experienceSettingsJson!);
    expect(persisted['performanceLoggingEnabled'], isTrue);

    AppLogger.info('regular message');
    await AppLogger.runPerformanceTask('load_messages', () async {});
    await tester.pumpAndSettle();

    expect(find.textContaining('regular message'), findsOneWidget);
    expect(find.textContaining('PERFORMANCE load_messages'), findsOneWidget);

    await tester.tap(find.text('Performance'));
    await tester.pumpAndSettle();

    expect(find.textContaining('regular message'), findsNothing);
    expect(find.textContaining('PERFORMANCE load_messages'), findsOneWidget);

    await tester.tap(find.byTooltip('Slowest performance logs'));
    await tester.pumpAndSettle();

    expect(find.text('Slowest performance logs'), findsOneWidget);
    expect(find.text('load_messages'), findsOneWidget);
  });
}
