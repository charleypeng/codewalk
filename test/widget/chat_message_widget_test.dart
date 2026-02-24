import 'package:codewalk/domain/entities/chat_message.dart';
import 'package:codewalk/presentation/widgets/chat_message_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

@Tags(<String>['slow'])
void main() {
  testWidgets('hides step blocks from assistant message body', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_1',
              sessionId: 'ses_1',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: const <MessagePart>[
                StepStartPart(
                  id: 'part_step_start',
                  messageId: 'msg_1',
                  sessionId: 'ses_1',
                  snapshot: 'snap-1',
                ),
                StepFinishPart(
                  id: 'part_step_finish',
                  messageId: 'msg_1',
                  sessionId: 'ses_1',
                  reason: 'stop',
                  cost: 0.0012,
                  tokens: MessageTokens(input: 3, output: 4),
                ),
                TextPart(
                  id: 'part_text',
                  messageId: 'msg_1',
                  sessionId: 'ses_1',
                  text: 'Final answer',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Step started'), findsNothing);
    expect(find.text('Step finished'), findsNothing);
    expect(find.text('Final answer'), findsOneWidget);
  });

  testWidgets('shows step metadata in assistant info popup', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_2',
              sessionId: 'ses_2',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              providerId: 'openai',
              modelId: 'gpt-4.1',
              parts: const <MessagePart>[
                StepStartPart(
                  id: 'part_step_start_2',
                  messageId: 'msg_2',
                  sessionId: 'ses_2',
                  snapshot: 'snap-abc',
                ),
                StepFinishPart(
                  id: 'part_step_finish_2',
                  messageId: 'msg_2',
                  sessionId: 'ses_2',
                  reason: 'stop',
                  cost: 0.0012,
                  tokens: MessageTokens(input: 3, output: 4),
                ),
                TextPart(
                  id: 'part_text_2',
                  messageId: 'msg_2',
                  sessionId: 'ses_2',
                  text: 'Done',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Message Info'));
    await tester.pumpAndSettle();

    expect(find.text('Model: gpt-4.1'), findsOneWidget);
    expect(find.text('Provider: openai'), findsOneWidget);
    expect(find.text('Step started #1: snap-abc'), findsOneWidget);
    expect(
      find.text('Step finished #1: stop • tokens 7 • \$0.001200'),
      findsOneWidget,
    );
  });

  testWidgets('assistant text is selectable and does not show copy button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_3',
              sessionId: 'ses_3',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_text_3',
                  messageId: 'msg_3',
                  sessionId: 'ses_3',
                  text: 'Selectable assistant text',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SelectionArea), findsOneWidget);
    expect(find.byTooltip('Copy'), findsNothing);
  });

  testWidgets('user text also does not show copy button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: UserMessage(
              id: 'msg_4',
              sessionId: 'ses_4',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_text_4',
                  messageId: 'msg_4',
                  sessionId: 'ses_4',
                  text: 'User text',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Copy'), findsNothing);
  });

  testWidgets('user text is not selectable and has no copy button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: UserMessage(
              id: 'msg_6',
              sessionId: 'ses_6',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_text_6',
                  messageId: 'msg_6',
                  sessionId: 'ses_6',
                  text: 'User selectable text',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SelectionArea), findsNothing);
    expect(find.byTooltip('Copy'), findsNothing);
  });

  testWidgets('file part with inline payload renders save action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: UserMessage(
              id: 'msg_file_data',
              sessionId: 'ses_file_data',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: const <MessagePart>[
                FilePart(
                  id: 'part_file_data',
                  messageId: 'msg_file_data',
                  sessionId: 'ses_file_data',
                  url:
                      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aX7sAAAAASUVORK5CYII=',
                  mime: 'image/png',
                  filename: 'preview.png',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Save File'), findsOneWidget);
    expect(find.byIcon(Symbols.download_rounded), findsOneWidget);
    expect(find.text('preview.png'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('file_image_preview_part_file_data')),
      findsOneWidget,
    );
  });

  testWidgets('file part with source path renders open action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: UserMessage(
              id: 'msg_file_source',
              sessionId: 'ses_file_source',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: const <MessagePart>[
                FilePart(
                  id: 'part_file_source',
                  messageId: 'msg_file_source',
                  sessionId: 'ses_file_source',
                  url: 'file:///tmp/report.pdf',
                  mime: 'application/pdf',
                  filename: 'report.pdf',
                  fileSource: FileSource(
                    path: '/tmp/report.pdf',
                    text: FilePartSourceText(value: '', start: 0, end: 0),
                    type: 'file',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Open File'), findsOneWidget);
    expect(find.byIcon(Symbols.open_in_new_rounded), findsOneWidget);
    expect(find.text('/tmp/report.pdf'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('file_image_preview_part_file_source')),
      findsNothing,
    );
  });

  testWidgets('background copy handler shows feedback on non-android', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_7',
              sessionId: 'ses_7',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_text_7a',
                  messageId: 'msg_7',
                  sessionId: 'ses_7',
                  text: 'First line',
                ),
                TextPart(
                  id: 'part_text_7b',
                  messageId: 'msg_7',
                  sessionId: 'ses_7',
                  text: 'Second line',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('First line'));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.text('First line'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Copied to clipboard'), findsOneWidget);
  });

  testWidgets('background copy handler does not show feedback on android', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_9',
              sessionId: 'ses_9',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_text_9',
                  messageId: 'msg_9',
                  sessionId: 'ses_9',
                  text: 'Android native clipboard feedback',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Android native clipboard feedback'));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.text('Android native clipboard feedback'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Copied to clipboard'), findsNothing);
  });

  testWidgets('user message double tap copies whole message text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: Scaffold(
          body: ChatMessageWidget(
            message: UserMessage(
              id: 'msg_user_no_double_tap',
              sessionId: 'ses_user_no_double_tap',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_text_user_no_double_tap',
                  messageId: 'msg_user_no_double_tap',
                  sessionId: 'ses_user_no_double_tap',
                  text: 'User text',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('User text'));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.text('User text'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Copied to clipboard'), findsOneWidget);
  });

  testWidgets('double tap on assistant text copies whole message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_8',
              sessionId: 'ses_8',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_text_8',
                  messageId: 'msg_8',
                  sessionId: 'ses_8',
                  text: 'Word selection should win',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final textFinder = find.text('Word selection should win');
    await tester.tap(textFinder);
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(textFinder);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Copied to clipboard'), findsOneWidget);
  });

  testWidgets('single tap on markdown code copies code snippet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_code_tap',
              sessionId: 'ses_code_tap',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_code_tap',
                  messageId: 'msg_code_tap',
                  sessionId: 'ses_code_tap',
                  text: '```dart\nfinal value = 42;\n```',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.textContaining('final value = 42;'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Copied to clipboard'), findsOneWidget);
  });

  testWidgets('markdown code stays stable across parent rebuilds', (
    WidgetTester tester,
  ) async {
    var showLeadingPanel = true;

    Widget buildHost() {
      return MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Row(
                children: [
                  if (showLeadingPanel) const SizedBox(width: 120),
                  Expanded(
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                showLeadingPanel = !showLeadingPanel;
                              });
                            },
                            child: const Text('toggle panel'),
                          ),
                        ),
                        Expanded(
                          child: ChatMessageWidget(
                            message: AssistantMessage(
                              id: 'msg_code_stable',
                              sessionId: 'ses_code_stable',
                              time: DateTime.fromMillisecondsSinceEpoch(1000),
                              completedTime:
                                  DateTime.fromMillisecondsSinceEpoch(1200),
                              parts: const <MessagePart>[
                                TextPart(
                                  id: 'part_code_stable',
                                  messageId: 'msg_code_stable',
                                  sessionId: 'ses_code_stable',
                                  text:
                                      '```dart\nfinal value = 42;\nprint(value);\n```',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildHost());
    await tester.pumpAndSettle();

    expect(find.textContaining('final value = 42;'), findsOneWidget);
    expect(find.textContaining('print(value);'), findsOneWidget);

    for (var i = 0; i < 4; i += 1) {
      await tester.tap(find.text('toggle panel'));
      await tester.pumpAndSettle();
      expect(find.textContaining('final value = 42;'), findsOneWidget);
      expect(find.textContaining('print(value);'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('multiple inline code spans render without key collisions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_inline_code_keys',
              sessionId: 'ses_inline_code_keys',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              completedTime: DateTime.fromMillisecondsSinceEpoch(1200),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_inline_code_keys',
                  messageId: 'msg_inline_code_keys',
                  sessionId: 'ses_inline_code_keys',
                  text: 'Use `alpha` and `beta` in sequence.',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('alpha'), findsOneWidget);
    expect(find.textContaining('beta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiple fenced code blocks render without key collisions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_fenced_code_keys',
              sessionId: 'ses_fenced_code_keys',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              completedTime: DateTime.fromMillisecondsSinceEpoch(1200),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_fenced_code_keys',
                  messageId: 'msg_fenced_code_keys',
                  sessionId: 'ses_fenced_code_keys',
                  text:
                      '```dart\nfinal alpha = 1;\n```\n\n```dart\nfinal beta = 2;\n```',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('final alpha = 1;'), findsOneWidget);
    expect(find.textContaining('final beta = 2;'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('touch hold callback stays scoped to user messages', (
    WidgetTester tester,
  ) async {
    var userLongPressCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            onBackgroundLongPress: () {
              userLongPressCount += 1;
            },
            message: UserMessage(
              id: 'msg_user_hold',
              sessionId: 'ses_user_hold',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_text_user_hold',
                  messageId: 'msg_user_hold',
                  sessionId: 'ses_user_hold',
                  text: 'Press and hold me',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.text('Press and hold me'));
    await tester.pumpAndSettle();
    expect(userLongPressCount, 1);

    var assistantLongPressCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            onBackgroundLongPress: () {
              assistantLongPressCount += 1;
            },
            message: AssistantMessage(
              id: 'msg_assistant_hold',
              sessionId: 'ses_assistant_hold',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_text_assistant_hold',
                  messageId: 'msg_assistant_hold',
                  sessionId: 'ses_assistant_hold',
                  text: 'Assistant should stay selectable',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.text('Assistant should stay selectable'));
    await tester.pumpAndSettle();
    expect(assistantLongPressCount, 0);
  });

  testWidgets('tool completed output starts collapsed and can expand', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_tool_completed',
              sessionId: 'ses_tool',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: <MessagePart>[
                ToolPart(
                  id: 'part_tool_completed',
                  messageId: 'msg_tool_completed',
                  sessionId: 'ses_tool',
                  callId: 'call_1',
                  tool: 'bash',
                  state: ToolStateCompleted(
                    input: const <String, dynamic>{'cmd': 'ls -la'},
                    output: 'line 1\nline 2\nline 3\nline 4',
                    time: ToolTime(
                      start: DateTime.fromMillisecondsSinceEpoch(1000),
                      end: DateTime.fromMillisecondsSinceEpoch(1200),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tool Call: bash'), findsNothing);
    expect(find.text('Running command'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.key == const ValueKey<String>('tool_command_text') &&
            widget.text.toPlainText().contains('Command: ls -la'),
      ),
      findsOneWidget,
    );

    var outputText = tester.widget<Text>(
      find.byKey(const ValueKey<String>('tool_content_text')),
    );
    expect(outputText.maxLines, 2);
    expect(find.text('Show more'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('tool_content_toggle_button')),
    );
    await tester.pumpAndSettle();

    outputText = tester.widget<Text>(
      find.byKey(const ValueKey<String>('tool_content_text')),
    );
    expect(outputText.maxLines, isNull);
    expect(find.text('Show less'), findsOneWidget);
  });

  testWidgets('tool error output starts collapsed and can expand', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_tool_error',
              sessionId: 'ses_tool',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: <MessagePart>[
                ToolPart(
                  id: 'part_tool_error',
                  messageId: 'msg_tool_error',
                  sessionId: 'ses_tool',
                  callId: 'call_2',
                  tool: 'bash',
                  state: ToolStateError(
                    input: const <String, dynamic>{'cmd': 'cat missing.txt'},
                    error: 'error line 1\nerror line 2\nerror line 3',
                    time: ToolTime(
                      start: DateTime.fromMillisecondsSinceEpoch(1000),
                      end: DateTime.fromMillisecondsSinceEpoch(1200),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tool Call: bash'), findsNothing);
    expect(find.text('Running command'), findsOneWidget);
    expect(find.text('Needs attention'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.key == const ValueKey<String>('tool_command_text') &&
            widget.text.toPlainText().contains('Command: cat missing.txt'),
      ),
      findsOneWidget,
    );

    var outputText = tester.widget<Text>(
      find.byKey(const ValueKey<String>('tool_content_text')),
    );
    expect(outputText.maxLines, 2);
    expect(find.text('Show more'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('tool_content_toggle_button')),
    );
    await tester.pumpAndSettle();

    outputText = tester.widget<Text>(
      find.byKey(const ValueKey<String>('tool_content_text')),
    );
    expect(outputText.maxLines, isNull);
    expect(find.text('Show less'), findsOneWidget);
  });

  testWidgets('mobile tool status chip shows icon without label text', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_tool_mobile_status',
              sessionId: 'ses_tool',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: <MessagePart>[
                ToolPart(
                  id: 'part_tool_mobile_status',
                  messageId: 'msg_tool_mobile_status',
                  sessionId: 'ses_tool',
                  callId: 'call_mobile_1',
                  tool: 'bash',
                  state: ToolStateCompleted(
                    input: const <String, dynamic>{'command': 'pwd'},
                    output: '/tmp',
                    time: ToolTime(
                      start: DateTime.fromMillisecondsSinceEpoch(1000),
                      end: DateTime.fromMillisecondsSinceEpoch(1200),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Done'), findsNothing);
    expect(find.byIcon(Symbols.check_circle_outline_rounded), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.key == const ValueKey<String>('tool_command_text') &&
            widget.text.toPlainText().contains('Command: pwd'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('collapses completed tool chains and reveals them on demand', (
    WidgetTester tester,
  ) async {
    final message = AssistantMessage(
      id: 'msg_tool_chain',
      sessionId: 'ses_tool_chain',
      time: DateTime.fromMillisecondsSinceEpoch(1000),
      completedTime: DateTime.fromMillisecondsSinceEpoch(1200),
      parts: <MessagePart>[
        ToolPart(
          id: 'part_tool_chain_1',
          messageId: 'msg_tool_chain',
          sessionId: 'ses_tool_chain',
          callId: 'call_chain_1',
          tool: 'bash',
          state: ToolStateCompleted(
            input: const <String, dynamic>{'command': 'pwd'},
            output: '/tmp/project',
            time: ToolTime(
              start: DateTime.fromMillisecondsSinceEpoch(1000),
              end: DateTime.fromMillisecondsSinceEpoch(1050),
            ),
          ),
        ),
        ToolPart(
          id: 'part_tool_chain_2',
          messageId: 'msg_tool_chain',
          sessionId: 'ses_tool_chain',
          callId: 'call_chain_2',
          tool: 'read',
          state: ToolStateCompleted(
            input: const <String, dynamic>{'filePath': 'lib/main.dart'},
            output: 'line 1\nline 2',
            time: ToolTime(
              start: DateTime.fromMillisecondsSinceEpoch(1060),
              end: DateTime.fromMillisecondsSinceEpoch(1100),
            ),
          ),
        ),
        const TextPart(
          id: 'part_tool_chain_text',
          messageId: 'msg_tool_chain',
          sessionId: 'ses_tool_chain',
          text: 'Final answer',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChatMessageWidget(message: message)),
      ),
    );

    expect(find.text('Details'), findsOneWidget);
    expect(find.textContaining('Running command'), findsOneWidget);
    expect(find.textContaining('Reading file'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'tool_chain_toggle_msg_tool_chain_part_tool_chain_1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hide'), findsNWidgets(2));
    expect(
      find.byKey(
        const ValueKey<String>('tool_part_details_button_part_tool_chain_1'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('tool_part_details_button_part_tool_chain_2'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('tool_part_details_button_part_tool_chain_1'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('tool_part_details_button_part_tool_chain_2'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('tool_command_text')),
      findsNWidgets(2),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'tool_chain_bottom_toggle_msg_tool_chain_part_tool_chain_1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Details'), findsOneWidget);
    expect(find.textContaining('Running command'), findsOneWidget);
  });

  testWidgets(
    'keeps tool chain expanded while responding and collapses after completion',
    (WidgetTester tester) async {
      final message = AssistantMessage(
        id: 'msg_tool_chain_streaming',
        sessionId: 'ses_tool_chain_streaming',
        time: DateTime.fromMillisecondsSinceEpoch(1000),
        completedTime: DateTime.fromMillisecondsSinceEpoch(1200),
        parts: <MessagePart>[
          ToolPart(
            id: 'part_tool_chain_streaming_1',
            messageId: 'msg_tool_chain_streaming',
            sessionId: 'ses_tool_chain_streaming',
            callId: 'call_chain_streaming_1',
            tool: 'bash',
            state: ToolStateCompleted(
              input: const <String, dynamic>{'command': 'pwd'},
              output: '/tmp/project',
              time: ToolTime(
                start: DateTime.fromMillisecondsSinceEpoch(1000),
                end: DateTime.fromMillisecondsSinceEpoch(1050),
              ),
            ),
          ),
          ToolPart(
            id: 'part_tool_chain_streaming_2',
            messageId: 'msg_tool_chain_streaming',
            sessionId: 'ses_tool_chain_streaming',
            callId: 'call_chain_streaming_2',
            tool: 'read',
            state: ToolStateCompleted(
              input: const <String, dynamic>{'filePath': 'lib/main.dart'},
              output: 'line 1\nline 2',
              time: ToolTime(
                start: DateTime.fromMillisecondsSinceEpoch(1060),
                end: DateTime.fromMillisecondsSinceEpoch(1100),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageWidget(
              message: message,
              isSessionActivelyResponding: true,
            ),
          ),
        ),
      );

      expect(
        find.byKey(
          const ValueKey<String>(
            'tool_chain_toggle_msg_tool_chain_streaming_part_tool_chain_streaming_1',
          ),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'tool_part_details_button_part_tool_chain_streaming_1',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'tool_part_details_button_part_tool_chain_streaming_2',
          ),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Running command'), findsOneWidget);
      expect(find.textContaining('Reading file'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageWidget(
              message: message,
              isSessionActivelyResponding: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>(
            'tool_chain_toggle_msg_tool_chain_streaming_part_tool_chain_streaming_1',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Details'), findsOneWidget);
      expect(find.textContaining('Running command'), findsOneWidget);
      expect(find.textContaining('Reading file'), findsOneWidget);
    },
  );

  testWidgets('uses input description while tool is running', (
    WidgetTester tester,
  ) async {
    final message = AssistantMessage(
      id: 'msg_tool_running_description',
      sessionId: 'ses_tool_running_description',
      time: DateTime.fromMillisecondsSinceEpoch(1000),
      parts: <MessagePart>[
        ToolPart(
          id: 'part_tool_running_description',
          messageId: 'msg_tool_running_description',
          sessionId: 'ses_tool_running_description',
          callId: 'call_tool_running_description',
          tool: 'bash',
          state: ToolStateRunning(
            input: const <String, dynamic>{
              'description': 'Checking project status in real time',
              'command': 'git status --short',
            },
            time: DateTime.fromMillisecondsSinceEpoch(1000),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: message,
            isSessionActivelyResponding: true,
          ),
        ),
      ),
    );

    expect(find.text('Checking project status in real time'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>(
          'tool_part_details_button_part_tool_running_description',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Hide'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.key == const ValueKey<String>('tool_command_text') &&
            widget.text.toPlainText().contains('Command: git status --short'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows tool call descriptions in collapsed summary', (
    WidgetTester tester,
  ) async {
    final message = AssistantMessage(
      id: 'msg_tool_summary_descriptions',
      sessionId: 'ses_tool_summary_descriptions',
      time: DateTime.fromMillisecondsSinceEpoch(1000),
      completedTime: DateTime.fromMillisecondsSinceEpoch(1200),
      parts: <MessagePart>[
        ToolPart(
          id: 'part_tool_summary_descriptions_1',
          messageId: 'msg_tool_summary_descriptions',
          sessionId: 'ses_tool_summary_descriptions',
          callId: 'call_tool_summary_descriptions_1',
          tool: 'bash',
          state: ToolStateCompleted(
            input: const <String, dynamic>{'command': 'ls'},
            output: 'README.md',
            time: ToolTime(
              start: DateTime.fromMillisecondsSinceEpoch(1000),
              end: DateTime.fromMillisecondsSinceEpoch(1050),
            ),
            title: 'Listing project files',
          ),
        ),
        ToolPart(
          id: 'part_tool_summary_descriptions_2',
          messageId: 'msg_tool_summary_descriptions',
          sessionId: 'ses_tool_summary_descriptions',
          callId: 'call_tool_summary_descriptions_2',
          tool: 'read',
          state: ToolStateCompleted(
            input: const <String, dynamic>{'filePath': 'README.md'},
            output: 'Intro',
            time: ToolTime(
              start: DateTime.fromMillisecondsSinceEpoch(1060),
              end: DateTime.fromMillisecondsSinceEpoch(1100),
            ),
            title: 'Reading project docs',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChatMessageWidget(message: message)),
      ),
    );

    expect(find.text('Details'), findsOneWidget);
    expect(find.textContaining('Listing project files'), findsOneWidget);
    expect(find.textContaining('Reading project docs'), findsOneWidget);
  });

  testWidgets('resets tool-chain expansion after widget remount', (
    WidgetTester tester,
  ) async {
    final message = AssistantMessage(
      id: 'msg_tool_chain_remount',
      sessionId: 'ses_tool_chain_remount',
      time: DateTime.fromMillisecondsSinceEpoch(1000),
      completedTime: DateTime.fromMillisecondsSinceEpoch(1200),
      parts: <MessagePart>[
        ToolPart(
          id: 'part_tool_chain_remount_1',
          messageId: 'msg_tool_chain_remount',
          sessionId: 'ses_tool_chain_remount',
          callId: 'call_chain_remount_1',
          tool: 'bash',
          state: ToolStateCompleted(
            input: const <String, dynamic>{'command': 'pwd'},
            output: '/tmp/project',
            time: ToolTime(
              start: DateTime.fromMillisecondsSinceEpoch(1000),
              end: DateTime.fromMillisecondsSinceEpoch(1050),
            ),
          ),
        ),
        ToolPart(
          id: 'part_tool_chain_remount_2',
          messageId: 'msg_tool_chain_remount',
          sessionId: 'ses_tool_chain_remount',
          callId: 'call_chain_remount_2',
          tool: 'read',
          state: ToolStateCompleted(
            input: const <String, dynamic>{'filePath': 'lib/main.dart'},
            output: 'line 1\nline 2',
            time: ToolTime(
              start: DateTime.fromMillisecondsSinceEpoch(1060),
              end: DateTime.fromMillisecondsSinceEpoch(1100),
            ),
          ),
        ),
      ],
    );

    Widget buildWidget() {
      return MaterialApp(
        home: Scaffold(body: ChatMessageWidget(message: message)),
      );
    }

    await tester.pumpWidget(buildWidget());
    expect(find.text('Details'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'tool_chain_toggle_msg_tool_chain_remount_part_tool_chain_remount_1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hide'), findsNWidgets(2));
    expect(find.text('Running command'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('Details'), findsOneWidget);
    expect(find.textContaining('Running command'), findsOneWidget);
  });

  testWidgets('hides assistant title while keeping user header label', (
    WidgetTester tester,
  ) async {
    final userMessage = UserMessage(
      id: 'msg_user_header',
      sessionId: 'ses_header_labels',
      time: DateTime.fromMillisecondsSinceEpoch(1000),
      parts: const <MessagePart>[
        TextPart(
          id: 'part_user_header',
          messageId: 'msg_user_header',
          sessionId: 'ses_header_labels',
          text: 'User text',
        ),
      ],
    );

    final assistantMessage = AssistantMessage(
      id: 'msg_assistant_header',
      sessionId: 'ses_header_labels',
      time: DateTime.fromMillisecondsSinceEpoch(1100),
      completedTime: DateTime.fromMillisecondsSinceEpoch(1200),
      parts: const <MessagePart>[
        TextPart(
          id: 'part_assistant_header',
          messageId: 'msg_assistant_header',
          sessionId: 'ses_header_labels',
          text: 'Assistant text',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ChatMessageWidget(message: userMessage),
              ChatMessageWidget(message: assistantMessage),
            ],
          ),
        ),
      ),
    );

    expect(find.text('You'), findsOneWidget);
    expect(find.text('Assistant'), findsNothing);
    expect(find.text('Assistant text'), findsOneWidget);
  });

  testWidgets('shows queued badge for queued user message', (
    WidgetTester tester,
  ) async {
    final userMessage = UserMessage(
      id: 'msg_user_queued_badge',
      sessionId: 'ses_user_queued_badge',
      time: DateTime.fromMillisecondsSinceEpoch(1000),
      parts: const <MessagePart>[
        TextPart(
          id: 'part_user_queued_badge',
          messageId: 'msg_user_queued_badge',
          sessionId: 'ses_user_queued_badge',
          text: 'Queued message body',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: userMessage,
            isQueuedUserMessage: true,
          ),
        ),
      ),
    );

    expect(find.text('Queued'), findsOneWidget);
  });

  testWidgets('assistant header spacing follows visual density', (
    WidgetTester tester,
  ) async {
    final message = AssistantMessage(
      id: 'msg_density_spacing',
      sessionId: 'ses_density_spacing',
      time: DateTime.fromMillisecondsSinceEpoch(1100),
      completedTime: DateTime.fromMillisecondsSinceEpoch(1200),
      parts: const <MessagePart>[
        TextPart(
          id: 'part_density_spacing',
          messageId: 'msg_density_spacing',
          sessionId: 'ses_density_spacing',
          text: 'Density aware content',
        ),
      ],
    );

    Future<double> pumpAndReadSpacing(VisualDensity density) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true, visualDensity: density),
          home: Scaffold(body: ChatMessageWidget(message: message)),
        ),
      );
      await tester.pumpAndSettle();
      final spacing = tester.widget<SizedBox>(
        find.byKey(
          const ValueKey<String>('message_header_spacing_msg_density_spacing'),
        ),
      );
      return spacing.height!;
    }

    final denseHeight = await pumpAndReadSpacing(
      const VisualDensity(horizontal: -2, vertical: -2),
    );
    final normalHeight = await pumpAndReadSpacing(VisualDensity.standard);
    final spaciousHeight = await pumpAndReadSpacing(
      const VisualDensity(horizontal: 2, vertical: 2),
    );

    expect(denseHeight, lessThanOrEqualTo(normalHeight));
    expect(spaciousHeight, greaterThan(normalHeight));
  });

  testWidgets(
    'thinking starts compact, expands with bounded viewport, and previous block collapses',
    (WidgetTester tester) async {
      AssistantMessage buildMessage(List<MessagePart> parts) {
        return AssistantMessage(
          id: 'msg_thinking',
          sessionId: 'ses_thinking',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          parts: parts,
        );
      }

      Widget buildWidget(AssistantMessage message) {
        return MaterialApp(
          home: Scaffold(body: ChatMessageWidget(message: message)),
        );
      }

      const reasoningOne = ReasoningPart(
        id: 'thinking_1',
        messageId: 'msg_thinking',
        sessionId: 'ses_thinking',
        text:
            'line 1\nline 2\nline 3\nline 4\nline 5\nline 6\nline 7\nline 8\nline 9\nline 10',
      );
      const reasoningTwo = ReasoningPart(
        id: 'thinking_2',
        messageId: 'msg_thinking',
        sessionId: 'ses_thinking',
        text: 'step 1\nstep 2\nstep 3\nstep 4\nstep 5\nstep 6',
      );

      await tester.pumpWidget(
        buildWidget(buildMessage(const <MessagePart>[reasoningOne])),
      );

      final firstViewportFinder = find.byKey(
        const ValueKey<String>(
          'thinking_content_viewport_msg_thinking::thinking_1',
        ),
      );
      final collapsedHeight = tester.getSize(firstViewportFinder).height;
      expect(
        find.byKey(
          const ValueKey<String>(
            'thinking_content_toggle_msg_thinking::thinking_1',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'thinking_content_scrollbar_msg_thinking::thinking_1',
          ),
        ),
        findsNothing,
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>(
            'thinking_content_toggle_msg_thinking::thinking_1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final expandedHeight = tester.getSize(firstViewportFinder).height;
      expect(expandedHeight, greaterThan(collapsedHeight));
      expect(
        find.byKey(
          const ValueKey<String>(
            'thinking_content_scrollbar_msg_thinking::thinking_1',
          ),
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(
        buildWidget(
          buildMessage(const <MessagePart>[reasoningOne, reasoningTwo]),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>(
            'thinking_content_scrollbar_msg_thinking::thinking_1',
          ),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'thinking_content_viewport_msg_thinking::thinking_2',
          ),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'hides reasoning block when first line is a markdown status marker',
    (WidgetTester tester) async {
      final message = AssistantMessage(
        id: 'msg_status_reasoning',
        sessionId: 'ses_status_reasoning',
        time: DateTime.fromMillisecondsSinceEpoch(1000),
        parts: const <MessagePart>[
          ReasoningPart(
            id: 'reasoning_status',
            messageId: 'msg_status_reasoning',
            sessionId: 'ses_status_reasoning',
            text: '**Indexing workspace**\ncollecting files...',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ChatMessageWidget(message: message)),
        ),
      );

      expect(find.text('Thinking Process'), findsNothing);
      expect(
        find.byKey(
          const ValueKey<String>(
            'thinking_content_text_msg_status_reasoning::reasoning_status',
          ),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'thinking auto-collapses when latest reasoning moves to another message',
    (WidgetTester tester) async {
      final message = AssistantMessage(
        id: 'msg_a',
        sessionId: 'ses_thinking',
        time: DateTime.fromMillisecondsSinceEpoch(1000),
        parts: const <MessagePart>[
          ReasoningPart(
            id: 'thinking_a',
            messageId: 'msg_a',
            sessionId: 'ses_thinking',
            text: 'line 1\nline 2\nline 3\nline 4\nline 5\nline 6',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageWidget(
              message: message,
              activeReasoningPartKey: 'msg_a::thinking_a',
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('thinking_content_toggle_msg_a::thinking_a'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>(
            'thinking_content_scrollbar_msg_a::thinking_a',
          ),
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageWidget(
              message: message,
              activeReasoningPartKey: 'msg_b::thinking_b',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>(
            'thinking_content_scrollbar_msg_a::thinking_a',
          ),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('renders colorized diff for apply_patch tool', (tester) async {
    const diffOutput = '''--- file.dart
+++ file.dart
@@ -1,2 +1,3 @@
 context
-old line
+new line''';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_diff_1',
              sessionId: 'ses_diff',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: <MessagePart>[
                ToolPart(
                  id: 'tool_diff_1',
                  messageId: 'msg_diff_1',
                  sessionId: 'ses_diff',
                  callId: 'call_diff_1',
                  tool: 'apply_patch',
                  state: ToolStateCompleted(
                    input: const <String, dynamic>{},
                    output: diffOutput,
                    time: ToolTime(
                      start: DateTime.fromMillisecondsSinceEpoch(1000),
                      end: DateTime.fromMillisecondsSinceEpoch(1100),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Expandir para ver diff colorizado
    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();

    // Linhas de diff colorizadas devem estar presentes
    expect(
      find.byKey(const ValueKey<String>('diff_line_container_0')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('tool_output_diff_container_0')),
      findsOneWidget,
    );
  });

  testWidgets('applies diff foreground and background styles', (tester) async {
    const diffOutput = '''--- file.dart
+++ file.dart
@@ -1,2 +1,3 @@
 context
-old line
+new line''';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_diff_styled_1',
              sessionId: 'ses_diff',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: <MessagePart>[
                ToolPart(
                  id: 'tool_diff_styled_1',
                  messageId: 'msg_diff_styled_1',
                  sessionId: 'ses_diff',
                  callId: 'call_diff_styled_1',
                  tool: 'apply_patch',
                  state: ToolStateCompleted(
                    input: const <String, dynamic>{},
                    output: diffOutput,
                    time: ToolTime(
                      start: DateTime.fromMillisecondsSinceEpoch(1000),
                      end: DateTime.fromMillisecondsSinceEpoch(1100),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();

    final addContainer = tester.widget<Container>(
      find.byKey(const ValueKey<String>('tool_output_diff_container_5')),
    );
    final removeContainer = tester.widget<Container>(
      find.byKey(const ValueKey<String>('tool_output_diff_container_4')),
    );
    final hunkContainer = tester.widget<Container>(
      find.byKey(const ValueKey<String>('tool_output_diff_container_2')),
    );

    final addText = tester.widget<Text>(
      find.byKey(const ValueKey<String>('tool_output_diff_text_5')),
    );
    final removeText = tester.widget<Text>(
      find.byKey(const ValueKey<String>('tool_output_diff_text_4')),
    );
    final hunkText = tester.widget<Text>(
      find.byKey(const ValueKey<String>('tool_output_diff_text_2')),
    );
    final metadataText = tester.widget<Text>(
      find.byKey(const ValueKey<String>('tool_output_diff_text_0')),
    );

    expect(addText.style?.color, isNotNull);
    expect(addContainer.color, isNotNull);
    expect(removeText.style?.color, isNotNull);
    expect(removeContainer.color, isNotNull);
    expect(hunkText.style?.color, isNotNull);
    expect(hunkContainer.color, isNotNull);
    expect(metadataText.style?.color, isNotNull);
  });

  testWidgets(
    'renders colorized diff from apply_patch input when output is empty',
    (tester) async {
      const patchInput = '''*** Begin Patch
*** Update File: lib/main.dart
@@
-old line
+new line
*** End Patch''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageWidget(
              message: AssistantMessage(
                id: 'msg_diff_input_1',
                sessionId: 'ses_diff',
                time: DateTime.fromMillisecondsSinceEpoch(1000),
                parts: <MessagePart>[
                  ToolPart(
                    id: 'tool_diff_input_1',
                    messageId: 'msg_diff_input_1',
                    sessionId: 'ses_diff',
                    callId: 'call_diff_input_1',
                    tool: 'apply_patch',
                    state: ToolStateCompleted(
                      input: const <String, dynamic>{'patch': patchInput},
                      output: '',
                      time: ToolTime(
                        start: DateTime.fromMillisecondsSinceEpoch(1000),
                        end: DateTime.fromMillisecondsSinceEpoch(1100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show more').first);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('diff_line_container_0')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('tool_output_diff_container_0')),
        findsOneWidget,
      );
    },
  );

  testWidgets('colorizes apply_patch input section when output is success', (
    tester,
  ) async {
    const patchInput = '''*** Begin Patch
*** Update File: lib/main.dart
@@
-old line
+new line
*** End Patch''';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_diff_input_success_1',
              sessionId: 'ses_diff',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: <MessagePart>[
                ToolPart(
                  id: 'tool_diff_input_success_1',
                  messageId: 'msg_diff_input_success_1',
                  sessionId: 'ses_diff',
                  callId: 'call_diff_input_success_1',
                  tool: 'apply_patch',
                  state: ToolStateCompleted(
                    input: const <String, dynamic>{'patchText': patchInput},
                    output: 'Success. Updated the following files:\nM file.txt',
                    time: ToolTime(
                      start: DateTime.fromMillisecondsSinceEpoch(1000),
                      end: DateTime.fromMillisecondsSinceEpoch(1100),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show more').first);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('tool_input_diff_container_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('tool_input_diff_text_3')),
      findsOneWidget,
    );

    final removeLineContainer = tester.widget<Container>(
      find.byKey(const ValueKey<String>('tool_input_diff_container_3')),
    );
    final addLineContainer = tester.widget<Container>(
      find.byKey(const ValueKey<String>('tool_input_diff_container_4')),
    );

    expect(removeLineContainer.color, isNotNull);
    expect(addLineContainer.color, isNotNull);
  });

  testWidgets('uses MediaQuery textScaler in expanded diff lines', (
    tester,
  ) async {
    const diffOutput = '''--- file.dart
+++ file.dart
@@ -1,2 +1,3 @@
 context
-old line
+new line''';
    const expectedScaler = TextScaler.linear(1.2);
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(
            context,
          ).copyWith(textScaler: expectedScaler);
          return MediaQuery(data: mediaQuery, child: child!);
        },
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_diff_scaler',
              sessionId: 'ses_diff',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: <MessagePart>[
                ToolPart(
                  id: 'tool_diff_scaler',
                  messageId: 'msg_diff_scaler',
                  sessionId: 'ses_diff',
                  callId: 'call_diff_scaler',
                  tool: 'apply_patch',
                  state: ToolStateCompleted(
                    input: const <String, dynamic>{},
                    output: diffOutput,
                    time: ToolTime(
                      start: DateTime.fromMillisecondsSinceEpoch(1000),
                      end: DateTime.fromMillisecondsSinceEpoch(1100),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Future<void> expandIfNeeded() async {
      final showMore = find.text('Show more');
      if (showMore.evaluate().isNotEmpty) {
        await tester.tap(showMore);
        await tester.pumpAndSettle();
      }
    }

    await expandIfNeeded();

    final scaledHeight = tester
        .getSize(
          find.byKey(const ValueKey<String>('tool_output_diff_container_5')),
        )
        .height;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_diff_scaler',
              sessionId: 'ses_diff',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: <MessagePart>[
                ToolPart(
                  id: 'tool_diff_scaler',
                  messageId: 'msg_diff_scaler',
                  sessionId: 'ses_diff',
                  callId: 'call_diff_scaler',
                  tool: 'apply_patch',
                  state: ToolStateCompleted(
                    input: const <String, dynamic>{},
                    output: diffOutput,
                    time: ToolTime(
                      start: DateTime.fromMillisecondsSinceEpoch(1000),
                      end: DateTime.fromMillisecondsSinceEpoch(1100),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await expandIfNeeded();

    final defaultHeight = tester
        .getSize(
          find.byKey(const ValueKey<String>('tool_output_diff_container_5')),
        )
        .height;

    expect(scaledHeight, greaterThan(defaultHeight));
  });

  testWidgets('detects diff in bash git diff via heuristic', (tester) async {
    const gitDiff = '''diff --git a/lib/main.dart b/lib/main.dart
--- a/lib/main.dart
+++ b/lib/main.dart
@@ -1,1 +1,2 @@
-old
+new''';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_diff_2',
              sessionId: 'ses_diff',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: <MessagePart>[
                ToolPart(
                  id: 'tool_diff_2',
                  messageId: 'msg_diff_2',
                  sessionId: 'ses_diff',
                  callId: 'call_diff_2',
                  tool: 'bash', // Não é apply_patch, detecta via heurística
                  state: ToolStateCompleted(
                    input: const <String, dynamic>{'command': 'git diff'},
                    output: gitDiff,
                    time: ToolTime(
                      start: DateTime.fromMillisecondsSinceEpoch(1000),
                      end: DateTime.fromMillisecondsSinceEpoch(1150),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();

    // Deve colorizar mesmo sendo bash
    expect(
      find.byKey(const ValueKey<String>('diff_line_container_0')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('tool_output_diff_container_0')),
      findsOneWidget,
    );
  });

  testWidgets('does not colorize normal bash output', (tester) async {
    const plainOutput = 'file1.txt\nfile2.txt';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_diff_3',
              sessionId: 'ses_diff',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: <MessagePart>[
                ToolPart(
                  id: 'tool_diff_3',
                  messageId: 'msg_diff_3',
                  sessionId: 'ses_diff',
                  callId: 'call_diff_3',
                  tool: 'bash',
                  state: ToolStateCompleted(
                    input: const <String, dynamic>{'command': 'ls'},
                    output: plainOutput,
                    time: ToolTime(
                      start: DateTime.fromMillisecondsSinceEpoch(1000),
                      end: DateTime.fromMillisecondsSinceEpoch(1050),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Texto plano, sem expansão necessária (2 linhas)
    expect(find.text(plainOutput), findsOneWidget);
    expect(find.text('Show more'), findsNothing);
  });

  testWidgets('preserves content when collapsing and expanding diff', (
    tester,
  ) async {
    const diff = '@@ -1,1 +1,2 @@\n-old\n+new';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_diff_4',
              sessionId: 'ses_diff',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: <MessagePart>[
                ToolPart(
                  id: 'tool_diff_4',
                  messageId: 'msg_diff_4',
                  sessionId: 'ses_diff',
                  callId: 'call_diff_4',
                  tool: 'edit',
                  state: ToolStateCompleted(
                    input: const <String, dynamic>{},
                    output: diff,
                    time: ToolTime(
                      start: DateTime.fromMillisecondsSinceEpoch(1000),
                      end: DateTime.fromMillisecondsSinceEpoch(1080),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Expandir
    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();
    expect(find.text('Show less'), findsOneWidget);

    // Colapsar
    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();
    expect(find.text('Show more'), findsOneWidget);
  });

  testWidgets('renders colorized diff for edit tool', (tester) async {
    const editDiff = '''diff --git a/test.dart b/test.dart
index abc123..def456 100644
--- a/test.dart
+++ b/test.dart
@@ -10,5 +10,6 @@
 normal line
-removed line
+added line
 another normal line''';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_diff_5',
              sessionId: 'ses_diff',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: <MessagePart>[
                ToolPart(
                  id: 'tool_diff_5',
                  messageId: 'msg_diff_5',
                  sessionId: 'ses_diff',
                  callId: 'call_diff_5',
                  tool: 'edit',
                  state: ToolStateCompleted(
                    input: const <String, dynamic>{},
                    output: editDiff,
                    time: ToolTime(
                      start: DateTime.fromMillisecondsSinceEpoch(1000),
                      end: DateTime.fromMillisecondsSinceEpoch(1120),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Expandir
    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();

    // Diff por linha deve estar presente
    expect(
      find.byKey(const ValueKey<String>('diff_line_container_0')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('tool_output_diff_container_0')),
      findsOneWidget,
    );
  });

  testWidgets('builds synthetic diff for edit tool when output is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_edit_input',
              sessionId: 'ses_diff',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: <MessagePart>[
                ToolPart(
                  id: 'tool_edit_input',
                  messageId: 'msg_edit_input',
                  sessionId: 'ses_diff',
                  callId: 'call_edit_input',
                  tool: 'edit',
                  state: ToolStateCompleted(
                    input: const <String, dynamic>{
                      'file_path': 'lib/sample.dart',
                      'old_string': 'line old',
                      'new_string': 'line new',
                    },
                    output: '',
                    time: ToolTime(
                      start: DateTime.fromMillisecondsSinceEpoch(1000),
                      end: DateTime.fromMillisecondsSinceEpoch(1100),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('diff_line_container_0')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('tool_output_diff_container_0')),
      findsOneWidget,
    );
  });

  testWidgets('hides thinking bubbles when toggle is disabled', (
    WidgetTester tester,
  ) async {
    final message = AssistantMessage(
      id: 'msg_hide_thinking',
      sessionId: 'ses_hide_thinking',
      time: DateTime.fromMillisecondsSinceEpoch(1000),
      parts: const <MessagePart>[
        ReasoningPart(
          id: 'part_reasoning_hide',
          messageId: 'msg_hide_thinking',
          sessionId: 'ses_hide_thinking',
          text: 'line 1\nline 2\nline 3',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(message: message, showThinkingBubbles: false),
        ),
      ),
    );

    expect(find.text('Thinking Process'), findsNothing);
    expect(
      find.byKey(
        const ValueKey<String>(
          'thinking_content_text_msg_hide_thinking::part_reasoning_hide',
        ),
      ),
      findsNothing,
    );
  });

  testWidgets('hides tool call bubbles when toggle is disabled', (
    WidgetTester tester,
  ) async {
    final message = AssistantMessage(
      id: 'msg_hide_tool',
      sessionId: 'ses_hide_tool',
      time: DateTime.fromMillisecondsSinceEpoch(1000),
      parts: <MessagePart>[
        ToolPart(
          id: 'part_tool_hide',
          messageId: 'msg_hide_tool',
          sessionId: 'ses_hide_tool',
          callId: 'call_hide_tool',
          tool: 'bash',
          state: ToolStateCompleted(
            input: const <String, dynamic>{'cmd': 'pwd'},
            output: '/tmp',
            time: ToolTime(
              start: DateTime.fromMillisecondsSinceEpoch(1000),
              end: DateTime.fromMillisecondsSinceEpoch(1200),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(message: message, showToolCallBubbles: false),
        ),
      ),
    );

    expect(find.text('Running command'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('tool_command_text')),
      findsNothing,
    );
    expect(find.text('Assistant'), findsNothing);
  });

  testWidgets('hides patch bubbles when tool call toggle is disabled', (
    WidgetTester tester,
  ) async {
    final message = AssistantMessage(
      id: 'msg_hide_patch',
      sessionId: 'ses_hide_patch',
      time: DateTime.fromMillisecondsSinceEpoch(1000),
      parts: const <MessagePart>[
        PatchPart(
          id: 'part_patch_hide',
          messageId: 'msg_hide_patch',
          sessionId: 'ses_hide_patch',
          files: <String>['lib/main.dart'],
          hash: 'abc123',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(message: message, showToolCallBubbles: false),
        ),
      ),
    );

    expect(find.text('Patch'), findsNothing);
    expect(find.text('Assistant'), findsNothing);
  });

  testWidgets('hides todowrite and todoread tool calls and empty bubble', (
    WidgetTester tester,
  ) async {
    final message = AssistantMessage(
      id: 'msg_hide_todo',
      sessionId: 'ses_hide_todo',
      time: DateTime.fromMillisecondsSinceEpoch(1000),
      parts: <MessagePart>[
        ToolPart(
          id: 'part_todo_write',
          messageId: 'msg_hide_todo',
          sessionId: 'ses_hide_todo',
          callId: 'call_todo_write',
          tool: 'todowrite',
          state: ToolStateCompleted(
            input: const <String, dynamic>{'tasks': []},
            output: 'ok',
            time: ToolTime(
              start: DateTime.fromMillisecondsSinceEpoch(1000),
              end: DateTime.fromMillisecondsSinceEpoch(1200),
            ),
          ),
        ),
        ToolPart(
          id: 'part_todo_read',
          messageId: 'msg_hide_todo',
          sessionId: 'ses_hide_todo',
          callId: 'call_todo_read',
          tool: 'todoread',
          state: ToolStateCompleted(
            input: const <String, dynamic>{},
            output: '[]',
            time: ToolTime(
              start: DateTime.fromMillisecondsSinceEpoch(1200),
              end: DateTime.fromMillisecondsSinceEpoch(1400),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChatMessageWidget(message: message)),
      ),
    );

    expect(find.text('Updating task list'), findsNothing);
    expect(find.text('Assistant'), findsNothing);
  });

  testWidgets('expanded tool output caps content viewport height', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(tester.view.reset);

    final longOutput = List<String>.generate(
      120,
      (index) => 'output line $index',
    ).join('\n');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_tool_height_cap',
              sessionId: 'ses_tool_height_cap',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: <MessagePart>[
                ToolPart(
                  id: 'part_tool_height_cap',
                  messageId: 'msg_tool_height_cap',
                  sessionId: 'ses_tool_height_cap',
                  callId: 'call_tool_height_cap',
                  tool: 'bash',
                  state: ToolStateCompleted(
                    input: const <String, dynamic>{'command': 'cat big.log'},
                    output: longOutput,
                    time: ToolTime(
                      start: DateTime.fromMillisecondsSinceEpoch(1000),
                      end: DateTime.fromMillisecondsSinceEpoch(1200),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('tool_content_toggle_button')),
    );
    await tester.pumpAndSettle();

    final viewportSize = tester.getSize(
      find.byKey(const ValueKey<String>('tool_content_expanded_scroll')),
    );
    expect(viewportSize.height, lessThanOrEqualTo(300));
  });

  testWidgets('truncates oversized tool payload to keep UI responsive', (
    WidgetTester tester,
  ) async {
    final hugeOutput = List<String>.filled(12000, 'line payload').join('\n');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_huge_tool',
              sessionId: 'ses_huge_tool',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: <MessagePart>[
                ToolPart(
                  id: 'part_huge_tool',
                  messageId: 'msg_huge_tool',
                  sessionId: 'ses_huge_tool',
                  callId: 'call_huge',
                  tool: 'bash',
                  state: ToolStateCompleted(
                    input: const <String, dynamic>{'command': 'cat huge.log'},
                    output: hugeOutput,
                    time: ToolTime(
                      start: DateTime.fromMillisecondsSinceEpoch(1000),
                      end: DateTime.fromMillisecondsSinceEpoch(1200),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.textContaining('Large tool output preview truncated'),
      findsOneWidget,
    );
  });

  testWidgets('shows feedback for invalid markdown link format', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: AssistantMessage(
              id: 'msg_link_open_failure',
              sessionId: 'ses_link_open_failure',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_link_open_failure',
                  messageId: 'msg_link_open_failure',
                  sessionId: 'ses_link_open_failure',
                  text: '[Broken link](://invalid)',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Broken link'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid link format'), findsOneWidget);
  });
}
