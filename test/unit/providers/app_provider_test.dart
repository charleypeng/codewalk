import 'package:codewalk/core/errors/failures.dart';
import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/domain/usecases/check_connection.dart';
import 'package:codewalk/domain/usecases/get_app_info.dart';
import 'package:codewalk/presentation/providers/app_provider.dart';
import 'package:codewalk/presentation/services/local_opencode_server_runtime_types.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  group('AppProvider', () {
    late FakeAppRepository repository;
    late InMemoryAppLocalDataSource localDataSource;
    late FakeLocalOpencodeServerRuntime localServerRuntime;
    late AppProvider provider;

    setUp(() {
      repository = FakeAppRepository();
      localDataSource = InMemoryAppLocalDataSource();
      localServerRuntime = FakeLocalOpencodeServerRuntime();
      provider = AppProvider(
        getAppInfo: GetAppInfo(repository),
        checkConnection: CheckConnection(repository),
        localDataSource: localDataSource,
        dioClient: DioClient(),
        localServerRuntime: localServerRuntime,
        enableHealthPolling: false,
      );
    });

    test('getAppInfo sets loaded state on success', () async {
      await provider.getAppInfo();

      expect(provider.status, AppStatus.loaded);
      expect(provider.isConnected, isTrue);
      expect(provider.errorMessage, isEmpty);
      expect(provider.appInfo?.hostname, 'localhost');
    });

    test('getAppInfo sets error state on failure', () async {
      repository.appInfoResult = const Left(
        NetworkFailure('server unavailable'),
      );

      await provider.getAppInfo();

      expect(provider.status, AppStatus.error);
      expect(provider.isConnected, isFalse);
      expect(provider.errorMessage, 'server unavailable');
    });

    test(
      'updateServerConfig persists host and port in provider state',
      () async {
        await provider.initialize();
        final updated = await provider.updateServerConfig('10.0.0.10', 5050);

        expect(updated, isTrue);
        expect(provider.serverHost, '10.0.0.10');
        expect(provider.serverPort, 5050);
        expect(provider.serverUrl, 'http://10.0.0.10:5050');
      },
    );

    test(
      'initialize migrates legacy host/port into server profile list',
      () async {
        localDataSource.serverHost = '10.10.0.7';
        localDataSource.serverPort = 4010;
        localDataSource.basicAuthEnabled = true;
        localDataSource.basicAuthUsername = 'user';
        localDataSource.basicAuthPassword = 'pass';

        await provider.initialize();

        expect(provider.serverProfiles, hasLength(1));
        expect(provider.activeServerId, isNotNull);
        expect(provider.defaultServerId, provider.activeServerId);
        expect(provider.activeServer?.url, 'http://10.10.0.7:4010');
        expect(provider.activeServer?.basicAuthEnabled, isTrue);
        expect(localDataSource.serverProfilesJson, isNotNull);
      },
    );

    test(
      'initialize keeps empty server list when no legacy config exists',
      () async {
        await provider.initialize();

        expect(provider.serverProfiles, isEmpty);
        expect(provider.activeServerId, isNull);
        expect(provider.defaultServerId, isNull);
      },
    );

    test(
      'checkConnection skips remote call when no server is configured',
      () async {
        repository.checkConnectionResult = const Left(
          NetworkFailure('should not be used without server'),
        );

        await provider.initialize();
        await provider.checkConnection();

        expect(provider.isConnected, isFalse);
        expect(provider.errorMessage, isEmpty);
      },
    );

    test('addServerProfile rejects duplicates after normalization', () async {
      await provider.initialize();
      final created = await provider.addServerProfile(
        url: 'http://127.0.0.1:5009',
      );
      final duplicate = await provider.addServerProfile(url: '127.0.0.1:5009/');

      expect(created, isTrue);
      expect(duplicate, isFalse);
      expect(provider.errorMessage, 'A server with this URL already exists');
    });

    test('setActiveServer blocks unhealthy profiles', () async {
      await provider.initialize();
      await provider.addServerProfile(url: 'http://127.0.0.1:5001');
      await provider.addServerProfile(url: 'http://127.0.0.1:5002');
      final target = provider.serverProfiles
          .where((p) => p.url == 'http://127.0.0.1:5002')
          .first;
      provider.setHealthForTesting(target.id, ServerHealthStatus.unhealthy);

      final ok = await provider.setActiveServer(target.id);

      expect(ok, isFalse);
      expect(provider.errorMessage, 'Cannot activate an unhealthy server');
    });

    test('persists AI-generated-title toggle in server profiles', () async {
      await provider.initialize();
      final created = await provider.addServerProfile(
        url: 'http://127.0.0.1:5010',
        aiGeneratedTitlesEnabled: true,
      );

      expect(created, isTrue);
      final profile = provider.serverProfiles
          .where((item) => item.url == 'http://127.0.0.1:5010')
          .first;
      expect(profile.aiGeneratedTitlesEnabled, isTrue);

      final updated = await provider.updateServerProfile(
        id: profile.id,
        url: profile.url,
        label: profile.label,
        basicAuthEnabled: profile.basicAuthEnabled,
        basicAuthUsername: profile.basicAuthUsername,
        basicAuthPassword: profile.basicAuthPassword,
        aiGeneratedTitlesEnabled: false,
      );

      expect(updated, isTrue);
      final refreshed = provider.serverProfiles
          .where((item) => item.id == profile.id)
          .first;
      expect(refreshed.aiGeneratedTitlesEnabled, isFalse);
    });

    test(
      'startLocalServer creates and activates managed local profile',
      () async {
        localServerRuntime.supported = true;
        provider = AppProvider(
          getAppInfo: GetAppInfo(repository),
          checkConnection: CheckConnection(repository),
          localDataSource: localDataSource,
          dioClient: DioClient(),
          localServerRuntime: localServerRuntime,
          localServerHealthProbe: (_) async => ServerHealthStatus.healthy,
          enableHealthPolling: false,
        );

        await provider.initialize();
        final ok = await provider.startLocalServer();

        expect(ok, isTrue);
        expect(provider.localServerStatus, LocalServerRuntimeStatus.running);
        expect(provider.activeServer?.url, 'http://127.0.0.1:4096');
        expect(
          provider.serverProfiles
              .where((profile) => profile.url == 'http://127.0.0.1:4096')
              .isNotEmpty,
          isTrue,
        );
      },
    );

    test('stopLocalServer moves status back to stopped', () async {
      localServerRuntime.supported = true;
      provider = AppProvider(
        getAppInfo: GetAppInfo(repository),
        checkConnection: CheckConnection(repository),
        localDataSource: localDataSource,
        dioClient: DioClient(),
        localServerRuntime: localServerRuntime,
        localServerHealthProbe: (_) async => ServerHealthStatus.healthy,
        enableHealthPolling: false,
      );

      await provider.initialize();
      await provider.startLocalServer();
      final ok = await provider.stopLocalServer();

      expect(ok, isTrue);
      expect(provider.localServerStatus, LocalServerRuntimeStatus.stopped);
    });

    test('startLocalServer reports launch failures', () async {
      localServerRuntime = FakeLocalOpencodeServerRuntime(
        supported: true,
        startResult: const LocalOpencodeServerStartResult(
          ok: false,
          errorMessage: 'opencode command was not found',
        ),
      );
      provider = AppProvider(
        getAppInfo: GetAppInfo(repository),
        checkConnection: CheckConnection(repository),
        localDataSource: localDataSource,
        dioClient: DioClient(),
        localServerRuntime: localServerRuntime,
        enableHealthPolling: false,
      );

      await provider.initialize();
      final ok = await provider.startLocalServer();

      expect(ok, isFalse);
      expect(provider.localServerStatus, LocalServerRuntimeStatus.failed);
      expect(provider.errorMessage, 'opencode command was not found');
    });

    test('runLocalServerDiagnostics stores detected command path', () async {
      localServerRuntime.supported = true;
      localServerRuntime.diagnoseResult = const LocalOpencodeEnvironmentReport(
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
        recommendation: 'Use existing OpenCode',
      );

      await provider.initialize();
      await provider.runLocalServerDiagnostics();

      expect(provider.localEnvironmentReport, isNotNull);
      expect(provider.localServerCommandPath, '/tmp/opencode');
      expect(localDataSource.localOpencodeCommand, '/tmp/opencode');
    });

    test('installLocalServerRequirements persists installer command', () async {
      localServerRuntime.supported = true;
      localServerRuntime.installResult = const LocalOpencodeInstallResult(
        ok: true,
        commandPath: '/opt/codewalk/opencode',
      );
      localServerRuntime.diagnoseResult = const LocalOpencodeEnvironmentReport(
        supported: true,
        platform: 'linux',
        opencode: LocalToolStatus(
          available: true,
          path: '/opt/codewalk/opencode',
          version: '1.2.4',
        ),
        node: LocalToolStatus(available: true),
        npm: LocalToolStatus(available: true),
        bun: LocalToolStatus(available: true),
        wsl: LocalToolStatus(available: false),
        hasNetworkAccess: true,
        installDirectoryWritable: true,
        recommendation: 'Ready',
      );

      await provider.initialize();
      final ok = await provider.installLocalServerRequirements(
        LocalOpencodeInstallMethod.downloadBinary,
      );

      expect(ok, isTrue);
      expect(provider.localSetupInProgress, isFalse);
      expect(provider.localServerCommandPath, '/opt/codewalk/opencode');
      expect(localDataSource.localOpencodeCommand, '/opt/codewalk/opencode');
      expect(
        localServerRuntime.lastInstallMethod,
        LocalOpencodeInstallMethod.downloadBinary,
      );
    });
  });
}
