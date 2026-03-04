import 'dart:async';

import 'package:codewalk/domain/entities/chat_session.dart';
import 'package:codewalk/presentation/providers/chat_provider.dart';
import 'package:codewalk/presentation/widgets/chat_session_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  ChatSession session({bool shared = false, DateTime? archivedAt}) {
    return ChatSession(
      id: 'ses_1',
      workspaceId: 'default',
      time: DateTime.fromMillisecondsSinceEpoch(1000),
      title: 'Session 1',
      shared: shared,
      shareUrl: shared ? 'https://share.mock/s/ses_1' : null,
      archivedAt: archivedAt,
    );
  }

  testWidgets('rename menu action calls rename callback', (tester) async {
    String? renamedTitle;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatSessionList(
            sessions: <ChatSession>[session()],
            onSessionRenamed: (item, title) async {
              renamedTitle = title;
              return true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Symbols.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Renamed title');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(renamedTitle, 'Renamed title');
  });

  testWidgets('share toggle action calls callback', (tester) async {
    var calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatSessionList(
            sessions: <ChatSession>[session(shared: false)],
            onSessionShareToggled: (item) async {
              calls += 1;
              return true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Symbols.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();

    expect(calls, 1);
  });

  testWidgets('pin action calls callback and shows pinned indicator', (
    tester,
  ) async {
    var calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatSessionList(
            sessions: <ChatSession>[session()],
            pinnedSessionIds: const <String>{'ses_1'},
            onSessionPinToggled: (item) async {
              calls += 1;
            },
          ),
        ),
      ),
    );

    expect(find.byIcon(Symbols.push_pin), findsOneWidget);

    await tester.tap(find.byIcon(Symbols.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unpin'));
    await tester.pumpAndSettle();

    expect(calls, 1);
  });

  testWidgets('archive and delete actions call callbacks', (tester) async {
    var archivedCalls = 0;
    var deleteCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatSessionList(
            sessions: <ChatSession>[session()],
            onSessionArchiveToggled: (item, archived) async {
              archivedCalls += archived ? 1 : 0;
              return true;
            },
            onSessionDeleted: (item) async {
              deleteCalls += 1;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Symbols.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(archivedCalls, 1);

    await tester.tap(find.byIcon(Symbols.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(deleteCalls, 1);
  });

  testWidgets('renders loading indicator for active session rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatSessionList(
            sessions: <ChatSession>[session()],
            isSessionActive: (sessionId) => sessionId == 'ses_1',
          ),
        ),
      ),
    );

    expect(find.byIcon(Symbols.sync_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.chat), findsNothing);
  });

  testWidgets('mobile layout uses floating badge instead of leading icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatSessionList(
            sessions: <ChatSession>[session()],
            isMobileLayout: true,
            sessionAttentionFor: (_) =>
                const SessionAttentionState(isActive: true),
          ),
        ),
      ),
    );

    expect(find.byType(CircleAvatar), findsNothing);
    expect(
      find.byKey(
        const ValueKey<String>('chat_session_attention_badge_active_ses_1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows pending-interaction floating badge when needed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatSessionList(
            sessions: <ChatSession>[session()],
            isMobileLayout: true,
            sessionAttentionFor: (_) =>
                const SessionAttentionState(hasPendingInteraction: true),
          ),
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>(
          'chat_session_attention_badge_pendingInteraction_ses_1',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('ignores repeated taps while session selection is in flight', (
    tester,
  ) async {
    var selectionCalls = 0;
    final inFlightSelection = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatSessionList(
            sessions: <ChatSession>[session()],
            onSessionSelected: (_) async {
              selectionCalls += 1;
              await inFlightSelection.future;
            },
          ),
        ),
      ),
    );

    final tileFinder = find.byKey(
      const ValueKey<String>('chat_session_tile_ses_1'),
    );

    await tester.tap(tileFinder);
    await tester.pump();
    await tester.tap(tileFinder);
    await tester.pump();

    expect(selectionCalls, 1);

    inFlightSelection.complete();
    await tester.pumpAndSettle();

    await tester.tap(tileFinder);
    await tester.pump();

    expect(selectionCalls, 2);
  });

  testWidgets('renders child sessions as collapsed sub-conversations', (
    tester,
  ) async {
    final parent = ChatSession(
      id: 'ses_parent',
      workspaceId: 'default',
      time: DateTime.fromMillisecondsSinceEpoch(2000),
      title: 'Parent Session',
    );
    final child = ChatSession(
      id: 'ses_child',
      workspaceId: 'default',
      time: DateTime.fromMillisecondsSinceEpoch(3000),
      title: 'Child Session',
      parentId: 'ses_parent',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatSessionList(sessions: <ChatSession>[parent, child]),
        ),
      ),
    );

    expect(find.text('Child Session'), findsNothing);
    expect(find.text('1 sub-conversation'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('chat_session_toggle_ses_parent')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('chat_session_tile_ses_child')),
      findsOneWidget,
    );
    expect(find.text('Child Session'), findsOneWidget);
  });

  testWidgets('lazily builds long session lists', (tester) async {
    final sessions = List<ChatSession>.generate(
      220,
      (index) => ChatSession(
        id: 'ses_$index',
        workspaceId: 'default',
        time: DateTime.fromMillisecondsSinceEpoch(1000 + index),
        title: 'Session $index',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 420,
            child: ChatSessionList(sessions: sessions),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('chat_session_tile_ses_219')),
      findsNothing,
    );

    for (var attempt = 0; attempt < 42; attempt += 1) {
      if (find
          .byKey(const ValueKey<String>('chat_session_tile_ses_219'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
      await tester.drag(find.byType(ListView).first, const Offset(0, -760));
      await tester.pumpAndSettle();
    }

    expect(
      find.byKey(const ValueKey<String>('chat_session_tile_ses_219')),
      findsOneWidget,
    );
  });

  testWidgets('desktop layout applies compact vertical tile padding', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatSessionList(
            sessions: <ChatSession>[session()],
            isMobileLayout: false,
            verticalTilePadding: 1,
          ),
        ),
      ),
    );

    final tilePadding = tester.widget<Padding>(
      find.byKey(const ValueKey<String>('chat_session_tile_ses_1')),
    );
    expect(tilePadding.padding, const EdgeInsets.symmetric(vertical: 1));
  });

  testWidgets('mobile layout keeps default vertical tile padding', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatSessionList(
            sessions: <ChatSession>[session()],
            isMobileLayout: true,
          ),
        ),
      ),
    );

    final tilePadding = tester.widget<Padding>(
      find.byKey(const ValueKey<String>('chat_session_tile_ses_1')),
    );
    expect(tilePadding.padding, const EdgeInsets.symmetric(vertical: 3));
  });
}
