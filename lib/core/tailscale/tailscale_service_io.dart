import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:tailscale/tailscale.dart' as ts;

import '../logging/app_logger.dart';
import 'tailscale_state.dart';

class TailscaleService {
  TailscaleService({ts.TailscaleClient? client})
    : _client = client ?? ts.Tailscale.instance;

  final ts.TailscaleClient _client;
  final StreamController<TailscaleState> _stateController =
      StreamController<TailscaleState>.broadcast();

  StreamSubscription<ts.NodeState>? _nodeStateSubscription;
  String? _activeProfileId;
  TailscaleState _state = const TailscaleState.disconnected();

  TailscaleState get state => _state;

  Stream<TailscaleState> get stateChanges => _stateController.stream;

  bool get hasClient => _state.isConnected;

  http.Client get httpClient => _client.http.client;

  Future<TailscaleState> upForProfile({
    required String profileId,
    required String profileLabel,
  }) async {
    if (Platform.isWindows) {
      return _publish(
        const TailscaleState(
          nodeState: TailscaleNodeState.unsupported,
          message: 'Tailscale is not supported on Windows.',
        ),
      );
    }

    if (_activeProfileId != null && _activeProfileId != profileId) {
      await down();
    }

    _activeProfileId = profileId;
    _publish(const TailscaleState(nodeState: TailscaleNodeState.connecting));

    final stateDir = await _stateDirForProfile(profileId);
    ts.Tailscale.init(
      stateDir: stateDir.path,
      logLevel: kReleaseMode
          ? ts.TailscaleLogLevel.error
          : ts.TailscaleLogLevel.info,
    );
    _listenToNodeState();

    try {
      final status = await _client.up(
        hostname: _hostnameForProfile(profileLabel),
        timeout: const Duration(seconds: 30),
      );
      return _publish(_stateFromStatus(status));
    } catch (error, stackTrace) {
      AppLogger.warn(
        '[Tailscale] Failed to start node for profile $profileId',
        error: error,
        stackTrace: stackTrace,
      );
      return _publish(
        TailscaleState(
          nodeState: TailscaleNodeState.error,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> down() async {
    await _nodeStateSubscription?.cancel();
    _nodeStateSubscription = null;
    try {
      await _client.down();
    } catch (error, stackTrace) {
      AppLogger.warn(
        '[Tailscale] Failed to stop node',
        error: error,
        stackTrace: stackTrace,
      );
    }
    _activeProfileId = null;
    _publish(const TailscaleState.disconnected());
  }

  void _listenToNodeState() {
    _nodeStateSubscription ??= _client.onStateChange.listen((state) {
      _publish(_stateFromNodeState(state));
    });
  }

  Future<Directory> _stateDirForProfile(String profileId) async {
    final root = await getApplicationSupportDirectory();
    final safeProfileId = profileId.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    final dir = Directory('${root.path}/tailscale_profiles/$safeProfileId');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _hostnameForProfile(String profileLabel) {
    final normalized = profileLabel
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return normalized.isEmpty ? 'codewalk' : 'codewalk-$normalized';
  }

  TailscaleState _stateFromStatus(ts.TailscaleStatus status) {
    return switch (status.state) {
      ts.NodeState.running => const TailscaleState(
        nodeState: TailscaleNodeState.connected,
      ),
      ts.NodeState.needsLogin => TailscaleState(
        nodeState: TailscaleNodeState.needsLogin,
        authUrl: status.authUrl,
      ),
      ts.NodeState.needsMachineAuth => const TailscaleState(
        nodeState: TailscaleNodeState.needsMachineAuth,
        message: 'This Tailscale node is waiting for admin approval.',
      ),
      ts.NodeState.starting => const TailscaleState(
        nodeState: TailscaleNodeState.connecting,
      ),
      ts.NodeState.noState ||
      ts.NodeState.stopped => const TailscaleState.disconnected(),
    };
  }

  TailscaleState _stateFromNodeState(ts.NodeState state) {
    return switch (state) {
      ts.NodeState.running => const TailscaleState(
        nodeState: TailscaleNodeState.connected,
      ),
      ts.NodeState.needsLogin => const TailscaleState(
        nodeState: TailscaleNodeState.needsLogin,
      ),
      ts.NodeState.needsMachineAuth => const TailscaleState(
        nodeState: TailscaleNodeState.needsMachineAuth,
        message: 'This Tailscale node is waiting for admin approval.',
      ),
      ts.NodeState.starting => const TailscaleState(
        nodeState: TailscaleNodeState.connecting,
      ),
      ts.NodeState.noState ||
      ts.NodeState.stopped => const TailscaleState.disconnected(),
    };
  }

  TailscaleState _publish(TailscaleState next) {
    _state = next;
    _stateController.add(next);
    return next;
  }
}
