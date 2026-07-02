import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/utils/path_utils.dart';
import 'chat_title_generator.dart';

enum WorkspaceFileOperationCode {
  ok,
  unavailable,
  invalidName,
  outsideRoot,
  rootDeleteBlocked,
  missing,
  alreadyExists,
  permissionDenied,
  notDirectory,
  failed,
  malformedResponse,
}

class WorkspaceFileOperationResult {
  const WorkspaceFileOperationResult({
    required this.ok,
    required this.code,
    required this.message,
    this.path,
    this.newPath,
  });

  final bool ok;
  final WorkspaceFileOperationCode code;
  final String message;
  final String? path;
  final String? newPath;

  WorkspaceFileOperationResult copyWith({String? path, String? newPath}) {
    return WorkspaceFileOperationResult(
      ok: ok,
      code: code,
      message: message,
      path: path ?? this.path,
      newPath: newPath ?? this.newPath,
    );
  }
}

class WorkspaceFileOperationsCapabilities {
  const WorkspaceFileOperationsCapabilities({
    required this.shellFileOpsSupported,
    required this.message,
  });

  final bool shellFileOpsSupported;
  final String message;
}

abstract class WorkspaceFileOperationsService {
  Future<WorkspaceFileOperationsCapabilities> getCapabilities({
    required String serverScopeKey,
    required String directory,
  });

  Future<void> invalidateCapabilities({
    required String serverScopeKey,
    required String directory,
  });

  Future<WorkspaceFileOperationResult> createFile({
    required String serverScopeKey,
    required String rootDirectory,
    required String parentDirectory,
    required String name,
  });

  Future<WorkspaceFileOperationResult> createFolder({
    required String serverScopeKey,
    required String rootDirectory,
    required String parentDirectory,
    required String name,
  });

  Future<WorkspaceFileOperationResult> rename({
    required String serverScopeKey,
    required String rootDirectory,
    required String parentDirectory,
    required String oldName,
    required String newName,
  });

  Future<WorkspaceFileOperationResult> delete({
    required String serverScopeKey,
    required String rootDirectory,
    required String parentDirectory,
    required String name,
  });
}

