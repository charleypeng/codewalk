@Tags(<String>['slow'])
library;

import 'dart:async';
import 'dart:convert';

import 'package:codewalk/core/errors/failures.dart';
import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/data/models/chat_message_model.dart';
import 'package:codewalk/data/models/chat_session_model.dart';
import 'package:codewalk/domain/entities/chat_message.dart';
import 'package:codewalk/domain/entities/chat_session.dart';
import 'package:codewalk/domain/entities/provider.dart';
import 'package:codewalk/domain/usecases/create_chat_session.dart';
import 'package:codewalk/domain/usecases/delete_chat_session.dart';
import 'package:codewalk/domain/usecases/fork_chat_session.dart';
import 'package:codewalk/domain/usecases/get_agents.dart';
import 'package:codewalk/domain/usecases/get_chat_message.dart';
import 'package:codewalk/domain/usecases/get_chat_messages.dart';
import 'package:codewalk/domain/usecases/get_chat_sessions.dart';
import 'package:codewalk/domain/usecases/get_providers.dart';
import 'package:codewalk/domain/usecases/get_session_children.dart';
import 'package:codewalk/domain/usecases/get_session_diff.dart';
import 'package:codewalk/domain/usecases/get_session_status.dart';
import 'package:codewalk/domain/usecases/get_session_todo.dart';
import 'package:codewalk/domain/usecases/list_pending_permissions.dart';
import 'package:codewalk/domain/usecases/list_pending_questions.dart';
import 'package:codewalk/domain/usecases/reject_question.dart';
import 'package:codewalk/domain/usecases/reply_permission.dart';
import 'package:codewalk/domain/usecases/reply_question.dart';
import 'package:codewalk/domain/usecases/send_chat_message.dart';
import 'package:codewalk/domain/usecases/share_chat_session.dart';
import 'package:codewalk/domain/usecases/unshare_chat_session.dart';
import 'package:codewalk/domain/usecases/update_chat_session.dart';
import 'package:codewalk/domain/usecases/watch_chat_events.dart';
import 'package:codewalk/domain/usecases/watch_global_chat_events.dart';
import 'package:codewalk/presentation/providers/chat_provider.dart';
import 'package:codewalk/presentation/providers/project_provider.dart';
import 'package:codewalk/presentation/providers/settings_provider.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import 'chat_provider_test_support.dart';

