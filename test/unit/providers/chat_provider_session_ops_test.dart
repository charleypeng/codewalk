@Tags(<String>['slow'])
library;

import 'dart:async';

import 'package:codewalk/core/errors/failures.dart';
import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/domain/entities/chat_message.dart';
import 'package:codewalk/domain/entities/chat_realtime.dart';
import 'package:codewalk/domain/entities/chat_session.dart';
import 'package:codewalk/domain/entities/provider.dart';
import 'package:codewalk/presentation/providers/chat_provider.dart';
import 'package:codewalk/presentation/providers/settings_provider.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import 'chat_provider_test_support.dart';

void main() {
  group('ChatProvider - session ops', () {
    late FakeChatRepository chatRepository;
    late FakeAppRepository appRepository;
    late InMemoryAppLocalDataSource localDataSource;
    late ChatProvider provider;
    late SettingsProvider defaultSettingsProvider;

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

    test('renameSession applies persisted title on success', () async {
      await provider.loadSessions();
      final session = provider.sessions.first;

      final ok = await provider.renameSession(session, 'Renamed Session');
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(ok, isTrue);
      expect(
        provider.sessions.where((item) => item.id == session.id).first.title,
        'Renamed Session',
      );
      expect(
        chatRepository.sessions
            .where((item) => item.id == session.id)
            .first
            .title,
        'Renamed Session',
      );
    });

    test(
      'renameSession returns true for no-op rename with same title',
      () async {
        await provider.loadSessions();
        final session = provider.sessions.first;

        final ok = await provider.renameSession(session, 'Session 1');

        expect(ok, isTrue);
        expect(
          provider.sessions.where((item) => item.id == session.id).first.title,
          'Session 1',
        );
      },
    );

    test('renameSession rolls back optimistic title on failure', () async {
      await provider.loadSessions();
      final session = provider.sessions.first;
      chatRepository.updateSessionFailure = const ServerFailure(
        'update failed',
      );

      final ok = await provider.renameSession(session, 'Broken Rename');
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(ok, isFalse);
      expect(
        provider.sessions.where((item) => item.id == session.id).first.title,
        'Session 1',
      );
      expect(provider.state, ChatState.error);
    });

    test(
      'share/archive/fork lifecycle operations update provider state',
      () async {
        chatRepository.sessions.add(
          ChatSession(
            id: 'ses_2',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1200),
            title: 'Session 2',
          ),
        );

        await provider.loadSessions();
        await provider.selectSession(
          provider.sessions.where((item) => item.id == 'ses_1').first,
        );

        final shared = await provider.toggleSessionShare(
          provider.currentSession!,
        );
        expect(shared, isTrue);
        expect(provider.currentSession?.shared, isTrue);
        expect(provider.currentSession?.shareUrl, isNotNull);

        final archived = await provider.setSessionArchived(
          provider.currentSession!,
          true,
        );
        expect(archived, isTrue);
        final archivedSession = provider.sessions
            .where((item) => item.id == 'ses_1')
            .first;
        expect(archivedSession.archived, isTrue);

        final unarchived = await provider.setSessionArchived(
          archivedSession,
          false,
        );
        expect(unarchived, isTrue);
        final unarchivedSession = provider.sessions
            .where((item) => item.id == 'ses_1')
            .first;
        expect(unarchivedSession.archived, isFalse);

        final forked = await provider.forkSession(unarchivedSession);
        expect(forked, isNotNull);
        expect(forked?.parentId, 'ses_1');
        expect(provider.currentSession?.id, forked?.id);
      },
    );

    test(
      'loadSessionInsights updates children, todo, diff and status maps',
      () async {
        final child = ChatSession(
          id: 'ses_child_1',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(2000),
          title: 'Child Session',
          parentId: 'ses_1',
        );
        chatRepository.sessionChildrenById['ses_1'] = <ChatSession>[child];
        chatRepository.sessionTodoById['ses_1'] = const <SessionTodo>[
          SessionTodo(
            id: 'todo_1',
            content: 'Implement feature',
            status: 'in_progress',
            priority: 'high',
          ),
        ];
        chatRepository.sessionDiffById['ses_1'] = const <SessionDiff>[
          SessionDiff(
            file: 'lib/main.dart',
            before: '',
            after: '',
            additions: 10,
            deletions: 2,
            status: 'modified',
          ),
        ];
        chatRepository.sessionStatusById = const <String, SessionStatusInfo>{
          'ses_1': SessionStatusInfo(type: SessionStatusType.busy),
        };

        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);
        await provider.loadSessionInsights('ses_1');

        expect(provider.currentSessionChildren, hasLength(1));
        expect(provider.currentSessionChildren.single.id, 'ses_child_1');
        expect(provider.currentSessionTodo, hasLength(1));
        expect(provider.currentSessionTodo.single.id, 'todo_1');
        expect(provider.currentSessionDiff, hasLength(1));
        expect(provider.currentSessionDiff.single.file, 'lib/main.dart');
        expect(provider.currentSessionStatus?.type, SessionStatusType.busy);
      },
    );

    test(
      'deleteSession clears current session when deleting active one',
      () async {
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);

        expect(provider.currentSession?.id, 'ses_1');

        await provider.deleteSession('ses_1');
        await Future<void>.delayed(const Duration(milliseconds: 5));

        expect(provider.sessions, isEmpty);
        expect(provider.currentSession, isNull);
        expect(provider.messages, isEmpty);
      },
    );

    test('loadSessions surfaces mapped failure state', () async {
      chatRepository.getSessionsFailure = const NetworkFailure('no network');

      await provider.loadSessions();

      expect(provider.state, ChatState.error);
      expect(
        provider.errorMessage,
        'Network connection failed. Please check network settings',
      );
    });

    test(
      'applies realtime message.updated fallback fetch and session status',
      () async {
        final draft = AssistantMessage(
          id: 'msg_ai_live',
          sessionId: 'ses_1',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          parts: const <MessagePart>[
            TextPart(
              id: 'prt_draft',
              messageId: 'msg_ai_live',
              sessionId: 'ses_1',
              text: 'draft',
            ),
          ],
        );
        final completed = AssistantMessage(
          id: 'msg_ai_live',
          sessionId: 'ses_1',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          completedTime: DateTime.fromMillisecondsSinceEpoch(1500),
          parts: const <MessagePart>[
            TextPart(
              id: 'prt_done',
              messageId: 'msg_ai_live',
              sessionId: 'ses_1',
              text: 'done',
            ),
          ],
        );
        chatRepository.messagesBySession['ses_1'] = <ChatMessage>[draft];

        appRepository.providersResult = Right(
          ProvidersResponse(
            providers: <Provider>[
              Provider(
                id: 'provider_a',
                name: 'Provider A',
                env: const <String>[],
                models: <String, Model>{'model_a': testModel('model_a')},
              ),
            ],
            defaultModels: const <String, String>{'provider_a': 'model_a'},
            connected: const <String>['provider_a'],
          ),
        );

        await provider.initializeProviders();
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);
        expect(
          ((provider.messages.single as AssistantMessage).parts.single
                  as TextPart)
              .text,
          'draft',
        );

        chatRepository.messagesBySession['ses_1'] = <ChatMessage>[completed];
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'message.updated',
            properties: <String, dynamic>{
              'info': <String, dynamic>{
                'id': 'msg_ai_live',
                'sessionID': 'ses_1',
              },
            },
          ),
        );
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.status',
            properties: <String, dynamic>{
              'sessionID': 'ses_1',
              'status': <String, dynamic>{'type': 'busy'},
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));

        final message = provider.messages.single as AssistantMessage;
        expect((message.parts.single as TextPart).text, 'done');
        expect(message.isCompleted, isTrue);
        expect(provider.currentSessionStatus?.type, SessionStatusType.busy);
      },
    );

    test(
      'does not treat stale in-progress assistant as active response without busy status',
      () async {
        final draft = AssistantMessage(
          id: 'msg_ai_stale_draft',
          sessionId: 'ses_1',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          parts: const <MessagePart>[
            TextPart(
              id: 'prt_stale_draft',
              messageId: 'msg_ai_stale_draft',
              sessionId: 'ses_1',
              text: 'draft still open',
            ),
          ],
        );

        chatRepository.messagesBySession['ses_1'] = <ChatMessage>[draft];
        chatRepository.sessionStatusById = const <String, SessionStatusInfo>{
          'ses_1': SessionStatusInfo(type: SessionStatusType.idle),
        };

        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);
        await provider.loadSessionInsights('ses_1');

        expect(provider.currentSessionStatus?.type, SessionStatusType.idle);
        expect(provider.isCurrentSessionActivelyResponding, isFalse);
        expect(provider.canAbortActiveResponse, isFalse);

        chatRepository.sessionStatusById = const <String, SessionStatusInfo>{
          'ses_1': SessionStatusInfo(type: SessionStatusType.busy),
        };
        await provider.loadSessionInsights('ses_1');

        expect(provider.currentSessionStatus?.type, SessionStatusType.busy);
        expect(provider.isCurrentSessionActivelyResponding, isTrue);
        expect(provider.canAbortActiveResponse, isTrue);
      },
    );

    test(
      'treats busy tool-only assistant turn as actively responding',
      () async {
        final toolOnlyAssistant = AssistantMessage(
          id: 'msg_ai_tool_only',
          sessionId: 'ses_1',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          completedTime: DateTime.fromMillisecondsSinceEpoch(1100),
          parts: <MessagePart>[
            ToolPart(
              id: 'prt_tool_only',
              messageId: 'msg_ai_tool_only',
              sessionId: 'ses_1',
              callId: 'call_tool_only',
              tool: 'bash',
              state: ToolStateCompleted(
                input: const <String, dynamic>{'command': 'ls'},
                output: 'README.md',
                time: ToolTime(
                  start: DateTime.fromMillisecondsSinceEpoch(1000),
                  end: DateTime.fromMillisecondsSinceEpoch(1050),
                ),
              ),
            ),
          ],
        );

        chatRepository.messagesBySession['ses_1'] = <ChatMessage>[
          toolOnlyAssistant,
        ];
        chatRepository.sessionStatusById = const <String, SessionStatusInfo>{
          'ses_1': SessionStatusInfo(type: SessionStatusType.busy),
        };

        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);
        await provider.loadSessionInsights('ses_1');

        expect(provider.currentSessionStatus?.type, SessionStatusType.busy);
        expect(provider.isCurrentSessionActivelyResponding, isTrue);
        expect(provider.canAbortActiveResponse, isTrue);
      },
    );

    test('loadSessionInsights calls all 4 endpoints', () async {
      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);

      // Reset counters after selectSession (which also calls loadSessionInsights).
      chatRepository.getSessionChildrenCallCount = 0;
      chatRepository.getSessionTodoCallCount = 0;
      chatRepository.getSessionDiffCallCount = 0;
      chatRepository.getSessionStatusCallCount = 0;

      await provider.loadSessionInsights('ses_1');

      expect(chatRepository.getSessionChildrenCallCount, 1);
      expect(chatRepository.getSessionTodoCallCount, 1);
      expect(chatRepository.getSessionDiffCallCount, 1);
      expect(chatRepository.getSessionStatusCallCount, 1);
    });

    test('loadSessionInsights handles partial failures gracefully', () async {
      chatRepository.sessionChildrenFailure = const ServerFailure(
        'children down',
      );
      chatRepository.sessionDiffFailure = const ServerFailure('diff down');
      chatRepository.sessionTodoById['ses_1'] = const <SessionTodo>[
        SessionTodo(
          id: 'todo_partial',
          content: 'Survive failure',
          status: 'pending',
          priority: 'low',
        ),
      ];
      chatRepository.sessionStatusById = const <String, SessionStatusInfo>{
        'ses_1': SessionStatusInfo(type: SessionStatusType.idle),
      };

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.loadSessionInsights('ses_1');

      // Todo and status populated despite children and diff failing.
      expect(provider.currentSessionTodo, hasLength(1));
      expect(provider.currentSessionTodo.single.id, 'todo_partial');
      expect(provider.currentSessionStatus?.type, SessionStatusType.idle);
    });

    test(
      'loadSessionInsights keeps partial data when one endpoint throws',
      () async {
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);

        chatRepository.sessionTodoById['ses_1'] = const <SessionTodo>[
          SessionTodo(
            id: 'todo_after_throw',
            content: 'Still available',
            status: 'pending',
            priority: 'low',
          ),
        ];
        chatRepository.sessionStatusById = const <String, SessionStatusInfo>{
          'ses_1': SessionStatusInfo(type: SessionStatusType.idle),
        };
        chatRepository.getSessionChildrenDelay = () async {
          throw StateError('children boom');
        };

        await expectLater(provider.loadSessionInsights('ses_1'), completes);

        expect(provider.currentSessionTodo, hasLength(1));
        expect(provider.currentSessionTodo.single.id, 'todo_after_throw');
        expect(provider.currentSessionStatus?.type, SessionStatusType.idle);
        expect(provider.isLoadingSessionInsights, isFalse);
      },
    );

    test(
      'loadSessionInsights clears loading flag when status throws',
      () async {
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);

        chatRepository.getSessionStatusDelay = () async {
          throw StateError('status boom');
        };

        await expectLater(provider.loadSessionInsights('ses_1'), completes);

        expect(provider.isLoadingSessionInsights, isFalse);
        expect(
          provider.sessionInsightsError,
          'Some session details could not be loaded',
        );
      },
    );

    test('loadSessionInsights runs calls concurrently', () async {
      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);

      // Set up delay hooks AFTER selectSession to avoid blocking it.
      final childrenStarted = Completer<void>();
      final todoStarted = Completer<void>();
      final gate = Completer<void>();

      // Children blocks on gate; todo signals when it starts.
      chatRepository.getSessionChildrenDelay = () async {
        childrenStarted.complete();
        await gate.future;
      };
      chatRepository.getSessionTodoDelay = () async {
        todoStarted.complete();
      };

      final insightsFuture = provider.loadSessionInsights('ses_1');

      // If sequential, todo would never start while children is blocked.
      // With parallel execution, todo starts independently.
      await todoStarted.future;
      expect(childrenStarted.isCompleted, isTrue);

      // Release the gate so loadSessionInsights can finish.
      gate.complete();
      await insightsFuture;
    });

    test('loadSessionInsights does not set loading flag when silent', () async {
      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);

      bool sawLoading = false;
      provider.addListener(() {
        if (provider.isLoadingSessionInsights) {
          sawLoading = true;
        }
      });

      await provider.loadSessionInsights('ses_1', silent: true);

      expect(sawLoading, isFalse);
    });

    test(
      'session.idle does not clear active stream activity for current session',
      () async {
        final sendStream = StreamController<Either<Failure, ChatMessage>>();
        addTearDown(() async {
          await sendStream.close();
        });
        chatRepository.sendMessageHandler = (_, _, _, _) => sendStream.stream;

        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);
        await provider.initializeProviders();

        await provider.sendMessage('pending stream');
        expect(provider.isCurrentSessionActivelyResponding, isTrue);
        expect(provider.canAbortActiveResponse, isTrue);

        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.idle',
            properties: <String, dynamic>{'sessionID': 'ses_1'},
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(
          provider.currentSessionStatus?.type,
          isNot(SessionStatusType.idle),
        );
        expect(provider.isCurrentSessionActivelyResponding, isTrue);
        expect(provider.canAbortActiveResponse, isTrue);
      },
    );

    test('refreshes active session when realtime stream reconnects', () async {
      final draft = AssistantMessage(
        id: 'msg_ai_live',
        sessionId: 'ses_1',
        time: DateTime.fromMillisecondsSinceEpoch(1000),
        parts: const <MessagePart>[
          TextPart(
            id: 'prt_draft',
            messageId: 'msg_ai_live',
            sessionId: 'ses_1',
            text: 'draft',
          ),
        ],
      );
      final updated = AssistantMessage(
        id: 'msg_ai_live',
        sessionId: 'ses_1',
        time: DateTime.fromMillisecondsSinceEpoch(1000),
        completedTime: DateTime.fromMillisecondsSinceEpoch(1800),
        parts: const <MessagePart>[
          TextPart(
            id: 'prt_done',
            messageId: 'msg_ai_live',
            sessionId: 'ses_1',
            text: 'done after reconnect',
          ),
        ],
      );
      chatRepository.messagesBySession['ses_1'] = <ChatMessage>[draft];
      chatRepository.sessionStatusById = const <String, SessionStatusInfo>{
        'ses_1': SessionStatusInfo(type: SessionStatusType.idle),
      };

      appRepository.providersResult = Right(
        ProvidersResponse(
          providers: <Provider>[
            Provider(
              id: 'provider_a',
              name: 'Provider A',
              env: const <String>[],
              models: <String, Model>{'model_a': testModel('model_a')},
            ),
          ],
          defaultModels: const <String, String>{'provider_a': 'model_a'},
          connected: const <String>['provider_a'],
        ),
      );

      await provider.initializeProviders();
      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      expect(
        ((provider.messages.single as AssistantMessage).parts.single
                as TextPart)
            .text,
        'draft',
      );

      chatRepository.messagesBySession['ses_1'] = <ChatMessage>[updated];
      chatRepository.sessionStatusById = const <String, SessionStatusInfo>{
        'ses_1': SessionStatusInfo(type: SessionStatusType.busy),
      };
      chatRepository.emitEvent(
        const ChatEvent(
          type: 'server.connected',
          properties: <String, dynamic>{},
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));

      final message = provider.messages.single as AssistantMessage;
      expect((message.parts.single as TextPart).text, 'done after reconnect');
      expect(provider.currentSessionStatus?.type, SessionStatusType.busy);
    });

    test(
      'refreshActiveSessionView scrolls when latest message changes even if session is idle',
      () async {
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);

        chatRepository.sessionStatusById = const <String, SessionStatusInfo>{
          'ses_1': SessionStatusInfo(type: SessionStatusType.busy),
        };
        await provider.loadSessionInsights('ses_1');

        var scrollRequests = 0;
        provider.setScrollToBottomCallback(() {
          scrollRequests += 1;
        });

        chatRepository.messagesBySession['ses_1'] = <ChatMessage>[
          AssistantMessage(
            id: 'msg_refresh_scroll',
            sessionId: 'ses_1',
            time: DateTime.fromMillisecondsSinceEpoch(2000),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_refresh_scroll',
                messageId: 'msg_refresh_scroll',
                sessionId: 'ses_1',
                text: 'fresh message from refresh',
              ),
            ],
          ),
        ];

        await provider.refreshActiveSessionView(includeStatus: false);
        // Flush microtask-coalesced scroll callback.
        await Future<void>.value();

        expect(scrollRequests, 1);
      },
    );

    test(
      'refreshActiveSessionView preserves active local tail against stale snapshot',
      () async {
        final sendStream = StreamController<Either<Failure, ChatMessage>>();
        addTearDown(() async {
          await sendStream.close();
        });
        chatRepository.sendMessageHandler = (_, _, _, _) => sendStream.stream;

        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);

        unawaited(provider.sendMessage('Run live tools'));
        await Future<void>.delayed(Duration.zero);

        final liveAssistant = AssistantMessage(
          id: 'msg_live_tail',
          sessionId: 'ses_1',
          time: DateTime.fromMillisecondsSinceEpoch(2200),
          parts: <MessagePart>[
            ToolPart(
              id: 'part_live_tail_tool',
              messageId: 'msg_live_tail',
              sessionId: 'ses_1',
              callId: 'call_live_tail_tool',
              tool: 'bash',
              state: ToolStateRunning(
                input: const <String, dynamic>{
                  'description': 'Collecting runtime details',
                  'command': 'git status --short',
                },
                time: DateTime.fromMillisecondsSinceEpoch(2200),
              ),
            ),
          ],
        );

        sendStream.add(Right(liveAssistant));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(provider.isCurrentSessionActivelyResponding, isTrue);
        expect(
          provider.messages.any((msg) => msg.id == 'msg_live_tail'),
          isTrue,
        );

        chatRepository.messagesBySession['ses_1'] = const <ChatMessage>[];
        await provider.refreshActiveSessionView(includeStatus: false);

        expect(provider.isCurrentSessionActivelyResponding, isTrue);
        expect(
          provider.messages.any((msg) => msg.id == 'msg_live_tail'),
          isTrue,
        );
      },
    );

    test(
      'enters degraded mode after repeated stream failures and recovers on signal',
      () async {
        appRepository.providersResult = Right(
          ProvidersResponse(
            providers: <Provider>[
              Provider(
                id: 'provider_a',
                name: 'Provider A',
                env: const <String>[],
                models: <String, Model>{'model_a': testModel('model_a')},
              ),
            ],
            defaultModels: const <String, String>{'provider_a': 'model_a'},
            connected: const <String>['provider_a'],
          ),
        );

        await provider.initializeProviders();
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);

        chatRepository.emitEventFailure(const NetworkFailure('stream down 1'));
        chatRepository.emitEventFailure(const NetworkFailure('stream down 2'));
        chatRepository.emitEventFailure(const NetworkFailure('stream down 3'));
        await Future<void>.delayed(const Duration(milliseconds: 60));

        expect(provider.isInDegradedMode, isTrue);
        expect(provider.syncState, ChatSyncState.delayed);

        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.status',
            properties: <String, dynamic>{
              'sessionID': 'ses_1',
              'status': <String, dynamic>{'type': 'idle'},
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 60));

        expect(provider.isInDegradedMode, isFalse);
        expect(provider.syncState, ChatSyncState.connected);
      },
    );

    test(
      'resume foreground re-subscribes and reconciles session state',
      () async {
        final nextMessage = AssistantMessage(
          id: 'msg_resume',
          sessionId: 'ses_1',
          time: DateTime.fromMillisecondsSinceEpoch(2000),
          completedTime: DateTime.fromMillisecondsSinceEpoch(2100),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_resume',
              messageId: 'msg_resume',
              sessionId: 'ses_1',
              text: 'after resume',
            ),
          ],
        );
        chatRepository.messagesBySession['ses_1'] = <ChatMessage>[nextMessage];

        appRepository.providersResult = Right(
          ProvidersResponse(
            providers: <Provider>[
              Provider(
                id: 'provider_a',
                name: 'Provider A',
                env: const <String>[],
                models: <String, Model>{'model_a': testModel('model_a')},
              ),
            ],
            defaultModels: const <String, String>{'provider_a': 'model_a'},
            connected: const <String>['provider_a'],
          ),
        );

        await provider.initializeProviders();
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);

        final sessionsBefore = chatRepository.getSessionsCallCount;
        final messagesBefore = chatRepository.getMessagesCallCount;

        await provider.setForegroundActive(false);
        await provider.setForegroundActive(true);
        await Future<void>.delayed(const Duration(milliseconds: 80));

        expect(
          chatRepository.getSessionsCallCount,
          greaterThan(sessionsBefore),
        );
        expect(
          chatRepository.getMessagesCallCount,
          greaterThan(messagesBefore),
        );
        expect(
          ((provider.messages.single as AssistantMessage).parts.single
                  as TextPart)
              .text,
          'after resume',
        );
      },
    );

    test(
      'global session.updated applies incrementally without broad session reload',
      () async {
        appRepository.providersResult = Right(
          ProvidersResponse(
            providers: <Provider>[
              Provider(
                id: 'provider_a',
                name: 'Provider A',
                env: const <String>[],
                models: <String, Model>{'model_a': testModel('model_a')},
              ),
            ],
            defaultModels: const <String, String>{'provider_a': 'model_a'},
            connected: const <String>['provider_a'],
          ),
        );

        await provider.initializeProviders();
        await provider.loadSessions();
        final sessionsBefore = chatRepository.getSessionsCallCount;
        final activeDirectory = provider.projectProvider.currentDirectory;

        chatRepository.emitGlobalEvent(
          ChatEvent(
            type: 'session.updated',
            properties: <String, dynamic>{
              'directory': ?activeDirectory,
              'info': const <String, dynamic>{
                'id': 'ses_1',
                'workspaceId': 'default',
                'title': 'Session 1 renamed',
                'time': <String, dynamic>{'created': 1000, 'updated': 2000},
              },
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(provider.sessions.first.title, 'Session 1 renamed');
        expect(chatRepository.getSessionsCallCount, sessionsBefore);
      },
    );

    test(
      'global session.updated preserves parentId when payload omits parent fields',
      () async {
        chatRepository.sessions
          ..clear()
          ..addAll(<ChatSession>[
            ChatSession(
              id: 'ses_parent',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              title: 'Parent',
            ),
            ChatSession(
              id: 'ses_child',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(2000),
              title: 'Child',
              parentId: 'ses_parent',
            ),
          ]);

        appRepository.providersResult = Right(
          ProvidersResponse(
            providers: <Provider>[
              Provider(
                id: 'provider_a',
                name: 'Provider A',
                env: const <String>[],
                models: <String, Model>{'model_a': testModel('model_a')},
              ),
            ],
            defaultModels: const <String, String>{'provider_a': 'model_a'},
            connected: const <String>['provider_a'],
          ),
        );

        await provider.initializeProviders();
        await provider.loadSessions();
        final activeDirectory = provider.projectProvider.currentDirectory;

        chatRepository.emitGlobalEvent(
          ChatEvent(
            type: 'session.updated',
            properties: <String, dynamic>{
              'directory': ?activeDirectory,
              'info': const <String, dynamic>{
                'id': 'ses_child',
                'workspaceId': 'default',
                'title': 'Child renamed',
                'time': <String, dynamic>{'created': 2000, 'updated': 3000},
              },
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final updatedChild = provider.sessions
            .where((session) => session.id == 'ses_child')
            .first;
        expect(updatedChild.title, 'Child renamed');
        expect(updatedChild.parentId, 'ses_parent');
      },
    );

    test(
      'visibleSessions keeps ancestors needed for tree grouping beyond limit',
      () async {
        chatRepository.sessions
          ..clear()
          ..add(
            ChatSession(
              id: 'ses_parent',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              title: 'Parent',
            ),
          )
          ..add(
            ChatSession(
              id: 'ses_child',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(999999),
              title: 'Child',
              parentId: 'ses_parent',
            ),
          )
          ..addAll(
            List<ChatSession>.generate(
              44,
              (index) => ChatSession(
                id: 'ses_root_$index',
                workspaceId: 'default',
                time: DateTime.fromMillisecondsSinceEpoch(900000 - index),
                title: 'Root $index',
              ),
            ),
          );

        await provider.loadSessions();

        expect(
          provider.visibleSessions.where((s) => s.id == 'ses_child'),
          isNotEmpty,
        );
        expect(
          provider.visibleSessions.where((s) => s.id == 'ses_parent'),
          isNotEmpty,
        );
      },
    );

    test(
      'ignores conflicting session.updated events while rename is pending',
      () async {
        appRepository.providersResult = Right(
          ProvidersResponse(
            providers: <Provider>[
              Provider(
                id: 'provider_a',
                name: 'Provider A',
                env: const <String>[],
                models: <String, Model>{'model_a': testModel('model_a')},
              ),
            ],
            defaultModels: const <String, String>{'provider_a': 'model_a'},
            connected: const <String>['provider_a'],
          ),
        );

        final renameCompleter = Completer<Either<Failure, ChatSession>>();
        chatRepository.updateSessionHandler = (_, sessionId, input, _) {
          return renameCompleter.future;
        };

        await provider.initializeProviders();
        await provider.loadSessions();
        final session = provider.sessions.first;
        final activeDirectory = provider.projectProvider.currentDirectory;

        final renameFuture = provider.renameSession(session, 'Local Rename');
        await Future<void>.delayed(const Duration(milliseconds: 5));
        expect(provider.sessions.first.title, 'Local Rename');

        chatRepository.emitGlobalEvent(
          ChatEvent(
            type: 'session.updated',
            properties: <String, dynamic>{
              'directory': ?activeDirectory,
              'info': <String, dynamic>{
                'id': session.id,
                'workspaceId': session.workspaceId,
                'title': 'Remote Old Title',
                'time': <String, dynamic>{
                  'created': session.time.millisecondsSinceEpoch,
                  'updated': session.time.millisecondsSinceEpoch,
                },
              },
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(provider.sessions.first.title, 'Local Rename');

        final renamedSession = session.copyWith(title: 'Local Rename');
        renameCompleter.complete(Right(renamedSession));
        final ok = await renameFuture;
        await Future<void>.delayed(const Duration(milliseconds: 5));

        expect(ok, isTrue);
        expect(provider.sessions.first.title, 'Local Rename');
      },
    );
  });
}
