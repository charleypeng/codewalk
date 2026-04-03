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
  String? _attachUrl;
  String? _commandPath;

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
    final sameTarget =
        !force &&
        _process != null &&
        _attachUrl == attachUrl &&
        _commandPath == executable;
    if (sameTarget) {
      return;
    }

    await _terminateProcess();
    _terminal = _createTerminal();
    _state = CodewalkTerminalState.attaching;
    _statusMessage = 'Attaching to ${serverProfile.displayName}...';
    _attachedServerLabel = serverProfile.displayName;
    _attachUrl = attachUrl;
    _commandPath = executable;
    notifyListeners();

    try {
      final process = startCodewalkTerminalProcess(
        executable: executable,
        arguments: <String>['attach', attachUrl],
      );
      _process = process;
      _outputSubscription = process.output.listen(
        (data) {
          _terminal.write(data);
          if (_state == CodewalkTerminalState.attaching) {
            _state = CodewalkTerminalState.attached;
            _statusMessage = 'Attached to ${serverProfile.displayName}';
            notifyListeners();
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          _state = CodewalkTerminalState.failed;
          _statusMessage = 'Terminal attach failed: $error';
          notifyListeners();
        },
      );
      _exitWatcher = process.exitCode.then((code) async {
        if (!identical(process, _process)) {
          return;
        }
        _process = null;
        await _outputSubscription?.cancel();
        _outputSubscription = null;
        _state = CodewalkTerminalState.exited;
        _statusMessage = 'Terminal exited with code $code.';
        notifyListeners();
      });
    } catch (error) {
      _process = null;
      _state = CodewalkTerminalState.failed;
      _statusMessage = 'Terminal attach failed: $error';
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _terminateProcess();
    _state = CodewalkTerminalState.idle;
    _statusMessage = 'Terminal session closed.';
    notifyListeners();
  }

  Future<void> _resetToUnavailable(String message) async {
    await _terminateProcess();
    _terminal = _createTerminal();
    _state = CodewalkTerminalState.unavailable;
    _statusMessage = message;
    notifyListeners();
  }

  Future<void> _terminateProcess() async {
    _process?.kill();
    _process = null;
    await _outputSubscription?.cancel();
    _outputSubscription = null;
    await _exitWatcher;
    _exitWatcher = null;
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

  @override
  void dispose() {
    unawaited(_terminateProcess());
    super.dispose();
  }
}
