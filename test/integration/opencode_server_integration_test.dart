import 'package:codewalk/core/errors/exceptions.dart';
import 'package:codewalk/core/errors/failures.dart';
import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/data/datasources/app_remote_datasource.dart';
import 'package:codewalk/data/datasources/chat_remote_datasource.dart';
import 'package:codewalk/data/datasources/project_remote_datasource.dart';
import 'package:codewalk/data/models/chat_session_model.dart';
import 'package:codewalk/data/repositories/app_repository_impl.dart';
import 'package:codewalk/data/repositories/chat_repository_impl.dart';
import 'package:codewalk/domain/entities/chat_session.dart';
import 'package:codewalk/domain/entities/project.dart';
import 'package:codewalk/domain/usecases/check_connection.dart';
import 'package:codewalk/domain/usecases/create_chat_session.dart';
import 'package:codewalk/domain/usecases/delete_chat_session.dart';
import 'package:codewalk/domain/usecases/fork_chat_session.dart';
import 'package:codewalk/domain/usecases/get_agents.dart';
import 'package:codewalk/domain/usecases/get_app_info.dart';
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
import 'package:codewalk/presentation/providers/app_provider.dart';
import 'package:codewalk/presentation/providers/chat_provider.dart';
import 'package:codewalk/presentation/providers/project_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/mock_opencode_server.dart';

