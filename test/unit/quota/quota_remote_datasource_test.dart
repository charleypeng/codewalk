import 'dart:convert';
import 'dart:io';

import 'package:codewalk/data/datasources/quota_remote_datasource.dart';
import 'package:codewalk/presentation/services/chat_title_generator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

String _decodeShellScript(String command) {
  final match = RegExp(
    r"Buffer\.from\('([^']+)'\s*,\s*'base64'\)",
  ).firstMatch(command);
  expect(match, isNotNull);
  final encoded = match!.group(1)!;
  return utf8.decode(base64Decode(encoded));
}

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
      String? shellCommand;
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
              shellCommand =
                  (options.data as Map<String, dynamic>)['command'] as String?;
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

      final script = _decodeShellScript(shellCommand!);
      expect(script, contains("const AG = ["));
      expect(script, contains("p.join(CFG, 'antigravity-accounts.json')"));
      expect(script, contains('function rGem(a)'));
      expect(script, contains('function rAnti()'));
      expect(script, isNot(contains('GOCSPX-')));
      expect(script, isNot(contains('.apps.googleusercontent.com')));
    },
  );

  test('generated quota shell script is valid JavaScript', () async {
    final dio = Dio();
    String? shellCommand;
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
                data: <String, dynamic>{'id': 'ses_syntax_probe'},
              ),
            );
            return;
          }
          if (options.path == '/session/ses_syntax_probe/shell') {
            shellCommand =
                (options.data as Map<String, dynamic>)['command'] as String?;
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'parts': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'type': 'text',
                      'text': 'CW_QUOTA_JSON:{"results":[]}',
                    },
                  ],
                },
              ),
            );
            return;
          }
          if (options.path == '/session/ses_syntax_probe' &&
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
    await dataSource.fetchQuotaResults();

    final script = _decodeShellScript(shellCommand!);
    final tempFile = File(
      '${Directory.systemTemp.path}/codewalk_quota_shell_syntax_${DateTime.now().microsecondsSinceEpoch}.js',
    );
    await tempFile.writeAsString(script);
    addTearDown(() async {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });

    final result = await Process.run('node', <String>[
      '--check',
      tempFile.path,
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
  });

  test(
    'falls back to shell when REST returns non-404 error (e.g. 500)',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/quota/providers') {
              // Simulate a 500 internal server error – previously this
              // returned an empty list instead of null, preventing the
              // shell fallback from being attempted.
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response<dynamic>(
                    requestOptions: options,
                    statusCode: 500,
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
                  data: <String, dynamic>{'id': 'ses_500_fallback'},
                ),
              );
              return;
            }
            if (options.path == '/session/ses_500_fallback/shell') {
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: <String, dynamic>{
                    'parts': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'type': 'text',
                        'text':
                            'CW_QUOTA_JSON:{"results":[{"providerId":"claude","providerName":"Claude","ok":true,"configured":true,"usage":{"windows":{"5h":{"usedPercent":30}}},"fetchedAt":1}]}',
                      },
                    ],
                  },
                ),
              );
              return;
            }
            if (options.path == '/session/ses_500_fallback' &&
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
      expect(results.first.providerId, 'claude');
      expect(results.first.usage?.windows['5h']?.usedPercent, 30);
    },
  );

  test(
    'parses Google model quota payloads from shell fallback results',
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
                  data: <String, dynamic>{'id': 'ses_google_probe'},
                ),
              );
              return;
            }
            if (options.path == '/session/ses_google_probe/shell') {
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: <String, dynamic>{
                    'parts': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'type': 'text',
                        'text':
                            'CW_QUOTA_JSON:{"results":[{"providerId":"google","providerName":"Google","ok":true,"configured":true,"usage":{"windows":{},"models":{"gemini/gemini-2.5-pro":{"windows":{"daily":{"usedPercent":44,"remainingPercent":56,"windowSeconds":86400}}},"antigravity/gemini-2.5-flash":{"windows":{"5h":{"usedPercent":72,"remainingPercent":28,"windowSeconds":18000}}}}},"fetchedAt":1}]}',
                      },
                    ],
                  },
                ),
              );
              return;
            }
            if (options.path == '/session/ses_google_probe' &&
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
      expect(results.first.providerId, 'google');
      expect(
        results.first.usage?.models.keys,
        containsAll(<String>[
          'gemini/gemini-2.5-pro',
          'antigravity/gemini-2.5-flash',
        ]),
      );
      expect(
        results
            .first
            .usage
            ?.models['gemini/gemini-2.5-pro']
            ?.windows['daily']
            ?.usedPercent,
        44,
      );
      expect(
        results
            .first
            .usage
            ?.models['antigravity/gemini-2.5-flash']
            ?.windows['5h']
            ?.windowSeconds,
        18000,
      );
    },
  );
}
