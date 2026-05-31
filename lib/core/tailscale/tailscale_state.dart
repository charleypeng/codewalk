import 'package:equatable/equatable.dart';

enum TailscaleNodeState {
  disconnected,
  connecting,
  connected,
  needsLogin,
  needsMachineAuth,
  error,
  unsupported,
}

class TailscaleState extends Equatable {
  const TailscaleState({required this.nodeState, this.authUrl, this.message});

  const TailscaleState.disconnected()
    : nodeState = TailscaleNodeState.disconnected,
      authUrl = null,
      message = null;

  final TailscaleNodeState nodeState;
  final Uri? authUrl;
  final String? message;

  bool get isConnected => nodeState == TailscaleNodeState.connected;
  bool get requiresUserLogin => nodeState == TailscaleNodeState.needsLogin;

  @override
  List<Object?> get props => <Object?>[nodeState, authUrl, message];
}
