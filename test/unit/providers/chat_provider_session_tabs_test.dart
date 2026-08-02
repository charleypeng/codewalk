import 'dart:async';

import 'package:codewalk/domain/entities/chat_realtime.dart';
import 'package:codewalk/domain/entities/chat_session.dart';
import 'package:codewalk/domain/entities/persisted_session_tabs_state.dart';
import 'package:codewalk/presentation/providers/chat_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import 'chat_provider_test_support.dart';

const int _hourMs = 60 * 60 * 1000;

SessionTabIdentity _identity(
  String sessionId, {
  String serverId = 'server-a',
  String directory = '/work/project',
}) {
  return SessionTabIdentity(
    serverId: serverId,
    directory: directory,
    sessionId: sessionId,
  );
}

SessionTabCandidate _candidate(
  String sessionId, {
  int updatedAtMs = 0,
  String serverId = 'server-a',
  String directory = '/work/project',
  SessionStatusType status = SessionStatusType.idle,
  bool isSelected = false,
  bool isArchived = false,
  bool isRoot = true,
  List<String> pendingQuestionIds = const <String>[],
  String? completionToken,
  String? errorToken,
}) {
  return SessionTabCandidate(
    identity: _identity(sessionId, serverId: serverId, directory: directory),
    title: 'Title $sessionId',
    serverUpdatedAtMs: updatedAtMs,
    status: status,
    isSelected: isSelected,
    isArchived: isArchived,
    isRoot: isRoot,
    pendingQuestionIds: pendingQuestionIds,
    completionToken: completionToken,
    errorToken: errorToken,
  );
}

PersistedSessionTab _persisted(
  String sessionId, {
  int lastOpenedAtMs = 0,
  int serverUpdatedAtMs = 0,
  String directory = '/work/project',
  String? title,
  List<String> seenQuestionIds = const <String>[],
  String? seenCompletionToken,
  String? seenErrorToken,
}) {
  return PersistedSessionTab(
    directory: directory,
    sessionId: sessionId,
    title: title ?? 'Persisted $sessionId',
    lastOpenedAtMs: lastOpenedAtMs,
    serverUpdatedAtMs: serverUpdatedAtMs,
    seenQuestionIds: seenQuestionIds,
    seenCompletionToken: seenCompletionToken,
    seenErrorToken: seenErrorToken,
  );
}

