import 'edge_tts_websocket_stub.dart'
    if (dart.library.io) 'edge_tts_websocket_io.dart';

typedef EdgeTtsWebSocketConnector =
    EdgeTtsWebSocketConnection Function(Uri uri);

abstract class EdgeTtsWebSocketConnection {
  Future<void> get ready;
  Stream<dynamic> get stream;
  void sendText(String data);
  Future<void> close();
}

EdgeTtsWebSocketConnection openEdgeTtsWebSocket(Uri uri) {
  return openEdgeTtsWebSocketImpl(uri);
}
