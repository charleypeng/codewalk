import 'package:codewalk/data/datasources/quota_remote_datasource.dart';
import 'package:codewalk/presentation/services/chat_title_generator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(ChatTitleGenerator.ephemeralSessionIds.clear);

  test('uses OpenChamber REST endpoints when available', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/api/quota/providers') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'providers': <String>['claude'],
                },
              ),
            );
            return;
          }
          if (options.path == '/api/quota/claude') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'providerId': 'claude',
                  'providerName': 'Claude',
                  'ok': true,
                  'configured': true,
                  'usage': <String, dynamic>{
                    'windows': <String, dynamic>{
                      '5h': <String, dynamic>{'usedPercent': 50},
                    },
                  },
                  'fetchedAt': DateTime.now().millisecondsSinceEpoch,
                },
              ),
            );
            return;
          }
          handler.reject(
            DioException(
              requestOptions: options,
              error: 'Unexpected ${options.path}',
            ),
          );
        },
      ),
    );

    final dataSource = QuotaRemoteDataSourceImpl(dio: dio);
    final results = await dataSource.fetchQuotaResults();

    expect(results, hasLength(1));
    expect(results.first.providerId, 'claude');
  });

  test(
    'falls back to shell discovery when REST endpoints are unavailable',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/quota/providers') {
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response<dynamic>(
                    requestOptions: options,
                    statusCode: 404,
                  ),
                ),
              );
              return;
            }
            if (options.path == '/session' && options.method == 'POST') {
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: <String, dynamic>{'id': 'ses_quota_probe'},
                ),
              );
              return;
            }
            if (options.path == '/session/ses_quota_probe/shell') {
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: <String, dynamic>{
                    'parts': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'type': 'text',
                        'text':
                            'CW_QUOTA_JSON:{"results":[{"providerId":"openrouter","providerName":"OpenRouter","ok":true,"configured":true,"usage":{"windows":{"credits":{"usedPercent":63,"valueLabel":"\$12.00 remaining"}}},"fetchedAt":1}]}',
                      },
                    ],
                  },
                ),
              );
              return;
            }
            if (options.path == '/session/ses_quota_probe' &&
                options.method == 'DELETE') {
              handler.resolve(
                Response<dynamic>(requestOptions: options, statusCode: 200),
              );
              return;
            }
            handler.reject(
              DioException(
                requestOptions: options,
                error: 'Unexpected ${options.path}',
              ),
            );
          },
        ),
      );

      final dataSource = QuotaRemoteDataSourceImpl(dio: dio);
      final results = await dataSource.fetchQuotaResults();

      expect(results, hasLength(1));
      expect(results.first.providerId, 'openrouter');
      expect(
        results.first.usage?.windows['credits']?.valueLabel,
        '\$12.00 remaining',
      );
    },
  );
}
