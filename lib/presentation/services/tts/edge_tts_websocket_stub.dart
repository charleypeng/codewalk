import 'package:web_socket_channel/web_socket_channel.dart';

import 'edge_tts_websocket.dart';

EdgeTtsWebSocketConnection openEdgeTtsWebSocketImpl(Uri uri) {
  return _WebSocketChannelEdgeTtsConnection(WebSocketChannel.connect(uri));
}

class _WebSocketChannelEdgeTtsConnection implements EdgeTtsWebSocketConnection {
  _WebSocketChannelEdgeTtsConnection(this._channel);

  final WebSocketChannel _channel;
  bool _closed = false;

  @override
  Future<void> get ready => _channel.ready;

  @override
  Stream<dynamic> get stream => _channel.stream;

  @override
  void sendText(String data) {
    _channel.sink.add(data);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _channel.sink.close();
  }
}
