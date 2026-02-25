import '../../core/utils/path_utils.dart';
import '../../domain/entities/file_node.dart';

FileNodeType _parseFileNodeType(String? raw) {
  final normalized = raw?.trim().toLowerCase() ?? '';
  switch (normalized) {
    case 'file':
      return FileNodeType.file;
    case 'directory':
    case 'dir':
    case 'folder':
      return FileNodeType.directory;
    default:
      return FileNodeType.unknown;
  }
}

String _coercePath(
  dynamic value, {
  required String parentPath,
  String? fallbackName,
}) {
  final raw = value is String ? value.trim() : '';
  if (raw.isNotEmpty) {
    final normalized = normalizeFilePath(raw);
    if (normalized.startsWith('/')) {
      return normalized;
    }
    // Some servers already return a rooted-relative path (eg: lib/main.dart).
    // In this case, avoid re-joining with parent to prevent duplicated segments.
    if (normalized.contains('/')) {
      return normalized;
    }
    final parent = normalizeFilePath(parentPath);
    return normalizeFilePath(joinParentPath(parent, normalized));
  }

  final safeFallbackName = fallbackName?.trim() ?? '';
  if (safeFallbackName.isEmpty) {
    return normalizeFilePath(parentPath);
  }
  final parent = normalizeFilePath(parentPath);
  return normalizeFilePath(joinParentPath(parent, safeFallbackName));
}

class FileNodeModel {

  factory FileNodeModel.fromJson(
    Map<String, dynamic> json, {
    required String parentPath,
  }) {
    final rawName = json['name'] as String?;
    final resolvedPath = _coercePath(
      json['absolute'] ?? json['path'] ?? json['file'] ?? json['id'],
      parentPath: parentPath,
      fallbackName: rawName,
    );
    final fallbackType =
        (json['children'] is List && (json['children'] as List).isNotEmpty)
        ? FileNodeType.directory
        : FileNodeType.unknown;
    final parsedType = _parseFileNodeType(json['type'] as String?);

    return FileNodeModel(
      path: resolvedPath,
      name: (rawName == null || rawName.trim().isEmpty)
          ? fileBasename(resolvedPath)
          : rawName.trim(),
      type: parsedType == FileNodeType.unknown ? fallbackType : parsedType,
    );
  }
  const FileNodeModel({
    required this.path,
    required this.name,
    required this.type,
  });

  final String path;
  final String name;
  final FileNodeType type;

  FileNode toDomain() => FileNode(path: path, name: name, type: type);
}
