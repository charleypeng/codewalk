import 'dart:async';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/experience_settings.dart';
import 'session_attention_host_contract.dart';
import 'session_attention_host_protocol.dart';
import 'session_overlay_entrypoint.dart';

SessionAttentionHostService createSessionAttentionHostService() {
  return _IoSessionAttentionHostService();
}

class _IoSessionAttentionHostService
    implements
        SessionAttentionHostService,
        SessionAttentionSnapshotHostService {
  static const _androidChannel = MethodChannel('codewalk/session_overlay_host');

  WindowController? _desktopWindow;
  bool _desktopHostActive = false;
  bool _iosHostActive = false;

  bool get _isDesktop => switch (defaultTargetPlatform) {
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => true,
    _ => false,
  };

  @override
  Future<SessionAttentionHostCapability> capability() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final stopState =
          await _invokeAndroid<Map<Object?, Object?>>(
            'consumeOverlayStopState',
          ) ??
          const <Object?, Object?>{};
      final permissionGranted =
          await _invokeAndroid<bool>('canDrawOverlays') ?? false;
      final running =
          await _invokeAndroid<bool>('isOverlayServiceRunning') ?? false;
      return SessionAttentionHostCapability(
        kind: SessionAttentionHostKind.androidExternal,
        supported: true,
        permissionGranted: permissionGranted,
        running: running,
        topmostSupported: true,
        stoppedByUser: stopState['stoppedByUser'] == true,
        permissionRevoked: stopState['permissionRevoked'] == true,
        explanation: permissionGranted
            ? null
            : 'Display-over-other-apps permission is required.',
      );
    }
    if (_isDesktop) {
      final wayland =
          defaultTargetPlatform == TargetPlatform.linux &&
          (Platform.environment['WAYLAND_DISPLAY']?.isNotEmpty ?? false);
      return SessionAttentionHostCapability(
        kind: SessionAttentionHostKind.desktopWindow,
        supported: true,
        permissionGranted: true,
        running: _desktopHostActive,
        topmostSupported: !wayland,
        explanation: wayland
            ? 'Always-on-top depends on the active Wayland compositor.'
            : null,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return SessionAttentionHostCapability(
        kind: SessionAttentionHostKind.iosInApp,
        supported: true,
        permissionGranted: true,
        running: _iosHostActive,
        topmostSupported: false,
        explanation: 'Session attention is available only inside CodeWalk.',
      );
    }
    return const SessionAttentionHostCapability(
      kind: SessionAttentionHostKind.unsupported,
      supported: false,
      permissionGranted: false,
      running: false,
      topmostSupported: false,
      explanation:
          'Session attention surfaces are unavailable on this platform.',
    );
  }

  @override
  Future<SessionAttentionHostActivationResult> activate(
    SessionAttentionPresentation presentation,
  ) async {
    if (presentation == SessionAttentionPresentation.off) {
      await stop();
      return SessionAttentionHostActivationResult.success(await capability());
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final current = await capability();
      if (!current.permissionGranted) {
        await openSystemSettings();
        return SessionAttentionHostActivationResult.failure(
          current,
          'Grant display-over-other-apps permission, then try again.',
        );
      }
      final started =
          await _invokeAndroid<bool>('startOverlayService') ?? false;
      var next = await capability();
      for (
        var attempt = 0;
        started && !next.running && attempt < 10;
        attempt++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        next = await capability();
      }
      return started && next.running
          ? SessionAttentionHostActivationResult.success(next)
          : SessionAttentionHostActivationResult.failure(
              next,
              'The Android session attention service could not start.',
            );
    }
    if (_isDesktop) {
      final controller =
          await _findDesktopWindow() ??
          await WindowController.create(
            const WindowConfiguration(
              arguments: sessionAttentionDesktopChildRole,
            ),
          );
      _desktopWindow = controller;
      await controller.show();
      _desktopHostActive = true;
      return SessionAttentionHostActivationResult.success(await capability());
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _iosHostActive = true;
      return SessionAttentionHostActivationResult.success(await capability());
    }
    final current = await capability();
    return SessionAttentionHostActivationResult.failure(
      current,
      current.explanation,
    );
  }

  @override
  Future<void> openSystemSettings() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _invokeAndroid<void>('requestOverlayPermission');
    }
  }

  @override
  Future<void> stop() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _invokeAndroid<void>('stopOverlayService');
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _iosHostActive = false;
      return;
    }
    final controller = await _findDesktopWindow();
    await controller?.hide();
    _desktopHostActive = false;
  }

  @override
  Future<void> publishSnapshot(SessionAttentionHostSnapshot snapshot) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _invokeAndroid<void>('updateOverlaySnapshot', snapshot.toJson());
      return;
    }
    if (_isDesktop) {
      final controller = await _findDesktopWindow();
      await controller?.invokeMethod(
        'sessionAttention.applySnapshot',
        snapshot.toJson(),
      );
    }
  }

  Future<WindowController?> _findDesktopWindow() async {
    if (!_isDesktop) {
      return null;
    }
    final cached = _desktopWindow;
    if (cached != null) {
      return cached;
    }
    final windows = await WindowController.getAll();
    for (final window in windows) {
      if (window.arguments == sessionAttentionDesktopChildRole) {
        _desktopWindow = window;
        return window;
      }
    }
    return null;
  }

  Future<T?> _invokeAndroid<T>(String method, [Object? arguments]) {
    return _androidChannel
        .invokeMethod<T>(method, arguments)
        .timeout(const Duration(seconds: 2));
  }
}
