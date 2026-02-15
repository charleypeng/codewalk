import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/provider.dart';
import '../repositories/app_repository.dart';

/// Technical comment translated to English.
class GetProviders {

  GetProviders(this.repository);
  final AppRepository repository;

  Future<Either<Failure, ProvidersResponse>> call({String? directory}) async {
    return await repository.getProviders(directory: directory);
  }
}