void main() {
  group('ChatProvider - messaging', () {
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

    test('loadSessions merges cache startup with remote refresh', () async {
      await provider.projectProvider.initializeProject();

      final cachedSession = ChatSession(
        id: 'cached_1',
        workspaceId: 'default',
        time: DateTime.fromMillisecondsSinceEpoch(500),
        title: 'Cached Session',
      );
      final cachedJson = jsonEncode(<Map<String, dynamic>>[
        ChatSessionModel.fromDomain(cachedSession).toJson(),
      ]);
      await localDataSource.saveCachedSessions(
        cachedJson,
        serverId: 'srv_test',
        scopeId: '/tmp',
      );

      await provider.loadSessions();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(provider.state, ChatState.loaded);
      expect(provider.sessions.first.id, anyOf('cached_1', 'ses_1'));

      final savedScoped =
          localDataSource.scopedStrings['cached_sessions::srv_test::/tmp'];
      expect(savedScoped, isNotNull);
      final savedCache = jsonDecode(savedScoped!) as List<dynamic>;
      expect(
        (savedCache.first as Map<String, dynamic>)['id'],
        anyOf('cached_1', 'ses_1'),
      );
    });

    test(
      'loadSessions restores cached last-session snapshot and revalidates silently',
      () async {
        await provider.projectProvider.initializeProject();

        final snapshotSession = chatRepository.sessions.first;
        final snapshotMessage = AssistantMessage(
          id: 'msg_cached',
          sessionId: snapshotSession.id,
          time: DateTime.fromMillisecondsSinceEpoch(1010),
          completedTime: DateTime.fromMillisecondsSinceEpoch(1011),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_cached',
              messageId: 'msg_cached',
              sessionId: 'ses_1',
              text: 'cached assistant reply',
            ),
          ],
        );
        final snapshotPayload = jsonEncode(<String, dynamic>{
          'session': ChatSessionModel.fromDomain(snapshotSession).toJson(),
          'messages': <Map<String, dynamic>>[
            ChatMessageModel.fromDomain(snapshotMessage).toJson(),
          ],
        });

        await localDataSource.saveCurrentSessionId(
          snapshotSession.id,
          serverId: 'srv_test',
          scopeId: '/tmp',
        );
        await localDataSource.saveLastSessionSnapshot(
          snapshotPayload,
          serverId: 'srv_test',
          scopeId: '/tmp',
        );
        await localDataSource.saveLastSessionSnapshotUpdatedAt(
          DateTime.now().millisecondsSinceEpoch,
          serverId: 'srv_test',
          scopeId: '/tmp',
        );

        chatRepository.getMessagesFailure = const NetworkFailure(
          'offline',
          503,
        );

        await provider.loadSessions();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(provider.state, ChatState.loaded);
        expect(provider.currentSession?.id, snapshotSession.id);
        expect(provider.messages, hasLength(1));
        expect(
          (provider.messages.first as AssistantMessage).parts
              .whereType<TextPart>()
              .single
              .text,
          'cached assistant reply',
        );
        expect(provider.errorMessage, isNull);
        expect(chatRepository.getMessagesCallCount, greaterThan(0));
      },
    );

    test(
      'selectSession restores per-session snapshot cache before remote revalidation',
      () async {
        await provider.projectProvider.initializeProject();

        final secondSession = ChatSession(
          id: 'ses_2',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(2000),
          title: 'Session 2',
        );
        chatRepository.sessions.add(secondSession);

        final cachedMessage = AssistantMessage(
          id: 'msg_cached_ses_2',
          sessionId: secondSession.id,
          time: DateTime.fromMillisecondsSinceEpoch(2020),
          completedTime: DateTime.fromMillisecondsSinceEpoch(2021),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_cached_ses_2',
              messageId: 'msg_cached_ses_2',
              sessionId: 'ses_2',
              text: 'cached swr message',
            ),
          ],
        );

        chatRepository.messagesBySession[secondSession.id] = <ChatMessage>[
          cachedMessage,
        ];

        await provider.loadSessions();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        final firstSession = provider.sessions.firstWhere(
          (session) => session.id != secondSession.id,
        );

        await provider.selectSession(secondSession);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(provider.messages, hasLength(1));

        chatRepository.getMessagesFailure = const NetworkFailure(
          'offline',
          503,
        );

        await provider.selectSession(firstSession);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await provider.selectSession(secondSession);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(provider.currentSession?.id, secondSession.id);
        expect(provider.state, ChatState.loaded);
        expect(provider.messages, hasLength(1));
        expect(
          (provider.messages.single as AssistantMessage).parts
              .whereType<TextPart>()
              .single
              .text,
          'cached swr message',
        );
      },
    );

    test(
      'createNewSession selects created session in directory-scoped context',
      () async {
        final scopedRepository = FakeChatRepository(
          sessions: <ChatSession>[
            ChatSession(
              id: 'ses_scoped_1',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              title: 'Scoped Session',
              directory: '/tmp',
            ),
          ],
        );
        final scopedProvider = ChatProvider(
          sendChatMessage: SendChatMessage(scopedRepository),
          getChatSessions: GetChatSessions(scopedRepository),
          createChatSession: CreateChatSession(scopedRepository),
          getChatMessages: GetChatMessages(scopedRepository),
          getChatMessage: GetChatMessage(scopedRepository),
          getAgents: GetAgents(appRepository),
          getProviders: GetProviders(appRepository),
          deleteChatSession: DeleteChatSession(scopedRepository),
          updateChatSession: UpdateChatSession(scopedRepository),
          shareChatSession: ShareChatSession(scopedRepository),
          unshareChatSession: UnshareChatSession(scopedRepository),
          forkChatSession: ForkChatSession(scopedRepository),
          getSessionStatus: GetSessionStatus(scopedRepository),
          getSessionChildren: GetSessionChildren(scopedRepository),
          getSessionTodo: GetSessionTodo(scopedRepository),
          getSessionDiff: GetSessionDiff(scopedRepository),
          watchChatEvents: WatchChatEvents(scopedRepository),
          watchGlobalChatEvents: WatchGlobalChatEvents(scopedRepository),
          listPendingPermissions: ListPendingPermissions(scopedRepository),
          replyPermission: ReplyPermission(scopedRepository),
          listPendingQuestions: ListPendingQuestions(scopedRepository),
          replyQuestion: ReplyQuestion(scopedRepository),
          rejectQuestion: RejectQuestion(scopedRepository),
          projectProvider: ProjectProvider(
            projectRepository: FakeProjectRepository(),
            localDataSource: localDataSource,
          ),
          localDataSource: localDataSource,
        );

        await scopedProvider.projectProvider.initializeProject();
        await scopedProvider.loadSessions();
        expect(scopedProvider.currentSession?.id, 'ses_scoped_1');

        await scopedProvider.createNewSession();

        expect(scopedProvider.state, ChatState.loaded);
        expect(scopedProvider.currentSession, isNotNull);
        expect(scopedProvider.currentSession?.id, isNot('ses_scoped_1'));
        expect(
          scopedProvider.sessions.any(
            (session) => session.id == scopedProvider.currentSession?.id,
          ),
          isTrue,
        );
        expect(scopedProvider.messages, isEmpty);

        final storedCurrent = await localDataSource.getCurrentSessionId(
          serverId: 'srv_test',
          scopeId: '/tmp',
        );
        expect(storedCurrent, scopedProvider.currentSession?.id);
      },
    );

    test(
      'sendMessage appends user message and final assistant reply',
      () async {
        final assistantPartial = AssistantMessage(
          id: 'msg_assistant_1',
          sessionId: 'ses_1',
          time: DateTime.fromMillisecondsSinceEpoch(2000),
          parts: const <MessagePart>[
            TextPart(
              id: 'prt_partial',
              messageId: 'msg_assistant_1',
              sessionId: 'ses_1',
              text: 'draft',
            ),
          ],
        );
        final assistantCompleted = AssistantMessage(
          id: 'msg_assistant_1',
          sessionId: 'ses_1',
          time: DateTime.fromMillisecondsSinceEpoch(2000),
          completedTime: DateTime.fromMillisecondsSinceEpoch(2200),
          parts: const <MessagePart>[
            TextPart(
              id: 'prt_done',
              messageId: 'msg_assistant_1',
              sessionId: 'ses_1',
              text: 'final answer',
            ),
          ],
        );

        chatRepository.sendMessageHandler = (_, _, _, _) async* {
          yield Right(assistantPartial);
          await Future<void>.delayed(const Duration(milliseconds: 1));
          yield Right(assistantCompleted);
        };

        await provider.projectProvider.initializeProject();
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);

        await provider.sendMessage('hello provider');
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(provider.state, ChatState.loaded);
        expect(provider.messages.length, 2);
        expect((provider.messages.first as UserMessage).parts, hasLength(1));
        final assistant = provider.messages.last as AssistantMessage;
        expect((assistant.parts.single as TextPart).text, 'final answer');
        expect(
          chatRepository.lastSendInput?.parts.single,
          const TextInputPart(text: 'hello provider'),
        );
        expect(chatRepository.lastSendInput?.messageId, isNull);
        expect(
          chatRepository.lastSendDirectory,
          provider.projectProvider.currentProject?.path,
        );
      },
    );

    test('send failure in foreground queues draft restore for retry', () async {
      final sendStream = StreamController<Either<Failure, ChatMessage>>();
      addTearDown(() async {
        await sendStream.close();
      });
      chatRepository.sendMessageHandler = (_, _, _, _) => sendStream.stream;

      await provider.projectProvider.initializeProject();
      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);

      await provider.sendMessage('retry this text');
      sendStream.add(const Left(NetworkFailure('temporary failure')));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final rejectedDraft = provider.consumeRejectedDraft(sessionId: 'ses_1');
      expect(rejectedDraft, isNotNull);
      expect(rejectedDraft?.text, 'retry this text');
      expect(rejectedDraft?.attachments, isEmpty);
      expect(rejectedDraft?.shellMode, isFalse);
    });

    test(
      'send network failure is surfaced as inline connection error',
      () async {
        final sendStream = StreamController<Either<Failure, ChatMessage>>();
        addTearDown(() async {
          await sendStream.close();
        });
        chatRepository.sendMessageHandler = (_, _, _, _) => sendStream.stream;

        await provider.projectProvider.initializeProject();
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);

        await provider.sendMessage('network fail now');
        sendStream.add(const Left(NetworkFailure('Network connection failed')));
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(provider.state, ChatState.loaded);
        expect(provider.errorMessage, isNull);
        final inlineErrorMessage = provider.messages.last as AssistantMessage;
        expect(inlineErrorMessage.error, isNotNull);
        expect(inlineErrorMessage.error!.name, 'Connection failed');
        expect(
          inlineErrorMessage.error!.message,
          'Unable to reach the server. Check connection and server status.',
        );
      },
    );

    test('send failure in background does not queue draft restore', () async {
      final sendStream = StreamController<Either<Failure, ChatMessage>>();
      addTearDown(() async {
        await sendStream.close();
      });
      chatRepository.sendMessageHandler = (_, _, _, _) => sendStream.stream;

      await provider.projectProvider.initializeProject();
      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      provider.setAppInForeground(false);

      await provider.sendMessage('do not resurrect this text');
      sendStream.add(
        const Left(NetworkFailure('stream dropped in background')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(provider.consumeRejectedDraft(sessionId: 'ses_1'), isNull);
    });

    test('send failure preserves attachment-only draft for retry', () async {
      final sendStream = StreamController<Either<Failure, ChatMessage>>();
      addTearDown(() async {
        await sendStream.close();
      });
      chatRepository.sendMessageHandler = (_, _, _, _) => sendStream.stream;

      await provider.projectProvider.initializeProject();
      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);

      const attachment = FileInputPart(
        mime: 'image/png',
        url: 'data:image/png;base64,AA==',
        filename: 'image.png',
      );
      await provider.sendMessage(
        '',
        attachments: const <FileInputPart>[attachment],
      );
      sendStream.add(const Left(NetworkFailure('temporary failure')));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final rejectedDraft = provider.consumeRejectedDraft(sessionId: 'ses_1');
      expect(rejectedDraft, isNotNull);
      expect(rejectedDraft?.text, '');
      expect(rejectedDraft?.attachments, const <FileInputPart>[attachment]);
      expect(rejectedDraft?.shellMode, isFalse);
    });

    test(
      'send failure outside active chat route does not queue retry draft',
      () async {
        final sendStream = StreamController<Either<Failure, ChatMessage>>();
        addTearDown(() async {
          await sendStream.close();
        });
        chatRepository.sendMessageHandler = (_, _, _, _) => sendStream.stream;

        await provider.projectProvider.initializeProject();
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);
        provider.setChatRouteActive(false);

        await provider.sendMessage('draft from inactive route');
        sendStream.add(const Left(NetworkFailure('temporary failure')));
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(provider.consumeRejectedDraft(sessionId: 'ses_1'), isNull);
      },
    );

    test(
      'submitMessage lazily creates a new session from draft state',
      () async {
        await provider.projectProvider.initializeProject();
        await provider.loadSessions();

        final initialSessionCount = chatRepository.sessions.length;
        final previousSessionId = provider.currentSession?.id;
        expect(previousSessionId, isNotNull);

        await provider.beginNewChatDraft();
        expect(provider.currentSession, isNull);

        await provider.submitMessage('start from lazy draft');
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(provider.currentSession, isNotNull);
        expect(provider.currentSession?.id, isNot(previousSessionId));
        expect(chatRepository.sessions.length, initialSessionCount + 1);
        expect(chatRepository.lastSendSessionId, provider.currentSession?.id);

        final textParts =
            chatRepository.lastSendInput?.parts
                .whereType<TextInputPart>()
                .toList(growable: false) ??
            const <TextInputPart>[];
        expect(textParts, hasLength(1));
        expect(textParts.first.text, 'start from lazy draft');
      },
    );

    test('sendMessage lazily creates a new session from draft state', () async {
      await provider.projectProvider.initializeProject();
      await provider.loadSessions();

      final previousSessionId = provider.currentSession?.id;
      expect(previousSessionId, isNotNull);

      await provider.beginNewChatDraft();
      expect(provider.currentSession, isNull);

      final started = await provider.sendMessage('direct lazy draft send');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(started, isTrue);
      expect(provider.currentSession, isNotNull);
      expect(provider.currentSession?.id, isNot(previousSessionId));
      expect(chatRepository.lastSendSessionId, provider.currentSession?.id);
    });

    test(
      'loadSessions keeps New Chat draft active when cached snapshot exists',
      () async {
        await provider.projectProvider.initializeProject();
        await provider.loadSessions();

        final existingSession = provider.sessions.first;
        final snapshotMessage = AssistantMessage(
          id: 'msg_snapshot_restore_guard',
          sessionId: existingSession.id,
          time: DateTime.fromMillisecondsSinceEpoch(1010),
          completedTime: DateTime.fromMillisecondsSinceEpoch(1020),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_snapshot_restore_guard',
              messageId: 'msg_snapshot_restore_guard',
              sessionId: 'ses_1',
              text: 'cached snapshot message',
            ),
          ],
        );

        await localDataSource.saveLastSessionSnapshot(
          jsonEncode(<String, dynamic>{
            'session': ChatSessionModel.fromDomain(existingSession).toJson(),
            'messages': <Map<String, dynamic>>[
              ChatMessageModel.fromDomain(snapshotMessage).toJson(),
            ],
          }),
          serverId: 'srv_test',
          scopeId: '/tmp',
        );
        await localDataSource.saveLastSessionSnapshotUpdatedAt(
          DateTime.now().millisecondsSinceEpoch,
          serverId: 'srv_test',
          scopeId: '/tmp',
        );

        await provider.beginNewChatDraft();
        expect(provider.isDraftingNewChat, isTrue);
        expect(provider.currentSession, isNull);

        await provider.loadSessions();
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(provider.isDraftingNewChat, isTrue);
        expect(provider.currentSession, isNull);
        expect(provider.messages, isEmpty);
      },
    );

    test(
      'switching sessions ignores in-flight stream updates from previous session',
      () async {
        chatRepository.sessions.add(
          ChatSession(
            id: 'ses_2',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1500),
            title: 'Session 2',
          ),
        );

        final streamController =
            StreamController<Either<Failure, ChatMessage>>();
        chatRepository.sendMessageHandler = (_, _, _, _) {
          return streamController.stream;
        };

        await provider.projectProvider.initializeProject();
        await provider.loadSessions();

        final session1 = provider.sessions
            .where((item) => item.id == 'ses_1')
            .first;
        final session2 = provider.sessions
            .where((item) => item.id == 'ses_2')
            .first;

        await provider.selectSession(session1);
        await provider.sendMessage('first session prompt');
        expect(provider.currentSession?.id, 'ses_1');

        await provider.selectSession(session2);
        expect(provider.currentSession?.id, 'ses_2');
        expect(provider.messages, isEmpty);

        streamController.add(
          Right(
            AssistantMessage(
              id: 'msg_assistant_old_session',
              sessionId: 'ses_1',
              time: DateTime.fromMillisecondsSinceEpoch(3000),
              parts: const <MessagePart>[
                TextPart(
                  id: 'prt_assistant_old_session',
                  messageId: 'msg_assistant_old_session',
                  sessionId: 'ses_1',
                  text: 'stale update',
                ),
              ],
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(provider.currentSession?.id, 'ses_2');
        expect(provider.messages, isEmpty);

        await streamController.close();
      },
    );

    test('switching sessions cancels the previous in-flight stream', () async {
      chatRepository.sessions.add(
        ChatSession(
          id: 'ses_2',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1500),
          title: 'Session 2',
        ),
      );

      final streamController = StreamController<Either<Failure, ChatMessage>>();
      var streamCancelled = false;
      streamController.onCancel = () {
        streamCancelled = true;
      };
      addTearDown(() async {
        await streamController.close();
      });

      chatRepository.sendMessageHandler = (_, _, _, _) {
        return streamController.stream;
      };

      await provider.projectProvider.initializeProject();
      await provider.loadSessions();

      final session1 = provider.sessions
          .where((item) => item.id == 'ses_1')
          .first;
      final session2 = provider.sessions
          .where((item) => item.id == 'ses_2')
          .first;

      await provider.selectSession(session1);
      await provider.sendMessage('keep stream alive');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await provider.selectSession(session2);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(provider.currentSession?.id, 'ses_2');
      expect(streamCancelled, isTrue);
    });

    test(
      'switching back to a session reloads messages from server after canceling the stale stream',
      () async {
        chatRepository.sessions.add(
          ChatSession(
            id: 'ses_2',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1500),
            title: 'Session 2',
          ),
        );

        final streamController =
            StreamController<Either<Failure, ChatMessage>>();
        var streamCancelled = false;
        streamController.onCancel = () {
          streamCancelled = true;
        };
        addTearDown(() async {
          await streamController.close();
        });

        chatRepository.sendMessageHandler = (_, _, _, _) {
          return streamController.stream;
        };

        // Pre-populate server-side messages for ses_1 so loadMessages
        // returns them when the user switches back.
        chatRepository.messagesBySession['ses_1'] = <ChatMessage>[
          AssistantMessage(
            id: 'msg_server_loaded',
            sessionId: 'ses_1',
            time: DateTime.fromMillisecondsSinceEpoch(3000),
            completedTime: DateTime.fromMillisecondsSinceEpoch(3200),
            parts: const <MessagePart>[
              TextPart(
                id: 'prt_server_loaded',
                messageId: 'msg_server_loaded',
                sessionId: 'ses_1',
                text: 'loaded from server',
              ),
            ],
          ),
        ];

        await provider.projectProvider.initializeProject();
        await provider.loadSessions();

        final session1 = provider.sessions
            .where((item) => item.id == 'ses_1')
            .first;
        final session2 = provider.sessions
            .where((item) => item.id == 'ses_2')
            .first;

        await provider.selectSession(session1);
        await provider.sendMessage('keep stream updates alive');
        await Future<void>.delayed(const Duration(milliseconds: 20));

        await provider.selectSession(session2);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Stream callbacks stay irrelevant after the session switch.
        streamController.add(
          Right(
            AssistantMessage(
              id: 'msg_stream_stale',
              sessionId: 'ses_1',
              time: DateTime.fromMillisecondsSinceEpoch(3000),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_stream_stale',
                  messageId: 'msg_stream_stale',
                  sessionId: 'ses_1',
                  text: 'should be ignored',
                ),
              ],
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Switch back to session1 — messages reload from server.
        await provider.selectSession(session1);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(provider.currentSession?.id, 'ses_1');
        // The previous stream subscription is canceled on switch.
        expect(streamCancelled, isTrue);
        // Messages come from server, not from the stale stream.
        final assistant = provider.messages
            .whereType<AssistantMessage>()
            .where((message) => message.id == 'msg_server_loaded')
            .first;
        expect((assistant.parts.single as TextPart).text, 'loaded from server');
        expect(assistant.isCompleted, isTrue);
      },
    );

    test(
      'sending in another session cancels the previous session stream',
      () async {
        chatRepository.sessions.add(
          ChatSession(
            id: 'ses_2',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1500),
            title: 'Session 2',
          ),
        );

        final firstStream = StreamController<Either<Failure, ChatMessage>>();
        final secondStream = StreamController<Either<Failure, ChatMessage>>();
        var firstStreamCancelled = false;
        firstStream.onCancel = () {
          firstStreamCancelled = true;
        };
        addTearDown(() async {
          await firstStream.close();
          await secondStream.close();
        });

        var sendCalls = 0;
        chatRepository.sendMessageHandler = (_, _, _, _) {
          sendCalls += 1;
          if (sendCalls == 1) {
            return firstStream.stream;
          }
          return secondStream.stream;
        };

        await provider.projectProvider.initializeProject();
        await provider.loadSessions();

        final session1 = provider.sessions
            .where((item) => item.id == 'ses_1')
            .first;
        final session2 = provider.sessions
            .where((item) => item.id == 'ses_2')
            .first;

        await provider.selectSession(session1);
        await provider.sendMessage('first session prompt');
        await Future<void>.delayed(const Duration(milliseconds: 20));

        await provider.selectSession(session2);
        await provider.sendMessage('second session prompt');
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(firstStreamCancelled, isTrue);
      },
    );

    test(
      'loadOlderMessages requests incremental limit and updates hasMore',
      () async {
        final sessionId = 'ses_1';
        final messages = List<ChatMessage>.generate(450, (index) {
          final timestamp = DateTime.fromMillisecondsSinceEpoch(1000 + index);
          if (index.isEven) {
            return UserMessage(
              id: 'msg_user_$index',
              sessionId: sessionId,
              time: timestamp,
              parts: <MessagePart>[
                TextPart(
                  id: 'part_user_$index',
                  messageId: 'msg_user_$index',
                  sessionId: sessionId,
                  text: 'u$index',
                ),
              ],
            );
          }
          return AssistantMessage(
            id: 'msg_assistant_$index',
            sessionId: sessionId,
            time: timestamp,
            completedTime: timestamp,
            parts: <MessagePart>[
              TextPart(
                id: 'part_assistant_$index',
                messageId: 'msg_assistant_$index',
                sessionId: sessionId,
                text: 'a$index',
              ),
            ],
          );
        });
        chatRepository.messagesBySession[sessionId] = messages;

        await provider.projectProvider.initializeProject();
        await provider.loadSessions();
        final session = provider.sessions.firstWhere(
          (item) => item.id == sessionId,
        );
        await provider.selectSession(session);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(provider.hasMoreOldMessages, isTrue);

        await provider.loadOlderMessages(chunkSize: 100);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(chatRepository.lastGetMessagesLimit, 550);
        expect(provider.messages.length, 450);
        expect(provider.hasMoreOldMessages, isFalse);
        expect(provider.isLoadingOlderMessages, isFalse);
      },
    );

    test(
      'loadMessages preserveVisibleState fetches tail first and falls back to full fetch when needed',
      () async {
        final sessionId = 'ses_1';
        final baseMessages = <ChatMessage>[
          AssistantMessage(
            id: 'base_1',
            sessionId: sessionId,
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            completedTime: DateTime.fromMillisecondsSinceEpoch(1001),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_base_1',
                messageId: 'base_1',
                sessionId: 'ses_1',
                text: 'base 1',
              ),
            ],
          ),
          AssistantMessage(
            id: 'base_2',
            sessionId: sessionId,
            time: DateTime.fromMillisecondsSinceEpoch(2000),
            completedTime: DateTime.fromMillisecondsSinceEpoch(2001),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_base_2',
                messageId: 'base_2',
                sessionId: 'ses_1',
                text: 'base 2',
              ),
            ],
          ),
        ];
        chatRepository.messagesBySession[sessionId] = List<ChatMessage>.from(
          baseMessages,
        );

        await provider.projectProvider.initializeProject();
        await provider.loadSessions();
        final session = provider.sessions.firstWhere(
          (item) => item.id == sessionId,
        );
        await provider.selectSession(session);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        final latestTail = <ChatMessage>[
          AssistantMessage(
            id: 'fresh_1',
            sessionId: sessionId,
            time: DateTime.fromMillisecondsSinceEpoch(3000),
            completedTime: DateTime.fromMillisecondsSinceEpoch(3001),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_fresh_1',
                messageId: 'fresh_1',
                sessionId: 'ses_1',
                text: 'fresh 1',
              ),
            ],
          ),
        ];
        final fullHistory = <ChatMessage>[...baseMessages, ...latestTail];
        var requestNumber = 0;
        chatRepository.getMessagesRequestedLimits.clear();
        chatRepository.getMessagesHandler =
            (String _, String __, {String? directory, int? limit}) async {
              requestNumber += 1;
              if (requestNumber == 1) {
                return Right(latestTail);
              }
              return Right(fullHistory);
            };

        await provider.loadMessages(sessionId, preserveVisibleState: true);
        await Future<void>.delayed(const Duration(milliseconds: 60));

        expect(chatRepository.getMessagesRequestedLimits, hasLength(2));
        expect(chatRepository.getMessagesRequestedLimits.first, isNotNull);
        expect(chatRepository.getMessagesRequestedLimits.last, isNull);
        expect(
          provider.messages.map((message) => message.id).toList(),
          <String>['base_1', 'base_2', 'fresh_1'],
        );
      },
    );

    test(
      'refreshActiveSessionView schedules scroll callback when latest message changes',
      () async {
        const sessionId = 'ses_1';
        final toolOnlyMessage = AssistantMessage(
          id: 'msg_tool_only_before_final',
          sessionId: sessionId,
          time: DateTime.fromMillisecondsSinceEpoch(2000),
          completedTime: DateTime.fromMillisecondsSinceEpoch(2010),
          parts: <MessagePart>[
            ToolPart(
              id: 'part_tool_only_before_final',
              messageId: 'msg_tool_only_before_final',
              sessionId: sessionId,
              callId: 'call_tool_only_before_final',
              tool: 'bash',
              state: ToolStateCompleted(
                input: const <String, dynamic>{'command': 'pwd'},
                output: '/tmp',
                time: ToolTime(
                  start: DateTime.fromMillisecondsSinceEpoch(2000),
                  end: DateTime.fromMillisecondsSinceEpoch(2005),
                ),
              ),
            ),
          ],
        );
        chatRepository.messagesBySession[sessionId] = <ChatMessage>[
          toolOnlyMessage,
        ];

        await provider.projectProvider.initializeProject();
        await provider.loadSessions();
        final session = provider.sessions.firstWhere(
          (item) => item.id == sessionId,
        );
        await provider.selectSession(session);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        var scrollToBottomRequests = 0;
        provider.setScrollToBottomCallback(() {
          scrollToBottomRequests += 1;
        });

        chatRepository.messagesBySession[sessionId] = <ChatMessage>[
          toolOnlyMessage,
          AssistantMessage(
            id: 'msg_final_after_tools',
            sessionId: sessionId,
            time: DateTime.fromMillisecondsSinceEpoch(2100),
            completedTime: DateTime.fromMillisecondsSinceEpoch(2110),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_final_after_tools',
                messageId: 'msg_final_after_tools',
                sessionId: sessionId,
                text: 'final response after tool calls',
              ),
            ],
          ),
        ];

        await provider.refreshActiveSessionView(
          reason: 'session-idle-final-reconcile',
          includeStatus: false,
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(provider.messages.last.id, 'msg_final_after_tools');
        expect(scrollToBottomRequests, greaterThan(0));
      },
    );

    test(
      'providers refresh exposes failed state and recovers on retry',
      () async {
        appRepository.providersResult = const Left(
          NetworkFailure('providers down'),
        );

        await provider.initializeProviders();

        expect(
          provider.providersRefreshState,
          ChatProvidersRefreshState.failed,
        );
        expect(
          provider.providersRefreshErrorMessage,
          contains('providers down'),
        );

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

        await provider.retryProvidersRefresh();

        expect(provider.providersRefreshState, ChatProvidersRefreshState.ready);
        expect(provider.providersRefreshErrorMessage, isNull);
        expect(provider.selectedProviderId, 'provider_a');
        expect(provider.selectedModelId, 'model_a');
      },
    );

    test('sendMessage sends shell mode payload when requested', () async {
      final assistantCompleted = AssistantMessage(
        id: 'msg_shell_done',
        sessionId: 'ses_1',
        time: DateTime.fromMillisecondsSinceEpoch(2000),
        completedTime: DateTime.fromMillisecondsSinceEpoch(2100),
        parts: const <MessagePart>[
          TextPart(
            id: 'prt_shell_done',
            messageId: 'msg_shell_done',
            sessionId: 'ses_1',
            text: 'shell output',
          ),
        ],
      );
      chatRepository.sendMessageHandler = (_, _, _, _) async* {
        yield Right(assistantCompleted);
      };

      await provider.projectProvider.initializeProject();
      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);

      await provider.sendMessage('pwd', shellMode: true);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(provider.state, ChatState.loaded);
      expect(chatRepository.lastSendInput?.mode, 'shell');
      expect(
        chatRepository.lastSendInput?.parts.single,
        const TextInputPart(text: 'pwd'),
      );
      final userMessage = provider.messages.first as UserMessage;
      expect((userMessage.parts.first as TextPart).text, '!pwd');
    });
  });
}
