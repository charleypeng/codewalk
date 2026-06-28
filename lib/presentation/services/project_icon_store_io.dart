import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/entities/project.dart';
import 'project_icon_models.dart';
import 'project_icon_store_base.dart';

ProjectIconStore createProjectIconStore() => ProjectIconStoreIo();

class ProjectIconStoreIo implements ProjectIconStore {
  ProjectIconStoreIo({Directory? rootDirectory})
    : _rootOverride = rootDirectory;

  final Directory? _rootOverride;
  Future<void> _metadataQueue = Future<void>.value();

  Future<T> _withMetadataQueue<T>(Future<T> Function() action) {
    final previous = _metadataQueue;
    final next = previous.then((_) => Future<T>.sync(action));
    _metadataQueue = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.warn(
          'Project icon metadata queue operation failed',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
    return next;
  }

  Future<Directory> _rootDirectory() async {
    final root =
        _rootOverride ??
        Directory(
          '${(await getApplicationSupportDirectory()).path}/project_icons',
        );
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    return root;
  }

  Future<File> _metadataFile() async {
    final root = await _rootDirectory();
    return File('${root.path}/metadata.json');
  }

  Future<Map<String, ProjectIconMetadata>> _readMetadataMap() async {
    final file = await _metadataFile();
    if (!await file.exists()) {
      return <String, ProjectIconMetadata>{};
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        return <String, ProjectIconMetadata>{};
      }
      final result = <String, ProjectIconMetadata>{};
      for (final entry in decoded.entries) {
        if (entry.value is Map) {
          final metadata = ProjectIconMetadata.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
          if (metadata.key.isNotEmpty) {
            result[entry.key.toString()] = metadata;
          }
        }
      }
      return result;
    } catch (error) {
      AppLogger.warn('Project icon metadata read failed', error: error);
      return <String, ProjectIconMetadata>{};
    }
  }

  Future<void> _writeMetadataMap(
    Map<String, ProjectIconMetadata> metadata,
  ) async {
    final file = await _metadataFile();
    final encoded = jsonEncode(
      metadata.map(
        (key, value) => MapEntry<String, dynamic>(key, value.toJson()),
      ),
    );
    await file.writeAsString(encoded);
  }

  @override
  Future<ProjectIconData?> readIcon(String key) async {
    final metadata = await _withMetadataQueue(() async {
      return (await _readMetadataMap())[key];
    });
    if (metadata == null || metadata.storedPath.trim().isEmpty) {
      return null;
    }
    final file = File(metadata.storedPath);
    if (!await file.exists()) {
      await deleteIcon(key);
      return null;
    }
    try {
      return ProjectIconData(
        metadata: metadata,
        bytes: await file.readAsBytes(),
      );
    } catch (error) {
      AppLogger.warn('Project icon read failed key=$key', error: error);
      return null;
    }
  }

  @override
  Future<ProjectIconData> saveIcon({
    required Project project,
    required String key,
    required ProjectIconCandidate candidate,
  }) async {
    final root = await _rootDirectory();
    return _withMetadataQueue(() async {
      final metadata = await _readMetadataMap();
      final previous = metadata[key];
      final storedPath =
          '${root.path}/$key.${candidate.storedFormat.storageExtension}';
      await File(storedPath).writeAsBytes(candidate.bytes, flush: true);
      if (previous != null && previous.storedPath != storedPath) {
        await _deleteFileIfExists(previous.storedPath);
      }
      final next = ProjectIconMetadata(
        key: key,
        projectId: project.id,
        projectPath: project.path,
        sourcePath: candidate.sourcePath,
        storedPath: storedPath,
        sourceFormat: candidate.sourceFormat,
        storedFormat: candidate.storedFormat,
        sourceByteLength: candidate.sourceByteLength,
        storedByteLength: candidate.bytes.length,
        updatedAt: DateTime.now(),
      );
      metadata[key] = next;
      await _writeMetadataMap(metadata);
      return ProjectIconData(metadata: next, bytes: candidate.bytes);
    });
  }

  @override
  Future<void> deleteIcon(String key) async {
    await _withMetadataQueue(() async {
      final metadata = await _readMetadataMap();
      final removed = metadata.remove(key);
      if (removed != null) {
        await _deleteFileIfExists(removed.storedPath);
        await _writeMetadataMap(metadata);
      }
    });
  }

  Future<void> _deleteFileIfExists(String path) async {
    if (path.trim().isEmpty) {
      return;
    }
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
