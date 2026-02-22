import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Configure a dedicated HttpClientAdapter for SSE Dio on IO platforms.
/// Uses a separate HttpClient instance so SSE long-lived connections
/// are never evicted by regular HTTP request pool pressure.
void configureSseAdapter(Dio dio) {
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.idleTimeout = const Duration(hours: 2);
      // SSE only needs a few concurrent long-lived connections.
      client.maxConnectionsPerHost = 4;
      return client;
    },
  );
}
