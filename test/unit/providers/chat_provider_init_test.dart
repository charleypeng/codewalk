@Tags(<String>['slow'])
library;

import 'dart:convert';

import 'package:codewalk/core/errors/failures.dart';
import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/domain/entities/agent.dart';
import 'package:codewalk/domain/entities/provider.dart';
import 'package:codewalk/presentation/providers/chat_provider.dart';
import 'package:codewalk/presentation/providers/settings_provider.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import 'chat_provider_test_support.dart';

void main() {
  group('ChatProvider - init', () {
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
      final fixtures = await buildDefaultTestFixtures();
      chatRepository = fixtures.chatRepository;
      appRepository = fixtures.appRepository;
      localDataSource = fixtures.localDataSource;
      defaultSettingsProvider = fixtures.defaultSettingsProvider;
      provider = buildProvider();
    });

    test(
      'initializeProviders chooses first connected provider and default model',
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
            defaultModels: const <String, String>{'provider_b': 'model_b'},
            connected: const <String>['provider_b'],
          ),
        );

        await provider.initializeProviders();

        expect(provider.providers, hasLength(2));
        expect(provider.selectedProviderId, 'provider_b');
        expect(provider.selectedModelId, 'model_b');
      },
    );

    test(
      'initializeProviders restores cached provider catalog before revalidation',
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

        await provider.initializeProviders();

        final cachedProvider = buildProvider();
        appRepository.providersResult = Left(
          NetworkFailure('provider refresh failed'),
        );

        await cachedProvider.initializeProviders();

        expect(cachedProvider.providers, hasLength(1));
        expect(cachedProvider.selectedProviderId, 'provider_a');
        expect(cachedProvider.selectedModelId, 'model_a');
        expect(
          cachedProvider.providersRefreshState,
          ChatProvidersRefreshState.ready,
        );
      },
    );

    test(
      'initializeProviders prioritizes server config model over local persisted selection',
      () async {
        await localDataSource.saveSelectedProvider(
          'provider_a',
          serverId: 'srv_test',
          scopeId: 'default',
        );
        await localDataSource.saveSelectedModel(
          'model_a',
          serverId: 'srv_test',
          scopeId: 'default',
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
            connected: const <String>['provider_a'],
          ),
        );

        final dioClient = RecordingDioClient(
          configResponse: <String, dynamic>{'model': 'provider_b/model_b'},
        );
        provider = buildProvider(dioClient: dioClient);

        await provider.initializeProviders();

        expect(provider.selectedProviderId, 'provider_b');
        expect(provider.selectedModelId, 'model_b');
      },
    );

    test(
      'initializeProviders prioritizes __codewalk namespaced selection over legacy root keys',
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
          Agent(name: 'plan', mode: 'primary', hidden: false, native: false),
        ]);

        final dioClient = RecordingDioClient(
          configResponse: <String, dynamic>{
            'model': 'provider_a/model_a',
            'default_agent': 'build',
            'agent': <String, dynamic>{
              '__codewalk': <String, dynamic>{
                'options': <String, dynamic>{
                  'codewalk': <String, dynamic>{
                    'selection': <String, dynamic>{
                      'providerId': 'provider_b',
                      'modelId': 'model_b',
                      'agentName': 'plan',
                    },
                  },
                },
              },
            },
          },
        );
        provider = buildProvider(dioClient: dioClient);

        await provider.initializeProviders();

        expect(provider.selectedProviderId, 'provider_b');
        expect(provider.selectedModelId, 'model_b');
        expect(provider.selectedAgentName, 'plan');
        expect(dioClient.getQueries.every((query) => query == null), isTrue);
      },
    );

    test(
      'setSelectedModelByProvider syncs model selection to server config',
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

        final dioClient = RecordingDioClient(
          configResponse: <String, dynamic>{'model': 'provider_a/model_a'},
        );
        provider = buildProvider(dioClient: dioClient);

        await provider.initializeProviders();
        dioClient.patchBodies.clear();

        await provider.setSelectedModelByProvider(
          providerId: 'provider_b',
          modelId: 'model_b',
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        final hasModelPatch = dioClient.patchBodies.any((body) {
          final selection = selectionPayloadFromPatch(body);
          return selection?['providerId'] == 'provider_b' &&
              selection?['modelId'] == 'model_b';
        });
        expect(hasModelPatch, isTrue);
        expect(dioClient.patchQueries.every((query) => query == null), isTrue);
      },
    );

    test(
      'setSelectedModelByProvider does not sync when experimental multi-device sync is disabled',
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

        final settingsProvider = await buildSettingsProvider(
          enableExperimentalMultiDeviceSync: false,
        );
        final dioClient = RecordingDioClient(
          configResponse: <String, dynamic>{'model': 'provider_a/model_a'},
        );
        provider = buildProvider(
          dioClient: dioClient,
          settingsProvider: settingsProvider,
        );

        await provider.initializeProviders();
        dioClient.patchBodies.clear();

        await provider.setSelectedModelByProvider(
          providerId: 'provider_b',
          modelId: 'model_b',
        );

        final hasModelPatch = dioClient.patchBodies.any((body) {
          final selection = selectionPayloadFromPatch(body);
          return selection?['providerId'] == 'provider_b' &&
              selection?['modelId'] == 'model_b';
        });
        expect(provider.selectedProviderId, 'provider_b');
        expect(provider.selectedModelId, 'model_b');
        expect(hasModelPatch, isFalse);
      },
    );

    test(
      'initializeProviders ignores remote composer selection when experimental sync is disabled',
      () async {
        await localDataSource.saveSelectedProvider(
          'provider_a',
          serverId: 'srv_test',
          scopeId: 'default',
        );
        await localDataSource.saveSelectedModel(
          'model_a',
          serverId: 'srv_test',
          scopeId: 'default',
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
        appRepository.agentsResult = const Right(<Agent>[
          Agent(name: 'build', mode: 'primary', hidden: false, native: false),
          Agent(name: 'plan', mode: 'primary', hidden: false, native: false),
        ]);

        final settingsProvider = await buildSettingsProvider(
          enableExperimentalMultiDeviceSync: false,
        );
        final dioClient = RecordingDioClient(
          configResponse: <String, dynamic>{
            'model': 'provider_a/model_a',
            'default_agent': 'build',
            'agent': <String, dynamic>{
              '__codewalk': <String, dynamic>{
                'options': <String, dynamic>{
                  'codewalk': <String, dynamic>{
                    'selection': <String, dynamic>{
                      'providerId': 'provider_b',
                      'modelId': 'model_b',
                      'agentName': 'plan',
                    },
                  },
                },
              },
            },
          },
        );
        provider = buildProvider(
          dioClient: dioClient,
          settingsProvider: settingsProvider,
        );

        await provider.initializeProviders();

        expect(provider.selectedProviderId, 'provider_a');
        expect(provider.selectedModelId, 'model_a');
        expect(provider.selectedAgentName, 'build');
      },
    );

    test(
      'initializeProviders prioritizes server default_agent over local persisted agent',
      () async {
        await localDataSource.saveSelectedAgent(
          'plan',
          serverId: 'srv_test',
          scopeId: 'default',
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
        appRepository.agentsResult = const Right(<Agent>[
          Agent(name: 'build', mode: 'primary', hidden: false, native: false),
          Agent(name: 'plan', mode: 'primary', hidden: false, native: false),
        ]);

        final dioClient = RecordingDioClient(
          configResponse: <String, dynamic>{
            'model': 'provider_a/model_a',
            'default_agent': 'build',
          },
        );
        provider = buildProvider(dioClient: dioClient);

        await provider.initializeProviders();

        expect(provider.selectedAgentName, 'build');
      },
    );

    test('setSelectedAgent syncs agent selection to server config', () async {
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

      final dioClient = RecordingDioClient(
        configResponse: <String, dynamic>{
          'model': 'provider_a/model_a',
          'default_agent': 'build',
        },
      );
      provider = buildProvider(dioClient: dioClient);

      await provider.initializeProviders();
      dioClient.patchBodies.clear();

      await provider.setSelectedAgent('plan');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final hasAgentPatch = dioClient.patchBodies.any((body) {
        final selection = selectionPayloadFromPatch(body);
        return selection?['agentName'] == 'plan';
      });
      expect(hasAgentPatch, isTrue);
      expect(dioClient.patchQueries.every((query) => query == null), isTrue);
    });

    test(
      'initializeProviders prioritizes remote variant map over local variant map',
      () async {
        await localDataSource.saveSelectedVariantMap(
          json.encode(<String, String>{'provider_a/model_reasoning': 'low'}),
          serverId: 'srv_test',
          scopeId: 'default',
        );

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
          Agent(name: 'plan', mode: 'primary', hidden: false, native: false),
        ]);

        final dioClient = RecordingDioClient(
          configResponse: <String, dynamic>{
            'model': 'provider_a/model_reasoning',
            'default_agent': 'build',
            'agent': <String, dynamic>{
              'build': <String, dynamic>{
                'options': <String, dynamic>{
                  'codewalk': <String, dynamic>{
                    'variantByModel': <String, String>{
                      'provider_a/model_reasoning': 'high',
                    },
                  },
                },
              },
            },
          },
        );
        provider = buildProvider(dioClient: dioClient);

        await provider.initializeProviders();

        expect(provider.selectedVariantId, 'high');
      },
    );

    test(
      'initializeProviders resolves remote variant value case-insensitively',
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
            'agent': <String, dynamic>{
              'build': <String, dynamic>{
                'options': <String, dynamic>{
                  'codewalk': <String, dynamic>{
                    'variantByModel': <String, String>{
                      'provider_a/model_reasoning': 'HIGH',
                    },
                  },
                },
              },
            },
          },
        );
        provider = buildProvider(dioClient: dioClient);

        await provider.initializeProviders();

        expect(provider.selectedVariantId, 'high');
      },
    );

    test(
      'initializeProviders ignores remote variant display names and expects canonical id',
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
                      'reasoning_low': ModelVariant(
                        id: 'reasoning_low',
                        name: 'Low',
                      ),
                      'reasoning_high': ModelVariant(
                        id: 'reasoning_high',
                        name: 'High',
                      ),
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
            'agent': <String, dynamic>{
              'build': <String, dynamic>{
                'options': <String, dynamic>{
                  'codewalk': <String, dynamic>{
                    'variantByModel': <String, String>{
                      'provider_a/model_reasoning': 'High',
                    },
                  },
                },
              },
            },
          },
        );
        provider = buildProvider(dioClient: dioClient);

        await provider.initializeProviders();

        expect(provider.selectedVariantId, isNull);
      },
    );

    test('setSelectedVariant syncs variant map to server config', () async {
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
      provider = buildProvider(dioClient: dioClient);

      await provider.initializeProviders();
      dioClient.patchBodies.clear();

      await provider.setSelectedVariant('high');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final variantPatch = dioClient.patchBodies
          .whereType<Map<String, dynamic>>()
          .where((body) => body.containsKey('agent'))
          .cast<Map<String, dynamic>>()
          .first;
      final variantValue = variantPayloadValueFromPatch(
        variantPatch,
        agentName: 'build',
        modelKey: 'provider_a/model_reasoning',
      );

      expect(variantValue, 'high');
      expect(dioClient.patchQueries.every((query) => query == null), isTrue);
    });
  });
}
