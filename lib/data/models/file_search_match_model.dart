import '../../domain/entities/file_node.dart';

class FileSearchMatchModel {
  const FileSearchMatchModel({
    required this.path,
    required this.lineNumber,
    required this.lineContent,
    this.absoluteOffset,
    this.submatches = const <String>[],
  });

  factory FileSearchMatchModel.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'];
    final lineContent = rawLines is List
        ? rawLines.map((item) => '$item').join('\n')
        : '${rawLines ?? json['line'] ?? ''}';
    final rawSubmatches = json['submatches'];
    return FileSearchMatchModel(
      path: '${json['path'] ?? ''}'.trim(),
      lineNumber:
          (json['line_number'] as num?)?.toInt() ??
          (json['lineNumber'] as num?)?.toInt() ??
          0,
      lineContent: lineContent.trimRight(),
      absoluteOffset: (json['absolute_offset'] as num?)?.toInt(),
      submatches: rawSubmatches is List
          ? rawSubmatches.map((item) => '$item').toList(growable: false)
          : const <String>[],
    );
  }

  final String path;
  final int lineNumber;
  final String lineContent;
  final int? absoluteOffset;
  final List<String> submatches;

  FileSearchMatch toDomain() {
    return FileSearchMatch(
      path: path,
      lineNumber: lineNumber,
      lineContent: lineContent,
      absoluteOffset: absoluteOffset,
      submatches: submatches,
    );
  }
}
