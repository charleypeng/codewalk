import 'codewalk_terminal_process.dart';

const bool codewalkTerminalProcessSupported = false;

CodewalkTerminalProcess createCodewalkTerminalProcess({
  required String executable,
  required List<String> arguments,
  Map<String, String>? environment,
}) {
  throw UnsupportedError('Native terminal processes are not available here.');
}
