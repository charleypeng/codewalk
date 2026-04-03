import 'codewalk_terminal_shell_stub.dart'
    if (dart.library.io) 'codewalk_terminal_shell_io.dart';

CodewalkTerminalShellTarget resolveCodewalkTerminalShellTarget({
  required String? workingDirectory,
}) {
  return resolveCodewalkTerminalShellTargetImpl(
    workingDirectory: workingDirectory,
  );
}

class CodewalkTerminalShellTarget {
  const CodewalkTerminalShellTarget({
    required this.executable,
    required this.arguments,
    required this.workingDirectory,
    required this.statusLabel,
    this.environment,
    this.errorMessage,
  });

  final String executable;
  final List<String> arguments;
  final String? workingDirectory;
  final String statusLabel;
  final Map<String, String>? environment;
  final String? errorMessage;

  bool get isError => errorMessage != null;
}
