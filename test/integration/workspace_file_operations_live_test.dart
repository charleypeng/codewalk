@Tags(<String>['integration', 'slow'])
library;

import 'dart:io';

import 'package:codewalk/presentation/services/workspace_file_operations_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final baseUrl = Platform.environment['CODEWALK_LIVE_OPENCODE_URL'];
  final rootDirectory = Platform.environment['CODEWALK_LIVE_OPENCODE_ROOT'];

  test(
    'live OpenCode shell round-trips create write and delete',
    () async {
      final root = rootDirectory!;
      final service = WorkspaceFileOperationsServiceImpl(
        dio: Dio(BaseOptions(baseUrl: baseUrl!)),
      );
      final name =
          '.codewalk-live-${DateTime.now().microsecondsSinceEpoch}.txt';
      final content = List<String>.filled(64 * 1024, 'x').join();

      final capabilities = await service.getCapabilities(
        serverScopeKey: 'live-test',
        directory: root,
      );
      expect(
        capabilities.shellFileOpsSupported,
        isTrue,
        reason: capabilities.message,
      );

      final created = await service.createFile(
        serverScopeKey: 'live-test',
        rootDirectory: root,
        parentDirectory: root,
        name: name,
      );
      expect(created.ok, isTrue, reason: created.message);

      final written = await service.writeFile(
        serverScopeKey: 'live-test',
        rootDirectory: root,
        path: '$root/$name',
        content: content,
      );
      expect(written.ok, isTrue, reason: written.message);
      expect(File('$root/$name').readAsStringSync(), content);

      final deleted = await service.delete(
        serverScopeKey: 'live-test',
        rootDirectory: root,
        parentDirectory: root,
        name: name,
      );
      expect(deleted.ok, isTrue, reason: deleted.message);
    },
    skip: baseUrl == null || rootDirectory == null
        ? 'set CODEWALK_LIVE_OPENCODE_URL and CODEWALK_LIVE_OPENCODE_ROOT'
        : false,
  );
}
