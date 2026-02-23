import 'dart:async';
import 'dart:convert';

import 'package:codewalk/core/errors/failures.dart';
import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/data/models/chat_message_model.dart';
import 'package:codewalk/data/models/chat_session_model.dart';
import 'package:codewalk/domain/entities/chat_message.dart';
import 'package:codewalk/domain/entities/chat_session.dart';
import 'package:codewalk/domain/entities/experience_settings.dart';
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
import 'package:codewalk/presentation/services/sound_service.dart';
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
      chatRepository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_1',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Session 1',
          ),
        ],
      );
      appRepository = FakeAppRepository();
      localDataSource = InMemoryAppLocalDataSource();
      localDataSource.activeServerId = 'srv_test';

      localDataSource.experienceSettingsJson = jsonEncode(
        ExperienceSettings.defaults()
            .copyWith(enableExperimentalMultiDeviceSync: true)
            .toJson(),
      );
      defaultSettingsProvider = SettingsProvider(
        localDataSource: localDataSource,
        dioClient: RecordingDioClient(),
        soundService: SoundService(),
      );
      await defaultSettingsProvider.initialize();

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

        chatRepository.sendMessageHandler = (_, __, ___, ____) async* {
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
      chatRepository.sendMessageHandler = (_, __, ___, ____) =>
          sendStream.stream;

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

    test('send failure in background does not queue draft restore', () async {
      final sendStream = StreamController<Either<Failure, ChatMessage>>();
      addTearDown(() async {
        await sendStream.close();
      });
      chatRepository.sendMessageHandler = (_, __, ___, ____) =>
          sendStream.stream;

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
      chatRepository.sendMessageHandler = (_, __, ___, ____) =>
          sendStream.stream;

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
        chatRepository.sendMessageHandler = (_, __, ___, ____) =>
            sendStream.stream;

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
        chatRepository.sendMessageHandler = (_, __, ___, ____) {
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

    test(
      'switching sessions keeps in-flight stream alive to avoid unintended abort',
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

        chatRepository.sendMessageHandler = (_, __, ___, ____) {
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
        expect(streamCancelled, isFalse);
      },
    );

    test(
      'switching back to a session reloads messages from server instead of stale stream',
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

        chatRepository.sendMessageHandler = (_, __, ___, ____) {
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

        // Stream callbacks are silenced (stale generation) but stream is alive.
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
        // Stream subscription is preserved (not cancelled).
        expect(streamCancelled, isFalse);
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
      'sending in another session does not cancel previous session stream',
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
        chatRepository.sendMessageHandler = (_, __, ___, ____) {
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

        expect(firstStreamCancelled, isFalse);
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
      chatRepository.sendMessageHandler = (_, __, ___, ____) async* {
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
