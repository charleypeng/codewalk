// One-shot diagnostic replica of CodeWalk's OAuthService._runPkceFlow.
// Run: dart tool/qa/oauth_loopback_probe.dart <serverUrl>   (default https://ai.pforever.win)
// It performs: metadata discovery -> DCR -> loopback callback server ->
// open system browser -> capture callback -> token exchange, printing
// every step so we can see exactly where the Android flow fails.
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

String baseUrl(String serverUrl) {
  var url = serverUrl.trim();
  if (!url.contains('://')) url = 'http://$url';
  final uri = Uri.parse(url);
  final portStr = uri.hasPort ? ':${uri.port}' : '';
  return '${uri.scheme}://${uri.host}$portStr';
}

String genVerifier() {
  final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}

Future<void> main(List<String> args) async {
  final server = args.isEmpty ? 'https://ai.pforever.win' : args.first;
  final base = baseUrl(server);
  print('== Target: $base');

  // 1. metadata
  final metaUrl = '$base/.well-known/oauth-authorization-server';
  print('== GET $metaUrl');
  final c1 = HttpClient();
  final metaReq = await c1.getUrl(Uri.parse(metaUrl));
  final metaRes = await metaReq.close().timeout(const Duration(seconds: 10));
  final metaBody = await metaRes.transform(utf8.decoder).join();
  print('   status=${metaRes.statusCode}');
  if (metaRes.statusCode != 200) {
    print('!! metadata fetch failed'); exit(1);
  }
  final meta = jsonDecode(metaBody) as Map<String, dynamic>;
  final authEp = meta['authorization_endpoint'] as String;
  final tokenEp = meta['token_endpoint'] as String;
  final regEp = meta['registration_endpoint'] as String?;
  print('   auth=$authEp\n   token=$tokenEp\n   register=$regEp');
  c1.close(force: true);

  // 2. loopback server
  final callbackServer = await HttpServer.bind('127.0.0.1', 0);
  final redirectUri = 'http://127.0.0.1:${callbackServer.port}/oauth/callback';
  print('== Loopback callback server on $redirectUri');

  // 3. DCR
  String? clientId;
  if (regEp != null) {
    final c2 = HttpClient();
    final regReq = await c2.postUrl(Uri.parse(regEp));
    regReq.headers.contentType = ContentType.json;
    regReq.write(jsonEncode({
      'redirect_uris': [redirectUri],
      'token_endpoint_auth_method': 'none',
      'grant_types': ['authorization_code', 'refresh_token'],
      'response_types': ['code'],
      'client_name': 'CodeWalkProbe',
      'resource': base,
    }));
    final regRes = await regReq.close().timeout(const Duration(seconds: 15));
    final regBody = await regRes.transform(utf8.decoder).join();
    print('== DCR status=${regRes.statusCode} body=$regBody');
    if (regRes.statusCode == 200 || regRes.statusCode == 201) {
      clientId = (jsonDecode(regBody) as Map<String, dynamic>)['client_id'] as String?;
    }
    c2.close(force: true);
  }
  print('   client_id=$clientId');

  // 4. auth URL
  final verifier = genVerifier();
  final challenge = base64Url
      .encode(sha256.convert(utf8.encode(verifier)).bytes)
      .replaceAll('=', '');
  final state = genVerifier();
  final params = <String, String>{
    'response_type': 'code',
    'redirect_uri': redirectUri,
    'code_challenge': challenge,
    'code_challenge_method': 'S256',
    'state': state,
    'resource': base,
  };
  if (clientId != null) params['client_id'] = clientId;
  final authUri = Uri.parse(authEp).replace(queryParameters: params);
  print('== Opening browser:\n   $authUri');

  // 5. capture callback
  final sw = Stopwatch()..start();
  String? code;
  String? callbackInfo;
  final sub = callbackServer.listen((req) async {
    print('== Callback hit: ${req.uri}  (+${sw.elapsed.inSeconds}s)');
    if (req.uri.path != '/oauth/callback') {
      req.response.statusCode = 404;
      await req.response.close();
      return;
    }
    final q = req.uri.queryParameters;
    callbackInfo = 'query keys=${q.keys.toList()} '
        'error=${q['error']} stateMatch=${q['state'] == state} '
        'hasCode=${q.containsKey('code')}';
    print('   $callbackInfo');
    if (q['code'] != null && q['state'] == state) code = q['code'];
    req.response.statusCode = 200;
    req.response.headers.contentType = ContentType.html;
    req.response.write('<h2>Probe received the callback — return to the terminal.</h2>');
    await req.response.close();
  });

  await Process.run('open', [authUri.toString()]);
  print('== Waiting up to 5 min for the callback...');
  final deadline = DateTime.now().add(const Duration(minutes: 5));
  while (code == null && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  await sub.cancel();
  await callbackServer.close(force: true);

  if (code == null) {
    print('!! NO USABLE CALLBACK. Last callback info: $callbackInfo');
    exit(2);
  }
  print('== Got code (${code!.length} chars), exchanging...');

  // 6. token exchange
  final c3 = HttpClient();
  final tokReq = await c3.postUrl(Uri.parse(tokenEp));
  tokReq.headers.contentType =
      ContentType('application', 'x-www-form-urlencoded');
  final bodyParams = <String, String>{
    'grant_type': 'authorization_code',
    'code': code!,
    'code_verifier': verifier,
    'redirect_uri': redirectUri,
    'resource': base,
  };
  if (clientId != null) bodyParams['client_id'] = clientId;
  tokReq.write(bodyParams.entries
      .map((e) =>
          '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
      .join('&'));
  final tokRes = await tokReq.close().timeout(const Duration(seconds: 15));
  final tokBody = await tokRes.transform(utf8.decoder).join();
  print('== Token exchange status=${tokRes.statusCode}');
  print('   body=${tokBody.length > 400 ? '${tokBody.substring(0, 400)}...' : tokBody}');
  c3.close(force: true);
  print(tokRes.statusCode == 200 ? '== SUCCESS' : '!! EXCHANGE FAILED');
}
