import '../../domain/entities/file_node.dart';

class WorkspaceSymbolModel {
  const WorkspaceSymbolModel({
    required this.name,
    required this.path,
    this.kind,
  });

  factory WorkspaceSymbolModel.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    final locationMap = location is Map
        ? Map<String, dynamic>.from(location)
        : null;
    final rawUri =
        '${locationMap?['uri'] ?? json['uri'] ?? json['path'] ?? ''}';
    return WorkspaceSymbolModel(
      name: '${json['name'] ?? ''}'.trim(),
      path: _normalizeSymbolPath(rawUri),
      kind: json['kind']?.toString(),
    );
  }

  final String name;
  final String path;
  final String? kind;

  WorkspaceSymbol toDomain() =>
      WorkspaceSymbol(name: name, path: path, kind: kind);

  static String _normalizeSymbolPath(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('file://')) {
      return Uri.tryParse(trimmed)?.toFilePath() ?? trimmed.substring(7);
    }
    return trimmed;
  }
}
