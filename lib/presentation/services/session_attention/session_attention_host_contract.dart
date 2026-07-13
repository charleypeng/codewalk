import 'package:flutter/foundation.dart';

import '../../../domain/entities/experience_settings.dart';

enum SessionAttentionHostKind {
  androidExternal,
  desktopWindow,
  iosInApp,
  unsupported,
}

@immutable
class SessionAttentionHostCapability {
  const SessionAttentionHostCapability({
    required this.kind,
    required this.supported,
    required this.permissionGranted,
    required this.running,
    required this.topmostSupported,
    this.stoppedByUser = false,
    this.permissionRevoked = false,
    this.explanation,
  });

  final SessionAttentionHostKind kind;
  final bool supported;
  final bool permissionGranted;
  final bool running;
  final bool topmostSupported;
  final bool stoppedByUser;
  final bool permissionRevoked;
  final String? explanation;
}

@immutable
class SessionAttentionHostActivationResult {
  const SessionAttentionHostActivationResult.success(this.capability)
    : activated = true,
      error = null;

  const SessionAttentionHostActivationResult.failure(
    this.capability,
    this.error,
  ) : activated = false;

  final bool activated;
  final SessionAttentionHostCapability capability;
  final String? error;
}

abstract interface class SessionAttentionHostService {
  Future<SessionAttentionHostCapability> capability();

  Future<SessionAttentionHostActivationResult> activate(
    SessionAttentionPresentation presentation,
  );

  Future<void> openSystemSettings();

  Future<void> stop();
}

class UnsupportedSessionAttentionHostService
    implements SessionAttentionHostService {
  const UnsupportedSessionAttentionHostService();

  static const capabilityValue = SessionAttentionHostCapability(
    kind: SessionAttentionHostKind.unsupported,
    supported: false,
    permissionGranted: false,
    running: false,
    topmostSupported: false,
    explanation: 'Session attention surfaces are unavailable on this platform.',
  );

  @override
  Future<SessionAttentionHostCapability> capability() async => capabilityValue;

  @override
  Future<SessionAttentionHostActivationResult> activate(
    SessionAttentionPresentation presentation,
  ) async => const SessionAttentionHostActivationResult.failure(
    capabilityValue,
    'Session attention surfaces are unavailable on this platform.',
  );

  @override
  Future<void> openSystemSettings() async {}

  @override
  Future<void> stop() async {}
}
