import 'codewalk_terminal_process_stub.dart'
    if (dart.library.io) 'codewalk_terminal_process_io.dart';

abstract class CodewalkTerminalProcess {
  Stream<String> get output;
  Future<int> get exitCode;

  void write(String data);
  void resize(int rows, int cols);
  bool kill();
}

bool get supportsCodewalkTerminalProcess => codewalkTerminalProcessSupported;

CodewalkTerminalProcess startCodewalkTerminalProcess({
  required String executable,
  required List<String> arguments,
  String? workingDirectory,
  Map<String, String>? environment,
}) {
  return createCodewalkTerminalProcess(
    executable: executable,
    arguments: arguments,
    workingDirectory: workingDirectory,
    environment: environment,
  );
}
