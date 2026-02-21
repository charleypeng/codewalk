import 'dart:convert';

import 'package:codewalk/core/constants/app_constants.dart';
import 'package:codewalk/data/cache/chat_cache_payload_store.dart';
import 'package:codewalk/data/datasources/app_local_datasource.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemoryChatCachePayloadStore implements ChatCachePayloadStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<void> clear() async {
    values.clear();
  }

  @override
  Future<String?> read(String key) async {
    return values[key];
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  final secureValues = <String, String>{};

  setUp(() {
    secureValues.clear();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
          final arguments =
              (call.arguments as Map<dynamic, dynamic>? ??
              const <dynamic, dynamic>{});
          final key = arguments['key']?.toString() ?? '';

          switch (call.method) {
            case 'read':
              return secureValues[key];
            case 'write':
              final value = arguments['value']?.toString();
              if (value == null) {
                secureValues.remove(key);
              } else {
                secureValues[key] = value;
              }
              return null;
            case 'delete':
              secureValues.remove(key);
              return null;
            case 'deleteAll':
              secureValues.clear();
              return null;
            case 'containsKey':
              return secureValues.containsKey(key);
            case 'readAll':
              return Map<String, String>.from(secureValues);
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  test(
    'migrates legacy api key from SharedPreferences to secure storage',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        AppConstants.apiKeyKey: 'legacy-token-123',
      });
      final prefs = await SharedPreferences.getInstance();
      final dataSource = AppLocalDataSourceImpl(sharedPreferences: prefs);

      final value = await dataSource.getApiKey();

      expect(value, 'legacy-token-123');
      expect(prefs.getString(AppConstants.apiKeyKey), isNull);
      expect(
        secureValues['${AppConstants.secureStorageNamespace}::${AppConstants.apiKeyKey}'],
        'legacy-token-123',
      );
    },
  );

  test(
    'stores server profile basic auth in secure storage and keeps prefs sanitized',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final dataSource = AppLocalDataSourceImpl(sharedPreferences: prefs);
      const serverId = 'srv_main';

      await dataSource.saveServerProfilesJson(
        jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': serverId,
            'url': 'http://127.0.0.1:4096',
            'basicAuthEnabled': true,
            'basicAuthUsername': 'alice',
            'basicAuthPassword': 'super-secret',
            'createdAt': 1,
            'updatedAt': 1,
          },
        ]),
      );

      final storedJson = prefs.getString(AppConstants.serverProfilesKey);
      expect(storedJson, isNotNull);
      final storedProfiles = jsonDecode(storedJson!) as List<dynamic>;
      final storedProfile = Map<String, dynamic>.from(
        storedProfiles.first as Map<dynamic, dynamic>,
      );
      expect(storedProfile['basicAuthUsername'], '');
      expect(storedProfile['basicAuthPassword'], '');

      expect(
        secureValues['${AppConstants.secureStorageNamespace}::${AppConstants.secureServerProfileBasicAuthUsernameKey}::${Uri.encodeComponent(serverId)}'],
        'alice',
      );
      expect(
        secureValues['${AppConstants.secureStorageNamespace}::${AppConstants.secureServerProfileBasicAuthPasswordKey}::${Uri.encodeComponent(serverId)}'],
        'super-secret',
      );

      final hydratedJson = await dataSource.getServerProfilesJson();
      final hydratedProfiles = jsonDecode(hydratedJson!) as List<dynamic>;
      final hydratedProfile = Map<String, dynamic>.from(
        hydratedProfiles.first as Map<dynamic, dynamic>,
      );
      expect(hydratedProfile['basicAuthUsername'], 'alice');
      expect(hydratedProfile['basicAuthPassword'], 'super-secret');
    },
  );

  test(
    'stores large chat cache payload in cache store instead of preferences',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final cacheStore = _InMemoryChatCachePayloadStore();
      final dataSource = AppLocalDataSourceImpl(
        sharedPreferences: prefs,
        chatCachePayloadStore: cacheStore,
      );

      await dataSource.saveCachedSessions('[{"id":"s1"}]');

      expect(
        cacheStore.values[AppConstants.cachedSessionsKey],
        '[{"id":"s1"}]',
      );
      expect(prefs.getString(AppConstants.cachedSessionsKey), isNull);
    },
  );

  test(
    'migrates legacy cached sessions payload from preferences to cache store',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        AppConstants.cachedSessionsKey: '[{"id":"legacy"}]',
      });
      final prefs = await SharedPreferences.getInstance();
      final cacheStore = _InMemoryChatCachePayloadStore();
      final dataSource = AppLocalDataSourceImpl(
        sharedPreferences: prefs,
        chatCachePayloadStore: cacheStore,
      );

      final payload = await dataSource.getCachedSessions();

      expect(payload, '[{"id":"legacy"}]');
      expect(
        cacheStore.values[AppConstants.cachedSessionsKey],
        '[{"id":"legacy"}]',
      );
      expect(prefs.getString(AppConstants.cachedSessionsKey), isNull);
    },
  );
}
