import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../repositories/chat_repository.dart';

class RejectQuestion {
  const RejectQuestion(this.repository);

  final ChatRepository repository;

  Future<Either<Failure, void>> call(RejectQuestionParams params) async {
    return repository.rejectQuestion(
      sessionId: params.sessionId,
      requestId: params.requestId,
      directory: params.directory,
    );
  }
}

class RejectQuestionParams {
  const RejectQuestionParams({
    this.sessionId,
    required this.requestId,
    this.directory,
  });

  final String? sessionId;
  final String requestId;
  final String? directory;
}
