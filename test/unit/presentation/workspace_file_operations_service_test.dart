import 'package:codewalk/presentation/services/chat_title_generator.dart';
import 'package:codewalk/presentation/services/workspace_file_operations_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(ChatTitleGenerator.ephemeralSessionIds.clear);

  group('WorkspaceFileOperationsServiceImpl', () {
    test('extracts the last sentinel payload from nested shell parts', () {
      final payload = WorkspaceFileOperationsServiceImpl.extractSentinelPayload(
        <String, dynamic>{
          'parts': <dynamic>[
            <String, dynamic>{'text': 'noise'},
            <String, dynamic>{
              'state': <String, dynamic>{
                'output': 'first\nCW_FILE_OP_JSON:{"ok":true,"code":"ok"}',
              },
            },
          ],
        },
      );

      expect(payload, '{"ok":true,"code":"ok"}');
    });

    test('parses malformed sentinel payloads as malformed responses', () {
      final result = WorkspaceFileOperationsServiceImpl.parseSentinelPayload(
        '{not json',
      );

      expect(result.ok, isFalse);
      expect(result.code, WorkspaceFileOperationCode.malformedResponse);
    });

    test('quotes shell values containing spaces and single quotes', () {
      final quoted = WorkspaceFileOperationsServiceImpl.shellQuoteForTest(
        "folder/John's notes",
      );

      expect(quoted, "'folder/John'\\''s notes'");
    });

    test('probes capabilities once and caches the result', () async {
      final fakeServer = _FakeShellServer(
        shellPayloads: <String>[
          '{"ok":true,"code":"ok","message":"available"}',
        ],
      );
      final service = WorkspaceFileOperationsServiceImpl(dio: fakeServer.dio);

      final first = await service.getCapabilities(
        serverScopeKey: 'srv',
        directory: '/repo/a',
      );
      final second = await service.getCapabilities(
        serverScopeKey: 'srv',
        directory: '/repo/a',
      );

      expect(first.shellFileOpsSupported, isTrue);
      expect(second.shellFileOpsSupported, isTrue);
      expect(fakeServer.shellCallCount, 1);
      expect(fakeServer.deletedSessions, <String>['ses_1']);
    });

    test('invalid names fail before any shell call', () async {
      final fakeServer = _FakeShellServer(shellPayloads: const <String>[]);
      final service = WorkspaceFileOperationsServiceImpl(dio: fakeServer.dio);

      final result = await service.createFile(
        serverScopeKey: 'srv',
        rootDirectory: '/repo/a',
        parentDirectory: '/repo/a',
        name: '../bad.dart',
      );

      expect(result.ok, isFalse);
      expect(result.code, WorkspaceFileOperationCode.invalidName);
      expect(fakeServer.shellCallCount, 0);
    });

    test('root directory keeps shell file operations unsupported', () async {
      final fakeServer = _FakeShellServer(shellPayloads: const <String>[]);
      final service = WorkspaceFileOperationsServiceImpl(dio: fakeServer.dio);

      final capabilities = await service.getCapabilities(
        serverScopeKey: 'srv',
        directory: '/',
      );
      final result = await service.createFile(
        serverScopeKey: 'srv',
        rootDirectory: '/',
        parentDirectory: '/',
        name: 'unsafe.txt',
      );

      expect(capabilities.shellFileOpsSupported, isFalse);
      expect(result.ok, isFalse);
      expect(result.code, WorkspaceFileOperationCode.outsideRoot);
      expect(fakeServer.shellCallCount, 0);
    });

    test(
      'create file uses probe then operation and returns target path',
      () async {
        final fakeServer = _FakeShellServer(
          shellPayloads: <String>[
            '{"ok":true,"code":"ok","message":"available"}',
            '{"ok":true,"code":"ok","message":"ok"}',
          ],
        );
        final service = WorkspaceFileOperationsServiceImpl(dio: fakeServer.dio);

        final result = await service.createFile(
          serverScopeKey: 'srv',
          rootDirectory: '/repo/a',
          parentDirectory: '/repo/a/lib',
          name: "John's notes.dart",
        );

        expect(result.ok, isTrue);
        expect(result.path, "/repo/a/lib/John's notes.dart");
        expect(fakeServer.shellCallCount, 2);
        expect(
          fakeServer.commands.last,
          contains("CW_NAME='John'\\''s notes.dart'"),
        );
      },
    );

    test('malformed probe disables shell file operations', () async {
      final fakeServer = _FakeShellServer(shellPayloads: const <String?>[null]);
      final service = WorkspaceFileOperationsServiceImpl(dio: fakeServer.dio);

      final capabilities = await service.getCapabilities(
        serverScopeKey: 'srv',
        directory: '/repo/a',
      );

      expect(capabilities.shellFileOpsSupported, isFalse);
      expect(fakeServer.shellCallCount, 1);
    });
  });
}

class _FakeShellServer {
  _FakeShellServer({required List<String?> shellPayloads})
    : _shellPayloads = List<String?>.from(shellPayloads) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final path = options.path;
          if (options.method == 'POST' && path == '/session') {
            final id = 'ses_${createdSessions.length + 1}';
            createdSessions.add(id);
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{'id': id},
              ),
            );
            return;
          }

          if (options.method == 'POST' && path.endsWith('/shell')) {
            shellCallCount += 1;
            final data = Map<String, dynamic>.from(options.data as Map);
            commands.add(data['command'] as String? ?? '');
            final payload = _shellPayloads.isEmpty
                ? null
                : _shellPayloads.removeAt(0);
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'parts': <dynamic>[
                    if (payload != null)
                      <String, dynamic>{'text': 'CW_FILE_OP_JSON:$payload'},
                  ],
                },
              ),
            );
            return;
          }

          if (options.method == 'DELETE' && path.startsWith('/session/')) {
            deletedSessions.add(path.substring('/session/'.length));
            handler.resolve(
              Response<dynamic>(requestOptions: options, statusCode: 200),
            );
            return;
          }

          handler.reject(
            DioException(
              requestOptions: options,
              error: 'Unexpected request: ${options.method} $path',
            ),
          );
        },
      ),
    );
  }

  final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
  final List<String?> _shellPayloads;
  final List<String> createdSessions = <String>[];
  final List<String> deletedSessions = <String>[];
  final List<String> commands = <String>[];
  int shellCallCount = 0;
}