void main() {
  group('SessionTabReconciler', () {
    test('uses the exact cutoff and retains selected or busy roots', () {
      const nowMs = 10 * _hourMs;
      const cutoffMs = nowMs - 3 * _hourMs;

      final result = SessionTabReconciler.reconcile(
        serverId: 'server-a',
        persistedState: const PersistedSessionTabsState(),
        candidates: <SessionTabCandidate>[
          _candidate('too-old', updatedAtMs: cutoffMs - 1),
          _candidate('at-cutoff', updatedAtMs: cutoffMs),
          _candidate('busy', updatedAtMs: 1, status: SessionStatusType.busy),
          _candidate('selected', updatedAtMs: 2, isSelected: true),
          _candidate('child', updatedAtMs: nowMs, isRoot: false),
          _candidate('archived', updatedAtMs: nowMs, isArchived: true),
          _candidate('other-server', updatedAtMs: nowMs, serverId: 'server-b'),
        ],
        nowMs: nowMs,
      );

      expect(result.tabs.map((tab) => tab.identity.sessionId), <String>[
        'busy',
        'selected',
        'at-cutoff',
      ]);
    });

    test(
      'bootstraps only the newest old session for a newly opened project',
      () {
        const nowMs = 10 * _hourMs;
        const reopenedDirectory = '/work/reopened';
        final result = SessionTabReconciler.reconcile(
          serverId: 'server-a',
          persistedState: PersistedSessionTabsState(
            open: <PersistedSessionTab>[
              _persisted(
                'existing',
                directory: '/work/existing',
                lastOpenedAtMs: nowMs,
              ),
              _persisted(
                'locally-newest',
                directory: reopenedDirectory,
                lastOpenedAtMs: 4 * _hourMs,
                serverUpdatedAtMs: 2 * _hourMs,
              ),
            ],
            closed: const <PersistedClosedSessionTab>[
              PersistedClosedSessionTab(
                directory: reopenedDirectory,
                sessionId: 'suppressed-newest',
                closedAtMs: 9 * _hourMs,
                observedServerUpdatedAtMs: 6 * _hourMs,
              ),
            ],
          ),
          candidates: <SessionTabCandidate>[
            _candidate(
              'server-older',
              directory: reopenedDirectory,
              updatedAtMs: 3 * _hourMs,
            ),
            _candidate(
              'locally-newest',
              directory: reopenedDirectory,
              updatedAtMs: 2 * _hourMs,
            ),
            _candidate(
              'suppressed-newest',
              directory: reopenedDirectory,
              updatedAtMs: 6 * _hourMs,
            ),
          ],
          nowMs: nowMs,
          bootstrapDirectory: reopenedDirectory,
        );

        expect(result.tabs.map((tab) => tab.identity.sessionId), <String>[
          'existing',
          'locally-newest',
        ]);
        expect(result.persistedState.closed, hasLength(1));
      },
    );

    test('bootstraps all recent sessions without adding an old fallback', () {
      const nowMs = 10 * _hourMs;
      const reopenedDirectory = '/work/reopened';
      const cutoffMs = nowMs - 3 * _hourMs;
      final result = SessionTabReconciler.reconcile(
        serverId: 'server-a',
        persistedState: const PersistedSessionTabsState(),
        candidates: <SessionTabCandidate>[
          _candidate(
            'old-latest',
            directory: reopenedDirectory,
            updatedAtMs: cutoffMs - 1,
          ),
          _candidate(
            'recent-a',
            directory: reopenedDirectory,
            updatedAtMs: cutoffMs,
          ),
          _candidate(
            'recent-b',
            directory: reopenedDirectory,
            updatedAtMs: nowMs,
          ),
        ],
        nowMs: nowMs,
        bootstrapDirectory: reopenedDirectory,
      );

      expect(result.tabs.map((tab) => tab.identity.sessionId), <String>[
        'recent-a',
        'recent-b',
      ]);
    });

    test('deduplicates while preserving existing order and append order', () {
      const nowMs = 10 * _hourMs;
      final result = SessionTabReconciler.reconcile(
        serverId: 'server-a',
        persistedState: PersistedSessionTabsState(
          open: <PersistedSessionTab>[
            _persisted('a', lastOpenedAtMs: _hourMs, title: 'Old A'),
            _persisted('b', lastOpenedAtMs: 8 * _hourMs),
            _persisted('a', lastOpenedAtMs: 9 * _hourMs, title: 'New A'),
          ],
        ),
        candidates: <SessionTabCandidate>[
          _candidate('c', updatedAtMs: 8 * _hourMs),
          _candidate('c', updatedAtMs: 8 * _hourMs),
          _candidate('d', updatedAtMs: 9 * _hourMs),
        ],
        nowMs: nowMs,
      );

      expect(result.tabs.map((tab) => tab.identity.sessionId), <String>[
        'a',
        'b',
        'c',
        'd',
      ]);
      expect(result.tabs.first.lastOpenedAtMs, 9 * _hourMs);
      expect(result.persistedState.open, hasLength(4));
    });

    test(
      'closed tabs reopen only explicitly or after a newer server update',
      () {
        const closedAtMs = 8 * _hourMs;
        const observedAtMs = 7 * _hourMs;
        final identity = _identity('a');
        final closed = SessionTabReconciler.close(
          state: PersistedSessionTabsState(
            open: <PersistedSessionTab>[
              _persisted('a', serverUpdatedAtMs: observedAtMs),
            ],
          ),
          identity: identity,
          nowMs: closedAtMs,
        );

        final suppressed = SessionTabReconciler.reconcile(
          serverId: 'server-a',
          persistedState: closed,
          candidates: <SessionTabCandidate>[
            _candidate(
              'a',
              updatedAtMs: observedAtMs,
              status: SessionStatusType.busy,
              isSelected: true,
            ),
          ],
          nowMs: closedAtMs,
        );
        expect(suppressed.tabs, isEmpty);
        expect(suppressed.persistedState.closed, hasLength(1));
        expect(
          suppressed.persistedState.closed.single.observedServerUpdatedAtMs,
          observedAtMs,
        );

        final remotelyUpdated = SessionTabReconciler.reconcile(
          serverId: 'server-a',
          persistedState: closed,
          candidates: <SessionTabCandidate>[
            _candidate('a', updatedAtMs: observedAtMs + 1),
          ],
          nowMs: closedAtMs,
        );
        expect(remotelyUpdated.tabs.single.identity, identity);
        expect(remotelyUpdated.persistedState.closed, isEmpty);

        final explicitlyOpened = SessionTabReconciler.reconcile(
          serverId: 'server-a',
          persistedState: closed,
          candidates: <SessionTabCandidate>[
            _candidate('a', updatedAtMs: observedAtMs),
          ],
          nowMs: closedAtMs,
          explicitlyOpened: identity,
        );
        expect(explicitlyOpened.tabs.single.lastOpenedAtMs, closedAtMs);
        expect(explicitlyOpened.persistedState.closed, isEmpty);
      },
    );

    test(
      'retains old tombstones until an authoritative archive clears them',
      () {
        const nowMs = 12 * _hourMs;
        final result = SessionTabReconciler.reconcile(
          serverId: 'server-a',
          persistedState: const PersistedSessionTabsState(
            closed: <PersistedClosedSessionTab>[
              PersistedClosedSessionTab(
                directory: '/work/project',
                sessionId: 'a',
                closedAtMs: 8 * _hourMs,
                observedServerUpdatedAtMs: 7 * _hourMs,
              ),
            ],
          ),
          candidates: <SessionTabCandidate>[
            _candidate('a', updatedAtMs: 7 * _hourMs),
          ],
          nowMs: nowMs,
        );

        expect(result.tabs, isEmpty);
        expect(result.persistedState.closed, hasLength(1));

        final archived = SessionTabReconciler.reconcile(
          serverId: 'server-a',
          persistedState: result.persistedState,
          candidates: <SessionTabCandidate>[
            _candidate('a', updatedAtMs: 7 * _hourMs, isArchived: true),
          ],
          nowMs: nowMs,
        );
        expect(archived.tabs, isEmpty);
        expect(archived.persistedState.closed, isEmpty);
      },
    );

    test('derives unseen attention from deterministic persisted markers', () {
      const nowMs = 10 * _hourMs;
      final seen = SessionTabReconciler.reconcile(
        serverId: 'server-a',
        persistedState: PersistedSessionTabsState(
          open: <PersistedSessionTab>[
            _persisted(
              'a',
              lastOpenedAtMs: nowMs,
              seenQuestionIds: const <String>['question-1'],
              seenCompletionToken: 'completion-1',
              seenErrorToken: 'error-1',
            ),
          ],
        ),
        candidates: <SessionTabCandidate>[
          _candidate(
            'a',
            updatedAtMs: nowMs,
            pendingQuestionIds: const <String>['question-1'],
            completionToken: 'completion-1',
            errorToken: 'error-1',
          ),
        ],
        nowMs: nowMs,
      );
      expect(seen.tabs.single.requiresAttention, isFalse);

      final unseen = SessionTabReconciler.reconcile(
        serverId: 'server-a',
        persistedState: seen.persistedState,
        candidates: <SessionTabCandidate>[
          _candidate(
            'a',
            updatedAtMs: nowMs,
            pendingQuestionIds: const <String>['question-1', 'question-2'],
            completionToken: 'completion-2',
            errorToken: 'error-2',
          ),
        ],
        nowMs: nowMs,
      );

      expect(unseen.tabs.single.hasUnseenQuestion, isTrue);
      expect(unseen.tabs.single.hasUnseenCompletion, isTrue);
      expect(unseen.tabs.single.hasUnseenError, isTrue);
      expect(unseen.tabs.single.attentionKind, SessionAttentionKind.error);
    });
  });

  group('ChatProvider session tabs', () {
    late ChatProviderTestFixtures fixtures;
    late ChatProvider provider;
    final now = DateTime.utc(2026, 7, 30, 4);

    setUp(() async {
      fixtures = await buildDefaultTestFixtures();
      fixtures.chatRepository.sessions
        ..clear()
        ..add(
          ChatSession(
            id: 'session-live',
            workspaceId: 'default',
            directory: '/work/project',
            time: now.subtract(const Duration(hours: 4)),
            title: 'Live session',
          ),
        );
      provider = buildChatProvider(
        chatRepository: fixtures.chatRepository,
        appRepository: fixtures.appRepository,
        localDataSource: fixtures.localDataSource,
        defaultSettingsProvider: fixtures.defaultSettingsProvider,
        sessionTabsNow: () => now,
      );
      addTearDown(provider.dispose);
    });

    test(
      'successful automatic selection opens and persists the visible tab',
      () async {
        await provider.loadSessions();
        await provider.debugWaitForSessionTabPersistence();

        expect(provider.sessionTabs, hasLength(1));
        expect(provider.sessionTabs.single.identity.sessionId, 'session-live');
        expect(
          provider.sessionTabs.single.lastOpenedAtMs,
          now.millisecondsSinceEpoch,
        );
        final raw = await fixtures.localDataSource.getSessionTabsStateJson(
          serverId: 'srv_test',
        );
        final persisted = PersistedSessionTabsState.decode(raw);
        expect(persisted.open.single.sessionId, 'session-live');
        expect(
          persisted.open.single.lastOpenedAtMs,
          now.millisecondsSinceEpoch,
        );
      },
    );

    test('closing a tab persists its local tombstone', () async {
      await provider.loadSessions();
      final identity = provider.sessionTabs.single.identity;

      provider.closeSessionTab(identity);
      await provider.debugWaitForSessionTabPersistence();
      await provider.loadSessionTabs();

      expect(provider.sessionTabs, isEmpty);
      final persisted = PersistedSessionTabsState.decode(
        await fixtures.localDataSource.getSessionTabsStateJson(
          serverId: 'srv_test',
        ),
      );
      expect(persisted.open, isEmpty);
      expect(persisted.closed, hasLength(1));
      expect(persisted.closed.single.sessionId, identity.sessionId);
      expect(persisted.closed.single.directory, identity.directory);
    });

    test(
      'question attention persists as seen after selecting its tab',
      () async {
        fixtures.chatRepository.sessions.add(
          ChatSession(
            id: 'session-other',
            workspaceId: 'default',
            directory: '/work/project',
            time: now.subtract(const Duration(hours: 5)),
            title: 'Other session',
          ),
        );
        await provider.loadSessions();
        await provider.selectSession(
          provider.sessions
              .where((session) => session.id == 'session-other')
              .single,
        );
        await provider.selectSession(
          provider.sessions
              .where((session) => session.id == 'session-live')
              .single,
        );
        await provider.initializeProviders();

        fixtures.chatRepository.emitEvent(
          const ChatEvent(
            type: 'question.asked',
            properties: <String, dynamic>{
              'id': 'question-1',
              'sessionID': 'session-other',
              'questions': <Map<String, dynamic>>[
                <String, dynamic>{
                  'question': 'Proceed?',
                  'header': 'Confirm',
                  'options': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'label': 'Yes',
                      'description': 'Continue',
                    },
                  ],
                },
              ],
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(
          provider.sessionTabs
              .where((tab) => tab.identity.sessionId == 'session-other')
              .single
              .hasUnseenQuestion,
          isTrue,
        );

        await provider.selectSession(
          provider.sessions
              .where((session) => session.id == 'session-other')
              .single,
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));
        await provider.debugWaitForSessionTabPersistence();

        final selectedTab = provider.sessionTabs
            .where((tab) => tab.identity.sessionId == 'session-other')
            .single;
        expect(selectedTab.hasUnseenQuestion, isFalse);
        final persisted = PersistedSessionTabsState.decode(
          await fixtures.localDataSource.getSessionTabsStateJson(
            serverId: 'srv_test',
          ),
        );
        expect(
          persisted.open
              .where((tab) => tab.sessionId == 'session-other')
              .single
              .seenQuestionIds,
          contains('question-1'),
        );
      },
    );

    test(
      'background question remains unseen until chat is foregrounded',
      () async {
        await provider.loadSessions();
        await provider.initializeProviders();
        await provider.setForegroundActive(false);

        fixtures.chatRepository.emitEvent(
          const ChatEvent(
            type: 'question.asked',
            properties: <String, dynamic>{
              'id': 'question-background',
              'sessionID': 'session-live',
              'questions': <Map<String, dynamic>>[
                <String, dynamic>{
                  'question': 'Review?',
                  'header': 'Review',
                  'options': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'label': 'Yes',
                      'description': 'Review now',
                    },
                  ],
                },
              ],
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(provider.sessionTabs.single.hasUnseenQuestion, isTrue);

        await provider.setForegroundActive(true);
        await provider.debugWaitForSessionTabPersistence();

        expect(provider.sessionTabs.single.hasUnseenQuestion, isFalse);
      },
    );

    test(
      'inactive persisted tab receives question attention from global events',
      () async {
        await fixtures.localDataSource.saveSessionTabsStateJson(
          PersistedSessionTabsState(
            open: <PersistedSessionTab>[
              PersistedSessionTab(
                directory: '/work/other',
                projectId: 'project-other',
                sessionId: 'session-other',
                title: 'Other session',
                lastOpenedAtMs: now.millisecondsSinceEpoch,
                serverUpdatedAtMs: now.millisecondsSinceEpoch,
              ),
            ],
          ).encode(),
          serverId: 'srv_test',
        );
        await provider.loadSessions();
        await provider.initializeProviders();

        fixtures.chatRepository.emitGlobalEvent(
          const ChatEvent(
            type: 'question.asked',
            properties: <String, dynamic>{
              'directory': '/work/other',
              'id': 'question-inactive',
              'sessionID': 'session-other',
              'questions': <Map<String, dynamic>>[
                <String, dynamic>{
                  'question': 'Proceed?',
                  'header': 'Confirm',
                  'options': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'label': 'Yes',
                      'description': 'Continue',
                    },
                  ],
                },
              ],
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));

        final inactiveTab = provider.sessionTabs
            .where((tab) => tab.identity.sessionId == 'session-other')
            .single;
        expect(inactiveTab.hasUnseenQuestion, isTrue);
        expect(
          inactiveTab.attentionKind,
          SessionAttentionKind.pendingInteraction,
        );

        fixtures.chatRepository.emitGlobalEvent(
          ChatEvent(
            type: 'session.updated',
            properties: <String, dynamic>{
              'directory': '/work/other',
              'info': <String, dynamic>{
                'id': 'session-other',
                'workspaceId': 'project-other',
                'title': 'Renamed other session',
                'time': <String, dynamic>{
                  'created': now.millisecondsSinceEpoch - 1,
                  'updated': now.millisecondsSinceEpoch + 1,
                },
              },
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));

        final renamedTab = provider.sessionTabs
            .where((tab) => tab.identity.sessionId == 'session-other')
            .single;
        expect(renamedTab.title, 'Renamed other session');
        expect(renamedTab.hasUnseenQuestion, isTrue);
      },
    );

    test('confirmed deletion removes tab without a tombstone', () async {
      await provider.loadSessions();

      await provider.deleteSession('session-live');
      await provider.debugWaitForSessionTabPersistence();

      expect(provider.sessionTabs, isEmpty);
      final persisted = PersistedSessionTabsState.decode(
        await fixtures.localDataSource.getSessionTabsStateJson(
          serverId: 'srv_test',
        ),
      );
      expect(persisted.open, isEmpty);
      expect(persisted.closed, isEmpty);
    });

    test(
      'confirmed deletion keeps a same-id tab from another directory',
      () async {
        await fixtures.localDataSource.saveSessionTabsStateJson(
          PersistedSessionTabsState(
            open: <PersistedSessionTab>[
              PersistedSessionTab(
                directory: '/work/other',
                sessionId: 'session-live',
                title: 'Other same-id session',
                lastOpenedAtMs: now.millisecondsSinceEpoch,
                serverUpdatedAtMs: now.millisecondsSinceEpoch,
              ),
            ],
          ).encode(),
          serverId: 'srv_test',
        );
        await provider.loadSessions();

        await provider.deleteSession('session-live');
        await provider.debugWaitForSessionTabPersistence();

        expect(provider.sessionTabs, hasLength(1));
        expect(provider.sessionTabs.single.identity.directory, '/work/other');
        final persisted = PersistedSessionTabsState.decode(
          await fixtures.localDataSource.getSessionTabsStateJson(
            serverId: 'srv_test',
          ),
        );
        expect(persisted.open, hasLength(1));
        expect(persisted.open.single.directory, '/work/other');
        expect(persisted.closed, isEmpty);
      },
    );

    test('project-history removal clears tabs for that directory', () async {
      await fixtures.localDataSource.saveSessionTabsStateJson(
        PersistedSessionTabsState(
          open: <PersistedSessionTab>[
            PersistedSessionTab(
              directory: '/work/other',
              projectId: 'project-other',
              sessionId: 'session-other',
              title: 'Other session',
              lastOpenedAtMs: now.millisecondsSinceEpoch,
              serverUpdatedAtMs: now.millisecondsSinceEpoch,
            ),
          ],
          closed: <PersistedClosedSessionTab>[
            PersistedClosedSessionTab(
              directory: '/work/other',
              projectId: 'project-other',
              sessionId: 'session-closed',
              closedAtMs: now.millisecondsSinceEpoch,
              observedServerUpdatedAtMs: now.millisecondsSinceEpoch,
            ),
          ],
        ).encode(),
        serverId: 'srv_test',
      );
      await provider.loadSessions();

      await provider.removeSessionTabsForProjectHistory('/work/other/');
      await provider.debugWaitForSessionTabPersistence();

      expect(
        provider.sessionTabs.any(
          (tab) => tab.identity.directory == '/work/other',
        ),
        isFalse,
      );
      final persisted = PersistedSessionTabsState.decode(
        await fixtures.localDataSource.getSessionTabsStateJson(
          serverId: 'srv_test',
        ),
      );
      expect(
        persisted.open.any((tab) => tab.directory == '/work/other'),
        isFalse,
      );
      expect(
        persisted.closed.any((tab) => tab.directory == '/work/other'),
        isFalse,
      );
    });

    test(
      'project-history removal targets the captured inactive server',
      () async {
        await fixtures.localDataSource.saveSessionTabsStateJson(
          PersistedSessionTabsState(
            open: <PersistedSessionTab>[
              PersistedSessionTab(
                directory: '/work/other',
                sessionId: 'session-other',
                title: 'Other session',
                lastOpenedAtMs: now.millisecondsSinceEpoch,
                serverUpdatedAtMs: now.millisecondsSinceEpoch,
              ),
            ],
          ).encode(),
          serverId: 'server-a',
        );
        await provider.loadSessions();

        await provider.removeSessionTabsForProjectHistory(
          '/work/other',
          serverId: 'server-a',
        );

        expect(provider.activeServerId, 'srv_test');
        expect(provider.sessionTabs, isNotEmpty);
        final persisted = PersistedSessionTabsState.decode(
          await fixtures.localDataSource.getSessionTabsStateJson(
            serverId: 'server-a',
          ),
        );
        expect(persisted.open, isEmpty);
        expect(persisted.closed, isEmpty);
      },
    );

    test(
      'concurrent inactive-server removals serialize read-modify-write',
      () async {
        await fixtures.localDataSource.saveSessionTabsStateJson(
          PersistedSessionTabsState(
            open: <PersistedSessionTab>[
              PersistedSessionTab(
                directory: '/work/one',
                sessionId: 'session-one',
                title: 'One',
                lastOpenedAtMs: now.millisecondsSinceEpoch,
                serverUpdatedAtMs: now.millisecondsSinceEpoch,
              ),
              PersistedSessionTab(
                directory: '/work/two',
                sessionId: 'session-two',
                title: 'Two',
                lastOpenedAtMs: now.millisecondsSinceEpoch,
                serverUpdatedAtMs: now.millisecondsSinceEpoch,
              ),
              PersistedSessionTab(
                directory: '/work/keep',
                sessionId: 'session-keep',
                title: 'Keep',
                lastOpenedAtMs: now.millisecondsSinceEpoch,
                serverUpdatedAtMs: now.millisecondsSinceEpoch,
              ),
            ],
          ).encode(),
          serverId: 'server-a',
        );

        await Future.wait(<Future<void>>[
          provider.removeSessionTabsForProjectHistory(
            '/work/one',
            serverId: 'server-a',
          ),
          provider.removeSessionTabsForProjectHistory(
            '/work/two',
            serverId: 'server-a',
          ),
        ]);

        final persisted = PersistedSessionTabsState.decode(
          await fixtures.localDataSource.getSessionTabsStateJson(
            serverId: 'server-a',
          ),
        );
        expect(persisted.open, hasLength(1));
        expect(persisted.open.single.directory, '/work/keep');
      },
    );

    test(
      'a late read from the previous server cannot replace active tabs',
      () async {
        final delayedLocalDataSource = _DelayedSessionTabsLocalDataSource()
          ..activeServerId = 'server-a';
        await delayedLocalDataSource.saveSessionTabsStateJson(
          PersistedSessionTabsState(
            open: <PersistedSessionTab>[
              _persisted('tab-a', lastOpenedAtMs: now.millisecondsSinceEpoch),
            ],
          ).encode(),
          serverId: 'server-a',
        );
        await delayedLocalDataSource.saveSessionTabsStateJson(
          PersistedSessionTabsState(
            open: <PersistedSessionTab>[
              _persisted('tab-b', lastOpenedAtMs: now.millisecondsSinceEpoch),
            ],
          ).encode(),
          serverId: 'server-b',
        );
        final delayedProvider = buildChatProvider(
          chatRepository: fixtures.chatRepository,
          appRepository: fixtures.appRepository,
          localDataSource: delayedLocalDataSource,
          defaultSettingsProvider: fixtures.defaultSettingsProvider,
          sessionTabsNow: () => now,
        );
        addTearDown(delayedProvider.dispose);

        final firstLoad = delayedProvider.loadSessionTabs();
        await delayedLocalDataSource.serverAReadStarted.future;
        delayedLocalDataSource.activeServerId = 'server-b';
        final switchServer = delayedProvider.onServerScopeChanged();
        await Future<void>.delayed(Duration.zero);
        delayedLocalDataSource.releaseServerARead.complete();
        await Future.wait(<Future<void>>[firstLoad, switchServer]);

        expect(delayedProvider.activeServerId, 'server-b');
        expect(
          delayedProvider.sessionTabs.map((tab) => tab.identity.sessionId),
          contains('tab-b'),
        );
        expect(
          delayedProvider.sessionTabs.map((tab) => tab.identity.sessionId),
          isNot(contains('tab-a')),
        );
      },
    );
  });
}

class _DelayedSessionTabsLocalDataSource extends InMemoryAppLocalDataSource {
  final Completer<void> serverAReadStarted = Completer<void>();
  final Completer<void> releaseServerARead = Completer<void>();

  @override
  Future<String?> getSessionTabsStateJson({required String serverId}) async {
    if (serverId == 'server-a') {
      if (!serverAReadStarted.isCompleted) serverAReadStarted.complete();
      await releaseServerARead.future;
    }
    return super.getSessionTabsStateJson(serverId: serverId);
  }
}
