import '../../domain/entities/chat_session.dart';

class SessionTodoModel {

  factory SessionTodoModel.fromJson(Map<String, dynamic> json) {
    return SessionTodoModel(
      id: json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      priority: json['priority'] as String? ?? 'medium',
    );
  }
  const SessionTodoModel({
    required this.id,
    required this.content,
    required this.status,
    required this.priority,
  });

  final String id;
  final String content;
  final String status;
  final String priority;

  SessionTodo toDomain() {
    return SessionTodo(
      id: id,
      content: content,
      status: status,
      priority: priority,
    );
  }
}

class SessionDiffModel {

  factory SessionDiffModel.fromJson(Map<String, dynamic> json) {
    return SessionDiffModel(
      file: json['file'] as String? ?? '',
      before: json['before'] as String? ?? '',
      after: json['after'] as String? ?? '',
      additions: (json['additions'] as num?)?.toInt() ?? 0,
      deletions: (json['deletions'] as num?)?.toInt() ?? 0,
      status: json['status'] as String?,
      patch: json['patch'] as String?,
    );
  }
  const SessionDiffModel({
    required this.file,
    required this.before,
    required this.after,
    required this.additions,
    required this.deletions,
    this.status,
    this.patch,
  });

  final String file;
  final String before;
  final String after;
  final int additions;
  final int deletions;
  final String? status;

  /// Unified diff text from the server (FileDiff.patch in OpenCode schema).
  final String? patch;

  SessionDiff toDomain() {
    return SessionDiff(
      file: file,
      before: before,
      after: after,
      additions: additions,
      deletions: deletions,
      status: status,
      patch: patch,
    );
  }
}
