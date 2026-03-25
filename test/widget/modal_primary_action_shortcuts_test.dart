import 'package:codewalk/presentation/widgets/modal_primary_action_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Enter triggers the modal primary action', (tester) async {
    var activations = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModalPrimaryActionShortcuts(
            autofocus: true,
            onPrimaryAction: () {
              activations += 1;
            },
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(activations, 1);
  });

  testWidgets('NumpadEnter triggers the modal primary action', (tester) async {
    var activations = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModalPrimaryActionShortcuts(
            autofocus: true,
            onPrimaryAction: () {
              activations += 1;
            },
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
    await tester.pump();

    expect(activations, 1);
  });

  testWidgets('disabled modal primary action shortcuts ignore Enter', (
    tester,
  ) async {
    var activations = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModalPrimaryActionShortcuts(
            autofocus: true,
            enabled: false,
            onPrimaryAction: () {
              activations += 1;
            },
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(activations, 0);
  });
}
