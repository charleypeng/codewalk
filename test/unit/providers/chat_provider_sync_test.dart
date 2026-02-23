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
import 'package:codewalk/presentation/providers/chat_provider.dart';
import 'package:codewalk/presentation/providers/settings_provider.dart';
import 'package:codewalk/presentation/services/sound_service.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import 'chat_provider_test_support.dart';

void main() {
  group('ChatProvider - sync', () {
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

    Future<SettingsProvider> buildSettingsProvider({
      required bool enableExperimentalMultiDeviceSync,
    }) {
      return buildTestSettingsProvider(
        localDataSource: localDataSource,
        enableExperimentalMultiDeviceSync: enableExperimentalMultiDeviceSync,
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
      'deferred variant sync stays queued while session is busy and flushes on idle',
      () async {
        appRepository.providersResult = Right(
          ProvidersResponse(
            providers: <Provider>[
              Provider(
                id: 'provider_a',
                name: 'Provider A',
                env: const <String>[],
                models: <String, Model>{
                  'model_reasoning': testModel(
                    'model_reasoning',
                    variants: const <String, ModelVariant>{
                      'low': ModelVariant(id: 'low', name: 'Low'),
                      'high': ModelVariant(id: 'high', name: 'High'),
                    },
                  ),
                },
              ),
            ],
            defaultModels: const <String, String>{
              'provider_a': 'model_reasoning',
            },
            connected: const <String>['provider_a'],
          ),
        );
        appRepository.agentsResult = const Right(<Agent>[
          Agent(name: 'build', mode: 'primary', hidden: false, native: false),
        ]);

        final dioClient = RecordingDioClient(
          configResponse: <String, dynamic>{
            'model': 'provider_a/model_reasoning',
            'default_agent': 'build',
          },
        );
        provider = buildProvider(
          dioClient: dioClient,
          syncHealthCheckInterval: const Duration(milliseconds: 50),
        );

        await provider.initializeProviders();
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);
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

        await provider.setSelectedVariant('high');

        final hasImmediateVariantPatch = dioClient.patchBodies
            .whereType<Map<String, dynamic>>()
            .any(
              (body) =>
                  variantPayloadValueFromPatch(
                    body,
                    agentName: 'build',
                    modelKey: 'provider_a/model_reasoning',
                  ) ==
                  'high',
            );
        expect(hasImmediateVariantPatch, isFalse);

        await Future<void>.delayed(const Duration(milliseconds: 180));

        final hasFlushedVariantPatch = dioClient.patchBodies
            .whereType<Map<String, dynamic>>()
            .any(
              (body) =>
                  variantPayloadValueFromPatch(
                    body,
                    agentName: 'build',
                    modelKey: 'provider_a/model_reasoning',
                  ) ==
                  'high',
            );
        expect(hasFlushedVariantPatch, isFalse);

        chatRepository.emitEvent(
          const ChatEvent(
            type: 'session.status',
            properties: <String, dynamic>{
              'sessionID': 'ses_1',
              'status': <String, dynamic>{'type': 'idle'},
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 80));

        final hasFlushedVariantPatchOnIdle = dioClient.patchBodies
            .whereType<Map<String, dynamic>>()
            .any(
              (body) =>
                  variantPayloadValueFromPatch(
                    body,
                    agentName: 'build',
                    modelKey: 'provider_a/model_reasoning',
                  ) ==
                  'high',
            );
        expect(hasFlushedVariantPatchOnIdle, isTrue);
      },
    );

    test('variant sync is not blocked after a completed send stream', () async {
      appRepository.providersResult = Right(
        ProvidersResponse(
          providers: <Provider>[
            Provider(
              id: 'provider_a',
              name: 'Provider A',
              env: const <String>[],
              models: <String, Model>{
                'model_reasoning': testModel(
                  'model_reasoning',
                  variants: const <String, ModelVariant>{
                    'low': ModelVariant(id: 'low', name: 'Low'),
                    'high': ModelVariant(id: 'high', name: 'High'),
                  },
                ),
              },
            ),
          ],
          defaultModels: const <String, String>{
            'provider_a': 'model_reasoning',
          },
          connected: const <String>['provider_a'],
        ),
      );
      appRepository.agentsResult = const Right(<Agent>[
        Agent(name: 'build', mode: 'primary', hidden: false, native: false),
      ]);

      final dioClient = RecordingDioClient(
        configResponse: <String, dynamic>{
          'model': 'provider_a/model_reasoning',
          'default_agent': 'build',
        },
      );
      provider = buildProvider(
        dioClient: dioClient,
        syncHealthCheckInterval: const Duration(milliseconds: 50),
      );

      await provider.initializeProviders();
      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);

      await provider.sendMessage('first send');
      await Future<void>.delayed(const Duration(milliseconds: 40));
      dioClient.patchBodies.clear();

      await provider.setSelectedVariant('high');
      await Future<void>.delayed(const Duration(milliseconds: 80));

      final hasVariantPatch = dioClient.patchBodies
          .whereType<Map<String, dynamic>>()
          .any(
            (body) =>
                variantPayloadValueFromPatch(
                  body,
                  agentName: 'build',
                  modelKey: 'provider_a/model_reasoning',
                ) ==
                'high',
          );
      expect(hasVariantPatch, isTrue);
    });

    test(
      'model sync is deferred while response is active and flushed on idle',
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

        final hasImmediateModelPatch = dioClient.patchBodies
            .whereType<Map>()
            .any((body) {
              final selection = selectionPayloadFromPatch(body);
              return selection?['providerId'] == 'provider_b' &&
                  selection?['modelId'] == 'model_b';
            });
        expect(hasImmediateModelPatch, isFalse);

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

        final hasFlushedModelPatch = dioClient.patchBodies.whereType<Map>().any(
          (body) {
            final selection = selectionPayloadFromPatch(body);
            return selection?['providerId'] == 'provider_b' &&
                selection?['modelId'] == 'model_b';
          },
        );
        expect(hasFlushedModelPatch, isTrue);
      },
    );

    test('session selection override wins when switching sessions', () async {
      chatRepository.sessions.add(
        ChatSession(
          id: 'ses_2',
          workspaceId: 'default',
          time: DateTime.fromMillisecondsSinceEpoch(2000),
          title: 'Session 2',
        ),
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

      await provider.initializeProviders();
      await provider.loadSessions();

      final session1 = provider.sessions.firstWhere((s) => s.id == 'ses_1');
      final session2 = provider.sessions.firstWhere((s) => s.id == 'ses_2');

      await provider.selectSession(session1);
      await provider.setSelectedModelByProvider(
        providerId: 'provider_b',
        modelId: 'model_b',
      );

      await provider.selectSession(session2);
      await provider.setSelectedModelByProvider(
        providerId: 'provider_a',
        modelId: 'model_a',
      );

      await provider.selectSession(session1);

      expect(provider.selectedProviderId, 'provider_b');
      expect(provider.selectedModelId, 'model_b');
    });

    test(
      'session selection override persists across provider restart',
      () async {
        chatRepository.sessions.add(
          ChatSession(
            id: 'ses_2',
            workspaceId: 'default',
            time: DateTime.fromMillisecondsSinceEpoch(2000),
            title: 'Session 2',
          ),
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

        await provider.initializeProviders();
        await provider.loadSessions();
        final session1 = provider.sessions.firstWhere((s) => s.id == 'ses_1');
        await provider.selectSession(session1);
        await provider.setSelectedModelByProvider(
          providerId: 'provider_b',
          modelId: 'model_b',
        );

        provider = buildProvider();
        await provider.initializeProviders();
        await provider.loadSessions();
        final restoredSession = provider.sessions.firstWhere(
          (s) => s.id == 'ses_1',
        );
        await provider.selectSession(restoredSession);

        expect(provider.selectedProviderId, 'provider_b');
        expect(provider.selectedModelId, 'model_b');
      },
    );

    test(
      'setSelectedModelByProvider syncs session selection override map to server config',
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
        dioClient.patchBodies.clear();

        await provider.setSelectedModelByProvider(
          providerId: 'provider_b',
          modelId: 'model_b',
        );

        final overridePatch = dioClient.patchBodies
            .whereType<Map<String, dynamic>>()
            .where((body) {
              final agent = body['agent'];
              return agent is Map && agent.containsKey('__codewalk');
            })
            .cast<Map<String, dynamic>>()
            .first;
        final agent = overridePatch['agent'] as Map<String, dynamic>;
        final syncAgent = agent['__codewalk'] as Map<String, dynamic>;
        final options = syncAgent['options'] as Map<String, dynamic>;
        final codewalk = options['codewalk'] as Map<String, dynamic>;
        final sessionSelections =
            codewalk['sessionSelections'] as Map<String, dynamic>;
        final sessionOverride =
            sessionSelections['ses_1'] as Map<String, dynamic>;

        expect(sessionOverride['providerId'], 'provider_b');
        expect(sessionOverride['modelId'], 'model_b');
      },
    );

    test(
      'initializeProviders applies remote session selection override after restart',
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
          configResponse: <String, dynamic>{
            'model': 'provider_a/model_a',
            'default_agent': 'build',
            'agent': <String, dynamic>{
              '__codewalk': <String, dynamic>{
                'options': <String, dynamic>{
                  'codewalk': <String, dynamic>{
                    'sessionSelections': <String, dynamic>{
                      'ses_1': <String, dynamic>{
                        'providerId': 'provider_b',
                        'modelId': 'model_b',
                        'agentName': 'build',
                        'variantId': '__auto__',
                        'updatedAt': 10,
                      },
                    },
                  },
                },
              },
            },
          },
        );
        provider = buildProvider(dioClient: dioClient);

        await provider.initializeProviders();
        await provider.loadSessions();
        final session = provider.sessions.firstWhere((s) => s.id == 'ses_1');
        await provider.selectSession(session);

        expect(provider.selectedProviderId, 'provider_b');
        expect(provider.selectedModelId, 'model_b');
      },
    );

    test(
      'open-session realtime events reconcile model agent and variant selects',
      () async {
        appRepository.providersResult = Right(
          ProvidersResponse(
            providers: <Provider>[
              Provider(
                id: 'provider_a',
                name: 'Provider A',
                env: const <String>[],
                models: <String, Model>{
                  'model_a': testModel(
                    'model_a',
                    variants: const <String, ModelVariant>{
                      'low': ModelVariant(id: 'low', name: 'Low'),
                    },
                  ),
                },
              ),
              Provider(
                id: 'provider_b',
                name: 'Provider B',
                env: const <String>[],
                models: <String, Model>{
                  'model_b': testModel(
                    'model_b',
                    variants: const <String, ModelVariant>{
                      'high': ModelVariant(id: 'high', name: 'High'),
                    },
                  ),
                },
              ),
            ],
            defaultModels: const <String, String>{'provider_a': 'model_a'},
            connected: const <String>['provider_a', 'provider_b'],
          ),
        );
        appRepository.agentsResult = const Right(<Agent>[
          Agent(name: 'build', mode: 'primary', hidden: false, native: false),
          Agent(name: 'plan', mode: 'primary', hidden: false, native: false),
        ]);

        final config = <String, dynamic>{
          'model': 'provider_a/model_a',
          'default_agent': 'build',
          'agent': <String, dynamic>{
            'build': <String, dynamic>{
              'options': <String, dynamic>{
                'codewalk': <String, dynamic>{
                  'variantByModel': <String, String>{
                    'provider_a/model_a': 'low',
                  },
                },
              },
            },
          },
        };

        final dioClient = RecordingDioClient(configResponse: config);
        provider = buildProvider(dioClient: dioClient);

        await provider.initializeProviders();
        expect(provider.selectedProviderId, 'provider_a');
        expect(provider.selectedModelId, 'model_a');
        expect(provider.selectedAgentName, 'build');
        expect(provider.selectedVariantId, 'low');

        config
          ..['model'] = 'provider_b/model_b'
          ..['default_agent'] = 'plan'
          ..['agent'] = <String, dynamic>{
            'plan': <String, dynamic>{
              'options': <String, dynamic>{
                'codewalk': <String, dynamic>{
                  'variantByModel': <String, String>{
                    'provider_b/model_b': 'high',
                  },
                },
              },
            },
          };

        await Future<void>.delayed(const Duration(milliseconds: 2100));
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

        expect(provider.selectedProviderId, 'provider_b');
        expect(provider.selectedModelId, 'model_b');
        expect(provider.selectedAgentName, 'plan');
        expect(provider.selectedVariantId, 'high');
      },
    );

    test(
      'initializeProviders restores persisted agent and filters selector',
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
        appRepository.agentsResult = const Right(<Agent>[
          Agent(name: 'plan', mode: 'primary', hidden: false, native: false),
          Agent(name: 'build', mode: 'primary', hidden: false, native: false),
          Agent(name: 'support', mode: 'all', hidden: false, native: false),
          Agent(
            name: 'internal',
            mode: 'subagent',
            hidden: false,
            native: true,
          ),
          Agent(name: 'hidden', mode: 'primary', hidden: true, native: false),
        ]);

        await localDataSource.saveSelectedAgent(
          'plan',
          serverId: 'srv_test',
          scopeId: 'default',
        );

        await provider.initializeProviders();

        expect(provider.selectedAgentName, 'plan');
        expect(provider.selectableAgents.map((agent) => agent.name), <String>[
          'build',
          'plan',
          'support',
        ]);
      },
    );

    test('setSelectedAgent and cycleAgent update payload mode', () async {
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
      appRepository.agentsResult = const Right(<Agent>[
        Agent(name: 'build', mode: 'primary', hidden: false, native: false),
        Agent(name: 'plan', mode: 'primary', hidden: false, native: false),
      ]);

      await provider.initializeProviders();
      expect(provider.selectedAgentName, 'build');

      await provider.setSelectedAgent('plan');
      expect(provider.selectedAgentName, 'plan');

      await provider.loadSessions();
      await provider.selectSession(provider.sessions.first);
      await provider.sendMessage('agent payload');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(chatRepository.lastSendInput?.mode, 'plan');

      await provider.cycleAgent(reverse: true);
      expect(provider.selectedAgentName, 'build');
    });

    test(
      'setSelectedModel and cycleVariant update selection and payload',
      () async {
        appRepository.providersResult = Right(
          ProvidersResponse(
            providers: <Provider>[
              Provider(
                id: 'provider_a',
                name: 'Provider A',
                env: const <String>[],
                models: <String, Model>{
                  'model_reasoning': testModel(
                    'model_reasoning',
                    variants: const <String, ModelVariant>{
                      'low': ModelVariant(id: 'low', name: 'Low'),
                      'high': ModelVariant(id: 'high', name: 'High'),
                    },
                  ),
                },
              ),
            ],
            defaultModels: const <String, String>{
              'provider_a': 'model_reasoning',
            },
            connected: const <String>['provider_a'],
          ),
        );

        await provider.initializeProviders();
        expect(provider.selectedVariantId, isNull);

        await provider.cycleVariant();
        expect(provider.selectedVariantId, 'low');

        await provider.cycleVariant();
        expect(provider.selectedVariantId, 'high');

        await provider.cycleVariant();
        expect(provider.selectedVariantId, isNull);

        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);
        await provider.setSelectedVariant('high');
        await provider.sendMessage('variant payload');
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(chatRepository.lastSendInput?.variant, 'high');
        expect(chatRepository.lastSendInput?.messageId, isNull);
      },
    );

    test(
      'setSelectedModelByProvider updates provider and model together',
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
            connected: const <String>['provider_a'],
          ),
        );

        await provider.initializeProviders();
        expect(provider.selectedProviderId, 'provider_a');
        expect(provider.selectedModelId, 'model_a');

        await provider.setSelectedModelByProvider(
          providerId: 'provider_b',
          modelId: 'model_b',
        );

        expect(provider.selectedProviderId, 'provider_b');
        expect(provider.selectedModelId, 'model_b');
      },
    );

    test(
      'ignores compaction summary messages when adopting selection',
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

        await provider.initializeProviders();
        await provider.loadSessions();
        await provider.selectSession(provider.sessions.first);

        expect(provider.selectedProviderId, 'provider_a');
        expect(provider.selectedModelId, 'model_a');

        final compactionSummaryMessage = AssistantMessage(
          id: 'msg_compaction_summary',
          sessionId: 'ses_1',
          time: DateTime.fromMillisecondsSinceEpoch(2000),
          completedTime: DateTime.fromMillisecondsSinceEpoch(2100),
          providerId: 'provider_b',
          modelId: 'model_b',
          summary: true,
          parts: const <MessagePart>[
            TextPart(
              id: 'part_compaction_summary_text',
              messageId: 'msg_compaction_summary',
              sessionId: 'ses_1',
              text: 'compact summary',
            ),
          ],
        );
        chatRepository.sendMessageHandler = (_, __, ___, ____) {
          return Stream<Either<Failure, ChatMessage>>.value(
            Right(compactionSummaryMessage),
          );
        };

        await provider.sendMessage('trigger compact flow');
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(provider.selectedProviderId, 'provider_a');
        expect(provider.selectedModelId, 'model_a');
      },
    );

    test(
      'onServerScopeChanged restores model selection per server scope',
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

        await provider.projectProvider.initializeProject();
        await provider.initializeProviders();
        expect(provider.selectedProviderId, 'provider_a');
        expect(provider.selectedModelId, 'model_a');

        await provider.setSelectedModelByProvider(
          providerId: 'provider_b',
          modelId: 'model_b',
        );
        expect(provider.selectedProviderId, 'provider_b');
        expect(provider.selectedModelId, 'model_b');

        localDataSource.activeServerId = 'srv_other';
        await provider.onServerScopeChanged();
        expect(provider.selectedProviderId, 'provider_a');
        expect(provider.selectedModelId, 'model_a');

        await provider.setSelectedModelByProvider(
          providerId: 'provider_a',
          modelId: 'model_a',
        );
        localDataSource.activeServerId = 'srv_test';
        await provider.onServerScopeChanged();
        expect(provider.selectedProviderId, 'provider_b');
        expect(provider.selectedModelId, 'model_b');
      },
    );

    test(
      'onServerScopeChanged restores agent selection per server scope',
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
        appRepository.agentsResult = const Right(<Agent>[
          Agent(name: 'build', mode: 'primary', hidden: false, native: false),
          Agent(name: 'plan', mode: 'primary', hidden: false, native: false),
        ]);

        await provider.projectProvider.initializeProject();
        await provider.initializeProviders();
        expect(provider.selectedAgentName, 'build');

        await provider.setSelectedAgent('plan');
        expect(provider.selectedAgentName, 'plan');

        localDataSource.activeServerId = 'srv_other';
        await provider.onServerScopeChanged();
        expect(provider.selectedAgentName, 'build');

        localDataSource.activeServerId = 'srv_test';
        await provider.onServerScopeChanged();
        expect(provider.selectedAgentName, 'plan');
      },
    );

    test('cycleVariant is no-op when current model has no variants', () async {
      appRepository.providersResult = Right(
        ProvidersResponse(
          providers: <Provider>[
            Provider(
              id: 'provider_a',
              name: 'Provider A',
              env: const <String>[],
              models: <String, Model>{'model_plain': testModel('model_plain')},
            ),
          ],
          defaultModels: const <String, String>{'provider_a': 'model_plain'},
          connected: const <String>['provider_a'],
        ),
      );

      await provider.initializeProviders();
      expect(provider.selectedVariantId, isNull);

      await provider.cycleVariant();
      expect(provider.selectedVariantId, isNull);
    });

    test(
      'initializeProviders restores recent/frequent model preference from local storage',
      () async {
        final scopeId =
            provider.projectProvider.currentProject?.path ??
            provider.projectProvider.currentProjectId;

        await localDataSource.saveRecentModelsJson(
          jsonEncode(<String>['provider_b/model_hot']),
          serverId: 'srv_test',
          scopeId: scopeId,
        );
        await localDataSource.saveModelUsageCountsJson(
          jsonEncode(<String, int>{'provider_b/model_hot': 7}),
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
              Provider(
                id: 'provider_b',
                name: 'Provider B',
                env: const <String>[],
                models: <String, Model>{'model_hot': testModel('model_hot')},
              ),
            ],
            defaultModels: const <String, String>{'provider_a': 'model_a'},
            connected: const <String>[],
          ),
        );

        await provider.initializeProviders();

        expect(provider.selectedProviderId, 'provider_b');
        expect(provider.selectedModelId, 'model_hot');
        expect(provider.recentModelKeys.first, 'provider_b/model_hot');
        expect(provider.modelUsageCounts['provider_b/model_hot'], 7);
      },
    );
  });
}
