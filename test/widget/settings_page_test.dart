import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/presentation/pages/settings_page.dart';
import 'package:codewalk/presentation/providers/settings_provider.dart';
import 'package:codewalk/presentation/services/sound_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../support/fakes.dart';

void main() {
  testWidgets('hides shortcuts on mobile and opens notifications section', (
    WidgetTester tester,
  ) async {
    final local = InMemoryAppLocalDataSource()
      ..experienceSettingsJson = '{"checkUpdatesOnOpen": false}';
    final settingsProvider = SettingsProvider(
      localDataSource: local,
      dioClient: DioClient(),
      soundService: SoundService(),
    );
    await settingsProvider.initialize();
    addTearDown(settingsProvider.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settingsProvider,
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Setup Wizard'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Behavior'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Speech to text'), findsOneWidget);
    expect(find.text('Logs'), findsOneWidget);
    expect(find.text('Sounds'), findsNothing);
    expect(find.text('Shortcuts'), findsNothing);
    expect(find.text('Servers'), findsOneWidget);

    await tester.tap(find.text('Appearance').first);
    await tester.pumpAndSettle();

    // Density card may be below the fold after Theme/Color/Contrast cards.
    await tester.scrollUntilVisible(
      find.text('Extra Dense'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Extra Dense'), findsOneWidget);
    expect(find.text('Dense'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('Spacious'), findsOneWidget);
    expect(find.text('Extra Spacious'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('settings_toggle_composer_tips')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Composer tips'), findsOneWidget);
    expect(find.text('Task list'), findsOneWidget);

    final composerTipsFinder = find.byKey(
      const ValueKey<String>('settings_toggle_composer_tips'),
    );
    expect(tester.widget<SwitchListTile>(composerTipsFinder).value, isTrue);

    await tester.tap(composerTipsFinder);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(composerTipsFinder).value, isFalse);
    expect(settingsProvider.showComposerTips, isFalse);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Behavior').first);
    await tester.pumpAndSettle();

    final syncToggleFinder = find.byKey(
      const ValueKey<String>('settings_toggle_experimental_multi_device_sync'),
    );
    expect(syncToggleFinder, findsOneWidget);
    expect(find.text('Enable experimental multi-device sync'), findsOneWidget);
    expect(
      find.text(
        'Can abort ongoing sessions when working in more than one session at the same time.',
      ),
      findsOneWidget,
    );
    expect(tester.widget<SwitchListTile>(syncToggleFinder).value, isFalse);

    await tester.tap(syncToggleFinder);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(syncToggleFinder).value, isTrue);
    expect(settingsProvider.enableExperimentalMultiDeviceSync, isTrue);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
  });

  testWidgets('mobile back follows detail then list then app flow', (
    WidgetTester tester,
  ) async {
    final local = InMemoryAppLocalDataSource()
      ..experienceSettingsJson = '{"checkUpdatesOnOpen": false}';
    final settingsProvider = SettingsProvider(
      localDataSource: local,
      dioClient: DioClient(),
      soundService: SoundService(),
    );
    await settingsProvider.initialize();
    addTearDown(settingsProvider.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settingsProvider,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    key: const ValueKey<String>('open_settings_button'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                    child: const Text('Open settings'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('open_settings_button')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);

    await tester.tap(find.text('Appearance').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('settings_toggle_composer_tips')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Composer tips'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Open settings'), findsOneWidget);
    expect(find.byType(SettingsPage), findsNothing);
  });

  testWidgets('shows Android background alert controls in notifications', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final local = InMemoryAppLocalDataSource()
        ..experienceSettingsJson = '{"checkUpdatesOnOpen": false}';
      final settingsProvider = SettingsProvider(
        localDataSource: local,
        dioClient: DioClient(),
        soundService: SoundService(),
      );
      await settingsProvider.initialize();
      addTearDown(settingsProvider.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: const MaterialApp(home: SettingsPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notifications').first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Android background alerts'), findsOneWidget);
      expect(find.text('Background alerts on Android'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('settings_toggle_android_background_alerts'),
        ),
        findsOneWidget,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