@Tags(<String>['integration', 'slow'])
void main() {
  group('integration with controllable mock OpenCode server', () {
    late MockOpenCodeServer server;

    setUp(() async {
      server = MockOpenCodeServer();
      await server.start();
    });

    tearDown(() async {
      await server.close();
    });

    test(
      'AppRepository reads /path, /provider and /agent successfully',
      () async {
        final dioClient = DioClient();
        dioClient.updateBaseUrl(server.baseUrl);

        final repository = AppRepositoryImpl(
          remoteDataSource: AppRemoteDataSourceImpl(dio: dioClient.dio),
          localDataSource: InMemoryAppLocalDataSource(),
          dioClient: dioClient,
        );

        final appInfoResult = await repository.getAppInfo();
        final providersResult = await repository.getProviders();
        final agentsResult = await repository.getAgents();

        expect(appInfoResult.isRight(), isTrue);
        expect(providersResult.isRight(), isTrue);
        expect(agentsResult.isRight(), isTrue);

        appInfoResult.fold((_) => fail('expected app info'), (appInfo) {
          expect(appInfo.path.root, '/workspace/project');
          expect(appInfo.path.cwd, '/workspace/project');
        });

        providersResult.fold((_) => fail('expected providers'), (providers) {
          expect(providers.providers, hasLength(1));
          expect(providers.defaultModels['mock-provider'], 'mock-model');
        });

        agentsResult.fold((_) => fail('expected agents'), (agents) {
          expect(agents.any((agent) => agent.name == 'build'), isTrue);
          expect(agents.any((agent) => agent.name == 'plan'), isTrue);
        });
      },
    );

    test(
      'AppRemoteDataSource sends workspace for scoped discovery calls',
      () async {
        final remote = AppRemoteDataSourceImpl(
          dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
        );

        await remote.getProviders(directory: '/workspace/project');
        await remote.getAgents(directory: '/workspace/project');
        await remote.getConfig(directory: '/workspace/project');

        expect(
          server.lastProviderQueryParameters?['directory'],
          '/workspace/project',
        );
        expect(
          server.lastProviderQueryParameters?['workspace'],
          '/workspace/project',
        );
        expect(
          server.lastAgentQueryParameters?['directory'],
          '/workspace/project',
        );
        expect(
          server.lastAgentQueryParameters?['workspace'],
          '/workspace/project',
        );
        expect(
          server.lastConfigQueryParameters?['directory'],
          '/workspace/project',
        );
        expect(
          server.lastConfigQueryParameters?['workspace'],
          '/workspace/project',
        );
      },
    );

    test('AppRemoteDataSource parses grouped agent payload shapes', () async {
      server.customAgentResponsePayload = <String, dynamic>{
        'primary': <Map<String, dynamic>>[
          <String, dynamic>{'name': 'build', 'hidden': false, 'native': false},
        ],
        'subagent': <Map<String, dynamic>>[
          <String, dynamic>{'name': 'review', 'hidden': false, 'native': true},
        ],
      };

      final remote = AppRemoteDataSourceImpl(
        dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
      );

      final agents = await remote.getAgents(directory: '/workspace/project');

      expect(agents.map((agent) => agent.name), <String>['build', 'review']);
      expect(agents.first.mode, 'primary');
      expect(agents.last.mode, 'subagent');
    });

    test(
      'AppRemoteDataSource falls back when scoped agent query returns empty',
      () async {
        server.returnEmptyAgentsWhenScoped = true;

        final remote = AppRemoteDataSourceImpl(
          dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
        );

        final agents = await remote.getAgents(directory: '/workspace/project');

        expect(
          agents.map((agent) => agent.name),
          containsAll(<String>['build', 'plan']),
        );
        expect(server.lastAgentQueryParameters, isEmpty);
      },
    );

    test(
      'AppRemoteDataSource falls back when scoped discovery queries fail',
      () async {
        server.failProviderWhenScoped = true;
        server.failAgentWhenScoped = true;
        server.failConfigWhenScoped = true;

        final remote = AppRemoteDataSourceImpl(
          dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
        );

        final providers = await remote.getProviders(
          directory: '/workspace/project',
        );
        final agents = await remote.getAgents(directory: '/workspace/project');
        final config = await remote.getConfig(directory: '/workspace/project');

        expect(providers.providers, hasLength(1));
        expect(
          agents.map((agent) => agent.name),
          containsAll(<String>['build', 'plan']),
        );
        expect(config['default_agent'], 'build');
        expect(server.lastProviderQueryParameters, isEmpty);
        expect(server.lastAgentQueryParameters, isEmpty);
        expect(server.lastConfigQueryParameters, isEmpty);
      },
    );

    test(
      'ProjectRemoteDataSource supports project context and worktrees',
      () async {
        final remote = ProjectRemoteDataSourceImpl(
          dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
        );

        final projects = await remote.getProjects();
        expect(projects.projects.length, 2);

        final current = await remote.getCurrentProject(
          directory: '/workspace/alt',
        );
        expect(current.path, '/workspace/alt');

        final worktreesBefore = await remote.getWorktrees(
          directory: '/workspace',
        );
        expect(worktreesBefore, isNotEmpty);

        final created = await remote.createWorktree(
          'feature-15',
          directory: '/workspace/project',
        );
        expect(created.directory, '/workspace/project/feature-15');

        await remote.resetWorktree(created.id, directory: '/workspace/project');
        await remote.deleteWorktree(
          created.id,
          directory: '/workspace/project',
        );

        final directories = await remote.findFiles(
          query: 'project',
          type: 'directory',
          limit: 10,
        );
        expect(directories, isNotEmpty);
        expect(
          directories.every((item) => item.type.name == 'directory'),
          isTrue,
        );

        final contentMatches = await remote.searchFileContents(
          pattern: 'content',
          limit: 10,
        );
        expect(contentMatches, hasLength(1));
        expect(contentMatches.single.path, '/workspace/project/README.md');
        expect(contentMatches.single.lineNumber, 12);
        expect(
          contentMatches.single.lineContent,
          'CodeWalk quick open content search',
        );

        final symbols = await remote.findSymbols(query: 'controller', limit: 5);
        expect(symbols, hasLength(1));
        expect(symbols.single.name, 'CodeWalkController');
        expect(
          symbols.single.path,
          '/workspace/project/lib/codewalk_controller.dart',
        );
      },
    );

    test('ChatRemoteDataSource subscribes to /global/event stream', () async {
      server.scriptedGlobalEvents = <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'session.updated',
          'properties': <String, dynamic>{'directory': '/workspace/project'},
        },
      ];
      final remote = ChatRemoteDataSourceImpl(
        dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
      );

      final events = await remote.subscribeGlobalEvents().take(1).toList();
      expect(events.single.type, 'session.updated');
      expect(events.single.properties['directory'], '/workspace/project');
    });

    test(
      'ChatRemoteDataSource performs session CRUD against mock server',
      () async {
        final remote = ChatRemoteDataSourceImpl(
          dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
        );

        final before = await remote.getSessions();
        expect(before, hasLength(1));

        final created = await remote.createSession(
          'default',
          const SessionCreateInputModel(title: 'Created via integration test'),
        );

        final afterCreate = await remote.getSessions();
        expect(afterCreate.map((s) => s.id), contains(created.id));

        await remote.deleteSession('default', created.id);
        final afterDelete = await remote.getSessions();
        expect(afterDelete.map((s) => s.id), isNot(contains(created.id)));
      },
    );

    test(
      'ChatRemoteDataSource supports lifecycle endpoints (status/todo/diff/share/fork/archive)',
      () async {
        server.sessionStatusById = <String, Map<String, dynamic>>{
          'ses_1': <String, dynamic>{'type': 'busy'},
        };
        server.sessionTodoById['ses_1'] = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'todo_1',
            'content': 'Implement lifecycle',
            'status': 'in_progress',
            'priority': 'high',
          },
        ];
        server.sessionDiffById['ses_1'] = <Map<String, dynamic>>[
          <String, dynamic>{
            'file': 'lib/main.dart',
            'before': 'old',
            'after': 'new',
            'additions': 8,
            'deletions': 2,
            'status': 'modified',
          },
        ];

        final remote = ChatRemoteDataSourceImpl(
          dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
        );

        final renamed = await remote.updateSession(
          'default',
          'ses_1',
          const SessionUpdateInputModel(title: 'Renamed Session'),
        );
        expect(renamed.title, 'Renamed Session');

        final archived = await remote.updateSession(
          'default',
          'ses_1',
          const SessionUpdateInputModel(archivedAtEpochMs: 1739079999999),
        );
        expect(archived.time.archived, 1739079999999);

        final unarchived = await remote.updateSession(
          'default',
          'ses_1',
          const SessionUpdateInputModel(archivedAtEpochMs: 0),
        );
        expect(unarchived.time.archived, isNull);

        final shared = await remote.shareSession('default', 'ses_1');
        expect(shared.share?.url, isNotNull);

        final unshared = await remote.unshareSession('default', 'ses_1');
        expect(unshared.share, isNull);

        final forked = await remote.forkSession('default', 'ses_1');
        expect(forked.parentId, 'ses_1');

        final children = await remote.getSessionChildren('default', 'ses_1');
        expect(children.map((item) => item.id), contains(forked.id));

        final todo = await remote.getSessionTodo('default', 'ses_1');
        expect(todo.single.id, 'todo_1');

        final diff = await remote.getSessionDiff('default', 'ses_1');
        expect(diff.single.file, 'lib/main.dart');

        final status = await remote.getSessionStatus();
        expect(status['ses_1']?.type, 'busy');
      },
    );

    test(
      'ChatRemoteDataSource prefers prompt_async and consumes SSE update',
      () async {
        server.streamMessageUpdates = true;

        final remote = ChatRemoteDataSourceImpl(
          dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
        );

        final messages = await remote
            .sendMessage(
              'default',
              'ses_1',
              const ChatInputModel(
                messageId: 'msg_user_1',
                providerId: 'mock-provider',
                modelId: 'mock-model',
                parts: <ChatInputPartModel>[
                  ChatInputPartModel(type: 'text', text: 'hello integration'),
                ],
              ),
            )
            .toList();

        expect(messages, isNotEmpty);
        expect((messages.last.parts.single).text, 'done');
        expect(messages.last.completedTime, isNotNull);
        expect(server.promptAsyncRequestCount, 1);
        expect(server.messageRequestCount, 0);
      },
    );

    test(
      'ChatRemoteDataSource requests bounded message-list tails in prompt_async flow',
      () async {
        server.streamMessageUpdates = true;

        final remote = ChatRemoteDataSourceImpl(
          dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
        );

        final messages = await remote
            .sendMessage(
              'default',
              'ses_1',
              const ChatInputModel(
                messageId: 'msg_user_tail_limit',
                providerId: 'mock-provider',
                modelId: 'mock-model',
                parts: <ChatInputPartModel>[
                  ChatInputPartModel(type: 'text', text: 'tail limit please'),
                ],
              ),
            )
            .toList();

        expect(messages, isNotEmpty);
        expect(server.sessionMessageListRequestCount, greaterThan(0));
        expect(server.lastSessionMessageListLimit, '120');
      },
    );

    test(
      'ChatRemoteDataSource does not complete a new send with stale previous assistant message',
      () async {
        server.preserveMessageHistoryOnPromptAsync = true;

        final remote = ChatRemoteDataSourceImpl(
          dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
        );

        final firstTurnMessages = await remote
            .sendMessage(
              'default',
              'ses_1',
              const ChatInputModel(
                messageId: 'msg_user_first_turn',
                providerId: 'mock-provider',
                modelId: 'mock-model',
                parts: <ChatInputPartModel>[
                  ChatInputPartModel(type: 'text', text: 'first turn'),
                ],
              ),
            )
            .toList();

        final firstAssistant = firstTurnMessages.last;
        expect(firstAssistant.completedTime, isNotNull);

        server.forceEmptySessionMessageListResponses = 1;
        server.promptAsyncSeedDelayMs = 1500;

        final secondTurnMessages = await remote
            .sendMessage(
              'default',
              'ses_1',
              const ChatInputModel(
                messageId: 'msg_user_second_turn',
                providerId: 'mock-provider',
                modelId: 'mock-model',
                parts: <ChatInputPartModel>[
                  ChatInputPartModel(type: 'text', text: 'second turn'),
                ],
              ),
            )
            .toList();

        final secondAssistant = secondTurnMessages.last;
        expect(secondAssistant.id, isNot(firstAssistant.id));
        expect(secondAssistant.completedTime, isNotNull);
        expect(
          secondAssistant.completedTime!.millisecondsSinceEpoch,
          greaterThan(firstAssistant.completedTime!.millisecondsSinceEpoch),
        );
        expect(server.promptAsyncRequestCount, 2);
      },
    );

    test(
      'ChatRemoteDataSource keeps waiting when idle appears before fresh assistant candidate',
      () async {
        server.preserveMessageHistoryOnPromptAsync = true;

        final remote = ChatRemoteDataSourceImpl(
          dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
        );

        final firstTurnMessages = await remote
            .sendMessage(
              'default',
              'ses_1',
              const ChatInputModel(
                messageId: 'msg_user_first_guarded_turn',
                providerId: 'mock-provider',
                modelId: 'mock-model',
                parts: <ChatInputPartModel>[
                  ChatInputPartModel(type: 'text', text: 'first guarded turn'),
                ],
              ),
            )
            .toList();

        final firstAssistant = firstTurnMessages.last;
        expect(firstAssistant.completedTime, isNotNull);

        server.simulateBusyThenIdleOnPromptAsync = true;
        server.promptAsyncBusyDurationMs = 200;
        server.promptAsyncSeedDelayMs = 2200;
        server.forceEmptySessionMessageListResponses = 3;

        final secondTurnMessages = await remote
            .sendMessage(
              'default',
              'ses_1',
              const ChatInputModel(
                messageId: 'msg_user_second_guarded_turn',
                providerId: 'mock-provider',
                modelId: 'mock-model',
                parts: <ChatInputPartModel>[
                  ChatInputPartModel(type: 'text', text: 'second guarded turn'),
                ],
              ),
            )
            .toList();

        final secondAssistant = secondTurnMessages.last;
        expect(secondAssistant.id, isNot(firstAssistant.id));
        expect(secondAssistant.completedTime, isNotNull);
        expect(
          secondAssistant.completedTime!.millisecondsSinceEpoch,
          greaterThan(firstAssistant.completedTime!.millisecondsSinceEpoch),
        );
        expect(server.promptAsyncRequestCount, 2);
      },
    );

    test(
      'ChatRemoteDataSource sendMessage forwards directory to event and message fetch',
      () async {
        server.streamMessageUpdates = true;
        server.requiredEventDirectory = '/workspace/project';
        server.requiredMessageDirectory = '/workspace/project';

        final remote = ChatRemoteDataSourceImpl(
          dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
        );

        final messages = await remote
            .sendMessage(
              'default',
              'ses_1',
              const ChatInputModel(
                messageId: 'msg_user_dir_1',
                providerId: 'mock-provider',
                modelId: 'mock-model',
                parts: <ChatInputPartModel>[
                  ChatInputPartModel(type: 'text', text: 'hello directory'),
                ],
              ),
              directory: '/workspace/project',
            )
            .toList();

        expect(messages, isNotEmpty);
        expect((messages.last.parts.single).text, 'done');
        expect(messages.last.completedTime, isNotNull);
        expect(server.promptAsyncRequestCount, 1);
        expect(server.messageRequestCount, 0);
      },
    );

    test(
      'ChatRemoteDataSource fails fast when prompt_async is unavailable',
      () async {
        server.promptAsyncSupported = false;

        final remote = ChatRemoteDataSourceImpl(
          dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
        );

        await expectLater(
          () => remote
              .sendMessage(
                'default',
                'ses_1',
                const ChatInputModel(
                  messageId: 'msg_user_fallback_1',
                  providerId: 'mock-provider',
                  modelId: 'mock-model',
                  parts: <ChatInputPartModel>[
                    ChatInputPartModel(type: 'text', text: 'fallback please'),
                  ],
                ),
              )
              .toList(),
          throwsA(isA<NotFoundException>()),
        );

        expect(server.promptAsyncRequestCount, 1);
        expect(server.messageRequestCount, 0);
      },
    );

    test(
      'ChatRemoteDataSource surfaces prompt_async 409 as a conflict error',
      () async {
        server.simulate409OnPromptAsync = true;

        final remote = ChatRemoteDataSourceImpl(
          dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
        );

        await expectLater(
          () => remote
              .sendMessage(
                'default',
                'ses_1',
                const ChatInputModel(
                  messageId: 'msg_user_busy_409',
                  providerId: 'mock-provider',
                  modelId: 'mock-model',
                  parts: <ChatInputPartModel>[
                    ChatInputPartModel(type: 'text', text: 'busy please'),
                  ],
                ),
              )
              .toList(),
          throwsA(
            isA<ConflictException>().having(
              (error) => error.message,
              'message',
              'Session is busy processing another request.',
            ),
          ),
        );
      },
    );

    test(
      'ChatRemoteDataSource surfaces structured validation payloads',
      () async {
        server.sendMessageValidationError = true;
        server.simulateStructuredValidationError = true;

        final remote = ChatRemoteDataSourceImpl(
          dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
        );

        await expectLater(
          () => remote
              .sendMessage(
                'default',
                'ses_1',
                const ChatInputModel(
                  messageId: 'msg_user_validation_400',
                  providerId: 'mock-provider',
                  modelId: 'mock-model',
                  parts: <ChatInputPartModel>[
                    ChatInputPartModel(type: 'text', text: 'invalid please'),
                  ],
                ),
              )
              .toList(),
          throwsA(
            isA<ValidationException>().having(
              (error) => error.message,
              'message',
              'messageId: Cannot be empty',
            ),
          ),
        );
      },
    );

    test('ChatRemoteDataSource preserves typed upstream error details', () async {
      server.promptAsyncCustomErrorStatusCode = 401;
      server.promptAsyncCustomErrorPayload = <String, dynamic>{
        'error': <String, dynamic>{
          'name': 'ProviderAuthError',
          'code': 'AUTH_FAILED',
          'message': 'Reconnect the provider and try again.',
          'details': <String, dynamic>{'provider': 'mock-provider'},
        },
      };

      final remote = ChatRemoteDataSourceImpl(
        dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
      );

      await expectLater(
        () => remote
            .sendMessage(
              'default',
              'ses_1',
              const ChatInputModel(
                messageId: 'msg_user_auth_401',
                providerId: 'mock-provider',
                modelId: 'mock-model',
                parts: <ChatInputPartModel>[
                  ChatInputPartModel(type: 'text', text: 'auth please'),
                ],
              ),
            )
            .toList(),
        throwsA(
          isA<ServerException>().having(
            (error) => error.message,
            'message',
            'ProviderAuthError [AUTH_FAILED]: Reconnect the provider and try again. (provider=mock-provider)',
          ),
        ),
      );
    });

    test('ChatRemoteDataSource includes variant in outbound payload', () async {
      final remote = ChatRemoteDataSourceImpl(
        dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
      );

      await remote
          .sendMessage(
            'default',
            'ses_1',
            const ChatInputModel(
              messageId: 'msg_user_variant',
              providerId: 'mock-provider',
              modelId: 'mock-model',
              variant: 'high',
              parts: <ChatInputPartModel>[
                ChatInputPartModel(type: 'text', text: 'variant please'),
              ],
            ),
          )
          .first;

      expect(server.lastSendMessagePayload, isNotNull);
      expect(server.lastSendMessagePayload?['variant'], 'high');
    });

    test(
      'ChatRemoteDataSource short-circuits prompt_async when server returns completed payload',
      () async {
        server.promptAsyncReturnsCompletePayload = true;

        final remote = ChatRemoteDataSourceImpl(
          dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
        );

        final messages = await remote
            .sendMessage(
              'default',
              'ses_1',
              const ChatInputModel(
                messageId: 'msg_user_prompt_async_200',
                providerId: 'mock-provider',
                modelId: 'mock-model',
                parts: <ChatInputPartModel>[
                  ChatInputPartModel(type: 'text', text: 'complete directly'),
                ],
              ),
            )
            .toList();

        expect(messages, hasLength(1));
        expect(messages.single.completedTime, isNotNull);
        expect((messages.single.parts.single).text, 'done');
        expect(server.promptAsyncRequestCount, 1);
        expect(server.messageDetailRequestCount, 0);
      },
    );

    test('ChatRemoteDataSource includes agent in outbound payload', () async {
      final remote = ChatRemoteDataSourceImpl(
        dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
      );

      await remote
          .sendMessage(
            'default',
            'ses_1',
            const ChatInputModel(
              messageId: 'msg_user_agent',
              providerId: 'mock-provider',
              modelId: 'mock-model',
              mode: 'plan',
              parts: <ChatInputPartModel>[
                ChatInputPartModel(type: 'text', text: 'agent please'),
              ],
            ),
          )
          .first;

      expect(server.lastSendMessagePayload, isNotNull);
      expect(server.lastSendMessagePayload?['agent'], 'plan');
    });

    test(
      'ChatRemoteDataSource subscribes and reconnects on SSE closure',
      () async {
        server.eventCloseDelayMs = 40;
        server.scriptedEventsByConnection = <List<Map<String, dynamic>>>[
          <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'session.status',
              'properties': <String, dynamic>{
                'sessionID': 'ses_1',
                'status': <String, dynamic>{'type': 'busy'},
              },
            },
          ],
          <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'question.asked',
              'properties': <String, dynamic>{
                'id': 'q_1',
                'sessionID': 'ses_1',
                'questions': <dynamic>[
                  <String, dynamic>{
                    'question': 'Proceed?',
                    'header': 'Confirm',
                    'options': <dynamic>[
                      <String, dynamic>{
                        'label': 'Yes',
                        'description': 'continue',
                      },
                    ],
                  },
                ],
              },
            },
          ],
        ];

        final remote = ChatRemoteDataSourceImpl(
          dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
        );

        final collected = await remote
            .subscribeEvents()
            .map((event) => event.type)
            .where((type) => type != 'server.connected')
            .take(2)
            .toList();

        expect(collected, <String>['session.status', 'question.asked']);
        expect(server.eventConnectionCount, greaterThanOrEqualTo(2));
      },
    );

    test(
      'ChatRemoteDataSource lists and responds to permission/question prompts',
      () async {
        server.pendingPermissions = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'perm_1',
            'sessionID': 'ses_1',
            'permission': 'edit',
            'patterns': <String>['lib/**'],
            'always': <String>[],
            'metadata': <String, dynamic>{},
          },
        ];
        server.pendingQuestions = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'q_1',
            'sessionID': 'ses_1',
            'questions': <dynamic>[
              <String, dynamic>{
                'question': 'Continue?',
                'header': 'Confirm',
                'options': <dynamic>[
                  <String, dynamic>{
                    'label': 'Yes',
                    'description': 'Continue execution',
                  },
                ],
              },
            ],
          },
        ];

        final remote = ChatRemoteDataSourceImpl(
          dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
        );

        final permissions = await remote.listPermissions();
        final questions = await remote.listQuestions();
        expect(permissions.single.id, 'perm_1');
        expect(questions.single.id, 'q_1');

        await remote.replyPermission(
          sessionId: 'ses_1',
          requestId: 'perm_1',
          reply: 'once',
        );
        expect(server.lastPermissionReplyRequestId, 'perm_1');
        expect(server.lastPermissionReplySessionId, 'ses_1');
        expect(server.lastPermissionReplyPayload?['response'], 'once');
        expect(
          server.lastPermissionReplyPayload?.containsKey('remember'),
          isFalse,
        );

        await remote.replyQuestion(
          sessionId: 'ses_1',
          requestId: 'q_1',
          answers: const <List<String>>[
            <String>['Yes'],
          ],
        );
        expect(server.lastQuestionReplyRequestId, 'q_1');
        expect(server.lastQuestionReplyQueryParameters?['sessionID'], 'ses_1');
        expect(
          server.lastQuestionReplyPayload?['answers'],
          const <List<String>>[
            <String>['Yes'],
          ],
        );
      },
    );

    test(
      'ChatRemoteDataSource omits remember for reject permission replies',
      () async {
        server.pendingPermissions = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'perm_reject_1',
            'sessionID': 'ses_1',
            'permission': 'edit',
            'patterns': <String>['lib/**'],
            'always': <String>[],
            'metadata': <String, dynamic>{},
          },
        ];

        final remote = ChatRemoteDataSourceImpl(
          dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
        );

        await remote.replyPermission(
          sessionId: 'ses_1',
          requestId: 'perm_reject_1',
          reply: 'reject',
        );

        expect(server.lastPermissionReplyRequestId, 'perm_reject_1');
        expect(server.lastPermissionReplyPayload?['response'], 'reject');
        expect(
          server.lastPermissionReplyPayload?.containsKey('remember'),
          isFalse,
        );
      },
    );

    test(
      'ChatRemoteDataSource falls back to legacy permission reply route on 405',
      () async {
        server.pendingPermissions = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'perm_legacy_1',
            'sessionID': 'ses_1',
            'permission': 'edit',
            'patterns': <String>['lib/**'],
            'always': <String>[],
            'metadata': <String, dynamic>{},
          },
        ];
        server.sessionPermissionRouteStatusCode = 405;

        final remote = ChatRemoteDataSourceImpl(
          dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
        );

        await remote.replyPermission(
          sessionId: 'ses_1',
          requestId: 'perm_legacy_1',
          reply: 'always',
        );

        expect(server.lastPermissionReplyRequestId, 'perm_legacy_1');
        expect(server.lastPermissionReplySessionId, isNull);
        expect(server.lastPermissionReplyPayload?['reply'], 'always');
        expect(server.lastPermissionReplyPayload?['remember'], isTrue);
      },
    );

    test(
      'ChatRemoteDataSource includes remember for always permission replies',
      () async {
        server.pendingPermissions = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'perm_remember_1',
            'sessionID': 'ses_1',
            'permission': 'edit',
            'patterns': <String>['lib/**'],
            'always': <String>[],
            'metadata': <String, dynamic>{},
          },
        ];

        final remote = ChatRemoteDataSourceImpl(
          dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
        );

        await remote.replyPermission(
          sessionId: 'ses_1',
          requestId: 'perm_remember_1',
          reply: 'always',
        );

        expect(server.lastPermissionReplyRequestId, 'perm_remember_1');
        expect(server.lastPermissionReplySessionId, 'ses_1');
        expect(server.lastPermissionReplyPayload?['response'], 'always');
        expect(server.lastPermissionReplyPayload?['remember'], isTrue);
      },
    );

    test('ChatRemoteDataSource rejects pending question requests', () async {
      server.pendingQuestions = <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'q_reject_1',
          'sessionID': 'ses_1',
          'questions': <dynamic>[
            <String, dynamic>{
              'question': 'Stop execution?',
              'header': 'Confirm',
              'options': <dynamic>[
                <String, dynamic>{
                  'label': 'Stop',
                  'description': 'Reject request',
                },
              ],
            },
          ],
        },
      ];

      final remote = ChatRemoteDataSourceImpl(
        dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
      );

      final before = await remote.listQuestions();
      expect(before.single.id, 'q_reject_1');

      await remote.rejectQuestion(sessionId: 'ses_1', requestId: 'q_reject_1');
      expect(server.lastQuestionRejectRequestId, 'q_reject_1');
      expect(server.lastQuestionRejectQueryParameters?['sessionID'], 'ses_1');

      final after = await remote.listQuestions();
      expect(after, isEmpty);
    });

    test('ChatRepository maps send 400 error to ValidationFailure', () async {
      server.sendMessageValidationError = true;

      final repository = ChatRepositoryImpl(
        remoteDataSource: ChatRemoteDataSourceImpl(
          dio: Dio(BaseOptions(baseUrl: server.baseUrl)),
        ),
      );

      final streamValues = await repository
          .sendMessage(
            'default',
            'ses_1',
            const ChatInput(
              messageId: 'msg_user_2',
              providerId: 'mock-provider',
              modelId: 'mock-model',
              parts: <ChatInputPart>[TextInputPart(text: 'trigger 400')],
            ),
          )
          .toList();

      expect(streamValues, hasLength(1));
      streamValues.single.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('expected failure'),
      );
    });

    test(
      'switching active server isolates session cache by server id',
      () async {
        final serverB = MockOpenCodeServer(
          initialSessionTitle: 'Second Server Session',
        );
        await serverB.start();
        addTearDown(serverB.close);

        final localDataSource = InMemoryAppLocalDataSource();
        final dioClient = DioClient();
        final appRepository = AppRepositoryImpl(
          remoteDataSource: AppRemoteDataSourceImpl(dio: dioClient.dio),
          localDataSource: localDataSource,
          dioClient: dioClient,
        );
        final chatRepository = ChatRepositoryImpl(
          remoteDataSource: ChatRemoteDataSourceImpl(dio: dioClient.dio),
        );
        final projectProvider = ProjectProvider(
          projectRepository: FakeProjectRepository(
            currentProject: Project(
              id: 'proj_workspace',
              name: 'Workspace',
              path: '/workspace/project',
              createdAt: DateTime.fromMillisecondsSinceEpoch(0),
            ),
            projects: <Project>[
              Project(
                id: 'proj_workspace',
                name: 'Workspace',
                path: '/workspace/project',
                createdAt: DateTime.fromMillisecondsSinceEpoch(0),
              ),
            ],
          ),
          localDataSource: localDataSource,
        );

        final appProvider = AppProvider(
          getAppInfo: GetAppInfo(appRepository),
          checkConnection: CheckConnection(appRepository),
          localDataSource: localDataSource,
          dioClient: dioClient,
          enableHealthPolling: false,
        );
        await appProvider.initialize();
        await appProvider.addServerProfile(
          url: server.baseUrl,
          label: 'Server A',
          setAsActive: true,
        );
        await appProvider.addServerProfile(
          url: serverB.baseUrl,
          label: 'Server B',
        );

        final chatProvider = ChatProvider(
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
          projectProvider: projectProvider,
          localDataSource: localDataSource,
        );
        await projectProvider.initializeProject();

        await chatProvider.initializeProviders();
        await chatProvider.loadSessions();
        expect(chatProvider.sessions.first.title, 'Initial Session');

        final serverBId = appProvider.serverProfiles
            .where((p) => p.label == 'Server B')
            .first
            .id;
        final switched = await appProvider.setActiveServer(serverBId);
        expect(switched, isTrue);
        await chatProvider.onServerScopeChanged();
        expect(chatProvider.sessions.first.title, 'Second Server Session');

        final serverAId = appProvider.serverProfiles
            .where((p) => p.label == 'Server A')
            .first
            .id;
        await appProvider.setActiveServer(serverAId);
        await chatProvider.onServerScopeChanged();
        expect(chatProvider.sessions.first.title, 'Initial Session');

        final scopeId =
            projectProvider.currentProject?.path ??
            projectProvider.currentProjectId;
        final keyA = 'cached_sessions::$serverAId::$scopeId';
        final keyB = 'cached_sessions::$serverBId::$scopeId';
        expect(localDataSource.scopedStrings[keyA], isNotNull);
        expect(localDataSource.scopedStrings[keyB], isNotNull);
        expect(
          localDataSource.scopedStrings[keyA],
          isNot(equals(localDataSource.scopedStrings[keyB])),
        );
      },
    );
  });
}
