import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/domain/usecases/check_connection.dart';
import 'package:codewalk/domain/usecases/get_app_info.dart';
import 'package:codewalk/presentation/pages/opencode_setup_debug_page.dart';
import 'package:codewalk/presentation/providers/app_provider.dart';
import 'package:codewalk/presentation/services/local_opencode_server_runtime_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders setup debug details and clears captured data', (
    WidgetTester tester,
  ) async {
    final localDataSource = InMemoryAppLocalDataSource();
    final localServerRuntime = FakeLocalOpencodeServerRuntime(
      supported: true,
      diagnoseResult: const LocalOpencodeEnvironmentReport(
        supported: true,
        platform: 'linux',
        opencode: LocalToolStatus(
          available: true,
          path: '/tmp/opencode',
          version: '1.2.4',
        ),
        node: LocalToolStatus(available: true),
        npm: LocalToolStatus(available: true),
        bun: LocalToolStatus(available: true),
        wsl: LocalToolStatus(available: false),
        hasNetworkAccess: true,
        installDirectoryWritable: true,
        recommendation: 'Use Existing OpenCode',
      ),
    );
    final appProvider = AppProvider(
      getAppInfo: GetAppInfo(FakeAppRepository()),
      checkConnection: CheckConnection(FakeAppRepository()),
      localDataSource: localDataSource,
      dioClient: DioClient(),
      localServerRuntime: localServerRuntime,
      enableHealthPolling: false,
    );
    await appProvider.initialize();
    await appProvider.runLocalServerDiagnostics();
    appProvider.recordSetupDebugEvent(
      source: 'Manual connection',
      message: 'Authorization: Bearer secret-token password=hunter2',
      severity: SetupDebugSeverity.error,
    );
    localServerRuntime.emitStdout('token=hidden-value');

    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: appProvider,
        child: const MaterialApp(home: OpenCodeSetupDebugPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('OpenCode Setup Debug'), findsOneWidget);
    expect(find.text('Environment diagnostics'), findsOneWidget);
    expect(find.textContaining('Authorization:'), findsOneWidget);
    expect(find.textContaining('hunter2'), findsNothing);
    expect(find.textContaining('secret-token'), findsNothing);
    expect(find.textContaining('hidden-value'), findsNothing);

    await tester.tap(find.byTooltip('Clear setup debug'));
    await tester.pumpAndSettle();

    expect(find.text('Timeline'), findsNothing);
  });
}
