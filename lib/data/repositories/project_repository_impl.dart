import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/file_node.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/worktree.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/project_remote_datasource.dart';
import 'dio_exception_handler.dart';

/// Technical comment translated to English.
class ProjectRepositoryImpl
    with DioExceptionHandler
    implements ProjectRepository {
  ProjectRepositoryImpl({required this.remoteDataSource});
  final ProjectRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, List<Project>>> getProjects() async {
    try {
      final projectsModel = await remoteDataSource.getProjects();
      return Right(projectsModel.toDomain());
    } on DioException catch (e) {
      return Left(handleDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Project>> getCurrentProject({
    String? directory,
  }) async {
    try {
      final projectModel = await remoteDataSource.getCurrentProject(
        directory: directory,
      );
      return Right(projectModel.toDomain());
    } on DioException catch (e) {
      return Left(handleDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Project>> getProject(String projectId) async {
    try {
      final projectModel = await remoteDataSource.getProject(projectId);
      return Right(projectModel.toDomain());
    } on DioException catch (e) {
      return Left(handleDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Worktree>>> getWorktrees({
    String? directory,
  }) async {
    try {
      final models = await remoteDataSource.getWorktrees(directory: directory);
      return Right(
        models.map((item) => item.toDomain()).toList(growable: false),
      );
    } on DioException catch (e) {
      return Left(handleDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Worktree>> createWorktree(
    String name, {
    String? directory,
  }) async {
    try {
      final model = await remoteDataSource.createWorktree(
        name,
        directory: directory,
      );
      return Right(model.toDomain());
    } on DioException catch (e) {
      return Left(handleDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetWorktree(
    String worktreeId, {
    String? directory,
  }) async {
    try {
      await remoteDataSource.resetWorktree(worktreeId, directory: directory);
      return const Right(null);
    } on DioException catch (e) {
      return Left(handleDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteWorktree(
    String worktreeId, {
    String? directory,
  }) async {
    try {
      await remoteDataSource.deleteWorktree(worktreeId, directory: directory);
      return const Right(null);
    } on DioException catch (e) {
      return Left(handleDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> listDirectories(
    String directory,
  ) async {
    try {
      final items = await remoteDataSource.listDirectories(directory);
      return Right(items);
    } on DioException catch (e) {
      return Left(handleDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isGitDirectory(String directory) async {
    try {
      final result = await remoteDataSource.isGitDirectory(directory);
      return Right(result);
    } on DioException catch (e) {
      return Left(handleDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FileNode>>> listFiles({
    String? directory,
    required String path,
  }) async {
    try {
      final items = await remoteDataSource.listFiles(
        directory: directory,
        path: path,
      );
      return Right(
        items.map((item) => item.toDomain()).toList(growable: false),
      );
    } on DioException catch (e) {
      return Left(handleDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FileNode>>> findFiles({
    String? directory,
    required String query,
    String? type,
    int limit = 50,
  }) async {
    try {
      final items = await remoteDataSource.findFiles(
        directory: directory,
        query: query,
        type: type,
        limit: limit,
      );
      return Right(
        items.map((item) => item.toDomain()).toList(growable: false),
      );
    } on DioException catch (e) {
      return Left(handleDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FileSearchMatch>>> searchFileContents({
    String? directory,
    required String pattern,
    int limit = 50,
  }) async {
    try {
      final items = await remoteDataSource.searchFileContents(
        directory: directory,
        pattern: pattern,
        limit: limit,
      );
      return Right(
        items.map((item) => item.toDomain()).toList(growable: false),
      );
    } on DioException catch (e) {
      return Left(handleDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FileContent>> readFileContent({
    String? directory,
    required String path,
  }) async {
    try {
      final content = await remoteDataSource.readFileContent(
        directory: directory,
        path: path,
      );
      return Right(content.toDomain());
    } on DioException catch (e) {
      return Left(handleDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
