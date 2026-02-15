import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../repositories/app_repository.dart';

/// Technical comment translated to English.
class UpdateServerConfigParams {

  const UpdateServerConfigParams({required this.host, required this.port});
  final String host;
  final int port;
}

/// Technical comment translated to English.
class UpdateServerConfig {

  UpdateServerConfig(this.repository);
  final AppRepository repository;

  Future<Either<Failure, void>> call(UpdateServerConfigParams params) async {
    return await repository.updateServerConfig(params.host, params.port);
  }
}
