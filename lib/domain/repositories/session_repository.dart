import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/message.dart';
import '../entities/session.dart';

/// Technical comment translated to English.
abstract class SessionRepository {
  /// Technical comment translated to English.
  Future<Either<Failure, List<Session>>> getSessions();

  /// Technical comment translated to English.
  Future<Either<Failure, Session>> getSession(String sessionId);

  /// Technical comment translated to English.
  Future<Either<Failure, Session>> createSession({
    String? parentId,
    String? title,
  });

  /// Technical comment translated to English.
  Future<Either<Failure, Session>> updateSession(
    String sessionId, {
    String? title,
  });

  /// Technical comment translated to English.
  Future<Either<Failure, bool>> deleteSession(String sessionId);

  /// Technical comment translated to English.
  Future<Either<Failure, List<Session>>> getChildSessions(String sessionId);

  /// Technical comment translated to English.
  Future<Either<Failure, Session>> shareSession(String sessionId);

  /// Technical comment translated to English.
  Future<Either<Failure, Session>> unshareSession(String sessionId);

  /// Technical comment translated to English.
  Future<Either<Failure, bool>> abortSession(String sessionId);

  /// Technical comment translated to English.
  Future<Either<Failure, bool>> summarizeSession(
    String sessionId,
    String providerId,
    String modelId,
  );

  /// Technical comment translated to English.
  Future<Either<Failure, List<Message>>> getSessionMessages(String sessionId);

  /// Technical comment translated to English.
  Future<Either<Failure, Message>> sendMessage({
    required String sessionId,
    required String providerId,
    required String modelId,
    required List<MessagePart> parts,
    String? messageId,
    String? mode,
    String? system,
    Map<String, bool>? tools,
  });

  /// Technical comment translated to English.
  Future<Either<Failure, Session>> revertMessage(
    String sessionId,
    String messageId, {
    String? partId,
  });

  /// Technical comment translated to English.
  Future<Either<Failure, Session>> unrevertMessages(String sessionId);
}

/// Technical comment translated to English.
abstract class MessagePart {

  const MessagePart({required this.type});
  final String type;
}

/// Technical comment translated to English.
class TextMessagePart extends MessagePart {

  const TextMessagePart({required this.text, this.synthetic})
    : super(type: 'text');
  final String text;
  final bool? synthetic;
}

/// Technical comment translated to English.
class FileMessagePart extends MessagePart {

  const FileMessagePart({required this.mime, required this.url, this.filename})
    : super(type: 'file');
  final String mime;
  final String url;
  final String? filename;
}

/// Technical comment translated to English.
class AgentMessagePart extends MessagePart {

  const AgentMessagePart({required this.name}) : super(type: 'agent');
  final String name;
}
