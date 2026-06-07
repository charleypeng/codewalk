import 'package:codewalk/domain/entities/chat_realtime.dart';
import 'package:codewalk/presentation/widgets/permission_request_card.dart';
import 'package:codewalk/presentation/widgets/question_request_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_localized_app.dart';

void main() {
  testWidgets('PermissionRequestCard dispatches selected decision', (
    WidgetTester tester,
  ) async {
    String? decided;
    const request = ChatPermissionRequest(
      id: 'perm_1',
      sessionId: 'ses_1',
      permission: 'edit',
      patterns: <String>['lib/**'],
      always: <String>[],
      metadata: <String, dynamic>{},
    );

    await tester.pumpWidget(
      localizedMaterialApp(
        home: Scaffold(
          body: PermissionRequestCard(
            request: request,
            busy: false,
            originBadgeLabel: 'Child Session',
            onDecide: (reply) => decided = reply,
          ),
        ),
      ),
    );

    expect(find.textContaining('Permission request:'), findsOneWidget);
    expect(find.text('Child Session'), findsOneWidget);
    await tester.tap(find.text('Allow Once'));
    await tester.pump();
    expect(decided, 'once');
  });

  testWidgets('QuestionRequestCard submits selected answers', (
    WidgetTester tester,
  ) async {
    List<List<String>>? submitted;
    var rejected = false;
    const request = ChatQuestionRequest(
      id: 'q_1',
      sessionId: 'ses_1',
      questions: <ChatQuestionInfo>[
        ChatQuestionInfo(
          question: 'Proceed?',
          header: 'Confirm',
          options: <ChatQuestionOption>[
            ChatQuestionOption(label: 'Yes', description: 'Continue'),
            ChatQuestionOption(label: 'No', description: 'Stop'),
          ],
          multiple: false,
          custom: false,
        ),
      ],
    );

    await tester.pumpWidget(
      localizedMaterialApp(
        home: Scaffold(
          body: QuestionRequestCard(
            request: request,
            busy: false,
            originBadgeLabel: 'Child Session',
            onSubmit: (answers) => submitted = answers,
            onReject: () => rejected = true,
          ),
        ),
      ),
    );

    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Child Session'), findsOneWidget);
    await tester.tap(find.text('Yes'));
    await tester.pump();
    await tester.tap(find.text('Review Answers'));
    await tester.pump();
    await tester.tap(find.text('Submit Answers'));
    await tester.pump();

    expect(submitted, isNotNull);
    expect(submitted, const <List<String>>[
      <String>['Yes'],
    ]);

    await tester.tap(find.text('Reject'));
    await tester.pump();
    expect(find.text('Reopen'), findsOneWidget);
    expect(find.text('Confirm Reject'), findsOneWidget);
    expect(
      find.textContaining('Question group marked as rejected'),
      findsOneWidget,
    );
    expect(rejected, isFalse);

    await tester.tap(find.text('Reopen'));
    await tester.pump();
    expect(find.text('Reopen'), findsNothing);

    await tester.tap(find.text('Reject'));
    await tester.pump();
    await tester.tap(find.text('Confirm Reject'));
    await tester.pump();
    expect(rejected, isTrue);
  });

  testWidgets('QuestionRequestCard supports desktop keyboard shortcuts', (
    WidgetTester tester,
  ) async {
    List<List<String>>? submitted;
    const request = ChatQuestionRequest(
      id: 'q_keyboard_1',
      sessionId: 'ses_1',
      questions: <ChatQuestionInfo>[
        ChatQuestionInfo(
          question: 'Pick one option',
          header: 'Keyboard',
          options: <ChatQuestionOption>[
            ChatQuestionOption(label: 'Alpha', description: 'Option alpha'),
            ChatQuestionOption(label: 'Beta', description: 'Option beta'),
          ],
          multiple: false,
          custom: false,
        ),
      ],
    );

    await tester.pumpWidget(
      localizedMaterialApp(
        home: Scaffold(
          body: QuestionRequestCard(
            request: request,
            busy: false,
            onSubmit: (answers) => submitted = answers,
            onReject: () {},
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();
    expect(find.text('Reopen'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();
    expect(find.text('Review Answers'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();
    expect(find.text('Submit Answers'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();

    expect(submitted, const <List<String>>[
      <String>['Alpha'],
    ]);
  });

  testWidgets('QuestionRequestCard ignores shortcuts while busy', (
    WidgetTester tester,
  ) async {
    List<List<String>>? submitted;
    var rejected = false;
    const request = ChatQuestionRequest(
      id: 'q_keyboard_busy_1',
      sessionId: 'ses_1',
      questions: <ChatQuestionInfo>[
        ChatQuestionInfo(
          question: 'Pick one option',
          header: 'Keyboard',
          options: <ChatQuestionOption>[
            ChatQuestionOption(label: 'Alpha', description: 'Option alpha'),
            ChatQuestionOption(label: 'Beta', description: 'Option beta'),
          ],
          multiple: false,
          custom: false,
        ),
      ],
    );

    await tester.pumpWidget(
      localizedMaterialApp(
        home: Scaffold(
          body: QuestionRequestCard(
            request: request,
            busy: true,
            onSubmit: (answers) => submitted = answers,
            onReject: () => rejected = true,
          ),
        ),
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();

    expect(find.text('Reopen'), findsNothing);
    expect(find.text('Review your answers before submitting.'), findsNothing);
    expect(submitted, isNull);
    expect(rejected, isFalse);
  });
}
