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
    test('keeps OpenCode named error and reference details', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      dio.httpClientAdapter = _JsonErrorAdapter(<String, dynamic>{
        'error': <String, dynamic>{
          'name': 'UnknownError',
          'data': <String, dynamic>{
            'message': 'Stored message is corrupt',
            'reference': 'log_ref_123',
          },
        },
      });
      final datasource = ChatRemoteDataSourceImpl(dio: dio);

      expect(
        datasource.getSessions(),
        throwsA(
          isA<ServerException>()
              .having(
                (exception) => exception.message,
                'message',
                contains('UnknownError'),
              )
              .having(
                (exception) => exception.message,
                'reference',
                contains('log_ref_123'),
              ),
        ),
      );
    });
  });
}
