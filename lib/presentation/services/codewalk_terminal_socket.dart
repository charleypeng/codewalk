import 'codewalk_terminal_socket_stub.dart'
    if (dart.library.io) 'codewalk_terminal_socket_io.dart';

abstract class CodewalkTerminalSocketConnection {
  Stream<List<int>> get messages;

  Future<void> get done;

  void send(List<int> data);

  Future<void> close();
}

Future<CodewalkTerminalSocketConnection> openCodewalkTerminalSocket({
  required Uri url,
  Map<String, String>? headers,
}) {
  return openCodewalkTerminalSocketImpl(url: url, headers: headers);
}
