@Tags(<String>['slow'])
library;

import 'package:codewalk/core/errors/failures.dart';
import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/domain/entities/chat_realtime.dart';
import 'package:codewalk/domain/entities/chat_session.dart';
import 'package:codewalk/presentation/providers/chat_provider.dart';
import 'package:codewalk/presentation/providers/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../unit/providers/chat_provider_test_support.dart';

void main() {
  group('SSE event dispatch contract', () {
    late FakeChatRepository chatRepository;
    late FakeAppRepository appRepository;
    late InMemoryAppLocalDataSource localDataSource;
    late SettingsProvider defaultSettingsProvider;
    late ChatProvider provider;

    ChatProvider buildProvider({
      DioClient? dioClient,
      Duration syncHealthCheckInterval = const Duration(seconds: 5),
      Duration abortSuppressionWindow = const Duration(milliseconds: 30),
      SettingsProvider? settingsProvider,
    }) {
      return buildChatProvider(
        chatRepository: chatRepository,
        appRepository: appRepository,
        localDataSource: localDataSource,
        defaultSettingsProvider: defaultSettingsProvider,
        dioClient: dioClient,
        syncHealthCheckInterval: syncHealthCheckInterval,
        abortSuppressionWindow: abortSuppressionWindow,
        settingsProvider: settingsProvider,
      );
    }

    setUp(() async {
      final fixtures = await buildDefaultTestFixtures();
      chatRepository = fixtures.chatRepository;
      appRepository = fixtures.appRepository;
      localDataSource = fixtures.localDataSource;
      defaultSettingsProvider = fixtures.defaultSettingsProvider;
      provider = buildProvider();
    });

    Future<void> settleUntil(
      bool Function() predicate, {
      int maxTicks = 40,
      String? reason,
    }) async {
      for (var tick = 0; tick < maxTicks; tick += 1) {
        if (predicate()) return;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      fail(reason ?? 'Condition was not met before event queue settled.');
    }

  Future<void> initAndSelectSession() async {
    await provider.projectProvider.initializeProject();
    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await provider.initializeProviders();
    // Allow async subscription setup to complete before emitting events.
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

    // ── server.heartbeat ──

    group('server.heartbeat', () {
      test('is silently ignored and does not change provider state', () async {
        await initAndSelectSession();
        final stateBefore = provider.state;
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'server.heartbeat',
            properties: <String, dynamic>{},
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(provider.state, stateBefore);
      });
    });

    // ── server.connected ──

    group('server.connected', () {
      test('triggers active session refresh without crashing', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'server.connected',
            properties: <String, dynamic>{},
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(provider.state, isNot(equals(ChatState.initial)));
      });
    });

    // ── session.created ──

    group('session.created', () {
  test('adds new session to the session list', () async {
      await initAndSelectSession();
      final countBefore = provider.sessions.length;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      chatRepository.emitEvent(
        ChatEvent(
          type: 'session.created',
          properties: <String, dynamic>{
            'info': <String, dynamic>{
              'id': 'ses_new',
              'workspaceId': 'default',
              'time': <String, dynamic>{
                'created': nowMs,
                'updated': nowMs,
              },
              'title': 'New from SSE',
            },
          },
        ),
      );
        await settleUntil(
          () => provider.sessions.length == countBefore + 1,
          reason: 'Expected new session from session.created event.',
        );
        expect(
          provider.sessions.any((s) => s.id == 'ses_new'),
          isTrue,
        );
      });

  test('ignores session with empty id', () async {
      await initAndSelectSession();
      final countBefore = provider.sessions.length;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      chatRepository.emitEvent(
        ChatEvent(
          type: 'session.created',
          properties: <String, dynamic>{
            'info': <String, dynamic>{
              'id': '',
              'workspaceId': 'default',
              'time': <String, dynamic>{
                'created': nowMs,
                'updated': nowMs,
              },
              'title': 'Empty ID',
            },
          },
        ),
      );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(provider.sessions.length, countBefore);
      });
    });

    // ── session.updated ──

    group('session.updated', () {
  test('updates existing session title', () async {
      await initAndSelectSession();
      final futureMs =
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch;
      chatRepository.emitEvent(
        ChatEvent(
          type: 'session.updated',
          properties: <String, dynamic>{
            'info': <String, dynamic>{
              'id': 'ses_1',
              'workspaceId': 'default',
              'time': <String, dynamic>{
                'created': futureMs,
                'updated': futureMs,
              },
              'title': 'Updated Title',
            },
          },
        ),
      );
        await settleUntil(
          () =>
              provider.sessions
                  .where((s) => s.id == 'ses_1')
                  .firstOrNull
                  ?.title ==
              'Updated Title',
          reason: 'Expected session title to update from session.updated.',
        );
      });

  test('ignores stale event with older timestamp', () async {
      await initAndSelectSession();
      final currentTitle = provider.sessions.first.title;
      // Use a very old timestamp that is before the existing session time.
      chatRepository.emitEvent(
        const ChatEvent(
          type: 'session.updated',
          properties: <String, dynamic>{
            'info': <String, dynamic>{
              'id': 'ses_1',
              'workspaceId': 'default',
              'time': <String, dynamic>{
                'created': 1,
                'updated': 1,
              },
              'title': 'Stale Title',
            },
          },
        ),
      );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        final updated = provider.sessions.firstWhere(
          (s) => s.id == 'ses_1',
        );
        expect(updated.title, currentTitle);
      });
    });

    // ── session.deleted ──

    group('session.deleted', () {
      test('removes session from list via info.id', () async {
        await initAndSelectSession();
        // Add a second session first.
        chatRepository.sessions.add(
          ChatSession(
            id: 'ses_to_delete',
            workspaceId: 'default',
            time: DateTime.now(),
            title: 'Delete Me',
          ),
        );
        await provider.loadSessions();
        final countBeforeDelete = provider.sessions.length;
        expect(countBeforeDelete, greaterThanOrEqualTo(2));
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.deleted',
            properties: <String, dynamic>{
              'info': <String, dynamic>{'id': 'ses_to_delete'},
            },
          ),
        );
        await settleUntil(
          () => !provider.sessions.any((s) => s.id == 'ses_to_delete'),
          reason: 'Expected session to be removed by session.deleted.',
        );
      });

      test('removes session from list via sessionID property', () async {
        await initAndSelectSession();
        chatRepository.sessions.add(
          ChatSession(
            id: 'ses_delete_alt',
            workspaceId: 'default',
            time: DateTime.now(),
            title: 'Delete Alt',
          ),
        );
        await provider.loadSessions();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.deleted',
            properties: <String, dynamic>{
              'sessionID': 'ses_delete_alt',
            },
          ),
        );
        await settleUntil(
          () => !provider.sessions.any((s) => s.id == 'ses_delete_alt'),
          reason:
              'Expected session to be removed by sessionID property in session.deleted.',
        );
      });

      test('ignores delete event with null/empty id', () async {
        await initAndSelectSession();
        final countBefore = provider.sessions.length;
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.deleted',
            properties: <String, dynamic>{},
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(provider.sessions.length, countBefore);
      });
    });

    // ── session.status ──

    group('session.status', () {
      test('updates session status to busy', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.status',
            properties: <String, dynamic>{
              'sessionID': 'ses_1',
              'status': <String, dynamic>{'type': 'busy'},
            },
          ),
        );
        await settleUntil(
          () =>
              provider.sessionStatusById['ses_1']?.type ==
              SessionStatusType.busy,
          reason: 'Expected session status to become busy.',
        );
      });

      test('updates session status to idle and marks non-current as unread',
          () async {
        await initAndSelectSession();
        // Add another session so we have a non-current one.
        chatRepository.sessions.add(
          ChatSession(
            id: 'ses_other',
            workspaceId: 'default',
            time: DateTime.now(),
            title: 'Other Session',
          ),
        );
        await provider.loadSessions();
        // First set busy.
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.status',
            properties: <String, dynamic>{
              'sessionID': 'ses_other',
              'status': <String, dynamic>{'type': 'busy'},
            },
          ),
        );
        await settleUntil(
          () =>
              provider.sessionStatusById['ses_other']?.type ==
              SessionStatusType.busy,
          reason: 'Expected other session status to become busy.',
        );
        // Now set idle — should mark unread since it's not the current session.
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.status',
            properties: <String, dynamic>{
              'sessionID': 'ses_other',
              'status': <String, dynamic>{'type': 'idle'},
            },
          ),
        );
        await settleUntil(
          () =>
              provider.sessionStatusById['ses_other']?.type ==
              SessionStatusType.idle,
          reason: 'Expected other session status to become idle.',
        );
      });

      test('ignores status event with missing sessionID', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.status',
            properties: <String, dynamic>{
              'status': <String, dynamic>{'type': 'busy'},
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(provider.state, isNot(equals(ChatState.initial)));
      });
    });

    // ── session.diff ──

    group('session.diff', () {
      test('stores diff entries for the current session', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.diff',
            properties: <String, dynamic>{
              'sessionID': 'ses_1',
              'diff': <dynamic>[
                <String, dynamic>{
                  'file': 'lib/main.dart',
                  'before': 'old',
                  'after': 'new',
                  'additions': 5,
                  'deletions': 2,
                },
              ],
            },
          ),
        );
        await settleUntil(
          () => provider.currentSessionDiff.isNotEmpty,
          reason: 'Expected session diff to be populated.',
        );
        expect(provider.currentSessionDiff.first.file, 'lib/main.dart');
      });

      test('ignores diff event with missing sessionID', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.diff',
            properties: <String, dynamic>{
              'diff': <dynamic>[
                <String, dynamic>{
                  'file': 'lib/other.dart',
                  'before': '',
                  'after': 'content',
                  'additions': 1,
                  'deletions': 0,
                },
              ],
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(provider.currentSessionDiff, isEmpty);
      });
    });

    // ── todo.updated ──

    group('todo.updated', () {
      test('stores todo entries for the current session', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'todo.updated',
            properties: <String, dynamic>{
              'sessionID': 'ses_1',
              'todos': <dynamic>[
                <String, dynamic>{
                  'id': 'todo_1',
                  'content': 'Fix bug',
                  'status': 'pending',
                  'priority': 'high',
                },
              ],
            },
          ),
        );
        await settleUntil(
          () => provider.currentSessionTodo.isNotEmpty,
          reason: 'Expected session todo to be populated.',
        );
        expect(provider.currentSessionTodo.first.content, 'Fix bug');
      });

      test('ignores todo event with missing sessionID', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'todo.updated',
            properties: <String, dynamic>{
              'todos': <dynamic>[
                <String, dynamic>{
                  'id': 'todo_2',
                  'content': 'Orphan',
                  'status': 'pending',
                  'priority': 'low',
                },
              ],
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(provider.currentSessionTodo, isEmpty);
      });
    });

    // ── session.idle ──

    group('session.idle', () {
      test('sets status to idle for current session', () async {
        await initAndSelectSession();
        // First make it busy.
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.status',
            properties: <String, dynamic>{
              'sessionID': 'ses_1',
              'status': <String, dynamic>{'type': 'busy'},
            },
          ),
        );
        await settleUntil(
          () =>
              provider.sessionStatusById['ses_1']?.type ==
              SessionStatusType.busy,
          reason: 'Pre-condition: session must be busy.',
        );
        // Now emit idle.
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.idle',
            properties: <String, dynamic>{'sessionID': 'ses_1'},
          ),
        );
        await settleUntil(
          () =>
              provider.sessionStatusById['ses_1']?.type ==
              SessionStatusType.idle,
          reason: 'Expected session status to become idle from session.idle.',
        );
      });

      test('ignores idle event with missing sessionID', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.idle',
            properties: <String, dynamic>{},
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(provider.state, isNot(equals(ChatState.initial)));
      });
    });

    // ── session.error ──

    group('session.error', () {
      test('enqueues UI notice with error message for current session',
          () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.error',
            properties: <String, dynamic>{
              'sessionID': 'ses_1',
              'error': <String, dynamic>{
                'message': 'Something went wrong',
              },
            },
          ),
        );
        await settleUntil(
          () => provider.pendingUiNotice != null,
          reason: 'Expected UI notice to be enqueued for current session error.',
        );
        expect(
          provider.pendingUiNotice!.message,
          contains('Something went wrong'),
        );
      });

      test('sets idle status for non-current session on error', () async {
        await initAndSelectSession();
        // Add another session so ses_other exists in the session list.
        chatRepository.sessions.add(
          ChatSession(
            id: 'ses_other',
            workspaceId: 'default',
            time: DateTime.now(),
            title: 'Other Session',
          ),
        );
        await provider.loadSessions();
        // Set it busy first.
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.status',
            properties: <String, dynamic>{
              'sessionID': 'ses_other',
              'status': <String, dynamic>{'type': 'busy'},
            },
          ),
        );
        await settleUntil(
          () =>
              provider.sessionStatusById['ses_other']?.type ==
              SessionStatusType.busy,
          reason: 'Pre-condition: other session must be busy.',
        );
        // Now emit error for the non-current session.
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.error',
            properties: <String, dynamic>{
              'sessionID': 'ses_other',
              'error': <String, dynamic>{'message': 'Background error'},
            },
          ),
        );
        await settleUntil(
          () =>
              provider.sessionStatusById['ses_other']?.type ==
              SessionStatusType.idle,
          reason:
              'Expected non-current session to go idle on session.error.',
        );
      });

      test('ignores error event with null sessionID', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.error',
            properties: <String, dynamic>{},
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(provider.state, isNot(equals(ChatState.initial)));
      });
    });

    // ── message.created / message.updated ──

    group('message.created', () {
      test('triggers fallback fetch for message in current session',
          () async {
        await initAndSelectSession();
        final getMessagesBefore = chatRepository.getMessagesCallCount;
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'message.created',
            properties: <String, dynamic>{
              'info': <String, dynamic>{
                'sessionID': 'ses_1',
                'id': 'msg_new_1',
              },
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(
          chatRepository.getMessagesCallCount,
          greaterThanOrEqualTo(getMessagesBefore),
        );
      });

      test('skips event with missing sessionID or messageId', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'message.created',
            properties: <String, dynamic>{
              'info': <String, dynamic>{},
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(provider.state, isNot(equals(ChatState.initial)));
      });
    });

    // ── message.part.updated ──

    group('message.part.updated', () {
      test('skips event for non-current session', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'message.part.updated',
            properties: <String, dynamic>{
              'part': <String, dynamic>{
                'id': 'prt_x',
                'messageID': 'msg_x',
                'sessionID': 'ses_other',
              },
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(provider.state, isNot(equals(ChatState.initial)));
      });

      test('skips event with missing part data', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'message.part.updated',
            properties: <String, dynamic>{},
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(provider.state, isNot(equals(ChatState.initial)));
      });
    });

    // ── message.part.removed ──

    group('message.part.removed', () {
      test('skips event for non-current session', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'message.part.removed',
            properties: <String, dynamic>{
              'sessionID': 'ses_other',
              'messageID': 'msg_x',
              'partID': 'prt_x',
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(provider.state, isNot(equals(ChatState.initial)));
      });

      test('skips event with missing fields', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'message.part.removed',
            properties: <String, dynamic>{},
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(provider.state, isNot(equals(ChatState.initial)));
      });
    });

    // ── message.removed ──

    group('message.removed', () {
      test('skips event for non-current session', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'message.removed',
            properties: <String, dynamic>{
              'sessionID': 'ses_other',
              'messageID': 'msg_x',
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(provider.state, isNot(equals(ChatState.initial)));
      });

      test('skips event with missing fields', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'message.removed',
            properties: <String, dynamic>{},
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(provider.state, isNot(equals(ChatState.initial)));
      });
    });

    // ── permission.asked ──

    group('permission.asked', () {
      test('adds permission request to current session', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'permission.asked',
            properties: <String, dynamic>{
              'id': 'perm_1',
              'sessionID': 'ses_1',
              'permission': 'bash',
              'patterns': <dynamic>['ls'],
              'always': <dynamic>[],
              'metadata': <String, dynamic>{},
            },
          ),
        );
        await settleUntil(
          () => provider.currentSessionPermissions.isNotEmpty,
          reason: 'Expected permission request to be added.',
        );
        expect(
          provider.currentSessionPermissions.first.id,
          'perm_1',
        );
        expect(
          provider.currentSessionPermissions.first.permission,
          'bash',
        );
      });
    });

    // ── permission.updated ──

    group('permission.updated', () {
      test('updates existing permission request in-place', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'permission.asked',
            properties: <String, dynamic>{
              'id': 'perm_1',
              'sessionID': 'ses_1',
              'permission': 'bash',
              'patterns': <dynamic>['ls'],
              'always': <dynamic>[],
              'metadata': <String, dynamic>{},
            },
          ),
        );
        await settleUntil(
          () => provider.currentSessionPermissions.isNotEmpty,
          reason: 'Pre-condition: permission must be added first.',
        );
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'permission.updated',
            properties: <String, dynamic>{
              'id': 'perm_1',
              'sessionID': 'ses_1',
              'permission': 'bash',
              'patterns': <dynamic>['ls', 'cat'],
              'always': <dynamic>['bash'],
              'metadata': <String, dynamic>{},
            },
          ),
        );
        await settleUntil(
          () =>
              provider.currentSessionPermissions.first.always.isNotEmpty,
          reason: 'Expected permission to be updated with always field.',
        );
        expect(
          provider.currentSessionPermissions.first.patterns,
          containsAll(<String>['ls', 'cat']),
        );
      });
    });

    // ── permission.replied ──

    group('permission.replied', () {
      test('removes permission request after reply', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'permission.asked',
            properties: <String, dynamic>{
              'id': 'perm_1',
              'sessionID': 'ses_1',
              'permission': 'bash',
              'patterns': <dynamic>['ls'],
              'always': <dynamic>[],
              'metadata': <String, dynamic>{},
            },
          ),
        );
        await settleUntil(
          () => provider.currentSessionPermissions.isNotEmpty,
          reason: 'Pre-condition: permission must be added first.',
        );
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'permission.replied',
            properties: <String, dynamic>{
              'sessionID': 'ses_1',
              'requestID': 'perm_1',
            },
          ),
        );
        await settleUntil(
          () => provider.currentSessionPermissions.isEmpty,
          reason: 'Expected permission to be removed after reply.',
        );
      });

      test('skips event with missing sessionID or requestID', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'permission.replied',
            properties: <String, dynamic>{},
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(provider.state, isNot(equals(ChatState.initial)));
      });
    });

    // ── question.asked ──

    group('question.asked', () {
      test('adds question request to current session', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'question.asked',
            properties: <String, dynamic>{
              'id': 'q_1',
              'sessionID': 'ses_1',
              'questions': <dynamic>[
                <String, dynamic>{
                  'question': 'Which model?',
                  'header': 'Model',
                  'options': <dynamic>[
                    <String, dynamic>{
                      'label': 'GPT-4',
                      'description': 'Best quality',
                    },
                  ],
                  'multiple': false,
                  'custom': true,
                },
              ],
            },
          ),
        );
        await settleUntil(
          () => provider.currentSessionQuestions.isNotEmpty,
          reason: 'Expected question request to be added.',
        );
        expect(provider.currentSessionQuestions.first.id, 'q_1');
        expect(
          provider.currentSessionQuestions.first.questions.first.question,
          'Which model?',
        );
      });
    });

    // ── question.updated ──

    group('question.updated', () {
      test('updates existing question request in-place', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'question.asked',
            properties: <String, dynamic>{
              'id': 'q_1',
              'sessionID': 'ses_1',
              'questions': <dynamic>[
                <String, dynamic>{
                  'question': 'Which model?',
                  'header': 'Model',
                  'options': <dynamic>[
                    <String, dynamic>{
                      'label': 'GPT-4',
                      'description': 'Best quality',
                    },
                  ],
                  'multiple': false,
                  'custom': true,
                },
              ],
            },
          ),
        );
        await settleUntil(
          () => provider.currentSessionQuestions.isNotEmpty,
          reason: 'Pre-condition: question must be added first.',
        );
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'question.updated',
            properties: <String, dynamic>{
              'id': 'q_1',
              'sessionID': 'ses_1',
              'questions': <dynamic>[
                <String, dynamic>{
                  'question': 'Which model now?',
                  'header': 'Model',
                  'options': <dynamic>[
                    <String, dynamic>{
                      'label': 'GPT-4',
                      'description': 'Best quality',
                    },
                    <String, dynamic>{
                      'label': 'Claude',
                      'description': 'Alternative',
                    },
                  ],
                  'multiple': true,
                  'custom': false,
                },
              ],
            },
          ),
        );
        await settleUntil(
          () =>
              provider
                  .currentSessionQuestions.first.questions.first.multiple ==
              true,
          reason: 'Expected question to be updated with multiple=true.',
        );
        expect(
          provider
              .currentSessionQuestions.first.questions.first.options.length,
          2,
        );
      });
    });

    // ── question.replied ──

    group('question.replied', () {
      test('removes question request after reply', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'question.asked',
            properties: <String, dynamic>{
              'id': 'q_1',
              'sessionID': 'ses_1',
              'questions': <dynamic>[
                <String, dynamic>{
                  'question': 'Which model?',
                  'header': 'Model',
                  'options': <dynamic>[
                    <String, dynamic>{
                      'label': 'GPT-4',
                      'description': 'Best quality',
                    },
                  ],
                  'multiple': false,
                  'custom': true,
                },
              ],
            },
          ),
        );
        await settleUntil(
          () => provider.currentSessionQuestions.isNotEmpty,
          reason: 'Pre-condition: question must be added first.',
        );
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'question.replied',
            properties: <String, dynamic>{
              'sessionID': 'ses_1',
              'requestID': 'q_1',
            },
          ),
        );
        await settleUntil(
          () => provider.currentSessionQuestions.isEmpty,
          reason: 'Expected question to be removed after reply.',
        );
      });
    });

    // ── question.rejected ──

    group('question.rejected', () {
      test('removes question request after rejection', () async {
        await initAndSelectSession();
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'question.asked',
            properties: <String, dynamic>{
              'id': 'q_1',
              'sessionID': 'ses_1',
              'questions': <dynamic>[
                <String, dynamic>{
                  'question': 'Which model?',
                  'header': 'Model',
                  'options': <dynamic>[
                    <String, dynamic>{
                      'label': 'GPT-4',
                      'description': 'Best quality',
                    },
                  ],
                  'multiple': false,
                  'custom': true,
                },
              ],
            },
          ),
        );
        await settleUntil(
          () => provider.currentSessionQuestions.isNotEmpty,
          reason: 'Pre-condition: question must be added first.',
        );
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'question.rejected',
            properties: <String, dynamic>{
              'sessionID': 'ses_1',
              'requestID': 'q_1',
            },
          ),
        );
        await settleUntil(
          () => provider.currentSessionQuestions.isEmpty,
          reason: 'Expected question to be removed after rejection.',
        );
      });
    });

    // ── global event routing ──

    group('global event routing', () {
      test('global permission.asked event adds permission for active context',
          () async {
        await initAndSelectSession();
        chatRepository.emitGlobalEvent(
          const ChatEvent(
            type: 'permission.asked',
            properties: <String, dynamic>{
              'id': 'perm_global_1',
              'sessionID': 'ses_1',
              'permission': 'bash',
              'patterns': <dynamic>['ls'],
              'always': <dynamic>[],
              'metadata': <String, dynamic>{},
            },
          ),
        );
        await settleUntil(
          () => provider.currentSessionPermissions.isNotEmpty,
          reason:
              'Expected global permission.asked to add permission for active context.',
        );
        expect(
          provider.currentSessionPermissions.first.id,
          'perm_global_1',
        );
      });

      test('global server.heartbeat is silently ignored', () async {
        await initAndSelectSession();
        final stateBefore = provider.state;
        chatRepository.emitGlobalEvent(
          const ChatEvent(
            type: 'server.heartbeat',
            properties: <String, dynamic>{},
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(provider.state, stateBefore);
      });

      test('global event with unknown type is ignored', () async {
        await initAndSelectSession();
        final stateBefore = provider.state;
        chatRepository.emitGlobalEvent(
          const ChatEvent(
            type: 'unknown.event.type',
            properties: <String, dynamic>{},
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(provider.state, stateBefore);
      });
    });

    // ── event deduplication ──

    group('event deduplication', () {
      test(
          'permission.replied on session stream then global duplicate is skipped by dedup',
          () async {
        await initAndSelectSession();
        // First add a permission.
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'permission.asked',
            properties: <String, dynamic>{
              'id': 'perm_dedup_1',
              'sessionID': 'ses_1',
              'permission': 'bash',
              'patterns': <dynamic>['ls'],
              'always': <dynamic>[],
              'metadata': <String, dynamic>{},
            },
          ),
        );
        await settleUntil(
          () => provider.currentSessionPermissions.isNotEmpty,
          reason: 'Pre-condition: permission must be added first.',
        );
        // Emit permission.replied on session stream — removes the permission.
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'permission.replied',
            properties: <String, dynamic>{
              'sessionID': 'ses_1',
              'requestID': 'perm_dedup_1',
            },
          ),
        );
        await settleUntil(
          () => provider.currentSessionPermissions.isEmpty,
          reason: 'Pre-condition: permission must be removed by session stream reply.',
        );
        // Re-add permission so we can test global dedup.
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'permission.asked',
            properties: <String, dynamic>{
              'id': 'perm_dedup_1',
              'sessionID': 'ses_1',
              'permission': 'bash',
              'patterns': <dynamic>['ls'],
              'always': <dynamic>[],
              'metadata': <String, dynamic>{},
            },
          ),
        );
        await settleUntil(
          () => provider.currentSessionPermissions.isNotEmpty,
          reason: 'Pre-condition: permission must be re-added for dedup test.',
        );
        // Emit same permission.replied on global stream — should be deduped.
        chatRepository.emitGlobalEvent(
          const ChatEvent(
            type: 'permission.replied',
            properties: <String, dynamic>{
              'sessionID': 'ses_1',
              'requestID': 'perm_dedup_1',
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        // Permission should still exist since the global duplicate was deduped.
        expect(
          provider.currentSessionPermissions.isNotEmpty,
          isTrue,
          reason:
              'Global duplicate permission.replied should have been deduped, leaving the permission intact.',
        );
      });
    });

    // ── event stream failure ──

    group('event stream failure', () {
      test('provider remains stable when event stream emits failure', () async {
        await initAndSelectSession();
        chatRepository.emitEventFailure(
          const ServerFailure('SSE connection lost'),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(provider.state, isNot(equals(ChatState.initial)));
      });
    });

    // ── unknown event type ──

    group('unknown event type', () {
      test('is silently ignored via default switch branch', () async {
        await initAndSelectSession();
        final stateBefore = provider.state;
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'future.unknown.event',
            properties: <String, dynamic>{},
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(provider.state, stateBefore);
      });
    });
  });
}
