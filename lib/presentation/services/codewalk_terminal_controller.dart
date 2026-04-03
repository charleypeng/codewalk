import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:xterm/xterm.dart';

import 'codewalk_terminal_process.dart';
import 'codewalk_terminal_shell.dart';

enum CodewalkTerminalState {
  idle,
  unavailable,
  starting,
  running,
  exited,
  failed,
}

class CodewalkTerminalController extends ChangeNotifier {
  CodewalkTerminalController() {
    _terminal = _createTerminal();
  }

  late Terminal _terminal;
  CodewalkTerminalProcess? _process;
  StreamSubscription<String>? _outputSubscription;
  Future<void>? _exitWatcher;
  CodewalkTerminalState _state = CodewalkTerminalState.idle;
  String _statusMessage =
      'Open Terminal to start a shell in the active project folder.';
  String? _targetKey;
  int _processToken = 0;
  bool _disposed = false;

  Terminal get terminal => _terminal;
  CodewalkTerminalState get state => _state;
  String get statusMessage => _statusMessage;

  bool get supportsDesktopAttach {
    if (kIsWeb || !supportsCodewalkTerminalProcess) {
      return false;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      _ => false,
    };
  }

  Future<void> startShell({
    required String? workingDirectory,
    bool force = false,
  }) async {
    if (!supportsDesktopAttach) {
      await _resetToUnavailable(
        'Embedded terminal is available on desktop only right now.',
      );
      return;
    }

    final shellTarget = resolveCodewalkTerminalShellTarget(
      workingDirectory: workingDirectory,
    );
    if (shellTarget.isError) {
      await _resetToUnavailable(shellTarget.errorMessage!);
      return;
    }

    final targetKey =
        '${shellTarget.executable}\u0000${shellTarget.workingDirectory}';
    final sameTarget = !force && _process != null && _targetKey == targetKey;
    if (sameTarget) {
      return;
    }

    await _terminateProcess();
    final processToken = ++_processToken;
    _terminal = _createTerminal();
    _state = CodewalkTerminalState.starting;
    _statusMessage =
        'Starting ${shellTarget.statusLabel} in ${shellTarget.workingDirectory}...';
    _targetKey = targetKey;
    _notify();

    try {
      final process = startCodewalkTerminalProcess(
        executable: shellTarget.executable,
        arguments: shellTarget.arguments,
        workingDirectory: shellTarget.workingDirectory,
        environment: shellTarget.environment,
      );
      _process = process;
      late final StreamSubscription<String> outputSubscription;
      var outputClosed = false;

      Future<void> closeOutput() async {
        if (outputClosed) {
          return;
        }
        outputClosed = true;
        if (identical(_outputSubscription, outputSubscription)) {
          _outputSubscription = null;
        }
        await outputSubscription.cancel();
      }

      outputSubscription = process.output.listen(
        (data) {
          _terminal.write(data);
          if (_processToken == processToken &&
              _state == CodewalkTerminalState.starting) {
            _state = CodewalkTerminalState.running;
            _statusMessage =
                '${shellTarget.statusLabel} running in ${shellTarget.workingDirectory}';
            _notify();
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (_processToken != processToken) {
            return;
          }
          unawaited(closeOutput());
          _state = CodewalkTerminalState.failed;
          _statusMessage = 'Terminal start failed: $error';
          _notify();
        },
      );
      _outputSubscription = outputSubscription;
      _exitWatcher = process.exitCode.then((code) async {
        if (_processToken != processToken) {
          return;
        }
        _process = null;
        await closeOutput();
        _state = CodewalkTerminalState.exited;
        _statusMessage = 'Terminal exited with code $code.';
        _notify();
      });
    } catch (error) {
      _process = null;
      _state = CodewalkTerminalState.failed;
      _statusMessage = 'Terminal start failed: $error';
      _notify();
    }
  }

  Future<void> stop() async {
    await _terminateProcess();
    _state = CodewalkTerminalState.idle;
    _statusMessage = 'Terminal session closed.';
    _notify();
  }

  Future<void> _resetToUnavailable(String message) async {
    await _terminateProcess();
    _terminal = _createTerminal();
    _state = CodewalkTerminalState.unavailable;
    _statusMessage = message;
    _notify();
  }

  Future<void> _terminateProcess({bool awaitExit = true}) async {
    final process = _process;
    final outputSubscription = _outputSubscription;
    final exitWatcher = _exitWatcher;
    _processToken += 1;
    _process = null;
    _outputSubscription = null;
    _targetKey = null;
    _exitWatcher = null;
    process?.kill();
    await outputSubscription?.cancel();
    if (awaitExit) {
      await exitWatcher;
    }
  }

  Terminal _createTerminal() {
    final terminal = Terminal(maxLines: 10000);
    terminal.onOutput = (data) {
      _process?.write(data);
    };
    terminal.onResize = (width, height, _, _) {
      _process?.resize(height, width);
    };
    return terminal;
  }

  void _notify() {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_terminateProcess(awaitExit: false));
    super.dispose();
  }
}
