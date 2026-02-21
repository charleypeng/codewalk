import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import 'chat_cache_payload_store_base.dart';

ChatCachePayloadStore? createChatCachePayloadStore() {
  return _FileBackedChatCachePayloadStore();
}

class _FileBackedChatCachePayloadStore implements ChatCachePayloadStore {
  static const int _maxInMemoryEntries = 24;

  final LinkedHashMap<String, String> _memoryCache =
      LinkedHashMap<String, String>();
  Future<Directory>? _cacheDirectoryFuture;

  @override
  Future<String?> read(String key) async {
    final inMemory = _touchMemory(key);
    if (inMemory != null) {
      return inMemory;
    }

    final file = await _fileForKey(key);
    if (!await file.exists()) {
      return null;
    }

    final value = await file.readAsString();
    _storeMemory(key, value);
    return value;
  }

  @override
  Future<void> write(String key, String value) async {
    _storeMemory(key, value);
    final file = await _fileForKey(key);
    await file.parent.create(recursive: true);
    await file.writeAsString(value, flush: true);
  }

  @override
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    final file = await _fileForKey(key);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> clear() async {
    _memoryCache.clear();
    final directory = await _cacheDirectory();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    _cacheDirectoryFuture = null;
  }

  String? _touchMemory(String key) {
    final cached = _memoryCache.remove(key);
    if (cached == null) {
      return null;
    }
    _memoryCache[key] = cached;
    return cached;
  }

  void _storeMemory(String key, String value) {
    _memoryCache.remove(key);
    _memoryCache[key] = value;
    while (_memoryCache.length > _maxInMemoryEntries) {
      _memoryCache.remove(_memoryCache.keys.first);
    }
  }

  Future<File> _fileForKey(String key) async {
    final directory = await _cacheDirectory();
    final digest = sha1.convert(utf8.encode(key)).toString();
    return File('${directory.path}${Platform.pathSeparator}$digest.json');
  }

  Future<Directory> _cacheDirectory() {
    _cacheDirectoryFuture ??= _resolveCacheDirectory();
    return _cacheDirectoryFuture!;
  }

  Future<Directory> _resolveCacheDirectory() async {
    final supportDirectory = await getApplicationSupportDirectory();
    return Directory(
      '${supportDirectory.path}${Platform.pathSeparator}chat_cache_v1',
    );
  }
}
