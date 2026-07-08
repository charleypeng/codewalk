import 'package:codewalk/core/auth/tts_api_key_storage.dart';
import 'package:codewalk/domain/entities/experience_settings.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTtsApiKeyStorageBackend implements TtsApiKeyStorageBackend {
  final Map<String, String> values = <String, String>{};
  bool fail = false;

  @override
  Future<void> write({required String key, required String value}) async {
    if (fail) {
      throw StateError('secure storage unavailable');
    }
    values[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    if (fail) {
      throw StateError('secure storage unavailable');
    }
    return values[key];
  }

  @override
  Future<void> delete({required String key}) async {
    if (fail) {
      throw StateError('secure storage unavailable');
    }
    values.remove(key);
  }
}

void main() {
  group('TtsApiKeyStorage', () {
    test('stores keys under provider-scoped secure keys', () async {
      final backend = _FakeTtsApiKeyStorageBackend();
      final storage = TtsApiKeyStorage(backend: backend);

      await storage.write(ReadAloudProvider.openAiCompatible, ' sk-test ');

      expect(backend.values, hasLength(1));
      expect(backend.values.keys.single, contains('tts_api_key'));
      expect(backend.values.keys.single, contains('openai_compatible'));
      expect(await storage.read(ReadAloudProvider.openAiCompatible), 'sk-test');
      expect(await storage.read(ReadAloudProvider.edgeExperimental), isNull);
    });

    test('empty writes delete existing keys', () async {
      final backend = _FakeTtsApiKeyStorageBackend();
      final storage = TtsApiKeyStorage(backend: backend);

      await storage.write(ReadAloudProvider.openAiCompatible, 'sk-test');
      await storage.write(ReadAloudProvider.openAiCompatible, '  ');

      expect(await storage.read(ReadAloudProvider.openAiCompatible), isNull);
      expect(backend.values, isEmpty);
    });

    test('fails closed when secure storage is unavailable', () async {
      final backend = _FakeTtsApiKeyStorageBackend()..fail = true;
      final storage = TtsApiKeyStorage(backend: backend);

      expect(
        () => storage.write(ReadAloudProvider.openAiCompatible, 'sk-test'),
        throwsA(isA<TtsApiKeyStorageException>()),
      );
      expect(
        () => storage.read(ReadAloudProvider.openAiCompatible),
        throwsA(isA<TtsApiKeyStorageException>()),
      );
    });
  });
}
