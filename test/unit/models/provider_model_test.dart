import 'package:codewalk/data/models/provider_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProvidersResponseModel', () {
    test('parses new schema with all/default/connected', () {
      final model = ProvidersResponseModel.fromJson(<String, dynamic>{
        'all': <dynamic>[
          <String, dynamic>{
            'id': 'anthropic',
            'name': 'Anthropic',
            'env': <String>['ANTHROPIC_API_KEY'],
            'models': <String, dynamic>{
              'claude-3-5-sonnet': <String, dynamic>{
                'id': 'claude-3-5-sonnet',
                'name': 'Claude 3.5 Sonnet',
                'release_date': '2025-01-01',
                'capabilities': <String, dynamic>{
                  'attachment': true,
                  'reasoning': true,
                  'temperature': false,
                  'toolcall': true,
                  'input': <String, dynamic>{
                    'text': true,
                    'image': true,
                    'pdf': false,
                  },
                  'output': <String, dynamic>{'text': true},
                },
                'cost': <String, dynamic>{
                  'input': '0.003',
                  'output': 0.015,
                  'cache': <String, dynamic>{'read': 0.0003, 'write': 0.003},
                },
                'limit': <String, dynamic>{'context': 200000, 'output': 8192},
                'variants': <String, dynamic>{
                  'low': <String, dynamic>{
                    'name': 'Low',
                    'description': 'Fast reasoning',
                    'effort': 1,
                  },
                  'high': <String, dynamic>{'label': 'High', 'effort': 3},
                },
              },
            },
          },
        ],
        'default': <String, String>{'anthropic': 'claude-3-5-sonnet'},
        'connected': <String>['anthropic'],
      });

      expect(model.providers, hasLength(1));
      expect(model.defaultModels['anthropic'], 'claude-3-5-sonnet');
      expect(model.connected, <String>['anthropic']);

      final provider = model.toDomain().providers.single;
      final domainModel = provider.models['claude-3-5-sonnet'];

      expect(provider.id, 'anthropic');
      expect(domainModel?.toolCall, isTrue);
      expect(domainModel?.cost.cacheRead, closeTo(0.0003, 0.0000001));
      expect(domainModel?.limit.context, 200000);
      expect(domainModel?.variants.keys, containsAll(<String>['low', 'high']));
      expect(domainModel?.variants['low']?.name, 'Low');
      expect(domainModel?.variants['high']?.name, 'High');
      expect(
        domainModel?.modalities?['input'],
        containsAll(<String>['text', 'image']),
      );
    });

    test('parses legacy schema and skips invalid models', () {
      final model = ProvidersResponseModel.fromJson(<String, dynamic>{
        'providers': <dynamic>[
          <String, dynamic>{
            'id': 'openai',
            'models': <String, dynamic>{
              'valid-model': <String, dynamic>{
                'id': 'valid-model',
                'cost': <String, dynamic>{'input': 1, 'output': 2},
                'limit': <String, dynamic>{'context': 1000, 'output': 100},
                'tool_call': true,
              },
              'invalid-model': 'broken',
            },
          },
        ],
        'default': <String, String>{'openai': 'valid-model'},
      });

      final provider = model.providers.single;
      expect(provider.name, 'openai');
      expect(provider.models.keys, <String>['valid-model']);
      expect(provider.models['valid-model']?.toolCall, isTrue);
    });

    test('parses GPT-5.5 with structured reasoning object', () {
      final model = ProvidersResponseModel.fromJson(<String, dynamic>{
        'all': <dynamic>[
          <String, dynamic>{
            'id': 'openai',
            'name': 'OpenAI',
            'env': <String>['OPENAI_API_KEY'],
            'models': <String, dynamic>{
              'gpt-5.5': <String, dynamic>{
                'id': 'gpt-5.5',
                'name': 'GPT-5.5',
                'release_date': '2026-01-01',
                'reasoning': <String, dynamic>{'effort': 'medium'},
                'attachment': true,
                'tool_call': true,
                'cost': <String, dynamic>{'input': 0.01, 'output': 0.03},
                'limit': <String, dynamic>{'context': 128000, 'output': 16384},
              },
            },
          },
        ],
        'default': <String, String>{'openai': 'gpt-5.5'},
        'connected': <String>['openai'],
      });

      final provider = model.providers.single;
      final gpt55 = provider.models['gpt-5.5'];
      expect(gpt55, isNotNull, reason: 'gpt-5.5 must not be silently dropped');
      expect(
        gpt55!.reasoning,
        isTrue,
        reason: 'structured reasoning object should coerce to true',
      );
      expect(gpt55.attachment, isTrue);
      expect(gpt55.toolCall, isTrue);
      expect(gpt55.cost.input, closeTo(0.01, 0.0001));
      expect(gpt55.limit.context, 128000);
    });

    test('parses model with missing cost and limit fields', () {
      final model = ProvidersResponseModel.fromJson(<String, dynamic>{
        'all': <dynamic>[
          <String, dynamic>{
            'id': 'openai',
            'name': 'OpenAI',
            'env': <String>[],
            'models': <String, dynamic>{
              'new-model': <String, dynamic>{
                'id': 'new-model',
                'name': 'New Model',
              },
            },
          },
        ],
      });

      final m = model.providers.single.models['new-model'];
      expect(
        m,
        isNotNull,
        reason: 'model without cost/limit must not be dropped',
      );
      expect(m!.cost.input, 0.0);
      expect(m.cost.output, 0.0);
      expect(m.limit.context, 0);
      expect(m.limit.output, 0);
    });

    test(
      'parses capabilities with structured reasoning inside capabilities map',
      () {
        final model = ProvidersResponseModel.fromJson(<String, dynamic>{
          'all': <dynamic>[
            <String, dynamic>{
              'id': 'openai',
              'name': 'OpenAI',
              'env': <String>[],
              'models': <String, dynamic>{
                'o3-pro': <String, dynamic>{
                  'id': 'o3-pro',
                  'name': 'o3-pro',
                  'capabilities': <String, dynamic>{
                    'reasoning': <String, dynamic>{'effort': 'high'},
                    'attachment': true,
                    'toolcall': true,
                  },
                  'cost': <String, dynamic>{'input': 0.02, 'output': 0.08},
                  'limit': <String, dynamic>{
                    'context': 200000,
                    'output': 100000,
                  },
                },
              },
            },
          ],
        });

        final m = model.providers.single.models['o3-pro'];
        expect(m, isNotNull);
        expect(
          m!.reasoning,
          isTrue,
          reason: 'structured reasoning in capabilities should coerce to true',
        );
        expect(m.attachment, isTrue);
        expect(m.toolCall, isTrue);
      },
    );

    test('gracefully handles malformed payload types without crashing', () {
      final model = ProvidersResponseModel.fromJson(<String, dynamic>{
        'all': <dynamic>[
          <String, dynamic>{
            'id': 123, // not a string
            'name': <dynamic>[], // not a string
            'env': <String>[],
            'models': <String, dynamic>{
              'bad-model': <String, dynamic>{
                'id': 456, // not a string
                'name': <String, dynamic>{}, // not a string
                'release_date': 2026, // not a string
                'modalities': <dynamic>['text', 'image'], // list instead of map
                'options': <dynamic>['invalid'], // list instead of map
                'cost': 'free', // string instead of map
                'limit': 100, // int instead of map
              },
            },
          },
        ],
      });

      final provider = model.providers.single;
      expect(provider.id, '123', reason: 'number coerced to string');
      expect(provider.name, '123', reason: 'invalid name falls back to id');

      final m = provider.models['bad-model'];
      expect(m, isNotNull, reason: 'malformed model should still parse');
      expect(m!.id, '456', reason: 'number coerced to string');
      expect(m.name, '456', reason: 'invalid name falls back to id');
      expect(m.releaseDate, '2026', reason: 'number coerced to string');
      expect(m.modalities, <String, dynamic>{
        'input': <String>['text', 'image'],
      });
      expect(
        m.options,
        isEmpty,
        reason: 'invalid options fallback to empty map',
      );
      expect(m.cost.input, 0.0, reason: 'invalid cost fallback to default');
      expect(m.limit.context, 0, reason: 'invalid limit fallback to default');
    });
  });
}
