@Tags(<String>['slow'])
library;

import 'dart:async';
import 'dart:convert';

import 'package:codewalk/core/errors/failures.dart';
import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/domain/entities/agent.dart';
import 'package:codewalk/domain/entities/chat_message.dart';
import 'package:codewalk/domain/entities/chat_realtime.dart';
import 'package:codewalk/domain/entities/chat_session.dart';
import 'package:codewalk/domain/entities/experience_settings.dart';
import 'package:codewalk/domain/entities/provider.dart';
import 'package:codewalk/domain/usecases/abort_chat_session.dart';
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
import 'package:codewalk/presentation/services/chat_title_generator.dart';
import 'package:codewalk/presentation/services/sound_service.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import 'chat_provider_test_support.dart';

void main() {
  group('ChatProvider - realtime', () {
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

    test(
      'does not generate AI titles when server toggle is disabled',
      () async {
        final titleGenerator = _FakeChatTitleGenerator();
        final providerWithAutoTitle = ChatProvider(
          sendChatMessage: SendChatMessage(chatRepository),
          abortChatSession: AbortChatSession(chatRepository),
          getChatSessions: GetChatSessions(chatRepository),
          createChatSession: CreateChatSession(chatRepository),
          getChatMessages: GetChatMessages(chatRepository),
          getChatMessage: GetChatMessage(chatRepository),
          getAgents: GetAgents(appRepository),
          getProviders: GetProviders(appRepository),
          deleteChatSession: DeleteChatSession(chatRepository),
          updateChatSession: UpdateChatSession(chatRepository),
          shareChatSession: ShareChatSession(chatRepository),
          unshareChatSession: UnshareChatSession(chatRepository),
          forkChatSession: ForkChatSession(chatRepository),
          getSessionStatus: GetSessionStatus(chatRepository),
          getSessionChildren: GetSessionChildren(chatRepository),
          getSessionTodo: GetSessionTodo(chatRepository),
          getSessionDiff: GetSessionDiff(chatRepository),
          watchChatEvents: WatchChatEvents(chatRepository),
          watchGlobalChatEvents: WatchGlobalChatEvents(chatRepository),
          listPendingPermissions: ListPendingPermissions(chatRepository),
          replyPermission: ReplyPermission(chatRepository),
          listPendingQuestions: ListPendingQuestions(chatRepository),
          replyQuestion: ReplyQuestion(chatRepository),
          rejectQuestion: RejectQuestion(chatRepository),
          projectProvider: ProjectProvider(
            projectRepository: FakeProjectRepository(),
            localDataSource: localDataSource,
          ),
          localDataSource: localDataSource,
          titleGenerator: titleGenerator,
        );

        chatRepository.sendMessageHandler = (_, __, ___, ____) async* {
          yield Right(
            AssistantMessage(
              id: 'msg_assistant_toggle_off',
              sessionId: 'ses_1',
              time: DateTime.fromMillisecondsSinceEpoch(2000),
              completedTime: DateTime.fromMillisecondsSinceEpoch(2100),
              parts: const <MessagePart>[
                TextPart(
                  id: 'prt_assistant_toggle_off',
                  messageId: 'msg_assistant_toggle_off',
                  sessionId: 'ses_1',
                  text: 'reply',
                ),
              ],
            ),
          );
        };

        await providerWithAutoTitle.projectProvider.initializeProject();
        await providerWithAutoTitle.loadSessions();
        await providerWithAutoTitle.selectSession(
          providerWithAutoTitle.sessions.first,
        );
        await providerWithAutoTitle.sendMessage('hello');
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(titleGenerator.callCount, 0);
      },
    );

    test(
      'generates title after each user/assistant turn until 3+3 messages',
      () async {
        localDataSource.serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'srv_test',
            'url': 'http://127.0.0.1:4096',
            'createdAt': 1,
            'updatedAt': 1,
            'aiGeneratedTitlesEnabled': true,
          },
        ]);
        final titleGenerator = _FakeChatTitleGenerator();
        final providerWithAutoTitle = ChatProvider(
          sendChatMessage: SendChatMessage(chatRepository),
          abortChatSession: AbortChatSession(chatRepository),
          getChatSessions: GetChatSessions(chatRepository),
          createChatSession: CreateChatSession(chatRepository),
          getChatMessages: GetChatMessages(chatRepository),
          getChatMessage: GetChatMessage(chatRepository),
          getAgents: GetAgents(appRepository),
          getProviders: GetProviders(appRepository),
          deleteChatSession: DeleteChatSession(chatRepository),
          updateChatSession: UpdateChatSession(chatRepository),
          shareChatSession: ShareChatSession(chatRepository),
          unshareChatSession: UnshareChatSession(chatRepository),
          forkChatSession: ForkChatSession(chatRepository),
          getSessionStatus: GetSessionStatus(chatRepository),
          getSessionChildren: GetSessionChildren(chatRepository),
          getSessionTodo: GetSessionTodo(chatRepository),
          getSessionDiff: GetSessionDiff(chatRepository),
          watchChatEvents: WatchChatEvents(chatRepository),
          watchGlobalChatEvents: WatchGlobalChatEvents(chatRepository),
          listPendingPermissions: ListPendingPermissions(chatRepository),
          replyPermission: ReplyPermission(chatRepository),
          listPendingQuestions: ListPendingQuestions(chatRepository),
          replyQuestion: ReplyQuestion(chatRepository),
          rejectQuestion: RejectQuestion(chatRepository),
          projectProvider: ProjectProvider(
            projectRepository: FakeProjectRepository(),
            localDataSource: localDataSource,
          ),
          localDataSource: localDataSource,
          titleGenerator: titleGenerator,
        );

        var responseCounter = 0;
        chatRepository.sendMessageHandler = (_, __, ___, ____) async* {
          responseCounter += 1;
          yield Right(
            AssistantMessage(
              id: 'msg_assistant_$responseCounter',
              sessionId: 'ses_1',
              time: DateTime.fromMillisecondsSinceEpoch(2000 + responseCounter),
              completedTime: DateTime.fromMillisecondsSinceEpoch(
                2100 + responseCounter,
              ),
              parts: <MessagePart>[
                TextPart(
                  id: 'prt_assistant_$responseCounter',
                  messageId: 'msg_assistant_$responseCounter',
                  sessionId: 'ses_1',
                  text: 'assistant reply $responseCounter',
                ),
              ],
            ),
          );
        };

        await providerWithAutoTitle.projectProvider.initializeProject();
        await providerWithAutoTitle.loadSessions();
        await providerWithAutoTitle.selectSession(
          providerWithAutoTitle.sessions.first,
        );

        await providerWithAutoTitle.sendMessage('user 1');
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await providerWithAutoTitle.sendMessage('user 2');
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await providerWithAutoTitle.sendMessage('user 3');
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(titleGenerator.callCount, 6);
        final lastBatch = titleGenerator.payloads.last;
        expect(lastBatch.length, 6);
        expect(lastBatch.where((item) => item.role == 'user').length, 3);
        expect(lastBatch.where((item) => item.role == 'assistant').length, 3);

        await providerWithAutoTitle.sendMessage('user 4');
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(titleGenerator.callCount, 6);
      },
    );

    test(
      'does not apply stale auto-title result after switching sessions',
      () async {
        localDataSource.serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'srv_test',
            'url': 'http://127.0.0.1:4096',
            'createdAt': 1,
            'updatedAt': 1,
            'aiGeneratedTitlesEnabled': true,
          },
        ]);
        chatRepository.sessions.add(
          ChatSession(
            id: 'ses_2',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1100),
            title: 'Session 2',
          ),
        );

        final completer = Completer<String?>();
        final titleGenerator = _BlockingChatTitleGenerator(completer);
        final providerWithAutoTitle = ChatProvider(
          sendChatMessage: SendChatMessage(chatRepository),
          abortChatSession: AbortChatSession(chatRepository),
          getChatSessions: GetChatSessions(chatRepository),
          createChatSession: CreateChatSession(chatRepository),
          getChatMessages: GetChatMessages(chatRepository),
          getChatMessage: GetChatMessage(chatRepository),
          getAgents: GetAgents(appRepository),
          getProviders: GetProviders(appRepository),
          deleteChatSession: DeleteChatSession(chatRepository),
          updateChatSession: UpdateChatSession(chatRepository),
          shareChatSession: ShareChatSession(chatRepository),
          unshareChatSession: UnshareChatSession(chatRepository),
          forkChatSession: ForkChatSession(chatRepository),
          getSessionStatus: GetSessionStatus(chatRepository),
          getSessionChildren: GetSessionChildren(chatRepository),
          getSessionTodo: GetSessionTodo(chatRepository),
          getSessionDiff: GetSessionDiff(chatRepository),
          watchChatEvents: WatchChatEvents(chatRepository),
          watchGlobalChatEvents: WatchGlobalChatEvents(chatRepository),
          listPendingPermissions: ListPendingPermissions(chatRepository),
          replyPermission: ReplyPermission(chatRepository),
          listPendingQuestions: ListPendingQuestions(chatRepository),
          replyQuestion: ReplyQuestion(chatRepository),
          rejectQuestion: RejectQuestion(chatRepository),
          projectProvider: ProjectProvider(
            projectRepository: FakeProjectRepository(),
            localDataSource: localDataSource,
          ),
          localDataSource: localDataSource,
          titleGenerator: titleGenerator,
        );

        final updatedSessionIds = <String>[];
        chatRepository.updateSessionHandler = (_, sessionId, input, __) async {
          updatedSessionIds.add(sessionId);
          final index = chatRepository.sessions.indexWhere(
            (item) => item.id == sessionId,
          );
          final updated = chatRepository.sessions[index].copyWith(
            title: input.title,
          );
          chatRepository.sessions[index] = updated;
          return Right(updated);
        };

        chatRepository.sendMessageHandler = (_, __, ___, ____) async* {
          yield Right(
            AssistantMessage(
              id: 'msg_assistant_stale',
              sessionId: 'ses_1',
              time: DateTime.fromMillisecondsSinceEpoch(2000),
              completedTime: DateTime.fromMillisecondsSinceEpoch(2100),
              parts: const <MessagePart>[
                TextPart(
                  id: 'prt_assistant_stale',
                  messageId: 'msg_assistant_stale',
                  sessionId: 'ses_1',
                  text: 'reply',
                ),
              ],
            ),
          );
        };

        await providerWithAutoTitle.projectProvider.initializeProject();
        await providerWithAutoTitle.loadSessions();
        await providerWithAutoTitle.selectSession(
          providerWithAutoTitle.sessions
              .where((item) => item.id == 'ses_1')
              .first,
        );

        await providerWithAutoTitle.sendMessage('hello');
        await providerWithAutoTitle.selectSession(
          providerWithAutoTitle.sessions
              .where((item) => item.id == 'ses_2')
              .first,
        );

        completer.complete('Stale title');
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(titleGenerator.callCount, 1);
        expect(updatedSessionIds, isEmpty);
        expect(
          chatRepository.sessions
              .where((item) => item.id == 'ses_1')
              .first
              .title,
          'Session 1',
        );
      },
    );

    test(
      'does not regenerate title on reopen when transcript is already 3+3',
      () async {
        localDataSource.serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'srv_test',
            'url': 'http://127.0.0.1:4096',
            'createdAt': 1,
            'updatedAt': 1,
            'aiGeneratedTitlesEnabled': true,
          },
        ]);

        chatRepository.messagesBySession['ses_1'] = <ChatMessage>[
          UserMessage(
            id: 'msg_user_1',
            sessionId: 'ses_1',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            parts: const <MessagePart>[
              TextPart(
                id: 'prt_user_1',
                messageId: 'msg_user_1',
                sessionId: 'ses_1',
                text: 'user 1',
              ),
            ],
          ),
          AssistantMessage(
            id: 'msg_assistant_1',
            sessionId: 'ses_1',
            time: DateTime.fromMillisecondsSinceEpoch(1100),
            completedTime: DateTime.fromMillisecondsSinceEpoch(1150),
            parts: const <MessagePart>[
              TextPart(
                id: 'prt_assistant_1',
                messageId: 'msg_assistant_1',
                sessionId: 'ses_1',
                text: 'assistant 1',
              ),
            ],
          ),
          UserMessage(
            id: 'msg_user_2',
            sessionId: 'ses_1',
            time: DateTime.fromMillisecondsSinceEpoch(1200),
            parts: const <MessagePart>[
              TextPart(
                id: 'prt_user_2',
                messageId: 'msg_user_2',
                sessionId: 'ses_1',
                text: 'user 2',
              ),
            ],
          ),
          AssistantMessage(
            id: 'msg_assistant_2',
            sessionId: 'ses_1',
            time: DateTime.fromMillisecondsSinceEpoch(1300),
            completedTime: DateTime.fromMillisecondsSinceEpoch(1350),
            parts: const <MessagePart>[
              TextPart(
                id: 'prt_assistant_2',
                messageId: 'msg_assistant_2',
                sessionId: 'ses_1',
                text: 'assistant 2',
              ),
            ],
          ),
          UserMessage(
            id: 'msg_user_3',
            sessionId: 'ses_1',
            time: DateTime.fromMillisecondsSinceEpoch(1400),
            parts: const <MessagePart>[
              TextPart(
                id: 'prt_user_3',
                messageId: 'msg_user_3',
                sessionId: 'ses_1',
                text: 'user 3',
              ),
            ],
          ),
          AssistantMessage(
            id: 'msg_assistant_3',
            sessionId: 'ses_1',
            time: DateTime.fromMillisecondsSinceEpoch(1500),
            completedTime: DateTime.fromMillisecondsSinceEpoch(1550),
            parts: const <MessagePart>[
              TextPart(
                id: 'prt_assistant_3',
                messageId: 'msg_assistant_3',
                sessionId: 'ses_1',
                text: 'assistant 3',
              ),
            ],
          ),
        ];

        final titleGenerator = _FakeChatTitleGenerator();
        final providerWithAutoTitle = ChatProvider(
          sendChatMessage: SendChatMessage(chatRepository),
          abortChatSession: AbortChatSession(chatRepository),
          getChatSessions: GetChatSessions(chatRepository),
          createChatSession: CreateChatSession(chatRepository),
          getChatMessages: GetChatMessages(chatRepository),
          getChatMessage: GetChatMessage(chatRepository),
          getAgents: GetAgents(appRepository),
          getProviders: GetProviders(appRepository),
          deleteChatSession: DeleteChatSession(chatRepository),
          updateChatSession: UpdateChatSession(chatRepository),
          shareChatSession: ShareChatSession(chatRepository),
          unshareChatSession: UnshareChatSession(chatRepository),
          forkChatSession: ForkChatSession(chatRepository),
          getSessionStatus: GetSessionStatus(chatRepository),
          getSessionChildren: GetSessionChildren(chatRepository),
          getSessionTodo: GetSessionTodo(chatRepository),
          getSessionDiff: GetSessionDiff(chatRepository),
          watchChatEvents: WatchChatEvents(chatRepository),
          watchGlobalChatEvents: WatchGlobalChatEvents(chatRepository),
          listPendingPermissions: ListPendingPermissions(chatRepository),
          replyPermission: ReplyPermission(chatRepository),
          listPendingQuestions: ListPendingQuestions(chatRepository),
          replyQuestion: ReplyQuestion(chatRepository),
          rejectQuestion: RejectQuestion(chatRepository),
          projectProvider: ProjectProvider(
            projectRepository: FakeProjectRepository(),
            localDataSource: localDataSource,
          ),
          localDataSource: localDataSource,
          titleGenerator: titleGenerator,
        );

        await providerWithAutoTitle.projectProvider.initializeProject();
        await providerWithAutoTitle.loadSessions();
        await providerWithAutoTitle.selectSession(
          providerWithAutoTitle.sessions.first,
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(titleGenerator.callCount, 0);
      },
    );

    test(
      'session.error with aborted message after stop does not replace chat with global error',
      () async {
        final streamController =
            StreamController<Either<Failure, ChatMessage>>();
        addTearDown(() async {
          await streamController.close();
        });
        chatRepository.sendMessageHandler = (_, __, ___, ____) =>
            streamController.stream;

        await provider.projectProvider.initializeProject();
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);

        await provider.sendMessage('stop me');
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final stopped = await provider.abortActiveResponse();
        expect(stopped, isTrue);

        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.error',
            properties: <String, dynamic>{
              'sessionID': 'ses_1',
              'error': <String, dynamic>{
                'message': 'The operation was aborted.',
              },
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(provider.state, ChatState.loaded);
        expect(provider.errorMessage, isNull);
      },
    );

    test(
      'session.error with retry marker after stop does not replace chat with global error',
      () async {
        final streamController =
            StreamController<Either<Failure, ChatMessage>>();
        addTearDown(() async {
          await streamController.close();
        });
        chatRepository.sendMessageHandler = (_, __, ___, ____) =>
            streamController.stream;

        await provider.projectProvider.initializeProject();
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);

        await provider.sendMessage('stop me');
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final stopped = await provider.abortActiveResponse();
        expect(stopped, isTrue);

        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.error',
            properties: <String, dynamic>{
              'sessionID': 'ses_1',
              'error': <String, dynamic>{'message': 'retry'},
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(provider.state, ChatState.loaded);
        expect(provider.errorMessage, isNull);
      },
    );

    test('session.error remote abort appends inline message', () async {
      await provider.projectProvider.initializeProject();
      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.initializeProviders();

      chatRepository.emitEvent(
        const ChatEvent(
          type: 'session.error',
          properties: <String, dynamic>{
            'sessionID': 'ses_1',
            'error': <String, dynamic>{
              'message': 'The operation was aborted by user',
            },
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(provider.state, ChatState.loaded);
      expect(provider.errorMessage, isNull);
      expect(provider.consumePendingUiNotice(), isNull);

      final inlineAbort = provider.messages.last as AssistantMessage;
      expect(inlineAbort.error, isNotNull);
      expect(inlineAbort.error!.name, 'MessageAborted');
      expect(inlineAbort.error!.message, 'What you want to do different?');
    });

    test('session.error string payload is handled as abort error', () async {
      await provider.projectProvider.initializeProject();
      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.initializeProviders();

      chatRepository.emitEvent(
        const ChatEvent(
          type: 'session.error',
          properties: <String, dynamic>{
            'sessionID': 'ses_1',
            'error': 'Request was aborted',
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(provider.state, ChatState.loaded);
      expect(provider.errorMessage, isNull);
    });

    test(
      'session.error from non-current session only settles background status',
      () async {
        chatRepository.sessions.add(
          ChatSession(
            id: 'ses_2',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1500),
            title: 'Session 2',
          ),
        );

        await provider.projectProvider.initializeProject();
        await provider.loadSessions();
        await provider.selectSession(
          provider.sessions.where((item) => item.id == 'ses_1').first,
        );
        await provider.initializeProviders();

        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.error',
            properties: <String, dynamic>{
              'sessionID': 'ses_2',
              'error': <String, dynamic>{'message': 'background failure'},
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(provider.currentSession?.id, 'ses_1');
        expect(provider.errorMessage, isNull);
        expect(
          provider.sessionStatusById['ses_2']?.type,
          SessionStatusType.idle,
        );
      },
    );

    test(
      'session.idle from non-current session updates only that status',
      () async {
        chatRepository.sessions.add(
          ChatSession(
            id: 'ses_2',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1500),
            title: 'Session 2',
          ),
        );

        await provider.projectProvider.initializeProject();
        await provider.loadSessions();
        await provider.selectSession(
          provider.sessions.where((item) => item.id == 'ses_1').first,
        );
        await provider.initializeProviders();

        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.idle',
            properties: <String, dynamic>{'sessionID': 'ses_2'},
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(provider.currentSession?.id, 'ses_1');
        expect(
          provider.sessionStatusById['ses_2']?.type,
          SessionStatusType.idle,
        );
      },
    );

    test(
      'sending again immediately after stop keeps provider stable and delivers next reply',
      () async {
        final firstStreamController =
            StreamController<Either<Failure, ChatMessage>>();
        addTearDown(() async {
          await firstStreamController.close();
        });
        final assistantAfterStop = AssistantMessage(
          id: 'msg_after_stop',
          sessionId: 'ses_1',
          time: DateTime.fromMillisecondsSinceEpoch(3000),
          completedTime: DateTime.fromMillisecondsSinceEpoch(3100),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_after_stop',
              messageId: 'msg_after_stop',
              sessionId: 'ses_1',
              text: 'new reply after stop',
            ),
          ],
        );
        var sendCalls = 0;
        chatRepository.sendMessageHandler = (_, __, ___, ____) {
          sendCalls += 1;
          if (sendCalls == 1) {
            return firstStreamController.stream;
          }
          return Stream<Either<Failure, ChatMessage>>.value(
            Right(assistantAfterStop),
          );
        };

        await provider.projectProvider.initializeProject();
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);

        await provider.sendMessage('first prompt');
        await Future<void>.delayed(const Duration(milliseconds: 10));
        final stopped = await provider.abortActiveResponse();
        expect(stopped, isTrue);

        await provider.sendMessage('prompt after stop');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(provider.state, ChatState.loaded);
        expect(provider.errorMessage, isNull);
        final sentAfterStop = provider.messages.whereType<UserMessage>().any((
          message,
        ) {
          return message.parts.whereType<TextPart>().any(
            (part) => part.text == 'prompt after stop',
          );
        });
        expect(sentAfterStop, isTrue);
        final assistant = provider.messages.last as AssistantMessage;
        expect(
          (assistant.parts.single as TextPart).text,
          'new reply after stop',
        );
      },
    );

    test(
      'sendMessageWithInterrupt aborts in-flight response and sends follow-up',
      () async {
        final firstStreamController =
            StreamController<Either<Failure, ChatMessage>>();
        var firstStreamCancelled = false;
        firstStreamController.onCancel = () {
          firstStreamCancelled = true;
        };
        addTearDown(() async {
          await firstStreamController.close();
        });
        final assistantAfterInterrupt = AssistantMessage(
          id: 'msg_after_interrupt_provider',
          sessionId: 'ses_1',
          time: DateTime.fromMillisecondsSinceEpoch(3000),
          completedTime: DateTime.fromMillisecondsSinceEpoch(3200),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_after_interrupt_provider',
              messageId: 'msg_after_interrupt_provider',
              sessionId: 'ses_1',
              text: 'interrupt ok',
            ),
          ],
        );

        var sendCalls = 0;
        chatRepository.sendMessageHandler = (_, __, ___, ____) {
          sendCalls += 1;
          if (sendCalls == 1) {
            return firstStreamController.stream;
          }
          return Stream<Either<Failure, ChatMessage>>.value(
            Right(assistantAfterInterrupt),
          );
        };

        await provider.projectProvider.initializeProject();
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);

        await provider.sendMessage('initial prompt');
        await Future<void>.delayed(const Duration(milliseconds: 10));

        await provider.sendMessageWithInterrupt('follow-up prompt');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(chatRepository.abortSessionCallCount, 1);
        expect(firstStreamCancelled, isTrue);
        expect(sendCalls, 2);
        expect(provider.state, ChatState.loaded);

        final sentFollowUp = provider.messages.whereType<UserMessage>().any((
          message,
        ) {
          return message.parts.whereType<TextPart>().any(
            (part) => part.text == 'follow-up prompt',
          );
        });
        expect(sentFollowUp, isTrue);
      },
    );

    test(
      'sendMessageWithInterrupt waits for busy status to settle before follow-up send',
      () async {
        final firstStreamController =
            StreamController<Either<Failure, ChatMessage>>();
        addTearDown(() async {
          await firstStreamController.close();
        });
        final assistantAfterSettledInterrupt = AssistantMessage(
          id: 'msg_after_settled_interrupt',
          sessionId: 'ses_1',
          time: DateTime.fromMillisecondsSinceEpoch(3500),
          completedTime: DateTime.fromMillisecondsSinceEpoch(3600),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_after_settled_interrupt',
              messageId: 'msg_after_settled_interrupt',
              sessionId: 'ses_1',
              text: 'reply after settle',
            ),
          ],
        );

        var sendCalls = 0;
        DateTime? secondSendAt;
        chatRepository.sendMessageHandler = (_, __, ___, ____) {
          sendCalls += 1;
          if (sendCalls == 1) {
            return firstStreamController.stream;
          }
          secondSendAt = DateTime.now();
          return Stream<Either<Failure, ChatMessage>>.value(
            Right(assistantAfterSettledInterrupt),
          );
        };
        chatRepository.sessionStatusById = const <String, SessionStatusInfo>{
          'ses_1': SessionStatusInfo(type: SessionStatusType.busy),
        };

        await provider.projectProvider.initializeProject();
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);

        await provider.sendMessage('initial prompt');
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final statusCallsBefore = chatRepository.getSessionStatusCallCount;
        final interruptRequestedAt = DateTime.now();
        unawaited(
          Future<void>.delayed(const Duration(milliseconds: 220), () {
            chatRepository.sessionStatusById =
                const <String, SessionStatusInfo>{
                  'ses_1': SessionStatusInfo(type: SessionStatusType.idle),
                };
          }),
        );

        await provider.sendMessageWithInterrupt('follow-up prompt');
        await Future<void>.delayed(const Duration(milliseconds: 60));

        expect(chatRepository.abortSessionCallCount, 1);
        expect(sendCalls, 2);
        expect(
          chatRepository.getSessionStatusCallCount,
          greaterThan(statusCallsBefore),
        );
        expect(secondSendAt, isNotNull);
        expect(
          secondSendAt!.difference(interruptRequestedAt).inMilliseconds,
          greaterThanOrEqualTo(120),
        );
      },
    );

    test(
      'sendMessageWithInterrupt ignores stop failure and continues sending',
      () async {
        final firstStreamController =
            StreamController<Either<Failure, ChatMessage>>();
        addTearDown(() async {
          await firstStreamController.close();
        });

        final assistantAfterInterruptFailure = AssistantMessage(
          id: 'msg_after_interrupt_stop_failure',
          sessionId: 'ses_1',
          time: DateTime.fromMillisecondsSinceEpoch(4000),
          completedTime: DateTime.fromMillisecondsSinceEpoch(4100),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_after_interrupt_stop_failure',
              messageId: 'msg_after_interrupt_stop_failure',
              sessionId: 'ses_1',
              text: 'continued after stop failure',
            ),
          ],
        );

        var sendCalls = 0;
        chatRepository.sendMessageHandler = (_, __, ___, ____) {
          sendCalls += 1;
          if (sendCalls == 1) {
            return firstStreamController.stream;
          }
          return Stream<Either<Failure, ChatMessage>>.value(
            Right(assistantAfterInterruptFailure),
          );
        };
        chatRepository.abortSessionFailure = const ServerFailure(
          'abort failed',
        );

        await provider.projectProvider.initializeProject();
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);

        await provider.sendMessage('initial prompt');
        await Future<void>.delayed(const Duration(milliseconds: 10));

        await provider.sendMessageWithInterrupt('follow-up prompt');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(chatRepository.abortSessionCallCount, 1);
        expect(sendCalls, 2);
        expect(provider.state, ChatState.loaded);
        expect(provider.errorMessage, isNull);

        final sentFollowUp = provider.messages.whereType<UserMessage>().any((
          message,
        ) {
          return message.parts.whereType<TextPart>().any(
            (part) => part.text == 'follow-up prompt',
          );
        });
        expect(sentFollowUp, isTrue);

        final rejectedDraft = provider.consumeRejectedDraft(sessionId: 'ses_1');
        expect(rejectedDraft, isNull);
      },
    );

    test('session.error after stop still surfaces non-abort errors', () async {
      final streamController = StreamController<Either<Failure, ChatMessage>>();
      addTearDown(() async {
        await streamController.close();
      });
      chatRepository.sendMessageHandler = (_, __, ___, ____) =>
          streamController.stream;

      await provider.projectProvider.initializeProject();
      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);

      await provider.sendMessage('stop me');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final stopped = await provider.abortActiveResponse();
      expect(stopped, isTrue);

      chatRepository.emitEvent(
        const ChatEvent(
          type: 'session.error',
          properties: <String, dynamic>{
            'sessionID': 'ses_1',
            'error': <String, dynamic>{'message': 'Rate limit exceeded'},
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(provider.state, ChatState.error);
      expect(provider.errorMessage, 'Rate limit exceeded');
    });

    test(
      'sendMessage replaces optimistic local user message with server user message',
      () async {
        final now = DateTime.now();
        final serverUserMessage = UserMessage(
          id: 'msg_server_user_1',
          sessionId: 'ses_1',
          time: now.add(const Duration(seconds: 1)),
          parts: const <MessagePart>[
            TextPart(
              id: 'prt_user_server_1',
              messageId: 'msg_server_user_1',
              sessionId: 'ses_1',
              text: 'hello dedupe',
            ),
          ],
        );
        final assistantCompleted = AssistantMessage(
          id: 'msg_assistant_dedupe',
          sessionId: 'ses_1',
          time: now.add(const Duration(seconds: 2)),
          completedTime: now.add(const Duration(seconds: 3)),
          parts: const <MessagePart>[
            TextPart(
              id: 'prt_assistant_dedupe',
              messageId: 'msg_assistant_dedupe',
              sessionId: 'ses_1',
              text: 'dedupe ok',
            ),
          ],
        );

        chatRepository.sendMessageHandler = (_, __, ___, ____) async* {
          yield Right(serverUserMessage);
          await Future<void>.delayed(const Duration(milliseconds: 1));
          yield Right(assistantCompleted);
        };

        await provider.projectProvider.initializeProject();
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);

        await provider.sendMessage('hello dedupe');
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(provider.state, ChatState.loaded);
        expect(provider.messages.length, 2);
        expect(provider.messages.first.id, 'msg_server_user_1');
        expect((provider.messages.first as UserMessage).parts, hasLength(1));
        expect(
          ((provider.messages.first as UserMessage).parts.first as TextPart)
              .text,
          'hello dedupe',
        );
        expect(provider.messages.last.id, 'msg_assistant_dedupe');
      },
    );

    test('sendMessage does not forward local messageId to server', () async {
      final now = DateTime.now();
      String? echoedMessageId;

      chatRepository.sendMessageHandler = (_, __, input, ___) async* {
        echoedMessageId = input.messageId;
        yield Right(
          UserMessage(
            id: 'msg_server_user_1',
            sessionId: 'ses_1',
            time: now.add(const Duration(seconds: 1)),
            parts: <MessagePart>[
              TextPart(
                id: 'prt_user_server_1',
                messageId: 'msg_server_user_1',
                sessionId: 'ses_1',
                text: 'hello stable id',
              ),
            ],
          ),
        );
      };

      await provider.projectProvider.initializeProject();
      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);

      await provider.sendMessage('hello stable id');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // messageId must not be sent to the server.
      expect(echoedMessageId, isNull);
      expect(provider.state, ChatState.loaded);
      // Reconciliation by content signature deduplicates the optimistic message.
      expect(provider.messages.whereType<UserMessage>(), hasLength(1));
      final userMessage = provider.messages.single as UserMessage;
      expect(userMessage.id, 'msg_server_user_1');
      expect((userMessage.parts.single as TextPart).text, 'hello stable id');
    });

    test(
      'sendMessage dedupes optimistic attachment message when server file URL differs',
      () async {
        final now = DateTime.now();
        final serverUserMessage = UserMessage(
          id: 'msg_server_user_attachment_1',
          sessionId: 'ses_1',
          time: now.add(const Duration(seconds: 1)),
          parts: const <MessagePart>[
            FilePart(
              id: 'prt_user_server_file_1',
              messageId: 'msg_server_user_attachment_1',
              sessionId: 'ses_1',
              url: 'file:///tmp/uploaded/image.png',
              mime: 'image/png',
              filename: 'image.png',
            ),
          ],
        );
        final assistantCompleted = AssistantMessage(
          id: 'msg_assistant_attachment_dedupe',
          sessionId: 'ses_1',
          time: now.add(const Duration(seconds: 2)),
          completedTime: now.add(const Duration(seconds: 3)),
          parts: const <MessagePart>[
            TextPart(
              id: 'prt_assistant_attachment_dedupe',
              messageId: 'msg_assistant_attachment_dedupe',
              sessionId: 'ses_1',
              text: 'attachment dedupe ok',
            ),
          ],
        );

        chatRepository.sendMessageHandler = (_, __, ___, ____) async* {
          yield Right(serverUserMessage);
          await Future<void>.delayed(const Duration(milliseconds: 1));
          yield Right(assistantCompleted);
        };

        await provider.projectProvider.initializeProject();
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);

        await provider.sendMessage(
          '',
          attachments: const <FileInputPart>[
            FileInputPart(
              mime: 'image/png',
              url: 'data:image/png;base64,AA==',
              filename: 'image.png',
            ),
          ],
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(provider.state, ChatState.loaded);
        expect(provider.messages.length, 2);
        expect(provider.messages.first.id, 'msg_server_user_attachment_1');
        expect((provider.messages.first as UserMessage).parts, hasLength(1));
        final firstPart =
            (provider.messages.first as UserMessage).parts.first as FilePart;
        expect(firstPart.mime, 'image/png');
        expect(firstPart.filename, 'image.png');
        expect(provider.messages.last.id, 'msg_assistant_attachment_dedupe');
      },
    );

    test(
      'sendMessage works when recent models are restored from local storage',
      () async {
        final scopeId =
            provider.projectProvider.currentProject?.path ??
            provider.projectProvider.currentProjectId;
        await localDataSource.saveRecentModelsJson(
          jsonEncode(<String>['provider_a/model_a']),
          serverId: 'srv_test',
          scopeId: scopeId,
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

        final assistantCompleted = AssistantMessage(
          id: 'msg_assistant_recent_storage',
          sessionId: 'ses_1',
          time: DateTime.fromMillisecondsSinceEpoch(2000),
          completedTime: DateTime.fromMillisecondsSinceEpoch(2200),
          parts: const <MessagePart>[
            TextPart(
              id: 'prt_recent_storage_done',
              messageId: 'msg_assistant_recent_storage',
              sessionId: 'ses_1',
              text: 'answer from restored recent model',
            ),
          ],
        );
        chatRepository.sendMessageHandler = (_, __, ___, ____) async* {
          yield Right(assistantCompleted);
        };

        await provider.projectProvider.initializeProject();
        await provider.initializeProviders();
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);

        await provider.sendMessage('hello from restored recent storage');
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(provider.state, ChatState.loaded);
        expect(
          chatRepository.lastSendInput?.parts.single,
          const TextInputPart(text: 'hello from restored recent storage'),
        );
        final assistant = provider.messages.last as AssistantMessage;
        expect(
          (assistant.parts.single as TextPart).text,
          'answer from restored recent model',
        );
      },
    );

    test(
      'sendMessage continues when local selection persistence fails',
      () async {
        final failingLocalDataSource = _ThrowingPersistenceLocalDataSource();
        failingLocalDataSource.activeServerId = 'srv_test';

        final resilientProvider = ChatProvider(
          sendChatMessage: SendChatMessage(chatRepository),
          getChatSessions: GetChatSessions(chatRepository),
          createChatSession: CreateChatSession(chatRepository),
          getChatMessages: GetChatMessages(chatRepository),
          getChatMessage: GetChatMessage(chatRepository),
          getAgents: GetAgents(appRepository),
          getProviders: GetProviders(appRepository),
          deleteChatSession: DeleteChatSession(chatRepository),
          updateChatSession: UpdateChatSession(chatRepository),
          shareChatSession: ShareChatSession(chatRepository),
          unshareChatSession: UnshareChatSession(chatRepository),
          forkChatSession: ForkChatSession(chatRepository),
          getSessionStatus: GetSessionStatus(chatRepository),
          getSessionChildren: GetSessionChildren(chatRepository),
          getSessionTodo: GetSessionTodo(chatRepository),
          getSessionDiff: GetSessionDiff(chatRepository),
          watchChatEvents: WatchChatEvents(chatRepository),
          watchGlobalChatEvents: WatchGlobalChatEvents(chatRepository),
          listPendingPermissions: ListPendingPermissions(chatRepository),
          replyPermission: ReplyPermission(chatRepository),
          listPendingQuestions: ListPendingQuestions(chatRepository),
          replyQuestion: ReplyQuestion(chatRepository),
          rejectQuestion: RejectQuestion(chatRepository),
          projectProvider: ProjectProvider(
            projectRepository: FakeProjectRepository(),
            localDataSource: failingLocalDataSource,
          ),
          localDataSource: failingLocalDataSource,
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

        final assistantCompleted = AssistantMessage(
          id: 'msg_assistant_resilient',
          sessionId: 'ses_1',
          time: DateTime.fromMillisecondsSinceEpoch(2000),
          completedTime: DateTime.fromMillisecondsSinceEpoch(2200),
          parts: const <MessagePart>[
            TextPart(
              id: 'prt_resilient_done',
              messageId: 'msg_assistant_resilient',
              sessionId: 'ses_1',
              text: 'resilient answer',
            ),
          ],
        );
        chatRepository.sendMessageHandler = (_, __, ___, ____) async* {
          yield Right(assistantCompleted);
        };

        await resilientProvider.projectProvider.initializeProject();
        await resilientProvider.initializeProviders();
        await resilientProvider.loadSessions();
        await resilientProvider.selectSession(resilientProvider.sessions.first);

        await resilientProvider.sendMessage('hello with persistence failure');
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(resilientProvider.state, ChatState.loaded);
        expect(
          chatRepository.lastSendInput?.parts.single,
          const TextInputPart(text: 'hello with persistence failure'),
        );
        expect(chatRepository.lastSendInput?.messageId, isNull);
        final assistant = resilientProvider.messages.last as AssistantMessage;
        expect((assistant.parts.single as TextPart).text, 'resilient answer');
      },
    );

    test(
      'refreshActiveSessionView does not duplicate user message reconciled by content signature',
      () async {
        // Simulate the duplication bug: the local optimistic user message has a
        // different ID than the server-echoed version. During an active stream,
        // _mergeServerMessagesWithActiveLocalTail must not re-append the local
        // message after _mergeServerMessagesWithPendingLocalUsers reconciled it.
        final now = DateTime.now();
        final streamController =
            StreamController<Either<Failure, ChatMessage>>();
        addTearDown(() async {
          await streamController.close();
        });

        chatRepository.sendMessageHandler = (_, __, ___, ____) {
          // Emit the server user message echo, then keep the stream open
          // (simulating an in-progress assistant response / tool calls).
          streamController.add(
            Right(
              UserMessage(
                id: 'msg_server_user',
                sessionId: 'ses_1',
                time: now.add(const Duration(seconds: 1)),
                parts: const <MessagePart>[
                  TextPart(
                    id: 'prt_server_user',
                    messageId: 'msg_server_user',
                    sessionId: 'ses_1',
                    text: 'hello dedup active',
                  ),
                ],
              ),
            ),
          );
          // Emit a partial (in-progress) assistant to keep session "active".
          streamController.add(
            Right(
              AssistantMessage(
                id: 'msg_assistant_partial',
                sessionId: 'ses_1',
                time: now.add(const Duration(seconds: 2)),
                // No completedTime — this marks it as in-progress.
                parts: const <MessagePart>[
                  TextPart(
                    id: 'prt_assistant_partial',
                    messageId: 'msg_assistant_partial',
                    sessionId: 'ses_1',
                    text: 'thinking...',
                  ),
                ],
              ),
            ),
          );
          return streamController.stream;
        };

        await provider.projectProvider.initializeProject();
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);

        await provider.sendMessage('hello dedup active');
        await Future<void>.delayed(const Duration(milliseconds: 30));

        // Verify the stream is still open and the session is actively
        // responding (prerequisite for the tail preservation code path).
        expect(provider.isCurrentSessionActivelyResponding, isTrue);

        // Set up messagesBySession to return the server-side view (different
        // user message ID, same text). This is what refreshActiveSessionView
        // will fetch from getChatMessages.
        chatRepository.messagesBySession['ses_1'] = <ChatMessage>[
          UserMessage(
            id: 'msg_server_user',
            sessionId: 'ses_1',
            time: now.add(const Duration(seconds: 1)),
            parts: const <MessagePart>[
              TextPart(
                id: 'prt_server_user',
                messageId: 'msg_server_user',
                sessionId: 'ses_1',
                text: 'hello dedup active',
              ),
            ],
          ),
          AssistantMessage(
            id: 'msg_assistant_partial',
            sessionId: 'ses_1',
            time: now.add(const Duration(seconds: 2)),
            parts: const <MessagePart>[
              TextPart(
                id: 'prt_assistant_partial',
                messageId: 'msg_assistant_partial',
                sessionId: 'ses_1',
                text: 'still thinking...',
              ),
            ],
          ),
        ];

        // Trigger the merge via refresh — this is where the duplication
        // happened before the fix.
        await provider.refresh();
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // There must be exactly one UserMessage (the server version).
        final userMessages = provider.messages
            .whereType<UserMessage>()
            .toList();
        expect(
          userMessages,
          hasLength(1),
          reason: 'User message was duplicated during active session refresh',
        );
        expect(userMessages.single.id, 'msg_server_user');

        // Assistant tail message must also stay de-duplicated after refresh.
        final assistantMessages = provider.messages
            .whereType<AssistantMessage>()
            .toList();
        expect(
          assistantMessages,
          hasLength(1),
          reason:
              'Assistant message was duplicated during active session refresh',
        );
        expect(assistantMessages.single.id, 'msg_assistant_partial');
        expect(
          (assistantMessages.single.parts.single as TextPart).text,
          'still thinking...',
        );
      },
    );
  });
}

