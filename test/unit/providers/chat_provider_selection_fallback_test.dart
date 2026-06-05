@Tags(<String>['slow'])
library;

import 'package:codewalk/core/errors/failures.dart';
import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/domain/entities/agent.dart';
import 'package:codewalk/domain/entities/chat_message.dart';
import 'package:codewalk/domain/entities/chat_session.dart';
import 'package:codewalk/domain/entities/provider.dart';
import 'package:codewalk/presentation/providers/chat_provider.dart';
import 'package:codewalk/presentation/providers/settings_provider.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import 'chat_provider_test_support.dart';

void main() {
  group('ChatProvider - message-derived selection fallback (Feature 7)', () {
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

    /// Fully initialize the provider with providers, agents, and sessions.
    /// [getMessagesHandler] is wired BEFORE loadSessions() so that
    /// loadLastSession() → loadMessages() returns the test messages.
    Future<RecordingDioClient> setupFullyInitialized({
      Future<Either<Failure, List<ChatMessage>>> Function(
        String projectId,
        String sessionId, {
        String? directory,
        int? limit,
      })? getMessagesHandler,
    }) async {
      appRepository.providersResult = Right(
        ProvidersResponse(
          providers: <Provider>[
            Provider(
              id: 'anthropic',
              name: 'Anthropic',
              env: const <String>[],
              models: <String, Model>{
                'claude-sonnet': testModel('claude-sonnet'),
                'claude-opus': testModel(
                  'claude-opus',
                  variants: const <String, ModelVariant>{
                    'think': ModelVariant(id: 'think', name: 'Think'),
                  },
                ),
              },
            ),
            Provider(
              id: 'openai',
              name: 'OpenAI',
              env: const <String>[],
              models: <String, Model>{
                'gpt-4o': testModel('gpt-4o'),
              },
            ),
          ],
          defaultModels: const <String, String>{
            'anthropic': 'claude-sonnet',
            'openai': 'gpt-4o',
          },
          connected: const <String>['anthropic', 'openai'],
        ),
      );
      appRepository.agentsResult = const Right(<Agent>[
        Agent(name: 'code', mode: 'primary', hidden: false, native: false),
        Agent(name: 'build', mode: 'primary', hidden: false, native: false),
      ]);

      if (getMessagesHandler != null) {
        chatRepository.getMessagesHandler = getMessagesHandler;
      }

      final dioClient = RecordingDioClient(
        configResponse: <String, dynamic>{
          'model': 'anthropic/claude-sonnet',
          'default_agent': 'code',
        },
      );
      provider = buildProvider(dioClient: dioClient);

      await provider.initializeProviders();
      await provider.loadSessions();

      return dioClient;
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
      'fallback restores provider/model/agent from last AssistantMessage '
      'when no override exists',
      () async {
        const sessionId = 'ses_1';
        final testMessages = <ChatMessage>[
          AssistantMessage(
            id: 'msg_1',
            sessionId: sessionId,
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            parts: const <MessagePart>[],
            providerId: 'anthropic',
            modelId: 'claude-sonnet',
            mode: 'code',
            completedTime: DateTime.fromMillisecondsSinceEpoch(1100),
          ),
          UserMessage(
            id: 'msg_2',
            sessionId: sessionId,
            time: DateTime.fromMillisecondsSinceEpoch(2000),
            parts: const <MessagePart>[],
          ),
          AssistantMessage(
            id: 'msg_3',
            sessionId: sessionId,
            time: DateTime.fromMillisecondsSinceEpoch(3000),
            parts: const <MessagePart>[],
            providerId: 'openai',
            modelId: 'gpt-4o',
            mode: 'build',
            completedTime: DateTime.fromMillisecondsSinceEpoch(3100),
          ),
        ];

        await setupFullyInitialized(
          getMessagesHandler: (projectId, sid, {directory, limit}) {
            if (sid == sessionId) {
              return Future.value(Right(testMessages));
            }
            return Future.value(const Right(<ChatMessage>[]));
          },
        );

        // The provider should have loaded messages during loadLastSession(),
        // and the message-derived fallback should have adopted the last
        // assistant message's selection.
        expect(provider.selectedProviderId, 'openai');
        expect(provider.selectedModelId, 'gpt-4o');
        expect(provider.selectedAgentName, 'build');
      },
    );

    test(
      'fallback restores model variant from last AssistantMessage metadata',
      () async {
        const sessionId = 'ses_1';
        final testMessages = <ChatMessage>[
          AssistantMessage(
            id: 'msg_1',
            sessionId: sessionId,
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            parts: const <MessagePart>[],
            providerId: 'anthropic',
            modelId: 'claude-opus',
            variant: 'think',
            mode: 'code',
            completedTime: DateTime.fromMillisecondsSinceEpoch(1100),
          ),
        ];

        await setupFullyInitialized(
          getMessagesHandler: (projectId, sid, {directory, limit}) {
            if (sid == sessionId) {
              return Future.value(Right(testMessages));
            }
            return Future.value(const Right(<ChatMessage>[]));
          },
        );

        expect(provider.selectedProviderId, 'anthropic');
        expect(provider.selectedModelId, 'claude-opus');
        expect(provider.selectedVariantId, 'think');
        expect(provider.selectedAgentName, 'code');
      },
    );

    test(
      'fallback is skipped when an explicit override already exists',
      () async {
        const sessionId = 'ses_1';
        final testMessages = <ChatMessage>[
          AssistantMessage(
            id: 'msg_1',
            sessionId: sessionId,
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            parts: const <MessagePart>[],
            providerId: 'openai',
            modelId: 'gpt-4o',
            mode: 'build',
            completedTime: DateTime.fromMillisecondsSinceEpoch(1100),
          ),
        ];

        await setupFullyInitialized(
          getMessagesHandler: (projectId, sid, {directory, limit}) {
            if (sid == sessionId) {
              return Future.value(Right(testMessages));
            }
            return Future.value(const Right(<ChatMessage>[]));
          },
        );

        // After initial load, the fallback should have set openai/gpt-4o.
        // Now explicitly change the provider — this stores an explicit
        // override that the message fallback must not overwrite.
        await provider.setSelectedProvider('anthropic');
        await provider.setSelectedModel('claude-sonnet');

        // Re-select the session — the explicit override should win.
        final session = provider.sessions.first;
        await provider.selectSession(session);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(provider.selectedProviderId, 'anthropic');
        expect(provider.selectedModelId, 'claude-sonnet');
      },
    );

    test(
      'fallback does nothing when no messages are cached',
      () async {
        await setupFullyInitialized();

        // No messages handler — loadMessages returns empty list.
        // The default from config is anthropic/claude-sonnet/code.
        expect(provider.selectedProviderId, 'anthropic');
        expect(provider.selectedModelId, 'claude-sonnet');
        expect(provider.selectedAgentName, 'code');
      },
    );

    test(
      'fallback skips neutral assistant messages (summary, compaction)',
      () async {
        const sessionId = 'ses_1';
        final testMessages = <ChatMessage>[
          AssistantMessage(
            id: 'msg_1',
            sessionId: sessionId,
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            parts: const <MessagePart>[],
            providerId: 'anthropic',
            modelId: 'claude-sonnet',
            mode: 'code',
            completedTime: DateTime.fromMillisecondsSinceEpoch(1100),
          ),
          // Summary message — should be skipped by the fallback.
          AssistantMessage(
            id: 'msg_summary',
            sessionId: sessionId,
            time: DateTime.fromMillisecondsSinceEpoch(2000),
            parts: const <MessagePart>[],
            providerId: 'openai',
            modelId: 'gpt-4o',
            mode: 'build',
            summary: true,
            completedTime: DateTime.fromMillisecondsSinceEpoch(2100),
          ),
        ];

        await setupFullyInitialized(
          getMessagesHandler: (projectId, sid, {directory, limit}) {
            if (sid == sessionId) {
              return Future.value(Right(testMessages));
            }
return Future.value(const Right(<ChatMessage>[]));
    },
  );

  // The fallback should have skipped the summary and found msg_1.
        expect(provider.selectedProviderId, 'anthropic');
        expect(provider.selectedModelId, 'claude-sonnet');
        expect(provider.selectedAgentName, 'code');
      },
    );

    test(
      'fallback persists restored selection as an explicit override',
      () async {
        const sessionId = 'ses_1';
        var callCount = 0;
        final testMessages = <ChatMessage>[
          AssistantMessage(
            id: 'msg_1',
            sessionId: sessionId,
            time: DateTime.fromMillisecondsSinceEpoch(1000),
            parts: const <MessagePart>[],
            providerId: 'openai',
            modelId: 'gpt-4o',
            mode: 'build',
            completedTime: DateTime.fromMillisecondsSinceEpoch(1100),
          ),
        ];

        await setupFullyInitialized(
          getMessagesHandler: (projectId, sid, {directory, limit}) {
            if (sid == sessionId) {
              callCount++;
              // First call: return messages. Second call: return empty.
              if (callCount == 1) {
                return Future.value(Right(testMessages));
              }
              return Future.value(const Right(<ChatMessage>[]));
            }
            return Future.value(const Right(<ChatMessage>[]));
          },
        );

        expect(provider.selectedProviderId, 'openai');
        expect(provider.selectedModelId, 'gpt-4o');

        // Re-select the session — the override (stored by the first fallback)
        // should now win without needing messages.
        final session = provider.sessions.first;
        await provider.selectSession(session);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(provider.selectedProviderId, 'openai');
        expect(provider.selectedModelId, 'gpt-4o');
        expect(provider.selectedAgentName, 'build');
      },
    );
  });
}
