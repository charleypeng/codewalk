import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../repositories/chat_repository.dart';

class RevertChatMessage {
  const RevertChatMessage(this.repository);

  final ChatRepository repository;

  Future<Either<Failure, void>> call(RevertChatMessageParams params) async {
    return repository.revertMessage(
      params.projectId,
      params.sessionId,
      params.messageId,
      directory: params.directory,
    );
  }
}

class RevertChatMessageParams {
  const RevertChatMessageParams({
    required this.projectId,
    required this.sessionId,
    required this.messageId,
    this.directory,
  });

  final String projectId;
  final String sessionId;
  final String messageId;
  final String? directory;
}
