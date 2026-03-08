import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../repositories/chat_repository.dart';

class UnrevertChatMessages {
  const UnrevertChatMessages(this.repository);

  final ChatRepository repository;

  Future<Either<Failure, void>> call(UnrevertChatMessagesParams params) async {
    return repository.unrevertMessages(
      params.projectId,
      params.sessionId,
      directory: params.directory,
    );
  }
}

class UnrevertChatMessagesParams {
  const UnrevertChatMessagesParams({
    required this.projectId,
    required this.sessionId,
    this.directory,
  });

  final String projectId;
  final String sessionId;
  final String? directory;
}
