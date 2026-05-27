import 'package:codewalk/core/constants/api_constants.dart';
import 'package:codewalk/core/network/dio_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DioClient auth ownership', () {
    test('clearing OAuth restores Basic Auth instead of removing it', () {
      final client = DioClient(baseUrl: 'https://code.example.com');

      client.setBasicAuth('opencode', 'password');
      final basicHeader = client.dio.options.headers[ApiConstants.authorization];

      client.setOAuthToken('oauth-token', origin: 'https://code.example.com');
      client.clearOAuthToken();

      expect(client.dio.options.headers[ApiConstants.authorization], basicHeader);
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
}
