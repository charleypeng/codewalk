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

class _StickySessionAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final headers = requests.length == 1
        ? <String, List<String>>{
            'X-Session-Id': <String>['sticky-session'],
          }
        : <String, List<String>>{};
    return ResponseBody.fromString('{}', 200, headers: headers);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('DioClient auth ownership', () {
    test('clearing OAuth restores origin-bound Basic Auth', () async {
      final client = DioClient(baseUrl: 'https://code.example.com');
      final adapter = _StickySessionAdapter();
      client.dio.httpClientAdapter = adapter;

      client.setBasicAuth(
        'opencode',
        'password',
        origin: 'https://code.example.com',
      );

      client.setOAuthToken('oauth-token', origin: 'https://code.example.com');
      client.clearOAuthToken();
      await client.dio.get<void>('/auth');

      expect(
        adapter.requests.single.headers[ApiConstants.authorization],
        startsWith('Basic '),
      );
    });

    test('clearing Basic Auth does not clear OAuth state', () {
      final client = DioClient(baseUrl: 'https://code.example.com');

      client.setOAuthToken('oauth-token', origin: 'https://code.example.com');
      client.setBasicAuth(
        'opencode',
        'password',
        origin: 'https://code.example.com',
      );
      client.clearBasicAuth();

      expect(client.hasOAuthToken, isTrue);
    });

    test('does not send Basic Auth to another origin', () async {
      final client = DioClient(baseUrl: 'https://code.example.com');
      final adapter = _StickySessionAdapter();
      client.dio.httpClientAdapter = adapter;
      client.setBasicAuth(
        'opencode',
        'password',
        origin: 'https://code.example.com',
      );

      await client.dio.get<void>('/same-origin');
      await client.dio.get<void>('https://other.example.com/cross-origin');

      expect(
        adapter.requests.first.headers[ApiConstants.authorization],
        startsWith('Basic '),
      );
      expect(adapter.requests.last.headers[ApiConstants.authorization], isNull);
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

  group('DioClient OpenCode sticky routing', () {
    test(
      'echoes X-Session-Id from a prior response on later requests',
      () async {
        final client = DioClient(baseUrl: 'https://code.example.com');
        final adapter = _StickySessionAdapter();
        client.dio.httpClientAdapter = adapter;

        await client.get<dynamic>('/global/health');
        await client.get<dynamic>('/session');

        expect(adapter.requests, hasLength(2));
        expect(adapter.requests.last.headers['X-Session-Id'], 'sticky-session');
      },
    );

    test('clears sticky session when base URL changes', () async {
      final client = DioClient(baseUrl: 'https://code.example.com');
      final adapter = _StickySessionAdapter();
      client.dio.httpClientAdapter = adapter;

      await client.get<dynamic>('/global/health');
      client.updateBaseUrl('https://other.example.com');
      await client.get<dynamic>('/session');

      expect(adapter.requests.last.headers['X-Session-Id'], isNull);
    });

    test('clears sticky session when auth is cleared', () async {
      final client = DioClient(baseUrl: 'https://code.example.com');
      final adapter = _StickySessionAdapter();
      client.dio.httpClientAdapter = adapter;

      await client.get<dynamic>('/global/health');
      client.clearAuth();
      await client.get<dynamic>('/session');

      expect(adapter.requests.last.headers['X-Session-Id'], isNull);
    });
  });
}