class _ThrowingPersistenceLocalDataSource extends InMemoryAppLocalDataSource {
  @override
  Future<void> saveSelectedProvider(
    String providerId, {
    String? serverId,
    String? scopeId,
  }) async {
    throw Exception('saveSelectedProvider failed');
  }

  @override
  Future<void> saveSelectedModel(
    String modelId, {
    String? serverId,
    String? scopeId,
  }) async {
    throw Exception('saveSelectedModel failed');
  }

  @override
  Future<void> saveRecentModelsJson(
    String recentModelsJson, {
    String? serverId,
    String? scopeId,
  }) async {
    throw Exception('saveRecentModelsJson failed');
  }

  @override
  Future<void> saveModelUsageCountsJson(
    String usageCountsJson, {
    String? serverId,
    String? scopeId,
  }) async {
    throw Exception('saveModelUsageCountsJson failed');
  }

  @override
  Future<void> saveSelectedVariantMap(
    String variantMapJson, {
    String? serverId,
    String? scopeId,
  }) async {
    throw Exception('saveSelectedVariantMap failed');
  }
}

class _FakeChatTitleGenerator implements ChatTitleGenerator {
  int callCount = 0;
  final List<List<ChatTitleGeneratorMessage>> payloads =
      <List<ChatTitleGeneratorMessage>>[];

  @override
  Future<String?> generateTitle(
    List<ChatTitleGeneratorMessage> messages, {
    int maxWords = 6,
  }) async {
    callCount += 1;
    payloads.add(List<ChatTitleGeneratorMessage>.from(messages));
    return 'Auto title $callCount';
  }
}

class _BlockingChatTitleGenerator implements ChatTitleGenerator {
  _BlockingChatTitleGenerator(this._completer);

  final Completer<String?> _completer;
  int callCount = 0;

  @override
  Future<String?> generateTitle(
    List<ChatTitleGeneratorMessage> messages, {
    int maxWords = 6,
  }) {
    callCount += 1;
    return _completer.future;
  }
}
