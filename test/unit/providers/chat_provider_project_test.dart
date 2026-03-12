@Tags(<String>['slow'])
library;

import 'dart:async';
import 'dart:convert';

import 'package:codewalk/core/errors/failures.dart';
import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/domain/entities/chat_message.dart';
import 'package:codewalk/domain/entities/chat_realtime.dart';
import 'package:codewalk/domain/entities/chat_session.dart';
import 'package:codewalk/domain/entities/project.dart';
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
import 'package:codewalk/presentation/services/chat_title_generator.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import 'chat_provider_test_support.dart';

void main() {
  group('ChatProvider - project', () {
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

    test(
      'loads and responds to pending permission and question requests',
      () async {
        chatRepository.pendingPermissions = const <ChatPermissionRequest>[
          ChatPermissionRequest(
            id: 'perm_1',
            sessionId: 'ses_1',
            permission: 'edit',
            patterns: <String>['lib/**'],
            always: <String>[],
            metadata: <String, dynamic>{},
          ),
        ];
        chatRepository.pendingQuestions = const <ChatQuestionRequest>[
          ChatQuestionRequest(
            id: 'q_1',
            sessionId: 'ses_1',
            questions: <ChatQuestionInfo>[
              ChatQuestionInfo(
                question: 'Proceed?',
                header: 'Confirm',
                options: <ChatQuestionOption>[
                  ChatQuestionOption(label: 'Yes', description: 'continue'),
                ],
              ),
            ],
          ),
        ];
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

        expect(provider.currentPermissionRequest?.id, 'perm_1');
        expect(provider.currentQuestionRequest?.id, 'q_1');

        await provider.respondPermissionRequest(
          requestId: 'perm_1',
          reply: 'once',
        );
        expect(chatRepository.lastPermissionRequestId, 'perm_1');
        expect(chatRepository.lastPermissionReply, 'once');

        await provider.submitQuestionAnswers(
          requestId: 'q_1',
          answers: const <List<String>>[
            <String>['Yes'],
          ],
        );
        expect(chatRepository.lastQuestionReplyRequestId, 'q_1');
        expect(chatRepository.lastQuestionAnswers, const <List<String>>[
          <String>['Yes'],
        ]);
      },
    );

    test(
      'collects current-thread permissions including subagent descendants',
      () async {
        chatRepository.sessions.add(
          ChatSession(
            id: 'ses_child_1',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(900),
            title: 'Child Session',
            parentId: 'ses_1',
          ),
        );

        chatRepository.pendingPermissions = const <ChatPermissionRequest>[
          ChatPermissionRequest(
            id: 'perm_root_1',
            sessionId: 'ses_1',
            permission: 'edit',
            patterns: <String>['lib/**'],
            always: <String>[],
            metadata: <String, dynamic>{},
          ),
          ChatPermissionRequest(
            id: 'perm_sub_1',
            sessionId: 'ses_child_1',
            permission: 'bash',
            patterns: <String>['*'],
            always: <String>[],
            metadata: <String, dynamic>{},
          ),
          ChatPermissionRequest(
            id: 'perm_other_1',
            sessionId: 'ses_unrelated',
            permission: 'read',
            patterns: <String>['README.md'],
            always: <String>[],
            metadata: <String, dynamic>{},
          ),
        ];

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
        await provider.selectSession(
          provider.sessions.where((item) => item.id == 'ses_1').first,
        );

        expect(
          provider.currentThreadPermissionRequests.map((item) => item.id),
          <String>['perm_root_1', 'perm_sub_1'],
        );
        final currentSessionId = provider.currentSession?.id;
        final subagentRequestIds = provider.currentThreadPermissionRequests
            .where((item) => item.sessionId != currentSessionId)
            .map((item) => item.id)
            .toList(growable: false);

        expect(subagentRequestIds, <String>['perm_sub_1']);
      },
    );

    test(
      'collects current-thread questions including subagent descendants',
      () async {
        chatRepository.sessions.add(
          ChatSession(
            id: 'ses_child_1',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(900),
            title: 'Child Session',
            parentId: 'ses_1',
          ),
        );

        chatRepository.pendingQuestions = const <ChatQuestionRequest>[
          ChatQuestionRequest(
            id: 'q_root_1',
            sessionId: 'ses_1',
            questions: <ChatQuestionInfo>[
              ChatQuestionInfo(
                question: 'Approve root?',
                header: 'Root',
                options: <ChatQuestionOption>[
                  ChatQuestionOption(label: 'Yes', description: 'Continue'),
                ],
              ),
            ],
          ),
          ChatQuestionRequest(
            id: 'q_sub_1',
            sessionId: 'ses_child_1',
            questions: <ChatQuestionInfo>[
              ChatQuestionInfo(
                question: 'Approve child?',
                header: 'Child',
                options: <ChatQuestionOption>[
                  ChatQuestionOption(label: 'Yes', description: 'Continue'),
                ],
              ),
            ],
          ),
          ChatQuestionRequest(
            id: 'q_other_1',
            sessionId: 'ses_unrelated',
            questions: <ChatQuestionInfo>[
              ChatQuestionInfo(
                question: 'Ignore other?',
                header: 'Other',
                options: <ChatQuestionOption>[
                  ChatQuestionOption(label: 'Yes', description: 'Continue'),
                ],
              ),
            ],
          ),
        ];

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
        await provider.selectSession(
          provider.sessions.where((item) => item.id == 'ses_1').first,
        );

        expect(
          provider.currentThreadQuestionRequests.map((item) => item.id),
          <String>['q_root_1', 'q_sub_1'],
        );
      },
    );

    test(
      'rejectQuestionRequest removes pending question from provider state',
      () async {
        chatRepository.pendingQuestions = const <ChatQuestionRequest>[
          ChatQuestionRequest(
            id: 'q_reject_1',
            sessionId: 'ses_1',
            questions: <ChatQuestionInfo>[
              ChatQuestionInfo(
                question: 'Reject this?',
                header: 'Confirm',
                options: <ChatQuestionOption>[
                  ChatQuestionOption(label: 'Yes', description: 'Reject'),
                ],
              ),
            ],
          ),
        ];
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

        expect(provider.currentQuestionRequest?.id, 'q_reject_1');

        await provider.rejectQuestionRequest(requestId: 'q_reject_1');

        expect(chatRepository.lastQuestionRejectRequestId, 'q_reject_1');
        expect(provider.currentQuestionRequest, isNull);
      },
    );

    test(
      'switches project context with isolated directory session state',
      () async {
        final scopedRepository = FakeChatRepository(
          sessions: <ChatSession>[
            ChatSession(
              id: 'ses_a',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              title: 'Session A',
            ),
          ],
        );
        final scopedLocal = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test';
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
            projectRepository: FakeProjectRepository(
              currentProject: Project(
                id: 'proj_a',
                name: 'Project A',
                path: '/repo/a',
                createdAt: DateTime.fromMillisecondsSinceEpoch(0),
              ),
              projects: <Project>[
                Project(
                  id: 'proj_a',
                  name: 'Project A',
                  path: '/repo/a',
                  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
                ),
                Project(
                  id: 'proj_b',
                  name: 'Project B',
                  path: '/repo/b',
                  createdAt: DateTime.fromMillisecondsSinceEpoch(1),
                ),
              ],
            ),
            localDataSource: scopedLocal,
          ),
          localDataSource: scopedLocal,
        );

        await scopedProvider.projectProvider.initializeProject();
        await scopedProvider.initializeProviders();
        await scopedProvider.loadSessions();
        expect(scopedRepository.lastGetSessionsDirectory, '/repo/a');
        expect(scopedProvider.sessions.first.id, 'ses_a');

        scopedRepository.sessions
          ..clear()
          ..add(
            ChatSession(
              id: 'ses_b',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(2000),
              title: 'Session B',
            ),
          );
        await scopedProvider.projectProvider.switchProject('proj_b');
        await scopedProvider.onProjectScopeChanged();
        expect(scopedRepository.lastGetSessionsDirectory, '/repo/b');
        expect(scopedProvider.sessions.first.id, 'ses_b');

        await scopedProvider.projectProvider.switchProject('proj_a');
        await scopedProvider.onProjectScopeChanged();
        expect(scopedProvider.sessions.first.id, 'ses_a');
      },
    );

    test(
      'project scope round-trip does not cancel in-flight stream from previous context',
      () async {
        final scopedRepository = FakeChatRepository(
          sessions: <ChatSession>[
            ChatSession(
              id: 'ses_a',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              title: 'Session A',
            ),
          ],
        );
        final streamController =
            StreamController<Either<Failure, ChatMessage>>();
        var streamCancelled = false;
        streamController.onCancel = () {
          streamCancelled = true;
        };
        scopedRepository.sendMessageHandler = (_, _, _, _) {
          return streamController.stream;
        };
        addTearDown(() async {
          await streamController.close();
        });

        final scopedLocal = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test';
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
            projectRepository: FakeProjectRepository(
              currentProject: Project(
                id: 'proj_a',
                name: 'Project A',
                path: '/repo/a',
                createdAt: DateTime.fromMillisecondsSinceEpoch(0),
              ),
              projects: <Project>[
                Project(
                  id: 'proj_a',
                  name: 'Project A',
                  path: '/repo/a',
                  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
                ),
                Project(
                  id: 'proj_b',
                  name: 'Project B',
                  path: '/repo/b',
                  createdAt: DateTime.fromMillisecondsSinceEpoch(1),
                ),
              ],
            ),
            localDataSource: scopedLocal,
          ),
          localDataSource: scopedLocal,
        );
        await scopedProvider.projectProvider.initializeProject();
        await scopedProvider.initializeProviders();
        await scopedProvider.loadSessions();
        await scopedProvider.selectSession(scopedProvider.sessions.first);

        await scopedProvider.sendMessage('keep this conversation alive');
        await Future<void>.delayed(const Duration(milliseconds: 20));

        await scopedProvider.projectProvider.switchProject('proj_b');
        await scopedProvider.onProjectScopeChanged();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        await scopedProvider.projectProvider.switchProject('proj_a');
        await scopedProvider.onProjectScopeChanged();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(streamCancelled, isTrue);
      },
    );

    test('pinned sessions stay isolated per project scope', () async {
      final scopedRepository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_a',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Session A',
          ),
        ],
      );
      final scopedLocal = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
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
          projectRepository: FakeProjectRepository(
            currentProject: Project(
              id: 'proj_a',
              name: 'Project A',
              path: '/repo/a',
              createdAt: DateTime.fromMillisecondsSinceEpoch(0),
            ),
            projects: <Project>[
              Project(
                id: 'proj_a',
                name: 'Project A',
                path: '/repo/a',
                createdAt: DateTime.fromMillisecondsSinceEpoch(0),
              ),
              Project(
                id: 'proj_b',
                name: 'Project B',
                path: '/repo/b',
                createdAt: DateTime.fromMillisecondsSinceEpoch(1),
              ),
            ],
          ),
          localDataSource: scopedLocal,
        ),
        localDataSource: scopedLocal,
      );

      await scopedProvider.projectProvider.initializeProject();
      await scopedProvider.initializeProviders();
      await scopedProvider.loadSessions();

      final projectASession = scopedProvider.sessions.first;
      await scopedProvider.toggleSessionPinned(projectASession);
      expect(scopedProvider.isSessionPinned('ses_a'), isTrue);

      scopedRepository.sessions
        ..clear()
        ..add(
          ChatSession(
            id: 'ses_b',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(2000),
            title: 'Session B',
          ),
        );
      await scopedProvider.projectProvider.switchProject('proj_b');
      await scopedProvider.onProjectScopeChanged();

      expect(scopedProvider.isSessionPinned('ses_a'), isFalse);
      expect(scopedProvider.isSessionPinned('ses_b'), isFalse);

      scopedRepository.sessions
        ..clear()
        ..add(
          ChatSession(
            id: 'ses_a',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Session A',
          ),
        );
      await scopedProvider.projectProvider.switchProject('proj_a');
      await scopedProvider.onProjectScopeChanged();

      expect(scopedProvider.isSessionPinned('ses_a'), isTrue);
    });

    test(
      'switching project restores last session for each directory automatically',
      () async {
        final scopedRepository = FakeChatRepository(
          sessions: <ChatSession>[
            ChatSession(
              id: 'ses_a_old',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              title: 'Session A Old',
            ),
            ChatSession(
              id: 'ses_a_new',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(3000),
              title: 'Session A New',
            ),
          ],
        );
        final scopedLocal = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test';
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
            projectRepository: FakeProjectRepository(
              currentProject: Project(
                id: 'proj_a',
                name: 'Project A',
                path: '/repo/a',
                createdAt: DateTime.fromMillisecondsSinceEpoch(0),
              ),
              projects: <Project>[
                Project(
                  id: 'proj_a',
                  name: 'Project A',
                  path: '/repo/a',
                  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
                ),
                Project(
                  id: 'proj_b',
                  name: 'Project B',
                  path: '/repo/b',
                  createdAt: DateTime.fromMillisecondsSinceEpoch(1),
                ),
              ],
            ),
            localDataSource: scopedLocal,
          ),
          localDataSource: scopedLocal,
        );

        await scopedProvider.projectProvider.initializeProject();
        await scopedProvider.initializeProviders();
        await scopedProvider.loadSessions();

        expect(scopedProvider.currentSession?.id, 'ses_a_new');
        expect(
          scopedLocal.scopedStrings['current_session_id::srv_test::/repo/a'],
          'ses_a_new',
        );

        scopedRepository.sessions
          ..clear()
          ..addAll(<ChatSession>[
            ChatSession(
              id: 'ses_b_old',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1500),
              title: 'Session B Old',
            ),
            ChatSession(
              id: 'ses_b_new',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(2500),
              title: 'Session B New',
            ),
          ]);
        await scopedProvider.projectProvider.switchProject('proj_b');
        await scopedProvider.onProjectScopeChanged();

        expect(scopedProvider.currentSession?.id, 'ses_b_new');
        expect(
          scopedLocal.scopedStrings['current_session_id::srv_test::/repo/b'],
          'ses_b_new',
        );

        final oldSessionB = scopedProvider.sessions
            .where((session) => session.id == 'ses_b_old')
            .first;
        await scopedProvider.selectSession(oldSessionB);
        expect(scopedProvider.currentSession?.id, 'ses_b_old');
        expect(
          scopedLocal.scopedStrings['current_session_id::srv_test::/repo/b'],
          'ses_b_old',
        );

        await scopedProvider.projectProvider.switchProject('proj_a');
        await scopedProvider.onProjectScopeChanged();
        expect(scopedProvider.currentSession?.id, 'ses_a_new');

        await scopedProvider.projectProvider.switchProject('proj_b');
        await scopedProvider.onProjectScopeChanged();
        expect(scopedProvider.currentSession?.id, 'ses_b_old');
      },
    );

    test(
      'project switch can return quickly and revalidate sessions in background',
      () async {
        final scopedRepository = FakeChatRepository(
          sessions: <ChatSession>[
            ChatSession(
              id: 'ses_a',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              title: 'Session A',
            ),
          ],
        );
        final scopedLocal = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test';
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
            projectRepository: FakeProjectRepository(
              currentProject: Project(
                id: 'proj_a',
                name: 'Project A',
                path: '/repo/a',
                createdAt: DateTime.fromMillisecondsSinceEpoch(0),
              ),
              projects: <Project>[
                Project(
                  id: 'proj_a',
                  name: 'Project A',
                  path: '/repo/a',
                  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
                ),
                Project(
                  id: 'proj_b',
                  name: 'Project B',
                  path: '/repo/b',
                  createdAt: DateTime.fromMillisecondsSinceEpoch(1),
                ),
              ],
            ),
            localDataSource: scopedLocal,
          ),
          localDataSource: scopedLocal,
        );

        await scopedProvider.projectProvider.initializeProject();
        await scopedProvider.initializeProviders();
        await scopedProvider.loadSessions();
        expect(scopedProvider.sessions.map((item) => item.id), <String>[
          'ses_a',
        ]);

        scopedRepository.sessions
          ..clear()
          ..add(
            ChatSession(
              id: 'ses_b_cached',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(2000),
              title: 'Session B Cached',
            ),
          );
        await scopedProvider.projectProvider.switchProject('proj_b');
        await scopedProvider.onProjectScopeChanged();
        expect(scopedProvider.sessions.map((item) => item.id), <String>[
          'ses_b_cached',
        ]);

        await scopedProvider.projectProvider.switchProject('proj_a');
        await scopedProvider.onProjectScopeChanged();
        expect(scopedProvider.sessions.map((item) => item.id), <String>[
          'ses_a',
        ]);

        final networkGate = Completer<void>();
        final networkStarted = Completer<void>();
        scopedRepository.getSessionsDelay = () async {
          if (!networkStarted.isCompleted) {
            networkStarted.complete();
          }
          await networkGate.future;
        };
        final messagesGate = Completer<void>();
        final messagesStarted = Completer<void>();
        scopedRepository.getMessagesDelay = () async {
          if (!messagesStarted.isCompleted) {
            messagesStarted.complete();
          }
          await messagesGate.future;
        };

        scopedRepository.sessions
          ..clear()
          ..add(
            ChatSession(
              id: 'ses_b_fresh',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(3000),
              title: 'Session B Fresh',
            ),
          );

        await scopedProvider.projectProvider.switchProject('proj_b');
        await scopedProvider
            .onProjectScopeChanged(waitForRevalidation: false)
            .timeout(const Duration(milliseconds: 300));

        await networkStarted.future;
        await messagesStarted.future;
        expect(scopedProvider.sessions.map((item) => item.id), <String>[
          'ses_b_cached',
        ]);

        messagesGate.complete();
        networkGate.complete();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(scopedProvider.sessions.map((item) => item.id), <String>[
          'ses_b_fresh',
        ]);
      },
    );

    test(
      'project switch fast-path does not leak draft mode across contexts',
      () async {
        final scopedRepository = FakeChatRepository(
          sessions: <ChatSession>[
            ChatSession(
              id: 'ses_a',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              title: 'Session A',
            ),
          ],
        );
        final scopedLocal = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test';
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
            projectRepository: FakeProjectRepository(
              currentProject: Project(
                id: 'proj_a',
                name: 'Project A',
                path: '/repo/a',
                createdAt: DateTime.fromMillisecondsSinceEpoch(0),
              ),
              projects: <Project>[
                Project(
                  id: 'proj_a',
                  name: 'Project A',
                  path: '/repo/a',
                  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
                ),
                Project(
                  id: 'proj_b',
                  name: 'Project B',
                  path: '/repo/b',
                  createdAt: DateTime.fromMillisecondsSinceEpoch(1),
                ),
              ],
            ),
            localDataSource: scopedLocal,
          ),
          localDataSource: scopedLocal,
        );

        await scopedProvider.projectProvider.initializeProject();
        await scopedProvider.initializeProviders();
        await scopedProvider.loadSessions();
        expect(scopedProvider.currentSession?.id, 'ses_a');

        await scopedProvider.beginNewChatDraft();
        expect(scopedProvider.isDraftingNewChat, isTrue);
        expect(scopedProvider.currentSession, isNull);

        scopedRepository.sessions
          ..clear()
          ..add(
            ChatSession(
              id: 'ses_b',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(2000),
              title: 'Session B',
            ),
          );

        await scopedProvider.projectProvider.switchProject('proj_b');
        await scopedProvider
            .onProjectScopeChanged(waitForRevalidation: false)
            .timeout(const Duration(milliseconds: 300));
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(scopedProvider.isDraftingNewChat, isFalse);
        expect(scopedProvider.currentSession?.id, 'ses_b');

        scopedRepository.sessions
          ..clear()
          ..add(
            ChatSession(
              id: 'ses_a',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              title: 'Session A',
            ),
          );

        await scopedProvider.projectProvider.switchProject('proj_a');
        await scopedProvider
            .onProjectScopeChanged(waitForRevalidation: false)
            .timeout(const Duration(milliseconds: 300));
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(scopedProvider.isDraftingNewChat, isTrue);
        expect(scopedProvider.currentSession, isNull);
      },
    );

    test(
      'filters mixed session list to active directory when server returns unscoped data',
      () async {
        final scopedRepository = FakeChatRepository(
          sessions: <ChatSession>[
            ChatSession(
              id: 'ses_a',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(3000),
              title: 'Session A',
              directory: '/repo/a',
            ),
            ChatSession(
              id: 'ses_b',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(2000),
              title: 'Session B',
              directory: '/repo/b',
            ),
            ChatSession(
              id: 'ses_unknown',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              title: 'Session Unknown',
            ),
          ],
        );

        final scopedLocal = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test';
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
            projectRepository: FakeProjectRepository(
              currentProject: Project(
                id: 'proj_a',
                name: 'Project A',
                path: '/repo/a',
                createdAt: DateTime.fromMillisecondsSinceEpoch(0),
              ),
              projects: <Project>[
                Project(
                  id: 'proj_a',
                  name: 'Project A',
                  path: '/repo/a',
                  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
                ),
                Project(
                  id: 'proj_b',
                  name: 'Project B',
                  path: '/repo/b',
                  createdAt: DateTime.fromMillisecondsSinceEpoch(1),
                ),
              ],
            ),
            localDataSource: scopedLocal,
          ),
          localDataSource: scopedLocal,
        );

        await scopedProvider.projectProvider.initializeProject();
        await scopedProvider.initializeProviders();
        await scopedProvider.loadSessions();

        expect(scopedRepository.lastGetSessionsDirectory, '/repo/a');
        expect(scopedProvider.sessions.map((item) => item.id), <String>[
          'ses_a',
        ]);

        await scopedProvider.projectProvider.switchProject('proj_b');
        await scopedProvider.onProjectScopeChanged();

        expect(scopedRepository.lastGetSessionsDirectory, '/repo/b');
        expect(scopedProvider.sessions.map((item) => item.id), <String>[
          'ses_b',
        ]);
      },
    );

    test(
      'loadSessions excludes internal _title_gen sessions from Conversations',
      () async {
        chatRepository.sessions
          ..clear()
          ..addAll(<ChatSession>[
            ChatSession(
              id: 'ses_internal_title',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(3000),
              title: ChatTitleGenerator.ephemeralSessionTitle,
            ),
            ChatSession(
              id: 'ses_user_visible',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(2000),
              title: 'Visible Conversation',
            ),
          ]);

        await provider.loadSessions();

        expect(provider.sessions.map((session) => session.id), <String>[
          'ses_user_visible',
        ]);
        expect(provider.visibleSessions.map((session) => session.id), <String>[
          'ses_user_visible',
        ]);
      },
    );

    test(
      'global event marks non-active context dirty and reloads on return',
      () async {
        final scopedRepository = FakeChatRepository(
          sessions: <ChatSession>[
            ChatSession(
              id: 'ses_a_old',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              title: 'Session A Old',
            ),
          ],
        );
        final scopedLocal = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test';
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
            projectRepository: FakeProjectRepository(
              currentProject: Project(
                id: 'proj_a',
                name: 'Project A',
                path: '/repo/a',
                createdAt: DateTime.fromMillisecondsSinceEpoch(0),
              ),
              projects: <Project>[
                Project(
                  id: 'proj_a',
                  name: 'Project A',
                  path: '/repo/a',
                  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
                ),
                Project(
                  id: 'proj_b',
                  name: 'Project B',
                  path: '/repo/b',
                  createdAt: DateTime.fromMillisecondsSinceEpoch(1),
                ),
              ],
            ),
            localDataSource: scopedLocal,
          ),
          localDataSource: scopedLocal,
        );

        await scopedProvider.projectProvider.initializeProject();
        await scopedProvider.initializeProviders();
        await scopedProvider.loadSessions();
        expect(scopedProvider.sessions.first.id, 'ses_a_old');

        scopedRepository.sessions
          ..clear()
          ..add(
            ChatSession(
              id: 'ses_b',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(2000),
              title: 'Session B',
            ),
          );
        await scopedProvider.projectProvider.switchProject('proj_b');
        await scopedProvider.onProjectScopeChanged();
        expect(scopedProvider.sessions.first.id, 'ses_b');

        scopedRepository.emitGlobalEvent(
          const ChatEvent(
            type: 'session.updated',
            properties: <String, dynamic>{'directory': '/repo/a'},
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));

        scopedRepository.sessions
          ..clear()
          ..add(
            ChatSession(
              id: 'ses_a_new',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(3000),
              title: 'Session A New',
            ),
          );
        await scopedProvider.projectProvider.switchProject('proj_a');
        await scopedProvider.onProjectScopeChanged();

        expect(scopedProvider.sessions.first.id, 'ses_a_new');
      },
    );

    test(
      'global session.updated patches inactive cached sessions immediately',
      () async {
        final scopedRepository = FakeChatRepository(
          sessions: <ChatSession>[
            ChatSession(
              id: 'ses_a_old',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              title: 'Session A Old',
            ),
          ],
        );
        final scopedLocal = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test';
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
            projectRepository: FakeProjectRepository(
              currentProject: Project(
                id: 'proj_a',
                name: 'Project A',
                path: '/repo/a',
                createdAt: DateTime.fromMillisecondsSinceEpoch(0),
              ),
              projects: <Project>[
                Project(
                  id: 'proj_a',
                  name: 'Project A',
                  path: '/repo/a',
                  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
                ),
                Project(
                  id: 'proj_b',
                  name: 'Project B',
                  path: '/repo/b',
                  createdAt: DateTime.fromMillisecondsSinceEpoch(1),
                ),
              ],
            ),
            localDataSource: scopedLocal,
          ),
          localDataSource: scopedLocal,
        );

        await scopedProvider.projectProvider.initializeProject();
        await scopedProvider.initializeProviders();
        await scopedProvider.loadSessions();
        expect(scopedProvider.sessions.first.title, 'Session A Old');

        scopedRepository.sessions
          ..clear()
          ..add(
            ChatSession(
              id: 'ses_b',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(2000),
              title: 'Session B',
            ),
          );
        await scopedProvider.projectProvider.switchProject('proj_b');
        await scopedProvider.onProjectScopeChanged();
        expect(scopedProvider.sessions.first.title, 'Session B');

        scopedRepository.emitGlobalEvent(
          const ChatEvent(
            type: 'session.updated',
            properties: <String, dynamic>{
              'directory': '/repo/a',
              'info': <String, dynamic>{
                'id': 'ses_a_old',
                'workspaceId': 'default',
                'title': 'Session A Renamed',
                'time': <String, dynamic>{'created': 1000, 'updated': 3000},
              },
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));

        final inactiveSessions = scopedProvider.visibleSessionsForScopeId(
          '/repo/a',
        );
        expect(inactiveSessions, isNotEmpty);
        expect(inactiveSessions.first.title, 'Session A Renamed');
      },
    );

    test(
      'dirty inactive context keeps cached sessions visible during fast switch',
      () async {
        final scopedRepository = FakeChatRepository(
          sessions: <ChatSession>[
            ChatSession(
              id: 'ses_a_old',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              title: 'Session A Old',
            ),
          ],
        );
        final scopedLocal = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test';
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
            projectRepository: FakeProjectRepository(
              currentProject: Project(
                id: 'proj_a',
                name: 'Project A',
                path: '/repo/a',
                createdAt: DateTime.fromMillisecondsSinceEpoch(0),
              ),
              projects: <Project>[
                Project(
                  id: 'proj_a',
                  name: 'Project A',
                  path: '/repo/a',
                  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
                ),
                Project(
                  id: 'proj_b',
                  name: 'Project B',
                  path: '/repo/b',
                  createdAt: DateTime.fromMillisecondsSinceEpoch(1),
                ),
              ],
            ),
            localDataSource: scopedLocal,
          ),
          localDataSource: scopedLocal,
        );

        await scopedProvider.projectProvider.initializeProject();
        await scopedProvider.initializeProviders();
        await scopedProvider.loadSessions();
        expect(scopedProvider.sessions.first.id, 'ses_a_old');

        scopedRepository.sessions
          ..clear()
          ..add(
            ChatSession(
              id: 'ses_b',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(2000),
              title: 'Session B',
            ),
          );
        await scopedProvider.projectProvider.switchProject('proj_b');
        await scopedProvider.onProjectScopeChanged(waitForRevalidation: false);
        await Future<void>.delayed(const Duration(milliseconds: 40));
        expect(scopedProvider.sessions.first.id, 'ses_b');

        scopedRepository.emitGlobalEvent(
          const ChatEvent(
            type: 'session.updated',
            properties: <String, dynamic>{'directory': '/repo/a'},
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));

        final revalidationGate = Completer<void>();
        final revalidationStarted = Completer<void>();
        scopedRepository.getSessionsDelay = () async {
          if (!revalidationStarted.isCompleted) {
            revalidationStarted.complete();
          }
          await revalidationGate.future;
        };
        scopedRepository.sessions
          ..clear()
          ..add(
            ChatSession(
              id: 'ses_a_new',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(3000),
              title: 'Session A New',
            ),
          );

        await scopedProvider.projectProvider.switchProject('proj_a');
        await scopedProvider
            .onProjectScopeChanged(waitForRevalidation: false)
            .timeout(const Duration(milliseconds: 300));

        await revalidationStarted.future;
        expect(scopedProvider.sessions.first.id, 'ses_a_old');

        revalidationGate.complete();
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(scopedProvider.sessions.first.id, 'ses_a_new');
      },
    );

    test('toggleModelFavorite adds and removes model from favorites', () async {
      appRepository.providersResult = Right(
        ProvidersResponse(
          providers: <Provider>[
            Provider(
              id: 'prov_a',
              name: 'Provider A',
              env: const <String>[],
              models: <String, Model>{'mod_a': testModel('mod_a')},
            ),
          ],
          defaultModels: const <String, String>{'prov_a': 'mod_a'},
          connected: const <String>['prov_a'],
        ),
      );
      await provider.initializeProviders();

      expect(
        provider.isModelFavorite(providerId: 'prov_a', modelId: 'mod_a'),
        isFalse,
      );

      await provider.toggleModelFavorite(
        providerId: 'prov_a',
        modelId: 'mod_a',
      );
      expect(
        provider.isModelFavorite(providerId: 'prov_a', modelId: 'mod_a'),
        isTrue,
      );
      expect(provider.favoriteModelKeys, contains('prov_a/mod_a'));

      await provider.toggleModelFavorite(
        providerId: 'prov_a',
        modelId: 'mod_a',
      );
      expect(
        provider.isModelFavorite(providerId: 'prov_a', modelId: 'mod_a'),
        isFalse,
      );
      expect(provider.favoriteModelKeys, isEmpty);
    });

    test(
      'favorite models persist and reload across provider instances',
      () async {
        appRepository.providersResult = Right(
          ProvidersResponse(
            providers: <Provider>[
              Provider(
                id: 'prov_a',
                name: 'Provider A',
                env: const <String>[],
                models: <String, Model>{'mod_a': testModel('mod_a')},
              ),
            ],
            defaultModels: const <String, String>{'prov_a': 'mod_a'},
            connected: const <String>['prov_a'],
          ),
        );
        await provider.initializeProviders();
        await provider.toggleModelFavorite(
          providerId: 'prov_a',
          modelId: 'mod_a',
        );

        // Verify the data was persisted to local storage.
        final storedJson = await localDataSource.getFavoriteModelsJson(
          serverId: 'srv_test',
        );
        expect(storedJson, isNotNull);
        final decoded = json.decode(storedJson!) as List<dynamic>;
        expect(decoded, contains('prov_a/mod_a'));

        // Build a new provider instance and verify favorites are loaded.
        final provider2 = buildProvider();
        await provider2.initializeProviders();
        // Let coalesced microtask notifications flush before asserting.
        await Future<void>.delayed(Duration.zero);
        expect(
          provider2.isModelFavorite(providerId: 'prov_a', modelId: 'mod_a'),
          isTrue,
        );
        provider2.dispose();
      },
    );

    test(
      'legacy scoped favorite models are deleted after server migration',
      () async {
        appRepository.providersResult = Right(
          ProvidersResponse(
            providers: <Provider>[
              Provider(
                id: 'prov_a',
                name: 'Provider A',
                env: const <String>[],
                models: <String, Model>{'mod_a': testModel('mod_a')},
              ),
            ],
            defaultModels: const <String, String>{'prov_a': 'mod_a'},
            connected: const <String>['prov_a'],
          ),
        );
        await localDataSource.saveFavoriteModelsJson(
          json.encode(<String>['prov_a/mod_a']),
          serverId: 'srv_test',
          scopeId: 'default',
        );

        await provider.initializeProviders();

        expect(
          await localDataSource.getFavoriteModelsJson(
            serverId: 'srv_test',
            scopeId: 'default',
          ),
          isNull,
        );
        expect(
          await localDataSource.getFavoriteModelsJson(serverId: 'srv_test'),
          isNotNull,
        );
      },
    );

    test(
      'favorite models stay shared across projects on the same server',
      () async {
        final scopedLocal = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test';
        final scopedProjectProvider = ProjectProvider(
          projectRepository: FakeProjectRepository(
            currentProject: Project(
              id: 'proj_a',
              name: 'Project A',
              path: '/repo/a',
              createdAt: DateTime.fromMillisecondsSinceEpoch(0),
            ),
            projects: <Project>[
              Project(
                id: 'proj_a',
                name: 'Project A',
                path: '/repo/a',
                createdAt: DateTime.fromMillisecondsSinceEpoch(0),
              ),
              Project(
                id: 'proj_b',
                name: 'Project B',
                path: '/repo/b',
                createdAt: DateTime.fromMillisecondsSinceEpoch(1),
              ),
            ],
          ),
          localDataSource: scopedLocal,
        );
        final scopedProvider = ChatProvider(
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
          projectProvider: scopedProjectProvider,
          localDataSource: scopedLocal,
        );
        addTearDown(scopedProvider.dispose);

        appRepository.providersResult = Right(
          ProvidersResponse(
            providers: <Provider>[
              Provider(
                id: 'prov_a',
                name: 'Provider A',
                env: const <String>[],
                models: <String, Model>{'mod_a': testModel('mod_a')},
              ),
            ],
            defaultModels: const <String, String>{'prov_a': 'mod_a'},
            connected: const <String>['prov_a'],
          ),
        );

        await scopedProjectProvider.initializeProject();
        await scopedProvider.initializeProviders();
        await scopedProvider.toggleModelFavorite(
          providerId: 'prov_a',
          modelId: 'mod_a',
        );

        await scopedProjectProvider.switchProject('proj_b');
        await scopedProvider.onProjectScopeChanged();
        await scopedProvider.initializeProviders();

        expect(
          scopedProvider.isModelFavorite(
            providerId: 'prov_a',
            modelId: 'mod_a',
          ),
          isTrue,
        );
      },
    );

    test(
      'same-server project switch keeps cached providers visible during refresh',
      () async {
        final scopedLocal = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test';
        final scopedProjectProvider = ProjectProvider(
          projectRepository: FakeProjectRepository(
            currentProject: Project(
              id: 'proj_a',
              name: 'Project A',
              path: '/repo/a',
              createdAt: DateTime.fromMillisecondsSinceEpoch(0),
            ),
            projects: <Project>[
              Project(
                id: 'proj_a',
                name: 'Project A',
                path: '/repo/a',
                createdAt: DateTime.fromMillisecondsSinceEpoch(0),
              ),
              Project(
                id: 'proj_b',
                name: 'Project B',
                path: '/repo/b',
                createdAt: DateTime.fromMillisecondsSinceEpoch(1),
              ),
            ],
          ),
          localDataSource: scopedLocal,
        );
        final scopedProvider = ChatProvider(
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
          projectProvider: scopedProjectProvider,
          localDataSource: scopedLocal,
        );
        addTearDown(scopedProvider.dispose);

        appRepository.providersResult = Right(
          ProvidersResponse(
            providers: <Provider>[
              Provider(
                id: 'prov_a',
                name: 'Provider A',
                env: const <String>[],
                models: <String, Model>{'mod_a': testModel('mod_a')},
              ),
            ],
            defaultModels: const <String, String>{'prov_a': 'mod_a'},
            connected: const <String>['prov_a'],
          ),
        );

        await scopedProjectProvider.initializeProject();
        await scopedProvider.initializeProviders();
        expect(scopedProvider.providers, isNotEmpty);

        appRepository.providersResult = Left(NetworkFailure('refresh failed'));

        await scopedProjectProvider.switchProject('proj_b');
        await scopedProvider.onProjectScopeChanged(waitForRevalidation: false);
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(scopedProvider.providers, isNotEmpty);
        expect(scopedProvider.providers.single.id, 'prov_a');
        expect(
          scopedProvider.providersRefreshState,
          ChatProvidersRefreshState.ready,
        );

        await scopedProvider.initializeProviders();
      },
    );

    test('currentThreadPermissionRequests returns identical cached list on '
        'repeated access without mutations', () async {
      chatRepository.pendingPermissions = const <ChatPermissionRequest>[
        ChatPermissionRequest(
          id: 'perm_cache_1',
          sessionId: 'ses_1',
          permission: 'edit',
          patterns: <String>['lib/**'],
          always: <String>[],
          metadata: <String, dynamic>{},
        ),
      ];
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

      final first = provider.currentThreadPermissionRequests;
      final second = provider.currentThreadPermissionRequests;
      expect(identical(first, second), isTrue);
    });

    test(
      'currentThreadPermissionRequests cache invalidates on permission event',
      () async {
        chatRepository.pendingPermissions = const <ChatPermissionRequest>[
          ChatPermissionRequest(
            id: 'perm_inv_1',
            sessionId: 'ses_1',
            permission: 'edit',
            patterns: <String>['lib/**'],
            always: <String>[],
            metadata: <String, dynamic>{},
          ),
        ];
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

        final before = provider.currentThreadPermissionRequests;
        expect(before.map((item) => item.id), <String>['perm_inv_1']);

        // Respond to the permission request (removes it from pending map).
        await provider.respondPermissionRequest(
          requestId: 'perm_inv_1',
          reply: 'once',
        );

        final after = provider.currentThreadPermissionRequests;
        expect(identical(before, after), isFalse);
        expect(after, isEmpty);
      },
    );

    test(
      'currentThreadPermissionRequests cache invalidates on session switch',
      () async {
        chatRepository.sessions.add(
          ChatSession(
            id: 'ses_2',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(500),
            title: 'Session 2',
          ),
        );
        chatRepository.pendingPermissions = const <ChatPermissionRequest>[
          ChatPermissionRequest(
            id: 'perm_sw_1',
            sessionId: 'ses_1',
            permission: 'edit',
            patterns: <String>['lib/**'],
            always: <String>[],
            metadata: <String, dynamic>{},
          ),
        ];
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
        await provider.selectSession(
          provider.sessions.where((item) => item.id == 'ses_1').first,
        );

        final beforeSwitch = provider.currentThreadPermissionRequests;
        expect(beforeSwitch.map((item) => item.id), <String>['perm_sw_1']);

        // Switch to a session that has no pending permissions.
        await provider.selectSession(
          provider.sessions.where((item) => item.id == 'ses_2').first,
        );

        final afterSwitch = provider.currentThreadPermissionRequests;
        expect(identical(beforeSwitch, afterSwitch), isFalse);
        expect(afterSwitch, isEmpty);
      },
    );
  });
}
