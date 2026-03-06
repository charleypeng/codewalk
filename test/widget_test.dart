import 'dart:async';
import 'dart:convert';

import 'package:codewalk/domain/entities/chat_composer_draft.dart';
import 'package:codewalk/domain/entities/chat_session.dart';
import 'package:codewalk/presentation/widgets/chat_input_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'support/fakes.dart';

Widget _buildChatInputHarness({
  required ChatInputWidget child,
  MediaQueryData? mediaQueryData,
  double? width,
}) {
  final content = width == null ? child : SizedBox(width: width, child: child);
  Widget home = Scaffold(
    body: Align(alignment: Alignment.bottomCenter, child: content),
  );
  if (mediaQueryData != null) {
    home = MediaQuery(data: mediaQueryData, child: home);
  }
  return MaterialApp(home: home);
}

void main() {
  testWidgets('ChatInputWidget renders and sends message', (
    WidgetTester tester,
  ) async {
    ChatInputSubmission? sentSubmission;

    await tester.pumpWidget(
      _buildChatInputHarness(
        child: ChatInputWidget(
          onSendMessage: (submission) {
            sentSubmission = submission;
          },
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byTooltip('Start voice input'), findsOneWidget);
    expect(find.byIcon(Symbols.send_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.keyboard_return_rounded), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.send_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Symbols.send_rounded));
    await tester.pumpAndSettle();

    expect(sentSubmission?.text, 'hello');
    expect(sentSubmission?.mode, ChatComposerMode.normal);
  });

  testWidgets('canned answers button is visible', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildChatInputHarness(
        child: ChatInputWidget(
          onSendMessage: (_) {},
          cannedAnswersDataSource: InMemoryAppLocalDataSource(),
        ),
      ),
    );

    expect(find.byTooltip('Canned answers'), findsOneWidget);
  });

  testWidgets('canned append inserts text at current cursor', (
    WidgetTester tester,
  ) async {
    final localDataSource = InMemoryAppLocalDataSource();
    await localDataSource.saveCannedAnswersJson(
      jsonEncode([
        {
          'id': 'append-1',
          'text': 'XYZ',
          'insertMode': 'append',
          'scopeMode': 'global',
          'updatedAtEpochMs': 1,
        },
      ]),
    );

    await tester.pumpWidget(
      _buildChatInputHarness(
        child: ChatInputWidget(
          onSendMessage: (_) {},
          cannedAnswersDataSource: localDataSource,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.showKeyboard(find.byType(TextField));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'ab',
        selection: TextSelection.collapsed(offset: 1),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Canned answers'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('XYZ').first);
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'aXYZb');
    expect(field.focusNode?.hasFocus, isTrue);
  });

  testWidgets('canned replace mode replaces current composer text', (
    WidgetTester tester,
  ) async {
    final localDataSource = InMemoryAppLocalDataSource();
    await localDataSource.saveCannedAnswersJson(
      jsonEncode([
        {
          'id': 'replace-1',
          'text': 'Replacement text',
          'insertMode': 'replace',
          'scopeMode': 'global',
          'updatedAtEpochMs': 2,
        },
      ]),
    );

    await tester.pumpWidget(
      _buildChatInputHarness(
        child: ChatInputWidget(
          onSendMessage: (_) {},
          cannedAnswersDataSource: localDataSource,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'old text');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Canned answers'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replacement text').first);
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Replacement text');
  });

  testWidgets(
    'holding send button for 300ms inserts newline instead of sending',
    (WidgetTester tester) async {
      ChatInputSubmission? sentSubmission;

      await tester.pumpWidget(
        _buildChatInputHarness(
          child: ChatInputWidget(
            onSendMessage: (submission) {
              sentSubmission = submission;
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pumpAndSettle();

      final sendButtonFinder = find.byType(FilledButton);
      final gesture = await tester.startGesture(
        tester.getCenter(sendButtonFinder),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(sentSubmission, isNull);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, 'hello\n');
    },
  );

  testWidgets('typing ! enters shell mode and sends shell submission', (
    WidgetTester tester,
  ) async {
    ChatInputSubmission? sentSubmission;

    await tester.pumpWidget(
      _buildChatInputHarness(
        child: ChatInputWidget(
          onSendMessage: (submission) {
            sentSubmission = submission;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '!pwd');
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('composer_shell_mode_chip')),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Symbols.send_rounded));
    await tester.pumpAndSettle();

    expect(sentSubmission?.mode, ChatComposerMode.shell);
    expect(sentSubmission?.text, 'pwd');
  });

  testWidgets('prefilled draft restores attachment-only composer state', (
    WidgetTester tester,
  ) async {
    var prefilledVersion = 0;
    ChatComposerDraft? prefilledDraft;

    Widget buildHarness() {
      return _buildChatInputHarness(
        child: ChatInputWidget(
          onSendMessage: (_) {},
          showAttachmentButton: true,
          prefilledDraft: prefilledDraft,
          prefilledDraftVersion: prefilledVersion,
        ),
      );
    }

    await tester.pumpWidget(buildHarness());

    prefilledDraft = const ChatComposerDraft(
      text: '',
      attachments: <FileInputPart>[
        FileInputPart(
          mime: 'image/png',
          url: 'data:image/png;base64,AA==',
          filename: 'image.png',
        ),
      ],
    );
    prefilledVersion = 1;
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('composer_attachments_row')),
      findsOneWidget,
    );
    expect(find.text('image.png'), findsOneWidget);
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, isEmpty);
  });

  testWidgets('prefilled shell draft restores shell mode with ! prefix', (
    WidgetTester tester,
  ) async {
    var prefilledVersion = 0;
    ChatComposerDraft? prefilledDraft;

    Widget buildHarness() {
      return _buildChatInputHarness(
        child: ChatInputWidget(
          onSendMessage: (_) {},
          prefilledDraft: prefilledDraft,
          prefilledDraftVersion: prefilledVersion,
        ),
      );
    }

    await tester.pumpWidget(buildHarness());

    prefilledDraft = const ChatComposerDraft(text: 'ls -la', shellMode: true);
    prefilledVersion = 1;
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('composer_shell_mode_chip')),
      findsOneWidget,
    );
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, '!ls -la');
  });

  testWidgets('desktop Enter sends and Shift+Enter inserts newline', (
    WidgetTester tester,
  ) async {
    ChatInputSubmission? sentSubmission;
    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await tester.pumpWidget(
        _buildChatInputHarness(
          child: ChatInputWidget(
            onSendMessage: (submission) {
              sentSubmission = submission;
            },
          ),
        ),
      );

      final desktopInputField = tester.widget<TextField>(
        find.byType(TextField),
      );
      expect(desktopInputField.textInputAction, TextInputAction.newline);

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      final textFieldAfterShift = tester.widget<TextField>(
        find.byType(TextField),
      );
      expect(textFieldAfterShift.controller!.text, 'hello\n');
      expect(sentSubmission, isNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(sentSubmission?.text, 'hello');
    } finally {
      debugDefaultTargetPlatformOverride = previousPlatform;
    }
  });

  testWidgets('desktop ESC in normal mode keeps composer focus', (
    WidgetTester tester,
  ) async {
    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await tester.pumpWidget(
        _buildChatInputHarness(child: ChatInputWidget(onSendMessage: (_) {})),
      );

      await tester.showKeyboard(find.byType(TextField));
      await tester.pumpAndSettle();

      final focusedBeforeEsc = tester.widget<TextField>(find.byType(TextField));
      expect(focusedBeforeEsc.focusNode?.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      final focusedAfterEsc = tester.widget<TextField>(find.byType(TextField));
      expect(focusedAfterEsc.focusNode?.hasFocus, isTrue);
    } finally {
      debugDefaultTargetPlatformOverride = previousPlatform;
    }
  });

  testWidgets('double ESC within 500ms requests stop while responding', (
    WidgetTester tester,
  ) async {
    var stopCount = 0;
    var hintCount = 0;
    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await tester.pumpWidget(
        _buildChatInputHarness(
          child: ChatInputWidget(
            onSendMessage: (_) {},
            isResponding: true,
            onStopRequested: () {
              stopCount += 1;
            },
            onStopHintRequested: () {
              hintCount += 1;
            },
          ),
        ),
      );

      await tester.showKeyboard(find.byType(TextField));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(stopCount, 0);
      expect(hintCount, 1);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(stopCount, 1);
      expect(hintCount, 2);
    } finally {
      debugDefaultTargetPlatformOverride = previousPlatform;
    }
  });

  testWidgets(
    'mobile Enter action sends with software keyboard insets active',
    (WidgetTester tester) async {
      ChatInputSubmission? sentSubmission;
      final previousPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await tester.pumpWidget(
          _buildChatInputHarness(
            mediaQueryData: const MediaQueryData(
              viewInsets: EdgeInsets.only(bottom: 320),
            ),
            child: ChatInputWidget(
              onSendMessage: (submission) {
                sentSubmission = submission;
              },
            ),
          ),
        );

        await tester.enterText(find.byType(TextField), 'hello');
        await tester.pumpAndSettle();

        final mobileInputField = tester.widget<TextField>(
          find.byType(TextField),
        );
        expect(mobileInputField.textInputAction, TextInputAction.send);
        expect(mobileInputField.focusNode?.hasFocus, isTrue);

        mobileInputField.onSubmitted?.call('hello');
        await tester.pumpAndSettle();

        expect(sentSubmission?.text, 'hello');

        final updatedInputField = tester.widget<TextField>(
          find.byType(TextField),
        );
        expect(updatedInputField.focusNode?.hasFocus, isTrue);
      } finally {
        debugDefaultTargetPlatformOverride = previousPlatform;
      }
    },
  );

  testWidgets(
    'mobile Enter action keeps focus when software keyboard is hidden',
    (WidgetTester tester) async {
      ChatInputSubmission? sentSubmission;
      final previousPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await tester.pumpWidget(
          _buildChatInputHarness(
            child: ChatInputWidget(
              onSendMessage: (submission) {
                sentSubmission = submission;
              },
            ),
          ),
        );

        await tester.enterText(find.byType(TextField), 'hello');
        await tester.pumpAndSettle();

        final mobileInputField = tester.widget<TextField>(
          find.byType(TextField),
        );
        expect(mobileInputField.textInputAction, TextInputAction.send);
        expect(mobileInputField.focusNode?.hasFocus, isTrue);

        mobileInputField.onSubmitted?.call('hello');
        await tester.pumpAndSettle();

        expect(sentSubmission?.text, 'hello');

        final updatedInputField = tester.widget<TextField>(
          find.byType(TextField),
        );
        expect(updatedInputField.focusNode?.hasFocus, isTrue);
      } finally {
        debugDefaultTargetPlatformOverride = previousPlatform;
      }
    },
  );

  testWidgets(
    'desktop ArrowUp and ArrowDown navigate sent-message history with caret boundaries',
    (WidgetTester tester) async {
      final previousPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await tester.pumpWidget(
          _buildChatInputHarness(
            child: ChatInputWidget(
              onSendMessage: (_) {},
              sentMessageHistory: const <String>[
                'first prompt',
                'second prompt',
                'third prompt',
              ],
            ),
          ),
        );

        await tester.showKeyboard(find.byType(TextField));
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        var textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller!.text, 'third prompt');
        expect(
          textField.controller!.selection.baseOffset,
          'third prompt'.length,
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller!.text, 'third prompt');
        expect(textField.controller!.selection.baseOffset, 0);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller!.text, 'second prompt');
        expect(
          textField.controller!.selection.baseOffset,
          'second prompt'.length,
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller!.selection.baseOffset, 0);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        textField = tester.widget<TextField>(find.byType(TextField));
        expect(
          textField.controller!.selection.baseOffset,
          'second prompt'.length,
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller!.text, 'third prompt');

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller!.text, '');
      } finally {
        debugDefaultTargetPlatformOverride = previousPlatform;
      }
    },
  );

  testWidgets(
    'desktop ArrowUp keeps multiline editor movement before sent-message history',
    (WidgetTester tester) async {
      final previousPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await tester.pumpWidget(
          _buildChatInputHarness(
            child: ChatInputWidget(
              onSendMessage: (_) {},
              sentMessageHistory: const <String>['third prompt'],
            ),
          ),
        );

        await tester.showKeyboard(find.byType(TextField));
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: 'first line\nsecond line',
            selection: TextSelection.collapsed(offset: 22),
          ),
        );
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();

        var textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller!.text, 'first line\nsecond line');
        expect(textField.controller!.selection.baseOffset, lessThan(22));

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();

        textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller!.text, 'third prompt');
      } finally {
        debugDefaultTargetPlatformOverride = previousPlatform;
      }
    },
  );

  testWidgets(
    'desktop ArrowDown keeps multiline editor movement before sent-message history restore',
    (WidgetTester tester) async {
      final previousPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await tester.pumpWidget(
          _buildChatInputHarness(
            child: ChatInputWidget(
              onSendMessage: (_) {},
              sentMessageHistory: const <String>[
                'older prompt',
                'first line\nsecond line',
              ],
            ),
          ),
        );

        await tester.showKeyboard(find.byType(TextField));
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();

        var textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller!.text, 'first line\nsecond line');
        expect(textField.controller!.selection.baseOffset, lessThan(22));

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();

        textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller!.text, 'first line\nsecond line');
        expect(textField.controller!.selection.baseOffset, 22);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();

        textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller!.text, '');
      } finally {
        debugDefaultTargetPlatformOverride = previousPlatform;
      }
    },
  );

  testWidgets(
    'desktop ArrowUp respects soft-wrapped multiline movement before history',
    (WidgetTester tester) async {
      final previousPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await tester.pumpWidget(
          _buildChatInputHarness(
            width: 220,
            child: ChatInputWidget(
              onSendMessage: (_) {},
              sentMessageHistory: const <String>['third prompt'],
            ),
          ),
        );

        await tester.showKeyboard(find.byType(TextField));
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text:
                'This is a long composer line that should wrap before history navigation',
            selection: TextSelection.collapsed(offset: 71),
          ),
        );
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(
          textField.controller!.text,
          'This is a long composer line that should wrap before history navigation',
        );
        expect(textField.controller!.selection.baseOffset, lessThan(71));
      } finally {
        debugDefaultTargetPlatformOverride = previousPlatform;
      }
    },
  );

  testWidgets(
    'desktop ArrowUp and ArrowDown with modifiers keep text field behavior',
    (WidgetTester tester) async {
      final previousPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await tester.pumpWidget(
          _buildChatInputHarness(
            child: ChatInputWidget(
              onSendMessage: (_) {},
              sentMessageHistory: const <String>['third prompt'],
            ),
          ),
        );

        await tester.showKeyboard(find.byType(TextField));
        await tester.pumpAndSettle();

        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();

        var textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller!.text, '');

        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: 'first line\nsecond line',
            selection: TextSelection.collapsed(offset: 0),
          ),
        );
        await tester.pumpAndSettle();

        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();

        textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller!.text, 'first line\nsecond line');
        expect(textField.controller!.selection.baseOffset, 0);
      } finally {
        debugDefaultTargetPlatformOverride = previousPlatform;
      }
    },
  );

  testWidgets('shows Stop action while responding and calls callback', (
    WidgetTester tester,
  ) async {
    var stopCount = 0;
    await tester.pumpWidget(
      _buildChatInputHarness(
        child: ChatInputWidget(
          onSendMessage: (_) {},
          isResponding: true,
          onStopRequested: () {
            stopCount += 1;
          },
        ),
      ),
    );

    expect(find.byIcon(Symbols.stop_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.send_rounded), findsNothing);

    await tester.tap(find.byIcon(Symbols.stop_rounded));
    await tester.pumpAndSettle();

    expect(stopCount, 1);
  });

  testWidgets('microphone stays enabled while responding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildChatInputHarness(
        child: ChatInputWidget(
          onSendMessage: (_) {},
          isResponding: true,
          onStopRequested: () {},
        ),
      ),
    );

    final micButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('Start voice input'),
        matching: find.byType(IconButton),
      ),
    );

    expect(micButton.onPressed, isNotNull);
  });

  testWidgets('microphone stays enabled while send is in flight', (
    WidgetTester tester,
  ) async {
    final sendCompleter = Completer<void>();
    await tester.pumpWidget(
      _buildChatInputHarness(
        child: ChatInputWidget(
          onSendMessage: (_) async {
            await sendCompleter.future;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Symbols.send_rounded));
    await tester.pump();

    final micButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('Start voice input'),
        matching: find.byType(IconButton),
      ),
    );
    expect(micButton.onPressed, isNotNull);

    sendCompleter.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('send completion does not clear draft changed while sending', (
    WidgetTester tester,
  ) async {
    final sendCompleter = Completer<void>();
    await tester.pumpWidget(
      _buildChatInputHarness(
        child: ChatInputWidget(
          onSendMessage: (_) async {
            await sendCompleter.future;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'initial prompt');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Symbols.send_rounded));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'new draft while sending');
    await tester.pump();

    sendCompleter.complete();
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller!.text, 'new draft while sending');
  });

  testWidgets('responding with draft switches action to send', (
    WidgetTester tester,
  ) async {
    ChatInputSubmission? sentSubmission;
    var stopCount = 0;
    await tester.pumpWidget(
      _buildChatInputHarness(
        child: ChatInputWidget(
          onSendMessage: (submission) {
            sentSubmission = submission;
          },
          isResponding: true,
          onStopRequested: () {
            stopCount += 1;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'follow-up prompt');
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.send_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.stop_rounded), findsNothing);

    await tester.tap(find.byIcon(Symbols.send_rounded));
    await tester.pumpAndSettle();

    expect(sentSubmission?.text, 'follow-up prompt');
    expect(stopCount, 0);
  });

  testWidgets('composer keeps outer background transparent', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildChatInputHarness(child: ChatInputWidget(onSendMessage: (_) {})),
    );

    final rootContainer = tester.widget<Container>(
      find.byKey(const ValueKey<String>('composer_root_container')),
    );
    final rootDecoration = rootContainer.decoration as BoxDecoration;
    expect(rootDecoration.color, Colors.transparent);

    final inputBubble = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey<String>('composer_input_bubble')),
    );
    final inputBubbleDecoration = inputBubble.decoration as BoxDecoration;
    expect(inputBubbleDecoration.color, isNot(Colors.transparent));
    expect(inputBubbleDecoration.border, isNull);
  });

  testWidgets('inline attachment button uses subtle transparent style', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildChatInputHarness(
        child: ChatInputWidget(
          onSendMessage: (_) {},
          showAttachmentButton: true,
          showInlineAttachmentButton: true,
        ),
      ),
    );

    final attachButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('Add attachment'),
        matching: find.byType(IconButton),
      ),
    );
    final style = attachButton.style;

    expect(style, isNotNull);
    expect(
      style!.backgroundColor?.resolve(const <WidgetState>{}),
      Colors.transparent,
    );
    expect(
      style.backgroundColor?.resolve(const <WidgetState>{WidgetState.hovered}),
      Colors.transparent,
    );
  });

  testWidgets('composer text field disables inherited hover fill', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildChatInputHarness(child: ChatInputWidget(onSendMessage: (_) {})),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    final decoration = textField.decoration;

    expect(decoration, isNotNull);
    expect(decoration!.filled, isFalse);
    expect(decoration.fillColor, Colors.transparent);
    expect(decoration.hoverColor, Colors.transparent);
    expect(decoration.focusColor, Colors.transparent);
  });

  testWidgets('slash popover inserts selected command prefix', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildChatInputHarness(
        child: ChatInputWidget(
          onSendMessage: (_) {},
          onSlashQuery: (query) async {
            return const <ChatComposerSlashCommandSuggestion>[
              ChatComposerSlashCommandSuggestion(
                name: 'open',
                source: 'command',
                description: 'Open file',
              ),
            ];
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '/op');
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('composer_popover_slash')),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller!.text, '/open ');
  });

  testWidgets('mention popover inserts @ token', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildChatInputHarness(
        child: ChatInputWidget(
          onSendMessage: (_) {},
          onMentionQuery: (query) async {
            return const <ChatComposerMentionSuggestion>[
              ChatComposerMentionSuggestion(
                value: 'README.md',
                type: ChatComposerSuggestionType.file,
                subtitle: 'file',
              ),
            ];
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '@REA');
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('composer_popover_mention')),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller!.text, '@README.md ');
  });

  testWidgets(
    'mention popover stays above input when keyboard insets are active',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildChatInputHarness(
          mediaQueryData: const MediaQueryData(
            size: Size(390, 844),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: ChatInputWidget(
            onSendMessage: (_) {},
            onMentionQuery: (query) async {
              return List<ChatComposerMentionSuggestion>.generate(
                20,
                (index) => ChatComposerMentionSuggestion(
                  value: 'README_$index.md',
                  type: ChatComposerSuggestionType.file,
                  subtitle: 'file',
                ),
              );
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '@REA');
      await tester.pumpAndSettle();

      final popoverFinder = find.byKey(
        const ValueKey<String>('composer_popover_mention'),
      );
      expect(popoverFinder, findsOneWidget);
      final panelFinder = find.byKey(
        const ValueKey<String>('composer_popover_panel_mention'),
      );
      expect(panelFinder, findsOneWidget);

      final inputRect = tester.getRect(find.byType(TextField));
      final popoverRect = tester.getRect(panelFinder);
      expect(popoverRect.bottom, lessThanOrEqualTo(inputRect.top));
      expect(popoverRect.height, lessThanOrEqualTo(156));
      expect(inputRect.bottom, lessThanOrEqualTo(844 - 300));

      final popoverScrollableFinder = find.descendant(
        of: panelFinder,
        matching: find.byType(Scrollable),
      );
      expect(popoverScrollableFinder, findsOneWidget);
      expect(find.text('README_19.md'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('README_19.md'),
        80,
        scrollable: popoverScrollableFinder,
      );
      await tester.pumpAndSettle();
      expect(find.text('README_19.md'), findsOneWidget);
    },
  );

  testWidgets('mention selection keeps input focused while typing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildChatInputHarness(
        child: ChatInputWidget(
          onSendMessage: (_) {},
          onMentionQuery: (query) async {
            return const <ChatComposerMentionSuggestion>[
              ChatComposerMentionSuggestion(
                value: 'lib/main.dart',
                type: ChatComposerSuggestionType.file,
                subtitle: 'file',
              ),
            ];
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '@ma');
    await tester.pumpAndSettle();

    final inputField = tester.widget<TextField>(find.byType(TextField));
    expect(inputField.focusNode?.hasFocus, isTrue);
  });

  testWidgets(
    'mention insertion guarantees space before trailing punctuation',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildChatInputHarness(
          child: ChatInputWidget(
            onSendMessage: (_) {},
            onMentionQuery: (query) async {
              return const <ChatComposerMentionSuggestion>[
                ChatComposerMentionSuggestion(
                  value: 'README.md',
                  type: ChatComposerSuggestionType.file,
                  subtitle: 'file',
                ),
              ];
            },
          ),
        ),
      );

      await tester.showKeyboard(find.byType(TextField));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '@REA?',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, '@README.md ?');
    },
  );

  test('microphone button uses transparent background when inactive', () {
    const colorScheme = ColorScheme.light();
    expect(
      microphoneButtonBackgroundColor(
        isListening: false,
        colorScheme: colorScheme,
      ),
      Colors.transparent,
    );
    expect(
      microphoneButtonForegroundColor(
        isListening: false,
        colorScheme: colorScheme,
      ),
      colorScheme.onSecondaryContainer,
    );
  });

  test('microphone button turns red while listening', () {
    const colorScheme = ColorScheme.light();
    expect(
      microphoneButtonBackgroundColor(
        isListening: true,
        colorScheme: colorScheme,
      ),
      colorScheme.error,
    );
    expect(
      microphoneButtonForegroundColor(
        isListening: true,
        colorScheme: colorScheme,
      ),
      colorScheme.onError,
    );
  });

  test('splitComposerTextAtSelection keeps trailing text at caret', () {
    final split = splitComposerTextAtSelection(
      const TextEditingValue(
        text: 'hello world',
        selection: TextSelection.collapsed(offset: 6),
      ),
    );

    expect(split.leadingText, 'hello ');
    expect(split.trailingText, 'world');
  });

  test('splitComposerTextAtSelection replaces selected range', () {
    final split = splitComposerTextAtSelection(
      const TextEditingValue(
        text: 'hello brave world',
        selection: TextSelection(baseOffset: 6, extentOffset: 11),
      ),
    );

    expect(split.leadingText, 'hello ');
    expect(split.trailingText, ' world');
  });

  test('composeComposerValueWithSuffix keeps cursor before suffix', () {
    final value = composeComposerValueWithSuffix(
      leadingText: 'hello voice',
      trailingText: ' world',
    );

    expect(value.text, 'hello voice world');
    expect(value.selection.baseOffset, 'hello voice'.length);
    expect(value.selection.extentOffset, 'hello voice'.length);
  });

  test('composer attachment style keeps transparent backgrounds', () {
    final style = composerAttachButtonStyle(
      colorScheme: const ColorScheme.light(),
    );

    expect(
      style.backgroundColor?.resolve(const <WidgetState>{}),
      Colors.transparent,
    );
    expect(
      style.backgroundColor?.resolve(const <WidgetState>{WidgetState.hovered}),
      Colors.transparent,
    );
    expect(
      style.backgroundColor?.resolve(const <WidgetState>{WidgetState.pressed}),
      Colors.transparent,
    );
  });

  test('composer bubble color falls back when preferred is too close', () {
    const surface = Color(0xFF101010);
    const preferred = Color(0xFF101010);
    const fallbackOverlay = Color(0x1FFFFFFF);

    final resolved = resolveComposerBubbleColor(
      preferredColor: preferred,
      surfaceColor: surface,
      fallbackOverlayColor: fallbackOverlay,
      minLuminanceDelta: 0.03,
    );

    expect(resolved, isNot(surface));
  });

  test('composer bubble color keeps preferred when already distinct', () {
    const surface = Color(0xFF101010);
    const preferred = Color(0xFF2A2A2A);

    final resolved = resolveComposerBubbleColor(
      preferredColor: preferred,
      surfaceColor: surface,
      fallbackOverlayColor: const Color(0x1FFFFFFF),
      minLuminanceDelta: 0.01,
    );

    expect(resolved, preferred);
  });
}
