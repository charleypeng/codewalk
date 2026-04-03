import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:xterm/xterm.dart';

import '../../domain/entities/server_profile.dart';
import 'codewalk_terminal_process.dart';

enum CodewalkTerminalState {
  idle,
  unavailable,
  attaching,
  attached,
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
  String _statusMessage = 'Open Terminal to attach the official OpenCode TUI.';
  String? _attachedServerLabel;
  String? _targetKey;
  int _processToken = 0;
  bool _disposed = false;

  Terminal get terminal => _terminal;
  CodewalkTerminalState get state => _state;
  String get statusMessage => _statusMessage;
  String? get attachedServerLabel => _attachedServerLabel;
  bool get isAttached => _state == CodewalkTerminalState.attached;

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

  Future<void> attach({
    required ServerProfile? serverProfile,
    required String commandPath,
    bool force = false,
  }) async {
    if (!supportsDesktopAttach) {
      await _resetToUnavailable(
        'Embedded terminal is available on desktop only right now.',
      );
      return;
    }

    if (serverProfile == null) {
      await _resetToUnavailable(
        'Select an active server before opening Terminal.',
      );
      return;
    }

    final executable = commandPath.trim();
    if (executable.isEmpty) {
      await _resetToUnavailable(
        'Configure the local OpenCode command first so CodeWalk can run `opencode attach`.',
      );
      return;
    }

    final attachUrl = _buildAttachUrl(serverProfile);
    final targetKey = '${serverProfile.id}\u0000$executable';
    final sameTarget = !force && _process != null && _targetKey == targetKey;
    if (sameTarget) {
      return;
    }

    await _terminateProcess();
    final processToken = ++_processToken;
    _terminal = _createTerminal();
    _state = CodewalkTerminalState.attaching;
    _statusMessage = 'Attaching to ${serverProfile.displayName}...';
    _attachedServerLabel = serverProfile.displayName;
    _targetKey = targetKey;
    _notify();

    try {
      final process = startCodewalkTerminalProcess(
        executable: executable,
        arguments: <String>['attach', attachUrl],
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
              _state == CodewalkTerminalState.attaching) {
            _state = CodewalkTerminalState.attached;
            _statusMessage = 'Attached to ${serverProfile.displayName}';
            _notify();
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (_processToken != processToken) {
            return;
          }
          unawaited(closeOutput());
          _state = CodewalkTerminalState.failed;
          _statusMessage = 'Terminal attach failed: $error';
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
      _statusMessage = 'Terminal attach failed: $error';
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

  static String _buildAttachUrl(ServerProfile profile) {
    final uri = Uri.parse(profile.url);
    if (!profile.basicAuthEnabled ||
        profile.basicAuthUsername.trim().isEmpty ||
        profile.basicAuthPassword.trim().isEmpty) {
      return uri.toString();
    }
    return uri
        .replace(
          userInfo:
              '${Uri.encodeComponent(profile.basicAuthUsername)}:${Uri.encodeComponent(profile.basicAuthPassword)}',
        )
        .toString();
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
