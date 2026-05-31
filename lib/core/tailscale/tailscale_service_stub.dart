import 'package:http/http.dart' as http;

import 'tailscale_state.dart';

class TailscaleService {
  TailscaleService();

  TailscaleState get state => const TailscaleState(
    nodeState: TailscaleNodeState.unsupported,
    message: 'Tailscale is not supported on this platform.',
  );

  Stream<TailscaleState> get stateChanges =>
      Stream<TailscaleState>.value(state);

  bool get hasClient => false;

  http.Client get httpClient => throw UnsupportedError(
    'Tailscale transport is not supported on this platform.',
  );

  Future<TailscaleState> upForProfile({
    required String profileId,
    required String profileLabel,
  }) async => state;

  Future<void> down() async {}
}
