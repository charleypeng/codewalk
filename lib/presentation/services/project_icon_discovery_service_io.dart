import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../core/utils/path_utils.dart';
import '../../domain/entities/project.dart';
import 'project_icon_discovery_service_base.dart';
import 'project_icon_models.dart';

ProjectIconDiscoveryService createProjectIconDiscoveryService() =>
    const ProjectIconDiscoveryServiceIo();

class ProjectIconDiscoveryServiceIo implements ProjectIconDiscoveryService {
  const ProjectIconDiscoveryServiceIo();

  @override
  bool get isSupported => true;

  @override
  Future<ProjectIconDiscoveryResult> discover(Project project) async {
    final path = normalizeOptionalFilePath(project.path);
    if (path == null) {
      return const ProjectIconDiscoveryResult(
        status: ProjectIconDiscoveryStatus.notFound,
        message: 'Project path is empty.',
      );
    }
    return compute(_discoverProjectIcon, <String, Object?>{'path': path});
  }
}

class _DirectoryToVisit {
  const _DirectoryToVisit(this.path, this.depth);

  final String path;
  final int depth;
}

class _IconMatch {
  const _IconMatch({
    required this.path,
    required this.relativePath,
    required this.format,
    required this.length,
  });

  final String path;
  final String relativePath;
  final ProjectIconFormat format;
  final int length;
}

Future<ProjectIconDiscoveryResult> _discoverProjectIcon(
  Map<String, Object?> request,
) async {
  final rootPath = request['path']?.toString() ?? '';
  final root = Directory(rootPath);
  if (!await root.exists()) {
    return ProjectIconDiscoveryResult(
      status: ProjectIconDiscoveryStatus.notFound,
      message: 'Directory does not exist: $rootPath',
    );
  }

  var sawUnsupported = false;
  var sawOversized = false;
  var visited = 0;
  final matches = <_IconMatch>[];
  final queue = Queue<_DirectoryToVisit>()
    ..add(_DirectoryToVisit(root.path, 0));

  while (queue.isNotEmpty && visited < 5000) {
    final current = queue.removeFirst();
    if (current.depth > 8) {
      continue;
    }
    late final List<FileSystemEntity> entries;
    try {
      entries = await Directory(current.path).list(followLinks: false).toList();
    } catch (_) {
      continue;
    }
    entries.sort(
      (left, right) =>
          left.path.toLowerCase().compareTo(right.path.toLowerCase()),
    );
    for (final entry in entries) {
      visited += 1;
      if (visited > 5000) {
        break;
      }
      final name = fileBasename(entry.path);
      if (entry is Directory) {
        if (!_shouldSkipDirectory(entry.path)) {
          queue.add(_DirectoryToVisit(entry.path, current.depth + 1));
        }
        continue;
      }
      if (entry is! File || !_isFaviconName(name)) {
        continue;
      }
      final format = ProjectIconFormatX.fromName(name);
      if (format == null) {
        sawUnsupported = true;
        continue;
      }
      late final int length;
      try {
        length = await entry.length();
      } catch (_) {
        continue;
      }
      if (length <= 0) {
        continue;
      }
      if (length > projectIconMaxBytes) {
        sawOversized = true;
        continue;
      }
      matches.add(
        _IconMatch(
          path: entry.path,
          relativePath: _relativePath(root.path, entry.path),
          format: format,
          length: length,
        ),
      );
    }
  }

  if (matches.isEmpty) {
    if (sawOversized) {
      return const ProjectIconDiscoveryResult(
        status: ProjectIconDiscoveryStatus.oversized,
        message: 'Only oversized favicon files were found.',
      );
    }
    if (sawUnsupported) {
      return const ProjectIconDiscoveryResult(
        status: ProjectIconDiscoveryStatus.unsupported,
        message: 'Only unsupported favicon formats were found.',
      );
    }
    return const ProjectIconDiscoveryResult(
      status: ProjectIconDiscoveryStatus.notFound,
      message: 'No favicon file found.',
    );
  }

  matches.sort((left, right) {
    final byRelativeLength = left.relativePath.length.compareTo(
      right.relativePath.length,
    );
    if (byRelativeLength != 0) {
      return byRelativeLength;
    }
    return left.relativePath.toLowerCase().compareTo(
      right.relativePath.toLowerCase(),
    );
  });
  final chosen = matches.first;
  try {
    final sourceBytes = await File(chosen.path).readAsBytes();
    final candidate = _candidateFromSource(
      path: chosen.path,
      sourceBytes: sourceBytes,
      sourceFormat: chosen.format,
      sourceByteLength: chosen.length,
    );
    if (candidate == null) {
      return ProjectIconDiscoveryResult(
        status: ProjectIconDiscoveryStatus.error,
        message: 'Could not decode project icon: ${chosen.path}',
      );
    }
    if (candidate.bytes.length > projectIconMaxBytes) {
      return const ProjectIconDiscoveryResult(
        status: ProjectIconDiscoveryStatus.oversized,
        message: 'Decoded project icon exceeds the size limit.',
      );
    }
    return ProjectIconDiscoveryResult.found(candidate);
  } catch (error) {
    return ProjectIconDiscoveryResult(
      status: ProjectIconDiscoveryStatus.error,
      message: 'Could not read project icon: $error',
    );
  }
}

ProjectIconCandidate? _candidateFromSource({
  required String path,
  required Uint8List sourceBytes,
  required ProjectIconFormat sourceFormat,
  required int sourceByteLength,
}) {
  if (sourceFormat == ProjectIconFormat.ico) {
    final decoded = img.decodeIco(sourceBytes);
    if (decoded == null) {
      return null;
    }
    return ProjectIconCandidate(
      sourcePath: path,
      bytes: Uint8List.fromList(img.encodePng(decoded)),
      sourceFormat: ProjectIconFormat.ico,
      storedFormat: ProjectIconFormat.png,
      sourceByteLength: sourceByteLength,
    );
  }
  return ProjectIconCandidate(
    sourcePath: path,
    bytes: sourceBytes,
    sourceFormat: sourceFormat,
    storedFormat: sourceFormat,
    sourceByteLength: sourceByteLength,
  );
}

bool _isFaviconName(String name) {
  final normalized = name.trim().toLowerCase();
  if (!normalized.startsWith('favicon.')) {
    return false;
  }
  return normalized.indexOf('.', 'favicon.'.length) == -1;
}

bool _shouldSkipDirectory(String path) {
  final name = fileBasename(path).trim().toLowerCase();
  const skip = <String>{
    '.git',
    'node_modules',
    'dist',
    'build',
    '.dart_tool',
    '.gradle',
    '.next',
    '.turbo',
    '.cache',
    'coverage',
    'tmp',
    'logs',
    'pods',
    'ephemeral',
  };
  return skip.contains(name);
}

String _relativePath(String rootPath, String filePath) {
  final root = normalizeFilePath(rootPath);
  final file = normalizeFilePath(filePath);
  return file.startsWith('$root/') ? file.substring(root.length + 1) : file;
}
