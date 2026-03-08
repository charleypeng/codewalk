import 'dart:async';
import 'dart:convert';

import 'package:codewalk/core/config/feature_flags.dart';
import 'package:codewalk/core/di/injection_container.dart' as di;
import 'package:codewalk/core/errors/failures.dart';
import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/data/datasources/app_local_datasource.dart';
import 'package:codewalk/domain/entities/agent.dart';
import 'package:codewalk/domain/entities/chat_message.dart';
import 'package:codewalk/domain/entities/chat_realtime.dart';
import 'package:codewalk/domain/entities/chat_session.dart';
import 'package:codewalk/domain/entities/file_node.dart';
import 'package:codewalk/domain/entities/project.dart';
import 'package:codewalk/domain/entities/provider.dart';
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
import 'package:codewalk/domain/usecases/send_chat_message.dart';
import 'package:codewalk/domain/usecases/share_chat_session.dart';
import 'package:codewalk/domain/usecases/unshare_chat_session.dart';
import 'package:codewalk/domain/usecases/update_chat_session.dart';
import 'package:codewalk/domain/usecases/watch_chat_events.dart';
import 'package:codewalk/domain/usecases/watch_global_chat_events.dart';
import 'package:codewalk/presentation/pages/chat_page.dart';
import 'package:codewalk/presentation/pages/settings_page.dart';
import 'package:codewalk/presentation/providers/app_provider.dart';
import 'package:codewalk/presentation/providers/chat_provider.dart';
import 'package:codewalk/presentation/providers/project_provider.dart';
import 'package:codewalk/presentation/providers/settings_provider.dart';
import 'package:codewalk/presentation/services/sound_service.dart';
import 'package:codewalk/presentation/utils/session_title_formatter.dart';
import 'package:codewalk/presentation/widgets/chat_skeleton_shimmer.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart' hide Provider;
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

