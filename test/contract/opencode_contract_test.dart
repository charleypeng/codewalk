@Tags(<String>['slow'])
library;

import 'dart:async';

import 'package:codewalk/core/errors/failures.dart';
import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/domain/entities/agent.dart';
import 'package:codewalk/domain/entities/chat_message.dart';
import 'package:codewalk/domain/entities/chat_realtime.dart';
import 'package:codewalk/domain/entities/provider.dart';
import 'package:codewalk/presentation/providers/chat_provider.dart';
import 'package:codewalk/presentation/providers/settings_provider.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../unit/providers/chat_provider_test_support.dart';

void main() {
  group('OpenCode contract invariants', () {
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
        if (predicate()) {
          return;
        }
        await pumpEventQueue();
      }
      fail(reason ?? 'Condition was not met before event queue settled.');
    }

    test(
      'sendMessage keeps the optimistic local_user prefix and omits messageId in prompt_async payload',
      () async {
        final sendStream = StreamController<Either<Failure, ChatMessage>>();
        addTearDown(() async {
          if (!sendStream.isClosed) {
            await sendStream.close();
          }
        });
        chatRepository.sendMessageHandler = (_, _, _, _) => sendStream.stream;

        await provider.projectProvider.initializeProject();
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);

        final started = await provider.sendMessage('contract prompt');
        expect(started, isTrue);

        await settleUntil(
          () => provider.messages.whereType<UserMessage>().length == 1,
          reason: 'Expected optimistic user message to be visible.',
        );

        final optimistic = provider.messages.single as UserMessage;
        expect(optimistic.id, startsWith('local_user_'));
        expect(chatRepository.lastSendInput?.messageId, isNull);
      },
    );

    test(
      'remote selection sync is deferred while the session is busy and flushes on idle',
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
              Provider(
                id: 'provider_b',
                name: 'Provider B',
                env: const <String>[],
                models: <String, Model>{'model_b': testModel('model_b')},
              ),
            ],
            defaultModels: const <String, String>{'provider_a': 'model_a'},
            connected: const <String>['provider_a', 'provider_b'],
          ),
        );

        final dioClient = RecordingDioClient(
          configResponse: <String, dynamic>{'model': 'provider_a/model_a'},
        );
        provider = buildProvider(dioClient: dioClient);

        await provider.initializeProviders();
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        dioClient.patchBodies.clear();

        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.status',
            properties: <String, dynamic>{
              'sessionID': 'ses_1',
              'status': <String, dynamic>{'type': 'busy'},
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));

        await provider.setSelectedModelByProvider(
          providerId: 'provider_b',
          modelId: 'model_b',
        );

        final sentWhileBusy = dioClient.patchBodies
            .whereType<Map<String, dynamic>>()
            .any((body) {
              final selection = selectionPayloadFromPatch(body);
              return selection?['providerId'] == 'provider_b' &&
                  selection?['modelId'] == 'model_b';
            });
        expect(sentWhileBusy, isFalse);

        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.status',
            properties: <String, dynamic>{
              'sessionID': 'ses_1',
              'status': <String, dynamic>{'type': 'idle'},
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));

        final sentAfterIdle = dioClient.patchBodies
            .whereType<Map<String, dynamic>>()
            .any((body) {
              final selection = selectionPayloadFromPatch(body);
              return selection?['providerId'] == 'provider_b' &&
                  selection?['modelId'] == 'model_b';
            });
        expect(sentAfterIdle, isTrue);
      },
    );

    test(
      'remote selection sync stays deferred during abort suppression and only flushes when safe again',
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
              Provider(
                id: 'provider_b',
                name: 'Provider B',
                env: const <String>[],
                models: <String, Model>{'model_b': testModel('model_b')},
              ),
            ],
            defaultModels: const <String, String>{'provider_a': 'model_a'},
            connected: const <String>['provider_a', 'provider_b'],
          ),
        );
        appRepository.agentsResult = const Right(<Agent>[
          Agent(name: 'build', mode: 'primary', hidden: false, native: false),
        ]);

        final dioClient = RecordingDioClient(
          configResponse: <String, dynamic>{
            'model': 'provider_a/model_a',
            'default_agent': 'build',
          },
        );
        provider = buildProvider(
          dioClient: dioClient,
          syncHealthCheckInterval: const Duration(milliseconds: 50),
          abortSuppressionWindow: const Duration(milliseconds: 50),
        );

        final sendStream = StreamController<Either<Failure, ChatMessage>>();
        addTearDown(() async {
          if (!sendStream.isClosed) {
            await sendStream.close();
          }
        });
        chatRepository.sendMessageHandler = (_, sessionId, _, _) {
          sendStream.add(
            Right(
              AssistantMessage(
                id: 'msg_a_1',
                sessionId: sessionId,
                time: DateTime.now(),
                completedTime: DateTime.now(),
                parts: <MessagePart>[
                  TextPart(
                    id: 'p1',
                    messageId: 'msg_a_1',
                    sessionId: sessionId,
                    text: 'ok',
                  ),
                ],
              ),
            ),
          );
          return sendStream.stream;
        };

        await provider.initializeProviders();
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);
        dioClient.patchBodies.clear();

        await provider.sendMessage('hello');
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await sendStream.close();
        await Future<void>.delayed(const Duration(milliseconds: 10));

        await provider.setSelectedModelByProvider(
          providerId: 'provider_b',
          modelId: 'model_b',
        );

        final sentDuringAbortSuppression = dioClient.patchBodies
            .whereType<Map<String, dynamic>>()
            .any((body) {
              final selection = selectionPayloadFromPatch(body);
              return selection?['providerId'] == 'provider_b' &&
                  selection?['modelId'] == 'model_b';
            });
        expect(sentDuringAbortSuppression, isFalse);

        await Future<void>.delayed(const Duration(milliseconds: 80));
        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.status',
            properties: <String, dynamic>{
              'sessionID': 'ses_1',
              'status': <String, dynamic>{'type': 'idle'},
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));

        final sentAfterSafeIdle = dioClient.patchBodies
            .whereType<Map<String, dynamic>>()
            .any((body) {
              final selection = selectionPayloadFromPatch(body);
              return selection?['providerId'] == 'provider_b' &&
                  selection?['modelId'] == 'model_b';
            });
        expect(sentAfterSafeIdle, isTrue);
      },
    );
  });
}
