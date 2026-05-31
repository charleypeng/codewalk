import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class TailscaleHttpAdapter implements HttpClientAdapter {
  TailscaleHttpAdapter(this._client);

  final http.Client _client;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final request = http.StreamedRequest(options.method, options.uri);
    request.followRedirects = options.followRedirects;
    request.maxRedirects = options.maxRedirects;
    request.persistentConnection = options.persistentConnection;
    request.headers.addAll(
      options.headers.map(
        (key, value) => MapEntry(key, value == null ? '' : value.toString()),
      ),
    );
    final contentLength = options.headers[Headers.contentLengthHeader];
    if (contentLength is int) {
      request.contentLength = contentLength;
    } else if (contentLength is String) {
      request.contentLength = int.tryParse(contentLength) ?? -1;
    }

    final bodyDone = Completer<void>();
    final subscription = requestStream?.listen(
      request.sink.add,
      onError: (Object error, StackTrace stackTrace) {
        request.sink.addError(error, stackTrace);
        if (!bodyDone.isCompleted) {
          bodyDone.completeError(error, stackTrace);
        }
      },
      onDone: () {
        unawaited(request.sink.close());
        if (!bodyDone.isCompleted) {
          bodyDone.complete();
        }
      },
      cancelOnError: true,
    );
    if (requestStream == null) {
      await request.sink.close();
      bodyDone.complete();
    }

    if (cancelFuture != null) {
      unawaited(
        cancelFuture.then((_) async {
          await subscription?.cancel();
          await request.sink.close();
          if (!bodyDone.isCompleted) {
            bodyDone.completeError(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
                error: 'Tailscale request cancelled',
              ),
            );
          }
        }),
      );
    }

    await bodyDone.future;
    final response = await _client.send(request);
    final headers = response.headers.map(
      (key, value) => MapEntry(key, <String>[value]),
    );

    // Keep the response stream live for SSE and long assistant responses.
    return ResponseBody(
      response.stream.map(Uint8List.fromList),
      response.statusCode,
      headers: headers,
      statusMessage: response.reasonPhrase,
      isRedirect: response.isRedirect,
    );
  }

  @override
  void close({bool force = false}) {}
}
