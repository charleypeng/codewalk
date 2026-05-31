import 'dart:typed_data';

import 'package:codewalk/core/constants/api_constants.dart';
import 'package:codewalk/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdapter implements HttpClientAdapter {
  var closed = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw UnimplementedError();
  }

  @override
  void close({bool force = false}) {
    closed = true;
  }
}

void main() {
  group('DioClient auth ownership', () {
    test('clearing OAuth restores Basic Auth instead of removing it', () {
      final client = DioClient(baseUrl: 'https://code.example.com');

      client.setBasicAuth('opencode', 'password');
      final basicHeader =
          client.dio.options.headers[ApiConstants.authorization];

      client.setOAuthToken('oauth-token', origin: 'https://code.example.com');
      client.clearOAuthToken();

      expect(
        client.dio.options.headers[ApiConstants.authorization],
        basicHeader,
      );
      expect(
        client.sseDio.options.headers[ApiConstants.authorization],
        basicHeader,
      );
    });

    test('clearing Basic Auth does not clear OAuth state', () {
      final client = DioClient(baseUrl: 'https://code.example.com');

      client.setOAuthToken('oauth-token', origin: 'https://code.example.com');
      client.setBasicAuth('opencode', 'password');
      client.clearBasicAuth();

      expect(client.hasOAuthToken, isTrue);
    });
  });

  group('DioClient transport ownership', () {
    test('applies Tailscale adapter to regular and SSE clients', () {
      final client = DioClient(baseUrl: 'https://code.example.com');
      final adapter = _FakeAdapter();

      client.applyTailscaleAdapter(adapter);

      expect(client.dio.httpClientAdapter, same(adapter));
      expect(client.sseDio.httpClientAdapter, same(adapter));
    });

    test('creates health check Dio with active Tailscale adapter', () {
      final client = DioClient(baseUrl: 'https://code.example.com');
      final adapter = _FakeAdapter();

      client.applyTailscaleAdapter(adapter);
      final healthDio = client.createHealthCheckDio();

      expect(healthDio.httpClientAdapter, same(adapter));
      expect(healthDio.options.baseUrl, 'https://code.example.com');
    });
  });
}
