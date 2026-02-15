import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/domain/usecases/check_connection.dart';
import 'package:codewalk/domain/usecases/get_app_info.dart';
import 'package:codewalk/presentation/pages/server_settings_page.dart';
import 'package:codewalk/presentation/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../support/fakes.dart';

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
    await tester.pumpWidget(_testApp(appProvider));
    await tester.pumpAndSettle();
    await _scrollToServer(tester, 'Beta');

    final betaTile = find.ancestor(
      of: find.text('Beta'),
      matching: find.byType(ListTile),
    );
    final betaMenu = find.descendant(
      of: betaTile,
      matching: find.byIcon(Icons.more_vert),
    );
    expect(betaMenu, findsOneWidget);

    await tester.tap(betaMenu);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Set Active'));
    await tester.pumpAndSettle();

    expect(find.text('Cannot activate an unhealthy server'), findsOneWidget);
  });

  testWidgets('add/edit dialog exposes AI generated title privacy toggle', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_testApp(appProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Server'));
    await tester.pumpAndSettle();

    expect(find.text('Quick setup'), findsOneWidget);
    expect(
      find.textContaining('opencode serve --hostname 127.0.0.1 --port 4096'),
      findsOneWidget,
    );
    expect(find.text('Copy'), findsOneWidget);
    expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    expect(find.text('1. Install OpenCode CLI.'), findsOneWidget);
    expect(find.textContaining('opencode.ai/docs/server'), findsNothing);
    expect(find.textContaining('Use this URL in the app'), findsNothing);
    expect(find.text('4. Verify with /global/health or /doc.'), findsNothing);

    final urlField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(urlField.controller?.text, 'http://127.0.0.1:4096');

    expect(find.byTooltip('Clear server URL'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear server URL'));
    await tester.pumpAndSettle();

    final clearedUrlField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(clearedUrlField.controller?.text, isEmpty);
    expect(find.text('Enable AI generated titles'), findsOneWidget);
    expect(
      find.textContaining('This is a free service powered by https://ch.at'),
      findsOneWidget,
    );
  });
}

Widget _testApp(AppProvider appProvider) {
  return ChangeNotifierProvider<AppProvider>.value(
    value: appProvider,
    child: const MaterialApp(home: ServerSettingsPage()),
  );
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