class WorkspaceFileOperationsServiceImpl
    implements WorkspaceFileOperationsService {
  WorkspaceFileOperationsServiceImpl({required Dio dio}) : _dio = dio;

  static const String _shellPrefix = 'CW_FILE_OP_JSON:';

  final Dio _dio;
  final Map<String, WorkspaceFileOperationsCapabilities> _capabilityCache =
      <String, WorkspaceFileOperationsCapabilities>{};

  @override
  Future<WorkspaceFileOperationsCapabilities> getCapabilities({
    required String serverScopeKey,
    required String directory,
  }) async {
    if (_isUnsafeRoot(directory)) {
      return const WorkspaceFileOperationsCapabilities(
        shellFileOpsSupported: false,
        message: 'File operations require an active project directory.',
      );
    }
    final key = _capabilityKey(serverScopeKey, directory);
    final cached = _capabilityCache[key];
    if (cached != null) {
      return cached;
    }

    final result = await _runShellScript(
      directory: normalizeFilePath(directory),
      command: _buildProbeCommand(),
    );
    final capabilities = WorkspaceFileOperationsCapabilities(
      shellFileOpsSupported: result.ok,
      message: result.message,
    );
    _capabilityCache[key] = capabilities;
    return capabilities;
  }

  @override
  Future<void> invalidateCapabilities({
    required String serverScopeKey,
    required String directory,
  }) async {
    _capabilityCache.remove(_capabilityKey(serverScopeKey, directory));
  }

  @override
  Future<WorkspaceFileOperationResult> createFile({
    required String serverScopeKey,
    required String rootDirectory,
    required String parentDirectory,
    required String name,
  }) async {
    final prepared = await _prepareLeafOperation(
      serverScopeKey: serverScopeKey,
      rootDirectory: rootDirectory,
      parentDirectory: parentDirectory,
      name: name,
    );
    if (prepared.result != null) {
      return prepared.result!;
    }

    final target = _joinPath(prepared.parentDirectory, prepared.name);
    return _runMutation(
      serverScopeKey: serverScopeKey,
      rootDirectory: prepared.rootDirectory,
      command: _buildCreateFileCommand(
        rootDirectory: prepared.rootDirectory,
        parentDirectory: prepared.parentDirectory,
        name: prepared.name,
      ),
      path: target,
    );
  }

  @override
  Future<WorkspaceFileOperationResult> createFolder({
    required String serverScopeKey,
    required String rootDirectory,
    required String parentDirectory,
    required String name,
  }) async {
    final prepared = await _prepareLeafOperation(
      serverScopeKey: serverScopeKey,
      rootDirectory: rootDirectory,
      parentDirectory: parentDirectory,
      name: name,
    );
    if (prepared.result != null) {
      return prepared.result!;
    }

    final target = _joinPath(prepared.parentDirectory, prepared.name);
    return _runMutation(
      serverScopeKey: serverScopeKey,
      rootDirectory: prepared.rootDirectory,
      command: _buildCreateFolderCommand(
        rootDirectory: prepared.rootDirectory,
        parentDirectory: prepared.parentDirectory,
        name: prepared.name,
      ),
      path: target,
    );
  }

  @override
  Future<WorkspaceFileOperationResult> rename({
    required String serverScopeKey,
    required String rootDirectory,
    required String parentDirectory,
    required String oldName,
    required String newName,
  }) async {
    final preparedOld = _normalizeLeafName(oldName);
    if (preparedOld.result != null) {
      return preparedOld.result!;
    }
    final preparedNew = _normalizeLeafName(newName);
    if (preparedNew.result != null) {
      return preparedNew.result!;
    }

    final root = normalizeFilePath(rootDirectory);
    final parent = normalizeFilePath(parentDirectory);
    final rootCheck = _validateRootParent(rootDirectory: root, parent: parent);
    if (rootCheck != null) {
      return rootCheck;
    }

    final source = _joinPath(parent, preparedOld.name);
    final destination = _joinPath(parent, preparedNew.name);
    if (normalizeFilePath(source) == normalizeFilePath(root)) {
      return _result(WorkspaceFileOperationCode.rootDeleteBlocked);
    }

    return _runMutation(
      serverScopeKey: serverScopeKey,
      rootDirectory: root,
      command: _buildRenameCommand(
        rootDirectory: root,
        parentDirectory: parent,
        oldName: preparedOld.name,
        newName: preparedNew.name,
      ),
      path: source,
      newPath: destination,
    );
  }

  @override
  Future<WorkspaceFileOperationResult> delete({
    required String serverScopeKey,
    required String rootDirectory,
    required String parentDirectory,
    required String name,
  }) async {
    final prepared = await _prepareLeafOperation(
      serverScopeKey: serverScopeKey,
      rootDirectory: rootDirectory,
      parentDirectory: parentDirectory,
      name: name,
      checkCapabilities: false,
    );
    if (prepared.result != null) {
      return prepared.result!;
    }

    final target = _joinPath(prepared.parentDirectory, prepared.name);
    if (normalizeFilePath(target) ==
        normalizeFilePath(prepared.rootDirectory)) {
      return _result(WorkspaceFileOperationCode.rootDeleteBlocked);
    }

    final capabilities = await getCapabilities(
      serverScopeKey: serverScopeKey,
      directory: prepared.rootDirectory,
    );
    if (!capabilities.shellFileOpsSupported) {
      return _result(
        WorkspaceFileOperationCode.unavailable,
        message: capabilities.message,
      );
    }

    return _runMutation(
      serverScopeKey: serverScopeKey,
      rootDirectory: prepared.rootDirectory,
      command: _buildDeleteCommand(
        rootDirectory: prepared.rootDirectory,
        parentDirectory: prepared.parentDirectory,
        name: prepared.name,
      ),
      path: target,
    );
  }

  Future<WorkspaceFileOperationResult> _runMutation({
    required String serverScopeKey,
    required String rootDirectory,
    required String command,
    String? path,
    String? newPath,
  }) async {
    final capabilities = await getCapabilities(
      serverScopeKey: serverScopeKey,
      directory: rootDirectory,
    );
    if (!capabilities.shellFileOpsSupported) {
      return _result(
        WorkspaceFileOperationCode.unavailable,
        message: capabilities.message,
      );
    }

    final result = await _runShellScript(
      directory: rootDirectory,
      command: command,
    );
    if (result.code == WorkspaceFileOperationCode.unavailable ||
        result.code == WorkspaceFileOperationCode.malformedResponse) {
      await invalidateCapabilities(
        serverScopeKey: serverScopeKey,
        directory: rootDirectory,
      );
    }
    return result.copyWith(path: path, newPath: newPath);
  }

  Future<_PreparedLeafOperation> _prepareLeafOperation({
    required String serverScopeKey,
    required String rootDirectory,
    required String parentDirectory,
    required String name,
    bool checkCapabilities = true,
  }) async {
    final preparedName = _normalizeLeafName(name);
    if (preparedName.result != null) {
      return _PreparedLeafOperation(result: preparedName.result!);
    }

    final root = normalizeFilePath(rootDirectory);
    final parent = normalizeFilePath(parentDirectory);
    final rootCheck = _validateRootParent(rootDirectory: root, parent: parent);
    if (rootCheck != null) {
      return _PreparedLeafOperation(result: rootCheck);
    }

    if (checkCapabilities) {
      final capabilities = await getCapabilities(
        serverScopeKey: serverScopeKey,
        directory: root,
      );
      if (!capabilities.shellFileOpsSupported) {
        return _PreparedLeafOperation(
          result: _result(
            WorkspaceFileOperationCode.unavailable,
            message: capabilities.message,
          ),
        );
      }
    }

    return _PreparedLeafOperation(
      rootDirectory: root,
      parentDirectory: parent,
      name: preparedName.name,
    );
  }

  _PreparedLeafName _normalizeLeafName(String raw) {
    final value = raw.trim();
    if (value.isEmpty ||
        value == '.' ||
        value == '..' ||
        value.contains('/') ||
        value.contains('\\') ||
        value.contains('\x00') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return _PreparedLeafName(
        result: _result(WorkspaceFileOperationCode.invalidName),
      );
    }
    return _PreparedLeafName(name: value);
  }

  WorkspaceFileOperationResult? _validateRootParent({
    required String rootDirectory,
    required String parent,
  }) {
    if (rootDirectory.isEmpty || parent.isEmpty) {
      return _result(WorkspaceFileOperationCode.missing);
    }
    if (_isUnsafeRoot(rootDirectory)) {
      return _result(WorkspaceFileOperationCode.outsideRoot);
    }
    if (!_isPathUnderRoot(rootDirectory, parent)) {
      return _result(WorkspaceFileOperationCode.outsideRoot);
    }
    return null;
  }

  bool _isPathUnderRoot(String rootDirectory, String candidate) {
    final root = normalizeFilePath(rootDirectory);
    final value = normalizeFilePath(candidate);
    return value == root || value.startsWith('$root/');
  }

  bool _isUnsafeRoot(String directory) {
    final normalized = normalizeFilePath(directory);
    return normalized.isEmpty || normalized == '/';
  }

  String _joinPath(String parent, String name) {
    final normalizedParent = normalizeFilePath(parent);
    if (normalizedParent == '/') {
      return '/$name';
    }
    return normalizeFilePath(joinParentPath(normalizedParent, name));
  }

  Future<WorkspaceFileOperationResult> _runShellScript({
    required String directory,
    required String command,
  }) async {
    String? sessionId;
    try {
      sessionId = await _createEphemeralSession();
      if (sessionId == null) {
        return _result(WorkspaceFileOperationCode.unavailable);
      }

      final response = await _dio.post<dynamic>(
        '/session/$sessionId/shell',
        data: <String, dynamic>{'agent': 'build', 'command': command},
        queryParameters: <String, String>{'directory': directory},
      );
      if (response.statusCode != 200 || response.data is! Map) {
        return _result(WorkspaceFileOperationCode.failed);
      }
      final payload = extractSentinelPayload(
        Map<String, dynamic>.from(response.data as Map),
      );
      if (payload == null) {
        return _result(WorkspaceFileOperationCode.malformedResponse);
      }
      return parseSentinelPayload(payload);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return _result(WorkspaceFileOperationCode.unavailable);
      }
      return _result(WorkspaceFileOperationCode.failed);
    } catch (_) {
      return _result(WorkspaceFileOperationCode.failed);
    } finally {
      if (sessionId != null) {
        try {
          await _dio.delete<dynamic>('/session/$sessionId');
        } catch (_) {}
        final ephemeralId = sessionId;
        Future<void>.delayed(const Duration(seconds: 5), () {
          ChatTitleGenerator.ephemeralSessionIds.remove(ephemeralId);
        });
      }
    }
  }

  Future<String?> _createEphemeralSession() async {
    final response = await _dio.post<dynamic>(
      '/session',
      data: <String, dynamic>{
        'title': ChatTitleGenerator.ephemeralSessionTitle,
      },
    );
    final data = response.data;
    if (data is! Map) {
      return null;
    }
    final sessionId = data['id'] as String?;
    if (sessionId == null || sessionId.trim().isEmpty) {
      return null;
    }
    ChatTitleGenerator.ephemeralSessionIds.add(sessionId);
    return sessionId;
  }

  String _capabilityKey(String serverScopeKey, String directory) {
    return '$serverScopeKey::${normalizeFilePath(directory)}';
  }

  @visibleForTesting
  static String? extractSentinelPayload(Map<String, dynamic> envelope) {
    return _searchStringValues(envelope);
  }

  static String? _searchStringValues(dynamic data) {
    if (data is String && data.trim().isNotEmpty) {
      for (final line in data.split('\n').reversed) {
        final trimmed = line.trim();
        if (trimmed.startsWith(_shellPrefix)) {
          return trimmed.substring(_shellPrefix.length);
        }
      }
      return null;
    }
    if (data is Map) {
      for (final value in data.values) {
        final found = _searchStringValues(value);
        if (found != null) {
          return found;
        }
      }
      return null;
    }
    if (data is List) {
      for (final value in data) {
        final found = _searchStringValues(value);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }

  @visibleForTesting
  static WorkspaceFileOperationResult parseSentinelPayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) {
        return _result(WorkspaceFileOperationCode.malformedResponse);
      }
      final map = Map<String, dynamic>.from(decoded);
      final code = _codeFromWire(map['code'] as String?);
      if (code == null) {
        return _result(WorkspaceFileOperationCode.malformedResponse);
      }
      final ok = map['ok'] == true && code == WorkspaceFileOperationCode.ok;
      final message = map['message'] as String? ?? _defaultMessage(code);
      return WorkspaceFileOperationResult(
        ok: ok,
        code: code,
        message: message,
        path: map['path'] as String?,
        newPath: map['newPath'] as String?,
      );
    } catch (_) {
      return _result(WorkspaceFileOperationCode.malformedResponse);
    }
  }

  static WorkspaceFileOperationCode? _codeFromWire(String? raw) {
    switch (raw) {
      case 'ok':
        return WorkspaceFileOperationCode.ok;
      case 'unavailable':
        return WorkspaceFileOperationCode.unavailable;
      case 'invalidName':
        return WorkspaceFileOperationCode.invalidName;
      case 'outsideRoot':
        return WorkspaceFileOperationCode.outsideRoot;
      case 'rootDeleteBlocked':
        return WorkspaceFileOperationCode.rootDeleteBlocked;
      case 'missing':
        return WorkspaceFileOperationCode.missing;
      case 'alreadyExists':
        return WorkspaceFileOperationCode.alreadyExists;
      case 'permissionDenied':
        return WorkspaceFileOperationCode.permissionDenied;
      case 'notDirectory':
        return WorkspaceFileOperationCode.notDirectory;
      case 'failed':
        return WorkspaceFileOperationCode.failed;
      case 'malformedResponse':
        return WorkspaceFileOperationCode.malformedResponse;
    }
    return null;
  }

  static WorkspaceFileOperationResult _result(
    WorkspaceFileOperationCode code, {
    String? message,
  }) {
    return WorkspaceFileOperationResult(
      ok: code == WorkspaceFileOperationCode.ok,
      code: code,
      message: message ?? _defaultMessage(code),
    );
  }

  static String _defaultMessage(WorkspaceFileOperationCode code) {
    switch (code) {
      case WorkspaceFileOperationCode.ok:
        return 'ok';
      case WorkspaceFileOperationCode.unavailable:
        return 'File operations are not available for this server.';
      case WorkspaceFileOperationCode.invalidName:
        return 'Invalid name.';
      case WorkspaceFileOperationCode.outsideRoot:
        return 'Path is outside the project root.';
      case WorkspaceFileOperationCode.rootDeleteBlocked:
        return 'The project root cannot be deleted.';
      case WorkspaceFileOperationCode.missing:
        return 'Path does not exist.';
      case WorkspaceFileOperationCode.alreadyExists:
        return 'A file or folder with that name already exists.';
      case WorkspaceFileOperationCode.permissionDenied:
        return 'Permission denied.';
      case WorkspaceFileOperationCode.notDirectory:
        return 'Parent is not a directory.';
      case WorkspaceFileOperationCode.failed:
        return 'File operation failed.';
      case WorkspaceFileOperationCode.malformedResponse:
        return 'File operation returned an invalid response.';
    }
  }

  @visibleForTesting
  static String buildProbeCommandForTest() => _buildProbeCommand();

  static String _buildProbeCommand() {
    return "root=\$(pwd -P 2>/dev/null || printf /); if [ \"\$root\" = / ]; then printf '%s\\n' '$_shellPrefix{\"ok\":false,\"code\":\"outsideRoot\",\"message\":\"Path is outside the project root.\"}'; else printf '%s\\n' '$_shellPrefix{\"ok\":true,\"code\":\"ok\",\"message\":\"shell file operations available\"}'; fi";
  }

  @visibleForTesting
  static String shellQuoteForTest(String value) => _shQuote(value);

  static String _shQuote(String value) {
    return "'${value.replaceAll("'", "'\\''")}'";
  }

  String _buildCreateFileCommand({
    required String rootDirectory,
    required String parentDirectory,
    required String name,
  }) {
    return _buildScript(
      rootDirectory: rootDirectory,
      parentDirectory: parentDirectory,
      name: name,
      body: r'''
cw_validate_name "$CW_NAME"
cw_prepare_parent
target="$parent/$CW_NAME"
if [ -e "$target" ] || [ -L "$target" ]; then cw_fail alreadyExists; fi
if ! [ -w "$parent" ]; then cw_fail permissionDenied; fi
if : > "$target" 2>/dev/null; then cw_ok; fi
cw_fail failed
''',
    );
  }

  String _buildCreateFolderCommand({
    required String rootDirectory,
    required String parentDirectory,
    required String name,
  }) {
    return _buildScript(
      rootDirectory: rootDirectory,
      parentDirectory: parentDirectory,
      name: name,
      body: r'''
cw_validate_name "$CW_NAME"
cw_prepare_parent
target="$parent/$CW_NAME"
if [ -e "$target" ] || [ -L "$target" ]; then cw_fail alreadyExists; fi
if ! [ -w "$parent" ]; then cw_fail permissionDenied; fi
if mkdir -- "$target" 2>/dev/null; then cw_ok; fi
cw_fail failed
''',
    );
  }

  String _buildRenameCommand({
    required String rootDirectory,
    required String parentDirectory,
    required String oldName,
    required String newName,
  }) {
    return _buildScript(
      rootDirectory: rootDirectory,
      parentDirectory: parentDirectory,
      name: oldName,
      newName: newName,
      body: r'''
cw_validate_name "$CW_NAME"
cw_validate_name "$CW_NEW_NAME"
cw_prepare_parent
source="$parent/$CW_NAME"
destination="$parent/$CW_NEW_NAME"
if [ "$source" = "$root" ]; then cw_fail rootDeleteBlocked; fi
if ! [ -e "$source" ] && ! [ -L "$source" ]; then cw_fail missing; fi
if [ -e "$destination" ] || [ -L "$destination" ]; then cw_fail alreadyExists; fi
if ! [ -w "$parent" ]; then cw_fail permissionDenied; fi
if mv -- "$source" "$destination" 2>/dev/null; then cw_ok; fi
cw_fail failed
''',
    );
  }

  String _buildDeleteCommand({
    required String rootDirectory,
    required String parentDirectory,
    required String name,
  }) {
    return _buildScript(
      rootDirectory: rootDirectory,
      parentDirectory: parentDirectory,
      name: name,
      body: r'''
cw_validate_name "$CW_NAME"
cw_prepare_parent
target="$parent/$CW_NAME"
if [ "$target" = "$root" ]; then cw_fail rootDeleteBlocked; fi
if ! [ -e "$target" ] && ! [ -L "$target" ]; then cw_fail missing; fi
if ! [ -w "$parent" ]; then cw_fail permissionDenied; fi
if [ -d "$target" ] && ! [ -L "$target" ]; then
  if rm -r -- "$target" 2>/dev/null; then cw_ok; fi
else
  if rm -- "$target" 2>/dev/null; then cw_ok; fi
fi
cw_fail failed
''',
    );
  }

  String _buildScript({
    required String rootDirectory,
    required String parentDirectory,
    required String name,
    required String body,
    String? newName,
  }) {
    final buffer = StringBuffer()
      ..writeln('set -u')
      ..writeln('CW_ROOT_INPUT=${_shQuote(rootDirectory)}')
      ..writeln('CW_PARENT_INPUT=${_shQuote(parentDirectory)}')
      ..writeln('CW_NAME=${_shQuote(name)}');
    if (newName != null) {
      buffer.writeln('CW_NEW_NAME=${_shQuote(newName)}');
    }
    buffer
      ..write(_shellHelpers())
      ..writeln(body.trim());
    return buffer.toString();
  }

  String _shellHelpers() {
    return r'''
cw_emit() { printf '%s\n' "CW_FILE_OP_JSON:$1"; }
cw_ok() { cw_emit '{"ok":true,"code":"ok","message":"ok"}'; exit 0; }
cw_fail() {
  case "$1" in
    invalidName) cw_emit '{"ok":false,"code":"invalidName","message":"Invalid name."}' ;;
    outsideRoot) cw_emit '{"ok":false,"code":"outsideRoot","message":"Path is outside the project root."}' ;;
    rootDeleteBlocked) cw_emit '{"ok":false,"code":"rootDeleteBlocked","message":"The project root cannot be deleted."}' ;;
    missing) cw_emit '{"ok":false,"code":"missing","message":"Path does not exist."}' ;;
    alreadyExists) cw_emit '{"ok":false,"code":"alreadyExists","message":"A file or folder with that name already exists."}' ;;
    permissionDenied) cw_emit '{"ok":false,"code":"permissionDenied","message":"Permission denied."}' ;;
    notDirectory) cw_emit '{"ok":false,"code":"notDirectory","message":"Parent is not a directory."}' ;;
    *) cw_emit '{"ok":false,"code":"failed","message":"File operation failed."}' ;;
  esac
  exit 0
}
cw_validate_name() {
  case "$1" in
    ''|'.'|'..'|*/*|*\\*) cw_fail invalidName ;;
  esac
}
cw_prepare_parent() {
  root=$(cd -- "$CW_ROOT_INPUT" 2>/dev/null && pwd -P) || cw_fail missing
  if [ "$root" = "/" ]; then cw_fail outsideRoot; fi
  parent=$(cd -- "$CW_PARENT_INPUT" 2>/dev/null && pwd -P) || cw_fail missing
  if ! [ -d "$parent" ]; then cw_fail notDirectory; fi
  case "$parent" in
    "$root"|"$root"/*) ;;
    *) cw_fail outsideRoot ;;
  esac
}
''';
  }
}

class _PreparedLeafName {
  const _PreparedLeafName({this.name = '', this.result});

  final String name;
  final WorkspaceFileOperationResult? result;
}

class _PreparedLeafOperation {
  const _PreparedLeafOperation({
    this.rootDirectory = '',
    this.parentDirectory = '',
    this.name = '',
    this.result,
  });

  final String rootDirectory;
  final String parentDirectory;
  final String name;
  final WorkspaceFileOperationResult? result;
}
