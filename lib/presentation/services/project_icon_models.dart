import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../core/utils/path_utils.dart';
import '../../domain/entities/project.dart';

const int projectIconMaxBytes = 5 * 1024 * 1024;

enum ProjectIconFormat { png, jpeg, svg, webp, ico }

extension ProjectIconFormatX on ProjectIconFormat {
  String get extension {
    return switch (this) {
      ProjectIconFormat.png => 'png',
      ProjectIconFormat.jpeg => 'jpg',
      ProjectIconFormat.svg => 'svg',
      ProjectIconFormat.webp => 'webp',
      ProjectIconFormat.ico => 'ico',
    };
  }

  String get storageExtension {
    return this == ProjectIconFormat.ico ? 'png' : extension;
  }

  static ProjectIconFormat? fromExtension(String value) {
    return switch (value.trim().toLowerCase()) {
      'png' => ProjectIconFormat.png,
      'jpg' || 'jpeg' => ProjectIconFormat.jpeg,
      'svg' => ProjectIconFormat.svg,
      'webp' => ProjectIconFormat.webp,
      'ico' => ProjectIconFormat.ico,
      _ => null,
    };
  }

  static ProjectIconFormat? fromName(String fileName) {
    final normalized = fileName.trim().toLowerCase();
    final separator = normalized.lastIndexOf('.');
    if (separator < 0 || separator == normalized.length - 1) {
      return null;
    }
    return fromExtension(normalized.substring(separator + 1));
  }
}

class ProjectIconMetadata {
  const ProjectIconMetadata({
    required this.key,
    required this.projectId,
    required this.projectPath,
    required this.sourcePath,
    required this.storedPath,
    required this.sourceFormat,
    required this.storedFormat,
    required this.sourceByteLength,
    required this.storedByteLength,
    required this.updatedAt,
  });

  factory ProjectIconMetadata.fromJson(Map<String, dynamic> json) {
    final sourceFormat = ProjectIconFormatX.fromExtension(
      json['sourceFormat']?.toString() ?? '',
    );
    final storedFormat = ProjectIconFormatX.fromExtension(
      json['storedFormat']?.toString() ?? '',
    );
    if (sourceFormat == null || storedFormat == null) {
      throw const FormatException('Invalid project icon format');
    }
    return ProjectIconMetadata(
      key: json['key']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      projectPath: json['projectPath']?.toString() ?? '',
      sourcePath: json['sourcePath']?.toString() ?? '',
      storedPath: json['storedPath']?.toString() ?? '',
      sourceFormat: sourceFormat,
      storedFormat: storedFormat,
      sourceByteLength: (json['sourceByteLength'] as num?)?.toInt() ?? 0,
      storedByteLength: (json['storedByteLength'] as num?)?.toInt() ?? 0,
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String key;
  final String projectId;
  final String projectPath;
  final String sourcePath;
  final String storedPath;
  final ProjectIconFormat sourceFormat;
  final ProjectIconFormat storedFormat;
  final int sourceByteLength;
  final int storedByteLength;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'key': key,
      'projectId': projectId,
      'projectPath': projectPath,
      'sourcePath': sourcePath,
      'storedPath': storedPath,
      'sourceFormat': sourceFormat.extension,
      'storedFormat': storedFormat.extension,
      'sourceByteLength': sourceByteLength,
      'storedByteLength': storedByteLength,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ProjectIconData {
  const ProjectIconData({required this.metadata, required this.bytes});

  final ProjectIconMetadata metadata;
  final Uint8List bytes;
}

class ProjectIconCandidate {
  const ProjectIconCandidate({
    required this.sourcePath,
    required this.bytes,
    required this.sourceFormat,
    required this.storedFormat,
    required this.sourceByteLength,
  });

  final String sourcePath;
  final Uint8List bytes;
  final ProjectIconFormat sourceFormat;
  final ProjectIconFormat storedFormat;
  final int sourceByteLength;
}

enum ProjectIconDiscoveryStatus {
  found,
  notFound,
  unsupported,
  oversized,
  unsupportedPlatform,
  error,
}

class ProjectIconDiscoveryResult {
  const ProjectIconDiscoveryResult({
    required this.status,
    this.candidate,
    this.message,
  });

  const ProjectIconDiscoveryResult.found(ProjectIconCandidate candidate)
    : this(status: ProjectIconDiscoveryStatus.found, candidate: candidate);

  final ProjectIconDiscoveryStatus status;
  final ProjectIconCandidate? candidate;
  final String? message;

  bool get found => status == ProjectIconDiscoveryStatus.found;
}

String projectIconKeyFor(Project project) {
  return projectIconKey(projectId: project.id, projectPath: project.path);
}

String projectIconKey({
  required String projectId,
  required String projectPath,
}) {
  final normalizedPath = normalizeFilePath(projectPath);
  return sha256
      .convert(utf8.encode('${projectId.trim()}\n$normalizedPath'))
      .toString();
}
