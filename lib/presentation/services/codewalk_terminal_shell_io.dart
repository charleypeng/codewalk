import 'dart:io';

import 'codewalk_terminal_shell.dart';

CodewalkTerminalShellTarget resolveCodewalkTerminalShellTargetImpl({
  required String? workingDirectory,
}) {
  var normalizedDirectory = workingDirectory?.trim();
  if (normalizedDirectory == null || normalizedDirectory.isEmpty) {
    return const CodewalkTerminalShellTarget(
      executable: '',
      arguments: <String>[],
      workingDirectory: null,
      statusLabel: 'shell',
      errorMessage:
          'Open a project folder before starting the embedded terminal.',
    );
  }

  if (!Directory(normalizedDirectory).existsSync()) {
    if (Platform.isAndroid) {
      // Android terminals often receive a server-scoped project path that does
      // not exist inside the app sandbox. Falling back to a safe local cwd is
      // better than blocking terminal startup entirely.
      normalizedDirectory = '/';
    } else {
      return CodewalkTerminalShellTarget(
        executable: '',
        arguments: const <String>[],
        workingDirectory: normalizedDirectory,
        statusLabel: 'shell',
        errorMessage:
            'The current project folder is unavailable, so Terminal cannot start there yet.',
      );
    }
  }

  if (Platform.isWindows) {
    final commandShell = Platform.environment['COMSPEC']?.trim();
    if (commandShell != null && commandShell.isNotEmpty) {
      return CodewalkTerminalShellTarget(
        executable: commandShell,
        arguments: const <String>[],
        workingDirectory: normalizedDirectory,
        statusLabel: _shellLabel(commandShell),
      );
    }
    return CodewalkTerminalShellTarget(
      executable: 'powershell.exe',
      arguments: const <String>['-NoLogo'],
      workingDirectory: normalizedDirectory,
      statusLabel: 'PowerShell',
    );
  }

  final preferredShell = Platform.environment['SHELL']?.trim();
  if (preferredShell != null &&
      preferredShell.isNotEmpty &&
      File(preferredShell).existsSync()) {
    return CodewalkTerminalShellTarget(
      executable: preferredShell,
      arguments: const <String>[],
      workingDirectory: normalizedDirectory,
      statusLabel: _shellLabel(preferredShell),
    );
  }

  for (final candidate in const <String>[
    '/system/bin/sh',
    '/bin/bash',
    '/bin/zsh',
    '/bin/sh',
  ]) {
    if (File(candidate).existsSync()) {
      return CodewalkTerminalShellTarget(
        executable: candidate,
        arguments: const <String>[],
        workingDirectory: normalizedDirectory,
        statusLabel: _shellLabel(candidate),
      );
    }
  }

  return CodewalkTerminalShellTarget(
    executable: '',
    arguments: const <String>[],
    workingDirectory: normalizedDirectory,
    statusLabel: 'shell',
    errorMessage:
        'No supported shell was found for the embedded terminal on this platform.',
  );
}

String _shellLabel(String executable) {
  final normalized = executable.replaceAll('\\', '/');
  final segments = normalized.split('/');
  final last = segments.isEmpty ? executable : segments.last;
  if (last.trim().isEmpty) {
    return 'shell';
  }
  return last;
}
