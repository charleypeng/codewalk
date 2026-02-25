import 'package:dio/dio.dart';

import '../../core/errors/failures.dart';

/// Mixin that maps DioException types to domain Failure values.
/// Used by repository implementations to avoid duplicating error-handling logic.
mixin DioExceptionHandler {
  Failure handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure('Connection timeout');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode != null) {
          if (statusCode >= 400 && statusCode < 500) {
            return NetworkFailure('Client error', statusCode);
          } else if (statusCode >= 500) {
            return ServerFailure('Server error', statusCode);
          }
        }
        // Unexpected 1xx/2xx/3xx from badResponse, or null status — treat as server error.
        return const ServerFailure('Response error');
      case DioExceptionType.cancel:
        return const NetworkFailure('Request cancelled');
      case DioExceptionType.connectionError:
        return const NetworkFailure('Network connection error');
      case DioExceptionType.unknown:
        return NetworkFailure('Unknown network error: ${e.message}');
      case DioExceptionType.badCertificate:
        return const NetworkFailure('Certificate error');
    }
  }
}
