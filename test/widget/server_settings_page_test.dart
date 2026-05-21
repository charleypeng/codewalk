import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/domain/usecases/check_connection.dart';
import 'package:codewalk/domain/usecases/get_app_info.dart';
import 'package:codewalk/presentation/pages/server_settings_page.dart';
import 'package:codewalk/presentation/providers/app_provider.dart';
import 'package:codewalk/presentation/services/local_opencode_server_runtime_types.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../support/fakes.dart';
import '../support/pump_localized_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryAppLocalDataSource localDataSource;
  late AppProvider appProvider;

  setUp(() async {
    localDataSource = InMemoryAppLocalDataSource();
    appProvider = AppProvider(
      getAppInfo: GetAppInfo(FakeAppRepository()),
      checkConnection: CheckConnection(FakeAppRepository()),
      localDataSource: localDataSource,
      dioClient: DioClient(),
      enableHealthPolling: false,
    );
    await appProvider.initialize();
    await appProvider.addServerProfile(
      url: 'http://127.0.0.1:4101',
      label: 'Alpha',
      setAsActive: true,
    );
    await appProvider.addServerProfile(
      url: 'http://127.0.0.1:4102',
      label: 'Beta',
    );
    final alpha = appProvider.serverProfiles
        .where((p) => p.displayName == 'Alpha')
        .first;
    final beta = appProvider.serverProfiles
        .where((p) => p.displayName == 'Beta')
        .first;
    appProvider.setHealthForTesting(alpha.id, ServerHealthStatus.healthy);
    appProvider.setHealthForTesting(beta.id, ServerHealthStatus.unhealthy);
  });

  testWidgets('renders server list with active/default metadata', (
    WidgetTester tester,
  ) async {
    await _setLargeSurface(tester);
    await tester.pumpWidget(_testApp(appProvider));
    await tester.pumpAndSettle();

    expect(find.text('Servers'), findsOneWidget);
    expect(find.text('Alpha'), findsWidgets);
    expect(find.text('Active'), findsWidgets);
    expect(find.text('Default'), findsWidgets);

    await _scrollToServer(tester, 'Beta');
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('blocks activating unhealthy server from action menu', (
    WidgetTester tester,
  ) async {
    await _setLargeSurface(tester);
    await tester.pumpWidget(_testApp(appProvider));
    await tester.pumpAndSettle();
    await _scrollToServer(tester, 'Beta');

    final betaTile = find.ancestor(
      of: find.text('Beta'),
      matching: find.byType(ListTile),
    );
    final betaMenu = find.descendant(
      of: betaTile,
      matching: find.byIcon(Symbols.more_vert),
    );
    expect(betaMenu, findsOneWidget);

    await tester.tap(betaMenu);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Set Active'));
    await tester.pumpAndSettle();

    expect(find.text('Cannot activate an unhealthy server'), findsOneWidget);
  });

  testWidgets('local server card opens separate setup debug page', (
    WidgetTester tester,
  ) async {
    await _setLargeSurface(tester);

    final localServerRuntime = FakeLocalOpencodeServerRuntime(
      supported: true,
      diagnoseResult: const LocalOpencodeEnvironmentReport(
        supported: true,
        platform: 'linux',
        opencode: LocalToolStatus(available: true, path: '/tmp/opencode'),
        node: LocalToolStatus(available: true),
        npm: LocalToolStatus(available: true),
        bun: LocalToolStatus(available: true),
        wsl: LocalToolStatus(available: false),
        hasNetworkAccess: true,
        installDirectoryWritable: true,
        recommendation: 'Ready',
      ),
    );
    final supportedProvider = AppProvider(
      getAppInfo: GetAppInfo(FakeAppRepository()),
      checkConnection: CheckConnection(FakeAppRepository()),
      localDataSource: InMemoryAppLocalDataSource(),
      dioClient: DioClient(),
      localServerRuntime: localServerRuntime,
      enableHealthPolling: false,
    );
    await supportedProvider.initialize();
    await tester.pumpWidget(_testApp(supportedProvider));
    await tester.pumpAndSettle();

    expect(find.text('Setup Debug'), findsOneWidget);

    await tester.tap(find.text('Setup Debug'));
    await tester.pumpAndSettle();

    expect(find.text('OpenCode Setup Debug'), findsOneWidget);
  });

  testWidgets(
    'add server opens unified wizard and preserves remote setup form',
    (WidgetTester tester) async {
      await _setLargeSurface(tester);
      await tester.pumpWidget(_testApp(appProvider));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Server'));
      await tester.pumpAndSettle();

      expect(find.text('Server connection'), findsOneWidget);
      expect(find.text('Choose another path'), findsOneWidget);
      expect(find.text('AI generated titles'), findsOneWidget);

      final urlField = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      final expectedDefaultUrl = defaultTargetPlatform == TargetPlatform.android
          ? 'http://10.0.2.2:4096'
          : 'http://127.0.0.1:4096';
      expect(urlField.controller?.text, expectedDefaultUrl);

      await tester.tap(find.text('Choose another path'));
      await tester.pumpAndSettle();

      expect(find.text('Connect to a running server'), findsOneWidget);
      expect(find.text('Show me the setup steps'), findsOneWidget);
      expect(find.text('Let CodeWalk set it up locally'), findsOneWidget);

      await tester.ensureVisible(find.text('Show me the setup steps'));
      await tester.tap(find.text('Show me the setup steps'));
      await tester.pumpAndSettle();

      expect(find.text('Quick setup'), findsOneWidget);
      expect(
        find.textContaining('opencode serve --hostname 0.0.0.0 --port 4096'),
        findsOneWidget,
      );
      expect(find.text('Protect access with password'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.byIcon(Symbols.content_copy_rounded), findsOneWidget);
      expect(find.text('1. Install OpenCode CLI.'), findsOneWidget);
      expect(find.textContaining('opencode.ai/docs/server'), findsNothing);
      expect(find.textContaining('Use this URL in the app'), findsNothing);
      expect(find.text('4. Verify with /global/health or /doc.'), findsNothing);

      await tester.tap(find.text('Protect access with password'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'mypass123');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('OPENCODE_SERVER_PASSWORD=\'mypass123\''),
        findsOneWidget,
      );

      await tester.tap(find.text('Continue to server URL'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Clear'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear'));
      await tester.pumpAndSettle();

      final clearedUrlField = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(clearedUrlField.controller?.text, isEmpty);
      expect(find.text('AI generated titles'), findsOneWidget);
    },
  );
}

Widget _testApp(AppProvider appProvider) {
  return ChangeNotifierProvider<AppProvider>.value(
    value: appProvider,
    child: localizedMaterialApp(home: const ServerSettingsPage()),
  );
}

Future<void> _setLargeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1200, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _scrollToServer(WidgetTester tester, String label) async {
  final target = find.text(label);
  if (target.evaluate().isNotEmpty) {
    return;
  }

  final scrollable = find.byType(Scrollable).last;
  await tester.scrollUntilVisible(target, 200, scrollable: scrollable);
  await tester.pumpAndSettle();
}
