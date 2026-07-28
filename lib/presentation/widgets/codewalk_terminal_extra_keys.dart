import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:xterm/xterm.dart';

const codewalkTerminalArrowRepeatInterval = Duration(milliseconds: 80);

class CodewalkTerminalExtraKeysController extends ChangeNotifier {
  Terminal? _terminal;
  TerminalInputHandler? _originalInputHandler;
  _CodewalkTerminalInputHandler? _installedInputHandler;
  Timer? _repeatTimer;
  bool _controlEnabled = false;
  bool _altEnabled = false;
  bool _disposed = false;

  bool get controlEnabled => _controlEnabled;
  bool get altEnabled => _altEnabled;

  void attach(Terminal terminal) {
    assert(!_disposed, 'Cannot attach a disposed controller.');
    if (identical(_terminal, terminal) &&
        identical(terminal.inputHandler, _installedInputHandler)) {
      return;
    }

    detach();
    _terminal = terminal;
    _originalInputHandler = terminal.inputHandler;
    _installedInputHandler = _CodewalkTerminalInputHandler(
      _handleKeyboardEvent,
    );
    terminal.inputHandler = _installedInputHandler;
  }

  void detach() {
    reset();
    final terminal = _terminal;
    final installedInputHandler = _installedInputHandler;
    if (terminal != null &&
        identical(terminal.inputHandler, installedInputHandler)) {
      terminal.inputHandler = _originalInputHandler;
    }
    _terminal = null;
    _originalInputHandler = null;
    _installedInputHandler = null;
  }

  void toggleControl() {
    _controlEnabled = !_controlEnabled;
    notifyListeners();
  }

  void toggleAlt() {
    _altEnabled = !_altEnabled;
    notifyListeners();
  }

  void dispatchKey(TerminalKey key) {
    stopRepeat();
    final terminal = _terminal;
    if (terminal == null) {
      _clearModifiers();
      return;
    }

    final sequence = _resolveKeyboardEvent(_eventFor(terminal, key));
    if (sequence != null) {
      terminal.textInput(sequence);
    }
  }

  void startArrowRepeat(TerminalKey key) {
    assert(_isArrowKey(key), 'Only arrow keys can repeat.');
    stopRepeat();
    final terminal = _terminal;
    if (terminal == null) {
      _clearModifiers();
      return;
    }

    final sequence = _resolveKeyboardEvent(_eventFor(terminal, key));
    if (sequence == null) {
      return;
    }

    terminal.textInput(sequence);
    _repeatTimer = Timer.periodic(codewalkTerminalArrowRepeatInterval, (_) {
      if (!identical(_terminal, terminal)) {
        stopRepeat();
        return;
      }
      terminal.textInput(sequence);
    });
  }

  void stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  bool handleRawTextInput(String text) {
    if (!_hasPendingModifiers) {
      return false;
    }

    final terminal = _terminal;
    final control = _controlEnabled;
    final alt = _altEnabled;
    _clearModifiers();
    if (terminal == null || text.isEmpty) {
      return true;
    }

    final scalars = text.runes.toList(growable: false);
    final first = String.fromCharCode(scalars.first);
    final remaining = String.fromCharCodes(scalars.skip(1));
    terminal.textInput(
      '${_modifyScalar(first, scalars.first, control: control, alt: alt)}'
      '$remaining',
    );
    return true;
  }

  void reset() {
    stopRepeat();
    _clearModifiers();
  }

  TerminalKeyboardEvent _eventFor(Terminal terminal, TerminalKey key) {
    return TerminalKeyboardEvent(
      key: key,
      shift: false,
      ctrl: false,
      alt: false,
      state: terminal,
      altBuffer: terminal.isUsingAltBuffer,
      platform: terminal.platform,
    );
  }

  String? _handleKeyboardEvent(TerminalKeyboardEvent event) {
    if (_isModifierKey(event.key)) {
      return _originalInputHandler?.call(event);
    }
    return _resolveKeyboardEvent(event);
  }

