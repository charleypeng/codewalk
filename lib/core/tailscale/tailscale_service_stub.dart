import 'package:http/http.dart' as http;

import 'tailscale_peer.dart';
import 'tailscale_state.dart';

class TailscaleService {
  TailscaleService();

  TailscaleState get state => const TailscaleState(
        nodeState: TailscaleNodeState.unsupported,
        message: 'Tailscale is not supported on this platform.',
      );

  List<TailscalePeer> get peers => const [];

  Stream<TailscaleState> get stateChanges =>
      Stream<TailscaleState>.value(state);

  Stream<List<TailscalePeer>> get peerChanges =>
      Stream<List<TailscalePeer>>.value(const []);

  bool get hasClient => false;

  http.Client get httpClient => throw UnsupportedError(
        'Tailscale transport is not supported on this platform.',
      );

  Future<TailscaleState> upForProfile({
    required String profileId,
    required String profileLabel,
  }) async =>
      state;

  Future<void> down() async {}

  Future<List<TailscalePeer>> nodes() async => const [];
}
