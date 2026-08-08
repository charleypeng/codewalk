import 'package:codewalk/domain/entities/persisted_session_tabs_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips versioned open and closed session tabs', () {
    const state = PersistedSessionTabsState(
      open: <PersistedSessionTab>[
        PersistedSessionTab(
          directory: r'C:\work\demo\',
          projectId: 'project-1',
          sessionId: 'session-1',
          title: 'Review changes',
          lastOpenedAtMs: 100,
          serverUpdatedAtMs: 90,
          seenQuestionIds: <String>['question-1'],
          seenCompletionToken: 'completion-1',
          seenErrorToken: 'error-1',
        ),
      ],
      closed: <PersistedClosedSessionTab>[
        PersistedClosedSessionTab(
          directory: '/work/demo/',
          projectId: 'project-1',
          sessionId: 'session-2',
          closedAtMs: 80,
          observedServerUpdatedAtMs: 70,
        ),
      ],
    );

    final restored = PersistedSessionTabsState.decode(state.encode());

    expect(restored.open, hasLength(1));
    expect(restored.open.single.directory, 'C:/work/demo');
    expect(restored.open.single.projectId, 'project-1');
    expect(restored.open.single.sessionId, 'session-1');
    expect(restored.open.single.seenQuestionIds, <String>['question-1']);
    expect(restored.open.single.seenCompletionToken, 'completion-1');
    expect(restored.open.single.seenErrorToken, 'error-1');
    expect(restored.closed, hasLength(1));
    expect(restored.closed.single.directory, '/work/demo');
    expect(restored.closed.single.closedAtMs, 80);
    expect(restored.closed.single.observedServerUpdatedAtMs, 70);
  });

  test('ignores malformed and unknown-version payloads', () {
    expect(PersistedSessionTabsState.decode(null).open, isEmpty);
    expect(PersistedSessionTabsState.decode('').open, isEmpty);
    expect(PersistedSessionTabsState.decode('{not-json').open, isEmpty);
    expect(
      PersistedSessionTabsState.decode(
        '{"version":2,"open":[],"closed":[]}',
      ).open,
      isEmpty,
    );
    expect(
      PersistedSessionTabsState.decode(
        '{"version":1,"open":[{"sessionId":"missing-directory"}],"closed":[42]}',
      ).open,
      isEmpty,
    );
  });

  test('normalizes identity keys before a persistence round trip', () {
    const open = PersistedSessionTab(
      directory: '/work/demo/',
      sessionId: ' session-1 ',
      title: 'Demo',
      lastOpenedAtMs: 100,
      serverUpdatedAtMs: 90,
    );
    const closed = PersistedClosedSessionTab(
      directory: r'C:\work\demo\',
      sessionId: ' session-2 ',
      closedAtMs: 80,
      observedServerUpdatedAtMs: 70,
    );

    expect(open.identityKey, '/work/demo::session-1');
    expect(closed.identityKey, 'C:/work/demo::session-2');
  });
}
