import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../repositories/chat_repository.dart';

class ReplyQuestion {
  const ReplyQuestion(this.repository);

  final ChatRepository repository;

  Future<Either<Failure, void>> call(ReplyQuestionParams params) async {
    return repository.replyQuestion(
      sessionId: params.sessionId,
      requestId: params.requestId,
      answers: params.answers,
      directory: params.directory,
    );
  }
}

class ReplyQuestionParams {
  const ReplyQuestionParams({
    this.sessionId,
    required this.requestId,
    required this.answers,
    this.directory,
  });

  final String? sessionId;
  final String requestId;
  final List<List<String>> answers;
  final String? directory;
}
