import 'dart:async';
import 'dart:convert';

import 'package:codewalk/core/config/feature_flags.dart';
import 'package:codewalk/core/di/injection_container.dart' as di;
import 'package:codewalk/core/errors/failures.dart';
import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/data/datasources/app_local_datasource.dart';
import 'package:codewalk/data/datasources/quota_remote_datasource.dart';
import 'package:codewalk/domain/entities/agent.dart';
import 'package:codewalk/domain/entities/chat_message.dart';
import 'package:codewalk/domain/entities/chat_realtime.dart';
import 'package:codewalk/domain/entities/chat_session.dart';
import 'package:codewalk/domain/entities/file_node.dart';
import 'package:codewalk/domain/entities/project.dart';
import 'package:codewalk/domain/entities/provider.dart';
import 'package:codewalk/domain/entities/quota.dart';
import 'package:codewalk/domain/usecases/abort_chat_session.dart';
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
import 'package:codewalk/domain/usecases/revert_chat_message.dart';
import 'package:codewalk/domain/usecases/send_chat_message.dart';
import 'package:codewalk/domain/usecases/share_chat_session.dart';
import 'package:codewalk/domain/usecases/unrevert_chat_messages.dart';
import 'package:codewalk/domain/usecases/unshare_chat_session.dart';
import 'package:codewalk/domain/usecases/update_chat_session.dart';
import 'package:codewalk/domain/usecases/watch_chat_events.dart';
import 'package:codewalk/domain/usecases/watch_global_chat_events.dart';
import 'package:codewalk/presentation/pages/chat_page.dart';
import 'package:codewalk/presentation/pages/settings_page.dart';
import 'package:codewalk/presentation/providers/app_provider.dart';
import 'package:codewalk/presentation/providers/chat_provider.dart';
import 'package:codewalk/presentation/providers/project_provider.dart';
import 'package:codewalk/presentation/providers/quota_provider.dart';
import 'package:codewalk/presentation/providers/settings_provider.dart';
import 'package:codewalk/presentation/services/cellular_data_saver_service.dart';
import 'package:codewalk/presentation/services/sound_service.dart';
import 'package:codewalk/presentation/theme/app_theme.dart';
import 'package:codewalk/presentation/utils/session_title_formatter.dart';
import 'package:codewalk/presentation/widgets/chat_skeleton_shimmer.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart' hide Provider;
import 'package:showcaseview/showcaseview.dart';
import 'package:simple_icons/simple_icons.dart';

import '../support/fakes.dart';

class _ConfigurableDelayFakeChatRepository extends FakeChatRepository {
  _ConfigurableDelayFakeChatRepository({required super.sessions});

  Completer<void>? getMessagesGate;

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages(
    String projectId,
    String sessionId, {
    String? directory,
    int? limit,
  }) async {
    final gate = getMessagesGate;
    if (gate != null) {
      await gate.future;
    }
    return super.getMessages(
      projectId,
      sessionId,
      directory: directory,
      limit: limit,
    );
  }
}

