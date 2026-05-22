import 'package:equatable/equatable.dart';

enum FileNodeType { file, directory, unknown }

class FileNode extends Equatable {
  const FileNode({required this.path, required this.name, required this.type});

  final String path;
  final String name;
  final FileNodeType type;

  bool get isDirectory => type == FileNodeType.directory;
  bool get isFile => type == FileNodeType.file;

  @override
  List<Object?> get props => [path, name, type];
}

class FileContent extends Equatable {
  const FileContent({
    required this.path,
    required this.content,
    required this.isBinary,
    this.mimeType,
  });

  final String path;
  final String content;
  final bool isBinary;
  final String? mimeType;

  bool get isEmpty => !isBinary && content.isEmpty;

  @override
  List<Object?> get props => [path, content, isBinary, mimeType];
}

class FileSearchMatch extends Equatable {
  const FileSearchMatch({
    required this.path,
    required this.lineNumber,
    required this.lineContent,
    this.absoluteOffset,
    this.submatches = const <String>[],
  });

  final String path;
  final int lineNumber;
  final String lineContent;
  final int? absoluteOffset;
  final List<String> submatches;

  @override
  List<Object?> get props => [
    path,
    lineNumber,
    lineContent,
    absoluteOffset,
    submatches,
  ];
}

class WorkspaceSymbol extends Equatable {
  const WorkspaceSymbol({required this.name, required this.path, this.kind});

  final String name;
  final String path;
  final String? kind;

  @override
  List<Object?> get props => [name, path, kind];
}