@Tags(<String>['slow'])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatPage responsive shell', () {
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
      await tester.pumpAndSettle();

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

    testWidgets('shows utility pane on large desktop width', (
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
        ..activeServerId = 'srv_test';
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
        ..activeServerId = 'srv_test';
      final provider = _buildChatProvider(
        chatRepository: repository,
        localDataSource: localDataSource,
      );
      final appProvider = _buildAppProvider(localDataSource: localDataSource);

      await tester.pumpWidget(_testApp(provider, appProvider));
      await tester.pumpAndSettle();

      expect(find.textContaining('alpha'), findsOneWidget);
      expect(find.textContaining('beta'), findsOneWidget);
      expect(find.textContaining('final answer = 42;'), findsOneWidget);
      expect(find.textContaining('print(answer);'), findsOneWidget);

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
        expect(find.textContaining('final answer = 42;'), findsOneWidget);
        expect(find.textContaining('print(answer);'), findsOneWidget);
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
        ..activeServerId = 'srv_test';
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

    expect(find.byTooltip('Add attachment'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('composer_input_row')),
        matching: find.byTooltip('Add attachment'),
      ),
      findsNothing,
    );
    await tester.tap(find.byTooltip('Add attachment'));
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

      expect(find.byTooltip('Add attachment'), findsOneWidget);
      await tester.tap(find.byTooltip('Add attachment'));
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
    await tester.tap(
      find.byTooltip('Archive closed project Workspace Feature'),
    );
    await tester.pumpAndSettle();

    expect(provider.projectProvider.archivedProjectIds, contains('proj_ws'));
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

    expect(find.text('/repo/a/client/app'), findsOneWidget);

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
      await tester.pumpAndSettle();

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
    'shows subagent permission requests once in interaction prompt area',
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
        provider.sessions.where((session) => session.id == 'ses_root').first,
      );
      await tester.pumpAndSettle();

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
      expect(find.text('Subagent'), findsNothing);
      expect(repository.lastPermissionRequestId, isNull);
    },
  );

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
    await tester.tap(
      find.byKey(const ValueKey<String>('variant_selector_option_low')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Low'), findsOneWidget);
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
      expect(find.byIcon(Symbols.attach_file_rounded), findsOneWidget);
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
      final anthropicTile = tester.widget<ListTile>(anthropicTileFinder);
      final anthropicLeadingIcon = anthropicTile.leading as Icon?;
      expect(anthropicLeadingIcon?.icon, SimpleIcons.claude);

      final googleClaudeTileFinder = modelSelectorTileFinder(
        providerId: 'google',
        modelId: 'claude-opus-via-google',
      );
      expect(googleClaudeTileFinder, findsOneWidget);
      final googleClaudeTile = tester.widget<ListTile>(googleClaudeTileFinder);
      final googleClaudeLeadingIcon = googleClaudeTile.leading as Icon?;
      expect(googleClaudeLeadingIcon?.icon, SimpleIcons.claude);

      final googleTileFinder = modelSelectorTileFinder(
        providerId: 'google',
        modelId: 'gemini-2.5-pro',
      );
      expect(googleTileFinder, findsOneWidget);
      final googleTile = tester.widget<ListTile>(googleTileFinder);
      final googleLeadingIcon = googleTile.leading as Icon?;
      expect(googleLeadingIcon?.icon, SimpleIcons.googlegemini);

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
    final scrollableFinder = find.descendant(
      of: listFinder,
      matching: find.byType(Scrollable),
    );

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
      expect(find.text('2 work messages'), findsOneWidget);
      expect(
        find.textContaining(
          'assistant work messages hidden before final response',
        ),
        findsNothing,
      );
      expect(find.text('Working step 1'), findsNothing);
      expect(find.text('Working step 2'), findsNothing);
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

      repository.getMessagesGate = Completer<void>();
      final refreshFuture = provider.loadSessions();
      await tester.pump();

      expect(find.text('Hello! I am your AI assistant'), findsOneWidget);
      expect(find.byType(ChatSkeletonShimmer), findsNothing);

      repository.getMessagesGate?.complete();
      await refreshFuture;
      await tester.pumpAndSettle();

      expect(find.text('Hello! I am your AI assistant'), findsOneWidget);
      expect(find.byType(ChatSkeletonShimmer), findsNothing);
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
          AgentPart(
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
          SubtaskPart(
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

    await tester.tap(
      find.byKey(
        const ValueKey<String>('timeline_collapsed_assistant_work_toggle'),
      ),
    );
    await tester.pumpAndSettle();

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
    'does not collapse assistant work group before final assistant response',
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
        findsNothing,
      );
      expect(find.text('Details'), findsOneWidget);
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
    'does not yank latest message into reveal position when app resumes without new content',
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
      expect(
        scrollableBefore.position.maxScrollExtent -
            scrollableBefore.position.pixels,
        lessThanOrEqualTo(1),
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
        lessThanOrEqualTo(1),
      );
      expect(find.byTooltip('Go to latest message'), findsNothing);
    },
  );

  testWidgets('keeps latest follow when app resumes after new final content', (
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
      lessThanOrEqualTo(1),
    );
    expect(find.byTooltip('Go to latest message'), findsNothing);
  });

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
    'keeps composer status and stop hidden for stale in-progress draft without busy status',
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
      expect(find.byIcon(Symbols.stop_rounded), findsNothing);
      expect(find.byIcon(Symbols.send_rounded), findsOneWidget);
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
}

Future<void> _pumpUiFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

Widget _testApp(
  ChatProvider provider,
  AppProvider appProvider, {
  SettingsProvider? settingsProvider,
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
      );
  if (settingsProvider == null) {
    addTearDown(effectiveSettingsProvider.dispose);
    _disableAutomaticUpdateChecksForTest(
      provider.localDataSource as InMemoryAppLocalDataSource,
    );
    unawaited(effectiveSettingsProvider.initialize());
  }

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
    ],
    child: MaterialApp(home: home),
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
    projectProvider: ProjectProvider(
      projectRepository: projectRepository ?? FakeProjectRepository(),
      localDataSource: localDataSource,
    ),
    localDataSource: localDataSource,
    syncHealthCheckInterval: const Duration(milliseconds: 150),
    foregroundResumeSyncIndicatorDuration: const Duration(milliseconds: 250),
    foregroundResumeSyncIndicatorMaxCycles: 2,
    abortSuppressionWindow: const Duration(milliseconds: 500),
  );
}

AppProvider _buildAppProvider({
  required InMemoryAppLocalDataSource localDataSource,
  FakeAppRepository? appRepository,
}) {
  _ensureActiveServerProfile(localDataSource);
  final repository = appRepository ?? FakeAppRepository();
  final provider = AppProvider(
    getAppInfo: GetAppInfo(repository),
    checkConnection: CheckConnection(repository),
    localDataSource: localDataSource,
    dioClient: DioClient(),
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
