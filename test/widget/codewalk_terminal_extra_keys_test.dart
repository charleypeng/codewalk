import 'package:codewalk/presentation/widgets/codewalk_terminal_extra_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xterm/xterm.dart';

void main() {
  group('CodewalkTerminalExtraKeysController', () {
    test('delegates unmodified keys to the original input handler', () {
      final output = <String>[];
      final original = _InputHandler((event) {
        return event.state.cursorKeysMode ? 'application' : 'normal';
      });
      final terminal = Terminal(inputHandler: original, onOutput: output.add);
      final controller = CodewalkTerminalExtraKeysController()
        ..attach(terminal);

      controller.dispatchKey(TerminalKey.arrowUp);
      terminal.write('\x1b[?1h');
      controller.dispatchKey(TerminalKey.arrowUp);

      expect(output, ['normal', 'application']);
      controller.dispose();
    });

    test('emits one-shot control characters for letters', () {
      final output = <String>[];
      final terminal = Terminal(onOutput: output.add);
      final controller = CodewalkTerminalExtraKeysController()
        ..attach(terminal);

      for (final key in [
        TerminalKey.keyC,
        TerminalKey.keyD,
        TerminalKey.keyL,
      ]) {
        controller.toggleControl();
        controller.dispatchKey(key);
      }

      expect(output, ['\x03', '\x04', '\x0c']);
      expect(controller.controlEnabled, isFalse);
      controller.dispose();
    });

    test('emits exact arrow modifier sequences', () {
      final output = <String>[];
      final terminal = Terminal(onOutput: output.add);
      final controller = CodewalkTerminalExtraKeysController()
        ..attach(terminal);

      for (final key in [
        TerminalKey.arrowUp,
        TerminalKey.arrowDown,
        TerminalKey.arrowRight,
        TerminalKey.arrowLeft,
      ]) {
        controller.toggleAlt();
        controller.dispatchKey(key);
      }
      controller.toggleControl();
      controller.dispatchKey(TerminalKey.arrowLeft);
      controller.toggleControl();
      controller.toggleAlt();
      controller.dispatchKey(TerminalKey.arrowRight);

      expect(output, [
        '\x1b[1;3A',
        '\x1b[1;3B',
        '\x1b[1;3C',
        '\x1b[1;3D',
        '\x1b[1;5D',
        '\x1b[1;7C',
      ]);
      controller.dispose();
    });

    test('applies modifiers to the first scalar of an IME commit', () {
      final output = <String>[];
      final terminal = Terminal(onOutput: output.add);
      final controller = CodewalkTerminalExtraKeysController()
        ..attach(terminal);

      controller.toggleControl();
      controller.toggleAlt();
      expect(controller.handleRawTextInput('cat'), isTrue);
      expect(controller.handleRawTextInput('dog'), isFalse);
      controller.toggleAlt();
      expect(controller.handleRawTextInput('🙂ok'), isTrue);
      controller.toggleAlt();
      expect(controller.handleRawTextInput('A'), isTrue);
      controller.toggleAlt();
      expect(controller.handleRawTextInput('1'), isTrue);
      controller.toggleAlt();
      expect(controller.handleRawTextInput('!'), isTrue);

      expect(output, ['\x1b\x03at', '\x1b🙂ok', '\x1bA', '\x1b1', '\x1b!']);
      expect(controller.controlEnabled, isFalse);
      expect(controller.altEnabled, isFalse);
      controller.dispose();
    });

    test('leaves pending modifiers armed for modifier key events', () {
      final output = <String>[];
      final terminal = Terminal(onOutput: output.add);
      final controller = CodewalkTerminalExtraKeysController()
        ..attach(terminal);

      controller.toggleControl();
      terminal.keyInput(TerminalKey.shiftLeft);
      terminal.keyInput(TerminalKey.keyC);

      expect(output, ['\x03']);
      controller.dispose();
    });

    test('restores only the input handler installed by the controller', () {
      final original = _InputHandler((_) => 'original');
      final replacement = _InputHandler((_) => 'replacement');
      final terminal = Terminal(inputHandler: original);
      final controller = CodewalkTerminalExtraKeysController()
        ..attach(terminal);

      controller.detach();
      expect(terminal.inputHandler, same(original));

      controller.attach(terminal);
      terminal.inputHandler = replacement;
      controller.detach();
      expect(terminal.inputHandler, same(replacement));
      controller.dispose();
    });

    testWidgets('captures the modified sequence for an arrow repeat', (
      tester,
    ) async {
      final output = <String>[];
      final terminal = Terminal(onOutput: output.add);
      final controller = CodewalkTerminalExtraKeysController()
        ..attach(terminal);

      controller.toggleAlt();
      controller.startArrowRepeat(TerminalKey.arrowUp);
      await tester.pump(codewalkTerminalArrowRepeatInterval * 2);
      controller.stopRepeat();
      final countAfterStop = output.length;
      await tester.pump(codewalkTerminalArrowRepeatInterval * 2);

      expect(output, hasLength(3));
      expect(output, everyElement('\x1b[1;3A'));
      expect(output.length, countAfterStop);
      expect(controller.altEnabled, isFalse);
      controller.dispose();
    });

    testWidgets('reset clears modifiers and cancels arrow repeat', (
      tester,
    ) async {
      final output = <String>[];
      final terminal = Terminal(onOutput: output.add);
      final controller = CodewalkTerminalExtraKeysController()
        ..attach(terminal);

      controller.toggleControl();
      controller.toggleAlt();
      controller.startArrowRepeat(TerminalKey.arrowDown);
      controller.toggleControl();
      controller.reset();
      final countAfterReset = output.length;
      await tester.pump(codewalkTerminalArrowRepeatInterval * 2);

      expect(controller.controlEnabled, isFalse);
      expect(controller.altEnabled, isFalse);
      expect(output.length, countAfterReset);
      controller.dispose();
    });
  });
}

class _InputHandler implements TerminalInputHandler {
  const _InputHandler(this.handler);

  final String? Function(TerminalKeyboardEvent event) handler;

  @override
  String? call(TerminalKeyboardEvent event) => handler(event);
}