  String? _resolveKeyboardEvent(TerminalKeyboardEvent event) {
    if (!_hasPendingModifiers) {
      return _originalInputHandler?.call(event);
    }

    final modifiedEvent = event.copyWith(
      ctrl: event.ctrl || _controlEnabled,
      alt: event.alt || _altEnabled,
    );
    _clearModifiers();

    final arrowSuffix = _arrowSuffix(modifiedEvent.key);
    if (arrowSuffix != null &&
        (modifiedEvent.shift || modifiedEvent.ctrl || modifiedEvent.alt)) {
      final modifier = _modifierCode(modifiedEvent);
      return '\x1b[1;${modifier ?? 1}$arrowSuffix';
    }

    final letterIndex = _letterIndex(modifiedEvent.key);
    if (letterIndex != null && modifiedEvent.ctrl) {
      final controlCharacter = String.fromCharCode(letterIndex + 1);
      return modifiedEvent.alt ? '\x1b$controlCharacter' : controlCharacter;
    }
    if (letterIndex != null && modifiedEvent.alt) {
      final offset = modifiedEvent.shift ? 0x41 : 0x61;
      return '\x1b${String.fromCharCode(offset + letterIndex)}';
    }

    return _originalInputHandler?.call(modifiedEvent);
  }

  String _modifyScalar(
    String scalar,
    int codePoint, {
    required bool control,
    required bool alt,
  }) {
    if (control) {
      final normalized = codePoint >= 0x41 && codePoint <= 0x5a
          ? codePoint + 0x20
          : codePoint;
      if (normalized >= 0x61 && normalized <= 0x7a) {
        final controlCharacter = String.fromCharCode(normalized - 0x60);
        return alt ? '\x1b$controlCharacter' : controlCharacter;
      }
    }
    return alt ? '\x1b$scalar' : scalar;
  }

  bool get _hasPendingModifiers => _controlEnabled || _altEnabled;

  void _clearModifiers() {
    if (!_hasPendingModifiers) {
      return;
    }
    _controlEnabled = false;
    _altEnabled = false;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    detach();
    _disposed = true;
    super.dispose();
  }
}

class _CodewalkTerminalInputHandler implements TerminalInputHandler {
  const _CodewalkTerminalInputHandler(this._handle);

  final String? Function(TerminalKeyboardEvent event) _handle;

  @override
  String? call(TerminalKeyboardEvent event) => _handle(event);
}

bool _isArrowKey(TerminalKey key) => _arrowSuffix(key) != null;

String? _arrowSuffix(TerminalKey key) {
  return switch (key) {
    TerminalKey.arrowUp => 'A',
    TerminalKey.arrowDown => 'B',
    TerminalKey.arrowRight => 'C',
    TerminalKey.arrowLeft => 'D',
    _ => null,
  };
}

int? _letterIndex(TerminalKey key) {
  if (key.index < TerminalKey.keyA.index ||
      key.index > TerminalKey.keyZ.index) {
    return null;
  }
  return key.index - TerminalKey.keyA.index;
}

String? _modifierCode(TerminalKeyboardEvent event) {
  if (event.shift && event.alt && event.ctrl) {
    return '8';
  }
  if (event.ctrl && event.alt) {
    return '7';
  }
  if (event.shift && event.ctrl) {
    return '6';
  }
  if (event.ctrl) {
    return '5';
  }
  if (event.shift && event.alt) {
    return '4';
  }
  if (event.alt) {
    return '3';
  }
  if (event.shift) {
    return '2';
  }
  return null;
}

bool _isModifierKey(TerminalKey key) {
  return key == TerminalKey.control ||
      key == TerminalKey.controlLeft ||
      key == TerminalKey.controlRight ||
      key == TerminalKey.alt ||
      key == TerminalKey.altLeft ||
      key == TerminalKey.altRight ||
      key == TerminalKey.shift ||
      key == TerminalKey.shiftLeft ||
      key == TerminalKey.shiftRight ||
      key == TerminalKey.meta ||
      key == TerminalKey.metaLeft ||
      key == TerminalKey.metaRight;
}
