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
    final closed = <SessionTabIdentity>[];

    await tester.pumpWidget(
      _app(
        tabs: <SessionTabRecord>[tab],
        onActivate: activated.add,
        onClose: closed.add,
      ),
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
    final tabSemantics = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.selected == true &&
            widget.properties.label == 'Chat session: Alpha session' &&
            widget.properties.onTap != null &&
            widget.properties.onLongPress != null,
      ),
    );
    expect(
      tabSemantics.properties.customSemanticsActions?.keys.map(
        (action) => action.label,
      ),
      contains('Session actions'),
    );

    final activation = tester.widget<InkWell>(activateFinder);
    activation.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(activated, <SessionTabIdentity>[tab.identity]);

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();

    final closeFinder = find.byKey(
      ValueKey<String>('session_tab_close_$identityKey'),
    );
    expect(closeFinder, findsNothing);
    expect(closed, <SessionTabIdentity>[tab.identity]);
  });

  testWidgets('exposes close as a permanent semantics action', (tester) async {
    final tab = _tab('alpha', title: 'Alpha session', isSelected: true);
    final closed = <SessionTabIdentity>[];
    final identityKey = sessionTabIdentityKey(tab.identity);

    await tester.pumpWidget(
      _app(tabs: <SessionTabRecord>[tab], onClose: closed.add),
    );
    await tester.pump();

    expect(
      find.byKey(ValueKey<String>('session_tab_close_$identityKey')),
      findsNothing,
    );
    final tabSemantics = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Chat session: Alpha session' &&
            widget.properties.onDismiss != null,
      ),
    );

    tabSemantics.properties.onDismiss!.call();
    await tester.pump();

    expect(closed, <SessionTabIdentity>[tab.identity]);
  });

  testWidgets('keyboard traversal moves directly between tabs', (tester) async {
    final first = _tab('first', isSelected: true);
    final second = _tab('second');
    final activated = <SessionTabIdentity>[];

    await tester.pumpWidget(
      _app(tabs: <SessionTabRecord>[first, second], onActivate: activated.add),
    );
    await tester.pump();

    final firstKey = sessionTabIdentityKey(first.identity);
    final secondKey = sessionTabIdentityKey(second.identity);
    tester
        .widget<InkWell>(
          find.byKey(ValueKey<String>('session_tab_activate_$firstKey')),
        )
        .focusNode!
        .requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(
      tester
          .widget<InkWell>(
            find.byKey(ValueKey<String>('session_tab_activate_$secondKey')),
          )
          .focusNode
          ?.hasFocus,
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(activated, <SessionTabIdentity>[second.identity]);
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
      find.descendant(
        of: find.byKey(ValueKey<String>('session_tab_leading_$identityKey')),
        matching: find.byKey(
          ValueKey<String>('session_tab_busy_retry_$identityKey'),
        ),
      ),
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

  testWidgets('overlays busy status on the project icon lower right', (
    tester,
  ) async {
    final idle = _tab('working', title: 'Working session');
    final identityKey = sessionTabIdentityKey(idle.identity);
    final titleFinder = find.byKey(
      ValueKey<String>('session_tab_title_$identityKey'),
    );
    final projectIconFinder = find.byKey(
      ValueKey<String>('session_tab_project_icon_$identityKey'),
    );
    final badgeFinder = find.byKey(
      ValueKey<String>('session_tab_busy_busy_$identityKey'),
    );
    final leadingFinder = find.byKey(
      ValueKey<String>('session_tab_leading_$identityKey'),
    );

    await tester.pumpWidget(_app(tabs: <SessionTabRecord>[idle]));
    await tester.pump();

    final idleTitleWidth = tester.getSize(titleFinder).width;
    expect(badgeFinder, findsNothing);

    await tester.pumpWidget(
      _app(
        tabs: <SessionTabRecord>[
          _tab(
            'working',
            title: 'Working session',
            status: SessionStatusType.busy,
          ),
        ],
      ),
    );
    await tester.pump();

    expect(
      find.descendant(of: leadingFinder, matching: projectIconFinder),
      findsOneWidget,
    );
    expect(
      find.descendant(of: leadingFinder, matching: badgeFinder),
      findsOneWidget,
    );
    expect(tester.getSize(titleFinder).width, idleTitleWidth);

    final iconRect = tester.getRect(projectIconFinder);
    final badgeRect = tester.getRect(badgeFinder);
    final leadingRect = tester.getRect(leadingFinder);
    expect(badgeRect.size, const Size.square(12));
    expect(iconRect.overlaps(badgeRect), isTrue);
    expect(badgeRect.center.dx, greaterThan(iconRect.center.dx));
    expect(badgeRect.center.dy, greaterThan(iconRect.center.dy));
    expect(badgeRect.right, leadingRect.right);
    expect(badgeRect.bottom, leadingRect.bottom);
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
                onContextMenu: (tab, position, {required haptic}) async {},
                trailingBuilder: (context, tab) => null,
              );
            },
          ),
        ),
      ),
    );

    final secondFinder = find.byKey(
      ValueKey<String>(
        'session_tab_activate_${sessionTabIdentityKey(second.identity)}',
      ),
    );
    await tester.tap(secondFinder);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(secondFinder);
    await tester.pumpAndSettle();

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

    final firstFinder = find.byKey(
      ValueKey<String>(
        'session_tab_activate_${sessionTabIdentityKey(first.identity)}',
      ),
    );
    final middleClick = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kMiddleMouseButton,
    );
    await middleClick.addPointer(location: tester.getCenter(firstFinder));
    await middleClick.down(tester.getCenter(firstFinder));
    await middleClick.up();
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

  testWidgets('selected tab merges with the content surface below', (
    tester,
  ) async {
    final selected = _tab('alpha', isSelected: true);
    final inactive = _tab('beta');

    await tester.pumpWidget(_app(tabs: <SessionTabRecord>[selected, inactive]));
    await tester.pump();

    final context = tester.element(
      find.byKey(const ValueKey<String>('session_tab_strip')),
    );
    final colorScheme = Theme.of(context).colorScheme;

    // The selected tab takes the content surface colour so it reads as
    // continuous with the panel underneath; inactive tabs stay transparent
    // over the strip band.
    expect(_tabMaterial(tester, selected).color, colorScheme.surface);
    expect(_tabMaterial(tester, inactive).color, Colors.transparent);
  });

  testWidgets('tabs use lower flares, straight sides, and soft top corners', (
    tester,
  ) async {
    final selected = _tab('alpha', isSelected: true);

    await tester.pumpWidget(_app(tabs: <SessionTabRecord>[selected]));
    await tester.pump();

    final shape = _tabMaterial(tester, selected).shape!;

    for (final size in const <Size>[Size(317.2, 54), Size(278.2, 58)]) {
      final path = shape.getOuterPath(Offset.zero & size);
      final rightShoulder = size.width - 14;

      // The lower shoulders retain their outward flare.
      expect(path.contains(Offset(10, size.height - 2)), isTrue);
      expect(path.contains(Offset(size.width - 10, size.height - 2)), isTrue);

      // Above the flare, each side stays vertical at the 14px shoulder.
      expect(path.contains(const Offset(13, 20)), isFalse);
      expect(path.contains(const Offset(15, 20)), isTrue);
      expect(path.contains(Offset(rightShoulder - 1, 20)), isTrue);
      expect(path.contains(Offset(rightShoulder + 1, 20)), isFalse);

      // A 5px top radius admits points that the previous 10px arc excluded.
      expect(path.contains(const Offset(16, 2)), isTrue);
      expect(path.contains(Offset(size.width - 16, 2)), isTrue);
      expect(path.contains(const Offset(2, 2)), isFalse);
      expect(path.contains(Offset(size.width - 2, 2)), isFalse);
      expect(path.contains(Offset(size.width / 2, 2)), isTrue);
    }
  });

  testWidgets('double touch closes without rendering a close button', (
    tester,
  ) async {
    final tab = _tab('alpha', isSelected: true);
    final closed = <SessionTabIdentity>[];
    final closeFinder = find.byKey(
      ValueKey<String>(
        'session_tab_close_${sessionTabIdentityKey(tab.identity)}',
      ),
    );

    for (final isCompact in <bool>[true, false]) {
      await tester.pumpWidget(
        _app(
          tabs: <SessionTabRecord>[tab],
          isCompact: isCompact,
          onClose: closed.add,
        ),
      );
      await tester.pump();

      expect(closeFinder, findsNothing);
      final tabFinder = find.byKey(
        ValueKey<String>(
          'session_tab_activate_${sessionTabIdentityKey(tab.identity)}',
        ),
      );
      await tester.tap(tabFinder, kind: PointerDeviceKind.touch);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(tabFinder, kind: PointerDeviceKind.touch);
      await tester.pump();
      expect(closed.last, tab.identity);
      await tester.pump(const Duration(seconds: 1));
    }
  });

  testWidgets('right click and long press open the tab context menu', (
    tester,
  ) async {
    final tab = _tab('alpha', isSelected: true);
    final requests = <({SessionTabIdentity identity, bool haptic})>[];
    await tester.pumpWidget(
      _app(
        tabs: <SessionTabRecord>[tab],
        onContextMenu: (tab, position, {required haptic}) async {
          requests.add((identity: tab.identity, haptic: haptic));
        },
      ),
    );
    final finder = find.byKey(
      ValueKey<String>(
        'session_tab_activate_${sessionTabIdentityKey(tab.identity)}',
      ),
    );

    await tester.tap(finder, buttons: kSecondaryMouseButton);
    await tester.pump();
    await tester.longPress(finder);
    await tester.pump();

    tester.widget<InkWell>(finder).focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.f10);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    final semantics = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.customSemanticsActions?.keys.any(
                  (action) => action.label == 'Session actions',
                ) ==
                true,
      ),
    );
    semantics.properties.customSemanticsActions!.entries
        .singleWhere((entry) => entry.key.label == 'Session actions')
        .value();
    await tester.pump();

    expect(requests, <({SessionTabIdentity identity, bool haptic})>[
      (identity: tab.identity, haptic: false),
      (identity: tab.identity, haptic: true),
      (identity: tab.identity, haptic: false),
      (identity: tab.identity, haptic: false),
    ]);
  });

  testWidgets('selection is conveyed by more than colour', (tester) async {
    final selected = _tab('alpha', isSelected: true);
    final inactive = _tab('beta');

    await tester.pumpWidget(_app(tabs: <SessionTabRecord>[selected, inactive]));
    await tester.pump();

    Text titleOf(SessionTabRecord tab) => tester.widget<Text>(
      find.byKey(
        ValueKey<String>(
          'session_tab_title_${sessionTabIdentityKey(tab.identity)}',
        ),
      ),
    );

    // Weight differs, so selection survives for users who cannot rely on
    // colour alone even though the accent bar was dropped.
    expect(
      titleOf(selected).style!.fontWeight,
      isNot(titleOf(inactive).style!.fontWeight),
    );
  });
}

Material _tabMaterial(WidgetTester tester, SessionTabRecord tab) {
  return tester.widget<Material>(
    find.byKey(
      ValueKey<String>('session_tab_${sessionTabIdentityKey(tab.identity)}'),
    ),
  );
}

Widget _app({
  required List<SessionTabRecord> tabs,
  List<Project> projects = const <Project>[],
  Set<String> openProjectIds = const <String>{},
  ValueChanged<SessionTabIdentity>? onActivate,
  ValueChanged<SessionTabIdentity>? onClose,
  SessionTabContextMenuCallback? onContextMenu,
  SessionTabTrailingBuilder? trailingBuilder,
  double width = 800,
  bool isCompact = false,
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
            isCompact: isCompact,
            onActivate: (tab) => onActivate?.call(tab.identity),
            onClose: (tab) => onClose?.call(tab.identity),
            onContextMenu:
                onContextMenu ?? (tab, position, {required haptic}) async {},
            trailingBuilder: trailingBuilder ?? (context, tab) => null,
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
