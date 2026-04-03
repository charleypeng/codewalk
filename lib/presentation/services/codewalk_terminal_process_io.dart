import 'dart:convert';

import 'package:flutter_pty/flutter_pty.dart';

import 'codewalk_terminal_process.dart';

const bool codewalkTerminalProcessSupported = true;

CodewalkTerminalProcess createCodewalkTerminalProcess({
  required String executable,
  required List<String> arguments,
}) {
  return _FlutterPtyCodewalkTerminalProcess(
    Pty.start(executable, arguments: arguments),
  );
}

class _FlutterPtyCodewalkTerminalProcess implements CodewalkTerminalProcess {
  _FlutterPtyCodewalkTerminalProcess(this._pty);

  final Pty _pty;

  @override
  Stream<String> get output => utf8.decoder.bind(_pty.output);

  @override
  Future<int> get exitCode => _pty.exitCode;

  @override
  bool kill() => _pty.kill();

  @override
  void resize(int rows, int cols) {
    _pty.resize(rows, cols);
  }

  @override
  void write(String data) {
    _pty.write(utf8.encode(data));
  }
}
