import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xterm/xterm.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'xterm delete detection emits backspace for Android edit deltas',
    (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final terminalOutput = <String>[];
        final terminal = Terminal(onOutput: terminalOutput.add);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TerminalView(
                terminal,
                autofocus: true,
                deleteDetection: true,
              ),
            ),
          ),
        );
        await tester.tap(find.byType(TerminalView));
        await tester.pump(const Duration(seconds: 1));

        binding.testTextInput.enterText('ab');
        await binding.idle();
        binding.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: ' ',
            selection: TextSelection.collapsed(offset: 1),
          ),
        );
        await binding.idle();

        expect(terminalOutput.join(), 'ab\x7f');

        binding.testTextInput.enterText('c');
        await binding.idle();

        expect(terminalOutput.join(), 'ab\x7fc');
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