class _SlashCommandFallbackDioClient extends DioClient {
  _SlashCommandFallbackDioClient({
    List<dynamic> remoteCommands = const <dynamic>[],
    List<Map<String, dynamic>> projectCommandFiles =
        const <Map<String, dynamic>>[],
  }) : _remoteCommands = remoteCommands,
       _projectCommandFiles = projectCommandFiles,
       super(baseUrl: 'http://localhost') {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/command') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: _remoteCommands,
              ),
            );
            return;
          }

          if (options.path == '/file' &&
              options.queryParameters['path'] == '.opencode/commands') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: _projectCommandFiles,
              ),
            );
            return;
          }

          handler.reject(
            DioException(
              requestOptions: options,
              error: 'Unexpected request in test: ${options.path}',
            ),
          );
        },
      ),
    );
  }

  final List<dynamic> _remoteCommands;
  final List<Map<String, dynamic>> _projectCommandFiles;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatPage responsive shell', () {
    testWidgets('toolbar hides redo until session has redo state', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_1',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Stable Session',
          ),
        ],
      );
      repository.messagesBySession['ses_1'] = <ChatMessage>[
        UserMessage(
          id: 'msg_user_1',
          sessionId: 'ses_1',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_user_1',
              messageId: 'msg_user_1',
              sessionId: 'ses_1',
              text: 'first prompt',
            ),
          ],
        ),
        AssistantMessage(
          id: 'msg_assistant_1',
          sessionId: 'ses_1',
          time: DateTime.fromMillisecondsSinceEpoch(1100),
          completedTime: DateTime.fromMillisecondsSinceEpoch(1200),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_assistant_1',
              messageId: 'msg_assistant_1',
              sessionId: 'ses_1',
              text: 'first reply',
            ),
          ],
        ),
      ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..defaultServerId = 'srv_test'
        ..serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'srv_test',
            'url': 'http://127.0.0.1:4096',
            'label': 'Test Server',
            'basicAuthEnabled': false,
            'basicAuthUsername': '',
            'basicAuthPassword': '',
            'createdAt': 0,
            'updatedAt': 0,
          },
        ]);
      final provider = _buildChatProvider(
        localDataSource: localDataSource,
        chatRepository: repository,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(
        _testApp(
          provider,
          appProvider,
          mediaQueryData: const MediaQueryData(size: Size(500, 900)),
        ),
      );
      await _pumpUiFrames(tester);

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await _pumpUiFrames(tester);

      expect(find.text('first prompt'), findsOneWidget);
      expect(find.text('first reply'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('appbar_redo_button')),
        findsNothing,
      );
    });

    testWidgets(
      'toolbar undo hides reverted tail and restores composer draft',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1400, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final repository = FakeChatRepository(
          sessions: <ChatSession>[
            ChatSession(
              id: 'ses_1',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              title: 'Undo Session',
            ),
          ],
        );
        repository.messagesBySession['ses_1'] = <ChatMessage>[
          UserMessage(
            id: 'msg_user_1',
            sessionId: 'ses_1',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_user_1',
                messageId: 'msg_user_1',
                sessionId: 'ses_1',
                text: 'undo me',
              ),
            ],
          ),
          AssistantMessage(
            id: 'msg_assistant_1',
            sessionId: 'ses_1',
            time: DateTime.fromMillisecondsSinceEpoch(1100),
            completedTime: DateTime.fromMillisecondsSinceEpoch(1200),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_assistant_1',
                messageId: 'msg_assistant_1',
                sessionId: 'ses_1',
                text: 'assistant reply',
              ),
            ],
          ),
        ];

        final localDataSource = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test'
          ..defaultServerId = 'srv_test'
          ..serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'srv_test',
              'url': 'http://127.0.0.1:4096',
              'label': 'Test Server',
              'basicAuthEnabled': false,
              'basicAuthUsername': '',
              'basicAuthPassword': '',
              'createdAt': 0,
              'updatedAt': 0,
            },
          ]);
        final provider = _buildChatProvider(
          localDataSource: localDataSource,
          chatRepository: repository,
        );
        final appProvider = _buildAppProvider(localDataSource: localDataSource);

        await tester.pumpWidget(_testApp(provider, appProvider));
        await tester.pumpAndSettle();

        expect(find.text('undo me'), findsOneWidget);
        expect(find.text('assistant reply'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey<String>('appbar_undo_button')),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('chat_message_widget_msg_user_1')),
          findsNothing,
        );
        expect(
          find.byKey(
            const ValueKey<String>('chat_message_widget_msg_assistant_1'),
          ),
          findsNothing,
        );
        expect(find.byType(TextField), findsWidgets);
        expect(
          tester
              .widget<TextField>(find.byType(TextField).last)
              .controller
              ?.text,
          'undo me',
        );
      },
    );

    testWidgets(
      'undo then send keeps replacement branch visible during stale refresh',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1400, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final sendStream = StreamController<Either<Failure, ChatMessage>>();
        addTearDown(() async {
          await sendStream.close();
        });

        final repository = FakeChatRepository(
          sessions: <ChatSession>[
            ChatSession(
              id: 'ses_1',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              title: 'Branch Session',
            ),
          ],
        );
        repository.messagesBySession['ses_1'] = <ChatMessage>[
          UserMessage(
            id: 'msg_user_1',
            sessionId: 'ses_1',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_user_1',
                messageId: 'msg_user_1',
                sessionId: 'ses_1',
                text: 'first prompt',
              ),
            ],
          ),
          AssistantMessage(
            id: 'msg_assistant_1',
            sessionId: 'ses_1',
            time: DateTime.fromMillisecondsSinceEpoch(1100),
            completedTime: DateTime.fromMillisecondsSinceEpoch(1200),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_assistant_1',
                messageId: 'msg_assistant_1',
                sessionId: 'ses_1',
                text: 'first answer',
              ),
            ],
          ),
          UserMessage(
            id: 'msg_user_2',
            sessionId: 'ses_1',
            time: DateTime.fromMillisecondsSinceEpoch(1300),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_user_2',
                messageId: 'msg_user_2',
                sessionId: 'ses_1',
                text: 'second prompt',
              ),
            ],
          ),
          AssistantMessage(
            id: 'msg_assistant_2',
            sessionId: 'ses_1',
            time: DateTime.fromMillisecondsSinceEpoch(1400),
            completedTime: DateTime.fromMillisecondsSinceEpoch(1500),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_assistant_2',
                messageId: 'msg_assistant_2',
                sessionId: 'ses_1',
                text: 'second answer',
              ),
            ],
          ),
        ];
        repository.sendMessageHandler = (_, _, _, _) => sendStream.stream;

        final localDataSource = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test'
          ..defaultServerId = 'srv_test'
          ..serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'srv_test',
              'url': 'http://127.0.0.1:4096',
              'label': 'Test Server',
              'basicAuthEnabled': false,
              'basicAuthUsername': '',
              'basicAuthPassword': '',
              'createdAt': 0,
              'updatedAt': 0,
            },
          ]);
        final provider = _buildChatProvider(
          localDataSource: localDataSource,
          chatRepository: repository,
        );
        final appProvider = _buildAppProvider(localDataSource: localDataSource);

        await tester.pumpWidget(_testApp(provider, appProvider));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('appbar_undo_button')),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('second answer'), findsNothing);
        expect(
          tester
              .widget<TextField>(find.byType(TextField).last)
              .controller
              ?.text,
          'second prompt',
        );

        await tester.enterText(find.byType(TextField).last, 'branch prompt');
        await tester.pump();
        await tester.tap(find.byIcon(Symbols.send_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('first prompt'), findsOneWidget);
        expect(find.text('first answer'), findsOneWidget);
        expect(find.text('branch prompt'), findsOneWidget);
        expect(find.text('second prompt'), findsNothing);
        expect(find.text('second answer'), findsNothing);

        await provider.refreshActiveSessionView(includeStatus: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('branch prompt'), findsOneWidget);
        expect(find.text('second prompt'), findsNothing);
        expect(find.text('second answer'), findsNothing);
      },
    );

    testWidgets('slash redo restores reverted tail and clears composer draft', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(900, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await di.sl.reset();
      di.sl.registerLazySingleton<DioClient>(DioClient.new);
      addTearDown(di.sl.reset);

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_1',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Redo Session',
          ),
        ],
      );
      repository.messagesBySession['ses_1'] = <ChatMessage>[
        UserMessage(
          id: 'msg_user_1',
          sessionId: 'ses_1',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_user_1',
              messageId: 'msg_user_1',
              sessionId: 'ses_1',
              text: 'redo me',
            ),
          ],
        ),
        AssistantMessage(
          id: 'msg_assistant_1',
          sessionId: 'ses_1',
          time: DateTime.fromMillisecondsSinceEpoch(1100),
          completedTime: DateTime.fromMillisecondsSinceEpoch(1200),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_assistant_1',
              messageId: 'msg_assistant_1',
              sessionId: 'ses_1',
              text: 'assistant restored',
            ),
          ],
        ),
      ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..defaultServerId = 'srv_test'
        ..serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'srv_test',
            'url': 'http://127.0.0.1:4096',
            'label': 'Test Server',
            'basicAuthEnabled': false,
            'basicAuthUsername': '',
            'basicAuthPassword': '',
            'createdAt': 0,
            'updatedAt': 0,
          },
        ]);
      final provider = _buildChatProvider(
        localDataSource: localDataSource,
        chatRepository: repository,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('appbar_undo_button')),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('chat_message_widget_msg_user_1')),
        findsNothing,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller?.text,
        'redo me',
      );

      await tester.enterText(find.byType(TextField).last, '/redo');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      final suggestion = find.descendant(
        of: find.byKey(const ValueKey<String>('composer_popover_panel_slash')),
        matching: find.text('/redo'),
      );
      expect(suggestion, findsOneWidget);
      await tester.tap(suggestion);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('redo me'), findsOneWidget);
      expect(find.text('assistant restored'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller?.text,
        isEmpty,
      );
    });

    testWidgets('slash thinking suggestion toggles Thinking bubbles setting', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(900, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await di.sl.reset();
      di.sl.registerLazySingleton<DioClient>(DioClient.new);
      addTearDown(di.sl.reset);

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..defaultServerId = 'srv_test'
        ..serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'srv_test',
            'url': 'http://127.0.0.1:4096',
            'label': 'Test Server',
            'basicAuthEnabled': false,
            'basicAuthUsername': '',
            'basicAuthPassword': '',
            'createdAt': 0,
            'updatedAt': 0,
          },
        ]);
      final provider = _buildChatProvider(localDataSource: localDataSource);
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      final settingsProvider = tester
          .element(find.byType(ChatPage))
          .read<SettingsProvider>();
      final initial = settingsProvider.showThinkingBubbles;

      await provider.beginNewChatDraft();
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, '/thinking');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      final suggestion = find.descendant(
        of: find.byKey(const ValueKey<String>('composer_popover_panel_slash')),
        matching: find.text('/thinking'),
      );
      expect(suggestion, findsOneWidget);
      await tester.tap(suggestion);
      await tester.pumpAndSettle();

      expect(settingsProvider.showThinkingBubbles, isNot(initial));
    });

    testWidgets(
      'slash picker falls back to selected project .opencode commands',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await di.sl.reset();
        di.sl.registerLazySingleton<DioClient>(
          () => _SlashCommandFallbackDioClient(
            projectCommandFiles: const <Map<String, dynamic>>[
              <String, dynamic>{
                'name': 'release-monitor.md',
                'type': 'file',
                'path': '.opencode/commands/release-monitor.md',
              },
            ],
          ),
        );
        addTearDown(di.sl.reset);

        final localDataSource = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test'
          ..defaultServerId = 'srv_test'
          ..serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'srv_test',
              'url': 'http://127.0.0.1:4096',
              'label': 'Test Server',
              'basicAuthEnabled': false,
              'basicAuthUsername': '',
              'basicAuthPassword': '',
              'createdAt': 0,
              'updatedAt': 0,
            },
          ]);
        final provider = _buildChatProvider(localDataSource: localDataSource);
        final appProvider = _buildAppProvider(localDataSource: localDataSource);

        await tester.pumpWidget(_testApp(provider, appProvider));
        await tester.pumpAndSettle();

        await provider.beginNewChatDraft();
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).last, '/rel');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        final suggestion = find.descendant(
          of: find.byKey(
            const ValueKey<String>('composer_popover_panel_slash'),
          ),
          matching: find.text('/release-monitor'),
        );
        expect(suggestion, findsOneWidget);
      },
    );

    testWidgets('typed custom slash command routes through command mode', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(900, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_1',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Command Session',
          ),
        ],
      );
      repository.sendMessageHandler = (_, sessionId, _, _) async* {
        yield Right(
          AssistantMessage(
            id: 'msg_command_reply',
            sessionId: sessionId,
            time: DateTime.fromMillisecondsSinceEpoch(1100),
            completedTime: DateTime.fromMillisecondsSinceEpoch(1200),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_command_reply',
                messageId: 'msg_command_reply',
                sessionId: 'ses_1',
                text: 'command reply',
              ),
            ],
          ),
        );
      };

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..defaultServerId = 'srv_test'
        ..serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'srv_test',
            'url': 'http://127.0.0.1:4096',
            'label': 'Test Server',
            'basicAuthEnabled': false,
            'basicAuthUsername': '',
            'basicAuthPassword': '',
            'createdAt': 0,
            'updatedAt': 0,
          },
        ]);
      final provider = _buildChatProvider(
        localDataSource: localDataSource,
        chatRepository: repository,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).last,
        '/release-monitor v1.2.3',
      );
      await tester.pump();
      await tester.tap(find.byIcon(Symbols.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(repository.lastSendInput?.mode, 'command');
      expect(
        repository.lastSendInput?.parts.single,
        const TextInputPart(text: '/release-monitor v1.2.3'),
      );
      expect(find.text('/release-monitor v1.2.3'), findsOneWidget);
      expect(find.text('command reply'), findsOneWidget);
    });

    testWidgets('typed builtin slash command stays local and skips send', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(900, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository();
      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..defaultServerId = 'srv_test'
        ..serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'srv_test',
            'url': 'http://127.0.0.1:4096',
            'label': 'Test Server',
            'basicAuthEnabled': false,
            'basicAuthUsername': '',
            'basicAuthPassword': '',
            'createdAt': 0,
            'updatedAt': 0,
          },
        ]);
      final provider = _buildChatProvider(
        localDataSource: localDataSource,
        chatRepository: repository,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, '/help');
      await tester.pump();
      await tester.tap(find.byIcon(Symbols.send_rounded));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(repository.lastSendInput, isNull);
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller?.text,
        isEmpty,
      );
    });

    testWidgets('shows drawer on mobile width', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..defaultServerId = 'srv_test'
        ..serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'srv_test',
            'url': 'http://127.0.0.1:4096',
            'label': 'Test Server',
            'basicAuthEnabled': false,
            'basicAuthUsername': '',
            'basicAuthPassword': '',
            'createdAt': 0,
            'updatedAt': 0,
          },
        ]);
      final provider = _buildChatProvider(localDataSource: localDataSource);
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      expect(find.byIcon(Symbols.menu), findsOneWidget);
      expect(find.text('Desktop Shortcuts'), findsNothing);
    });

    testWidgets('mobile double tap on conversation keeps chat route mounted', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_1',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Session 1',
          ),
          ChatSession(
            id: 'ses_2',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(2000),
            title: 'Session 2',
          ),
        ],
      );
      repository.messagesBySession['ses_1'] = <ChatMessage>[];
      repository.messagesBySession['ses_2'] = <ChatMessage>[];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..defaultServerId = 'srv_test'
        ..serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'srv_test',
            'url': 'http://127.0.0.1:4096',
            'label': 'Test Server',
            'basicAuthEnabled': false,
            'basicAuthUsername': '',
            'basicAuthPassword': '',
            'createdAt': 0,
            'updatedAt': 0,
          },
        ]);
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await provider.initializeProviders();

      await provider.loadSessions();
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('appbar_drawer_button')),
      );
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(
        find.byType(Scaffold).first,
      );
      expect(scaffoldState.isDrawerOpen, isTrue);

      expect(find.text('Conversations'), findsOneWidget);

      final targetSessionTile = find.byKey(
        const ValueKey<String>('chat_session_tile_ses_2'),
      );
      expect(targetSessionTile, findsOneWidget);

      await tester.tap(targetSessionTile);
      await tester.tap(targetSessionTile);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(ChatPage), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('appbar_drawer_button')),
        findsOneWidget,
      );
      expect(provider.currentSession?.id, 'ses_2');
      expect(find.text('Conversations'), findsNothing);
      expect(scaffoldState.isDrawerOpen, isFalse);
    });

    testWidgets(
      'mobile selection closes drawer immediately while conversation loads',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(500, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final repository = _ConfigurableDelayFakeChatRepository(
          sessions: <ChatSession>[
            ChatSession(
              id: 'ses_1',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              title: 'Session 1',
            ),
            ChatSession(
              id: 'ses_2',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(2000),
              title: 'Session 2',
            ),
          ],
        );
        repository.messagesBySession['ses_1'] = <ChatMessage>[];
        repository.messagesBySession['ses_2'] = <ChatMessage>[];

        final localDataSource = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test'
          ..defaultServerId = 'srv_test'
          ..serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'srv_test',
              'url': 'http://127.0.0.1:4096',
              'label': 'Test Server',
              'basicAuthEnabled': false,
              'basicAuthUsername': '',
              'basicAuthPassword': '',
              'createdAt': 0,
              'updatedAt': 0,
            },
          ]);
        final provider = _buildChatProvider(
          chatRepository: repository,
          localDataSource: localDataSource,
        );
        final appProvider = _buildAppProvider(localDataSource: localDataSource);

        await tester.pumpWidget(_testApp(provider, appProvider));
        await tester.pumpAndSettle();

        await provider.loadSessions();
        await provider.selectSession(
          provider.sessions.firstWhere((session) => session.id == 'ses_1'),
        );
        await tester.pumpAndSettle();

        repository.getMessagesGate = Completer<void>();

        await tester.tap(
          find.byKey(const ValueKey<String>('appbar_drawer_button')),
        );
        await tester.pumpAndSettle();

        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold).first,
        );
        expect(scaffoldState.isDrawerOpen, isTrue);

        await tester.tap(
          find.byKey(const ValueKey<String>('chat_session_tile_ses_2')),
        );
        await tester.pump(const Duration(milliseconds: 60));
        await tester.pump(
          const Duration(milliseconds: 500),
        ); // Finish drawer close animation

        expect(scaffoldState.isDrawerOpen, isFalse);
        expect(provider.currentSession?.id, 'ses_2');

        repository.getMessagesGate?.complete();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'latest session tap wins while another session switch is in flight',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1300, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final repository = _ConfigurableDelayFakeChatRepository(
          sessions: <ChatSession>[
            ChatSession(
              id: 'ses_1',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              title: 'Session 1',
            ),
            ChatSession(
              id: 'ses_2',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(2000),
              title: 'Session 2',
            ),
            ChatSession(
              id: 'ses_3',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(3000),
              title: 'Session 3',
            ),
          ],
        );
        repository.messagesBySession['ses_1'] = <ChatMessage>[];
        repository.messagesBySession['ses_2'] = <ChatMessage>[];
        repository.messagesBySession['ses_3'] = <ChatMessage>[];

        final localDataSource = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test'
          ..defaultServerId = 'srv_test'
          ..serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'srv_test',
              'url': 'http://127.0.0.1:4096',
              'label': 'Test Server',
              'basicAuthEnabled': false,
              'basicAuthUsername': '',
              'basicAuthPassword': '',
              'createdAt': 0,
              'updatedAt': 0,
            },
          ]);
        final provider = _buildChatProvider(
          chatRepository: repository,
          localDataSource: localDataSource,
        );
        final appProvider = _buildAppProvider(localDataSource: localDataSource);

        await tester.pumpWidget(_testApp(provider, appProvider));
        await tester.pumpAndSettle();

        await provider.loadSessions();
        await provider.selectSession(
          provider.sessions.firstWhere((session) => session.id == 'ses_1'),
        );
        await tester.pumpAndSettle();

        repository.getMessagesGate = Completer<void>();

        await tester.tap(
          find.byKey(const ValueKey<String>('chat_session_tile_ses_2')),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const ValueKey<String>('chat_session_tile_ses_3')),
        );
        await tester.pump();

        repository.getMessagesGate?.complete();
        await tester.pumpAndSettle();

        expect(provider.currentSession?.id, 'ses_3');
      },
    );

    testWidgets(
      'shows soft loading indicator while switching to a cacheless session',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final repository = _ConfigurableDelayFakeChatRepository(
          sessions: <ChatSession>[
            ChatSession(
              id: 'ses_cached_empty',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              title: 'Cached Empty',
            ),
            ChatSession(
              id: 'ses_switch_loading',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(2000),
              title: 'Switch Loading',
            ),
          ],
        );
        repository.messagesBySession['ses_cached_empty'] = <ChatMessage>[];
        repository.messagesBySession['ses_switch_loading'] = <ChatMessage>[];

        final localDataSource = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test';
        final provider = _buildChatProvider(
          chatRepository: repository,
          localDataSource: localDataSource,
        );
        final appProvider = _buildAppProvider(localDataSource: localDataSource);

        await tester.pumpWidget(_testApp(provider, appProvider));
        await tester.pumpAndSettle();

        await provider.loadSessions();
        await provider.selectSession(
          provider.sessions.firstWhere(
            (session) => session.id == 'ses_cached_empty',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Hello! I am your AI assistant'), findsOneWidget);

        repository.getMessagesGate = Completer<void>();
        final selectFuture = provider.selectSession(
          provider.sessions.firstWhere(
            (session) => session.id == 'ses_switch_loading',
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(
          find.byKey(
            const ValueKey<String>('session_hydration_loading_indicator'),
          ),
          findsOneWidget,
        );
        expect(find.text('Hello! I am your AI assistant'), findsNothing);
        expect(find.byType(ChatSkeletonShimmer), findsNothing);

        repository.getMessagesGate?.complete();
        await selectFuture;
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const ValueKey<String>('session_hydration_loading_indicator'),
          ),
          findsNothing,
        );
        expect(find.text('Hello! I am your AI assistant'), findsOneWidget);
      },
    );

    testWidgets(
      'mobile opening settings from drawer keeps drawer closed after back',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(500, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final localDataSource = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test'
          ..defaultServerId = 'srv_test'
          ..serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'srv_test',
              'url': 'http://127.0.0.1:4096',
              'label': 'Test Server',
              'basicAuthEnabled': false,
              'basicAuthUsername': '',
              'basicAuthPassword': '',
              'createdAt': 0,
              'updatedAt': 0,
            },
          ]);
        final provider = _buildChatProvider(localDataSource: localDataSource);
        final appProvider = _buildAppProvider(localDataSource: localDataSource);

        await tester.pumpWidget(_testApp(provider, appProvider));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('appbar_drawer_button')),
        );
        await tester.pumpAndSettle();

        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold).first,
        );
        expect(scaffoldState.isDrawerOpen, isTrue);

        await tester.tap(
          find.byKey(const ValueKey<String>('sidebar_settings_icon_button')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SettingsPage), findsOneWidget);

        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(find.byType(ChatPage), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('appbar_drawer_button')),
          findsOneWidget,
        );
        expect(scaffoldState.isDrawerOpen, isFalse);
        expect(
          find.byKey(const ValueKey<String>('sidebar_settings_icon_button')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'mobile selection closes drawer even when session is already active',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(500, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final repository = FakeChatRepository(
          sessions: <ChatSession>[
            ChatSession(
              id: 'ses_active',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              title: 'Active Session',
            ),
          ],
        );
        repository.messagesBySession['ses_active'] = <ChatMessage>[];

        final localDataSource = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test'
          ..defaultServerId = 'srv_test'
          ..serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'srv_test',
              'url': 'http://127.0.0.1:4096',
              'label': 'Test Server',
              'basicAuthEnabled': false,
              'basicAuthUsername': '',
              'basicAuthPassword': '',
              'createdAt': 0,
              'updatedAt': 0,
            },
          ]);
        final provider = _buildChatProvider(
          chatRepository: repository,
          localDataSource: localDataSource,
        );
        final appProvider = _buildAppProvider(localDataSource: localDataSource);

        await tester.pumpWidget(_testApp(provider, appProvider));
        await tester.pumpAndSettle();

        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('appbar_drawer_button')),
        );
        await tester.pumpAndSettle();

        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold).first,
        );
        expect(scaffoldState.isDrawerOpen, isTrue);

        await tester.tap(
          find.byKey(const ValueKey<String>('chat_session_tile_ses_active')),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(provider.currentSession?.id, 'ses_active');
        expect(scaffoldState.isDrawerOpen, isFalse);
      },
    );

    testWidgets('delays hamburger alert badge during initial server issues', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..defaultServerId = 'srv_test'
        ..serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'srv_test',
            'url': 'http://127.0.0.1:4096',
            'label': 'Test Server',
            'basicAuthEnabled': false,
            'basicAuthUsername': '',
            'basicAuthPassword': '',
            'createdAt': 0,
            'updatedAt': 0,
          },
        ]);
      final provider = _buildChatProvider(localDataSource: localDataSource);
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      appProvider.reset();
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('appbar_drawer_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('appbar_drawer_alert_badge')),
        findsNothing,
      );
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('appbar_drawer_alert_badge')),
        findsNothing,
      );
    });

    testWidgets(
      'does not show hamburger alert badge for recoverable sync states',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(500, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final localDataSource = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test'
          ..defaultServerId = 'srv_test'
          ..serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'srv_test',
              'url': 'http://127.0.0.1:4096',
              'label': 'Test Server',
              'basicAuthEnabled': false,
              'basicAuthUsername': '',
              'basicAuthPassword': '',
              'createdAt': 0,
              'updatedAt': 0,
            },
          ]);
        final provider = _buildChatProvider(localDataSource: localDataSource);
        final appProvider = _buildAppProvider(localDataSource: localDataSource);

        await tester.pumpWidget(_testApp(provider, appProvider));
        await tester.pumpAndSettle();

        final activeServerId = appProvider.activeServerId;
        if (activeServerId != null) {
          appProvider.setHealthForTesting(
            activeServerId,
            ServerHealthStatus.healthy,
          );
        }
        await tester.pump();

        expect(provider.syncState, ChatSyncState.reconnecting);
        expect(
          find.byKey(const ValueKey<String>('appbar_drawer_alert_badge')),
          findsNothing,
        );
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();
        if (activeServerId != null) {
          appProvider.setHealthForTesting(
            activeServerId,
            ServerHealthStatus.healthy,
          );
        }
        await tester.pump();

        expect(provider.syncState, ChatSyncState.reconnecting);
        expect(provider.isForegroundResumeSyncing, isFalse);
        expect(
          find.byKey(const ValueKey<String>('appbar_drawer_alert_badge')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('appbar_drawer_sync_loading')),
          findsNothing,
        );
      },
    );

    testWidgets('shows hamburger data saver badge on cellular throttling', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..defaultServerId = 'srv_test'
        ..serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'srv_test',
            'url': 'http://127.0.0.1:4096',
            'label': 'Test Server',
            'basicAuthEnabled': false,
            'basicAuthUsername': '',
            'basicAuthPassword': '',
            'createdAt': 0,
            'updatedAt': 0,
          },
        ]);
      _disableAutomaticUpdateChecksForTest(localDataSource);
      final dataSaverService = CellularDataSaverService.disabled();
      addTearDown(dataSaverService.dispose);
      dataSaverService.debugSetDataSaverEnabled(true);
      dataSaverService.debugSetTransport(DataSaverTransport.cellular);

      final settingsProvider = SettingsProvider(
        localDataSource: localDataSource,
        dioClient: DioClient(),
        soundService: SoundService(),
        cellularDataSaverService: dataSaverService,
      );
      addTearDown(settingsProvider.dispose);
      await settingsProvider.initialize();

      final provider = _buildChatProvider(
        localDataSource: localDataSource,
        cellularDataSaverService: dataSaverService,
      );
      final appProvider = _buildAppProvider(
        localDataSource: localDataSource,
        cellularDataSaverService: dataSaverService,
      );

      await tester.pumpWidget(
        _testApp(
          provider,
          appProvider,
          settingsProvider: settingsProvider,
          cellularDataSaverService: dataSaverService,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('appbar_drawer_data_saver_badge')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('appbar_drawer_alert_badge')),
        findsNothing,
      );
    });

    testWidgets(
      'mobile drawer explains data saver badge and opens behavior settings',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(500, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final localDataSource = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test'
          ..defaultServerId = 'srv_test'
          ..serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'srv_test',
              'url': 'http://127.0.0.1:4096',
              'label': 'Test Server',
              'basicAuthEnabled': false,
              'basicAuthUsername': '',
              'basicAuthPassword': '',
              'createdAt': 0,
              'updatedAt': 0,
            },
          ]);
        _disableAutomaticUpdateChecksForTest(localDataSource);
        final dataSaverService = CellularDataSaverService.disabled();
        addTearDown(dataSaverService.dispose);
        dataSaverService.debugSetDataSaverEnabled(true);
        dataSaverService.debugSetTransport(DataSaverTransport.cellular);

        final settingsProvider = SettingsProvider(
          localDataSource: localDataSource,
          dioClient: DioClient(),
          soundService: SoundService(),
          cellularDataSaverService: dataSaverService,
        );
        addTearDown(settingsProvider.dispose);
        await settingsProvider.initialize();

        final provider = _buildChatProvider(
          localDataSource: localDataSource,
          cellularDataSaverService: dataSaverService,
        );
        final appProvider = _buildAppProvider(
          localDataSource: localDataSource,
          cellularDataSaverService: dataSaverService,
        );

        await tester.pumpWidget(
          _testApp(
            provider,
            appProvider,
            settingsProvider: settingsProvider,
            cellularDataSaverService: dataSaverService,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('appbar_drawer_button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('drawer_hamburger_reason_notice')),
          findsOneWidget,
        );
        expect(find.text('Cellular data saver is active.'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey<String>('drawer_hamburger_reason_notice')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Behavior'), findsWidgets);
      },
    );

    testWidgets(
      'shows hamburger attention badge for out-of-focus session interactions',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(500, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final repository = FakeChatRepository(
          sessions: <ChatSession>[
            ChatSession(
              id: 'ses_focus',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(3000),
              title: 'Focused Session',
            ),
            ChatSession(
              id: 'ses_other',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(2000),
              title: 'Other Session',
            ),
          ],
        );
        repository.messagesBySession['ses_focus'] = <ChatMessage>[];
        repository.messagesBySession['ses_other'] = <ChatMessage>[];

        final localDataSource = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test'
          ..defaultServerId = 'srv_test'
          ..serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'srv_test',
              'url': 'http://127.0.0.1:4096',
              'label': 'Test Server',
              'basicAuthEnabled': false,
              'basicAuthUsername': '',
              'basicAuthPassword': '',
              'createdAt': 0,
              'updatedAt': 0,
            },
          ]);
        final provider = _buildChatProvider(
          chatRepository: repository,
          localDataSource: localDataSource,
        );
        final appProvider = _buildAppProvider(localDataSource: localDataSource);

        await tester.pumpWidget(_testApp(provider, appProvider));
        await tester.pumpAndSettle();

        await provider.loadSessions();
        await provider.selectSession(
          provider.sessions.where((item) => item.id == 'ses_focus').first,
        );
        await tester.pumpAndSettle();

        repository.emitEvent(
          const ChatEvent(
            type: 'question.asked',
            properties: <String, dynamic>{
              'id': 'question_1',
              'sessionID': 'ses_other',
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
        await tester.pump(const Duration(milliseconds: 60));

        expect(
          find.byKey(const ValueKey<String>('appbar_drawer_attention_badge')),
          findsOneWidget,
        );

        await provider.selectSession(
          provider.sessions.where((item) => item.id == 'ses_other').first,
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('appbar_drawer_attention_badge')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'mobile drawer explains attention badge and switches sessions',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(500, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final repository = FakeChatRepository(
          sessions: <ChatSession>[
            ChatSession(
              id: 'ses_focus',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(3000),
              title: 'Focused Session',
            ),
            ChatSession(
              id: 'ses_other',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(2000),
              title: 'Other Session',
            ),
          ],
        );
        repository.messagesBySession['ses_focus'] = <ChatMessage>[];
        repository.messagesBySession['ses_other'] = <ChatMessage>[];

        final localDataSource = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test'
          ..defaultServerId = 'srv_test'
          ..serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'srv_test',
              'url': 'http://127.0.0.1:4096',
              'label': 'Test Server',
              'basicAuthEnabled': false,
              'basicAuthUsername': '',
              'basicAuthPassword': '',
              'createdAt': 0,
              'updatedAt': 0,
            },
          ]);
        final provider = _buildChatProvider(
          chatRepository: repository,
          localDataSource: localDataSource,
        );
        final appProvider = _buildAppProvider(localDataSource: localDataSource);

        await tester.pumpWidget(_testApp(provider, appProvider));
        await tester.pumpAndSettle();

        await provider.loadSessions();
        await provider.selectSession(
          provider.sessions.where((item) => item.id == 'ses_focus').first,
        );
        await tester.pumpAndSettle();

        repository.emitEvent(
          const ChatEvent(
            type: 'question.asked',
            properties: <String, dynamic>{
              'id': 'question_1',
              'sessionID': 'ses_other',
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
        await tester.pump(const Duration(milliseconds: 60));

        await tester.tap(
          find.byKey(const ValueKey<String>('appbar_drawer_button')),
        );
        await tester.pumpAndSettle();

        expect(find.text('"Other Session" needs your input.'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey<String>('drawer_hamburger_reason_notice')),
        );
        await tester.pumpAndSettle();

        expect(provider.currentSession?.id, 'ses_other');
        expect(find.text('Conversations'), findsNothing);
      },
    );

    testWidgets('desktop sidebar does not show the drawer badge explanation', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..defaultServerId = 'srv_test'
        ..serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'srv_test',
            'url': 'http://127.0.0.1:4096',
            'label': 'Test Server',
            'basicAuthEnabled': false,
            'basicAuthUsername': '',
            'basicAuthPassword': '',
            'createdAt': 0,
            'updatedAt': 0,
          },
        ]);
      _disableAutomaticUpdateChecksForTest(localDataSource);
      final dataSaverService = CellularDataSaverService.disabled();
      addTearDown(dataSaverService.dispose);
      dataSaverService.debugSetDataSaverEnabled(true);
      dataSaverService.debugSetTransport(DataSaverTransport.cellular);

      final settingsProvider = SettingsProvider(
        localDataSource: localDataSource,
        dioClient: DioClient(),
        soundService: SoundService(),
        cellularDataSaverService: dataSaverService,
      );
      addTearDown(settingsProvider.dispose);
      await settingsProvider.initialize();

      final provider = _buildChatProvider(
        localDataSource: localDataSource,
        cellularDataSaverService: dataSaverService,
      );
      final appProvider = _buildAppProvider(
        localDataSource: localDataSource,
        cellularDataSaverService: dataSaverService,
      );

      await tester.pumpWidget(
        _testApp(
          provider,
          appProvider,
          settingsProvider: settingsProvider,
          cellularDataSaverService: dataSaverService,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('drawer_hamburger_reason_notice')),
        findsNothing,
      );
      expect(find.text('Cellular data saver is active.'), findsNothing);
    });

    testWidgets('shows subtle menu loading after returning from background', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..defaultServerId = 'srv_test'
        ..serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'srv_test',
            'url': 'http://127.0.0.1:4096',
            'label': 'Test Server',
            'basicAuthEnabled': false,
            'basicAuthUsername': '',
            'basicAuthPassword': '',
            'createdAt': 0,
            'updatedAt': 0,
          },
        ]);
      final provider = _buildChatProvider(localDataSource: localDataSource);
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      final activeServerId = appProvider.activeServerId;
      if (activeServerId != null) {
        appProvider.setHealthForTesting(
          activeServerId,
          ServerHealthStatus.healthy,
        );
      }
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();

      if (FeatureFlags.refreshlessRealtime) {
        expect(provider.isForegroundResumeSyncing, isTrue);
      } else {
        expect(provider.isForegroundResumeSyncing, isFalse);
      }
      expect(provider.syncState, ChatSyncState.reconnecting);

      expect(
        find.byKey(const ValueKey<String>('appbar_drawer_alert_badge')),
        findsNothing,
      );
      if (FeatureFlags.refreshlessRealtime) {
        expect(
          find.byKey(const ValueKey<String>('appbar_drawer_sync_loading')),
          findsOneWidget,
        );
      } else {
        expect(
          find.byKey(const ValueKey<String>('appbar_drawer_sync_loading')),
          findsNothing,
        );
      }

      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      if (activeServerId != null) {
        appProvider.setHealthForTesting(
          activeServerId,
          ServerHealthStatus.healthy,
        );
      }
      await tester.pump();
      if (FeatureFlags.refreshlessRealtime) {
        expect(provider.isForegroundResumeSyncing, isTrue);
        expect(
          find.byKey(const ValueKey<String>('appbar_drawer_sync_loading')),
          findsOneWidget,
        );
      } else {
        expect(
          find.byKey(const ValueKey<String>('appbar_drawer_sync_loading')),
          findsNothing,
        );
      }
      expect(
        find.byKey(const ValueKey<String>('appbar_drawer_alert_badge')),
        findsNothing,
      );

      if (FeatureFlags.refreshlessRealtime) {
        await tester.pump(const Duration(milliseconds: 650));
        await tester.pump();
        if (activeServerId != null) {
          appProvider.setHealthForTesting(
            activeServerId,
            ServerHealthStatus.healthy,
          );
        }
        await tester.pump();
        expect(provider.isForegroundResumeSyncing, isFalse);
        expect(
          find.byKey(const ValueKey<String>('appbar_drawer_sync_loading')),
          findsNothing,
        );
      }
    });

    testWidgets('suppresses unhealthy warning UI during foreground grace', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..defaultServerId = 'srv_test'
        ..serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'srv_test',
            'url': 'http://127.0.0.1:4096',
            'label': 'Test Server',
            'basicAuthEnabled': false,
            'basicAuthUsername': '',
            'basicAuthPassword': '',
            'createdAt': 0,
            'updatedAt': 0,
          },
        ]);
      final provider = _buildChatProvider(localDataSource: localDataSource);
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      final activeServerId = appProvider.activeServerId;
      expect(activeServerId, isNotNull);
      appProvider.setHealthForTesting(
        activeServerId!,
        ServerHealthStatus.healthy,
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('appbar_drawer_alert_badge')),
        findsNothing,
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      appProvider.setHealthForTesting(
        activeServerId,
        ServerHealthStatus.unhealthy,
      );
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('Unhealthy'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('appbar_drawer_alert_badge')),
        findsNothing,
      );

      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pump();
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('Unhealthy'), findsNothing);
    });

    testWidgets('shows utility pane on large desktop width', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1300, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..experienceSettingsJson = jsonEncode(<String, dynamic>{
          'checkUpdatesOnOpen': false,
          'composerAutoApprovePermissions': false,
        });
      final provider = _buildChatProvider(localDataSource: localDataSource);
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      expect(find.byIcon(Symbols.menu), findsNothing);
      expect(find.text('Keyboard shortcuts'), findsOneWidget);
      expect(find.textContaining('Ctrl/Cmd'), findsNothing);
      expect(find.text('Ctrl+N'), findsOneWidget);
      expect(find.text('Alt+S'), findsOneWidget);
      expect(find.text('Ctrl+P'), findsOneWidget);
      expect(find.text('Ctrl+,'), findsOneWidget);
      expect(find.text('Ctrl+M'), findsOneWidget);
      expect(find.text('Ctrl+T'), findsOneWidget);
      expect(find.text('Esc, Esc'), findsOneWidget);
      expect(find.text('Conversations'), findsOneWidget);
    });

    testWidgets('desktop sidebars can be hidden and restored from menu', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1300, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..experienceSettingsJson = jsonEncode(<String, dynamic>{
          'checkUpdatesOnOpen': false,
          'composerAutoApprovePermissions': false,
        });
      final provider = _buildChatProvider(localDataSource: localDataSource);
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      expect(find.text('Conversations'), findsOneWidget);
      expect(find.text('Files'), findsOneWidget);
      expect(find.text('Keyboard shortcuts'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('hide_conversations_sidebar_button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Conversations'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey<String>('desktop_sidebars_menu_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey<String>('desktop_sidebar_menu_item_conversations'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Conversations'), findsOneWidget);
    });

    testWidgets('desktop sidebar toggles do not duplicate markdown code lines', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1300, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_sidebar_code',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Sidebar Code Session',
          ),
        ],
      );
      repository.messagesBySession['ses_sidebar_code'] = <ChatMessage>[
        AssistantMessage(
          id: 'msg_sidebar_code',
          sessionId: 'ses_sidebar_code',
          time: DateTime.fromMillisecondsSinceEpoch(1100),
          completedTime: DateTime.fromMillisecondsSinceEpoch(1200),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_sidebar_code',
              messageId: 'msg_sidebar_code',
              sessionId: 'ses_sidebar_code',
              text:
                  'Use `alpha` and `beta` in sequence.\n\n```dart\nfinal answer = 42;\nprint(answer);\n```',
            ),
          ],
        ),
      ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..experienceSettingsJson = jsonEncode(<String, dynamic>{
          'checkUpdatesOnOpen': false,
          'composerAutoApprovePermissions': false,
        });
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      expect(find.textContaining('alpha'), findsOneWidget);
      expect(find.textContaining('beta'), findsOneWidget);
      expect(find.byType(HighlightView), findsOneWidget);

      for (var i = 0; i < 3; i += 1) {
        await tester.tap(
          find.byKey(
            const ValueKey<String>('hide_conversations_sidebar_button'),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('desktop_sidebars_menu_button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(
            const ValueKey<String>('desktop_sidebar_menu_item_conversations'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('alpha'), findsOneWidget);
        expect(find.textContaining('beta'), findsOneWidget);
        expect(find.byType(HighlightView), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets(
      'app bar display toggles menu controls thinking and tool bubbles',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final repository = FakeChatRepository(
          sessions: <ChatSession>[
            ChatSession(
              id: 'ses_display_toggles',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              title: 'Display Toggles Session',
            ),
          ],
        );
        repository.messagesBySession['ses_display_toggles'] = <ChatMessage>[
          AssistantMessage(
            id: 'msg_display_toggles',
            sessionId: 'ses_display_toggles',
            time: DateTime.fromMillisecondsSinceEpoch(1100),
            completedTime: DateTime.fromMillisecondsSinceEpoch(1200),
            parts: <MessagePart>[
              const ReasoningPart(
                id: 'part_display_reasoning',
                messageId: 'msg_display_toggles',
                sessionId: 'ses_display_toggles',
                text: 'Investigating component state',
              ),
              ToolPart(
                id: 'part_display_tool',
                messageId: 'msg_display_toggles',
                sessionId: 'ses_display_toggles',
                callId: 'call_display_tool',
                tool: 'bash',
                state: ToolStateCompleted(
                  input: const <String, dynamic>{'command': 'pwd'},
                  output: '/tmp',
                  time: ToolTime(
                    start: DateTime.fromMillisecondsSinceEpoch(1100),
                    end: DateTime.fromMillisecondsSinceEpoch(1200),
                  ),
                ),
              ),
            ],
          ),
        ];

        final localDataSource = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test';
        final provider = _buildChatProvider(
          chatRepository: repository,
          localDataSource: localDataSource,
        );
        final appProvider = _buildAppProvider(localDataSource: localDataSource);

        await tester.pumpWidget(_testApp(provider, appProvider));
        await tester.pumpAndSettle();

        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);
        await tester.pumpAndSettle();

        expect(find.text('Thinking Process'), findsOneWidget);
        expect(
          find.byKey(
            const ValueKey<String>(
              'tool_part_details_button_part_display_tool',
            ),
          ),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('appbar_display_toggles_button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('display_toggle_item_thinking')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Thinking Process'), findsNothing);
        expect(
          find.byKey(
            const ValueKey<String>(
              'tool_part_details_button_part_display_tool',
            ),
          ),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('appbar_display_toggles_button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('display_toggle_item_tool_calls')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const ValueKey<String>(
              'tool_part_details_button_part_display_tool',
            ),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('mobile app bar opens files dialog in fullscreen', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..experienceSettingsJson = jsonEncode(<String, dynamic>{
          'checkUpdatesOnOpen': false,
          'composerAutoApprovePermissions': false,
        });
      final provider = _buildChatProvider(localDataSource: localDataSource);
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('appbar_quick_open_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('mobile_files_dialog_fullscreen')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('file_tree_quick_open_button')),
        findsOneWidget,
      );
    });

    testWidgets('desktop terminal button toggles terminal panel', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1300, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(localDataSource: localDataSource);
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('terminal_panel')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('appbar_terminal_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('terminal_panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('terminal_panel_status_text')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('terminal_panel_stop_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('terminal_panel')),
        findsNothing,
      );
    });

    testWidgets(
      'compact terminal opens and can be minimized',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 900));
        addTearDown(() {
          tester.binding.setSurfaceSize(null);
        });

        final localDataSource = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test';
        final provider = _buildChatProvider(localDataSource: localDataSource);
        final appProvider = _buildAppProvider(localDataSource: localDataSource);

        await tester.pumpWidget(_testApp(provider, appProvider));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('composer_root_container')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('appbar_terminal_button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('terminal_panel')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('terminal_panel_hide_button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('terminal_panel')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('composer_root_container')),
          findsOneWidget,
        );
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.android,
      }),
    );

    testWidgets('terminal maximize button expands panel height', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1300, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(localDataSource: localDataSource);
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('appbar_terminal_button')),
      );
      await tester.pumpAndSettle();

      final panelFinder = find.byKey(const ValueKey<String>('terminal_panel'));
      final initialHeight = tester.getSize(panelFinder).height;

      await tester.tap(
        find.byKey(const ValueKey<String>('terminal_panel_maximize_button')),
      );
      await tester.pumpAndSettle();

      final maximizedHeight = tester.getSize(panelFinder).height;
      expect(maximizedHeight, greaterThan(initialHeight));
    });

    testWidgets('applies compact app bar toolbar heights', (
      WidgetTester tester,
    ) async {
      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(localDataSource: localDataSource);
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.binding.setSurfaceSize(const Size(1000, 900));
      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      final desktopAppBar = tester.widget<AppBar>(find.byType(AppBar).first);
      expect(desktopAppBar.toolbarHeight, 44);

      await tester.binding.setSurfaceSize(const Size(500, 900));
      await tester.pumpAndSettle();

      final mobileAppBar = tester.widget<AppBar>(find.byType(AppBar).first);
      expect(mobileAppBar.toolbarHeight, 46);

      addTearDown(() => tester.binding.setSurfaceSize(null));
    });

    testWidgets(
      'display toggles include recent sessions and show recent card',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final localDataSource = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test'
          ..experienceSettingsJson = jsonEncode(<String, dynamic>{
            'showRecentSessions': true,
          });
        final repository = FakeChatRepository(
          sessions: <ChatSession>[
            ChatSession(
              id: 'ses_recent',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(2000),
              title: 'Recent Root Session',
            ),
          ],
        );
        repository.messagesBySession['ses_recent'] = <ChatMessage>[];
        final provider = _buildChatProvider(
          chatRepository: repository,
          localDataSource: localDataSource,
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
            ],
          ),
        );
        final appProvider = _buildAppProvider(localDataSource: localDataSource);

        await tester.pumpWidget(_testApp(provider, appProvider));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('appbar_display_toggles_button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const ValueKey<String>('display_toggle_item_recent_sessions'),
          ),
          findsOneWidget,
        );

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(find.text('Recent sessions'), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('recent_session_tile_ses_recent')),
          findsOneWidget,
        );
        expect(find.text('Project A'), findsWidgets);
      },
    );

    testWidgets('recent sessions shows busy sweep for non-current busy items', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..experienceSettingsJson = jsonEncode(<String, dynamic>{
          'showRecentSessions': true,
        });
      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_current',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Current Session',
          ),
          ChatSession(
            id: 'ses_recent',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(2000),
            title: 'Recent Root Session',
          ),
        ],
      );
      repository.messagesBySession['ses_current'] = <ChatMessage>[];
      repository.messagesBySession['ses_recent'] = <ChatMessage>[];
      repository.sessionStatusById = const <String, SessionStatusInfo>{
        'ses_recent': SessionStatusInfo(type: SessionStatusType.busy),
      };
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
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
          ],
        ),
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(
        provider.sessions.firstWhere((session) => session.id == 'ses_current'),
      );
      await provider.initializeProviders();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byKey(
          const ValueKey<String>('recent_session_busy_title_ses_recent'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('recent_session_title_ses_recent'),
          ),
          matching: find.byType(ShaderMask),
        ),
        findsOneWidget,
      );
    });

    testWidgets('recent sessions disables busy sweep when animations are off', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..experienceSettingsJson = jsonEncode(<String, dynamic>{
          'showRecentSessions': true,
        });
      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_current',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Current Session',
          ),
          ChatSession(
            id: 'ses_recent',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(2000),
            title: 'Recent Root Session',
          ),
        ],
      );
      repository.messagesBySession['ses_current'] = <ChatMessage>[];
      repository.messagesBySession['ses_recent'] = <ChatMessage>[];
      repository.sessionStatusById = const <String, SessionStatusInfo>{
        'ses_recent': SessionStatusInfo(type: SessionStatusType.busy),
      };
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
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
          ],
        ),
      );
      addTearDown(provider.dispose);
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      const mediaQueryData = MediaQueryData(
        size: Size(1000, 900),
        disableAnimations: true,
      );
      await tester.pumpWidget(
        _testApp(provider, appProvider, mediaQueryData: mediaQueryData),
      );
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(
        provider.sessions.firstWhere((session) => session.id == 'ses_current'),
      );
      await provider.initializeProviders();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byKey(
          const ValueKey<String>('recent_session_busy_title_ses_recent'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('recent_session_title_ses_recent'),
          ),
          matching: find.byType(ShaderMask),
        ),
        findsNothing,
      );
    });

    testWidgets(
      'recent sessions emphasizes unread title color after idle status transition',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final localDataSource = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test'
          ..experienceSettingsJson = jsonEncode(<String, dynamic>{
            'showRecentSessions': true,
          });
        final repository = FakeChatRepository(
          sessions: <ChatSession>[
            ChatSession(
              id: 'ses_current',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              title: 'Current Session',
            ),
            ChatSession(
              id: 'ses_recent',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(2000),
              title: 'Recent Root Session',
            ),
          ],
        );
        repository.messagesBySession['ses_current'] = <ChatMessage>[];
        repository.messagesBySession['ses_recent'] = <ChatMessage>[];
        final provider = _buildChatProvider(
          chatRepository: repository,
          localDataSource: localDataSource,
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
            ],
          ),
        );
        addTearDown(provider.dispose);
        final appProvider = _buildAppProvider(localDataSource: localDataSource);

        await tester.pumpWidget(_testApp(provider, appProvider));
        await tester.pumpAndSettle();

        await provider.loadSessions();
        await provider.selectSession(
          provider.sessions.firstWhere(
            (session) => session.id == 'ses_current',
          ),
        );
        await provider.initializeProviders();
        await tester.pumpAndSettle();

        repository.emitEvent(
          const ChatEvent(
            type: 'session.status',
            properties: <String, dynamic>{
              'sessionID': 'ses_recent',
              'status': <String, dynamic>{'type': 'busy'},
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));
        repository.emitEvent(
          const ChatEvent(
            type: 'session.status',
            properties: <String, dynamic>{
              'sessionID': 'ses_recent',
              'status': <String, dynamic>{'type': 'idle'},
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));
        repository.emitEvent(
          const ChatEvent(
            type: 'session.idle',
            properties: <String, dynamic>{'sessionID': 'ses_recent'},
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpAndSettle();

        final title = tester.widget<Text>(
          find.descendant(
            of: find.byKey(
              const ValueKey<String>('recent_session_title_ses_recent'),
            ),
            matching: find.text('Recent Root Session'),
          ),
        );
        final recentSessionsContext = tester.element(
          find.text('Recent sessions'),
        );
        final colorScheme = Theme.of(recentSessionsContext).colorScheme;
        expect(title.style?.color, colorScheme.primary);

        await provider.selectSession(
          provider.sessions.firstWhere((session) => session.id == 'ses_recent'),
        );
        await tester.pumpAndSettle();
      },
    );

    testWidgets('recent sessions highlights the current session row', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..experienceSettingsJson = jsonEncode(<String, dynamic>{
          'showRecentSessions': true,
        });
      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_current',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Current Session',
          ),
          ChatSession(
            id: 'ses_recent',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(2000),
            title: 'Recent Root Session',
          ),
        ],
      );
      repository.messagesBySession['ses_current'] = <ChatMessage>[];
      repository.messagesBySession['ses_recent'] = <ChatMessage>[];
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
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
          ],
        ),
      );
      addTearDown(provider.dispose);
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(
        provider.sessions.firstWhere((session) => session.id == 'ses_current'),
      );
      await provider.initializeProviders();
      await tester.pumpAndSettle();

      final tileMaterial = tester
          .widgetList<Material>(
            find.ancestor(
              of: find.byKey(
                const ValueKey<String>('recent_session_tile_ses_current'),
              ),
              matching: find.byType(Material),
            ),
          )
          .firstWhere((material) => material.color != null);
      final title = tester.widget<Text>(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('recent_session_title_ses_current'),
          ),
          matching: find.text('Current Session'),
        ),
      );
      final recentSessionsContext = tester.element(
        find.text('Recent sessions'),
      );
      final colorScheme = Theme.of(recentSessionsContext).colorScheme;

      expect(tileMaterial.color, colorScheme.secondaryContainer);
      expect(title.style?.color, colorScheme.onSecondaryContainer);
    });

    testWidgets('display toggles expose replay chat tour action', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(localDataSource: localDataSource);
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('appbar_display_toggles_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('display_toggle_item_replay_tour')),
        findsOneWidget,
      );
      expect(find.text('Replay chat tour'), findsOneWidget);
    });

    testWidgets('pending tour flag survives startup retries', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..experienceSettingsJson = jsonEncode(<String, dynamic>{
          'pendingPostOnboardingChatTour': true,
          'checkUpdatesOnOpen': false,
        });
      final provider = _buildChatProvider(localDataSource: localDataSource);
      final appProvider = _buildAppProvider(localDataSource: localDataSource);
      final settingsProvider = SettingsProvider(
        localDataSource: localDataSource,
        dioClient: DioClient(),
        soundService: SoundService(),
      );
      await settingsProvider.initialize();
      addTearDown(settingsProvider.dispose);

      await tester.pumpWidget(
        _testApp(provider, appProvider, settingsProvider: settingsProvider),
      );
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 3));

      expect(settingsProvider.pendingPostOnboardingChatTour, isTrue);
    });

    testWidgets('passive tour dismiss keeps the pending flag armed', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..experienceSettingsJson = jsonEncode(<String, dynamic>{
          'pendingPostOnboardingChatTour': true,
          'checkUpdatesOnOpen': false,
        });
      final provider = _buildChatProvider(localDataSource: localDataSource);
      final appProvider = _buildAppProvider(localDataSource: localDataSource);
      final settingsProvider = SettingsProvider(
        localDataSource: localDataSource,
        dioClient: DioClient(),
        soundService: SoundService(),
      );
      await settingsProvider.initialize();
      addTearDown(settingsProvider.dispose);

      await tester.pumpWidget(
        _testApp(
          provider,
          appProvider,
          settingsProvider: settingsProvider,
          mediaQueryData: const MediaQueryData(size: Size(500, 900)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Open sidebar'), findsOneWidget);

      await tester.tapAt(const Offset(12, 12));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(settingsProvider.pendingPostOnboardingChatTour, isTrue);
    });

    testWidgets('explicit skip clears the pending tour flag', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..experienceSettingsJson = jsonEncode(<String, dynamic>{
          'pendingPostOnboardingChatTour': true,
          'checkUpdatesOnOpen': false,
        });
      final provider = _buildChatProvider(localDataSource: localDataSource);
      final appProvider = _buildAppProvider(localDataSource: localDataSource);
      final settingsProvider = SettingsProvider(
        localDataSource: localDataSource,
        dioClient: DioClient(),
        soundService: SoundService(),
      );
      await settingsProvider.initialize();
      addTearDown(settingsProvider.dispose);

      await tester.pumpWidget(
        _testApp(
          provider,
          appProvider,
          settingsProvider: settingsProvider,
          mediaQueryData: const MediaQueryData(size: Size(500, 900)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(settingsProvider.pendingPostOnboardingChatTour, isFalse);
    });

    testWidgets('finishing the tour clears the pending flag', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..experienceSettingsJson = jsonEncode(<String, dynamic>{
          'pendingPostOnboardingChatTour': true,
          'checkUpdatesOnOpen': false,
        });
      final provider = _buildChatProvider(localDataSource: localDataSource);
      final appProvider = _buildAppProvider(localDataSource: localDataSource);
      final settingsProvider = SettingsProvider(
        localDataSource: localDataSource,
        dioClient: DioClient(),
        soundService: SoundService(),
      );
      await settingsProvider.initialize();
      addTearDown(settingsProvider.dispose);

      await tester.pumpWidget(
        _testApp(
          provider,
          appProvider,
          settingsProvider: settingsProvider,
          mediaQueryData: const MediaQueryData(size: Size(1000, 900)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Open project'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Chat input'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Done'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(settingsProvider.pendingPostOnboardingChatTour, isFalse);
    });

    testWidgets('display toggles replay starts the mobile intro tour', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..experienceSettingsJson = jsonEncode(<String, dynamic>{
          'checkUpdatesOnOpen': false,
        });
      final provider = _buildChatProvider(localDataSource: localDataSource);
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(
        _testApp(
          provider,
          appProvider,
          mediaQueryData: const MediaQueryData(size: Size(500, 900)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('appbar_display_toggles_button')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('display_toggle_item_replay_tour')),
      );
      // startShowcase uses a 350ms delay via _postOnboardingTourStartDelay.
      // Pump to let the Future.delayed fire and _activeWidgetId get set.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 500));

      // Access ShowCaseWidgetState directly to avoid ShowcaseService scope issues.
      final showcaseState = tester.state<ShowCaseWidgetState>(
        find.byType(ShowCaseWidget),
      );
      expect(showcaseState.isShowcaseRunning, isTrue);
      expect(find.text('Open sidebar'), findsOneWidget);
    });

    testWidgets('pending tour renders desktop intro overlay on startup', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..experienceSettingsJson = jsonEncode(<String, dynamic>{
          'pendingPostOnboardingChatTour': true,
          'checkUpdatesOnOpen': false,
        });
      final provider = _buildChatProvider(localDataSource: localDataSource);
      final appProvider = _buildAppProvider(localDataSource: localDataSource);
      final settingsProvider = SettingsProvider(
        localDataSource: localDataSource,
        dioClient: DioClient(),
        soundService: SoundService(),
      );
      await settingsProvider.initialize();
      addTearDown(settingsProvider.dispose);

      await tester.pumpWidget(
        _testApp(
          provider,
          appProvider,
          settingsProvider: settingsProvider,
          mediaQueryData: const MediaQueryData(size: Size(1000, 900)),
        ),
      );
      // Pump to let the post-frame callback fire and the showcase delay (350ms) elapse.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 500));

      // Access ShowCaseWidgetState directly to avoid ShowcaseService scope issues.
      final showcaseState = tester.state<ShowCaseWidgetState>(
        find.byType(ShowCaseWidget),
      );
      expect(showcaseState.isShowcaseRunning, isTrue);
      expect(find.text('Open project'), findsOneWidget);
    });

    testWidgets('recent sessions stays hidden when there are no recent roots', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        localDataSource: localDataSource,
        projectRepository: FakeProjectRepository(
          currentProject: Project(
            id: 'proj_a',
            name: 'Project A',
            path: '/very/long/path/to/repo/a',
            createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          ),
          projects: <Project>[
            Project(
              id: 'proj_a',
              name: 'Project A',
              path: '/very/long/path/to/repo/a',
              createdAt: DateTime.fromMillisecondsSinceEpoch(0),
            ),
          ],
        ),
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      expect(find.text('Recent sessions'), findsNothing);

      final projectTile = tester.widget<ListTile>(
        find.byKey(const ValueKey<String>('project_group_tile_proj_a')),
      );
      final subtitleDirectionality = tester.widget<Directionality>(
        find
            .descendant(
              of: find.byKey(
                const ValueKey<String>('project_group_tile_proj_a'),
              ),
              matching: find.byType(Directionality),
            )
            .last,
      );
      expect(projectTile.subtitle, isNotNull);
      expect(subtitleDirectionality.textDirection, TextDirection.rtl);
    });
  });

  testWidgets(
    'hides attachment button when selected model does not support attachments',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(localDataSource: localDataSource);
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Add attachment'), findsNothing);
    },
  );

  testWidgets('shows only supported attachment options for image-only model', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_attach_image_only',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Attachment Session',
        ),
      ],
    );
    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
      providersResponse: ProvidersResponse(
        providers: <Provider>[
          Provider(
            id: 'provider_1',
            name: 'Provider 1',
            env: const <String>[],
            models: <String, Model>{
              'model_1': _model(
                'model_1',
                attachment: true,
                modalities: const <String, dynamic>{
                  'input': <String>['text', 'image'],
                },
              ),
            },
          ),
        ],
        defaultModels: const <String, String>{'provider_1': 'model_1'},
        connected: const <String>['provider_1'],
      ),
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();
    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Extras'), findsOneWidget);
    await tester.tap(find.byTooltip('Extras'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Attach files'));
    await tester.pumpAndSettle();
    expect(find.text('Select Images'), findsOneWidget);
    expect(find.text('Select PDF'), findsNothing);
  });

  testWidgets(
    'shows both image and PDF options when model supports both modalities',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_attach_image_pdf',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Attachment Session',
          ),
        ],
      );
      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
        providersResponse: ProvidersResponse(
          providers: <Provider>[
            Provider(
              id: 'provider_1',
              name: 'Provider 1',
              env: const <String>[],
              models: <String, Model>{
                'model_1': _model(
                  'model_1',
                  attachment: true,
                  modalities: const <String, dynamic>{
                    'input': <String>['text', 'image', 'pdf'],
                  },
                ),
              },
            ),
          ],
          defaultModels: const <String, String>{'provider_1': 'model_1'},
          connected: const <String>['provider_1'],
        ),
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();
      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Extras'), findsOneWidget);
      await tester.tap(find.byTooltip('Extras'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Attach files'));
      await tester.pumpAndSettle();
      expect(find.text('Select Images'), findsOneWidget);
      expect(find.text('Select PDF'), findsOneWidget);
    },
  );

  testWidgets('shows active directory and directory selector guidance', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      localDataSource: localDataSource,
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
        ],
      ),
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Choose Directory'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('project_selector_button')),
      findsOneWidget,
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey<String>('project_selector_button')),
          )
          .dx,
      lessThan(220),
    );

    await tester.tap(find.byTooltip('Choose Directory'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('project_selector_dialog_content')),
      findsOneWidget,
    );
    expect(find.text('Project context'), findsOneWidget);
    expect(find.text('Current directory: /repo/a'), findsOneWidget);
    expect(find.text('Select a project below.'), findsOneWidget);
    expect(find.byIcon(Symbols.close_rounded), findsOneWidget);
  });

  testWidgets('renders grouped project conversation headers', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      localDataSource: localDataSource,
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
        ],
      ),
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('project_group_tile_proj_a')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('project_group_expand_proj_a')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('conversations_project_context_button'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('project_group_close_proj_a')),
      findsNothing,
    );
  });

  testWidgets('active project group can collapse and expand', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_group',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Grouped Session',
        ),
      ],
    );
    repository.messagesBySession['ses_group'] = <ChatMessage>[];

    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
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
        ],
      ),
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    final expandButton = find.byKey(
      const ValueKey<String>('project_group_expand_proj_a'),
    );
    expect(expandButton, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('chat_session_tile_ses_group')),
      findsOneWidget,
    );

    await tester.tap(expandButton);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('chat_session_tile_ses_group')),
      findsNothing,
    );

    await tester.tap(expandButton);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('chat_session_tile_ses_group')),
      findsOneWidget,
    );
  });

  testWidgets('project group tile switches project context', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    await localDataSource.saveOpenProjectIdsJson(
      jsonEncode(<String>['proj_a', 'proj_b']),
      serverId: 'srv_test',
    );

    final provider = _buildChatProvider(
      localDataSource: localDataSource,
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
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    IconData expandIconFor(String projectId) {
      final button = tester.widget<IconButton>(
        find.byKey(ValueKey<String>('project_group_expand_$projectId')),
      );
      final icon = button.icon as Icon;
      return icon.icon!;
    }

    expect(provider.projectProvider.currentProject?.id, 'proj_a');
    expect(expandIconFor('proj_a'), Symbols.expand_less);
    expect(expandIconFor('proj_b'), Symbols.expand_more);
    expect(
      find.byKey(const ValueKey<String>('project_group_tile_proj_b')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('project_group_tile_proj_b')),
    );
    await tester.pumpAndSettle();

    expect(provider.projectProvider.currentProject?.id, 'proj_b');
    expect(expandIconFor('proj_a'), Symbols.expand_more);
    expect(expandIconFor('proj_b'), Symbols.expand_less);
  });

  testWidgets('closed project can be archived from closed list', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final projectRepository = FakeProjectRepository(
      currentProject: Project(
        id: 'proj_main',
        name: 'Main',
        path: '/repo/main',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      projects: <Project>[
        Project(
          id: 'proj_main',
          name: 'Main',
          path: '/repo/main',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
        Project(
          id: 'proj_ws',
          name: 'Workspace Feature',
          path: '/repo/main/feature-a',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1),
        ),
      ],
    );
    final provider = _buildChatProvider(
      localDataSource: localDataSource,
      projectRepository: projectRepository,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Choose Directory'));
    await tester.pumpAndSettle();

    expect(find.text('Workspace Feature'), findsOneWidget);
    expect(find.byTooltip('Reopen Workspace Feature'), findsNothing);
    await tester.tap(find.byTooltip('Remove Workspace Feature from history'));
    await tester.pumpAndSettle();

    expect(provider.projectProvider.archivedProjectIds, contains('proj_ws'));
    expect(
      provider.projectProvider.hiddenProjectPaths,
      contains('/repo/main/feature-a'),
    );
    expect(find.text('Workspace Feature'), findsNothing);
  });

  testWidgets('tapping closed project reopens it and closes selector', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final projectRepository = FakeProjectRepository(
      currentProject: Project(
        id: 'proj_main',
        name: 'Main',
        path: '/repo/main',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      projects: <Project>[
        Project(
          id: 'proj_main',
          name: 'Main',
          path: '/repo/main',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
        Project(
          id: 'proj_ws',
          name: 'Workspace Feature',
          path: '/repo/main/feature-a',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1),
        ),
      ],
    );
    final provider = _buildChatProvider(
      localDataSource: localDataSource,
      projectRepository: projectRepository,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Choose Directory'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('project_selector_dialog_content')),
      findsOneWidget,
    );
    expect(provider.projectProvider.currentProject?.id, 'proj_main');
    expect(provider.projectProvider.openProjectIds, isNot(contains('proj_ws')));

    await tester.tap(find.text('Workspace Feature'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('project_selector_dialog_content')),
      findsNothing,
    );
    expect(provider.projectProvider.currentProject?.id, 'proj_ws');
    expect(provider.projectProvider.currentDirectory, '/repo/main/feature-a');
    expect(provider.projectProvider.openProjectIds, contains('proj_ws'));
  });

  testWidgets('tapping open project switches context and closes selector', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final projectRepository = FakeProjectRepository(
      currentProject: Project(
        id: 'proj_main',
        name: 'Main',
        path: '/repo/main',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      projects: <Project>[
        Project(
          id: 'proj_main',
          name: 'Main',
          path: '/repo/main',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
        Project(
          id: 'proj_ws',
          name: 'Workspace Feature',
          path: '/repo/main/feature-a',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1),
        ),
      ],
    );
    final provider = _buildChatProvider(
      localDataSource: localDataSource,
      projectRepository: projectRepository,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Choose Directory'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Workspace Feature'));
    await tester.pumpAndSettle();

    expect(provider.projectProvider.currentProject?.id, 'proj_ws');
    expect(provider.projectProvider.openProjectIds, contains('proj_ws'));

    await tester.tap(find.byTooltip('Choose Directory'));
    await tester.pumpAndSettle();

    final selectorContent = find.byKey(
      const ValueKey<String>('project_selector_dialog_content'),
    );
    expect(selectorContent, findsOneWidget);

    await tester.tap(
      find.descendant(of: selectorContent, matching: find.text('Main')).first,
    );
    await tester.pumpAndSettle();

    expect(selectorContent, findsNothing);
    expect(provider.projectProvider.currentProject?.id, 'proj_main');
    expect(provider.projectProvider.currentDirectory, '/repo/main');
  });

  testWidgets('shows basename directory and compact controls on mobile', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      localDataSource: localDataSource,
      projectRepository: FakeProjectRepository(
        currentProject: Project(
          id: 'proj_mobile',
          name: 'Project Mobile',
          path: '/repo/mobile-project',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
        projects: <Project>[
          Project(
            id: 'proj_mobile',
            name: 'Project Mobile',
            path: '/repo/mobile-project',
            createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          ),
        ],
      ),
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    expect(find.text('mobile-project'), findsOneWidget);
    expect(find.byTooltip('Focus Input'), findsNothing);

    await tester.tap(find.byTooltip('Choose Directory'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('project_selector_dialog_content')),
      findsOneWidget,
    );
    final mobileDialogSize = tester.getSize(
      find.byKey(const ValueKey<String>('project_selector_dialog_content')),
    );
    // Fullscreen dialog occupies available width minus system padding
    expect(mobileDialogSize.width, closeTo(390, 50));
    expect(
      find.text('Current directory: /repo/mobile-project'),
      findsOneWidget,
    );
  });

  testWidgets('shows global label when current context is root', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      localDataSource: localDataSource,
      projectRepository: FakeProjectRepository(
        currentProject: Project(
          id: 'proj_root',
          name: '/',
          path: '/',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
        projects: <Project>[
          Project(
            id: 'proj_root',
            name: '/',
            path: '/',
            createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          ),
        ],
      ),
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Choose Directory'), findsOneWidget);
    await tester.tap(find.byTooltip('Choose Directory'));
    await tester.pumpAndSettle();
    expect(find.text('Current directory: Global'), findsOneWidget);
  });

  testWidgets('open project folder allows overriding base directory', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final projectRepository = FakeProjectRepository(
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
          id: 'proj_custom',
          name: 'Custom',
          path: '/repo/custom',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1),
        ),
      ],
    );
    final provider = _buildChatProvider(
      localDataSource: localDataSource,
      projectRepository: projectRepository,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Choose Directory'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open project folder...'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('workspace_base_directory_input')),
      '/repo/custom',
    );
    await tester.tap(find.text('Open folder'));
    await tester.pumpAndSettle();

    expect(projectRepository.lastCreatedWorktreeName, isNull);
    expect(projectRepository.lastCreatedWorktreeDirectory, isNull);
    expect(provider.projectProvider.currentDirectory, '/repo/custom');
    expect(find.text('Project context opened: /repo/custom'), findsOneWidget);
  });

  testWidgets('open project folder supports non-git directories', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final projectRepository = FakeProjectRepository(
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
          id: 'proj_plain',
          name: 'Plain Folder',
          path: '/repo/plain',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1),
        ),
      ],
    );
    final provider = _buildChatProvider(
      localDataSource: localDataSource,
      projectRepository: projectRepository,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Choose Directory'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open project folder...'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('workspace_base_directory_input')),
      '/repo/plain',
    );
    await tester.tap(find.text('Open folder'));
    await tester.pumpAndSettle();

    expect(projectRepository.lastCreatedWorktreeName, isNull);
    expect(projectRepository.lastCreatedWorktreeDirectory, isNull);
    expect(provider.projectProvider.currentDirectory, '/repo/plain');
    expect(find.text('Project context opened: /repo/plain'), findsOneWidget);
  });

  testWidgets('open project folder keeps parent and nested directories open', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final projectRepository = FakeProjectRepository(
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
      ],
    );
    final provider = _buildChatProvider(
      localDataSource: localDataSource,
      projectRepository: projectRepository,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Choose Directory'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open project folder...'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('workspace_base_directory_input')),
      '/home/helio',
    );
    await tester.tap(find.text('Open folder'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Choose Directory'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open project folder...'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('workspace_base_directory_input')),
      '/home/helio/MEGA/CONFIG/opencode',
    );
    await tester.tap(find.text('Open folder'));
    await tester.pumpAndSettle();

    expect(
      provider.projectProvider.openProjectIds,
      contains('dir::/home/helio'),
    );
    expect(
      provider.projectProvider.openProjectIds,
      contains('dir::/home/helio/MEGA/CONFIG/opencode'),
    );
    expect(
      find.byKey(const ValueKey<String>('project_group_tile_dir::/home/helio')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>(
          'project_group_tile_dir::/home/helio/MEGA/CONFIG/opencode',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('open project folder Enter submits the chosen directory', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final projectRepository = FakeProjectRepository(
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
          id: 'proj_enter',
          name: 'Enter Directory',
          path: '/repo/enter',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1),
        ),
      ],
    );
    final provider = _buildChatProvider(
      localDataSource: localDataSource,
      projectRepository: projectRepository,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Choose Directory'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open project folder...'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('workspace_base_directory_input')),
      '/repo/enter',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(provider.projectProvider.currentDirectory, '/repo/enter');
    expect(find.text('Project context opened: /repo/enter'), findsOneWidget);
  });

  testWidgets('open project folder shows fuzzy directory suggestions', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final projectRepository = FakeProjectRepository(
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
          id: 'proj_known',
          name: 'Known Feature',
          path: '/repo/a/known-feature',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1),
        ),
      ],
    );
    projectRepository.searchResultsByQuery['feature'] = <FileNode>[
      const FileNode(
        path: '/repo/a/feature-search',
        name: 'feature-search',
        type: FileNodeType.directory,
      ),
    ];
    final provider = _buildChatProvider(
      localDataSource: localDataSource,
      projectRepository: projectRepository,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Choose Directory'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open project folder...'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('workspace_base_directory_input')),
      'feature',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('workspace_directory_suggestions')),
      findsOneWidget,
    );
    expect(find.text('/repo/a/feature-search'), findsOneWidget);
    expect(find.text('/repo/a/known-feature'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'workspace_directory_suggestion_/repo/a/feature-search',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('/repo/a/feature-search'), findsOneWidget);

    await tester.tap(find.text('Open folder'));
    await tester.pumpAndSettle();

    expect(provider.projectProvider.currentDirectory, '/repo/a/feature-search');
  });

  testWidgets('open project folder supports browsing directories dynamically', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final projectRepository = FakeProjectRepository(
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
          id: 'proj_client_app',
          name: 'Client App',
          path: '/repo/a/client/app',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1),
        ),
      ],
    );
    projectRepository.directoriesByPath['/repo/a'] = <String>[
      '/repo/a/client',
      '/repo/a/server',
    ];
    projectRepository.directoriesByPath['/repo/a/client'] = <String>[
      '/repo/a/client/app',
    ];
    final provider = _buildChatProvider(
      localDataSource: localDataSource,
      projectRepository: projectRepository,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Choose Directory'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open project folder...'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey<String>('workspace_open_directory_picker_button'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('directory_picker_sheet')),
      findsOneWidget,
    );
    expect(
      find.text('Choose a folder to open as project context.'),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('directory_picker_item_/repo/a/client'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('directory_picker_item_/repo/a/client/app'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('directory_picker_use_current')),
    );
    await tester.pumpAndSettle();

    final directoryField = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('workspace_base_directory_input')),
    );
    expect(directoryField.controller?.text, '/repo/a/client/app');

    await tester.tap(find.text('Open folder'));
    await tester.pumpAndSettle();

    expect(projectRepository.lastCreatedWorktreeDirectory, isNull);
    expect(provider.projectProvider.currentDirectory, '/repo/a/client/app');
  });

  testWidgets(
    'desktop file explorer expands tree and opens open-files dialog',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final projectRepository = FakeProjectRepository(
        currentProject: Project(
          id: 'proj_files',
          name: 'Project Files',
          path: '/repo/a',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
        projects: <Project>[
          Project(
            id: 'proj_files',
            name: 'Project Files',
            path: '/repo/a',
            createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          ),
        ],
      );
      projectRepository.filesByPath['.'] = const <FileNode>[
        FileNode(
          path: '/repo/a/.github',
          name: '.github',
          type: FileNodeType.directory,
        ),
        FileNode(
          path: '/repo/a/.vscode',
          name: '.vscode',
          type: FileNodeType.directory,
        ),
        FileNode(
          path: '/repo/a/.idea',
          name: '.idea',
          type: FileNodeType.directory,
        ),
        FileNode(
          path: '/repo/a/.dart_tool',
          name: '.dart_tool',
          type: FileNodeType.directory,
        ),
        FileNode(
          path: '/repo/a/android',
          name: 'android',
          type: FileNodeType.directory,
        ),
        FileNode(
          path: '/repo/a/ios',
          name: 'ios',
          type: FileNodeType.directory,
        ),
        FileNode(
          path: '/repo/a/macos',
          name: 'macos',
          type: FileNodeType.directory,
        ),
        FileNode(
          path: '/repo/a/lib',
          name: 'lib',
          type: FileNodeType.directory,
        ),
        FileNode(
          path: '/repo/a/src',
          name: 'src',
          type: FileNodeType.directory,
        ),
        FileNode(
          path: '/repo/a/package.json',
          name: 'package.json',
          type: FileNodeType.file,
        ),
        FileNode(
          path: '/repo/a/README.md',
          name: 'README.md',
          type: FileNodeType.file,
        ),
        FileNode(
          path: '/repo/a/scripts/setup.sh',
          name: 'setup.sh',
          type: FileNodeType.file,
        ),
        FileNode(
          path: '/repo/a/scripts/login.ash',
          name: 'login.ash',
          type: FileNodeType.file,
        ),
        FileNode(
          path: '/repo/a/Jenkinsfile',
          name: 'Jenkinsfile',
          type: FileNodeType.file,
        ),
        FileNode(
          path: '/repo/a/jenkins.yaml',
          name: 'jenkins.yaml',
          type: FileNodeType.file,
        ),
        FileNode(
          path: '/repo/a/vite.config.ts',
          name: 'vite.config.ts',
          type: FileNodeType.file,
        ),
        FileNode(
          path: '/repo/a/vite-env.d.ts',
          name: 'vite-env.d.ts',
          type: FileNodeType.file,
        ),
        FileNode(
          path: '/repo/a/vite.svg',
          name: 'vite.svg',
          type: FileNodeType.file,
        ),
        FileNode(
          path: '/repo/a/id_rsa',
          name: 'id_rsa',
          type: FileNodeType.file,
        ),
        FileNode(
          path: '/repo/a/id_ed25519',
          name: 'id_ed25519',
          type: FileNodeType.file,
        ),
        FileNode(
          path: '/repo/a/dev.pem',
          name: 'dev.pem',
          type: FileNodeType.file,
        ),
        FileNode(
          path: '/repo/a/logo.svg',
          name: 'logo.svg',
          type: FileNodeType.file,
        ),
        FileNode(
          path: '/repo/a/vector.svgz',
          name: 'vector.svgz',
          type: FileNodeType.file,
        ),
        FileNode(
          path: '/repo/a/photo.png',
          name: 'photo.png',
          type: FileNodeType.file,
        ),
        FileNode(
          path: '/repo/a/.env.production',
          name: '.env.production',
          type: FileNodeType.file,
        ),
        FileNode(
          path: '/repo/a/notes.txt',
          name: 'notes.txt',
          type: FileNodeType.file,
        ),
        FileNode(
          path: '/repo/a/data.csv',
          name: 'data.csv',
          type: FileNodeType.file,
        ),
        FileNode(
          path: '/repo/a/data.tsv',
          name: 'data.tsv',
          type: FileNodeType.file,
        ),
      ];
      projectRepository.filesByPath['/repo/a/.github'] = const <FileNode>[
        FileNode(
          path: '/repo/a/.github/workflows',
          name: 'workflows',
          type: FileNodeType.directory,
        ),
      ];
      projectRepository.filesByPath['/repo/a/lib'] = const <FileNode>[
        FileNode(
          path: '/repo/a/lib/main.dart',
          name: 'main.dart',
          type: FileNodeType.file,
        ),
      ];
      projectRepository.filesByPath['/repo/a/src'] = const <FileNode>[
        FileNode(
          path: '/repo/a/src/App.vue',
          name: 'App.vue',
          type: FileNodeType.file,
        ),
      ];
      projectRepository.fileContentsByPath['/repo/a/lib/main.dart'] =
          const FileContent(
            path: '/repo/a/lib/main.dart',
            content: 'void main() => print("ok");',
            isBinary: false,
          );

      final provider = _buildChatProvider(
        localDataSource: localDataSource,
        projectRepository: projectRepository,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('file_tree_list')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/package.json'),
          ),
          matching: find.byIcon(SimpleIcons.npm),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/.github'),
          ),
          matching: find.byIcon(SimpleIcons.github),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/.idea'),
          ),
          matching: find.byIcon(SimpleIcons.jetbrains),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/.dart_tool'),
          ),
          matching: find.byIcon(SimpleIcons.dart),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/android'),
          ),
          matching: find.byIcon(SimpleIcons.android),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('file_tree_item_/repo/a/ios')),
          matching: find.byIcon(SimpleIcons.ios),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/macos'),
          ),
          matching: find.byIcon(SimpleIcons.macos),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/.vscode'),
          ),
          matching: find.byIcon(SimpleIcons.vscodium),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/scripts/setup.sh'),
          ),
          matching: find.byIcon(SimpleIcons.iterm2),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/scripts/login.ash'),
          ),
          matching: find.byIcon(SimpleIcons.iterm2),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/Jenkinsfile'),
          ),
          matching: find.byIcon(SimpleIcons.jenkins),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/jenkins.yaml'),
          ),
          matching: find.byIcon(SimpleIcons.jenkins),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/vite.config.ts'),
          ),
          matching: find.byIcon(SimpleIcons.vite),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/vite-env.d.ts'),
          ),
          matching: find.byIcon(SimpleIcons.vite),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/id_rsa'),
          ),
          matching: find.byIcon(SimpleIcons.passbolt),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/id_ed25519'),
          ),
          matching: find.byIcon(SimpleIcons.passbolt),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/dev.pem'),
          ),
          matching: find.byIcon(SimpleIcons.passbolt),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/logo.svg'),
          ),
          matching: find.byIcon(SimpleIcons.svg),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/vector.svgz'),
          ),
          matching: find.byIcon(SimpleIcons.inkscape),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/photo.png'),
          ),
          matching: find.byIcon(SimpleIcons.googlephotos),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/.env.production'),
          ),
          matching: find.byIcon(SimpleIcons.dotenv),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/notes.txt'),
          ),
          matching: find.byIcon(Symbols.article),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/data.csv'),
          ),
          matching: find.byIcon(Symbols.table_chart),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/data.tsv'),
          ),
          matching: find.byIcon(Symbols.table_rows),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('file_tree_item_/repo/a/.github')),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/.github/workflows'),
          ),
          matching: find.byIcon(SimpleIcons.githubactions),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('file_tree_item_/repo/a/src')),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('file_tree_item_/repo/a/src/App.vue'),
          ),
          matching: find.byIcon(SimpleIcons.vuedotjs),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('file_tree_item_/repo/a/lib')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey<String>('file_tree_item_/repo/a/lib/main.dart'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('open_files_dialog_centered')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('open_files_dialog_centered')),
          matching: find.text(
            'void main() => print("ok");',
            findRichText: true,
          ),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('desktop open files button opens centered dialog with tabs', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1300, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final projectRepository = FakeProjectRepository(
      currentProject: Project(
        id: 'proj_tabs_desktop',
        name: 'Project Tabs Desktop',
        path: '/repo/a',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      projects: <Project>[
        Project(
          id: 'proj_tabs_desktop',
          name: 'Project Tabs Desktop',
          path: '/repo/a',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      ],
    );
    projectRepository.filesByPath['.'] = const <FileNode>[
      FileNode(
        path: '/repo/a/lib/main.dart',
        name: 'main.dart',
        type: FileNodeType.file,
      ),
    ];
    projectRepository.fileContentsByPath['/repo/a/lib/main.dart'] =
        const FileContent(
          path: '/repo/a/lib/main.dart',
          content: 'void desktopTabs() {}',
          isBinary: false,
        );

    final provider = _buildChatProvider(
      localDataSource: localDataSource,
      projectRepository: projectRepository,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey<String>('file_tree_item_/repo/a/lib/main.dart'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey<String>('open_files_dialog_centered')),
        matching: find.byTooltip('Close'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('file_tree_open_files_button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('open_files_dialog_centered')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('open_files_dialog_centered')),
        matching: find.byKey(
          const ValueKey<String>('file_viewer_tab_/repo/a/lib/main.dart'),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'file viewer fallback retries relative path when absolute result is empty',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final projectRepository = FakeProjectRepository(
        currentProject: Project(
          id: 'proj_files_fallback',
          name: 'Project Files Fallback',
          path: '/repo/a',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
        projects: <Project>[
          Project(
            id: 'proj_files_fallback',
            name: 'Project Files Fallback',
            path: '/repo/a',
            createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          ),
        ],
      );
      projectRepository.filesByPath['.'] = const <FileNode>[
        FileNode(
          path: '/repo/a/lib/main.dart',
          name: 'main.dart',
          type: FileNodeType.file,
        ),
      ];
      projectRepository.fileContentsByPath['lib/main.dart'] = const FileContent(
        path: 'lib/main.dart',
        content: 'void fallbackPath() {}',
        isBinary: false,
      );

      final provider = _buildChatProvider(
        localDataSource: localDataSource,
        projectRepository: projectRepository,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>('file_tree_item_/repo/a/lib/main.dart'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('open_files_dialog_centered')),
          matching: find.text('void fallbackPath() {}', findRichText: true),
        ),
        findsOneWidget,
      );
      expect(find.text('File is empty.'), findsNothing);
    },
  );

  testWidgets('quick open finds file and opens open-files dialog', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1300, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final projectRepository = FakeProjectRepository(
      currentProject: Project(
        id: 'proj_search',
        name: 'Project Search',
        path: '/repo/a',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      projects: <Project>[
        Project(
          id: 'proj_search',
          name: 'Project Search',
          path: '/repo/a',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      ],
    );
    projectRepository.searchResultsByQuery['chat'] = const <FileNode>[
      FileNode(
        path: '/repo/a/lib/chat_provider.dart',
        name: 'chat_provider.dart',
        type: FileNodeType.file,
      ),
      FileNode(
        path: '/repo/a/docs/chat.md',
        name: 'chat.md',
        type: FileNodeType.file,
      ),
    ];
    projectRepository.fileContentsByPath['/repo/a/docs/chat.md'] =
        const FileContent(
          path: '/repo/a/docs/chat.md',
          content: '# Chat Docs',
          isBinary: false,
        );
    projectRepository.fileContentsByPath['/repo/a/lib/chat_provider.dart'] =
        const FileContent(
          path: '/repo/a/lib/chat_provider.dart',
          content: 'class ChatProvider {}',
          isBinary: false,
        );

    final provider = _buildChatProvider(
      localDataSource: localDataSource,
      projectRepository: projectRepository,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('file_tree_quick_open_button')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('quick_open_input')),
      'chat',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'quick_open_result_/repo/a/lib/chat_provider.dart',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('open_files_dialog_centered')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('open_files_dialog_centered')),
        matching: find.text('class ChatProvider {}', findRichText: true),
      ),
      findsOneWidget,
    );
  });

  testWidgets('quick open Enter opens the first visible result', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1300, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final projectRepository = FakeProjectRepository(
      currentProject: Project(
        id: 'proj_search_enter',
        name: 'Project Search Enter',
        path: '/repo/a',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      projects: <Project>[
        Project(
          id: 'proj_search_enter',
          name: 'Project Search Enter',
          path: '/repo/a',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      ],
    );
    projectRepository.searchResultsByQuery['chat'] = const <FileNode>[
      FileNode(
        path: '/repo/a/lib/chat_provider.dart',
        name: 'chat_provider.dart',
        type: FileNodeType.file,
      ),
      FileNode(
        path: '/repo/a/docs/chat.md',
        name: 'chat.md',
        type: FileNodeType.file,
      ),
    ];
    projectRepository.fileContentsByPath['/repo/a/docs/chat.md'] =
        const FileContent(
          path: '/repo/a/docs/chat.md',
          content: '# Chat Docs',
          isBinary: false,
        );
    projectRepository.fileContentsByPath['/repo/a/lib/chat_provider.dart'] =
        const FileContent(
          path: '/repo/a/lib/chat_provider.dart',
          content: 'class ChatProvider {}',
          isBinary: false,
        );

    final provider = _buildChatProvider(
      localDataSource: localDataSource,
      projectRepository: projectRepository,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('file_tree_quick_open_button')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('quick_open_input')),
      'chat',
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('open_files_dialog_centered')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('open_files_dialog_centered')),
        matching: find.text('# Chat Docs', findRichText: true),
      ),
      findsOneWidget,
    );
  });

  testWidgets('mobile open files button opens fullscreen tab dialog', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final projectRepository = FakeProjectRepository(
      currentProject: Project(
        id: 'proj_tabs_mobile',
        name: 'Project Tabs Mobile',
        path: '/repo/a',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      projects: <Project>[
        Project(
          id: 'proj_tabs_mobile',
          name: 'Project Tabs Mobile',
          path: '/repo/a',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      ],
    );
    projectRepository.filesByPath['.'] = const <FileNode>[
      FileNode(
        path: '/repo/a/lib/mobile.dart',
        name: 'mobile.dart',
        type: FileNodeType.file,
      ),
    ];
    projectRepository.searchResultsByQuery['mobile'] = const <FileNode>[
      FileNode(
        path: '/repo/a/lib/mobile.dart',
        name: 'mobile.dart',
        type: FileNodeType.file,
      ),
    ];
    projectRepository.fileContentsByPath['/repo/a/lib/mobile.dart'] =
        const FileContent(
          path: '/repo/a/lib/mobile.dart',
          content: 'void mobileTabs() {}',
          isBinary: false,
        );

    final provider = _buildChatProvider(
      localDataSource: localDataSource,
      projectRepository: projectRepository,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    final newChatX = tester.getCenter(find.byTooltip('New Chat').first).dx;
    final openFilesX = tester.getCenter(find.byTooltip('Open Files')).dx;
    expect(newChatX, greaterThan(openFilesX));

    final refreshFinder = find.byTooltip('Refresh');
    if (refreshFinder.evaluate().isNotEmpty) {
      final refreshX = tester.getCenter(refreshFinder.first).dx;
      expect(newChatX, greaterThan(refreshX));
    }

    await tester.tap(
      find.byKey(const ValueKey<String>('appbar_quick_open_button')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('file_tree_quick_open_button')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('quick_open_input')),
      'mobile',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('quick_open_result_/repo/a/lib/mobile.dart'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('open_files_dialog_fullscreen')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('open_files_dialog_fullscreen')),
        matching: find.text('void mobileTabs() {}', findRichText: true),
      ),
      findsOneWidget,
    );
  });

  testWidgets('context usage knob shows compact value and popover metrics', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_context_usage',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Context Usage',
        ),
      ],
    );
    repository.messagesBySession['ses_context_usage'] = <ChatMessage>[
      AssistantMessage(
        id: 'msg_context_usage',
        sessionId: 'ses_context_usage',
        time: DateTime.fromMillisecondsSinceEpoch(1100),
        completedTime: DateTime.fromMillisecondsSinceEpoch(1200),
        providerId: 'provider_1',
        modelId: 'model_1',
        cost: 0,
        tokens: const MessageTokens(
          input: 200,
          output: 50,
          reasoning: 25,
          cacheRead: 25,
          cacheWrite: 0,
        ),
        parts: const <MessagePart>[
          TextPart(
            id: 'part_context_usage',
            messageId: 'msg_context_usage',
            sessionId: 'ses_context_usage',
            text: 'Done',
          ),
        ],
      ),
    ];

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('appbar_context_usage_button')),
        matching: find.text('30'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('appbar_context_usage_button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('context_usage_popover')),
      findsOneWidget,
    );
    expect(find.text('Usage'), findsOneWidget);
    expect(find.text('Tokens'), findsOneWidget);
    expect(find.text('Cost'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
    expect(find.text(r'$0.0000'), findsOneWidget);
  });

  testWidgets('context usage popover shows quota groups after compact action', (
    WidgetTester tester,
  ) async {
    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_quota_usage',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Quota Session',
        ),
      ],
    );
    repository.messagesBySession['ses_quota_usage'] = <ChatMessage>[
      AssistantMessage(
        id: 'msg_quota_usage',
        sessionId: 'ses_quota_usage',
        time: DateTime.fromMillisecondsSinceEpoch(1100),
        providerId: 'provider_1',
        modelId: 'model_1',
        cost: 0,
        tokens: const MessageTokens(
          input: 100,
          output: 100,
          reasoning: 50,
          cacheRead: 50,
          cacheWrite: 0,
        ),
        parts: const <MessagePart>[
          TextPart(
            id: 'part_quota_usage',
            messageId: 'msg_quota_usage',
            sessionId: 'ses_quota_usage',
            text: 'Done',
          ),
        ],
      ),
    ];

    final quotaDataSource = FakeQuotaRemoteDataSource(
      results: <QuotaProviderResult>[
        QuotaProviderResult.fromJson(<String, dynamic>{
          'providerId': 'claude',
          'providerName': 'Claude',
          'ok': true,
          'configured': true,
          'usage': <String, dynamic>{
            'windows': <String, dynamic>{
              '5h': <String, dynamic>{
                'usedPercent': 42,
                'remainingPercent': 58,
                'windowSeconds': 18000,
                'resetAt': DateTime.now()
                    .add(const Duration(hours: 2))
                    .millisecondsSinceEpoch,
              },
              '7d': <String, dynamic>{
                'usedPercent': 18,
                'remainingPercent': 82,
                'windowSeconds': 604800,
                'resetAt': DateTime.now()
                    .add(const Duration(days: 4))
                    .millisecondsSinceEpoch,
              },
            },
          },
          'fetchedAt': DateTime.now().millisecondsSinceEpoch,
        }),
        QuotaProviderResult.fromJson(<String, dynamic>{
          'providerId': 'openrouter',
          'providerName': 'OpenRouter',
          'ok': true,
          'configured': true,
          'usage': <String, dynamic>{
            'windows': <String, dynamic>{
              'credits': <String, dynamic>{
                'usedPercent': 63,
                'remainingPercent': 37,
                'valueLabel': '\$12.00 remaining',
              },
            },
          },
          'fetchedAt': DateTime.now().millisecondsSinceEpoch,
        }),
      ],
    );

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(
      _testApp(provider, appProvider, quotaRemoteDataSource: quotaDataSource),
    );
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('appbar_context_usage_button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Compact now'), findsOneWidget);
    expect(find.text('Rate limits'), findsOneWidget);
    expect(find.text('Claude'), findsOneWidget);
    expect(find.text('OpenRouter'), findsOneWidget);

    await tester.tap(find.text('Claude'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('5-Hour'), findsOneWidget);
    expect(find.text('7-Day Limit'), findsOneWidget);
    expect(find.textContaining('Pace '), findsWidgets);
  });

  testWidgets('file viewer shows binary and error states', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1300, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final projectRepository = FakeProjectRepository(
      currentProject: Project(
        id: 'proj_binary',
        name: 'Project Binary',
        path: '/repo/a',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      projects: <Project>[
        Project(
          id: 'proj_binary',
          name: 'Project Binary',
          path: '/repo/a',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      ],
    );
    projectRepository.filesByPath['.'] = const <FileNode>[
      FileNode(
        path: '/repo/a/assets/logo.png',
        name: 'logo.png',
        type: FileNodeType.file,
      ),
      FileNode(
        path: '/repo/a/lib/error.dart',
        name: 'error.dart',
        type: FileNodeType.file,
      ),
    ];
    projectRepository.fileContentsByPath['/repo/a/assets/logo.png'] =
        const FileContent(
          path: '/repo/a/assets/logo.png',
          content: '',
          isBinary: true,
          mimeType: 'image/png',
        );

    final provider = _buildChatProvider(
      localDataSource: localDataSource,
      projectRepository: projectRepository,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey<String>('file_tree_item_/repo/a/assets/logo.png'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('open_files_dialog_centered')),
        matching: find.text('Binary file preview is not available.'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey<String>('open_files_dialog_centered')),
        matching: find.byTooltip('Close'),
      ),
    );
    await tester.pumpAndSettle();

    projectRepository.fileContentFailure = const ServerFailure(
      'forced read failure',
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('file_tree_item_/repo/a/lib/error.dart'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('open_files_dialog_centered')),
        matching: find.byKey(
          const ValueKey<String>('file_viewer_retry_button'),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('open_files_dialog_centered')),
        matching: find.textContaining('Failed to read file'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('sends message from chat input and renders assistant response', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_1',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Session 1',
        ),
      ],
    );

    repository.sendMessageHandler = (_, sessionId, _, _) {
      final reply = AssistantMessage(
        id: 'msg_assistant_widget',
        sessionId: sessionId,
        time: DateTime.fromMillisecondsSinceEpoch(2000),
        completedTime: DateTime.fromMillisecondsSinceEpoch(2200),
        parts: const <MessagePart>[
          TextPart(
            id: 'prt_widget_reply',
            messageId: 'msg_assistant_widget',
            sessionId: 'ses_1',
            text: 'ok from widget',
          ),
        ],
      );
      return Stream<Either<Failure, ChatMessage>>.value(Right(reply));
    };

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pump(const Duration(milliseconds: 150));

    await provider.loadSessions();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Session 1').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'hello from widget');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Symbols.send_rounded));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.lastSendInput, isNotNull);
    expect(find.text('hello from widget'), findsOneWidget);
    expect(find.text('ok from widget'), findsOneWidget);
  });

  testWidgets(
    'refreshes active session on reconnect and keeps no manual 5s polling',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_refresh',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Refresh Session',
          ),
        ],
      );
      repository.messagesBySession['ses_refresh'] = <ChatMessage>[
        AssistantMessage(
          id: 'msg_refresh_1',
          sessionId: 'ses_refresh',
          time: DateTime.fromMillisecondsSinceEpoch(2000),
          completedTime: DateTime.fromMillisecondsSinceEpoch(2200),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_refresh_1',
              messageId: 'msg_refresh_1',
              sessionId: 'ses_refresh',
              text: 'initial',
            ),
          ],
        ),
      ];
      final appRepository = FakeAppRepository();

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..experienceSettingsJson = jsonEncode(<String, dynamic>{
          'checkUpdatesOnOpen': false,
          'composerAutoApprovePermissions': false,
        });
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(
        localDataSource: localDataSource,
        appRepository: appRepository,
      );

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.initializeProviders();
      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await tester.pumpAndSettle();

      final baseMessageCalls = repository.getMessagesCallCount;
      final baseStatusCalls = repository.getSessionStatusCallCount;

      appRepository.checkConnectionResult = const Right(false);
      await appProvider.checkConnection();
      await tester.pumpAndSettle();

      appRepository.checkConnectionResult = const Right(true);
      await appProvider.checkConnection();
      await tester.pumpAndSettle();

      expect(repository.getMessagesCallCount, greaterThan(baseMessageCalls));
      expect(
        repository.getSessionStatusCallCount,
        greaterThan(baseStatusCalls),
      );

      final reconnectMessageCalls = repository.getMessagesCallCount;
      final reconnectStatusCalls = repository.getSessionStatusCallCount;

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(repository.getMessagesCallCount, reconnectMessageCalls);
      expect(repository.getSessionStatusCallCount, reconnectStatusCalls);
    },
  );

  testWidgets(
    'offline startup reloads projects and sessions automatically once reconnected',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final project = Project(
        id: 'proj_recovery',
        name: 'Recovery Project',
        path: '/repo/recovery',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
      final projectRepository =
          FakeProjectRepository(
              currentProject: project,
              projects: <Project>[project],
            )
            ..getProjectsFailure = const NetworkFailure('offline')
            ..currentProjectFailure = const NetworkFailure('offline');
      final chatRepository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_recovery',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Recovered Session',
          ),
        ],
      )..getSessionsFailure = const NetworkFailure('offline');
      final appRepository = FakeAppRepository()
        ..checkConnectionResult = const Right(false);
      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: chatRepository,
        projectRepository: projectRepository,
        appRepository: appRepository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(
        localDataSource: localDataSource,
        appRepository: appRepository,
      );

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      final startupProjectCalls = projectRepository.getProjectsCallCount;
      final startupSessionCalls = chatRepository.getSessionsCallCount;
      expect(provider.projectProvider.currentProject, isNull);
      expect(provider.projectProvider.status, ProjectStatus.error);
      expect(provider.state, ChatState.error);

      projectRepository.getProjectsFailure = null;
      projectRepository.currentProjectFailure = null;
      chatRepository.getSessionsFailure = null;
      appRepository.checkConnectionResult = const Right(true);

      await appProvider.checkConnection();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(
        projectRepository.getProjectsCallCount,
        greaterThan(startupProjectCalls),
      );
      expect(
        chatRepository.getSessionsCallCount,
        greaterThan(startupSessionCalls),
      );
      expect(provider.projectProvider.currentProject?.id, 'proj_recovery');
      expect(provider.projectProvider.status, ProjectStatus.loaded);
      expect(
        provider.sessions.map((item) => item.id),
        contains('ses_recovery'),
      );
      expect(provider.state, ChatState.loaded);
    },
  );

  testWidgets(
    'health recovery retries initial data reload until connection succeeds',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final project = Project(
        id: 'proj_health_retry',
        name: 'Retry Project',
        path: '/repo/health-retry',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
      final projectRepository =
          FakeProjectRepository(
              currentProject: project,
              projects: <Project>[project],
            )
            ..getProjectsFailure = const NetworkFailure('offline')
            ..currentProjectFailure = const NetworkFailure('offline');
      final chatRepository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_health_retry',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Retry Session',
          ),
        ],
      )..getSessionsFailure = const NetworkFailure('offline');
      final appRepository = FakeAppRepository()
        ..checkConnectionResult = const Right(false);
      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: chatRepository,
        projectRepository: projectRepository,
        appRepository: appRepository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(
        localDataSource: localDataSource,
        appRepository: appRepository,
      );

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      final startupProjectCalls = projectRepository.getProjectsCallCount;
      projectRepository.getProjectsFailure = null;
      projectRepository.currentProjectFailure = null;
      chatRepository.getSessionsFailure = null;

      appProvider.setHealthForTesting('srv_test', ServerHealthStatus.healthy);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();

      expect(projectRepository.getProjectsCallCount, startupProjectCalls);
      expect(provider.projectProvider.currentProject, isNull);

      appRepository.checkConnectionResult = const Right(true);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(
        projectRepository.getProjectsCallCount,
        greaterThan(startupProjectCalls),
      );
      expect(provider.projectProvider.currentProject?.id, 'proj_health_retry');
      expect(
        provider.sessions.map((item) => item.id),
        contains('ses_health_retry'),
      );
    },
  );

  testWidgets(
    'offline-start reconnect flapping collapses to a single recovery reload',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final project = Project(
        id: 'proj_flap',
        name: 'Flap Project',
        path: '/repo/flap',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
      final projectRepository =
          FakeProjectRepository(
              currentProject: project,
              projects: <Project>[project],
            )
            ..getProjectsFailure = const NetworkFailure('offline')
            ..currentProjectFailure = const NetworkFailure('offline');
      final chatRepository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_flap',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Flap Session',
          ),
        ],
      )..getSessionsFailure = const NetworkFailure('offline');
      final appRepository = FakeAppRepository()
        ..checkConnectionResult = const Right(false);
      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: chatRepository,
        projectRepository: projectRepository,
        appRepository: appRepository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(
        localDataSource: localDataSource,
        appRepository: appRepository,
      );

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      final startupProjectCalls = projectRepository.getProjectsCallCount;
      final startupSessionCalls = chatRepository.getSessionsCallCount;
      projectRepository.getProjectsFailure = null;
      projectRepository.currentProjectFailure = null;
      chatRepository.getSessionsFailure = null;

      appRepository.checkConnectionResult = const Right(true);
      await appProvider.checkConnection();
      await tester.pump();

      appRepository.checkConnectionResult = const Right(false);
      await appProvider.checkConnection();
      await tester.pump();

      appRepository.checkConnectionResult = const Right(true);
      await appProvider.checkConnection();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(projectRepository.getProjectsCallCount, startupProjectCalls + 1);
      expect(chatRepository.getSessionsCallCount, startupSessionCalls + 1);
      expect(provider.projectProvider.currentProject?.id, 'proj_flap');
      expect(provider.sessions.map((item) => item.id), contains('ses_flap'));
    },
  );

  testWidgets(
    'mobile long-press on user message bubble pre-fills composer input',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_mobile_hold',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Mobile Hold Session',
          ),
        ],
      );
      repository.messagesBySession['ses_mobile_hold'] = <ChatMessage>[
        UserMessage(
          id: 'msg_user_hold',
          sessionId: 'ses_mobile_hold',
          time: DateTime.fromMillisecondsSinceEpoch(1200),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_user_hold',
              messageId: 'msg_user_hold',
              sessionId: 'ses_mobile_hold',
              text: 'reusar esse prompt',
            ),
          ],
        ),
      ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await tester.pumpAndSettle();

      final backgroundHoldListenerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Listener &&
            widget.behavior == HitTestBehavior.opaque &&
            widget.onPointerDown != null &&
            widget.onPointerMove != null,
      );
      expect(backgroundHoldListenerFinder, findsWidgets);

      final listener = tester.widget<Listener>(
        backgroundHoldListenerFinder.first,
      );
      listener.onPointerDown?.call(
        const PointerDownEvent(pointer: 1, position: Offset.zero),
      );
      await tester.pump(const Duration(milliseconds: 350));
      final chatInputFieldFinder = find.descendant(
        of: find.byKey(const ValueKey<String>('composer_input_row')),
        matching: find.byType(TextField),
      );
      var inputField = tester.widget<TextField>(chatInputFieldFinder);
      expect(inputField.controller!.text, 'reusar esse prompt');
      expect(
        inputField.focusNode?.hasFocus,
        isFalse,
        reason: 'Input must stay unfocused until finger is released',
      );

      listener.onPointerUp?.call(
        const PointerUpEvent(pointer: 1, position: Offset.zero),
      );
      await tester.pumpAndSettle();

      inputField = tester.widget<TextField>(chatInputFieldFinder);
      expect(inputField.controller!.text, 'reusar esse prompt');
      expect(inputField.focusNode?.hasFocus, isTrue);
    },
  );

  testWidgets('hides refresh actions in refreshless mode', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository();
    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Refresh'), findsNothing);
    expect(find.text('Refresh'), findsNothing);
  });

  testWidgets('rejects question request from chat interaction card', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_1',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Session 1',
        ),
      ],
    );
    repository.pendingQuestions = const <ChatQuestionRequest>[
      ChatQuestionRequest(
        id: 'q_widget_reject_1',
        sessionId: 'ses_1',
        questions: <ChatQuestionInfo>[
          ChatQuestionInfo(
            question: 'Proceed?',
            header: 'Confirm',
            options: <ChatQuestionOption>[
              ChatQuestionOption(label: 'Yes', description: 'Continue'),
              ChatQuestionOption(label: 'No', description: 'Stop'),
            ],
          ),
        ],
      ),
    ];

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.initializeProviders();
    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pumpAndSettle();

    expect(find.text('Review Answers'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);

    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();

    expect(find.text('Reopen'), findsOneWidget);
    expect(find.text('Confirm Reject'), findsOneWidget);
    expect(
      find.textContaining('Question group marked as rejected'),
      findsOneWidget,
    );

    await tester.tap(find.text('Confirm Reject'));
    await tester.pumpAndSettle();

    expect(repository.lastQuestionRejectRequestId, 'q_widget_reject_1');
    expect(find.text('Review Answers'), findsNothing);
  });

  testWidgets(
    'auto-approves mirrored subagent permissions when composer toggle is enabled',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_root_auto',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Root Session',
          ),
          ChatSession(
            id: 'ses_sub_auto',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(900),
            title: 'Sub Session',
            parentId: 'ses_root_auto',
          ),
        ],
      );
      repository.messagesBySession['ses_root_auto'] = <ChatMessage>[
        UserMessage(
          id: 'msg_root_auto_1',
          sessionId: 'ses_root_auto',
          time: DateTime.fromMillisecondsSinceEpoch(1200),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_root_auto_1',
              messageId: 'msg_root_auto_1',
              sessionId: 'ses_root_auto',
              text: 'Auto approve permissions',
            ),
          ],
        ),
      ];
      repository.pendingPermissions = const <ChatPermissionRequest>[
        ChatPermissionRequest(
          id: 'perm_auto_sub_1',
          sessionId: 'ses_sub_auto',
          permission: 'bash',
          patterns: <String>['*'],
          always: <String>[],
          metadata: <String, dynamic>{},
        ),
      ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.initializeProviders();
      await provider.loadSessions();
      await provider.selectSession(
        provider.sessions
            .where((session) => session.id == 'ses_root_auto')
            .first,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('composer_permission_auto_approve_toggle'),
        ),
        findsOneWidget,
      );
      expect(repository.lastPermissionRequestId, 'perm_auto_sub_1');
      expect(repository.lastPermissionReply, 'once');
      expect(
        find.byKey(
          const ValueKey<String>(
            'interaction_permission_request_perm_auto_sub_1',
          ),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('timeline_permission_request_perm_auto_sub_1'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'auto-approves permissions with always when the request exposes remembered approval',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_root_auto_always',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Root Session',
          ),
          ChatSession(
            id: 'ses_sub_auto_always',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(900),
            title: 'Sub Session',
            parentId: 'ses_root_auto_always',
          ),
        ],
      );
      repository.messagesBySession['ses_root_auto_always'] = <ChatMessage>[
        UserMessage(
          id: 'msg_root_auto_always_1',
          sessionId: 'ses_root_auto_always',
          time: DateTime.fromMillisecondsSinceEpoch(1200),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_root_auto_always_1',
              messageId: 'msg_root_auto_always_1',
              sessionId: 'ses_root_auto_always',
              text: 'Remember approvals when allowed',
            ),
          ],
        ),
      ];
      repository.pendingPermissions = const <ChatPermissionRequest>[
        ChatPermissionRequest(
          id: 'perm_auto_always_1',
          sessionId: 'ses_sub_auto_always',
          permission: 'bash',
          patterns: <String>['*'],
          always: <String>['*'],
          metadata: <String, dynamic>{},
        ),
      ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.initializeProviders();
      await provider.loadSessions();
      await provider.selectSession(
        provider.sessions
            .where((session) => session.id == 'ses_root_auto_always')
            .first,
      );
      await tester.pumpAndSettle();

      expect(repository.lastPermissionRequestId, 'perm_auto_always_1');
      expect(repository.lastPermissionReply, 'always');
    },
  );

  testWidgets(
    'restores persisted composer drafts per session when switching conversations',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_draft_one',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Draft One',
          ),
          ChatSession(
            id: 'ses_draft_two',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(900),
            title: 'Draft Two',
          ),
        ],
      );
      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.initializeProviders();
      await provider.loadSessions();
      await provider.selectSession(
        provider.sessions
            .where((session) => session.id == 'ses_draft_one')
            .first,
      );
      await tester.pumpAndSettle();

      final inputFinder = find.descendant(
        of: find.byKey(const ValueKey<String>('composer_input_row')),
        matching: find.byType(TextField),
      );

      await tester.enterText(inputFinder, 'draft for first session');
      await tester.pump(const Duration(milliseconds: 320));
      await tester.pumpAndSettle();

      await provider.selectSession(
        provider.sessions
            .where((session) => session.id == 'ses_draft_two')
            .first,
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(inputFinder).controller?.text ?? '',
        isEmpty,
      );

      await tester.enterText(inputFinder, 'draft for second session');
      await tester.pump(const Duration(milliseconds: 320));
      await tester.pumpAndSettle();

      await provider.selectSession(
        provider.sessions
            .where((session) => session.id == 'ses_draft_one')
            .first,
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(inputFinder).controller?.text,
        'draft for first session',
      );

      await provider.selectSession(
        provider.sessions
            .where((session) => session.id == 'ses_draft_two')
            .first,
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(inputFinder).controller?.text,
        'draft for second session',
      );
    },
  );

  testWidgets(
    'keeps permission manual when composer auto-approve is persisted off',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_root_manual',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Root Session',
          ),
        ],
      );
      repository.messagesBySession['ses_root_manual'] = <ChatMessage>[
        UserMessage(
          id: 'msg_root_manual_1',
          sessionId: 'ses_root_manual',
          time: DateTime.fromMillisecondsSinceEpoch(1200),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_root_manual_1',
              messageId: 'msg_root_manual_1',
              sessionId: 'ses_root_manual',
              text: 'Permission needs approval',
            ),
          ],
        ),
      ];
      repository.pendingPermissions = const <ChatPermissionRequest>[
        ChatPermissionRequest(
          id: 'perm_manual_1',
          sessionId: 'ses_root_manual',
          permission: 'edit',
          patterns: <String>['lib/**'],
          always: <String>[],
          metadata: <String, dynamic>{},
        ),
      ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..experienceSettingsJson = jsonEncode(<String, dynamic>{
          'checkUpdatesOnOpen': false,
          'composerAutoApprovePermissions': false,
        });
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.initializeProviders();
      await provider.loadSessions();
      await provider.selectSession(
        provider.sessions
            .where((session) => session.id == 'ses_root_manual')
            .first,
      );
      await tester.pumpAndSettle();

      expect(repository.lastPermissionRequestId, isNull);
      expect(
        find.byKey(
          const ValueKey<String>(
            'interaction_permission_request_perm_manual_1',
          ),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('composer_permission_auto_approve_toggle'),
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.lastPermissionRequestId, 'perm_manual_1');
      expect(repository.lastPermissionReply, 'once');
      expect(
        find.byKey(
          const ValueKey<String>(
            'interaction_permission_request_perm_manual_1',
          ),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'does not auto-answer questions when composer auto-approve is enabled',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_root_question_auto',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Root Session',
          ),
        ],
      );
      repository.pendingQuestions = const <ChatQuestionRequest>[
        ChatQuestionRequest(
          id: 'q_auto_1',
          sessionId: 'ses_root_question_auto',
          questions: <ChatQuestionInfo>[
            ChatQuestionInfo(
              question: 'Choose a mode',
              header: 'Mode',
              options: <ChatQuestionOption>[
                ChatQuestionOption(label: 'Safe', description: 'Be careful'),
                ChatQuestionOption(label: 'Fast', description: 'Go quickly'),
              ],
            ),
          ],
        ),
      ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.initializeProviders();
      await provider.loadSessions();
      await provider.selectSession(
        provider.sessions
            .where((session) => session.id == 'ses_root_question_auto')
            .first,
      );
      await tester.pumpAndSettle();

      expect(repository.lastQuestionReplyRequestId, isNull);
      expect(repository.lastQuestionRejectRequestId, isNull);
      expect(
        find.byKey(
          const ValueKey<String>('interaction_question_request_q_auto_1'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'toggling auto-approve with no pending permissions keeps the viewport stable',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const sessionId = 'ses_toggle_no_pending';
      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: sessionId,
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Toggle No Pending',
          ),
        ],
      );
      final messages = <ChatMessage>[];
      for (var index = 0; index < 18; index += 1) {
        final userId = 'msg_toggle_user_$index';
        messages.add(
          UserMessage(
            id: userId,
            sessionId: sessionId,
            time: DateTime.fromMillisecondsSinceEpoch(1000 + (index * 2000)),
            parts: <MessagePart>[
              TextPart(
                id: 'part_$userId',
                messageId: userId,
                sessionId: sessionId,
                text: index == 8 ? 'older user marker' : 'user message $index',
              ),
            ],
          ),
        );
        final assistantId = 'msg_toggle_assistant_$index';
        messages.add(
          AssistantMessage(
            id: assistantId,
            sessionId: sessionId,
            time: DateTime.fromMillisecondsSinceEpoch(2000 + (index * 2000)),
            completedTime: DateTime.fromMillisecondsSinceEpoch(
              2100 + (index * 2000),
            ),
            parts: <MessagePart>[
              TextPart(
                id: 'part_$assistantId',
                messageId: assistantId,
                sessionId: sessionId,
                text: 'assistant message $index',
              ),
            ],
          ),
        );
      }
      messages.add(
        UserMessage(
          id: 'msg_toggle_tail_user',
          sessionId: sessionId,
          time: DateTime.fromMillisecondsSinceEpoch(50000),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_toggle_tail_user',
              messageId: 'msg_toggle_tail_user',
              sessionId: sessionId,
              text: 'tail user awaiting the next response',
            ),
          ],
        ),
      );
      repository.messagesBySession[sessionId] = messages;

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.initializeProviders();
      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await tester.pumpAndSettle();

      final listFinder = find.byKey(
        const ValueKey<String>('chat_message_list'),
      );
      final scrollableFinder = find
          .descendant(of: listFinder, matching: find.byType(Scrollable))
          .first;

      double distanceToBottom() {
        final position = tester
            .state<ScrollableState>(scrollableFinder)
            .position;
        return position.maxScrollExtent - position.pixels;
      }

      final messageCallsBeforeToggle = repository.getMessagesCallCount;
      final sessionCallsBeforeToggle = repository.getSessionsCallCount;
      final statusCallsBeforeToggle = repository.getSessionStatusCallCount;
      final distanceBeforeToggle = distanceToBottom();

      expect(find.text('older user marker'), findsNothing);

      final toggleFinder = find.byKey(
        const ValueKey<String>('composer_permission_auto_approve_toggle'),
      );
      await tester.tap(toggleFinder);
      await tester.pump();

      expect(distanceToBottom(), closeTo(distanceBeforeToggle, 1));
      expect(find.text('older user marker'), findsNothing);

      await tester.pump(const Duration(milliseconds: 1200));

      expect(distanceToBottom(), closeTo(distanceBeforeToggle, 1));
      expect(find.text('older user marker'), findsNothing);
      expect(repository.getMessagesCallCount, messageCallsBeforeToggle);
      expect(repository.getSessionsCallCount, sessionCallsBeforeToggle);
      expect(repository.getSessionStatusCallCount, statusCallsBeforeToggle);

      await tester.tap(toggleFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));

      expect(distanceToBottom(), closeTo(distanceBeforeToggle, 1));
      expect(find.text('older user marker'), findsNothing);
      expect(repository.getMessagesCallCount, messageCallsBeforeToggle);
      expect(repository.getSessionsCallCount, sessionCallsBeforeToggle);
      expect(repository.getSessionStatusCallCount, statusCallsBeforeToggle);
    },
  );

  testWidgets(
    'enabling auto-approve with pending permissions keeps the viewport stable',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const sessionId = 'ses_toggle_pending';
      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: sessionId,
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Toggle Pending',
          ),
        ],
      );
      final messages = <ChatMessage>[];
      for (var index = 0; index < 18; index += 1) {
        final userId = 'msg_pending_user_$index';
        messages.add(
          UserMessage(
            id: userId,
            sessionId: sessionId,
            time: DateTime.fromMillisecondsSinceEpoch(1000 + (index * 2000)),
            parts: <MessagePart>[
              TextPart(
                id: 'part_$userId',
                messageId: userId,
                sessionId: sessionId,
                text: index == 8
                    ? 'older pending user marker'
                    : 'pending user $index',
              ),
            ],
          ),
        );
        final assistantId = 'msg_pending_assistant_$index';
        messages.add(
          AssistantMessage(
            id: assistantId,
            sessionId: sessionId,
            time: DateTime.fromMillisecondsSinceEpoch(2000 + (index * 2000)),
            completedTime: DateTime.fromMillisecondsSinceEpoch(
              2100 + (index * 2000),
            ),
            parts: <MessagePart>[
              TextPart(
                id: 'part_$assistantId',
                messageId: assistantId,
                sessionId: sessionId,
                text: 'pending assistant $index',
              ),
            ],
          ),
        );
      }
      messages.add(
        UserMessage(
          id: 'msg_pending_tail_user',
          sessionId: sessionId,
          time: DateTime.fromMillisecondsSinceEpoch(50000),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_pending_tail_user',
              messageId: 'msg_pending_tail_user',
              sessionId: sessionId,
              text: 'tail user waiting on permission',
            ),
          ],
        ),
      );
      repository.messagesBySession[sessionId] = messages;
      repository.pendingPermissions = const <ChatPermissionRequest>[
        ChatPermissionRequest(
          id: 'perm_toggle_pending_1',
          sessionId: sessionId,
          permission: 'bash',
          patterns: <String>['*'],
          always: <String>[],
          metadata: <String, dynamic>{},
        ),
      ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..experienceSettingsJson = jsonEncode(<String, dynamic>{
          'checkUpdatesOnOpen': false,
          'composerAutoApprovePermissions': false,
        });
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.initializeProviders();
      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await tester.pumpAndSettle();

      final listFinder = find.byKey(
        const ValueKey<String>('chat_message_list'),
      );
      final scrollableFinder = find
          .descendant(of: listFinder, matching: find.byType(Scrollable))
          .first;

      double distanceToBottom() {
        final position = tester
            .state<ScrollableState>(scrollableFinder)
            .position;
        return position.maxScrollExtent - position.pixels;
      }

      final messageCallsBeforeToggle = repository.getMessagesCallCount;
      final sessionCallsBeforeToggle = repository.getSessionsCallCount;
      final statusCallsBeforeToggle = repository.getSessionStatusCallCount;
      final distanceBeforeToggle = distanceToBottom();

      expect(find.text('older pending user marker'), findsNothing);
      expect(
        find.byKey(
          const ValueKey<String>(
            'interaction_permission_request_perm_toggle_pending_1',
          ),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('composer_permission_auto_approve_toggle'),
        ),
      );
      await tester.pump();

      expect(distanceToBottom(), closeTo(distanceBeforeToggle, 1));
      expect(find.text('older pending user marker'), findsNothing);

      await tester.pump(const Duration(milliseconds: 1200));

      expect(repository.lastPermissionRequestId, 'perm_toggle_pending_1');
      expect(repository.lastPermissionReply, 'once');
      expect(distanceToBottom(), closeTo(distanceBeforeToggle, 1));
      expect(find.text('older pending user marker'), findsNothing);
      expect(repository.getMessagesCallCount, messageCallsBeforeToggle);
      expect(repository.getSessionsCallCount, sessionCallsBeforeToggle);
      expect(repository.getSessionStatusCallCount, statusCallsBeforeToggle);
      expect(
        find.byKey(
          const ValueKey<String>(
            'interaction_permission_request_perm_toggle_pending_1',
          ),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'shows subagent permission requests in main prompt and timeline',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_root',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Root Session',
          ),
          ChatSession(
            id: 'ses_sub_1',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(900),
            title: 'Sub Session',
            parentId: 'ses_root',
          ),
        ],
      );
      repository.messagesBySession['ses_root'] = <ChatMessage>[
        UserMessage(
          id: 'msg_root_1',
          sessionId: 'ses_root',
          time: DateTime.fromMillisecondsSinceEpoch(1200),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_root_1',
              messageId: 'msg_root_1',
              sessionId: 'ses_root',
              text: 'Show pending permissions',
            ),
          ],
        ),
      ];
      repository.pendingPermissions = const <ChatPermissionRequest>[
        ChatPermissionRequest(
          id: 'perm_mirror_1',
          sessionId: 'ses_sub_1',
          permission: 'bash',
          patterns: <String>['*'],
          always: <String>[],
          metadata: <String, dynamic>{},
        ),
      ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test'
        ..experienceSettingsJson = jsonEncode(<String, dynamic>{
          'checkUpdatesOnOpen': false,
          'composerAutoApprovePermissions': false,
        });
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.initializeProviders();
      await provider.loadSessions();
      await provider.selectSession(
        provider.sessions.where((session) => session.id == 'ses_root').first,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>(
            'interaction_permission_request_perm_mirror_1',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('timeline_permission_request_perm_mirror_1'),
        ),
        findsOneWidget,
      );
      expect(find.text('Sub Session'), findsWidgets);

      await tester.tap(find.text('Allow Once').first);
      await tester.pumpAndSettle();

      expect(repository.lastPermissionRequestId, 'perm_mirror_1');
      expect(
        find.byKey(
          const ValueKey<String>(
            'interaction_permission_request_perm_mirror_1',
          ),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('timeline_permission_request_perm_mirror_1'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('shows subagent question requests in main interaction prompt', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_root_q',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Root Session',
        ),
        ChatSession(
          id: 'ses_sub_q',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(900),
          title: 'Sub Session',
          parentId: 'ses_root_q',
        ),
      ],
    );
    repository.pendingQuestions = const <ChatQuestionRequest>[
      ChatQuestionRequest(
        id: 'q_sub_prompt_1',
        sessionId: 'ses_sub_q',
        questions: <ChatQuestionInfo>[
          ChatQuestionInfo(
            question: 'Proceed from child?',
            header: 'Child Check',
            options: <ChatQuestionOption>[
              ChatQuestionOption(label: 'Yes', description: 'Continue'),
              ChatQuestionOption(label: 'No', description: 'Stop'),
            ],
            custom: false,
          ),
        ],
      ),
    ];

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.initializeProviders();
    await provider.loadSessions();
    await provider.selectSession(
      provider.sessions.where((session) => session.id == 'ses_root_q').first,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey<String>('interaction_question_request_q_sub_prompt_1'),
      ),
      findsOneWidget,
    );
    expect(find.text('Sub Session'), findsOneWidget);

    await tester.tap(find.text('Review Answers'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit Answers'));
    await tester.pumpAndSettle();

    expect(repository.lastQuestionReplyRequestId, 'q_sub_prompt_1');
  });

  testWidgets('shows model selector with search and quick reasoning selector', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_1',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Session 1',
        ),
      ],
    );

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
      includeVariants: true,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pump(const Duration(milliseconds: 150));

    expect(
      find.byKey(const ValueKey<String>('model_selector_button')),
      findsOneWidget,
    );
    expect(find.text('model_1'), findsOneWidget);
    expect(find.text('Auto'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('model_selector_button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Search model or provider'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('model_selector_provider_header_provider_1'),
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Search model or provider'),
      'missing-model',
    );
    await tester.pumpAndSettle();
    expect(find.text('No models found'), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('variant_selector_button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Low'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
  });

  testWidgets(
    'sub-conversation shows composer parity and keeps sends scoped to the child session',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final rootSession = ChatSession(
        id: 'ses_root_subtask_nav',
        workspaceId: 'default',
        time: DateTime.fromMillisecondsSinceEpoch(1000),
        title: 'Root Session',
      );
      final childSession = ChatSession(
        id: 'ses_child_subtask_nav',
        workspaceId: 'default',
        time: DateTime.fromMillisecondsSinceEpoch(1100),
        title: 'Child Session',
        parentId: rootSession.id,
      );
      final repository = FakeChatRepository(
        sessions: <ChatSession>[rootSession, childSession],
      );
      repository.messagesBySession[rootSession.id] = <ChatMessage>[
        AssistantMessage(
          id: 'msg_root_subtask',
          sessionId: rootSession.id,
          time: DateTime.fromMillisecondsSinceEpoch(1200),
          completedTime: DateTime.fromMillisecondsSinceEpoch(1210),
          parts: const <MessagePart>[
            SubtaskPart(
              id: 'part_root_subtask',
              messageId: 'msg_root_subtask',
              sessionId: 'ses_root_subtask_nav',
              prompt: 'inspect',
              description: 'Open child thread',
              agent: 'reviewer',
            ),
          ],
        ),
      ];
      repository.messagesBySession[childSession.id] = <ChatMessage>[
        UserMessage(
          id: 'msg_child_text',
          sessionId: 'ses_child_subtask_nav',
          time: DateTime.fromMillisecondsSinceEpoch(1300),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_child_text',
              messageId: 'msg_child_text',
              sessionId: 'ses_child_subtask_nav',
              text: 'Child thread context',
            ),
          ],
        ),
        AssistantMessage(
          id: 'msg_child_assistant',
          sessionId: 'ses_child_subtask_nav',
          time: DateTime.fromMillisecondsSinceEpoch(1350),
          completedTime: DateTime.fromMillisecondsSinceEpoch(1360),
          providerId: 'provider_1',
          modelId: 'model_1',
          mode: 'reviewer',
          parts: const <MessagePart>[
            TextPart(
              id: 'part_child_assistant',
              messageId: 'msg_child_assistant',
              sessionId: 'ses_child_subtask_nav',
              text: 'Child assistant output',
            ),
          ],
        ),
      ];
      repository.sessionChildrenById[rootSession.id] = <ChatSession>[
        childSession,
      ];
      repository.sendMessageHandler = (_, sessionId, _, _) {
        final reply = AssistantMessage(
          id: 'msg_child_help_reply',
          sessionId: sessionId,
          time: DateTime.fromMillisecondsSinceEpoch(1400),
          completedTime: DateTime.fromMillisecondsSinceEpoch(1410),
          providerId: 'provider_1',
          modelId: 'model_1',
          mode: 'reviewer',
          parts: const <MessagePart>[
            TextPart(
              id: 'part_child_help_reply',
              messageId: 'msg_child_help_reply',
              sessionId: 'ses_child_subtask_nav',
              text: 'Child help reply',
            ),
          ],
        );
        return Stream<Either<Failure, ChatMessage>>.value(Right(reply));
      };

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
        providersResponse: ProvidersResponse(
          providers: <Provider>[
            Provider(
              id: 'provider_1',
              name: 'Provider 1',
              env: const <String>[],
              models: <String, Model>{
                'model_1': _model(
                  'model_1',
                  attachment: true,
                  variants: const <String, ModelVariant>{
                    'low': ModelVariant(id: 'low', name: 'Low'),
                    'high': ModelVariant(id: 'high', name: 'High'),
                  },
                ),
                'model_2': _model(
                  'model_2',
                  attachment: true,
                  variants: const <String, ModelVariant>{
                    'low': ModelVariant(id: 'low', name: 'Low'),
                    'high': ModelVariant(id: 'high', name: 'High'),
                  },
                ),
              },
            ),
          ],
          defaultModels: const <String, String>{'provider_1': 'model_1'},
          connected: const <String>['provider_1'],
        ),
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.initializeProviders();
      await provider.selectSession(rootSession);
      await provider.setSelectedModelByProvider(
        providerId: 'provider_1',
        modelId: 'model_2',
      );
      await provider.setSelectedVariant('high');
      await provider.loadSessionInsights(rootSession.id, silent: true);
      await tester.pumpAndSettle();

      expect(find.text('model_2'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);

      expect(
        find.byKey(
          const ValueKey<String>('subtask_open_session_part_root_subtask'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('subtask_open_session_part_root_subtask'),
        ),
      );
      await tester.pumpAndSettle();

      expect(provider.currentSession?.id, childSession.id);
      expect(
        find.byKey(
          const ValueKey<String>('subconversation_return_main_button'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('composer_input_row')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('agent_selector_button')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('model_selector_button_readonly')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('variant_selector_button_readonly')),
        findsNothing,
      );
      expect(find.text('model_1'), findsOneWidget);
      expect(find.text('Auto (server)'), findsNothing);
      expect(find.byIcon(Symbols.attach_file_rounded), findsNothing);
      expect(find.byIcon(Symbols.add_rounded), findsOneWidget);
      expect(find.byIcon(Symbols.mic_none_rounded), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('model_selector_button_readonly')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Search model or provider'), findsNothing);

      final childComposerField = find.descendant(
        of: find.byKey(const ValueKey<String>('composer_input_row')),
        matching: find.byType(TextField),
      );
      await tester.enterText(childComposerField, 'child help');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Symbols.send_rounded));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(repository.lastSendSessionId, childSession.id);
      expect(find.text('child help'), findsOneWidget);
      expect(find.text('Child help reply'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('subconversation_return_main_button'),
        ),
      );
      await tester.pumpAndSettle();

      expect(provider.currentSession?.id, rootSession.id);
      expect(
        find.byKey(const ValueKey<String>('composer_input_row')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('agent_selector_button')),
        findsOneWidget,
      );
      expect(find.text('child help'), findsNothing);
      expect(find.text('Child help reply'), findsNothing);
    },
  );

  testWidgets(
    'sub-conversation keeps return control while composer stop is active',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final rootSession = ChatSession(
        id: 'ses_root_sub_stop',
        workspaceId: 'default',
        time: DateTime.fromMillisecondsSinceEpoch(1000),
        title: 'Root Session',
      );
      final childSession = ChatSession(
        id: 'ses_child_sub_stop',
        workspaceId: 'default',
        time: DateTime.fromMillisecondsSinceEpoch(1100),
        title: 'Child Session',
        parentId: rootSession.id,
      );

      final repository = FakeChatRepository(
        sessions: <ChatSession>[rootSession, childSession],
      );
      repository.messagesBySession[childSession.id] = <ChatMessage>[
        AssistantMessage(
          id: 'msg_child_sub_stop',
          sessionId: childSession.id,
          time: DateTime.fromMillisecondsSinceEpoch(1200),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_child_sub_stop',
              messageId: 'msg_child_sub_stop',
              sessionId: 'ses_child_sub_stop',
              text: 'Still generating...',
            ),
          ],
        ),
      ];
      repository.sessionStatusById = const <String, SessionStatusInfo>{
        'ses_child_sub_stop': SessionStatusInfo(type: SessionStatusType.busy),
      };

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(childSession);
      await provider.initializeProviders();
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('subconversation_return_main_button'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('composer_input_row')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('composer_input_row')),
          matching: find.byIcon(Symbols.stop_rounded),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey<String>('composer_input_row')),
          matching: find.byIcon(Symbols.stop_rounded),
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.abortSessionCallCount, 1);
      expect(repository.lastAbortSessionId, childSession.id);
    },
  );

  testWidgets(
    'task tool bubble opens matching sub-conversation from parent session',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final rootSession = ChatSession(
        id: 'ses_root_task_tool_nav',
        workspaceId: 'default',
        time: DateTime.fromMillisecondsSinceEpoch(1000),
        title: 'Root Session',
      );
      final childSession = ChatSession(
        id: 'ses_child_task_tool_nav',
        workspaceId: 'default',
        time: DateTime.fromMillisecondsSinceEpoch(1100),
        title: 'Child Session',
        parentId: rootSession.id,
      );

      final repository = FakeChatRepository(
        sessions: <ChatSession>[rootSession, childSession],
      );
      repository.messagesBySession[rootSession.id] = <ChatMessage>[
        AssistantMessage(
          id: 'msg_root_task_tool',
          sessionId: rootSession.id,
          time: DateTime.fromMillisecondsSinceEpoch(1200),
          completedTime: DateTime.fromMillisecondsSinceEpoch(1210),
          parts: <MessagePart>[
            ToolPart(
              id: 'part_root_task_tool',
              messageId: 'msg_root_task_tool',
              sessionId: rootSession.id,
              callId: 'call_root_task_tool',
              tool: 'task',
              state: ToolStateCompleted(
                input: const <String, dynamic>{
                  'childSessionID': 'ses_child_task_tool_nav',
                },
                output: 'created',
                time: ToolTime(
                  start: DateTime.fromMillisecondsSinceEpoch(1200),
                  end: DateTime.fromMillisecondsSinceEpoch(1205),
                ),
              ),
            ),
          ],
        ),
      ];
      repository.messagesBySession[childSession.id] = <ChatMessage>[
        UserMessage(
          id: 'msg_child_task_tool',
          sessionId: childSession.id,
          time: DateTime.fromMillisecondsSinceEpoch(1300),
          parts: <MessagePart>[
            TextPart(
              id: 'part_child_task_tool',
              messageId: 'msg_child_task_tool',
              sessionId: childSession.id,
              text: 'Child thread',
            ),
          ],
        ),
      ];
      repository.sessionChildrenById[rootSession.id] = <ChatSession>[
        childSession,
      ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(rootSession);
      await provider.loadSessionInsights(rootSession.id, silent: true);
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('task_tool_open_session_part_root_task_tool'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('task_tool_open_session_part_root_task_tool'),
        ),
      );
      await tester.pumpAndSettle();

      expect(provider.currentSession?.id, childSession.id);
      expect(
        find.byKey(
          const ValueKey<String>('subconversation_return_main_button'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'desktop model, variant, and agent shortcuts are blocked in sub-conversations',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final rootSession = ChatSession(
        id: 'ses_root_shortcuts_sub',
        workspaceId: 'default',
        time: DateTime.fromMillisecondsSinceEpoch(1000),
        title: 'Root Session',
      );
      final childSession = ChatSession(
        id: 'ses_child_shortcuts_sub',
        workspaceId: 'default',
        time: DateTime.fromMillisecondsSinceEpoch(1100),
        title: 'Child Session',
        parentId: rootSession.id,
      );
      final repository = FakeChatRepository(
        sessions: <ChatSession>[rootSession, childSession],
      );

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
        providersResponse: ProvidersResponse(
          providers: <Provider>[
            Provider(
              id: 'provider_1',
              name: 'Provider 1',
              env: const <String>[],
              models: <String, Model>{
                'model_1': _model(
                  'model_1',
                  variants: const <String, ModelVariant>{
                    'low': ModelVariant(id: 'low', name: 'Low'),
                    'high': ModelVariant(id: 'high', name: 'High'),
                  },
                ),
                'model_2': _model(
                  'model_2',
                  variants: const <String, ModelVariant>{
                    'low': ModelVariant(id: 'low', name: 'Low'),
                    'high': ModelVariant(id: 'high', name: 'High'),
                  },
                ),
              },
            ),
          ],
          defaultModels: const <String, String>{'provider_1': 'model_1'},
          connected: const <String>['provider_1'],
        ),
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.initializeProviders();
      await provider.selectSession(childSession);
      await provider.setSelectedModelByProvider(
        providerId: 'provider_1',
        modelId: 'model_1',
      );
      await tester.pumpAndSettle();

      expect(provider.selectedModelId, 'model_1');
      expect(provider.selectedVariantId, isNull);
      expect(provider.selectedAgentName, 'build');

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyM);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyM);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyT);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyT);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyJ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyJ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(provider.selectedModelId, 'model_1');
      expect(provider.selectedVariantId, isNull);
      expect(provider.selectedAgentName, 'build');
    },
  );

  testWidgets(
    'uses provider brand icons for selected model and model selector items',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_1',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Session 1',
          ),
        ],
      );

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
        providersResponse: ProvidersResponse(
          providers: <Provider>[
            Provider(
              id: 'anthropic',
              name: 'Anthropic',
              env: const <String>[],
              models: <String, Model>{
                'claude-sonnet-4-5': _model(
                  'claude-sonnet-4-5',
                  name: 'Claude Sonnet 4.5',
                ),
              },
            ),
            Provider(
              id: 'google',
              name: 'Google',
              env: const <String>[],
              models: <String, Model>{
                'claude-opus-via-google': _model(
                  'claude-opus-via-google',
                  name: 'Claude Opus via Google',
                ),
                'gemini-2.5-pro': _model(
                  'gemini-2.5-pro',
                  name: 'Gemini 2.5 Pro',
                ),
              },
            ),
            Provider(
              id: 'minimax',
              name: 'MiniMax',
              env: const <String>[],
              models: <String, Model>{
                'minimax-m1': _model('minimax-m1', name: 'MiniMax M1'),
              },
            ),
            Provider(
              id: 'xai',
              name: 'xAI',
              env: const <String>[],
              models: <String, Model>{
                'grok-3': _model('grok-3', name: 'Grok 3'),
              },
            ),
            Provider(
              id: 'mistral',
              name: 'Mistral',
              env: const <String>[],
              models: <String, Model>{
                'mistral-large': _model('mistral-large', name: 'Mistral Large'),
              },
            ),
            Provider(
              id: 'openrouter',
              name: 'OpenRouter',
              env: const <String>[],
              models: <String, Model>{
                'openrouter-model': _model(
                  'openrouter-model',
                  name: 'OpenRouter Model',
                ),
              },
            ),
          ],
          defaultModels: const <String, String>{
            'anthropic': 'claude-sonnet-4-5',
            'google': 'claude-opus-via-google',
            'minimax': 'minimax-m1',
            'xai': 'grok-3',
            'mistral': 'mistral-large',
            'openrouter': 'openrouter-model',
          },
          connected: const <String>[
            'anthropic',
            'google',
            'minimax',
            'xai',
            'mistral',
            'openrouter',
          ],
        ),
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.setSelectedModelByProvider(
        providerId: 'google',
        modelId: 'claude-opus-via-google',
      );
      await tester.pumpAndSettle();

      final modelSelectorChip = tester.widget<ActionChip>(
        find.byKey(const ValueKey<String>('model_selector_button')),
      );
      expect(modelSelectorChip.avatar, isNull);

      await tester.tap(
        find.byKey(const ValueKey<String>('model_selector_button')),
      );
      await tester.pumpAndSettle();

      Finder modelSelectorTileFinder({
        required String providerId,
        required String modelId,
      }) {
        return find.byWidgetPredicate((widget) {
          if (widget is! ListTile) {
            return false;
          }
          final key = widget.key;
          return key ==
                  ValueKey<String>(
                    'model_selector_item_${providerId}_$modelId',
                  ) ||
              key ==
                  ValueKey<String>(
                    'model_selector_recent_${providerId}_$modelId',
                  ) ||
              key ==
                  ValueKey<String>('model_selector_fav_${providerId}_$modelId');
        });
      }

      final anthropicTileFinder = modelSelectorTileFinder(
        providerId: 'anthropic',
        modelId: 'claude-sonnet-4-5',
      );
      expect(anthropicTileFinder, findsOneWidget);
      expect(
        find.descendant(
          of: anthropicTileFinder,
          matching: find.byIcon(SimpleIcons.claude),
        ),
        findsOneWidget,
      );

      final googleClaudeTileFinder = modelSelectorTileFinder(
        providerId: 'google',
        modelId: 'claude-opus-via-google',
      );
      expect(googleClaudeTileFinder, findsOneWidget);
      expect(
        find.descendant(
          of: googleClaudeTileFinder,
          matching: find.byIcon(SimpleIcons.claude),
        ),
        findsOneWidget,
      );

      final googleTileFinder = modelSelectorTileFinder(
        providerId: 'google',
        modelId: 'gemini-2.5-pro',
      );
      expect(googleTileFinder, findsOneWidget);
      expect(
        find.descendant(
          of: googleTileFinder,
          matching: find.byIcon(SimpleIcons.googlegemini),
        ),
        findsOneWidget,
      );

      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

      await provider.setSelectedModelByProvider(
        providerId: 'minimax',
        modelId: 'minimax-m1',
      );
      await tester.pumpAndSettle();
      final minimaxChip = tester.widget<ActionChip>(
        find.byKey(const ValueKey<String>('model_selector_button')),
      );
      expect(minimaxChip.avatar, isNull);

      await provider.setSelectedModelByProvider(
        providerId: 'xai',
        modelId: 'grok-3',
      );
      await tester.pumpAndSettle();
      final xaiChip = tester.widget<ActionChip>(
        find.byKey(const ValueKey<String>('model_selector_button')),
      );
      expect(xaiChip.avatar, isNull);

      await provider.setSelectedModelByProvider(
        providerId: 'mistral',
        modelId: 'mistral-large',
      );
      await tester.pumpAndSettle();
      final mistralChip = tester.widget<ActionChip>(
        find.byKey(const ValueKey<String>('model_selector_button')),
      );
      expect(mistralChip.avatar, isNull);

      await provider.setSelectedModelByProvider(
        providerId: 'openrouter',
        modelId: 'openrouter-model',
      );
      await tester.pumpAndSettle();
      final openrouterChip = tester.widget<ActionChip>(
        find.byKey(const ValueKey<String>('model_selector_button')),
      );
      expect(openrouterChip.avatar, isNull);
    },
  );

  testWidgets('shows agent selector and updates selected agent', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_1',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Session 1',
        ),
      ],
    );

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pump(const Duration(milliseconds: 150));

    expect(
      find.byKey(const ValueKey<String>('agent_selector_button')),
      findsOneWidget,
    );
    expect(find.text('Build'), findsOneWidget);
    final agentChip = tester.widget<ActionChip>(
      find.byKey(const ValueKey<String>('agent_selector_button')),
    );
    expect(agentChip.avatar, isNull);

    await tester.tap(
      find.byKey(const ValueKey<String>('agent_selector_button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('agent_selector_item_build')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('agent_selector_item_plan')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('agent_selector_item_plan')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Plan'), findsOneWidget);
    expect(provider.selectedAgentName, 'plan');
  });

  testWidgets('uses backend agent color on selector label', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_1',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Session 1',
        ),
      ],
    );

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final appRepository = FakeAppRepository()
      ..agentsResult = const Right(<Agent>[
        Agent(
          name: 'build',
          mode: 'primary',
          hidden: false,
          native: false,
          color: '#ff6b00',
        ),
        Agent(
          name: 'plan',
          mode: 'primary',
          hidden: false,
          native: false,
          color: '#00a8ff',
        ),
      ]);
    final provider = _buildChatProvider(
      chatRepository: repository,
      appRepository: appRepository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pump(const Duration(milliseconds: 150));

    final chipText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('agent_selector_button')),
        matching: find.text('Build'),
      ),
    );
    expect(chipText.style?.color, const Color(0xFFFF6B00));
  });

  testWidgets('desktop shortcut cycles selected agent', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_1',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Session 1',
        ),
      ],
    );

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pumpAndSettle();

    expect(provider.selectedAgentName, 'build');

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyJ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyJ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(provider.selectedAgentName, 'plan');
  });

  testWidgets('desktop shortcut opens settings without composer focus', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(localDataSource: localDataSource);
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.comma);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.comma);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Density and timeline bubble visibility'), findsOneWidget);
  });

  testWidgets('desktop New Chat focuses composer input', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_new_chat_focus_desktop',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Desktop New Chat Focus',
        ),
      ],
    );
    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pumpAndSettle();

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tester.tap(find.byTooltip('New Chat').first);
    await tester.pumpAndSettle();

    final chatInputFieldFinder = find.descendant(
      of: find.byKey(const ValueKey<String>('composer_input_row')),
      matching: find.byType(TextField),
    );
    final input = tester.widget<TextField>(chatInputFieldFinder);
    expect(input.focusNode?.hasFocus, isTrue);
  });

  testWidgets('mobile New Chat focuses composer input', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_new_chat_focus_mobile',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Mobile New Chat Focus',
        ),
      ],
    );
    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pumpAndSettle();

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tester.tap(find.byTooltip('New Chat').first);
    await tester.pumpAndSettle();

    final chatInputFieldFinder = find.descendant(
      of: find.byKey(const ValueKey<String>('composer_input_row')),
      matching: find.byType(TextField),
    );
    final input = tester.widget<TextField>(chatInputFieldFinder);
    expect(input.focusNode?.hasFocus, isTrue);
  });

  testWidgets('New Chat draft does not show select-or-create empty state', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_new_chat_draft_empty_state',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'New Chat Draft Empty State',
        ),
      ],
    );
    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('New Chat').first);
    await tester.pumpAndSettle();

    expect(
      find.text('Select or create a conversation to start chatting'),
      findsNothing,
    );
    expect(find.text('How can I help you?'), findsOneWidget);
  });

  testWidgets('keyboard shortcut focuses composer with mod+l on desktop', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_focus_shortcut',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Focus Shortcut Session',
        ),
      ],
    );
    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pumpAndSettle();

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyL);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyL);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    final chatInputFieldFinder = find.descendant(
      of: find.byKey(const ValueKey<String>('composer_input_row')),
      matching: find.byType(TextField),
    );
    final input = tester.widget<TextField>(chatInputFieldFinder);
    expect(input.focusNode?.hasFocus, isTrue);
  });

  testWidgets('keyboard shortcut focuses composer with mod+l on mobile', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_focus_shortcut_mobile',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Mobile Focus Shortcut Session',
        ),
      ],
    );
    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pumpAndSettle();

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyL);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyL);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    final chatInputFieldFinder = find.descendant(
      of: find.byKey(const ValueKey<String>('composer_input_row')),
      matching: find.byType(TextField),
    );
    final input = tester.widget<TextField>(chatInputFieldFinder);
    expect(input.focusNode?.hasFocus, isTrue);
  });

  testWidgets('desktop ESC focuses composer input when unfocused', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_escape_focus',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'ESC Focus Session',
        ),
      ],
    );
    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pumpAndSettle();

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    final chatInputFieldFinder = find.descendant(
      of: find.byKey(const ValueKey<String>('composer_input_row')),
      matching: find.byType(TextField),
    );
    final input = tester.widget<TextField>(chatInputFieldFinder);
    expect(input.focusNode?.hasFocus, isTrue);
  });

  testWidgets('double ESC closes settings page', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(localDataSource: localDataSource);
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.comma);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.comma);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.text('Density and timeline bubble visibility'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('Density and timeline bubble visibility'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Density and timeline bubble visibility'), findsNothing);
    expect(find.text('Conversations'), findsOneWidget);
  });

  testWidgets('desktop shortcuts cycle recent model and variant', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_1',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Session 1',
        ),
      ],
    );

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
      providersResponse: ProvidersResponse(
        providers: <Provider>[
          Provider(
            id: 'provider_1',
            name: 'Provider 1',
            env: const <String>[],
            models: <String, Model>{
              'model_1': _model(
                'model_1',
                variants: const <String, ModelVariant>{
                  'low': ModelVariant(id: 'low', name: 'Low'),
                  'high': ModelVariant(id: 'high', name: 'High'),
                },
              ),
              'model_2': _model(
                'model_2',
                variants: const <String, ModelVariant>{
                  'low': ModelVariant(id: 'low', name: 'Low'),
                  'high': ModelVariant(id: 'high', name: 'High'),
                },
              ),
            },
          ),
        ],
        defaultModels: const <String, String>{'provider_1': 'model_1'},
        connected: const <String>['provider_1'],
      ),
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await provider.initializeProviders();
    await provider.setSelectedModelByProvider(
      providerId: 'provider_1',
      modelId: 'model_2',
    );
    await provider.setSelectedModelByProvider(
      providerId: 'provider_1',
      modelId: 'model_1',
    );
    await tester.pumpAndSettle();

    expect(provider.selectedModelId, 'model_1');
    expect(provider.selectedVariantId, isNull);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyM);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyM);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(provider.selectedModelId, 'model_2');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyM);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyM);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(provider.selectedModelId, 'model_1');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyT);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyT);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(provider.selectedVariantId, 'low');
  });

  testWidgets(
    'model selector shows top 3 recent models and alphabetical providers',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final recentModelsJson = jsonEncode(<String>[
        'provider_a/model_a3',
        'provider_z/model_z2',
        'provider_a/model_a2',
      ]);
      localDataSource.recentModelsJson = recentModelsJson;
      for (final serverId in <String>['srv_test', 'legacy']) {
        for (final scopeId in <String>['/tmp', 'default']) {
          await localDataSource.saveRecentModelsJson(
            recentModelsJson,
            serverId: serverId,
            scopeId: scopeId,
          );
        }
      }

      final provider = _buildChatProvider(
        localDataSource: localDataSource,
        providersResponse: ProvidersResponse(
          providers: <Provider>[
            Provider(
              id: 'provider_z',
              name: 'Zulu Provider',
              env: const <String>[],
              models: <String, Model>{
                'model_z1': _model('model_z1', name: 'Z1'),
                'model_z2': _model('model_z2', name: 'Z2'),
              },
            ),
            Provider(
              id: 'provider_a',
              name: 'Alpha Provider',
              env: const <String>[],
              models: <String, Model>{
                'model_a1': _model('model_a1', name: 'A1'),
                'model_a2': _model('model_a2', name: 'A2'),
                'model_a3': _model('model_a3', name: 'A3'),
              },
            ),
          ],
          defaultModels: const <String, String>{'provider_a': 'model_a1'},
          connected: const <String>['provider_a', 'provider_z'],
        ),
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();
      final scopedServerId =
          await localDataSource.getActiveServerId() ?? 'legacy';
      final scopedScopeId =
          provider.projectProvider.currentDirectory ??
          provider.projectProvider.currentProjectId;
      await localDataSource.saveRecentModelsJson(
        recentModelsJson,
        serverId: scopedServerId,
        scopeId: scopedScopeId,
      );
      await provider.initializeProviders();
      await tester.pumpAndSettle();
      expect(provider.recentModelKeys, isNotEmpty);

      await tester.tap(
        find.byKey(const ValueKey<String>('model_selector_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('model_selector_recent_header')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('model_selector_recent_provider_a_model_a3'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('model_selector_recent_provider_z_model_z2'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('model_selector_recent_provider_a_model_a2'),
        ),
        findsOneWidget,
      );

      final alphaDy = tester
          .getTopLeft(
            find.byKey(
              const ValueKey<String>(
                'model_selector_provider_header_provider_a',
              ),
            ),
          )
          .dy;
      final zuluDy = tester
          .getTopLeft(
            find.byKey(
              const ValueKey<String>(
                'model_selector_provider_header_provider_z',
              ),
            ),
          )
          .dy;
      expect(alphaDy, lessThan(zuluDy));
    },
  );

  testWidgets('opens conversation at latest message and toggles jump FAB', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_scroll',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Scrollable Session',
        ),
      ],
    );
    repository.messagesBySession['ses_scroll'] = _threadMessages(
      'ses_scroll',
      40,
    );

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pumpAndSettle();

    final listFinder = find.byKey(const ValueKey<String>('chat_message_list'));
    final scrollableFinder = find
        .descendant(of: listFinder, matching: find.byType(Scrollable))
        .first;

    expect(find.text('message 39'), findsOneWidget);
    expect(find.byTooltip('Go to latest message'), findsNothing);

    await tester.drag(listFinder, const Offset(0, 420));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Go to latest message'), findsOneWidget);

    await tester.tap(find.byTooltip('Go to latest message'));
    await tester.pumpAndSettle();

    final scrollableAfterTap = tester.state<ScrollableState>(scrollableFinder);
    expect(
      scrollableAfterTap.position.maxScrollExtent -
          scrollableAfterTap.position.pixels,
      lessThanOrEqualTo(1),
    );

    expect(find.byTooltip('Go to latest message'), findsNothing);
    expect(find.text('message 39'), findsOneWidget);
  });

  testWidgets('shows jump-to-first FAB after scrolling up and jumps to top', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_scroll_top',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Scrollable Top Session',
        ),
      ],
    );
    repository.messagesBySession['ses_scroll_top'] = _threadMessages(
      'ses_scroll_top',
      60,
    );

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pumpAndSettle();

    final listFinder = find.byKey(const ValueKey<String>('chat_message_list'));
    final scrollableFinder = find.descendant(
      of: listFinder,
      matching: find.byType(Scrollable),
    );

    await tester.drag(listFinder, const Offset(0, 700));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('jump_to_first_fab')),
      findsOneWidget,
    );
    expect(find.byTooltip('Go to first message'), findsOneWidget);

    await tester.tap(find.byTooltip('Go to first message'));
    await tester.pumpAndSettle();

    final scrollableAfterTap = tester.state<ScrollableState>(scrollableFinder);
    expect(scrollableAfterTap.position.pixels, lessThanOrEqualTo(1));
    expect(find.text('message 0'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('jump_to_first_fab')),
      findsNothing,
    );
  });

  testWidgets('auto-follows incoming messages while user stays at latest', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_follow',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Follow Session',
        ),
      ],
    );
    repository.messagesBySession['ses_follow'] = _threadMessages(
      'ses_follow',
      40,
    );

    final streamController = StreamController<Either<Failure, ChatMessage>>();
    addTearDown(() async {
      if (!streamController.isClosed) {
        await streamController.close();
      }
    });
    repository.sendMessageHandler = (_, _, _, _) => streamController.stream;

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await provider.initializeProviders();
    await tester.pumpAndSettle();

    final listFinder = find.byKey(const ValueKey<String>('chat_message_list'));
    final scrollableFinder = find.descendant(
      of: listFinder,
      matching: find.byType(Scrollable),
    );
    final scrollableBefore = tester.state<ScrollableState>(scrollableFinder);
    expect(
      scrollableBefore.position.maxScrollExtent -
          scrollableBefore.position.pixels,
      lessThanOrEqualTo(1),
    );
    expect(find.byTooltip('Go to latest message'), findsNothing);

    await provider.sendMessage('trigger auto follow');
    await tester.pump();

    streamController.add(
      Right(
        AssistantMessage(
          id: 'msg_follow_1',
          sessionId: 'ses_follow',
          time: DateTime.fromMillisecondsSinceEpoch(3000),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_follow_1',
              messageId: 'msg_follow_1',
              sessionId: 'ses_follow',
              text:
                  'auto-follow should keep chat pinned to the latest message even when new content arrives while user is already at the bottom',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollableAfter = tester.state<ScrollableState>(scrollableFinder);
    expect(
      scrollableAfter.position.maxScrollExtent -
          scrollableAfter.position.pixels,
      lessThanOrEqualTo(1),
    );
    expect(
      find.textContaining('auto-follow should keep chat pinned'),
      findsOneWidget,
    );
    expect(find.byTooltip('Go to latest message'), findsNothing);
  });

  testWidgets('keeps following busy tool/system updates before final idle', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_busy_tool_follow',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Busy Tool Follow Session',
        ),
      ],
    );
    final baseMessages = _threadMessages('ses_busy_tool_follow', 40);
    repository.messagesBySession['ses_busy_tool_follow'] = List<ChatMessage>.of(
      baseMessages,
    );

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pumpAndSettle();

    final listFinder = find.byKey(const ValueKey<String>('chat_message_list'));
    final scrollableFinder = find.descendant(
      of: listFinder,
      matching: find.byType(Scrollable),
    );
    final scrollableBefore = tester.state<ScrollableState>(scrollableFinder);
    expect(
      scrollableBefore.position.maxScrollExtent -
          scrollableBefore.position.pixels,
      lessThanOrEqualTo(1),
    );

    final busyToolAndSystemUpdate = AssistantMessage(
      id: 'msg_busy_tool_follow',
      sessionId: 'ses_busy_tool_follow',
      time: DateTime.fromMillisecondsSinceEpoch(60000),
      completedTime: DateTime.fromMillisecondsSinceEpoch(61000),
      parts: <MessagePart>[
        ToolPart(
          id: 'part_busy_tool_follow_tool',
          messageId: 'msg_busy_tool_follow',
          sessionId: 'ses_busy_tool_follow',
          callId: 'call_busy_tool_follow_tool',
          tool: 'bash',
          state: ToolStateCompleted(
            input: const <String, dynamic>{
              'description': 'Collecting details',
              'command': 'git status --short',
            },
            output: 'M lib/presentation/providers/chat_provider.dart',
            time: ToolTime(
              start: DateTime.fromMillisecondsSinceEpoch(60000),
              end: DateTime.fromMillisecondsSinceEpoch(60500),
            ),
          ),
        ),
        TextPart(
          id: 'part_busy_tool_follow_text',
          messageId: 'msg_busy_tool_follow',
          sessionId: 'ses_busy_tool_follow',
          text: List<String>.filled(
            240,
            'system update should keep viewport following while busy',
          ).join(' '),
        ),
      ],
    );

    repository.messagesBySession['ses_busy_tool_follow'] = <ChatMessage>[
      ...baseMessages,
      busyToolAndSystemUpdate,
    ];

    repository.emitEvent(
      const ChatEvent(
        type: 'session.status',
        properties: <String, dynamic>{
          'sessionID': 'ses_busy_tool_follow',
          'status': <String, dynamic>{'type': 'busy'},
        },
      ),
    );
    repository.emitEvent(
      const ChatEvent(
        type: 'message.updated',
        properties: <String, dynamic>{
          'info': <String, dynamic>{
            'id': 'msg_busy_tool_follow',
            'sessionID': 'ses_busy_tool_follow',
          },
        },
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pumpAndSettle();

    final scrollableAfter = tester.state<ScrollableState>(scrollableFinder);
    expect(
      scrollableAfter.position.maxScrollExtent -
          scrollableAfter.position.pixels,
      lessThanOrEqualTo(1),
    );
    expect(find.byTooltip('Go to latest message'), findsNothing);
    expect(
      find.textContaining('system update should keep viewport following'),
      findsOneWidget,
    );
  });

  testWidgets(
    'keeps jump-to-latest FAB hidden when short final response fits viewport',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_short_final_fab',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Short Final FAB Session',
          ),
        ],
      );

      final streamController = StreamController<Either<Failure, ChatMessage>>();
      addTearDown(() async {
        if (!streamController.isClosed) {
          await streamController.close();
        }
      });
      repository.sendMessageHandler = (_, _, _, _) => streamController.stream;

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.initializeProviders();
      await tester.pumpAndSettle();

      await provider.sendMessage('trigger short final response');
      await tester.pump();

      streamController.add(
        Right(
          AssistantMessage(
            id: 'msg_short_final_tool_only',
            sessionId: 'ses_short_final_fab',
            time: DateTime.fromMillisecondsSinceEpoch(2100),
            completedTime: DateTime.fromMillisecondsSinceEpoch(2200),
            parts: <MessagePart>[
              ToolPart(
                id: 'part_short_final_tool_only',
                messageId: 'msg_short_final_tool_only',
                sessionId: 'ses_short_final_fab',
                callId: 'call_short_final_tool_only',
                tool: 'bash',
                state: ToolStateCompleted(
                  input: const <String, dynamic>{'command': 'echo hi'},
                  output: 'hi',
                  time: ToolTime(
                    start: DateTime.fromMillisecondsSinceEpoch(2100),
                    end: DateTime.fromMillisecondsSinceEpoch(2150),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 60));

      streamController.add(
        Right(
          AssistantMessage(
            id: 'msg_short_final_answer',
            sessionId: 'ses_short_final_fab',
            time: DateTime.fromMillisecondsSinceEpoch(2300),
            completedTime: DateTime.fromMillisecondsSinceEpoch(2400),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_short_final_answer',
                messageId: 'msg_short_final_answer',
                sessionId: 'ses_short_final_fab',
                text: 'ok',
              ),
            ],
          ),
        ),
      );
      await streamController.close();
      await tester.pumpAndSettle();

      expect(find.text('ok'), findsOneWidget);
      expect(find.byTooltip('Go to latest message'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('jump_to_latest_fab')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'sending a follow-up invalidates previous final-message reveal jump',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_reveal_invalidation',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Reveal Invalidation Session',
          ),
        ],
      );

      final firstStream = StreamController<Either<Failure, ChatMessage>>();
      final secondStream = StreamController<Either<Failure, ChatMessage>>();
      addTearDown(() async {
        if (!firstStream.isClosed) {
          await firstStream.close();
        }
        if (!secondStream.isClosed) {
          await secondStream.close();
        }
      });

      var sendCalls = 0;
      repository.sendMessageHandler = (_, _, _, _) {
        sendCalls += 1;
        if (sendCalls == 1) {
          return firstStream.stream;
        }
        return secondStream.stream;
      };

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.initializeProviders();
      await tester.pumpAndSettle();

      final chatInputFieldFinder = find.descendant(
        of: find.byKey(const ValueKey<String>('composer_input_row')),
        matching: find.byType(TextField),
      );

      await tester.enterText(chatInputFieldFinder, 'first prompt');
      await tester.pump();
      await tester.tap(find.byIcon(Symbols.send_rounded));
      await tester.pump();

      firstStream.add(
        Right(
          AssistantMessage(
            id: 'msg_reveal_tool_only',
            sessionId: 'ses_reveal_invalidation',
            time: DateTime.fromMillisecondsSinceEpoch(2100),
            completedTime: DateTime.fromMillisecondsSinceEpoch(2200),
            parts: <MessagePart>[
              ToolPart(
                id: 'part_reveal_tool_only',
                messageId: 'msg_reveal_tool_only',
                sessionId: 'ses_reveal_invalidation',
                callId: 'call_reveal_tool_only',
                tool: 'read',
                state: ToolStateCompleted(
                  input: const <String, dynamic>{'filePath': 'README.md'},
                  output: 'ok',
                  time: ToolTime(
                    start: DateTime.fromMillisecondsSinceEpoch(2100),
                    end: DateTime.fromMillisecondsSinceEpoch(2150),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      firstStream.add(
        Right(
          AssistantMessage(
            id: 'msg_reveal_final',
            sessionId: 'ses_reveal_invalidation',
            time: DateTime.fromMillisecondsSinceEpoch(2300),
            completedTime: DateTime.fromMillisecondsSinceEpoch(2400),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_reveal_final',
                messageId: 'msg_reveal_final',
                sessionId: 'ses_reveal_invalidation',
                text:
                    'final response that triggers reveal positioning before the next user follow-up message is sent',
              ),
            ],
          ),
        ),
      );
      await firstStream.close();

      // Do not settle fully: send follow-up while reveal callbacks from the
      // previous assistant completion are still pending.
      await tester.pump();
      await tester.enterText(chatInputFieldFinder, 'follow-up right away');
      await tester.pump();
      await tester.tap(find.byIcon(Symbols.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      expect(find.text('follow-up right away'), findsOneWidget);
      expect(find.byTooltip('Go to latest message'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('jump_to_latest_fab')),
        findsNothing,
      );
    },
  );

  testWidgets('highlights jump FAB when new messages arrive below viewport', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_live',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Live Session',
        ),
      ],
    );
    repository.messagesBySession['ses_live'] = _threadMessages('ses_live', 40);

    final streamController = StreamController<Either<Failure, ChatMessage>>();
    addTearDown(() async {
      await streamController.close();
    });
    repository.sendMessageHandler = (_, _, _, _) => streamController.stream;

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await provider.initializeProviders();
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey<String>('chat_message_list')),
      const Offset(0, 420),
    );
    await tester.pumpAndSettle();

    final listFinder = find.byKey(const ValueKey<String>('chat_message_list'));
    final scrollableFinder = find.descendant(
      of: listFinder,
      matching: find.byType(Scrollable),
    );
    final scrollableBefore = tester.state<ScrollableState>(scrollableFinder);
    final pixelsBeforeIncoming = scrollableBefore.position.pixels;

    final fabFinder = find.byKey(const ValueKey<String>('jump_to_latest_fab'));
    expect(fabFinder, findsOneWidget);
    expect(
      find.descendant(
        of: fabFinder,
        matching: find.byIcon(Symbols.arrow_downward_rounded),
      ),
      findsOneWidget,
    );

    await provider.sendMessage('trigger streaming reply');
    await tester.pump();

    streamController.add(
      Right(
        AssistantMessage(
          id: 'msg_stream_1',
          sessionId: 'ses_live',
          time: DateTime.fromMillisecondsSinceEpoch(3000),
          completedTime: DateTime.fromMillisecondsSinceEpoch(3200),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_stream_1',
              messageId: 'msg_stream_1',
              sessionId: 'ses_live',
              text: 'live response',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollableAfter = tester.state<ScrollableState>(scrollableFinder);
    expect(scrollableAfter.position.pixels, closeTo(pixelsBeforeIncoming, 1));

    expect(
      find.descendant(
        of: fabFinder,
        matching: find.byIcon(Symbols.mark_chat_unread),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Go to latest message'));
    await tester.pumpAndSettle();

    final scrollableAfterTap = tester.state<ScrollableState>(scrollableFinder);
    expect(
      scrollableAfterTap.position.maxScrollExtent -
          scrollableAfterTap.position.pixels,
      lessThanOrEqualTo(1),
    );

    expect(find.byIcon(Symbols.mark_chat_unread), findsNothing);
  });

  testWidgets(
    'slight manual upward scroll near bottom suppresses passive refresh auto-follow',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const sessionId = 'ses_manual_pause_refresh';
      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: sessionId,
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Manual Pause Refresh',
          ),
        ],
      );
      repository.messagesBySession[sessionId] = _threadMessages(sessionId, 40);

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await tester.pumpAndSettle();

      final listFinder = find.byKey(
        const ValueKey<String>('chat_message_list'),
      );
      final scrollableFinder = find.descendant(
        of: listFinder,
        matching: find.byType(Scrollable),
      );

      await tester.drag(listFinder, const Offset(0, 80));
      await tester.pumpAndSettle();

      final scrollableBefore = tester.state<ScrollableState>(scrollableFinder);
      final pixelsBeforeRefresh = scrollableBefore.position.pixels;
      expect(
        scrollableBefore.position.maxScrollExtent -
            scrollableBefore.position.pixels,
        greaterThan(1),
      );

      repository.messagesBySession[sessionId] = <ChatMessage>[
        ...repository.messagesBySession[sessionId]!,
        AssistantMessage(
          id: 'msg_manual_pause_refresh_tail',
          sessionId: sessionId,
          time: DateTime.fromMillisecondsSinceEpoch(90000),
          completedTime: DateTime.fromMillisecondsSinceEpoch(90100),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_manual_pause_refresh_tail',
              messageId: 'msg_manual_pause_refresh_tail',
              sessionId: sessionId,
              text: 'passive refresh should not steal the viewport',
            ),
          ],
        ),
      ];

      await provider.refreshActiveSessionView(
        reason: 'manual-scroll-near-bottom-passive-refresh',
        includeStatus: false,
      );
      await tester.pump();
      await tester.pumpAndSettle();

      final scrollableAfter = tester.state<ScrollableState>(scrollableFinder);
      expect(scrollableAfter.position.pixels, closeTo(pixelsBeforeRefresh, 1));
      expect(find.byTooltip('Go to latest message'), findsOneWidget);
      expect(find.byIcon(Symbols.mark_chat_unread), findsOneWidget);
    },
  );

  testWidgets(
    'collapses pre-compaction history by default and toggles older messages',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_compaction_timeline',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Compaction Timeline',
          ),
        ],
      );
      repository.messagesBySession['ses_compaction_timeline'] = <ChatMessage>[
        UserMessage(
          id: 'msg_old_1',
          sessionId: 'ses_compaction_timeline',
          time: DateTime.fromMillisecondsSinceEpoch(1100),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_old_1',
              messageId: 'msg_old_1',
              sessionId: 'ses_compaction_timeline',
              text: 'old message one',
            ),
          ],
        ),
        AssistantMessage(
          id: 'msg_old_2',
          sessionId: 'ses_compaction_timeline',
          time: DateTime.fromMillisecondsSinceEpoch(1200),
          completedTime: DateTime.fromMillisecondsSinceEpoch(1210),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_old_2',
              messageId: 'msg_old_2',
              sessionId: 'ses_compaction_timeline',
              text: 'old message two',
            ),
          ],
        ),
        UserMessage(
          id: 'msg_old_3',
          sessionId: 'ses_compaction_timeline',
          time: DateTime.fromMillisecondsSinceEpoch(1300),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_old_3',
              messageId: 'msg_old_3',
              sessionId: 'ses_compaction_timeline',
              text: 'old message three',
            ),
          ],
        ),
        AssistantMessage(
          id: 'msg_compaction_boundary',
          sessionId: 'ses_compaction_timeline',
          time: DateTime.fromMillisecondsSinceEpoch(2000),
          completedTime: DateTime.fromMillisecondsSinceEpoch(2100),
          parts: const <MessagePart>[
            CompactionPart(
              id: 'part_compaction_marker',
              messageId: 'msg_compaction_boundary',
              sessionId: 'ses_compaction_timeline',
              auto: false,
            ),
            TextPart(
              id: 'part_compaction_summary',
              messageId: 'msg_compaction_boundary',
              sessionId: 'ses_compaction_timeline',
              text: 'compaction summary response',
            ),
          ],
        ),
        AssistantMessage(
          id: 'msg_after_compaction',
          sessionId: 'ses_compaction_timeline',
          time: DateTime.fromMillisecondsSinceEpoch(2200),
          completedTime: DateTime.fromMillisecondsSinceEpoch(2210),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_after_compaction',
              messageId: 'msg_after_compaction',
              sessionId: 'ses_compaction_timeline',
              text: 'message after compaction',
            ),
          ],
        ),
      ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('timeline_collapsed_history_header')),
        findsOneWidget,
      );
      expect(find.text('Show earlier messages'), findsOneWidget);
      expect(find.text('old message one'), findsNothing);
      expect(find.text('old message two'), findsNothing);
      expect(find.text('old message three'), findsNothing);
      expect(find.text('compaction summary response'), findsOneWidget);
      expect(find.text('message after compaction'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('timeline_collapsed_history_toggle')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hide earlier messages'), findsOneWidget);
      expect(find.text('old message one'), findsOneWidget);
      expect(find.text('old message two'), findsOneWidget);
      expect(find.text('old message three'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('timeline_collapsed_history_toggle')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Show earlier messages'), findsOneWidget);
      expect(find.text('old message one'), findsNothing);
      expect(find.text('old message two'), findsNothing);
      expect(find.text('old message three'), findsNothing);
    },
  );

  testWidgets(
    'collapses pre-summary history when compaction marker part is absent',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_compaction_summary_boundary',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Compaction Summary Boundary',
          ),
        ],
      );
      repository.messagesBySession['ses_compaction_summary_boundary'] =
          <ChatMessage>[
            UserMessage(
              id: 'msg_summary_old_1',
              sessionId: 'ses_compaction_summary_boundary',
              time: DateTime.fromMillisecondsSinceEpoch(1100),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_summary_old_1',
                  messageId: 'msg_summary_old_1',
                  sessionId: 'ses_compaction_summary_boundary',
                  text: 'summary old message one',
                ),
              ],
            ),
            AssistantMessage(
              id: 'msg_summary_boundary',
              sessionId: 'ses_compaction_summary_boundary',
              time: DateTime.fromMillisecondsSinceEpoch(2000),
              completedTime: DateTime.fromMillisecondsSinceEpoch(2100),
              summary: true,
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_summary_boundary_text',
                  messageId: 'msg_summary_boundary',
                  sessionId: 'ses_compaction_summary_boundary',
                  text: 'summary boundary response',
                ),
              ],
            ),
            AssistantMessage(
              id: 'msg_summary_after',
              sessionId: 'ses_compaction_summary_boundary',
              time: DateTime.fromMillisecondsSinceEpoch(2200),
              completedTime: DateTime.fromMillisecondsSinceEpoch(2210),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_summary_after_text',
                  messageId: 'msg_summary_after',
                  sessionId: 'ses_compaction_summary_boundary',
                  text: 'summary message after boundary',
                ),
              ],
            ),
          ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('timeline_collapsed_history_header')),
        findsOneWidget,
      );
      expect(find.text('summary old message one'), findsNothing);
      expect(find.text('summary boundary response'), findsOneWidget);
      expect(find.text('summary message after boundary'), findsOneWidget);
    },
  );

  testWidgets('preserves collapsed history expansion when switching sessions', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_compaction_reset_a',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Compaction Reset A',
        ),
        ChatSession(
          id: 'ses_compaction_reset_b',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(2000),
          title: 'Compaction Reset B',
        ),
      ],
    );

    repository.messagesBySession['ses_compaction_reset_a'] = <ChatMessage>[
      UserMessage(
        id: 'msg_reset_old_a',
        sessionId: 'ses_compaction_reset_a',
        time: DateTime.fromMillisecondsSinceEpoch(1100),
        parts: const <MessagePart>[
          TextPart(
            id: 'part_reset_old_a',
            messageId: 'msg_reset_old_a',
            sessionId: 'ses_compaction_reset_a',
            text: 'reset old message a',
          ),
        ],
      ),
      AssistantMessage(
        id: 'msg_reset_compaction_a',
        sessionId: 'ses_compaction_reset_a',
        time: DateTime.fromMillisecondsSinceEpoch(2100),
        completedTime: DateTime.fromMillisecondsSinceEpoch(2110),
        parts: const <MessagePart>[
          CompactionPart(
            id: 'part_reset_compaction_a',
            messageId: 'msg_reset_compaction_a',
            sessionId: 'ses_compaction_reset_a',
            auto: true,
          ),
          TextPart(
            id: 'part_reset_summary_a',
            messageId: 'msg_reset_compaction_a',
            sessionId: 'ses_compaction_reset_a',
            text: 'reset summary a',
          ),
        ],
      ),
    ];

    repository.messagesBySession['ses_compaction_reset_b'] = <ChatMessage>[
      AssistantMessage(
        id: 'msg_reset_b',
        sessionId: 'ses_compaction_reset_b',
        time: DateTime.fromMillisecondsSinceEpoch(2200),
        completedTime: DateTime.fromMillisecondsSinceEpoch(2210),
        parts: const <MessagePart>[
          TextPart(
            id: 'part_reset_b',
            messageId: 'msg_reset_b',
            sessionId: 'ses_compaction_reset_b',
            text: 'another session message',
          ),
        ],
      ),
    ];

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    final sessionA = provider.sessions
        .where((session) => session.id == 'ses_compaction_reset_a')
        .first;
    final sessionB = provider.sessions
        .where((session) => session.id == 'ses_compaction_reset_b')
        .first;
    await provider.selectSession(sessionA);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('timeline_collapsed_history_toggle')),
    );
    await tester.pumpAndSettle();
    expect(find.text('reset old message a'), findsOneWidget);

    await provider.selectSession(sessionB);
    await tester.pumpAndSettle();

    await provider.selectSession(sessionA);
    await tester.pumpAndSettle();

    // Collapse state is preserved per session: history that was expanded
    // before switching away should still be expanded on return.
    expect(find.text('reset old message a'), findsOneWidget);
  });

  testWidgets(
    'reopening a settled cached session reveals the latest response instead of snapping to bottom',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_cached_bottom_a',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Cached Bottom A',
          ),
          ChatSession(
            id: 'ses_cached_bottom_b',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(2000),
            title: 'Cached Bottom B',
          ),
        ],
      );
      final longLatestText = List<String>.filled(
        120,
        'cached settled session should reveal the latest response',
      ).join(' ');
      repository.messagesBySession['ses_cached_bottom_a'] = <ChatMessage>[
        ..._threadMessages('ses_cached_bottom_a', 28),
        AssistantMessage(
          id: 'msg_cached_bottom_a_latest',
          sessionId: 'ses_cached_bottom_a',
          time: DateTime.fromMillisecondsSinceEpoch(35000),
          completedTime: DateTime.fromMillisecondsSinceEpoch(35500),
          parts: <MessagePart>[
            TextPart(
              id: 'part_cached_bottom_a_latest',
              messageId: 'msg_cached_bottom_a_latest',
              sessionId: 'ses_cached_bottom_a',
              text: longLatestText,
            ),
          ],
        ),
      ];
      repository.messagesBySession['ses_cached_bottom_b'] = _threadMessages(
        'ses_cached_bottom_b',
        6,
      );

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      final sessionA = provider.sessions
          .where((session) => session.id == 'ses_cached_bottom_a')
          .first;
      final sessionB = provider.sessions
          .where((session) => session.id == 'ses_cached_bottom_b')
          .first;

      await provider.selectSession(sessionA);
      await tester.pumpAndSettle();

      await provider.selectSession(sessionB);
      await tester.pumpAndSettle();

      await provider.selectSession(sessionA);
      for (var frame = 0; frame < 6; frame += 1) {
        await tester.pump();
      }

      final listFinder = find.byKey(
        const ValueKey<String>('chat_message_list'),
      );
      final scrollableFinder = find
          .descendant(of: listFinder, matching: find.byType(Scrollable))
          .first;
      final scrollable = tester.state<ScrollableState>(scrollableFinder);

      expect(
        scrollable.position.maxScrollExtent - scrollable.position.pixels,
        greaterThan(1),
      );
    },
  );

  testWidgets(
    'reopening a long settled cached session keeps virtualized return path stable',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_cached_virtualized_a',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Cached Virtualized A',
          ),
          ChatSession(
            id: 'ses_cached_virtualized_b',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(2000),
            title: 'Cached Virtualized B',
          ),
        ],
      );
      final longLatestText = List<String>.filled(
        120,
        'virtualized latest assistant start should be revealed after return',
      ).join(' ');
      repository.messagesBySession['ses_cached_virtualized_a'] = <ChatMessage>[
        ..._threadMessages('ses_cached_virtualized_a', 90),
        AssistantMessage(
          id: 'msg_cached_virtualized_a_latest',
          sessionId: 'ses_cached_virtualized_a',
          time: DateTime.fromMillisecondsSinceEpoch(95000),
          completedTime: DateTime.fromMillisecondsSinceEpoch(95500),
          parts: <MessagePart>[
            TextPart(
              id: 'part_cached_virtualized_a_latest',
              messageId: 'msg_cached_virtualized_a_latest',
              sessionId: 'ses_cached_virtualized_a',
              text: longLatestText,
            ),
          ],
        ),
      ];
      repository.messagesBySession['ses_cached_virtualized_b'] =
          _threadMessages('ses_cached_virtualized_b', 6);
      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      final sessionA = provider.sessions
          .where((session) => session.id == 'ses_cached_virtualized_a')
          .first;
      final sessionB = provider.sessions
          .where((session) => session.id == 'ses_cached_virtualized_b')
          .first;

      await provider.selectSession(sessionA);
      await tester.pumpAndSettle();

      await provider.selectSession(sessionB);
      await tester.pumpAndSettle();

      await provider.selectSession(sessionA);
      final listFinder = find.byKey(
        const ValueKey<String>('chat_message_list'),
      );
      final scrollableFinder = find
          .descendant(of: listFinder, matching: find.byType(Scrollable))
          .first;
      for (var frame = 0; frame < 40; frame += 1) {
        await tester.pump(const Duration(milliseconds: 16));
        await tester.idle();
      }
      await tester.pumpAndSettle();

      final scrollable = tester.state<ScrollableState>(scrollableFinder);

      expect(
        scrollable.position.maxScrollExtent - scrollable.position.pixels,
        greaterThan(1),
      );
    },
  );

  testWidgets('reopening an active cached session lands at bottom', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_cached_active_a',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Cached Active A',
        ),
        ChatSession(
          id: 'ses_cached_active_b',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(2000),
          title: 'Cached Active B',
        ),
      ],
    );
    repository.messagesBySession['ses_cached_active_a'] = <ChatMessage>[
      ..._threadMessages('ses_cached_active_a', 60),
      UserMessage(
        id: 'msg_cached_active_a_user',
        sessionId: 'ses_cached_active_a',
        time: DateTime.fromMillisecondsSinceEpoch(70000),
        parts: const <MessagePart>[
          TextPart(
            id: 'part_cached_active_a_user',
            messageId: 'msg_cached_active_a_user',
            sessionId: 'ses_cached_active_a',
            text: 'still processing',
          ),
        ],
      ),
    ];
    repository.messagesBySession['ses_cached_active_b'] = _threadMessages(
      'ses_cached_active_b',
      6,
    );
    repository.sessionStatusById = const <String, SessionStatusInfo>{
      'ses_cached_active_a': SessionStatusInfo(type: SessionStatusType.busy),
    };

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    final sessionA = provider.sessions
        .where((session) => session.id == 'ses_cached_active_a')
        .first;
    final sessionB = provider.sessions
        .where((session) => session.id == 'ses_cached_active_b')
        .first;

    await provider.selectSession(sessionA);
    await tester.pumpAndSettle();

    await provider.selectSession(sessionB);
    await tester.pumpAndSettle();

    await provider.selectSession(sessionA);
    for (var frame = 0; frame < 6; frame += 1) {
      await tester.pump();
    }

    final listFinder = find.byKey(const ValueKey<String>('chat_message_list'));
    final scrollableFinder = find
        .descendant(of: listFinder, matching: find.byType(Scrollable))
        .first;
    final scrollable = tester.state<ScrollableState>(scrollableFinder);

    expect(
      scrollable.position.maxScrollExtent - scrollable.position.pixels,
      lessThanOrEqualTo(1),
    );
    expect(find.byTooltip('Go to latest message'), findsNothing);
  });

  testWidgets(
    'resets tool-chain expansion when switching sessions and returning',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_tool_state_a',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Tool State A',
          ),
          ChatSession(
            id: 'ses_tool_state_b',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(2000),
            title: 'Tool State B',
          ),
        ],
      );

      repository.messagesBySession['ses_tool_state_a'] = <ChatMessage>[
        AssistantMessage(
          id: 'msg_tool_state_a',
          sessionId: 'ses_tool_state_a',
          time: DateTime.fromMillisecondsSinceEpoch(2100),
          completedTime: DateTime.fromMillisecondsSinceEpoch(2200),
          parts: <MessagePart>[
            ToolPart(
              id: 'part_tool_state_a_1',
              messageId: 'msg_tool_state_a',
              sessionId: 'ses_tool_state_a',
              callId: 'call_tool_state_a_1',
              tool: 'bash',
              state: ToolStateCompleted(
                input: const <String, dynamic>{'command': 'pwd'},
                output: '/tmp/project',
                time: ToolTime(
                  start: DateTime.fromMillisecondsSinceEpoch(2100),
                  end: DateTime.fromMillisecondsSinceEpoch(2120),
                ),
              ),
            ),
            ToolPart(
              id: 'part_tool_state_a_2',
              messageId: 'msg_tool_state_a',
              sessionId: 'ses_tool_state_a',
              callId: 'call_tool_state_a_2',
              tool: 'read',
              state: ToolStateCompleted(
                input: const <String, dynamic>{'filePath': 'lib/main.dart'},
                output: 'line 1\nline 2',
                time: ToolTime(
                  start: DateTime.fromMillisecondsSinceEpoch(2130),
                  end: DateTime.fromMillisecondsSinceEpoch(2150),
                ),
              ),
            ),
            const TextPart(
              id: 'part_tool_state_a_text',
              messageId: 'msg_tool_state_a',
              sessionId: 'ses_tool_state_a',
              text: 'Final answer A',
            ),
          ],
        ),
      ];

      repository.messagesBySession['ses_tool_state_b'] = <ChatMessage>[
        AssistantMessage(
          id: 'msg_tool_state_b',
          sessionId: 'ses_tool_state_b',
          time: DateTime.fromMillisecondsSinceEpoch(2300),
          completedTime: DateTime.fromMillisecondsSinceEpoch(2310),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_tool_state_b_text',
              messageId: 'msg_tool_state_b',
              sessionId: 'ses_tool_state_b',
              text: 'Final answer B',
            ),
          ],
        ),
      ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      final sessionA = provider.sessions
          .where((session) => session.id == 'ses_tool_state_a')
          .first;
      final sessionB = provider.sessions
          .where((session) => session.id == 'ses_tool_state_b')
          .first;

      await provider.selectSession(sessionA);
      await tester.pumpAndSettle();

      expect(find.text('Details'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey<String>(
            'tool_chain_toggle_msg_tool_state_a_call_tool_state_a_1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hide'), findsNWidgets(2));
      expect(find.text('Running command'), findsOneWidget);
      expect(find.text('Reading file'), findsOneWidget);

      await provider.selectSession(sessionB);
      await tester.pumpAndSettle();

      await provider.selectSession(sessionA);
      await tester.pumpAndSettle();

      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Hide'), findsNothing);
      expect(find.text('Running command'), findsNothing);
      expect(find.text('Reading file'), findsNothing);
    },
  );

  testWidgets(
    'groups assistant work messages between user and final assistant response',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_assistant_work_grouping',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Assistant Work Grouping',
          ),
        ],
      );

      repository.messagesBySession['ses_assistant_work_grouping'] =
          <ChatMessage>[
            UserMessage(
              id: 'msg_work_user',
              sessionId: 'ses_assistant_work_grouping',
              time: DateTime.fromMillisecondsSinceEpoch(1100),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_work_user',
                  messageId: 'msg_work_user',
                  sessionId: 'ses_assistant_work_grouping',
                  text: 'Build this for me',
                ),
              ],
            ),
            AssistantMessage(
              id: 'msg_work_step_1',
              sessionId: 'ses_assistant_work_grouping',
              time: DateTime.fromMillisecondsSinceEpoch(1200),
              completedTime: DateTime.fromMillisecondsSinceEpoch(1210),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_work_step_1',
                  messageId: 'msg_work_step_1',
                  sessionId: 'ses_assistant_work_grouping',
                  text: 'Working step 1',
                ),
              ],
            ),
            AssistantMessage(
              id: 'msg_work_step_2',
              sessionId: 'ses_assistant_work_grouping',
              time: DateTime.fromMillisecondsSinceEpoch(1300),
              completedTime: DateTime.fromMillisecondsSinceEpoch(1310),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_work_step_2',
                  messageId: 'msg_work_step_2',
                  sessionId: 'ses_assistant_work_grouping',
                  text: 'Working step 2',
                ),
              ],
            ),
            AssistantMessage(
              id: 'msg_work_final',
              sessionId: 'ses_assistant_work_grouping',
              time: DateTime.fromMillisecondsSinceEpoch(1400),
              completedTime: DateTime.fromMillisecondsSinceEpoch(1410),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_work_final',
                  messageId: 'msg_work_final',
                  sessionId: 'ses_assistant_work_grouping',
                  text: 'Final assistant response',
                ),
              ],
            ),
          ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('timeline_collapsed_assistant_work_header'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'timeline_assistant_work_preview_assistant_work_msg_work_final',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('2 work messages'), findsOneWidget);
      expect(find.text('Working step 1'), findsOneWidget);
      expect(find.text('Working step 2'), findsOneWidget);
      expect(find.text('Final assistant response'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('timeline_collapsed_assistant_work_toggle'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Working step 1'), findsOneWidget);
      expect(find.text('Working step 2'), findsOneWidget);
      expect(find.text('Final assistant response'), findsOneWidget);
    },
  );

  testWidgets(
    'keeps historical assistant work groups collapsed when a newer user turn exists',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_historical_assistant_work_grouping',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Historical Assistant Work Grouping',
          ),
        ],
      );

      repository.messagesBySession['ses_historical_assistant_work_grouping'] =
          <ChatMessage>[
            UserMessage(
              id: 'msg_historical_work_user',
              sessionId: 'ses_historical_assistant_work_grouping',
              time: DateTime.fromMillisecondsSinceEpoch(1100),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_historical_work_user',
                  messageId: 'msg_historical_work_user',
                  sessionId: 'ses_historical_assistant_work_grouping',
                  text: 'Build this for me',
                ),
              ],
            ),
            AssistantMessage(
              id: 'msg_historical_work_step_1',
              sessionId: 'ses_historical_assistant_work_grouping',
              time: DateTime.fromMillisecondsSinceEpoch(1200),
              completedTime: DateTime.fromMillisecondsSinceEpoch(1210),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_historical_work_step_1',
                  messageId: 'msg_historical_work_step_1',
                  sessionId: 'ses_historical_assistant_work_grouping',
                  text: 'Working step 1',
                ),
              ],
            ),
            AssistantMessage(
              id: 'msg_historical_work_step_2',
              sessionId: 'ses_historical_assistant_work_grouping',
              time: DateTime.fromMillisecondsSinceEpoch(1300),
              completedTime: DateTime.fromMillisecondsSinceEpoch(1310),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_historical_work_step_2',
                  messageId: 'msg_historical_work_step_2',
                  sessionId: 'ses_historical_assistant_work_grouping',
                  text: 'Working step 2',
                ),
              ],
            ),
            AssistantMessage(
              id: 'msg_historical_work_final',
              sessionId: 'ses_historical_assistant_work_grouping',
              time: DateTime.fromMillisecondsSinceEpoch(1400),
              completedTime: DateTime.fromMillisecondsSinceEpoch(1410),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_historical_work_final',
                  messageId: 'msg_historical_work_final',
                  sessionId: 'ses_historical_assistant_work_grouping',
                  text: 'Final assistant response',
                ),
              ],
            ),
            UserMessage(
              id: 'msg_historical_follow_up_user',
              sessionId: 'ses_historical_assistant_work_grouping',
              time: DateTime.fromMillisecondsSinceEpoch(1500),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_historical_follow_up_user',
                  messageId: 'msg_historical_follow_up_user',
                  sessionId: 'ses_historical_assistant_work_grouping',
                  text: 'Newer user turn',
                ),
              ],
            ),
          ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('timeline_collapsed_assistant_work_header'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'timeline_assistant_work_preview_assistant_work_msg_historical_work_final',
          ),
        ),
        findsNothing,
      );
      expect(find.text('Working step 1'), findsNothing);
      expect(find.text('Working step 2'), findsNothing);
      expect(find.text('Newer user turn'), findsOneWidget);
    },
  );

  testWidgets('keeps expanded assistant work group after SWR revalidation', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    List<ChatMessage> buildMessages(int offsetMs) {
      DateTime at(int value) =>
          DateTime.fromMillisecondsSinceEpoch(value + offsetMs);

      return <ChatMessage>[
        UserMessage(
          id: 'msg_work_revalidate_user',
          sessionId: 'ses_assistant_work_revalidate',
          time: at(1100),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_work_revalidate_user',
              messageId: 'msg_work_revalidate_user',
              sessionId: 'ses_assistant_work_revalidate',
              text: 'Build this for me',
            ),
          ],
        ),
        AssistantMessage(
          id: 'msg_work_revalidate_step_1',
          sessionId: 'ses_assistant_work_revalidate',
          time: at(1200),
          completedTime: at(1210),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_work_revalidate_step_1',
              messageId: 'msg_work_revalidate_step_1',
              sessionId: 'ses_assistant_work_revalidate',
              text: 'Working step 1',
            ),
          ],
        ),
        AssistantMessage(
          id: 'msg_work_revalidate_step_2',
          sessionId: 'ses_assistant_work_revalidate',
          time: at(1300),
          completedTime: at(1310),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_work_revalidate_step_2',
              messageId: 'msg_work_revalidate_step_2',
              sessionId: 'ses_assistant_work_revalidate',
              text: 'Working step 2',
            ),
          ],
        ),
        AssistantMessage(
          id: 'msg_work_revalidate_final',
          sessionId: 'ses_assistant_work_revalidate',
          time: at(1400),
          completedTime: at(1410),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_work_revalidate_final',
              messageId: 'msg_work_revalidate_final',
              sessionId: 'ses_assistant_work_revalidate',
              text: 'Final assistant response',
            ),
          ],
        ),
      ];
    }

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_assistant_work_revalidate',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Assistant Work Revalidate',
        ),
      ],
    );

    repository.messagesBySession['ses_assistant_work_revalidate'] =
        buildMessages(0);

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey<String>('timeline_collapsed_assistant_work_toggle'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Working step 1'), findsOneWidget);
    expect(find.text('Working step 2'), findsOneWidget);

    repository.messagesBySession['ses_assistant_work_revalidate'] =
        buildMessages(5000);

    await provider.loadMessages(
      'ses_assistant_work_revalidate',
      preserveVisibleState: true,
    );
    await tester.pumpAndSettle();

    expect(find.text('Working step 1'), findsOneWidget);
    expect(find.text('Working step 2'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('timeline_collapsed_assistant_work_header'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'does not restore manual assistant work expansion after session return',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      List<ChatMessage> buildMessages(String sessionId, int offsetMs) {
        DateTime at(int value) =>
            DateTime.fromMillisecondsSinceEpoch(value + offsetMs);

        return <ChatMessage>[
          UserMessage(
            id: 'msg_${sessionId}_user',
            sessionId: sessionId,
            time: at(1100),
            parts: <MessagePart>[
              TextPart(
                id: 'part_${sessionId}_user',
                messageId: 'msg_${sessionId}_user',
                sessionId: sessionId,
                text: 'Build this for me',
              ),
            ],
          ),
          AssistantMessage(
            id: 'msg_${sessionId}_step_1',
            sessionId: sessionId,
            time: at(1200),
            completedTime: at(1210),
            parts: <MessagePart>[
              TextPart(
                id: 'part_${sessionId}_step_1',
                messageId: 'msg_${sessionId}_step_1',
                sessionId: sessionId,
                text: 'Working step 1',
              ),
            ],
          ),
          AssistantMessage(
            id: 'msg_${sessionId}_step_2',
            sessionId: sessionId,
            time: at(1300),
            completedTime: at(1310),
            parts: <MessagePart>[
              TextPart(
                id: 'part_${sessionId}_step_2',
                messageId: 'msg_${sessionId}_step_2',
                sessionId: sessionId,
                text: 'Working step 2',
              ),
            ],
          ),
          AssistantMessage(
            id: 'msg_${sessionId}_final',
            sessionId: sessionId,
            time: at(1400),
            completedTime: at(1410),
            parts: <MessagePart>[
              TextPart(
                id: 'part_${sessionId}_final',
                messageId: 'msg_${sessionId}_final',
                sessionId: sessionId,
                text: 'Final assistant response',
              ),
            ],
          ),
        ];
      }

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_assistant_work_manual_return',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Assistant Work Manual Return',
          ),
          ChatSession(
            id: 'ses_assistant_work_manual_return_other',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(2000),
            title: 'Another Session',
          ),
        ],
      );
      repository.messagesBySession['ses_assistant_work_manual_return'] =
          buildMessages('ses_assistant_work_manual_return', 0);
      repository.messagesBySession['ses_assistant_work_manual_return_other'] =
          buildMessages('ses_assistant_work_manual_return_other', 5000);

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(
        provider.sessions.firstWhere(
          (session) => session.id == 'ses_assistant_work_manual_return',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>('timeline_collapsed_assistant_work_toggle'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextButton, 'Hide'), findsOneWidget);

      await provider.selectSession(
        provider.sessions.firstWhere(
          (session) => session.id == 'ses_assistant_work_manual_return_other',
        ),
      );
      await tester.pumpAndSettle();

      await provider.selectSession(
        provider.sessions.firstWhere(
          (session) => session.id == 'ses_assistant_work_manual_return',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('timeline_collapsed_assistant_work_header'),
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Expand'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Hide'), findsNothing);
    },
  );

  testWidgets(
    'keeps expanded historical assistant work group after SWR revalidation when work message ids shift',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      List<ChatMessage> buildMessages({
        required String stepSuffix,
        required String textSuffix,
      }) {
        return <ChatMessage>[
          UserMessage(
            id: 'msg_work_revalidate_shift_user',
            sessionId: 'ses_assistant_work_revalidate_shift',
            time: DateTime.fromMillisecondsSinceEpoch(1100),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_work_revalidate_shift_user',
                messageId: 'msg_work_revalidate_shift_user',
                sessionId: 'ses_assistant_work_revalidate_shift',
                text: 'Build this for me',
              ),
            ],
          ),
          AssistantMessage(
            id: 'msg_work_revalidate_shift_step_1_$stepSuffix',
            sessionId: 'ses_assistant_work_revalidate_shift',
            time: DateTime.fromMillisecondsSinceEpoch(1200),
            completedTime: DateTime.fromMillisecondsSinceEpoch(1210),
            parts: <MessagePart>[
              TextPart(
                id: 'part_work_revalidate_shift_step_1_$stepSuffix',
                messageId: 'msg_work_revalidate_shift_step_1_$stepSuffix',
                sessionId: 'ses_assistant_work_revalidate_shift',
                text: 'Working step 1 $textSuffix',
              ),
            ],
          ),
          AssistantMessage(
            id: 'msg_work_revalidate_shift_step_2_$stepSuffix',
            sessionId: 'ses_assistant_work_revalidate_shift',
            time: DateTime.fromMillisecondsSinceEpoch(1300),
            completedTime: DateTime.fromMillisecondsSinceEpoch(1310),
            parts: <MessagePart>[
              TextPart(
                id: 'part_work_revalidate_shift_step_2_$stepSuffix',
                messageId: 'msg_work_revalidate_shift_step_2_$stepSuffix',
                sessionId: 'ses_assistant_work_revalidate_shift',
                text: 'Working step 2 $textSuffix',
              ),
            ],
          ),
          AssistantMessage(
            id: 'msg_work_revalidate_shift_final',
            sessionId: 'ses_assistant_work_revalidate_shift',
            time: DateTime.fromMillisecondsSinceEpoch(1400),
            completedTime: DateTime.fromMillisecondsSinceEpoch(1410),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_work_revalidate_shift_final',
                messageId: 'msg_work_revalidate_shift_final',
                sessionId: 'ses_assistant_work_revalidate_shift',
                text: 'Final assistant response',
              ),
            ],
          ),
          UserMessage(
            id: 'msg_work_revalidate_shift_follow_up',
            sessionId: 'ses_assistant_work_revalidate_shift',
            time: DateTime.fromMillisecondsSinceEpoch(1500),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_work_revalidate_shift_follow_up',
                messageId: 'msg_work_revalidate_shift_follow_up',
                sessionId: 'ses_assistant_work_revalidate_shift',
                text: 'Newer user turn',
              ),
            ],
          ),
        ];
      }

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_assistant_work_revalidate_shift',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Assistant Work Revalidate Shift',
          ),
        ],
      );

      repository.messagesBySession['ses_assistant_work_revalidate_shift'] =
          buildMessages(stepSuffix: 'a', textSuffix: 'initial');

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>('timeline_collapsed_assistant_work_toggle'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Working step 1 initial'), findsOneWidget);
      expect(find.text('Working step 2 initial'), findsOneWidget);

      repository.messagesBySession['ses_assistant_work_revalidate_shift'] =
          buildMessages(stepSuffix: 'b', textSuffix: 'refreshed');

      await provider.loadMessages(
        'ses_assistant_work_revalidate_shift',
        preserveVisibleState: true,
      );
      await tester.pumpAndSettle();

      expect(find.text('Working step 1 refreshed'), findsOneWidget);
      expect(find.text('Working step 2 refreshed'), findsOneWidget);
      expect(find.text('Newer user turn'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('timeline_collapsed_assistant_work_header'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'keeps latest assistant work group collapsed during transient responding status pulses after completion',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_assistant_work_status_pulse',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Assistant Work Status Pulse',
          ),
        ],
      );

      repository.messagesBySession['ses_assistant_work_status_pulse'] =
          <ChatMessage>[
            UserMessage(
              id: 'msg_status_pulse_user',
              sessionId: 'ses_assistant_work_status_pulse',
              time: DateTime.fromMillisecondsSinceEpoch(1100),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_status_pulse_user',
                  messageId: 'msg_status_pulse_user',
                  sessionId: 'ses_assistant_work_status_pulse',
                  text: 'Build this for me',
                ),
              ],
            ),
            AssistantMessage(
              id: 'msg_status_pulse_step_1',
              sessionId: 'ses_assistant_work_status_pulse',
              time: DateTime.fromMillisecondsSinceEpoch(1200),
              completedTime: DateTime.fromMillisecondsSinceEpoch(1210),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_status_pulse_step_1',
                  messageId: 'msg_status_pulse_step_1',
                  sessionId: 'ses_assistant_work_status_pulse',
                  text: 'Working step 1',
                ),
              ],
            ),
            AssistantMessage(
              id: 'msg_status_pulse_step_2',
              sessionId: 'ses_assistant_work_status_pulse',
              time: DateTime.fromMillisecondsSinceEpoch(1300),
              completedTime: DateTime.fromMillisecondsSinceEpoch(1310),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_status_pulse_step_2',
                  messageId: 'msg_status_pulse_step_2',
                  sessionId: 'ses_assistant_work_status_pulse',
                  text: 'Working step 2',
                ),
              ],
            ),
            AssistantMessage(
              id: 'msg_status_pulse_final',
              sessionId: 'ses_assistant_work_status_pulse',
              time: DateTime.fromMillisecondsSinceEpoch(1400),
              completedTime: DateTime.fromMillisecondsSinceEpoch(1410),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_status_pulse_final',
                  messageId: 'msg_status_pulse_final',
                  sessionId: 'ses_assistant_work_status_pulse',
                  text: 'Final assistant response',
                ),
              ],
            ),
          ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('timeline_collapsed_assistant_work_header'),
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Expand'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Hide'), findsNothing);

      repository.emitEvent(
        const ChatEvent(
          type: 'session.status',
          properties: <String, dynamic>{
            'sessionID': 'ses_assistant_work_status_pulse',
            'status': <String, dynamic>{'type': 'busy'},
          },
        ),
      );
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('timeline_collapsed_assistant_work_header'),
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Expand'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Hide'), findsNothing);

      repository.emitEvent(
        const ChatEvent(
          type: 'session.status',
          properties: <String, dynamic>{
            'sessionID': 'ses_assistant_work_status_pulse',
            'status': <String, dynamic>{'type': 'idle'},
          },
        ),
      );
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('timeline_collapsed_assistant_work_header'),
        ),
        findsOneWidget,
      );
      expect(find.text('Final assistant response'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Expand'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Hide'), findsNothing);
    },
  );

  testWidgets(
    'keeps latest assistant work group collapsed after session re-entry during passive status pulses',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      List<ChatMessage> buildCollapsedWorkMessages() {
        return <ChatMessage>[
          UserMessage(
            id: 'msg_reentry_status_user',
            sessionId: 'ses_assistant_work_reentry_status',
            time: DateTime.fromMillisecondsSinceEpoch(1100),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_reentry_status_user',
                messageId: 'msg_reentry_status_user',
                sessionId: 'ses_assistant_work_reentry_status',
                text: 'Build this for me',
              ),
            ],
          ),
          AssistantMessage(
            id: 'msg_reentry_status_step_1',
            sessionId: 'ses_assistant_work_reentry_status',
            time: DateTime.fromMillisecondsSinceEpoch(1200),
            completedTime: DateTime.fromMillisecondsSinceEpoch(1210),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_reentry_status_step_1',
                messageId: 'msg_reentry_status_step_1',
                sessionId: 'ses_assistant_work_reentry_status',
                text: 'Working step 1',
              ),
            ],
          ),
          AssistantMessage(
            id: 'msg_reentry_status_step_2',
            sessionId: 'ses_assistant_work_reentry_status',
            time: DateTime.fromMillisecondsSinceEpoch(1300),
            completedTime: DateTime.fromMillisecondsSinceEpoch(1310),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_reentry_status_step_2',
                messageId: 'msg_reentry_status_step_2',
                sessionId: 'ses_assistant_work_reentry_status',
                text: 'Working step 2',
              ),
            ],
          ),
          AssistantMessage(
            id: 'msg_reentry_status_final',
            sessionId: 'ses_assistant_work_reentry_status',
            time: DateTime.fromMillisecondsSinceEpoch(1400),
            completedTime: DateTime.fromMillisecondsSinceEpoch(1410),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_reentry_status_final',
                messageId: 'msg_reentry_status_final',
                sessionId: 'ses_assistant_work_reentry_status',
                text: 'Final assistant response',
              ),
            ],
          ),
        ];
      }

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_assistant_work_reentry_status',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Assistant Work Reentry Status',
          ),
          ChatSession(
            id: 'ses_assistant_work_reentry_status_other',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(2000),
            title: 'Another Session',
          ),
        ],
      );
      repository.messagesBySession['ses_assistant_work_reentry_status'] =
          buildCollapsedWorkMessages();
      repository.messagesBySession['ses_assistant_work_reentry_status_other'] =
          <ChatMessage>[
            UserMessage(
              id: 'msg_reentry_status_other_user',
              sessionId: 'ses_assistant_work_reentry_status_other',
              time: DateTime.fromMillisecondsSinceEpoch(2100),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_reentry_status_other_user',
                  messageId: 'msg_reentry_status_other_user',
                  sessionId: 'ses_assistant_work_reentry_status_other',
                  text: 'Other session',
                ),
              ],
            ),
          ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(
        provider.sessions.firstWhere(
          (session) => session.id == 'ses_assistant_work_reentry_status',
        ),
      );
      await tester.pumpAndSettle();

      await provider.selectSession(
        provider.sessions.firstWhere(
          (session) => session.id == 'ses_assistant_work_reentry_status_other',
        ),
      );
      await tester.pumpAndSettle();

      repository.emitEvent(
        const ChatEvent(
          type: 'session.status',
          properties: <String, dynamic>{
            'sessionID': 'ses_assistant_work_reentry_status',
            'status': <String, dynamic>{'type': 'busy'},
          },
        ),
      );
      await tester.pump();

      await provider.selectSession(
        provider.sessions.firstWhere(
          (session) => session.id == 'ses_assistant_work_reentry_status',
        ),
      );
      await tester.pumpAndSettle();

      final listFinder = find.byKey(
        const ValueKey<String>('chat_message_list'),
      );
      final scrollableBefore = tester
          .stateList<ScrollableState>(
            find.descendant(of: listFinder, matching: find.byType(Scrollable)),
          )
          .first;
      final pixelsBeforePulses = scrollableBefore.position.pixels;
      final distanceToBottomBeforePulses =
          scrollableBefore.position.maxScrollExtent -
          scrollableBefore.position.pixels;

      expect(
        find.byKey(
          const ValueKey<String>('timeline_collapsed_assistant_work_header'),
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Expand'), findsOneWidget);

      repository.emitEvent(
        const ChatEvent(
          type: 'session.status',
          properties: <String, dynamic>{
            'sessionID': 'ses_assistant_work_reentry_status',
            'status': <String, dynamic>{'type': 'busy'},
          },
        ),
      );
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('timeline_collapsed_assistant_work_header'),
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Hide'), findsNothing);

      final scrollableAfterFirstBusy = tester
          .stateList<ScrollableState>(
            find.descendant(of: listFinder, matching: find.byType(Scrollable)),
          )
          .first;
      expect(
        scrollableAfterFirstBusy.position.pixels,
        closeTo(pixelsBeforePulses, 1),
      );
      expect(
        scrollableAfterFirstBusy.position.maxScrollExtent -
            scrollableAfterFirstBusy.position.pixels,
        closeTo(distanceToBottomBeforePulses, 1),
      );

      repository.emitEvent(
        const ChatEvent(
          type: 'session.status',
          properties: <String, dynamic>{
            'sessionID': 'ses_assistant_work_reentry_status',
            'status': <String, dynamic>{'type': 'idle'},
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('timeline_collapsed_assistant_work_header'),
        ),
        findsOneWidget,
      );
      expect(find.text('Final assistant response'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Expand'), findsOneWidget);

      final scrollableAfterFirstIdle = tester
          .stateList<ScrollableState>(
            find.descendant(of: listFinder, matching: find.byType(Scrollable)),
          )
          .first;
      expect(
        scrollableAfterFirstIdle.position.pixels,
        closeTo(pixelsBeforePulses, 1),
      );
      expect(
        scrollableAfterFirstIdle.position.maxScrollExtent -
            scrollableAfterFirstIdle.position.pixels,
        closeTo(distanceToBottomBeforePulses, 1),
      );

      repository.emitEvent(
        const ChatEvent(
          type: 'session.status',
          properties: <String, dynamic>{
            'sessionID': 'ses_assistant_work_reentry_status',
            'status': <String, dynamic>{'type': 'busy'},
          },
        ),
      );
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('timeline_collapsed_assistant_work_header'),
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Expand'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Hide'), findsNothing);

      final scrollableAfterSecondBusy = tester
          .stateList<ScrollableState>(
            find.descendant(of: listFinder, matching: find.byType(Scrollable)),
          )
          .first;
      expect(
        scrollableAfterSecondBusy.position.pixels,
        closeTo(pixelsBeforePulses, 1),
      );
      expect(
        scrollableAfterSecondBusy.position.maxScrollExtent -
            scrollableAfterSecondBusy.position.pixels,
        closeTo(distanceToBottomBeforePulses, 1),
      );

      repository.emitEvent(
        const ChatEvent(
          type: 'session.status',
          properties: <String, dynamic>{
            'sessionID': 'ses_assistant_work_reentry_status',
            'status': <String, dynamic>{'type': 'idle'},
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('timeline_collapsed_assistant_work_header'),
        ),
        findsOneWidget,
      );
      expect(find.text('Final assistant response'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Expand'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Hide'), findsNothing);

      final scrollableAfterSecondIdle = tester
          .stateList<ScrollableState>(
            find.descendant(of: listFinder, matching: find.byType(Scrollable)),
          )
          .first;
      expect(
        scrollableAfterSecondIdle.position.pixels,
        closeTo(pixelsBeforePulses, 1),
      );
      expect(
        scrollableAfterSecondIdle.position.maxScrollExtent -
            scrollableAfterSecondIdle.position.pixels,
        closeTo(distanceToBottomBeforePulses, 1),
      );
    },
  );

  testWidgets(
    'scroll stays stable during simulated background resume with passive refresh',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const sessionId = 'ses_resume_scroll_stable';
      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: sessionId,
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Resume Scroll Stable',
          ),
        ],
      );
      final messages = <ChatMessage>[];
      for (var index = 0; index < 15; index += 1) {
        final userId = 'msg_resume_user_$index';
        messages.add(
          UserMessage(
            id: userId,
            sessionId: sessionId,
            time: DateTime.fromMillisecondsSinceEpoch(1000 + (index * 2000)),
            parts: <MessagePart>[
              TextPart(
                id: 'part_$userId',
                messageId: userId,
                sessionId: sessionId,
                text: 'user message $index',
              ),
            ],
          ),
        );
        final assistantId = 'msg_resume_assistant_$index';
        messages.add(
          AssistantMessage(
            id: assistantId,
            sessionId: sessionId,
            time: DateTime.fromMillisecondsSinceEpoch(2000 + (index * 2000)),
            completedTime: DateTime.fromMillisecondsSinceEpoch(
              2100 + (index * 2000),
            ),
            parts: <MessagePart>[
              TextPart(
                id: 'part_$assistantId',
                messageId: assistantId,
                sessionId: sessionId,
                text: 'assistant message $index',
              ),
            ],
          ),
        );
      }
      repository.messagesBySession[sessionId] = messages;

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.initializeProviders();
      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await tester.pumpAndSettle();

      final listFinder = find.byKey(
        const ValueKey<String>('chat_message_list'),
      );
      final scrollableFinder = find
          .descendant(of: listFinder, matching: find.byType(Scrollable))
          .first;

      double scrollPixels() {
        final position = tester
            .state<ScrollableState>(scrollableFinder)
            .position;
        return position.pixels;
      }

      double distanceToBottom() {
        final position = tester
            .state<ScrollableState>(scrollableFinder)
            .position;
        return position.maxScrollExtent - position.pixels;
      }

      expect(distanceToBottom(), greaterThan(1));
      final pixelsBeforeResume = scrollPixels();

      repository.emitEvent(
        const ChatEvent(
          type: 'session.status',
          properties: <String, dynamic>{
            'sessionID': sessionId,
            'status': <String, dynamic>{'type': 'busy'},
          },
        ),
      );
      await tester.pump();

      repository.emitEvent(
        const ChatEvent(
          type: 'session.status',
          properties: <String, dynamic>{
            'sessionID': sessionId,
            'status': <String, dynamic>{'type': 'idle'},
          },
        ),
      );
      await tester.pumpAndSettle();

      final pixelsAfterPulses = scrollPixels();
      expect(
        pixelsAfterPulses,
        closeTo(pixelsBeforeResume, 1),
        reason: 'scroll position should not shift during passive status pulses',
      );
      expect(
        distanceToBottom(),
        greaterThan(1),
        reason:
            'settled cached restore should stay on the latest-response reveal position after passive pulses',
      );
    },
  );

  testWidgets(
    'timeline cache reused during passive status pulse without message changes',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const sessionId = 'ses_cache_pulse';
      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: sessionId,
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Cache Pulse',
          ),
        ],
      );
      repository.messagesBySession[sessionId] = <ChatMessage>[
        UserMessage(
          id: 'msg_cache_pulse_user',
          sessionId: sessionId,
          time: DateTime.fromMillisecondsSinceEpoch(1100),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_cache_pulse_user',
              messageId: 'msg_cache_pulse_user',
              sessionId: sessionId,
              text: 'Test cache',
            ),
          ],
        ),
        AssistantMessage(
          id: 'msg_cache_pulse_final',
          sessionId: sessionId,
          time: DateTime.fromMillisecondsSinceEpoch(1200),
          completedTime: DateTime.fromMillisecondsSinceEpoch(1210),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_cache_pulse_final',
              messageId: 'msg_cache_pulse_final',
              sessionId: sessionId,
              text: 'Final response',
            ),
          ],
        ),
      ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.initializeProviders();
      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await tester.pumpAndSettle();

      expect(find.text('Final response'), findsOneWidget);

      final messagesBefore = provider.messages.length;
      final versionBefore = provider.messagesVersion;

      repository.emitEvent(
        const ChatEvent(
          type: 'session.status',
          properties: <String, dynamic>{
            'sessionID': sessionId,
            'status': <String, dynamic>{'type': 'busy'},
          },
        ),
      );
      await tester.pump();

      expect(provider.messages.length, messagesBefore);
      expect(provider.messagesVersion, versionBefore);

      repository.emitEvent(
        const ChatEvent(
          type: 'session.status',
          properties: <String, dynamic>{
            'sessionID': sessionId,
            'status': <String, dynamic>{'type': 'idle'},
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(provider.messages.length, messagesBefore);
      expect(find.text('Final response'), findsOneWidget);
    },
  );

  testWidgets(
    'keeps latest assistant work group collapsed after session re-entry during background refresh',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      List<ChatMessage> buildMessages(int offsetMs) {
        DateTime at(int value) =>
            DateTime.fromMillisecondsSinceEpoch(value + offsetMs);

        return <ChatMessage>[
          UserMessage(
            id: 'msg_reentry_refresh_user',
            sessionId: 'ses_assistant_work_reentry_refresh',
            time: at(1100),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_reentry_refresh_user',
                messageId: 'msg_reentry_refresh_user',
                sessionId: 'ses_assistant_work_reentry_refresh',
                text: 'Build this for me',
              ),
            ],
          ),
          AssistantMessage(
            id: 'msg_reentry_refresh_step_1',
            sessionId: 'ses_assistant_work_reentry_refresh',
            time: at(1200),
            completedTime: at(1210),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_reentry_refresh_step_1',
                messageId: 'msg_reentry_refresh_step_1',
                sessionId: 'ses_assistant_work_reentry_refresh',
                text: 'Working step 1',
              ),
            ],
          ),
          AssistantMessage(
            id: 'msg_reentry_refresh_step_2',
            sessionId: 'ses_assistant_work_reentry_refresh',
            time: at(1300),
            completedTime: at(1310),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_reentry_refresh_step_2',
                messageId: 'msg_reentry_refresh_step_2',
                sessionId: 'ses_assistant_work_reentry_refresh',
                text: 'Working step 2',
              ),
            ],
          ),
          AssistantMessage(
            id: 'msg_reentry_refresh_final',
            sessionId: 'ses_assistant_work_reentry_refresh',
            time: at(1400),
            completedTime: at(1410),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_reentry_refresh_final',
                messageId: 'msg_reentry_refresh_final',
                sessionId: 'ses_assistant_work_reentry_refresh',
                text: 'Final assistant response',
              ),
            ],
          ),
        ];
      }

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_assistant_work_reentry_refresh',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Assistant Work Reentry Refresh',
          ),
          ChatSession(
            id: 'ses_assistant_work_reentry_refresh_other',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(2000),
            title: 'Another Session',
          ),
        ],
      );
      repository.messagesBySession['ses_assistant_work_reentry_refresh'] =
          buildMessages(0);
      repository.messagesBySession['ses_assistant_work_reentry_refresh_other'] =
          <ChatMessage>[
            UserMessage(
              id: 'msg_reentry_refresh_other_user',
              sessionId: 'ses_assistant_work_reentry_refresh_other',
              time: DateTime.fromMillisecondsSinceEpoch(2100),
              parts: const <MessagePart>[
                TextPart(
                  id: 'part_reentry_refresh_other_user',
                  messageId: 'msg_reentry_refresh_other_user',
                  sessionId: 'ses_assistant_work_reentry_refresh_other',
                  text: 'Other session',
                ),
              ],
            ),
          ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(
        provider.sessions.firstWhere(
          (session) => session.id == 'ses_assistant_work_reentry_refresh',
        ),
      );
      await tester.pumpAndSettle();

      await provider.selectSession(
        provider.sessions.firstWhere(
          (session) => session.id == 'ses_assistant_work_reentry_refresh_other',
        ),
      );
      await tester.pumpAndSettle();

      await provider.selectSession(
        provider.sessions.firstWhere(
          (session) => session.id == 'ses_assistant_work_reentry_refresh',
        ),
      );
      await tester.pumpAndSettle();

      repository.messagesBySession['ses_assistant_work_reentry_refresh'] =
          buildMessages(5000);
      await provider.loadMessages(
        'ses_assistant_work_reentry_refresh',
        preserveVisibleState: true,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('timeline_collapsed_assistant_work_header'),
        ),
        findsOneWidget,
      );
      expect(find.text('Final assistant response'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Expand'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Hide'), findsNothing);
    },
  );

  testWidgets(
    'keeps empty session placeholder visible during background refresh',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = _ConfigurableDelayFakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_empty_refresh',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Empty Refresh Session',
          ),
        ],
      );
      repository.messagesBySession['ses_empty_refresh'] = <ChatMessage>[];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await tester.pumpAndSettle();

      expect(find.text('Hello! I am your AI assistant'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('session_hydration_loading_indicator'),
        ),
        findsNothing,
      );

      repository.getMessagesGate = Completer<void>();
      final refreshFuture = provider.loadSessions();
      await tester.pump();

      expect(find.text('Hello! I am your AI assistant'), findsOneWidget);
      expect(find.byType(ChatSkeletonShimmer), findsNothing);
      expect(
        find.byKey(
          const ValueKey<String>('session_hydration_loading_indicator'),
        ),
        findsNothing,
      );

      repository.getMessagesGate?.complete();
      await refreshFuture;
      await tester.pumpAndSettle();

      expect(find.text('Hello! I am your AI assistant'), findsOneWidget);
      expect(find.byType(ChatSkeletonShimmer), findsNothing);
      expect(
        find.byKey(
          const ValueKey<String>('session_hydration_loading_indicator'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'keeps warm cached session visible while return revalidation is pending',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = _ConfigurableDelayFakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_cached_return_a',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Cached Return A',
          ),
          ChatSession(
            id: 'ses_cached_return_b',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(2000),
            title: 'Cached Return B',
          ),
        ],
      );
      repository.messagesBySession['ses_cached_return_a'] = <ChatMessage>[
        UserMessage(
          id: 'msg_cached_return_a_user',
          sessionId: 'ses_cached_return_a',
          time: DateTime.fromMillisecondsSinceEpoch(1100),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_cached_return_a_user',
              messageId: 'msg_cached_return_a_user',
              sessionId: 'ses_cached_return_a',
              text: 'Show cached return',
            ),
          ],
        ),
        AssistantMessage(
          id: 'msg_cached_return_a_final',
          sessionId: 'ses_cached_return_a',
          time: DateTime.fromMillisecondsSinceEpoch(1200),
          completedTime: DateTime.fromMillisecondsSinceEpoch(1210),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_cached_return_a_final',
              messageId: 'msg_cached_return_a_final',
              sessionId: 'ses_cached_return_a',
              text: 'Cached session content',
            ),
          ],
        ),
      ];
      repository.messagesBySession['ses_cached_return_b'] = <ChatMessage>[
        UserMessage(
          id: 'msg_cached_return_b_user',
          sessionId: 'ses_cached_return_b',
          time: DateTime.fromMillisecondsSinceEpoch(2100),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_cached_return_b_user',
              messageId: 'msg_cached_return_b_user',
              sessionId: 'ses_cached_return_b',
              text: 'Switch away',
            ),
          ],
        ),
        AssistantMessage(
          id: 'msg_cached_return_b_final',
          sessionId: 'ses_cached_return_b',
          time: DateTime.fromMillisecondsSinceEpoch(2200),
          completedTime: DateTime.fromMillisecondsSinceEpoch(2210),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_cached_return_b_final',
              messageId: 'msg_cached_return_b_final',
              sessionId: 'ses_cached_return_b',
              text: 'Other session content',
            ),
          ],
        ),
      ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(
        provider.sessions.firstWhere(
          (session) => session.id == 'ses_cached_return_a',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cached session content'), findsOneWidget);

      await provider.selectSession(
        provider.sessions.firstWhere(
          (session) => session.id == 'ses_cached_return_b',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Other session content'), findsOneWidget);

      repository.getMessagesGate = Completer<void>();
      await provider.selectSession(
        provider.sessions.firstWhere(
          (session) => session.id == 'ses_cached_return_a',
        ),
      );
      await tester.pump();

      expect(find.text('Cached session content'), findsOneWidget);
      expect(find.text('Other session content'), findsNothing);
      expect(find.byType(ChatSkeletonShimmer), findsNothing);
      expect(
        find.byKey(
          const ValueKey<String>('session_hydration_loading_indicator'),
        ),
        findsNothing,
      );

      repository.getMessagesGate?.complete();
      await tester.pumpAndSettle();

      expect(find.text('Cached session content'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('session_hydration_loading_indicator'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('merges consecutive assistant tool-only messages into one bubble', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_merge_tool_run',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Merge Tool Run',
        ),
      ],
    );

    repository.messagesBySession['ses_merge_tool_run'] = <ChatMessage>[
      UserMessage(
        id: 'msg_merge_tool_user',
        sessionId: 'ses_merge_tool_run',
        time: DateTime.fromMillisecondsSinceEpoch(1100),
        parts: const <MessagePart>[
          TextPart(
            id: 'part_merge_tool_user',
            messageId: 'msg_merge_tool_user',
            sessionId: 'ses_merge_tool_run',
            text: 'Run grouped tools',
          ),
        ],
      ),
      AssistantMessage(
        id: 'msg_merge_tool_1',
        sessionId: 'ses_merge_tool_run',
        time: DateTime.fromMillisecondsSinceEpoch(1200),
        completedTime: DateTime.fromMillisecondsSinceEpoch(1210),
        parts: <MessagePart>[
          const AgentPart(
            id: 'part_merge_tool_agent_1',
            messageId: 'msg_merge_tool_1',
            sessionId: 'ses_merge_tool_run',
            name: 'reviewer',
          ),
          ToolPart(
            id: 'part_merge_tool_1',
            messageId: 'msg_merge_tool_1',
            sessionId: 'ses_merge_tool_run',
            callId: 'call_merge_tool_1',
            tool: 'bash',
            state: ToolStateCompleted(
              input: const <String, dynamic>{'command': 'pwd'},
              output: '/tmp/work',
              time: ToolTime(
                start: DateTime.fromMillisecondsSinceEpoch(1200),
                end: DateTime.fromMillisecondsSinceEpoch(1205),
              ),
            ),
          ),
        ],
      ),
      AssistantMessage(
        id: 'msg_merge_tool_2',
        sessionId: 'ses_merge_tool_run',
        time: DateTime.fromMillisecondsSinceEpoch(1250),
        completedTime: DateTime.fromMillisecondsSinceEpoch(1260),
        parts: <MessagePart>[
          const SubtaskPart(
            id: 'part_merge_tool_subtask_2',
            messageId: 'msg_merge_tool_2',
            sessionId: 'ses_merge_tool_run',
            prompt: 'group',
            description: 'Tool execution step',
            agent: 'reviewer',
          ),
          ToolPart(
            id: 'part_merge_tool_2',
            messageId: 'msg_merge_tool_2',
            sessionId: 'ses_merge_tool_run',
            callId: 'call_merge_tool_2',
            tool: 'read',
            state: ToolStateCompleted(
              input: const <String, dynamic>{'filePath': 'lib/main.dart'},
              output: 'line 1\nline 2',
              time: ToolTime(
                start: DateTime.fromMillisecondsSinceEpoch(1250),
                end: DateTime.fromMillisecondsSinceEpoch(1255),
              ),
            ),
          ),
        ],
      ),
      AssistantMessage(
        id: 'msg_merge_tool_final',
        sessionId: 'ses_merge_tool_run',
        time: DateTime.fromMillisecondsSinceEpoch(1300),
        completedTime: DateTime.fromMillisecondsSinceEpoch(1310),
        parts: const <MessagePart>[
          TextPart(
            id: 'part_merge_tool_final',
            messageId: 'msg_merge_tool_final',
            sessionId: 'ses_merge_tool_run',
            text: 'Final assistant answer',
          ),
        ],
      ),
    ];

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey<String>('timeline_collapsed_assistant_work_header'),
      ),
      findsOneWidget,
    );
    expect(find.text('2 work messages'), findsOneWidget);
    expect(find.text('Final assistant answer'), findsOneWidget);

    expect(find.text('Details'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'tool_chain_toggle_merged_tool_run_msg_merge_tool_1_call_merge_tool_1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Running command'), findsOneWidget);
    expect(find.text('Reading file'), findsOneWidget);
  });

  testWidgets(
    'keeps active-turn tool-only messages separate before the final assistant response',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_no_final_collapse',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'No Final Collapse',
          ),
        ],
      );

      repository.messagesBySession['ses_no_final_collapse'] = <ChatMessage>[
        UserMessage(
          id: 'msg_no_final_user',
          sessionId: 'ses_no_final_collapse',
          time: DateTime.fromMillisecondsSinceEpoch(1100),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_no_final_user',
              messageId: 'msg_no_final_user',
              sessionId: 'ses_no_final_collapse',
              text: 'Run tools',
            ),
          ],
        ),
        AssistantMessage(
          id: 'msg_no_final_tool_1',
          sessionId: 'ses_no_final_collapse',
          time: DateTime.fromMillisecondsSinceEpoch(1200),
          completedTime: DateTime.fromMillisecondsSinceEpoch(1210),
          parts: <MessagePart>[
            ToolPart(
              id: 'part_no_final_tool_1',
              messageId: 'msg_no_final_tool_1',
              sessionId: 'ses_no_final_collapse',
              callId: 'call_no_final_tool_1',
              tool: 'bash',
              state: ToolStateCompleted(
                input: const <String, dynamic>{'command': 'pwd'},
                output: '/tmp/no-final',
                time: ToolTime(
                  start: DateTime.fromMillisecondsSinceEpoch(1200),
                  end: DateTime.fromMillisecondsSinceEpoch(1205),
                ),
              ),
            ),
          ],
        ),
        AssistantMessage(
          id: 'msg_no_final_tool_2',
          sessionId: 'ses_no_final_collapse',
          time: DateTime.fromMillisecondsSinceEpoch(1250),
          completedTime: DateTime.fromMillisecondsSinceEpoch(1260),
          parts: <MessagePart>[
            ToolPart(
              id: 'part_no_final_tool_2',
              messageId: 'msg_no_final_tool_2',
              sessionId: 'ses_no_final_collapse',
              callId: 'call_no_final_tool_2',
              tool: 'read',
              state: ToolStateCompleted(
                input: const <String, dynamic>{'filePath': 'README.md'},
                output: 'hello',
                time: ToolTime(
                  start: DateTime.fromMillisecondsSinceEpoch(1250),
                  end: DateTime.fromMillisecondsSinceEpoch(1255),
                ),
              ),
            ),
          ],
        ),
      ];
      repository.sessionStatusById = const <String, SessionStatusInfo>{
        'ses_no_final_collapse': SessionStatusInfo(
          type: SessionStatusType.busy,
        ),
      };

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.initializeProviders();
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('timeline_collapsed_assistant_work_header'),
        ),
        findsNothing,
      );
      expect(find.text('Details'), findsNWidgets(2));
    },
  );

  testWidgets(
    'heals bottom gap when active-turn content shrinks during passive follow',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const sessionId = 'ses_active_turn_shrink_heal';
      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: sessionId,
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Active Turn Shrink Heal',
          ),
        ],
      );
      final longActiveText = List<String>.filled(
        320,
        'active turn content should not leave a blank bottom vacuum while following',
      ).join(' ');
      repository.messagesBySession[sessionId] = <ChatMessage>[
        ..._threadMessages(sessionId, 18),
        AssistantMessage(
          id: 'msg_active_turn_shrink',
          sessionId: sessionId,
          time: DateTime.fromMillisecondsSinceEpoch(90000),
          parts: <MessagePart>[
            TextPart(
              id: 'part_active_turn_shrink',
              messageId: 'msg_active_turn_shrink',
              sessionId: sessionId,
              text: longActiveText,
            ),
          ],
        ),
      ];
      repository.sessionStatusById = const <String, SessionStatusInfo>{
        sessionId: SessionStatusInfo(type: SessionStatusType.busy),
      };

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.initializeProviders();
      await tester.pumpAndSettle();

      final listFinder = find.byKey(
        const ValueKey<String>('chat_message_list'),
      );
      final scrollableFinder = find.descendant(
        of: listFinder,
        matching: find.byType(Scrollable),
      );

      double distanceToBottom() {
        final position = tester
            .state<ScrollableState>(scrollableFinder)
            .position;
        return position.maxScrollExtent - position.pixels;
      }

      expect(distanceToBottom(), lessThanOrEqualTo(1));

      repository.messagesBySession[sessionId] = <ChatMessage>[
        ..._threadMessages(sessionId, 18),
        AssistantMessage(
          id: 'msg_active_turn_shrink',
          sessionId: sessionId,
          time: DateTime.fromMillisecondsSinceEpoch(90000),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_active_turn_shrink',
              messageId: 'msg_active_turn_shrink',
              sessionId: sessionId,
              text: 'short active turn content',
            ),
          ],
        ),
      ];

      await provider.refreshActiveSessionView(
        reason: 'active-turn-shrink-heal',
        includeStatus: false,
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(distanceToBottom(), lessThanOrEqualTo(1));
      expect(find.byTooltip('Go to latest message'), findsNothing);
    },
  );

  testWidgets(
    'does not auto-heal active-turn shrink after the user scrolls away',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const sessionId = 'ses_active_turn_shrink_manual_pause';
      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: sessionId,
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Active Turn Shrink Manual Pause',
          ),
        ],
      );
      final longActiveText = List<String>.filled(
        320,
        'manual scroll away should block the active-turn shrink heal',
      ).join(' ');
      repository.messagesBySession[sessionId] = <ChatMessage>[
        ..._threadMessages(sessionId, 40),
        AssistantMessage(
          id: 'msg_active_turn_manual_pause',
          sessionId: sessionId,
          time: DateTime.fromMillisecondsSinceEpoch(90000),
          parts: <MessagePart>[
            TextPart(
              id: 'part_active_turn_manual_pause',
              messageId: 'msg_active_turn_manual_pause',
              sessionId: sessionId,
              text: longActiveText,
            ),
          ],
        ),
      ];
      repository.sessionStatusById = const <String, SessionStatusInfo>{
        sessionId: SessionStatusInfo(type: SessionStatusType.busy),
      };

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.initializeProviders();
      await tester.pumpAndSettle();

      final listFinder = find.byKey(
        const ValueKey<String>('chat_message_list'),
      );
      final scrollableFinder = find.descendant(
        of: listFinder,
        matching: find.byType(Scrollable),
      );

      double distanceToBottom() {
        final position = tester
            .state<ScrollableState>(scrollableFinder)
            .position;
        return position.maxScrollExtent - position.pixels;
      }

      await tester.drag(listFinder, const Offset(0, 140));
      await tester.drag(listFinder, const Offset(0, 260));
      await tester.pumpAndSettle();

      expect(distanceToBottom(), greaterThan(1));

      repository.messagesBySession[sessionId] = <ChatMessage>[
        ..._threadMessages(sessionId, 40),
        AssistantMessage(
          id: 'msg_active_turn_manual_pause',
          sessionId: sessionId,
          time: DateTime.fromMillisecondsSinceEpoch(90000),
          parts: <MessagePart>[
            TextPart(
              id: 'part_active_turn_manual_pause',
              messageId: 'msg_active_turn_manual_pause',
              sessionId: sessionId,
              text: List<String>.filled(
                260,
                'slightly shorter active turn content should not yank the user back to bottom',
              ).join(' '),
            ),
          ],
        ),
      ];

      await provider.refreshActiveSessionView(
        reason: 'active-turn-shrink-manual-pause',
        includeStatus: false,
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(distanceToBottom(), greaterThan(1));
      expect(find.byTooltip('Go to latest message'), findsOneWidget);
    },
  );

  testWidgets(
    'refresh keeps visible tool operations during optimistic echo reconcile',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_refresh_tool_reconcile',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Refresh Tool Reconcile',
          ),
        ],
      );
      final streamController = StreamController<Either<Failure, ChatMessage>>();
      addTearDown(() async {
        if (!streamController.isClosed) {
          await streamController.close();
        }
      });
      repository.sendMessageHandler = (_, _, _, _) => streamController.stream;

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.initializeProviders();
      await tester.pumpAndSettle();

      final chatInputFieldFinder = find.descendant(
        of: find.byKey(const ValueKey<String>('composer_input_row')),
        matching: find.byType(TextField),
      );

      await tester.enterText(chatInputFieldFinder, 'inspect repo');
      await tester.pump();
      await tester.tap(find.byIcon(Symbols.send_rounded));
      await tester.pump();

      final assistantStreaming = AssistantMessage(
        id: 'msg_widget_tool_refresh_stream',
        sessionId: 'ses_refresh_tool_reconcile',
        time: DateTime.fromMillisecondsSinceEpoch(1200),
        parts: <MessagePart>[
          ToolPart(
            id: 'part_widget_tool_refresh_stream',
            messageId: 'msg_widget_tool_refresh_stream',
            sessionId: 'ses_refresh_tool_reconcile',
            callId: 'call_widget_tool_refresh_stream',
            tool: 'bash',
            state: ToolStateRunning(
              input: const <String, dynamic>{
                'description': 'Running command',
                'command': 'ls',
              },
              time: DateTime.fromMillisecondsSinceEpoch(1200),
            ),
          ),
        ],
      );
      streamController.add(Right(assistantStreaming));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));

      expect(find.text('Details'), findsOneWidget);
      await tester.tap(find.text('Details'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.text('Running command'), findsOneWidget);

      final serverUserEcho = UserMessage(
        id: 'msg_widget_user_refresh_stream',
        sessionId: 'ses_refresh_tool_reconcile',
        time: DateTime.fromMillisecondsSinceEpoch(1100),
        parts: const <MessagePart>[
          TextPart(
            id: 'part_widget_user_refresh_stream',
            messageId: 'msg_widget_user_refresh_stream',
            sessionId: 'ses_refresh_tool_reconcile',
            text: 'inspect repo',
          ),
        ],
      );
      repository.messagesBySession['ses_refresh_tool_reconcile'] =
          <ChatMessage>[serverUserEcho, assistantStreaming];

      await provider.refreshActiveSessionView(
        reason: 'widget-stream-refresh',
        includeStatus: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));

      expect(find.text('Running command'), findsOneWidget);

      repository.messagesBySession['ses_refresh_tool_reconcile'] =
          <ChatMessage>[
            serverUserEcho,
            AssistantMessage(
              id: 'msg_widget_tool_refresh_stream',
              sessionId: 'ses_refresh_tool_reconcile',
              time: DateTime.fromMillisecondsSinceEpoch(1200),
              completedTime: DateTime.fromMillisecondsSinceEpoch(1400),
              parts: <MessagePart>[
                ToolPart(
                  id: 'part_widget_tool_refresh_stream',
                  messageId: 'msg_widget_tool_refresh_stream',
                  sessionId: 'ses_refresh_tool_reconcile',
                  callId: 'call_widget_tool_refresh_stream',
                  tool: 'bash',
                  state: ToolStateCompleted(
                    input: const <String, dynamic>{'command': 'ls'},
                    output: 'README.md\nlib',
                    time: ToolTime(
                      start: DateTime.fromMillisecondsSinceEpoch(1200),
                      end: DateTime.fromMillisecondsSinceEpoch(1350),
                    ),
                  ),
                ),
                const TextPart(
                  id: 'part_widget_tool_refresh_stream_final',
                  messageId: 'msg_widget_tool_refresh_stream',
                  sessionId: 'ses_refresh_tool_reconcile',
                  text: 'repo inspected',
                ),
              ],
            ),
          ];
      await provider.refreshActiveSessionView(
        reason: 'widget-final-stream-refresh',
        includeStatus: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(find.text('repo inspected'), findsOneWidget);
    },
  );

  testWidgets(
    'updates final assistant bubble after message.updated with same id',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_message_updated_final',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Realtime Final Message',
          ),
        ],
      );

      repository.messagesBySession['ses_message_updated_final'] = <ChatMessage>[
        AssistantMessage(
          id: 'msg_final_same_id',
          sessionId: 'ses_message_updated_final',
          time: DateTime.fromMillisecondsSinceEpoch(1200),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_final_same_id_draft',
              messageId: 'msg_final_same_id',
              sessionId: 'ses_message_updated_final',
              text: 'draft answer',
            ),
          ],
        ),
      ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await tester.pumpAndSettle();

      expect(find.text('draft answer'), findsOneWidget);

      repository.messagesBySession['ses_message_updated_final'] = <ChatMessage>[
        AssistantMessage(
          id: 'msg_final_same_id',
          sessionId: 'ses_message_updated_final',
          time: DateTime.fromMillisecondsSinceEpoch(1200),
          completedTime: DateTime.fromMillisecondsSinceEpoch(1300),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_final_same_id_done',
              messageId: 'msg_final_same_id',
              sessionId: 'ses_message_updated_final',
              text: 'final answer visible',
            ),
          ],
        ),
      ];

      repository.emitEvent(
        const ChatEvent(
          type: 'message.updated',
          properties: <String, dynamic>{
            'info': <String, dynamic>{
              'id': 'msg_final_same_id',
              'sessionID': 'ses_message_updated_final',
            },
          },
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pumpAndSettle();

      expect(find.text('final answer visible'), findsOneWidget);
      expect(find.text('draft answer'), findsNothing);
    },
  );

  testWidgets(
    'delta refresh promotes latest server tail until fallback full fetch resolves',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const sessionId = 'ses_delta_no_overlap';
      final repository = _ConfigurableDelayFakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: sessionId,
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Delta No Overlap Session',
          ),
        ],
      );

      final initialMessages = List<ChatMessage>.generate(250, (index) {
        final messageId = 'msg_cached_$index';
        return UserMessage(
          id: messageId,
          sessionId: sessionId,
          time: DateTime.fromMillisecondsSinceEpoch(index * 1000),
          parts: <MessagePart>[
            TextPart(
              id: 'part_cached_$index',
              messageId: messageId,
              sessionId: sessionId,
              text: 'cached message $index',
            ),
          ],
        );
      });
      final refreshedMessages = List<ChatMessage>.generate(250, (index) {
        final messageId = 'msg_server_$index';
        return UserMessage(
          id: messageId,
          sessionId: sessionId,
          time: DateTime.fromMillisecondsSinceEpoch(300000 + index * 1000),
          parts: <MessagePart>[
            TextPart(
              id: 'part_server_$index',
              messageId: messageId,
              sessionId: sessionId,
              text: 'server message $index',
            ),
          ],
        );
      });
      repository.messagesBySession[sessionId] = List<ChatMessage>.of(
        initialMessages,
      );

      final fullFetchGate = Completer<void>();
      var shouldGateUnlimitedFetch = false;
      repository.getMessagesHandler =
          (_, requestedSessionId, {String? directory, int? limit}) async {
            final output = List<ChatMessage>.from(
              repository.messagesBySession[requestedSessionId] ?? const [],
            );
            if (limit == null) {
              if (!shouldGateUnlimitedFetch) {
                return Right(output);
              }
              await fullFetchGate.future;
              return Right(output);
            }
            if (limit > 0 && output.length > limit) {
              return Right(output.sublist(output.length - limit));
            }
            return Right(output);
          };

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(provider.messages.length, 250);
      expect(provider.messages.last.id, 'msg_cached_249');

      repository.messagesBySession[sessionId] = List<ChatMessage>.of(
        refreshedMessages,
      );
      shouldGateUnlimitedFetch = true;

      await provider.refreshActiveSessionView(
        reason: 'delta-no-overlap',
        includeStatus: false,
      );
      await tester.pump();

      expect(provider.messages.length, 200);
      expect(provider.messages.first.id, 'msg_server_50');
      expect(provider.messages.last.id, 'msg_server_249');
      expect(provider.hasMoreOldMessages, isTrue);

      fullFetchGate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pumpAndSettle();

      expect(provider.messages.length, 250);
      expect(provider.messages.first.id, 'msg_server_0');
      expect(provider.messages.last.id, 'msg_server_249');
    },
  );

  testWidgets(
    'tool-only turn completion keeps viewport pinned instead of revealing older assistant history',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const sessionId = 'ses_tool_only_reveal_guard';
      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: sessionId,
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Tool Only Reveal Guard',
          ),
        ],
      );

      final seededMessages = _threadMessages(sessionId, 40);
      seededMessages[10] = AssistantMessage(
        id: 'msg_previous_successful_assistant',
        sessionId: sessionId,
        time: DateTime.fromMillisecondsSinceEpoch(10500),
        completedTime: DateTime.fromMillisecondsSinceEpoch(10600),
        parts: const <MessagePart>[
          TextPart(
            id: 'part_previous_successful_assistant',
            messageId: 'msg_previous_successful_assistant',
            sessionId: sessionId,
            text: 'older successful assistant anchor',
          ),
        ],
      );
      repository.messagesBySession[sessionId] = seededMessages;

      final streamController = StreamController<Either<Failure, ChatMessage>>();
      addTearDown(() async {
        if (!streamController.isClosed) {
          await streamController.close();
        }
      });
      repository.sendMessageHandler = (_, _, _, _) => streamController.stream;

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.initializeProviders();
      await tester.pumpAndSettle();

      final listFinder = find.byKey(
        const ValueKey<String>('chat_message_list'),
      );
      final scrollableFinder = find.descendant(
        of: listFinder,
        matching: find.byType(Scrollable),
      );
      final scrollableBefore = tester.state<ScrollableState>(scrollableFinder);
      expect(
        scrollableBefore.position.maxScrollExtent -
            scrollableBefore.position.pixels,
        lessThanOrEqualTo(1),
      );

      await provider.sendMessage('run tool only step');
      await tester.pump();

      streamController.add(
        Right(
          AssistantMessage(
            id: 'msg_tool_only_tail',
            sessionId: sessionId,
            time: DateTime.fromMillisecondsSinceEpoch(60000),
            completedTime: DateTime.fromMillisecondsSinceEpoch(60100),
            parts: <MessagePart>[
              ToolPart(
                id: 'part_tool_only_tail',
                messageId: 'msg_tool_only_tail',
                sessionId: sessionId,
                callId: 'call_tool_only_tail',
                tool: 'bash',
                state: ToolStateCompleted(
                  input: const <String, dynamic>{'command': 'pwd'},
                  output: '/tmp/tool-only-tail',
                  time: ToolTime(
                    start: DateTime.fromMillisecondsSinceEpoch(60000),
                    end: DateTime.fromMillisecondsSinceEpoch(60080),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await streamController.close();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));
      await tester.pumpAndSettle();

      final scrollableAfter = tester.state<ScrollableState>(scrollableFinder);
      expect(
        scrollableAfter.position.maxScrollExtent -
            scrollableAfter.position.pixels,
        lessThanOrEqualTo(1),
      );
      expect(find.byTooltip('Go to latest message'), findsNothing);
      expect(find.text('run tool only step'), findsOneWidget);
    },
  );

  testWidgets('refreshes active session message list when app resumes', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_resume_refresh',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Resume Refresh Session',
        ),
      ],
    );

    repository.messagesBySession['ses_resume_refresh'] = <ChatMessage>[
      AssistantMessage(
        id: 'msg_resume_refresh',
        sessionId: 'ses_resume_refresh',
        time: DateTime.fromMillisecondsSinceEpoch(1200),
        parts: const <MessagePart>[
          TextPart(
            id: 'part_resume_refresh_draft',
            messageId: 'msg_resume_refresh',
            sessionId: 'ses_resume_refresh',
            text: 'draft before background',
          ),
        ],
      ),
    ];

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pumpAndSettle();

    expect(find.text('draft before background'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    repository.messagesBySession['ses_resume_refresh'] = <ChatMessage>[
      AssistantMessage(
        id: 'msg_resume_refresh',
        sessionId: 'ses_resume_refresh',
        time: DateTime.fromMillisecondsSinceEpoch(1200),
        completedTime: DateTime.fromMillisecondsSinceEpoch(1300),
        parts: const <MessagePart>[
          TextPart(
            id: 'part_resume_refresh_final',
            messageId: 'msg_resume_refresh',
            sessionId: 'ses_resume_refresh',
            text: 'final after resume sync',
          ),
        ],
      ),
    ];

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle();

    expect(find.text('final after resume sync'), findsOneWidget);
    expect(find.text('draft before background'), findsNothing);
  });

  testWidgets(
    'resuming a settled cached session reveals the latest response without a second jump',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_resume_reveal',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Resume Reveal Session',
          ),
        ],
      );
      final longLatestText = List<String>.filled(
        120,
        'latest message should start at top after resume',
      ).join(' ');
      repository.messagesBySession['ses_resume_reveal'] = <ChatMessage>[
        ..._threadMessages('ses_resume_reveal', 28),
        AssistantMessage(
          id: 'msg_resume_reveal_latest',
          sessionId: 'ses_resume_reveal',
          time: DateTime.fromMillisecondsSinceEpoch(35000),
          completedTime: DateTime.fromMillisecondsSinceEpoch(35500),
          parts: <MessagePart>[
            TextPart(
              id: 'part_resume_reveal_latest',
              messageId: 'msg_resume_reveal_latest',
              sessionId: 'ses_resume_reveal',
              text: longLatestText,
            ),
          ],
        ),
      ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await tester.pumpAndSettle();

      final listFinder = find.byKey(
        const ValueKey<String>('chat_message_list'),
      );
      final scrollableFinder = find.descendant(
        of: listFinder,
        matching: find.byType(Scrollable),
      );
      final scrollableBefore = tester.state<ScrollableState>(scrollableFinder);
      final pixelsBeforeResume = scrollableBefore.position.pixels;
      expect(
        scrollableBefore.position.maxScrollExtent -
            scrollableBefore.position.pixels,
        greaterThan(1),
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pumpAndSettle();

      final scrollableAfter = tester.state<ScrollableState>(scrollableFinder);
      expect(
        scrollableAfter.position.maxScrollExtent -
            scrollableAfter.position.pixels,
        greaterThan(1),
      );
      expect(scrollableAfter.position.pixels, closeTo(pixelsBeforeResume, 1));
    },
  );

  testWidgets('resuming after new final content reveals the latest response', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_resume_reveal_changed',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Resume Reveal Changed Session',
        ),
      ],
    );
    repository.messagesBySession['ses_resume_reveal_changed'] = _threadMessages(
      'ses_resume_reveal_changed',
      28,
    );

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pumpAndSettle();

    final listFinder = find.byKey(const ValueKey<String>('chat_message_list'));
    final scrollableFinder = find.descendant(
      of: listFinder,
      matching: find.byType(Scrollable),
    );
    final scrollableBefore = tester.state<ScrollableState>(scrollableFinder);
    expect(
      scrollableBefore.position.maxScrollExtent -
          scrollableBefore.position.pixels,
      lessThanOrEqualTo(1),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    final longLatestText = List<String>.filled(
      120,
      'latest message should start at top after resume when new content arrived',
    ).join(' ');
    repository.messagesBySession['ses_resume_reveal_changed'] = <ChatMessage>[
      ..._threadMessages('ses_resume_reveal_changed', 28),
      AssistantMessage(
        id: 'msg_resume_reveal_changed_latest',
        sessionId: 'ses_resume_reveal_changed',
        time: DateTime.fromMillisecondsSinceEpoch(35000),
        completedTime: DateTime.fromMillisecondsSinceEpoch(35500),
        parts: <MessagePart>[
          TextPart(
            id: 'part_resume_reveal_changed_latest',
            messageId: 'msg_resume_reveal_changed_latest',
            sessionId: 'ses_resume_reveal_changed',
            text: longLatestText,
          ),
        ],
      ),
    ];

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle();

    final scrollableAfter = tester.state<ScrollableState>(scrollableFinder);
    expect(
      scrollableAfter.position.maxScrollExtent -
          scrollableAfter.position.pixels,
      greaterThan(1),
    );
    expect(find.byTooltip('Go to latest message'), findsOneWidget);
  });

  testWidgets(
    'long final assistant reveal exits bottom follow for reading mode',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const sessionId = 'ses_final_reveal_alignment';
      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: sessionId,
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Final Reveal Alignment',
          ),
        ],
      );
      repository.messagesBySession[sessionId] = _threadMessages(sessionId, 30);

      final streamController = StreamController<Either<Failure, ChatMessage>>();
      addTearDown(() async {
        if (!streamController.isClosed) {
          await streamController.close();
        }
      });
      repository.sendMessageHandler = (_, _, _, _) => streamController.stream;

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.initializeProviders();
      await tester.pumpAndSettle();

      await provider.sendMessage('finish with a long final answer');
      await tester.pump();

      final longFinalFiller = List<String>.filled(
        320,
        'final answer should start around forty percent of the viewport height',
      ).join(' ');
      streamController.add(
        Right(
          AssistantMessage(
            id: 'msg_final_reveal_alignment',
            sessionId: sessionId,
            time: DateTime.fromMillisecondsSinceEpoch(60000),
            completedTime: DateTime.fromMillisecondsSinceEpoch(60100),
            parts: <MessagePart>[
              TextPart(
                id: 'part_final_reveal_alignment_intro',
                messageId: 'msg_final_reveal_alignment',
                sessionId: sessionId,
                text: 'Final reveal starts here',
              ),
              TextPart(
                id: 'part_final_reveal_alignment_body',
                messageId: 'msg_final_reveal_alignment',
                sessionId: sessionId,
                text: longFinalFiller,
              ),
            ],
          ),
        ),
      );
      await streamController.close();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 320));
      await tester.pumpAndSettle();

      final listFinder = find.byKey(
        const ValueKey<String>('chat_message_list'),
      );
      final scrollableFinder = find.descendant(
        of: listFinder,
        matching: find.byType(Scrollable),
      );
      final scrollableAfter = tester.state<ScrollableState>(scrollableFinder);
      expect(
        scrollableAfter.position.maxScrollExtent -
            scrollableAfter.position.pixels,
        greaterThan(1),
      );
      expect(find.byTooltip('Go to latest message'), findsOneWidget);
    },
  );

  testWidgets(
    'short final assistant answer that already fits does not reposition away from bottom',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const sessionId = 'ses_final_reveal_short';
      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: sessionId,
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Final Reveal Short',
          ),
        ],
      );
      repository.messagesBySession[sessionId] = _threadMessages(sessionId, 8);

      final streamController = StreamController<Either<Failure, ChatMessage>>();
      addTearDown(() async {
        if (!streamController.isClosed) {
          await streamController.close();
        }
      });
      repository.sendMessageHandler = (_, _, _, _) => streamController.stream;

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.initializeProviders();
      await tester.pumpAndSettle();

      await provider.sendMessage('finish with a short final answer');
      await tester.pump();

      streamController.add(
        Right(
          AssistantMessage(
            id: 'msg_final_reveal_short',
            sessionId: sessionId,
            time: DateTime.fromMillisecondsSinceEpoch(60000),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_final_reveal_short',
                messageId: 'msg_final_reveal_short',
                sessionId: sessionId,
                text: 'Short visible answer',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final listFinder = find.byKey(
        const ValueKey<String>('chat_message_list'),
      );
      final scrollableFinder = find.descendant(
        of: listFinder,
        matching: find.byType(Scrollable),
      );
      final scrollableBefore = tester.state<ScrollableState>(scrollableFinder);
      final pixelsBeforeCompletion = scrollableBefore.position.pixels;

      streamController.add(
        Right(
          AssistantMessage(
            id: 'msg_final_reveal_short',
            sessionId: sessionId,
            time: DateTime.fromMillisecondsSinceEpoch(60000),
            completedTime: DateTime.fromMillisecondsSinceEpoch(60100),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_final_reveal_short',
                messageId: 'msg_final_reveal_short',
                sessionId: sessionId,
                text: 'Short visible answer',
              ),
            ],
          ),
        ),
      );
      await streamController.close();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 320));
      await tester.pumpAndSettle();

      final scrollableAfter = tester.state<ScrollableState>(scrollableFinder);
      expect(
        scrollableAfter.position.pixels,
        closeTo(pixelsBeforeCompletion, 1),
      );
      expect(
        scrollableAfter.position.maxScrollExtent -
            scrollableAfter.position.pixels,
        lessThanOrEqualTo(1),
      );
      expect(find.byTooltip('Go to latest message'), findsNothing);
    },
  );

  testWidgets('keeps latest follow when app resumes during active response', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_resume_streaming',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Resume Streaming Session',
        ),
      ],
    );
    repository.messagesBySession['ses_resume_streaming'] = _threadMessages(
      'ses_resume_streaming',
      40,
    );

    final streamController = StreamController<Either<Failure, ChatMessage>>();
    addTearDown(() async {
      if (!streamController.isClosed) {
        await streamController.close();
      }
    });
    repository.sendMessageHandler = (_, _, _, _) => streamController.stream;

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await provider.initializeProviders();
    await tester.pumpAndSettle();

    final listFinder = find.byKey(const ValueKey<String>('chat_message_list'));
    final scrollableFinder = find.descendant(
      of: listFinder,
      matching: find.byType(Scrollable),
    );

    await provider.sendMessage('streaming while app resumes');
    await tester.pump();
    streamController.add(
      Right(
        AssistantMessage(
          id: 'msg_resume_streaming_partial',
          sessionId: 'ses_resume_streaming',
          time: DateTime.fromMillisecondsSinceEpoch(60000),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_resume_streaming_partial',
              messageId: 'msg_resume_streaming_partial',
              sessionId: 'ses_resume_streaming',
              text: 'partial assistant response while streaming',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pumpAndSettle();

    final scrollableAfter = tester.state<ScrollableState>(scrollableFinder);
    expect(
      scrollableAfter.position.maxScrollExtent -
          scrollableAfter.position.pixels,
      lessThanOrEqualTo(1),
    );
    expect(find.byTooltip('Go to latest message'), findsNothing);
  });

  testWidgets(
    'desktop window restore reveals the latest response for a settled cached session',
    (WidgetTester tester) async {
      final previousPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await tester.binding.setSurfaceSize(const Size(1000, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final repository = FakeChatRepository(
          sessions: <ChatSession>[
            ChatSession(
              id: 'ses_desktop_restore_settled',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              title: 'Desktop Restore Settled',
            ),
          ],
        );
        final longLatestText = List<String>.filled(
          120,
          'desktop window restore should reveal the latest settled response',
        ).join(' ');
        repository.messagesBySession['ses_desktop_restore_settled'] =
            <ChatMessage>[
              ..._threadMessages('ses_desktop_restore_settled', 28),
              AssistantMessage(
                id: 'msg_desktop_restore_settled_latest',
                sessionId: 'ses_desktop_restore_settled',
                time: DateTime.fromMillisecondsSinceEpoch(35000),
                completedTime: DateTime.fromMillisecondsSinceEpoch(35500),
                parts: <MessagePart>[
                  TextPart(
                    id: 'part_desktop_restore_settled_latest',
                    messageId: 'msg_desktop_restore_settled_latest',
                    sessionId: 'ses_desktop_restore_settled',
                    text: longLatestText,
                  ),
                ],
              ),
            ];

        final localDataSource = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test';
        final provider = _buildChatProvider(
          chatRepository: repository,
          localDataSource: localDataSource,
        );
        final appProvider = _buildAppProvider(localDataSource: localDataSource);

        await tester.pumpWidget(_testApp(provider, appProvider));
        await tester.pumpAndSettle();

        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);
        await tester.pumpAndSettle();

        final listFinder = find.byKey(
          const ValueKey<String>('chat_message_list'),
        );
        final scrollableFinder = find.descendant(
          of: listFinder,
          matching: find.byType(Scrollable),
        );
        final scrollableBefore = tester.state<ScrollableState>(
          scrollableFinder,
        );
        final pixelsBeforeRestore = scrollableBefore.position.pixels;
        expect(
          scrollableBefore.position.maxScrollExtent -
              scrollableBefore.position.pixels,
          greaterThan(1),
        );

        await tester.pump(const Duration(milliseconds: 450));

        final dynamic chatPageState = tester.state(find.byType(ChatPage));
        chatPageState.onWindowMinimize();
        await tester.pump();
        chatPageState.onWindowRestore();
        await tester.pump();
        await tester.pumpAndSettle();

        final scrollableAfter = tester.state<ScrollableState>(scrollableFinder);
        expect(
          scrollableAfter.position.maxScrollExtent -
              scrollableAfter.position.pixels,
          greaterThan(1),
        );
        expect(
          scrollableAfter.position.pixels,
          closeTo(pixelsBeforeRestore, 1),
        );
      } finally {
        debugDefaultTargetPlatformOverride = previousPlatform;
      }
    },
  );

  testWidgets(
    'desktop window focus keeps an active cached session pinned to bottom',
    (WidgetTester tester) async {
      final previousPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await tester.binding.setSurfaceSize(const Size(1000, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final repository = FakeChatRepository(
          sessions: <ChatSession>[
            ChatSession(
              id: 'ses_desktop_focus_active',
              workspaceId: 'default',
              time: DateTime.fromMillisecondsSinceEpoch(1000),
              title: 'Desktop Focus Active',
            ),
          ],
        );
        repository.messagesBySession['ses_desktop_focus_active'] =
            <ChatMessage>[
              ..._threadMessages('ses_desktop_focus_active', 40),
              UserMessage(
                id: 'msg_desktop_focus_active_user',
                sessionId: 'ses_desktop_focus_active',
                time: DateTime.fromMillisecondsSinceEpoch(60000),
                parts: const <MessagePart>[
                  TextPart(
                    id: 'part_desktop_focus_active_user',
                    messageId: 'msg_desktop_focus_active_user',
                    sessionId: 'ses_desktop_focus_active',
                    text: 'still processing on desktop focus',
                  ),
                ],
              ),
            ];
        repository.sessionStatusById = const <String, SessionStatusInfo>{
          'ses_desktop_focus_active': SessionStatusInfo(
            type: SessionStatusType.busy,
          ),
        };

        final localDataSource = InMemoryAppLocalDataSource()
          ..activeServerId = 'srv_test';
        final provider = _buildChatProvider(
          chatRepository: repository,
          localDataSource: localDataSource,
        );
        final appProvider = _buildAppProvider(localDataSource: localDataSource);

        await tester.pumpWidget(_testApp(provider, appProvider));
        await tester.pumpAndSettle();

        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);
        await tester.pumpAndSettle();

        final listFinder = find.byKey(
          const ValueKey<String>('chat_message_list'),
        );
        final scrollableFinder = find.descendant(
          of: listFinder,
          matching: find.byType(Scrollable),
        );
        final scrollableBefore = tester.state<ScrollableState>(
          scrollableFinder,
        );
        expect(
          scrollableBefore.position.maxScrollExtent -
              scrollableBefore.position.pixels,
          lessThanOrEqualTo(1),
        );

        final dynamic chatPageState = tester.state(find.byType(ChatPage));
        chatPageState.onWindowMinimize();
        await tester.pump();
        chatPageState.onWindowFocus();
        await tester.pump();
        await tester.pumpAndSettle();

        final scrollableAfter = tester.state<ScrollableState>(scrollableFinder);
        expect(
          scrollableAfter.position.maxScrollExtent -
              scrollableAfter.position.pixels,
          lessThanOrEqualTo(1),
        );
        expect(find.byTooltip('Go to latest message'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = previousPlatform;
      }
    },
  );

  testWidgets(
    'shows delayed tip in composer for both thinking and receiving stages',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_progress',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Progress Session',
          ),
        ],
      );
      repository.messagesBySession['ses_progress'] = const <ChatMessage>[];

      final streamController = StreamController<Either<Failure, ChatMessage>>();
      addTearDown(() async {
        await streamController.close();
      });
      repository.sendMessageHandler =
          (projectId, sessionId, input, directory) => streamController.stream;

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.initializeProviders();
      await tester.pumpAndSettle();

      await provider.sendMessage('status progress');
      await tester.pump();

      // Status slot exists but line not yet visible (debounce delay).
      expect(
        find.byKey(const ValueKey<String>('composer_reasoning_status_slot')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('composer_reasoning_status_line')),
        findsNothing,
      );

      await tester.pump(const Duration(milliseconds: 1900));
      expect(
        find.byKey(const ValueKey<String>('composer_reasoning_status_line')),
        findsNothing,
      );

      // After 2s debounce, thinking stage shows a tip (not "Thinking...").
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byKey(const ValueKey<String>('composer_reasoning_status_line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('composer_reasoning_status_spinner')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('composer_reasoning_status_type_tip'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data?.startsWith('Tip:') ?? false),
        ),
        findsOneWidget,
      );
      expect(find.text('Thinking...'), findsNothing);

      // Transition to receiving stage — tip continues without interruption.
      streamController.add(
        Right(
          AssistantMessage(
            id: 'msg_assistant_progress',
            sessionId: 'ses_progress',
            time: DateTime.fromMillisecondsSinceEpoch(2000),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_assistant_progress',
                messageId: 'msg_assistant_progress',
                sessionId: 'ses_progress',
                text: 'partial token',
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      // Same tip icon and text persist across the stage transition.
      expect(
        find.byKey(
          const ValueKey<String>('composer_reasoning_status_icon_tip'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data?.startsWith('Tip:') ?? false),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows composer status text without shader when animations are disabled',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_progress_no_motion',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Progress No Motion Session',
          ),
        ],
      );
      repository.messagesBySession['ses_progress_no_motion'] =
          const <ChatMessage>[];

      final streamController = StreamController<Either<Failure, ChatMessage>>();
      addTearDown(() async {
        if (!streamController.isClosed) {
          await streamController.close();
        }
      });
      repository.sendMessageHandler =
          (projectId, sessionId, input, directory) => streamController.stream;

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      const mediaQueryData = MediaQueryData(
        size: Size(1000, 900),
        disableAnimations: true,
      );
      await tester.pumpWidget(
        _testApp(provider, appProvider, mediaQueryData: mediaQueryData),
      );
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.initializeProviders();
      await tester.pumpAndSettle();

      await provider.sendMessage('status progress no motion');
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('composer_reasoning_status_line')),
        findsOneWidget,
      );
      expect(find.byType(ShaderMask), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data?.startsWith('Tip:') ?? false),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows transient reasoning status above composer and hides it after completion',
    (WidgetTester tester) async {
      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_status',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Status Session',
          ),
        ],
      );
      repository.messagesBySession['ses_status'] = const <ChatMessage>[];

      final streamController = StreamController<Either<Failure, ChatMessage>>();
      addTearDown(() async {
        if (!streamController.isClosed) {
          await streamController.close();
        }
      });
      repository.sendMessageHandler = (_, _, _, _) => streamController.stream;

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.initializeProviders();
      await tester.pumpAndSettle();

      await provider.sendMessage('status label');
      await tester.pump();

      streamController.add(
        Right(
          AssistantMessage(
            id: 'msg_assistant_status',
            sessionId: 'ses_status',
            time: DateTime.fromMillisecondsSinceEpoch(2000),
            parts: const <MessagePart>[
              ReasoningPart(
                id: 'part_assistant_status',
                messageId: 'msg_assistant_status',
                sessionId: 'ses_status',
                text: '**Reading project tree**\nloading nodes...',
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('composer_reasoning_status_line')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'composer_reasoning_status_type_dynamicReasoning',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Reading project tree'), findsOneWidget);
      expect(find.text('Receiving response...'), findsNothing);
      expect(find.text('Thinking Process'), findsNothing);

      streamController.add(
        Right(
          AssistantMessage(
            id: 'msg_assistant_status',
            sessionId: 'ses_status',
            time: DateTime.fromMillisecondsSinceEpoch(2300),
            completedTime: DateTime.fromMillisecondsSinceEpoch(2300),
            parts: const <MessagePart>[
              TextPart(
                id: 'part_assistant_status_final',
                messageId: 'msg_assistant_status',
                sessionId: 'ses_status',
                text: 'done',
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      repository.emitEvent(
        const ChatEvent(
          type: 'session.status',
          properties: <String, dynamic>{
            'sessionID': 'ses_status',
            'status': <String, dynamic>{'type': 'idle'},
          },
        ),
      );
      await tester.pump();
      await streamController.close();
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('composer_reasoning_status_line')),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('composer_reasoning_status_line')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('composer_reasoning_status_slot')),
        findsOneWidget,
      );
      expect(find.text('Reading project tree'), findsNothing);
      expect(find.text('Receiving response...'), findsNothing);
    },
  );

  testWidgets(
    'keeps composer status and stop hidden for background-only sync status',
    (WidgetTester tester) async {
      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_bg_sync_status',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Background Sync Session',
          ),
        ],
      );
      repository.messagesBySession['ses_bg_sync_status'] =
          const <ChatMessage>[];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.initializeProviders();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('composer_reasoning_status_line')),
        findsNothing,
      );
      expect(find.byIcon(Symbols.stop_rounded), findsNothing);
      expect(find.byIcon(Symbols.send_rounded), findsOneWidget);

      repository.emitEvent(
        const ChatEvent(
          type: 'session.status',
          properties: <String, dynamic>{
            'sessionID': 'ses_bg_sync_status',
            'status': <String, dynamic>{'type': 'busy'},
          },
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(
        find.byKey(const ValueKey<String>('composer_reasoning_status_line')),
        findsNothing,
      );
      expect(find.byIcon(Symbols.stop_rounded), findsNothing);
      expect(find.byIcon(Symbols.send_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'surfaces latest tool activity in composer and hides mirrored live thinking bubble',
    (WidgetTester tester) async {
      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_busy_progress',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Busy Progress Session',
          ),
        ],
      );
      repository.messagesBySession['ses_busy_progress'] = const <ChatMessage>[];

      final streamController = StreamController<Either<Failure, ChatMessage>>();
      addTearDown(() async {
        if (!streamController.isClosed) {
          await streamController.close();
        }
      });
      repository.sendMessageHandler = (_, _, _, _) => streamController.stream;

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.initializeProviders();
      await tester.pumpAndSettle();

      await provider.sendMessage('show latest progress');
      await tester.pump();

      streamController.add(
        Right(
          AssistantMessage(
            id: 'msg_busy_progress',
            sessionId: 'ses_busy_progress',
            time: DateTime.fromMillisecondsSinceEpoch(2000),
            parts: <MessagePart>[
              const ReasoningPart(
                id: 'part_busy_reasoning',
                messageId: 'msg_busy_progress',
                sessionId: 'ses_busy_progress',
                text: 'Inspecting the latest workspace changes',
              ),
              ToolPart(
                id: 'part_busy_tool',
                messageId: 'msg_busy_progress',
                sessionId: 'ses_busy_progress',
                callId: 'call_busy_tool',
                tool: 'read',
                state: ToolStateRunning(
                  input: const <String, dynamic>{'path': 'lib/main.dart'},
                  time: DateTime.fromMillisecondsSinceEpoch(2000),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>(
            'composer_reasoning_status_type_activeProgress',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Reading file'), findsOneWidget);
      expect(find.text('Reading'), findsOneWidget);
      expect(
        find.text('Inspecting the latest workspace changes'),
        findsNothing,
      );
      expect(find.text('Thinking Process'), findsNothing);
    },
  );

  testWidgets(
    'shows stop for an incomplete draft even before busy status arrives',
    (WidgetTester tester) async {
      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_stale_draft',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Stale Draft Session',
          ),
        ],
      );
      repository.messagesBySession['ses_stale_draft'] = <ChatMessage>[
        AssistantMessage(
          id: 'msg_stale_draft',
          sessionId: 'ses_stale_draft',
          time: DateTime.fromMillisecondsSinceEpoch(1100),
          parts: const <MessagePart>[
            TextPart(
              id: 'part_stale_draft',
              messageId: 'msg_stale_draft',
              sessionId: 'ses_stale_draft',
              text: 'draft token',
            ),
          ],
        ),
      ];
      repository.sessionStatusById = const <String, SessionStatusInfo>{
        'ses_stale_draft': SessionStatusInfo(type: SessionStatusType.idle),
      };

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.loadSessionInsights('ses_stale_draft');
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('composer_reasoning_status_line')),
        findsNothing,
      );
      expect(find.byIcon(Symbols.stop_rounded), findsOneWidget);
      expect(find.byIcon(Symbols.send_rounded), findsNothing);
    },
  );

  testWidgets(
    'shows recoverable current-session error card instead of full-screen retry',
    (WidgetTester tester) async {
      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_recoverable_error',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Recoverable Error Session',
          ),
        ],
      );
      repository.messagesBySession['ses_recoverable_error'] = <ChatMessage>[];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.initializeProviders();
      await tester.pumpAndSettle();

      final activeServerId = appProvider.activeServerId;
      expect(activeServerId, isNotNull);
      await appProvider.getAppInfo();
      appProvider.setHealthForTesting(
        activeServerId!,
        ServerHealthStatus.healthy,
      );
      await tester.pumpAndSettle();

      repository.getMessagesFailure = const NetworkFailure(
        'idle reconnect failed',
      );
      await provider.loadMessages('ses_recoverable_error');
      await tester.pumpAndSettle();

      expect(find.text('Could not refresh this conversation'), findsOneWidget);
      expect(find.text('Keep working'), findsOneWidget);
      expect(find.text('Retry refresh'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('chat_message_list')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'uses subtle composer block for confirmed offline current-session refresh failures',
    (WidgetTester tester) async {
      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_offline_block',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Offline Block Session',
          ),
        ],
      );
      repository.messagesBySession['ses_offline_block'] = <ChatMessage>[];

      final appRepository = FakeAppRepository();
      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(
        localDataSource: localDataSource,
        appRepository: appRepository,
      );

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.initializeProviders();
      await tester.pumpAndSettle();

      appRepository.checkConnectionResult = const Right(false);
      await appProvider.checkConnection();
      await tester.pumpAndSettle();

      repository.getMessagesFailure = const NetworkFailure(
        'SocketException: Connection refused',
      );
      await provider.loadMessages('ses_offline_block');
      await tester.pumpAndSettle();

      expect(find.text('Could not refresh this conversation'), findsNothing);
      expect(find.text('Retry refresh'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('composer_block_reason_row')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('composer_block_reason_text')),
        findsOneWidget,
      );

      final inputField = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const ValueKey<String>('composer_input_row')),
          matching: find.byType(TextField),
        ),
      );
      expect(inputField.enabled, isFalse);
    },
  );

  testWidgets(
    'uses subtle composer block for unhealthy current-session refresh failures',
    (WidgetTester tester) async {
      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_unhealthy_block',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Unhealthy Block Session',
          ),
        ],
      );
      repository.messagesBySession['ses_unhealthy_block'] = <ChatMessage>[];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.initializeProviders();
      await tester.pumpAndSettle();

      final activeServerId = appProvider.activeServerId;
      expect(activeServerId, isNotNull);
      await appProvider.getAppInfo();
      appProvider.setHealthForTesting(
        activeServerId!,
        ServerHealthStatus.unhealthy,
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));

      repository.getMessagesFailure = const ServerFailure(
        'service unavailable',
        503,
      );
      await provider.loadMessages('ses_unhealthy_block');
      await tester.pumpAndSettle();

      expect(find.text('Could not refresh this conversation'), findsNothing);
      expect(find.text('Retry refresh'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('composer_block_reason_row')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('composer_block_reason_text')),
        findsOneWidget,
      );

      final inputField = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const ValueKey<String>('composer_input_row')),
          matching: find.byType(TextField),
        ),
      );
      expect(inputField.enabled, isFalse);
    },
  );

  testWidgets('shows inline abort message without retry snackbar', (
    WidgetTester tester,
  ) async {
    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_remote_abort',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Remote Abort Session',
        ),
      ],
    );
    repository.messagesBySession['ses_remote_abort'] = <ChatMessage>[
      UserMessage(
        id: 'msg_remote_abort_user',
        sessionId: 'ses_remote_abort',
        time: DateTime.fromMillisecondsSinceEpoch(1100),
        parts: const <MessagePart>[
          TextPart(
            id: 'part_remote_abort_user',
            messageId: 'msg_remote_abort_user',
            sessionId: 'ses_remote_abort',
            text: 'keep chat visible',
          ),
        ],
      ),
    ];

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await provider.initializeProviders();
    await tester.pumpAndSettle();

    repository.emitEvent(
      const ChatEvent(
        type: 'session.error',
        properties: <String, dynamic>{
          'sessionID': 'ses_remote_abort',
          'error': <String, dynamic>{
            'message': 'The operation was aborted by user',
          },
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('What you want to do different?'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(find.byIcon(Symbols.error_outline), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('chat_message_list')),
      findsOneWidget,
    );
  });

  testWidgets('shows inline session diff review surface on compact layouts', (
    WidgetTester tester,
  ) async {
    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_diff_inline',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Diff Session',
        ),
      ],
    );
    repository.sessionDiffById['ses_diff_inline'] = const <SessionDiff>[
      SessionDiff(
        file: 'lib/main.dart',
        before: 'old line',
        after: 'new line',
        additions: 1,
        deletions: 1,
        status: 'modified',
      ),
    ];

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await provider.loadSessionInsights('ses_diff_inline', silent: true);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('session_diff_viewer_compact_tile')),
      findsOneWidget,
    );
    expect(find.text('1 file changed'), findsOneWidget);
  });

  testWidgets('shows labeled session actions for the active session', (
    WidgetTester tester,
  ) async {
    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_session_actions',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Action Session',
        ),
      ],
    );
    repository.messagesBySession['ses_session_actions'] = <ChatMessage>[
      UserMessage(
        id: 'msg_user_1',
        sessionId: 'ses_session_actions',
        time: DateTime.fromMillisecondsSinceEpoch(1100),
        parts: const <MessagePart>[
          TextPart(
            id: 'part_user_1',
            messageId: 'msg_user_1',
            sessionId: 'ses_session_actions',
            text: 'hello',
          ),
        ],
      ),
    ];

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('current_session_actions_button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Share session'), findsOneWidget);
    expect(find.text('View tasks'), findsOneWidget);
    expect(find.text('Review changes'), findsOneWidget);
    expect(find.text('Undo last turn'), findsOneWidget);
    expect(find.text('Redo last undone turn'), findsOneWidget);
    expect(find.text('Compact context'), findsOneWidget);
  });

  testWidgets('session actions can open the current session details dialog', (
    WidgetTester tester,
  ) async {
    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_session_details',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Details Session',
        ),
      ],
    );
    repository.sessionTodoById['ses_session_details'] = const <SessionTodo>[
      SessionTodo(
        id: 'todo_1',
        content: 'Implement feature',
        status: 'in_progress',
        priority: 'high',
      ),
    ];
    repository.sessionDiffById['ses_session_details'] = const <SessionDiff>[
      SessionDiff(
        file: 'lib/main.dart',
        before: 'old line',
        after: 'new line',
        additions: 1,
        deletions: 1,
        status: 'modified',
      ),
    ];

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const ValueKey<String>('current_session_actions_button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('View tasks'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey<String>('current_session_insights_dialog')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('current_session_tasks_heading')),
      findsOneWidget,
    );
    expect(find.text('Implement feature'), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('current_session_review_heading')),
      findsOneWidget,
    );
    expect(find.text('lib/main.dart'), findsWidgets);
  });

  testWidgets('keeps input editable while responding and stop aborts session', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_stop',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Stop Session',
        ),
      ],
    );
    final streamController = StreamController<Either<Failure, ChatMessage>>();
    addTearDown(() async {
      await streamController.close();
    });
    repository.sendMessageHandler = (_, _, _, _) => streamController.stream;

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await provider.initializeProviders();
    await tester.pumpAndSettle();

    await provider.sendMessage('trigger stop');
    await tester.pump();

    final chatInputFieldFinder = find.descendant(
      of: find.byKey(const ValueKey<String>('composer_input_row')),
      matching: find.byType(TextField),
    );
    final inputField = tester.widget<TextField>(chatInputFieldFinder);
    expect(inputField.enabled, isTrue);
    expect(find.byIcon(Symbols.stop_rounded), findsOneWidget);

    await tester.enterText(chatInputFieldFinder, 'draft while receiving');
    await tester.pump();
    final updatedInputField = tester.widget<TextField>(chatInputFieldFinder);
    expect(updatedInputField.controller!.text, 'draft while receiving');

    await tester.enterText(chatInputFieldFinder, '');
    await tester.pump();

    await tester.tap(find.byIcon(Symbols.stop_rounded));
    await tester.pumpAndSettle();

    expect(repository.abortSessionCallCount, 1);
    expect(repository.lastAbortSessionId, 'ses_stop');
  });

  testWidgets('responding composer sends follow-up without auto-abort', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_interrupt_send',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Interrupt And Send Session',
        ),
      ],
    );
    final firstStream = StreamController<Either<Failure, ChatMessage>>();
    addTearDown(() async {
      await firstStream.close();
    });
    final assistantAfterInterrupt = AssistantMessage(
      id: 'msg_after_interrupt',
      sessionId: 'ses_interrupt_send',
      time: DateTime.fromMillisecondsSinceEpoch(2000),
      completedTime: DateTime.fromMillisecondsSinceEpoch(2100),
      parts: const <MessagePart>[
        TextPart(
          id: 'part_after_interrupt',
          messageId: 'msg_after_interrupt',
          sessionId: 'ses_interrupt_send',
          text: 'reply after interrupt',
        ),
      ],
    );
    var sendCalls = 0;
    repository.sendMessageHandler = (_, _, _, _) {
      sendCalls += 1;
      if (sendCalls == 1) {
        return firstStream.stream;
      }
      return Stream<Either<Failure, ChatMessage>>.value(
        Right(assistantAfterInterrupt),
      );
    };

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await provider.initializeProviders();
    await tester.pumpAndSettle();

    await provider.sendMessage('trigger active response');
    await tester.pump();

    final chatInputFieldFinder = find.descendant(
      of: find.byKey(const ValueKey<String>('composer_input_row')),
      matching: find.byType(TextField),
    );

    await tester.enterText(chatInputFieldFinder, 'follow-up while responding');
    await tester.pump();

    expect(find.byIcon(Symbols.send_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.stop_rounded), findsNothing);

    await tester.tap(find.byIcon(Symbols.send_rounded));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 80));

    expect(repository.abortSessionCallCount, 0);
    expect(repository.lastAbortSessionId, isNull);
    expect(sendCalls, 2);
  });

  testWidgets('restores composer draft automatically when send is rejected', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_retry_draft',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Retry Draft Session',
        ),
      ],
    );
    final sendStream = StreamController<Either<Failure, ChatMessage>>();
    addTearDown(() async {
      await sendStream.close();
    });
    repository.sendMessageHandler = (_, _, _, _) => sendStream.stream;

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await provider.initializeProviders();
    await tester.pumpAndSettle();

    final chatInputFieldFinder = find.descendant(
      of: find.byKey(const ValueKey<String>('composer_input_row')),
      matching: find.byType(TextField),
    );

    await tester.enterText(chatInputFieldFinder, 'keep this draft');
    await tester.pump();
    await tester.tap(find.byIcon(Symbols.send_rounded));
    await tester.pump();

    sendStream.add(const Left(ServerFailure('temporary send rejection')));
    await tester.pumpAndSettle();

    final inputAfterFailure = tester.widget<TextField>(chatInputFieldFinder);
    expect(inputAfterFailure.controller?.text, 'keep this draft');
  });

  testWidgets(
    'restores composer draft even if provider leaves error state before rebuild',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: 'ses_retry_draft_fast_clear',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Retry Draft Fast Clear Session',
          ),
        ],
      );
      final sendStream = StreamController<Either<Failure, ChatMessage>>();
      addTearDown(() async {
        await sendStream.close();
      });
      repository.sendMessageHandler = (_, _, _, _) => sendStream.stream;

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.initializeProviders();
      await tester.pumpAndSettle();

      final chatInputFieldFinder = find.descendant(
        of: find.byKey(const ValueKey<String>('composer_input_row')),
        matching: find.byType(TextField),
      );

      await tester.enterText(chatInputFieldFinder, 'recover this quickly');
      await tester.pump();
      await tester.tap(find.byIcon(Symbols.send_rounded));
      await tester.pump();

      sendStream.add(const Left(ServerFailure('temporary send rejection')));
      await tester.pump(const Duration(milliseconds: 20));

      provider.clearError();
      await tester.pumpAndSettle();

      final inputAfterFailure = tester.widget<TextField>(chatInputFieldFinder);
      expect(inputAfterFailure.controller?.text, 'recover this quickly');
    },
  );

  testWidgets('double ESC shows stop hint and aborts active response', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_stop_double_esc',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Stop Double ESC Session',
        ),
      ],
    );
    final streamController = StreamController<Either<Failure, ChatMessage>>();
    addTearDown(() async {
      await streamController.close();
    });
    repository.sendMessageHandler = (_, _, _, _) => streamController.stream;

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await provider.initializeProviders();
    await tester.pumpAndSettle();

    await provider.sendMessage('trigger stop with esc');
    await tester.pump();

    final chatInputFieldFinder = find.descendant(
      of: find.byKey(const ValueKey<String>('composer_input_row')),
      matching: find.byType(TextField),
    );
    await tester.tap(chatInputFieldFinder);
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(repository.abortSessionCallCount, 0);
    expect(find.text('Double ESC to stop'), findsOneWidget);

    final hintFinder = find.text('Double ESC to stop');
    final hintText = tester.widget<Text>(hintFinder);
    final hintContext = tester.element(hintFinder);
    expect(hintText.style?.fontWeight, FontWeight.w400);
    expect(hintText.style?.color, Theme.of(hintContext).colorScheme.error);

    final inputAfterFirstEsc = tester.widget<TextField>(chatInputFieldFinder);
    expect(inputAfterFirstEsc.focusNode?.hasFocus, isTrue);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(repository.abortSessionCallCount, 1);
    expect(repository.lastAbortSessionId, 'ses_stop_double_esc');

    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump();

    expect(find.text('Double ESC to stop'), findsNothing);
  });

  testWidgets('double ESC aborts active response with unfocused composer', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_stop_double_esc_unfocused',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Stop Double ESC Unfocused Session',
        ),
      ],
    );
    final streamController = StreamController<Either<Failure, ChatMessage>>();
    addTearDown(() async {
      await streamController.close();
    });
    repository.sendMessageHandler = (_, _, _, _) => streamController.stream;

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await provider.initializeProviders();
    await tester.pumpAndSettle();

    await provider.sendMessage('trigger stop with global esc');
    await tester.pump();

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(repository.abortSessionCallCount, 0);
    expect(find.text('Double ESC to stop'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(repository.abortSessionCallCount, 1);
    expect(repository.lastAbortSessionId, 'ses_stop_double_esc_unfocused');
  });

  testWidgets('shows snackbar when stop request fails', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_stop_fail',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Stop Fail Session',
        ),
      ],
    )..abortSessionFailure = const ServerFailure('abort failed');
    final streamController = StreamController<Either<Failure, ChatMessage>>();
    addTearDown(() async {
      await streamController.close();
    });
    repository.sendMessageHandler = (_, _, _, _) => streamController.stream;

    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await provider.initializeProviders();
    await tester.pumpAndSettle();

    await provider.sendMessage('trigger failing stop');
    await tester.pump();

    await tester.tap(find.byIcon(Symbols.stop_rounded));
    await tester.pumpAndSettle();

    expect(provider.errorMessage, 'Server error. Please try again later');
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    final chatInputFieldFinder = find.descendant(
      of: find.byKey(const ValueKey<String>('composer_input_row')),
      matching: find.byType(TextField),
    );
    final inputField = tester.widget<TextField>(chatInputFieldFinder);
    expect(inputField.enabled, isTrue);
  });

  testWidgets('shows consistent fallback title in active session header', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final untitledTime = DateTime(2026, 2, 11, 10, 30);
    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_untitled',
          workspaceId: 'default',
          time: untitledTime,
          title: null,
        ),
      ],
    );
    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pumpAndSettle();

    final expected = SessionTitleFormatter.fallbackTitle(time: untitledTime);
    expect(find.text(expected), findsWidgets);
  });

  testWidgets('active session header keeps only essential info', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_compact_header',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Compact Header Session',
        ),
      ],
    );
    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('chat_compact_session_header')),
      findsOneWidget,
    );
    expect(find.textContaining('Children:'), findsNothing);
    expect(find.textContaining('Todos:'), findsNothing);
    expect(find.textContaining('Diff:'), findsNothing);
  });

  testWidgets('renames current session through inline header editor', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeChatRepository(
      sessions: <ChatSession>[
        ChatSession(
          id: 'ses_inline',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(1000),
          title: 'Session 1',
        ),
      ],
    );
    final localDataSource = InMemoryAppLocalDataSource()
      ..activeServerId = 'srv_test';
    final provider = _buildChatProvider(
      chatRepository: repository,
      localDataSource: localDataSource,
    );
    final appProvider = _buildAppProvider(localDataSource: localDataSource);

    await tester.pumpWidget(_testApp(provider, appProvider));
    await tester.pumpAndSettle();

    await provider.loadSessions();
    await provider.selectSession(provider.sessions.first);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('session_title_display')).first,
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('session_title_editor_field')).first,
      'Renamed Inline',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('session_title_save_button')).first,
    );
    await tester.pumpAndSettle();

    expect(provider.currentSession?.title, 'Renamed Inline');
    expect(
      provider.sessions.where((item) => item.id == 'ses_inline').first.title,
      'Renamed Inline',
    );
  });

  testWidgets(
    'mobile keyboard temporarily collapses task panel and restores expansion',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const sessionId = 'ses_todo_keyboard_restore';
      const baseMediaQueryData = MediaQueryData(size: Size(390, 844));
      final keyboardMediaQueryData = baseMediaQueryData.copyWith(
        viewInsets: const EdgeInsets.only(bottom: 280),
      );

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: sessionId,
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Todo keyboard restore session',
          ),
        ],
      );
      repository.messagesBySession[sessionId] = <ChatMessage>[];
      repository.sessionTodoById[sessionId] = const <SessionTodo>[
        SessionTodo(
          id: 'todo_restore_1',
          content: 'Todo',
          status: 'in_progress',
          priority: 'medium',
        ),
      ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);
      final settingsProvider = SettingsProvider(
        localDataSource: localDataSource,
        dioClient: DioClient(),
        soundService: SoundService(),
      );
      await settingsProvider.initialize();
      await settingsProvider.setCheckUpdatesOnOpen(false);
      addTearDown(settingsProvider.dispose);

      await tester.pumpWidget(
        _testApp(
          provider,
          appProvider,
          settingsProvider: settingsProvider,
          mediaQueryData: baseMediaQueryData,
        ),
      );
      await _pumpUiFrames(tester);

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await _pumpUiFrames(tester);

      expect(find.text('Tasks (1)'), findsOneWidget);
      expect(find.text('1/1 in progress'), findsNothing);
      expect(settingsProvider.taskListCollapsed, isFalse);

      await tester.pumpWidget(
        _testApp(
          provider,
          appProvider,
          settingsProvider: settingsProvider,
          mediaQueryData: keyboardMediaQueryData,
        ),
      );
      await _pumpUiFrames(tester);

      expect(find.text('1/1 in progress'), findsOneWidget);
      expect(find.text('Tasks (1)'), findsNothing);
      expect(settingsProvider.taskListCollapsed, isFalse);

      await tester.pumpWidget(
        _testApp(
          provider,
          appProvider,
          settingsProvider: settingsProvider,
          mediaQueryData: baseMediaQueryData,
        ),
      );
      await _pumpUiFrames(tester);

      expect(find.text('Tasks (1)'), findsOneWidget);
      expect(find.text('1/1 in progress'), findsNothing);
      expect(settingsProvider.taskListCollapsed, isFalse);
    },
  );

  testWidgets(
    'mobile task panel remains collapsed after keyboard closes when preference is collapsed',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const sessionId = 'ses_todo_keyboard_keep_collapsed';
      const baseMediaQueryData = MediaQueryData(size: Size(390, 844));
      final keyboardMediaQueryData = baseMediaQueryData.copyWith(
        viewInsets: const EdgeInsets.only(bottom: 280),
      );

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: sessionId,
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Todo keyboard keep collapsed session',
          ),
        ],
      );
      repository.messagesBySession[sessionId] = <ChatMessage>[];
      repository.sessionTodoById[sessionId] = const <SessionTodo>[
        SessionTodo(
          id: 'todo_collapsed_1',
          content: 'Todo',
          status: 'in_progress',
          priority: 'medium',
        ),
      ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);
      final settingsProvider = SettingsProvider(
        localDataSource: localDataSource,
        dioClient: DioClient(),
        soundService: SoundService(),
      );
      await settingsProvider.initialize();
      await settingsProvider.setCheckUpdatesOnOpen(false);
      addTearDown(settingsProvider.dispose);

      await tester.pumpWidget(
        _testApp(
          provider,
          appProvider,
          settingsProvider: settingsProvider,
          mediaQueryData: baseMediaQueryData,
        ),
      );
      await _pumpUiFrames(tester);

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await _pumpUiFrames(tester);

      expect(find.text('Tasks (1)'), findsOneWidget);
      await tester.tap(find.text('Tasks (1)'));
      await _pumpUiFrames(tester);

      expect(settingsProvider.taskListCollapsed, isTrue);
      expect(find.text('1/1 in progress'), findsOneWidget);

      await tester.pumpWidget(
        _testApp(
          provider,
          appProvider,
          settingsProvider: settingsProvider,
          mediaQueryData: keyboardMediaQueryData,
        ),
      );
      await _pumpUiFrames(tester);

      expect(find.text('1/1 in progress'), findsOneWidget);

      await tester.pumpWidget(
        _testApp(
          provider,
          appProvider,
          settingsProvider: settingsProvider,
          mediaQueryData: baseMediaQueryData,
        ),
      );
      await _pumpUiFrames(tester);

      expect(settingsProvider.taskListCollapsed, isTrue);
      expect(find.text('1/1 in progress'), findsOneWidget);
      expect(find.text('Tasks (1)'), findsNothing);
    },
  );

  testWidgets(
    'tapping task panel while keyboard is open does not persist collapse toggle',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const sessionId = 'ses_todo_keyboard_toggle_guard';
      const baseMediaQueryData = MediaQueryData(size: Size(390, 844));
      final keyboardMediaQueryData = baseMediaQueryData.copyWith(
        viewInsets: const EdgeInsets.only(bottom: 280),
      );

      final repository = FakeChatRepository(
        sessions: <ChatSession>[
          ChatSession(
            id: sessionId,
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            title: 'Todo keyboard toggle guard session',
          ),
        ],
      );
      repository.messagesBySession[sessionId] = <ChatMessage>[];
      repository.sessionTodoById[sessionId] = const <SessionTodo>[
        SessionTodo(
          id: 'todo_toggle_guard_1',
          content: 'Todo',
          status: 'in_progress',
          priority: 'medium',
        ),
      ];

      final localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);
      final settingsProvider = SettingsProvider(
        localDataSource: localDataSource,
        dioClient: DioClient(),
        soundService: SoundService(),
      );
      await settingsProvider.initialize();
      await settingsProvider.setCheckUpdatesOnOpen(false);
      addTearDown(settingsProvider.dispose);

      await tester.pumpWidget(
        _testApp(
          provider,
          appProvider,
          settingsProvider: settingsProvider,
          mediaQueryData: baseMediaQueryData,
        ),
      );
      await _pumpUiFrames(tester);

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await _pumpUiFrames(tester);

      expect(settingsProvider.taskListCollapsed, isFalse);

      await tester.pumpWidget(
        _testApp(
          provider,
          appProvider,
          settingsProvider: settingsProvider,
          mediaQueryData: keyboardMediaQueryData,
        ),
      );
      await _pumpUiFrames(tester);

      expect(find.text('1/1 in progress'), findsOneWidget);
      await tester.tap(find.text('1/1 in progress'));
      await _pumpUiFrames(tester);

      expect(settingsProvider.taskListCollapsed, isFalse);

      await tester.pumpWidget(
        _testApp(
          provider,
          appProvider,
          settingsProvider: settingsProvider,
          mediaQueryData: baseMediaQueryData,
        ),
      );
      await _pumpUiFrames(tester);

      expect(settingsProvider.taskListCollapsed, isFalse);
      expect(find.text('Tasks (1)'), findsOneWidget);
      expect(find.text('1/1 in progress'), findsNothing);
    },
  );

  testWidgets(
    'shows setup CTA when no server is configured and opens wizard directly',
    (WidgetTester tester) async {
      final localDataSource = InMemoryAppLocalDataSource();
      final chatRepository = FakeChatRepository();
      final appRepository = FakeAppRepository()
        ..checkConnectionResult = const Left(
          NetworkFailure('server should not be checked'),
        );
      final provider = _buildChatProvider(
        chatRepository: chatRepository,
        appRepository: appRepository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(
        localDataSource: localDataSource,
        appRepository: appRepository,
      );

      await tester.pumpWidget(_testApp(provider, appProvider));
      await _pumpUiFrames(tester);

      expect(find.text('No server configured yet'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('no_server_setup_button')),
        findsOneWidget,
      );
      expect(find.text('server should not be checked'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey<String>('no_server_setup_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('step_server_setup')),
        findsOneWidget,
      );
      expect(find.text('Server connection'), findsOneWidget);
    },
  );

  test('uses compact sidebar tour copy on small layouts', () {
    final copy = postOnboardingSidebarTourCopy(
      isMobile: true,
      showConversationPane: false,
    );

    expect(copy.title, 'Open sidebar');
    expect(
      copy.description,
      'Use this button to open your projects and conversations.',
    );
  });

  test('uses project-context tour copy on desktop layouts with sidebar', () {
    final copy = postOnboardingSidebarTourCopy(
      isMobile: false,
      showConversationPane: true,
    );

    expect(copy.title, 'Open project');
    expect(
      copy.description,
      'Use this button to switch project folders and context.',
    );
  });
}

Future<void> _pumpUiFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

Widget _testApp(
  ChatProvider provider,
  AppProvider appProvider, {
  SettingsProvider? settingsProvider,
  QuotaProvider? quotaProvider,
  QuotaRemoteDataSource? quotaRemoteDataSource,
  CellularDataSaverService? cellularDataSaverService,
  MediaQueryData? mediaQueryData,
}) {
  if (di.sl.isRegistered<AppLocalDataSource>()) {
    di.sl.unregister<AppLocalDataSource>();
  }
  di.sl.registerSingleton<AppLocalDataSource>(provider.localDataSource);

  final effectiveSettingsProvider =
      settingsProvider ??
      SettingsProvider(
        localDataSource: provider.localDataSource,
        dioClient: DioClient(),
        soundService: SoundService(),
        cellularDataSaverService: cellularDataSaverService,
      );
  if (settingsProvider == null) {
    addTearDown(effectiveSettingsProvider.dispose);
    _disableAutomaticUpdateChecksForTest(
      provider.localDataSource as InMemoryAppLocalDataSource,
    );
    unawaited(effectiveSettingsProvider.initialize());
  }

  final effectiveQuotaProvider =
      quotaProvider ??
      QuotaProvider(
        remoteDataSource: quotaRemoteDataSource ?? FakeQuotaRemoteDataSource(),
      );

  Widget home = const ChatPage();
  if (mediaQueryData != null) {
    home = MediaQuery(data: mediaQueryData, child: home);
  }

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ChatProvider>.value(value: provider),
      ChangeNotifierProvider<AppProvider>.value(value: appProvider),
      ChangeNotifierProvider<ProjectProvider>.value(
        value: provider.projectProvider,
      ),
      ChangeNotifierProvider<SettingsProvider>.value(
        value: effectiveSettingsProvider,
      ),
      ChangeNotifierProvider<QuotaProvider>.value(
        value: effectiveQuotaProvider,
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightFrom(
        ColorScheme.fromSeed(seedColor: AppTheme.seedColor),
      ),
      home: home,
    ),
  );
}

void _disableAutomaticUpdateChecksForTest(
  InMemoryAppLocalDataSource localDataSource,
) {
  final raw = localDataSource.experienceSettingsJson;
  final settingsJson = raw == null || raw.trim().isEmpty
      ? <String, dynamic>{}
      : (jsonDecode(raw) as Map).cast<String, dynamic>();
  settingsJson['checkUpdatesOnOpen'] = false;
  localDataSource.experienceSettingsJson = jsonEncode(settingsJson);
}

ChatProvider _buildChatProvider({
  FakeChatRepository? chatRepository,
  FakeProjectRepository? projectRepository,
  FakeAppRepository? appRepository,
  required InMemoryAppLocalDataSource localDataSource,
  CellularDataSaverService? cellularDataSaverService,
  bool includeVariants = false,
  ProvidersResponse? providersResponse,
}) {
  final chatRepo = chatRepository ?? FakeChatRepository();
  final appRepo = appRepository ?? FakeAppRepository();
  appRepo.providersResult = Right(
    providersResponse ??
        ProvidersResponse(
          providers: <Provider>[
            Provider(
              id: 'provider_1',
              name: 'Provider 1',
              env: const <String>[],
              models: <String, Model>{
                'model_1': _model(
                  'model_1',
                  variants: includeVariants
                      ? const <String, ModelVariant>{
                          'low': ModelVariant(id: 'low', name: 'Low'),
                          'high': ModelVariant(id: 'high', name: 'High'),
                        }
                      : const <String, ModelVariant>{},
                ),
              },
            ),
          ],
          defaultModels: const <String, String>{'provider_1': 'model_1'},
          connected: const <String>['provider_1'],
        ),
  );

  return ChatProvider(
    sendChatMessage: SendChatMessage(chatRepo),
    getChatSessions: GetChatSessions(chatRepo),
    createChatSession: CreateChatSession(chatRepo),
    getChatMessages: GetChatMessages(chatRepo),
    getChatMessage: GetChatMessage(chatRepo),
    getAgents: GetAgents(appRepo),
    getProviders: GetProviders(appRepo),
    deleteChatSession: DeleteChatSession(chatRepo),
    updateChatSession: UpdateChatSession(chatRepo),
    shareChatSession: ShareChatSession(chatRepo),
    unshareChatSession: UnshareChatSession(chatRepo),
    forkChatSession: ForkChatSession(chatRepo),
    getSessionStatus: GetSessionStatus(chatRepo),
    getSessionChildren: GetSessionChildren(chatRepo),
    getSessionTodo: GetSessionTodo(chatRepo),
    getSessionDiff: GetSessionDiff(chatRepo),
    watchChatEvents: WatchChatEvents(chatRepo),
    watchGlobalChatEvents: WatchGlobalChatEvents(chatRepo),
    abortChatSession: AbortChatSession(chatRepo),
    listPendingPermissions: ListPendingPermissions(chatRepo),
    replyPermission: ReplyPermission(chatRepo),
    listPendingQuestions: ListPendingQuestions(chatRepo),
    replyQuestion: ReplyQuestion(chatRepo),
    rejectQuestion: RejectQuestion(chatRepo),
    revertChatMessage: RevertChatMessage(chatRepo),
    unrevertChatMessages: UnrevertChatMessages(chatRepo),
    projectProvider: ProjectProvider(
      projectRepository: projectRepository ?? FakeProjectRepository(),
      localDataSource: localDataSource,
    ),
    localDataSource: localDataSource,
    cellularDataSaverService: cellularDataSaverService,
    syncHealthCheckInterval: const Duration(milliseconds: 150),
    foregroundResumeSyncIndicatorDuration: const Duration(milliseconds: 250),
    foregroundResumeSyncIndicatorMaxCycles: 2,
    abortSuppressionWindow: const Duration(milliseconds: 500),
  );
}

AppProvider _buildAppProvider({
  required InMemoryAppLocalDataSource localDataSource,
  FakeAppRepository? appRepository,
  CellularDataSaverService? cellularDataSaverService,
}) {
  _ensureActiveServerProfile(localDataSource);
  final repository = appRepository ?? FakeAppRepository();
  final provider = AppProvider(
    getAppInfo: GetAppInfo(repository),
    checkConnection: CheckConnection(repository),
    localDataSource: localDataSource,
    dioClient: DioClient(),
    cellularDataSaverService: cellularDataSaverService,
    enableHealthPolling: false,
  );
  unawaited(provider.initialize());
  return provider;
}

void _ensureActiveServerProfile(InMemoryAppLocalDataSource localDataSource) {
  final activeServerId = localDataSource.activeServerId?.trim();
  if (activeServerId == null || activeServerId.isEmpty) {
    return;
  }
  final existingProfilesJson = localDataSource.serverProfilesJson;
  if (existingProfilesJson != null && existingProfilesJson.trim().isNotEmpty) {
    return;
  }

  localDataSource.defaultServerId ??= activeServerId;
  localDataSource.serverProfilesJson = jsonEncode(<Map<String, dynamic>>[
    <String, dynamic>{
      'id': activeServerId,
      'url': 'http://127.0.0.1:4096',
      'label': 'Test Server',
      'basicAuthEnabled': false,
      'basicAuthUsername': '',
      'basicAuthPassword': '',
      'createdAt': 0,
      'updatedAt': 0,
    },
  ]);
}

Model _model(
  String id, {
  String? name,
  bool attachment = false,
  Map<String, dynamic>? modalities,
  Map<String, ModelVariant> variants = const <String, ModelVariant>{},
}) {
  return Model(
    id: id,
    name: name ?? id,
    releaseDate: '2025-01-01',
    attachment: attachment,
    reasoning: false,
    temperature: true,
    toolCall: false,
    cost: const ModelCost(input: 0.001, output: 0.002),
    limit: const ModelLimit(context: 1000, output: 100),
    options: const <String, dynamic>{},
    modalities: modalities,
    variants: variants,
  );
}

List<ChatMessage> _threadMessages(String sessionId, int count) {
  return List<ChatMessage>.generate(count, (index) {
    final messageId = 'msg_${sessionId}_$index';
    return UserMessage(
      id: messageId,
      sessionId: sessionId,
      time: DateTime.fromMillisecondsSinceEpoch(index * 1000),
      parts: <MessagePart>[
        TextPart(
          id: 'part_${sessionId}_$index',
          messageId: messageId,
          sessionId: sessionId,
          text: 'message $index',
        ),
      ],
    );
  });
}
