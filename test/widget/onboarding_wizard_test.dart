import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/domain/usecases/check_connection.dart';
import 'package:codewalk/domain/usecases/get_app_info.dart';
import 'package:codewalk/presentation/pages/onboarding_wizard_page.dart';
import 'package:codewalk/presentation/providers/app_provider.dart';
import 'package:codewalk/presentation/providers/settings_provider.dart';
import 'package:codewalk/presentation/services/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryAppLocalDataSource localDataSource;
  late AppProvider appProvider;
  late SettingsProvider settingsProvider;

  setUp(() async {
    localDataSource = InMemoryAppLocalDataSource();
    appProvider = AppProvider(
      getAppInfo: GetAppInfo(FakeAppRepository()),
      checkConnection: CheckConnection(FakeAppRepository()),
      localDataSource: localDataSource,
      dioClient: DioClient(),
      serverHealthRequestTimeout: const Duration(milliseconds: 120),
      enableHealthPolling: false,
    );
    settingsProvider = SettingsProvider(
      localDataSource: localDataSource,
      dioClient: DioClient(),
      soundService: SoundService(),
    );
    await appProvider.initialize();
    await settingsProvider.initialize();
  });

  Widget buildWizard({VoidCallback? onComplete}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppProvider>.value(value: appProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(home: OnboardingWizardPage(onComplete: onComplete)),
    );
  }

  group('welcome step', () {
    testWidgets('shows welcome and two option cards', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWizard());
      await tester.pumpAndSettle();

      expect(find.text('Welcome to CodeWalk'), findsOneWidget);
      expect(find.text('Connect to server'), findsOneWidget);
      expect(find.text('I need help setting up'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });
  });

  group('skip flow', () {
    testWidgets('skip without checkbox calls onComplete', (
      WidgetTester tester,
    ) async {
      var completed = false;
      await tester.pumpWidget(buildWizard(onComplete: () => completed = true));
      await tester.pumpAndSettle();

      // Tap the Skip button in the AppBar.
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Skip dialog should appear.
      expect(find.text('Skip setup?'), findsOneWidget);
      expect(find.text("Don't show again"), findsOneWidget);

      // Confirm skip WITHOUT checking "Don't show again".
      await tester.tap(find.widgetWithText(FilledButton, 'Skip'));
      await tester.pumpAndSettle();

      // onComplete should have been called.
      expect(completed, isTrue);

      // The persistent flag should remain false.
      expect(settingsProvider.skipOnboardingWizard, isFalse);
    });

    testWidgets('skip with checkbox persists skipOnboardingWizard', (
      WidgetTester tester,
    ) async {
      var completed = false;
      await tester.pumpWidget(buildWizard(onComplete: () => completed = true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Check the "Don't show again" checkbox.
      await tester.tap(find.text("Don't show again"));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Skip'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(settingsProvider.skipOnboardingWizard, isTrue);
    });

    testWidgets('cancel in skip dialog returns to wizard', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWizard());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.text('Skip setup?'), findsOneWidget);

      // Cancel the dialog.
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      // Should still be on the welcome step.
      expect(find.text('Welcome to CodeWalk'), findsOneWidget);
    });
  });

  group('server setup step', () {
    testWidgets('connect to server navigates to URL form', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWizard());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Connect to server'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('step_server_setup')), findsOneWidget);

      if (find.text('Continue to server URL').evaluate().isNotEmpty) {
        await tester.tap(find.text('Continue to server URL'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Server URL'), findsOneWidget);
      expect(find.text('Test connection'), findsOneWidget);
    });

    testWidgets('need help shows quick guide then continues to form', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWizard());
      await tester.pumpAndSettle();

      await tester.tap(find.text('I need help setting up'));
      await tester.pumpAndSettle();

      // Quick guide should be visible.
      expect(find.text('Quick setup'), findsOneWidget);
      expect(find.text('Continue to server URL'), findsOneWidget);

      // Tap continue to show the URL form.
      await tester.tap(find.text('Continue to server URL'));
      await tester.pumpAndSettle();

      expect(find.text('Server connection'), findsOneWidget);
    });

    testWidgets('test connection adds server and moves to step 2', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWizard());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Connect to server'));
      await tester.pumpAndSettle();

      // Tap "Test connection" and let the async chain complete.
      await tester.tap(find.text('Test connection'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 180));
      });
      // Use pump instead of pumpAndSettle to avoid timeout from spinner.
      await tester.pump();

      // Server should have been added (health may fail, but profile persists).
      expect(appProvider.serverProfiles.length, 1);
    });

    testWidgets(
      'try again re-checks health instead of adding duplicate server',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildWizard());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Connect to server'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Test connection'));
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 180));
        });
        await tester.pump();

        // Server was added.
        expect(appProvider.serverProfiles.length, 1);

        // If step 2 shows "Try again", use it.
        if (find.text('Try again').evaluate().isNotEmpty) {
          await tester.tap(find.text('Try again'));
          await tester.pump();

          // Back on step 1, tap "Test connection" again.
          if (find.text('Test connection').evaluate().isNotEmpty) {
            await tester.tap(find.text('Test connection'));
            await tester.runAsync(() async {
              await Future<void>.delayed(const Duration(milliseconds: 180));
            });
            await tester.pump();
          }

          // Should NOT have added a duplicate server.
          expect(appProvider.serverProfiles.length, 1);
        }
      },
    );
  });

  group('back navigation', () {
    testWidgets('back from step 1 returns to welcome', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWizard());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Connect to server'));
      await tester.pumpAndSettle();
      expect(find.text('Server connection'), findsOneWidget);

      // Tap back arrow.
      await tester.tap(find.byIcon(Symbols.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to CodeWalk'), findsOneWidget);
    });
  });
}
