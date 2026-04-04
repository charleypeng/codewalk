import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'codewalk_terminal_socket.dart';

Future<CodewalkTerminalSocketConnection> openCodewalkTerminalSocketImpl({
  required Uri url,
  Map<String, String>? headers,
}) async {
  final socket = await WebSocket.connect(url.toString(), headers: headers);
  return _IoCodewalkTerminalSocketConnection(socket);
}

class _IoCodewalkTerminalSocketConnection
    implements CodewalkTerminalSocketConnection {
  _IoCodewalkTerminalSocketConnection(this._socket);

  final WebSocket _socket;

  @override
  Stream<List<int>> get messages => _socket.map((event) {
    if (event is String) {
      return utf8.encode(event);
    }
    if (event is List<int>) {
      return List<int>.from(event);
    }
    throw UnsupportedError('Unsupported terminal websocket frame type');
  });

  @override
  Future<void> get done => _socket.done;

  @override
  void send(List<int> data) {
    _socket.add(data);
  }

  @override
  Future<void> close() async {
    await _socket.close();
  }
}
