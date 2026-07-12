// ignore_for_file: avoid_slow_async_io

import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

import 'session_attention_snapshot_file_store_base.dart';

SessionAttentionSnapshotFileStore createSessionAttentionSnapshotFileStore() {
  return _IoSessionAttentionSnapshotFileStore();
}

class _IoSessionAttentionSnapshotFileStore
    implements SessionAttentionSnapshotFileStore {
  Future<File>? _fileFuture;

  @override
  Future<String?> read() async {
    final file = await _file();
    if (!await file.exists()) {
      return null;
    }
    return file.readAsString();
  }

  @override
  Future<void> writeAtomically(String value) async {
    final target = await _file();
    await target.parent.create(recursive: true);
    final suffix = List<int>.generate(
      12,
      (_) => Random.secure().nextInt(256),
      growable: false,
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    final temporary = File('${target.path}.tmp.$suffix');
    try {
      await temporary.writeAsString(value, flush: true);
      await temporary.rename(target.path);
    } finally {
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }

  @override
  Future<void> delete() async {
    final file = await _file();
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> _file() {
    _fileFuture ??= _resolveFile();
    return _fileFuture!;
  }

  Future<File> _resolveFile() async {
    final support = await getApplicationSupportDirectory();
    return File(
      '${support.path}${Platform.pathSeparator}session_attention_v1'
      '${Platform.pathSeparator}snapshot.json',
    );
  }
}
