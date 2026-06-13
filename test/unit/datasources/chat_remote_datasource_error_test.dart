import 'dart:convert';
import 'dart:typed_data';

import 'package:codewalk/core/errors/exceptions.dart';
import 'package:codewalk/data/datasources/chat_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _JsonErrorAdapter implements HttpClientAdapter {
  _JsonErrorAdapter(this.payload);

  final Map<String, dynamic> payload;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(payload),
      500,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('ChatRemoteDataSource structured errors', () {
    Future<String> errorMessageFor(Map<String, dynamic> payload) async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      dio.httpClientAdapter = _JsonErrorAdapter(payload);
      final datasource = ChatRemoteDataSourceImpl(dio: dio);

      try {
        await datasource.getSessions();
      } on ServerException catch (exception) {
        return exception.message;
      }
      fail('Expected ServerException');
    }

    test('keeps OpenCode named error and reference details', () async {
      final message = await errorMessageFor(<String, dynamic>{
        'error': <String, dynamic>{
          'name': 'UnknownError',
          'data': <String, dynamic>{
            'message': 'Stored message is corrupt',
            'reference': 'log_ref_123',
          },
        },
      });

      expect(message, contains('UnknownError'));
      expect(message, contains('Stored message is corrupt'));
      expect(message, contains('log_ref_123'));
    });

    test('keeps named error code and direct message', () async {
      final message = await errorMessageFor(<String, dynamic>{
        'error': <String, dynamic>{
          'name': 'ServiceUnavailableError',
          'code': 'retry_later',
          'message': 'Mutation is not available yet',
        },
      });

      expect(message, contains('ServiceUnavailableError'));
      expect(message, contains('retry_later'));
      expect(message, contains('Mutation is not available yet'));
    });

    test('surfaces details when data is absent', () async {
      final message = await errorMessageFor(<String, dynamic>{
        'error': <String, dynamic>{
          'name': 'SessionNotFoundError',
          'details': <String, dynamic>{'reference': 'log_ref_456'},
        },
      });

      expect(message, contains('SessionNotFoundError'));
      expect(message, contains('log_ref_456'));
    });

    test('surfaces meta fields as details', () async {
      final message = await errorMessageFor(<String, dynamic>{
        'error': <String, dynamic>{
          'name': 'UnknownError',
          'meta': <String, dynamic>{'traceId': 'trace_789'},
        },
      });

      expect(message, contains('UnknownError'));
      expect(message, contains('trace_789'));
    });
  });
}
