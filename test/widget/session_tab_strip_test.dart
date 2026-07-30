import 'package:codewalk/domain/entities/chat_realtime.dart';
import 'package:codewalk/domain/entities/project.dart';
import 'package:codewalk/presentation/providers/chat_provider.dart';
import 'package:codewalk/presentation/widgets/project_icon.dart';
import 'package:codewalk/presentation/widgets/session_tab_strip.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../support/pump_localized_app.dart';

void main() {
  testWidgets('stays absent without tabs', (tester) async {
    await tester.pumpWidget(_app(tabs: const <SessionTabRecord>[]));

    expect(
      find.byKey(const ValueKey<String>('session_tab_strip')),
      findsNothing,
    );
  });

  testWidgets('exposes selected title semantics and keyboard activation', (
    tester,
  ) async {
    final tab = _tab('alpha', title: 'Alpha session', isSelected: true);
    final activated = <SessionTabIdentity>[];

    await tester.pumpWidget(
      _app(tabs: <SessionTabRecord>[tab], onActivate: activated.add),
    );
    await tester.pump();

    final identityKey = sessionTabIdentityKey(tab.identity);
    final activateFinder = find.byKey(
      ValueKey<String>('session_tab_activate_$identityKey'),
    );
    expect(find.byTooltip('Alpha session'), findsOneWidget);
    expect(
      tester
          .widget<Tooltip>(find.byTooltip('Alpha session'))
          .excludeFromSemantics,
      isTrue,
    );
    expect(find.byIcon(Symbols.folder_open), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.selected == true &&
            widget.properties.label == 'Chat session: Alpha session' &&
            widget.properties.onTap != null,
      ),
      findsOneWidget,
    );

    final activation = tester.widget<InkWell>(activateFinder);
    activation.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(activated, <SessionTabIdentity>[tab.identity]);
  });

  testWidgets('prioritizes error attention without replacing retry status', (
    tester,
  ) async {
    final tab = _tab(
      'attention',
      title: 'Needs review',
      status: SessionStatusType.retry,
      pendingQuestionIds: const <String>['question_1'],
      completionToken: 'completion_1',
      errorToken: 'error_1',
    );
    final identityKey = sessionTabIdentityKey(tab.identity);

    await tester.pumpWidget(_app(tabs: <SessionTabRecord>[tab]));

    expect(
      find.byKey(ValueKey<String>('session_tab_leading_error_$identityKey')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey<String>('session_tab_leading_question_$identityKey')),
      findsNothing,
    );
    expect(
      find.byKey(
        ValueKey<String>('session_tab_leading_completion_$identityKey'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey<String>('session_tab_busy_retry_$identityKey')),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                '"Needs review" has an error. Status: Retry',
      ),
      findsOneWidget,
    );
  });

  testWidgets('discovers icons only for open projects', (tester) async {
    final tab = _tab('project');
    final project = Project(
      id: 'proj_project',
      name: 'Project',
      path: tab.identity.directory,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );

    await tester.pumpWidget(
      _app(tabs: <SessionTabRecord>[tab], projects: <Project>[project]),
    );

    expect(
      tester.widget<ProjectIcon>(find.byType(ProjectIcon)).autoDiscover,
      isFalse,
    );

    await tester.pumpWidget(
      _app(
        tabs: <SessionTabRecord>[tab],
        projects: <Project>[project],
        openProjectIds: <String>{project.id},
      ),
    );

    expect(
      tester.widget<ProjectIcon>(find.byType(ProjectIcon)).autoDiscover,
      isTrue,
    );
  });

  testWidgets('scrolls overflow and keeps the selected tab visible', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final tabs = List<SessionTabRecord>.generate(
      6,
      (index) => _tab(
        'session_$index',
        title: 'Long session title $index',
        isSelected: index == 5,
      ),
    );

    await tester.pumpWidget(_app(tabs: tabs, width: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    final scrollViewFinder = find.byKey(
      const ValueKey<String>('session_tab_strip_scroll_view'),
    );
    final scrollableFinder = find.descendant(
      of: scrollViewFinder,
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollableFinder).position;
    expect(position.maxScrollExtent, greaterThan(0));
    expect(position.pixels, greaterThan(0));

    final viewportRect = tester.getRect(scrollViewFinder);
    final selectedRect = tester.getRect(
      find.byKey(
        ValueKey<String>(
          'session_tab_${sessionTabIdentityKey(tabs.last.identity)}',
        ),
      ),
    );
    expect(selectedRect.left, greaterThanOrEqualTo(viewportRect.left - 0.5));
    expect(selectedRect.right, lessThanOrEqualTo(viewportRect.right + 0.5));

    final title = tester.widget<Text>(
      find.byKey(
        ValueKey<String>(
          'session_tab_title_${sessionTabIdentityKey(tabs.last.identity)}',
        ),
      ),
    );
    expect(title.maxLines, 1);
    expect(title.overflow, TextOverflow.ellipsis);

    position.jumpTo(0);
    await tester.pump();
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(scrollViewFinder),
        scrollDelta: const Offset(0, 80),
      ),
    );
    await tester.pump();
    expect(position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('close never activates a tab and focuses its neighbor', (
    tester,
  ) async {
    final first = _tab('first', isSelected: true);
    final second = _tab('second');
    final third = _tab('third');
    var tabs = <SessionTabRecord>[first, second, third];
    final closed = <SessionTabIdentity>[];
    final activated = <SessionTabIdentity>[];

    await tester.pumpWidget(
      localizedMaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SessionTabStrip(
                tabs: tabs,
                projects: const [],
                openProjectIds: const <String>{},
                isCompact: false,
                onActivate: (tab) => activated.add(tab.identity),
                onClose: (tab) {
                  closed.add(tab.identity);
                  setState(() {
                    tabs = tabs
                        .where(
                          (candidate) => candidate.identity != tab.identity,
                        )
                        .toList(growable: false);
                  });
                },
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(
        ValueKey<String>(
          'session_tab_close_${sessionTabIdentityKey(second.identity)}',
        ),
      ),
    );
    await tester.pump();

    expect(closed, <SessionTabIdentity>[second.identity]);
    expect(activated, isEmpty);
    expect(
      tester
          .widget<InkWell>(
            find.byKey(
              ValueKey<String>(
                'session_tab_activate_${sessionTabIdentityKey(third.identity)}',
              ),
            ),
          )
          .focusNode
          ?.hasFocus,
      isTrue,
    );

    await tester.tap(
      find.byKey(
        ValueKey<String>(
          'session_tab_close_${sessionTabIdentityKey(first.identity)}',
        ),
      ),
    );
    await tester.pump();

    expect(closed, <SessionTabIdentity>[second.identity, first.identity]);
    expect(activated, isEmpty);
    expect(
      tester
          .widget<InkWell>(
            find.byKey(
              ValueKey<String>(
                'session_tab_activate_${sessionTabIdentityKey(third.identity)}',
              ),
            ),
          )
          .focusNode
          ?.hasFocus,
      isTrue,
    );
  });

  test('close fallback prefers right, then left', () {
    final first = _tab('first');
    final second = _tab('second');
    final third = _tab('third');
    final tabs = <SessionTabRecord>[first, second, third];

    expect(sessionTabCloseFallback(tabs, first.identity), same(second));
    expect(sessionTabCloseFallback(tabs, second.identity), same(third));
    expect(sessionTabCloseFallback(tabs, third.identity), same(second));
    expect(
      sessionTabCloseFallback(<SessionTabRecord>[first], first.identity),
      isNull,
    );
    expect(sessionTabCloseFallback(tabs, _identity('missing')), isNull);
  });
}

Widget _app({
  required List<SessionTabRecord> tabs,
  List<Project> projects = const <Project>[],
  Set<String> openProjectIds = const <String>{},
  ValueChanged<SessionTabIdentity>? onActivate,
  ValueChanged<SessionTabIdentity>? onClose,
  double width = 800,
}) {
  return localizedMaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: SessionTabStrip(
            tabs: tabs,
            projects: projects,
            openProjectIds: openProjectIds,
            isCompact: false,
            onActivate: (tab) => onActivate?.call(tab.identity),
            onClose: (tab) => onClose?.call(tab.identity),
          ),
        ),
      ),
    ),
  );
}

SessionTabRecord _tab(
  String id, {
  String? title,
  SessionStatusType status = SessionStatusType.idle,
  bool isSelected = false,
  List<String> pendingQuestionIds = const <String>[],
  String? completionToken,
  String? errorToken,
}) {
  return SessionTabRecord(
    identity: _identity(id),
    title: title ?? 'Session $id',
    lastOpenedAtMs: 0,
    serverUpdatedAtMs: 0,
    status: status,
    pendingQuestionIds: pendingQuestionIds,
    completionToken: completionToken,
    errorToken: errorToken,
    isSelected: isSelected,
  );
}

SessionTabIdentity _identity(String id) {
  return SessionTabIdentity(
    serverId: 'srv_test',
    directory: '/repo/$id',
    sessionId: 'ses_$id',
  );
}
