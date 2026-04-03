import 'codewalk_terminal_shell.dart';

CodewalkTerminalShellTarget resolveCodewalkTerminalShellTargetImpl({
  required String? workingDirectory,
}) {
  return const CodewalkTerminalShellTarget(
    executable: '',
    arguments: <String>[],
    workingDirectory: null,
    statusLabel: 'shell',
    errorMessage: 'Embedded terminal is available on desktop only right now.',
  );
}
