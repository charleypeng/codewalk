import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/entities/quota.dart';
import '../../presentation/services/chat_title_generator.dart';

abstract class QuotaRemoteDataSource {
  Future<List<QuotaProviderResult>> fetchQuotaResults();
}

class QuotaRemoteDataSourceImpl implements QuotaRemoteDataSource {
  QuotaRemoteDataSourceImpl({required this.dio});

  final Dio dio;

  static const String _shellPrefix = 'CW_QUOTA_JSON:';

  @override
  Future<List<QuotaProviderResult>> fetchQuotaResults() async {
    final viaRest = await _fetchViaOpenChamberRest();
    if (viaRest != null) {
      AppLogger.info('[Quota] REST path returned ${viaRest.length} results');
      return viaRest;
    }
    AppLogger.info('[Quota] REST path unavailable, trying shell fallback');
    return _fetchViaShellFallback();
  }

  Future<List<QuotaProviderResult>?> _fetchViaOpenChamberRest() async {
    try {
      final response = await dio.get<dynamic>('/api/quota/providers');
      if (response.statusCode != 200) {
        AppLogger.info(
          '[Quota] REST /api/quota/providers returned ${response.statusCode}',
        );
        return null;
      }
      final payload = response.data;
      if (payload is! Map) {
        AppLogger.info('[Quota] REST payload is not a Map: ${payload.runtimeType}');
        return null;
      }
      final providers =
          (payload['providers'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<String>()
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false);
      if (providers.isEmpty) {
        AppLogger.info('[Quota] REST returned empty providers list');
        return const <QuotaProviderResult>[];
      }
      AppLogger.info('[Quota] REST found providers: $providers');
      final results = await Future.wait(
        providers.map(_fetchQuotaForProviderRest),
      );
      return results.whereType<QuotaProviderResult>().toList(growable: false);
    } on DioException catch (error) {
      // Any DioException means the REST endpoint is not available on this
      // host.  Return null so the strategy chain falls through to the shell
      // fallback instead of silently returning an empty list.
      AppLogger.info(
        '[Quota] REST DioException (status=${error.response?.statusCode}): '
        '${error.type}',
      );
      return null;
    } catch (error) {
      AppLogger.info('[Quota] REST unexpected error: $error');
      return null;
    }
  }

  Future<QuotaProviderResult?> _fetchQuotaForProviderRest(
    String providerId,
  ) async {
    try {
      final response = await dio.get<dynamic>('/api/quota/$providerId');
      if (response.statusCode != 200) {
        return null;
      }
      final payload = response.data;
      if (payload is Map<String, dynamic>) {
        return QuotaProviderResult.fromJson(payload);
      }
      if (payload is Map) {
        return QuotaProviderResult.fromJson(Map<String, dynamic>.from(payload));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<QuotaProviderResult>> _fetchViaShellFallback() async {
    String? sessionId;
    try {
      sessionId = await _createEphemeralSession();
      if (sessionId == null) {
        AppLogger.info('[Quota] Shell fallback: failed to create session');
        return const <QuotaProviderResult>[];
      }
      AppLogger.info('[Quota] Shell fallback: session $sessionId created');
      final response = await dio.post<dynamic>(
        '/session/$sessionId/shell',
        data: <String, dynamic>{
          'agent': 'build',
          'command': _buildQuotaShellCommand(),
        },
      );
      if (response.statusCode != 200 || response.data is! Map) {
        AppLogger.info(
          '[Quota] Shell fallback: bad response '
          '(status=${response.statusCode}, '
          'type=${response.data.runtimeType})',
        );
        return const <QuotaProviderResult>[];
      }
      final envelope = Map<String, dynamic>.from(response.data as Map);
      final output = _extractShellJsonPayload(envelope);
      if (output == null) {
        // Dump parts content for diagnosis.
        final parts =
            envelope['parts'] as List<dynamic>? ?? const <dynamic>[];
        for (var i = 0; i < parts.length; i++) {
          final part = parts[i];
          try {
            // Log top-level keys and state sub-keys separately.
            if (part is Map) {
              final m = Map<String, dynamic>.from(part);
              AppLogger.info(
                '[Quota] Shell parts[$i] keys: ${m.keys.toList()}',
              );
              final state = m['state'];
              if (state is Map) {
                final sm = Map<String, dynamic>.from(state);
                AppLogger.info(
                  '[Quota] Shell parts[$i].state keys: ${sm.keys.toList()}',
                );
                for (final entry in sm.entries) {
                  final val = entry.value;
                  if (val is String) {
                    final preview = val.length > 400
                        ? '${val.substring(0, 400)}…'
                        : val;
                    AppLogger.info(
                      '[Quota] Shell parts[$i].state.${entry.key}: $preview',
                    );
                  } else {
                    AppLogger.info(
                      '[Quota] Shell parts[$i].state.${entry.key}: '
                      '${val?.runtimeType ?? 'null'}',
                    );
                  }
                }
              } else {
                AppLogger.info(
                  '[Quota] Shell parts[$i].state: ${state?.runtimeType ?? "null"}',
                );
              }
            }
          } catch (e) {
            AppLogger.info('[Quota] Shell parts[$i]: dump error $e');
          }
        }
        AppLogger.info(
          '[Quota] Shell fallback: no CW_QUOTA_JSON found in response. '
          'Keys: ${envelope.keys.toList()}',
        );
        return const <QuotaProviderResult>[];
      }
      final decoded = jsonDecode(output);
      if (decoded is! Map) {
        AppLogger.info(
          '[Quota] Shell fallback: decoded payload is not a Map',
        );
        return const <QuotaProviderResult>[];
      }
      final results =
          decoded['results'] as List<dynamic>? ?? const <dynamic>[];
      AppLogger.info(
        '[Quota] Shell fallback: got ${results.length} raw results',
      );
      return results
          .whereType<Map>()
          .map(
            (item) =>
                QuotaProviderResult.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    } catch (error) {
      AppLogger.info('[Quota] Shell fallback error: $error');
      return const <QuotaProviderResult>[];
    } finally {
      if (sessionId != null) {
        try {
          await dio.delete<dynamic>('/session/$sessionId');
        } catch (_) {}
        final ephemeralId = sessionId;
        Future<void>.delayed(const Duration(seconds: 5), () {
          ChatTitleGenerator.ephemeralSessionIds.remove(ephemeralId);
        });
      }
    }
  }

  Future<String?> _createEphemeralSession() async {
    try {
      final response = await dio.post<dynamic>(
        '/session',
        data: <String, dynamic>{
          'title': ChatTitleGenerator.ephemeralSessionTitle,
        },
      );
      final map = response.data as Map<String, dynamic>?;
      final sessionId = map?['id'] as String?;
      if (sessionId == null || sessionId.trim().isEmpty) {
        return null;
      }
      ChatTitleGenerator.ephemeralSessionIds.add(sessionId);
      return sessionId;
    } catch (_) {
      return null;
    }
  }

  String? _extractShellJsonPayload(Map<String, dynamic> envelope) {
    final parts = envelope['parts'] as List<dynamic>? ?? const <dynamic>[];
    for (final part in parts) {
      if (part is! Map) {
        continue;
      }
      final map = Map<String, dynamic>.from(part);
      // Search every string value in the part for the CW_QUOTA_JSON: prefix.
      // The OpenCode shell response may put output in 'text', 'result',
      // 'output', or nested inside the 'tool' object depending on version.
      final found = _searchStringValues(map);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  /// Recursively search all string values in [data] for a line starting with
  /// [_shellPrefix] and return the JSON payload after the prefix.
  String? _searchStringValues(Map<String, dynamic> data) {
    for (final value in data.values) {
      if (value is String && value.trim().isNotEmpty) {
        for (final line in value.split('\n').reversed) {
          final trimmed = line.trim();
          if (trimmed.startsWith(_shellPrefix)) {
            return trimmed.substring(_shellPrefix.length);
          }
        }
      } else if (value is Map) {
        final found =
            _searchStringValues(Map<String, dynamic>.from(value));
        if (found != null) {
          return found;
        }
      } else if (value is List) {
        for (final item in value) {
          if (item is Map) {
            final found =
                _searchStringValues(Map<String, dynamic>.from(item));
            if (found != null) {
              return found;
            }
          } else if (item is String && item.trim().isNotEmpty) {
            for (final line in item.split('\n').reversed) {
              final trimmed = line.trim();
              if (trimmed.startsWith(_shellPrefix)) {
                return trimmed.substring(_shellPrefix.length);
              }
            }
          }
        }
      }
    }
    return null;
  }

  String _buildQuotaShellCommand() {
    // Minimal JS: reads auth.json on the OpenCode host and outputs
    // configured providers. No HTTP calls, no multiline if/fi (which the
    // OpenCode shell endpoint truncates). Full command is ~800 chars.
    const jsScript =
        "const fs=require('fs'),os=require('os'),p=require('path');"
        "const P='CW_QUOTA_JSON:';"
        "function rAuth(){try{const f=p.join(process.env.XDG_DATA_HOME||p.join(os.homedir(),'.local','share'),'opencode','auth.json');"
        "if(!fs.existsSync(f))return{};const r=fs.readFileSync(f,'utf8').trim();"
        'if(!r)return{};return JSON.parse(r);}catch{return{};}}'
        'function getE(a,al){for(const x of al)if(a[x])return a[x];return null;}'
        "function toN(v){if(typeof v==='number'&&Number.isFinite(v))return v;if(typeof v==='string'){const p=Number(v);return Number.isFinite(p)?p:null;}return null;}"
        'function bR({pId,pName,ok,use,err}){return{providerId:pId,providerName:pName,ok,configured:true,usage:use??null,error:err??null,fetchedAt:Date.now()};}'
        "async function fC(a){const e=getE(a,['anthropic','claude']);const t=e&&(e.access||e.token);if(!t)return null;"
        "try{const res=await fetch('https://api.anthropic.com/api/oauth/usage',{headers:{Authorization:'Bearer '+t,'anthropic-beta':'oauth-2025-04-20'}});"
        "if(!res.ok)return bR({pId:'claude',pName:'Claude',ok:false,err:'API error: '+res.status});"
        'const d=await res.json();const w={};const add=(k,f)=>{if(d&&d[f]){const u=toN(d[f].utilization);'
        "const r=typeof d[f].resets_at==='string'?new Date(d[f].resets_at).getTime():null;"
        'w[k]={usedPercent:u!==null?Math.max(0,Math.min(100,u)):null,windowSeconds:null,resetAt:r};}};'
        "add('5h','five_hour');add('7d','seven_day');add('7d-sonnet','seven_day_sonnet');add('7d-opus','seven_day_opus');"
        "return bR({pId:'claude',pName:'Claude',ok:true,use:{windows:w}});"
        "}catch(err){return bR({pId:'claude',pName:'Claude',ok:false,err:err.message});}}"
        "async function fO(a){const e=getE(a,['openrouter']);const k=e&&(e.key||e.token);if(!k)return null;"
        "try{const res=await fetch('https://openrouter.ai/api/v1/credits',{headers:{Authorization:'Bearer '+k,'Content-Type':'application/json'}});"
        "if(!res.ok)return bR({pId:'openrouter',pName:'OpenRouter',ok:false,err:'API error: '+res.status});"
        'const d=await res.json();const c=d&&d.data?d.data:{};const tC=toN(c.total_credits);const tU=toN(c.total_usage);'
        'const uP=(tC!==null&&tU!==null&&tC>0)?Math.max(0,Math.min(100,(tU/tC)*100)):null;'
        'const rem=(tC!==null&&tU!==null)?Math.max(0,tC-tU):null;'
        "return bR({pId:'openrouter',pName:'OpenRouter',ok:true,use:{windows:{"
        "credits:{usedPercent:uP,valueLabel:rem!==null?'\$'+rem.toFixed(2)+' remaining':null}}}});"
        "}catch(err){return bR({pId:'openrouter',pName:'OpenRouter',ok:false,err:err.message});}}"
        '(async()=>{const a=rAuth();const R=[];const c=await fC(a);if(c)R.push(c);const o=await fO(a);if(o)R.push(o);'
        "const ig=['anthropic','claude','openrouter'];for(const k of Object.keys(a)){"
        "if(ig.includes(k)||!a[k]||typeof a[k]!=='object')continue;"
        'R.push(bR({pId:k,pName:k.charAt(0).toUpperCase()+k.slice(1),ok:true,use:{'
        "windows:{status:{usedPercent:0,valueLabel:'Configured'}}}}));}"
        'console.log(P+JSON.stringify({results:R}));})().catch(()=>{console.log(P+JSON.stringify({results:[]}));});';

    final b64 = base64Encode(utf8.encode(jsScript));
    // Single-line command — avoids multiline if/fi that OpenCode's eval truncates.
    return "node -e \"eval(Buffer.from('$b64','base64').toString())\""
        " || printf '%s\\n' '$_shellPrefix{\"results\":[]}'";
  }
}
