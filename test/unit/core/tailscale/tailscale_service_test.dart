import 'dart:async';
import 'dart:io';

import 'package:codewalk/core/tailscale/tailscale_service_io.dart';
import 'package:codewalk/core/tailscale/tailscale_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailscale/tailscale.dart' as ts;

class _FakeTailscaleClient implements ts.TailscaleClient {
  _FakeTailscaleClient({required this.statusResponse, required this.upError});

  final ts.TailscaleStatus statusResponse;
  final Object upError;
  final StreamController<ts.NodeState> stateController =
      StreamController<ts.NodeState>.broadcast();
  final StreamController<List<ts.TailscaleNode>> nodeController =
      StreamController<List<ts.TailscaleNode>>.broadcast();
  final StreamController<ts.TailscaleRuntimeError> errorController =
      StreamController<ts.TailscaleRuntimeError>.broadcast();

  @override
  Stream<ts.NodeState> get onStateChange => stateController.stream;

  @override
  Stream<List<ts.TailscaleNode>> get onNodeChanges => nodeController.stream;

  @override
  Stream<ts.TailscaleRuntimeError> get onError => errorController.stream;

  @override
  Future<ts.TailscaleStatus> up({
    String hostname = '',
    String? authKey,
    bool ephemeral = false,
    Uri? controlUrl,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    throw upError;
  }

  @override
  Future<ts.TailscaleStatus> status() async => statusResponse;

  Future<void> close() async {
    await stateController.close();
    await nodeController.close();
    await errorController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync(
      'codewalk_tailscale_service_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          if (call.method == 'getApplicationSupportDirectory') {
            return tempDir.path;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('TailscaleService', () {
    test(
      'publishes connected when up fails but status is already running',
      () async {
        final client = _FakeTailscaleClient(
          upError: TimeoutException('slow start'),
          statusResponse: const ts.TailscaleStatus(
            state: ts.NodeState.running,
            tailscaleIPs: [],
            health: [],
          ),
        );
        addTearDown(client.close);
        final service = TailscaleService(client: client);

        final state = await service.upForProfile(
          profileId: 'work profile',
          profileLabel: 'Work',
        );

        expect(state.nodeState, TailscaleNodeState.connected);
        expect(service.state.nodeState, TailscaleNodeState.connected);
      },
      skip: Platform.isWindows ? 'Tailscale is unsupported on Windows.' : false,
    );
  });
}
