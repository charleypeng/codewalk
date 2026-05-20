import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/entities/quota.dart';
import '../../presentation/services/chat_title_generator.dart';

class OpenCodeGoDashboardCredentials {
  const OpenCodeGoDashboardCredentials({
    required this.workspaceId,
    required this.authCookie,
  });

  final String workspaceId;
  final String authCookie;

  bool get isComplete =>
      workspaceId.trim().isNotEmpty && authCookie.trim().isNotEmpty;
}

abstract class QuotaRemoteDataSource {
  Future<List<QuotaProviderResult>> fetchQuotaResults({
    OpenCodeGoDashboardCredentials? openCodeGoCredentials,
  });
}

class QuotaRemoteDataSourceImpl implements QuotaRemoteDataSource {
  QuotaRemoteDataSourceImpl({required this.dio});

  final Dio dio;

  static const String _shellPrefix = 'CW_QUOTA_JSON:';

  @override
  Future<List<QuotaProviderResult>> fetchQuotaResults({
    OpenCodeGoDashboardCredentials? openCodeGoCredentials,
  }) async {
    final viaRest = await _fetchViaOpenChamberRest();
    if (viaRest != null) {
      AppLogger.info('[Quota] REST path returned ${viaRest.length} results');
      return viaRest;
    }
    AppLogger.info('[Quota] REST path unavailable, trying shell fallback');
    return _fetchViaShellFallback(openCodeGoCredentials: openCodeGoCredentials);
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
        AppLogger.info(
          '[Quota] REST payload is not a Map: ${payload.runtimeType}',
        );
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

  Future<List<QuotaProviderResult>> _fetchViaShellFallback({
    OpenCodeGoDashboardCredentials? openCodeGoCredentials,
  }) async {
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
          'command': _buildQuotaShellCommand(
            openCodeGoCredentials: openCodeGoCredentials,
          ),
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
        final parts = envelope['parts'] as List<dynamic>? ?? const <dynamic>[];
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
                    AppLogger.info(
                      '[Quota] Shell parts[$i].state.${entry.key}: '
                      'String(length=${val.length})',
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
        AppLogger.info('[Quota] Shell fallback: decoded payload is not a Map');
        return const <QuotaProviderResult>[];
      }
      final results = decoded['results'] as List<dynamic>? ?? const <dynamic>[];
      final meta = decoded['meta'];
      if (meta is Map) {
        AppLogger.info(
          '[Quota] Shell fallback meta: ${Map<String, dynamic>.from(meta)}',
        );
      }
      AppLogger.info(
        '[Quota] Shell fallback: got ${results.length} raw results',
      );
      final parsedResults = results
          .whereType<Map>()
          .map(
            (item) =>
                QuotaProviderResult.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
      AppLogger.info(
        '[Quota] Shell fallback parsed results: ${parsedResults.map((item) => '${item.providerId}(ok=${item.ok}, configured=${item.configured}, visible=${item.hasVisibleData}, error=${item.error ?? '-'})').toList()}',
      );
      return parsedResults;
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
        final found = _searchStringValues(Map<String, dynamic>.from(value));
        if (found != null) {
          return found;
        }
      } else if (value is List) {
        for (final item in value) {
          if (item is Map) {
            final found = _searchStringValues(Map<String, dynamic>.from(item));
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

  String _buildQuotaShellCommand({
    OpenCodeGoDashboardCredentials? openCodeGoCredentials,
  }) {
    // Full Base64-encoded JS keeps the shell transport to one line while still
    // allowing real host API fetches for supported providers.
    final openCodeGoWorkspaceIdB64 = openCodeGoCredentials?.isComplete == true
        ? base64Encode(utf8.encode(openCodeGoCredentials!.workspaceId.trim()))
        : '';
    final openCodeGoAuthCookieB64 = openCodeGoCredentials?.isComplete == true
        ? base64Encode(utf8.encode(openCodeGoCredentials!.authCookie.trim()))
        : '';
    final jsScript = r'''
const fs = require('fs');
const os = require('os');
const p = require('path');

const P = 'CW_QUOTA_JSON:';
const OCG_WS_B64 = '__OCG_WS_B64__';
const OCG_CK_B64 = '__OCG_CK_B64__';
const CFG = p.join(os.homedir(), '.config', 'opencode');
const DATA = p.join(
  process.env.XDG_DATA_HOME || p.join(os.homedir(), '.local', 'share'),
  'opencode',
);
const AG = [
  p.join(CFG, 'antigravity-accounts.json'),
  p.join(DATA, 'antigravity-accounts.json'),
];
const GEP = ['https://cloudcode-pa.googleapis.com'];
const GDP = 'rising-fact-p41fc';
// These are provider-level OAuth app credentials, not user account secrets.
// OpenChamber ships the same fallback so installed builds can refresh
// host-owned Gemini tokens even when the host auth files omit client metadata.
const GGID = '681255809395-oo8ft2oprdrnp9e3aqf6av3hmdib135j.apps.googleusercontent.com';
const GGSC = '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';
const AGID = '1071006060591-tmhssin2h21lcre235vtolojh4g403ep.apps.googleusercontent.com';
const AGSC = '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';
const GHD = {
  'User-Agent': 'antigravity/1.11.5 windows/amd64',
  'X-Goog-Api-Client': 'google-cloud-sdk vscode_cloudshelleditor/0.1',
  'Client-Metadata': '{"ideType":"IDE_UNSPECIFIED","platform":"PLATFORM_UNSPECIFIED","pluginType":"GEMINI"}',
};

function rAuth() {
  try {
    const f = p.join(DATA, 'auth.json');
    if (!fs.existsSync(f)) return {};
    const r = fs.readFileSync(f, 'utf8').trim();
    if (!r) return {};
    return JSON.parse(r);
  } catch {
    return {};
  }
}

function rJson(f) {
  try {
    if (!fs.existsSync(f)) return null;
    const r = fs.readFileSync(f, 'utf8').trim();
    if (!r) return null;
    const j = JSON.parse(r);
    return j && typeof j === 'object' ? j : null;
  } catch {
    return null;
  }
}

function getE(a, al) {
  for (const x of al) {
    if (a[x]) return a[x];
  }
  return null;
}

function nE(e) {
  if (!e) return null;
  if (typeof e === 'string') return { token: e };
  if (typeof e === 'object') return e;
  return null;
}

function asO(v) {
  return v && typeof v === 'object' && !Array.isArray(v) ? v : null;
}

function asS(v) {
  if (typeof v !== 'string') return null;
  const t = v.trim();
  return t || null;
}

function pickS(...values) {
  for (const value of values) {
    const s = asS(value);
    if (s) return s;
  }
  return null;
}

function fromB64(v) {
  const s = asS(v);
  if (!s) return null;
  try {
    return Buffer.from(s, 'base64').toString('utf8').trim() || null;
  } catch {
    return null;
  }
}

function toN(v) {
  if (typeof v === 'number' && Number.isFinite(v)) return v;
  if (typeof v === 'string') {
    const p = Number(v);
    return Number.isFinite(p) ? p : null;
  }
  return null;
}

function toTs(v) {
  if (!v) return null;
  if (typeof v === 'number') return v < 1e12 ? v * 1000 : v;
  if (typeof v === 'string') {
    const p = Date.parse(v);
    return Number.isNaN(p) ? null : p;
  }
  return null;
}

function pgR(v) {
  const r = asS(v);
  if (!r) {
    return { refreshToken: null, projectId: null, managedProjectId: null };
  }
  const parts = r.split('|');
  return {
    refreshToken: asS(parts[0]),
    projectId: asS(parts[1]),
    managedProjectId: asS(parts[2]),
  };
}

function gCred(obj, prefix) {
  const o = asO(obj) || {};
  const c = asO(o.client);
  const did = prefix === 'GEMINI' ? GGID : prefix === 'ANTIGRAVITY' ? AGID : null;
  const dsc = prefix === 'GEMINI' ? GGSC : prefix === 'ANTIGRAVITY' ? AGSC : null;
  return {
    clientId: pickS(
      o.clientId,
      o.client_id,
      o.googleClientId,
      o.google_client_id,
      c && c.id,
      c && c.clientId,
      prefix ? process.env[prefix + '_GOOGLE_CLIENT_ID'] : null,
      process.env.GOOGLE_CLIENT_ID,
      did,
    ),
    clientSecret: pickS(
      o.clientSecret,
      o.client_secret,
      o.googleClientSecret,
      o.google_client_secret,
      c && c.secret,
      c && c.clientSecret,
      prefix ? process.env[prefix + '_GOOGLE_CLIENT_SECRET'] : null,
      process.env.GOOGLE_CLIENT_SECRET,
      dsc,
    ),
  };
}

function gDiag(src) {
  return [
    'access=' + (src.accessToken ? 'yes' : 'no'),
    'refresh=' + (src.refreshToken ? 'yes' : 'no'),
    'clientId=' + (src.clientId ? 'yes' : 'no'),
    'clientSecret=' + (src.clientSecret ? 'yes' : 'no'),
    'project=' + (src.projectId ? 'yes' : 'no'),
    'expires=' + (typeof src.expires === 'number' ? 'yes' : 'no'),
  ].join(', ');
}

function bR({ pId, pName, ok, use, err }) {
  return {
    providerId: pId,
    providerName: pName,
    ok,
    configured: true,
    usage: use ?? null,
    error: err ?? null,
    fetchedAt: Date.now(),
  };
}

function tUW({ uP, wS, rA, vL }) {
  const c = typeof uP === 'number' ? Math.max(0, Math.min(100, uP)) : null;
  const rS =
    typeof rA === 'number' ? Math.max(0, Math.round((rA - Date.now()) / 1000)) : null;
  return {
    usedPercent: c,
    remainingPercent: c === null ? null : Math.max(0, 100 - c),
    windowSeconds: typeof wS === 'number' ? wS : null,
    resetAfterSeconds: rS,
    resetAt: typeof rA === 'number' ? rA : null,
    resetAtFormatted: null,
    resetAfterFormatted: null,
    valueLabel: vL ?? null,
  };
}

function gWin(s, rA) {
  if (s === 'antigravity') {
    const rem =
      typeof rA === 'number' ? Math.max(0, Math.round((rA - Date.now()) / 1000)) : null;
    if (rem !== null && rem > 36000) return { label: 'daily', seconds: 86400 };
    return { label: '5h', seconds: 18000 };
  }
  return { label: 'daily', seconds: 86400 };
}

async function fC(a) {
  const e = nE(getE(a, ['anthropic', 'claude']));
  const t = e && (e.access || e.token);
  if (!t) return null;
  try {
    const res = await fetch('https://api.anthropic.com/api/oauth/usage', {
      headers: {
        Authorization: 'Bearer ' + t,
        'anthropic-beta': 'oauth-2025-04-20',
      },
    });
    if (!res.ok) {
      return bR({ pId: 'claude', pName: 'Claude', ok: false, err: 'API error: ' + res.status });
    }
    const d = await res.json();
    const w = {};
    const add = (k, f) => {
      if (d && d[f]) {
        const u = toN(d[f].utilization);
        const r = toTs(d[f].resets_at);
        w[k] = tUW({ uP: u, wS: null, rA: r });
      }
    };
    add('5h', 'five_hour');
    add('7d', 'seven_day');
    add('7d-sonnet', 'seven_day_sonnet');
    add('7d-opus', 'seven_day_opus');
    return bR({ pId: 'claude', pName: 'Claude', ok: true, use: { windows: w } });
  } catch (err) {
    return bR({ pId: 'claude', pName: 'Claude', ok: false, err: err.message });
  }
}

async function fO(a) {
  const e = nE(getE(a, ['openrouter']));
  const k = e && (e.key || e.token);
  if (!k) return null;
  try {
    const res = await fetch('https://openrouter.ai/api/v1/credits', {
      headers: {
        Authorization: 'Bearer ' + k,
        'Content-Type': 'application/json',
      },
    });
    if (!res.ok) {
      return bR({
        pId: 'openrouter',
        pName: 'OpenRouter',
        ok: false,
        err: 'API error: ' + res.status,
      });
    }
    const d = await res.json();
    const c = d && d.data ? d.data : {};
    const tC = toN(c.total_credits);
    const tU = toN(c.total_usage);
    const uP = tC !== null && tU !== null && tC > 0 ? Math.max(0, Math.min(100, (tU / tC) * 100)) : null;
    const rem = tC !== null && tU !== null ? Math.max(0, tC - tU) : null;
    return bR({
      pId: 'openrouter',
      pName: 'OpenRouter',
      ok: true,
      use: {
        windows: {
          credits: tUW({ uP: uP, wS: null, rA: null, vL: rem !== null ? '$' + rem.toFixed(2) + ' remaining' : null }),
        },
      },
    });
  } catch (err) {
    return bR({ pId: 'openrouter', pName: 'OpenRouter', ok: false, err: err.message });
  }
}

async function fX(a) {
  const e = nE(getE(a, ['openai', 'codex', 'chatgpt']));
  const t = e && (e.access || e.token);
  const acc = e && e.accountId;
  if (!t) return null;
  try {
    const h = {
      Authorization: 'Bearer ' + t,
      'Content-Type': 'application/json',
    };
    if (acc) h['ChatGPT-Account-Id'] = acc;
    const res = await fetch('https://chatgpt.com/backend-api/wham/usage', {
      method: 'GET',
      headers: h,
    });
    if (!res.ok) {
      return bR({
        pId: 'codex',
        pName: 'Codex',
        ok: false,
        err:
          res.status === 401
            ? 'Session expired — please re-authenticate with OpenAI'
            : 'API error: ' + res.status,
      });
    }
    const d = await res.json();
    const p = d && d.rate_limit ? d.rate_limit.primary_window : null;
    const s = d && d.rate_limit ? d.rate_limit.secondary_window : null;
    const cr = d && d.credits ? d.credits : null;
    const w = {};
    if (p) {
      w['5h'] = tUW({
        uP: toN(p.used_percent),
        wS: toN(p.limit_window_seconds),
        rA: toTs(p.reset_at),
      });
    }
    if (s) {
      w.weekly = tUW({
        uP: toN(s.used_percent),
        wS: toN(s.limit_window_seconds),
        rA: toTs(s.reset_at),
      });
    }
    if (cr) {
      const bal = toN(cr.balance);
      const lab = cr.unlimited ? 'Unlimited' : bal !== null ? '$' + bal.toFixed(2) + ' remaining' : null;
      w.credits = tUW({ uP: null, wS: null, rA: null, vL: lab });
    }
    return bR({ pId: 'codex', pName: 'Codex', ok: true, use: { windows: w } });
  } catch (err) {
    return bR({ pId: 'codex', pName: 'Codex', ok: false, err: err.message });
  }
}

function rGem(a) {
  const raw = nE(getE(a, ['google', 'google.oauth']));
  const eo = asO(raw);
  if (!eo) return null;
  const oo = asO(eo.oauth) || eo;
  const at = pickS(oo.access, oo.token, eo.access, eo.token);
  const rp = pgR(oo.refresh);
  const gc = gCred(oo, 'GEMINI');
  const ec = gCred(eo, 'GEMINI');
  if (!at && !rp.refreshToken) return null;
  return {
    sourceId: 'gemini',
    sourceLabel: 'Gemini',
    accessToken: at,
    refreshToken: rp.refreshToken,
    projectId: pickS(
      oo.projectId,
      oo.managedProjectId,
      eo.projectId,
      eo.managedProjectId,
      rp.projectId,
      rp.managedProjectId,
    ),
    expires: toTs(oo.expires || eo.expires),
    clientId: pickS(gc.clientId, ec.clientId),
    clientSecret: pickS(gc.clientSecret, ec.clientSecret),
  };
}

function rAnti() {
  for (const f of AG) {
    const data = rJson(f);
    const root = asO(data);
    const accs = Array.isArray(root && root.accounts) ? root.accounts : [];
    if (!accs.length) continue;
    const idx = typeof (root && root.activeIndex) === 'number' ? root.activeIndex : 0;
    const acc = asO(accs[idx]) || asO(accs[0]);
    if (!acc) continue;
    const at = pickS(acc.accessToken, acc.access);
    const rp = pgR(acc.refreshToken);
    const ac = gCred(acc, 'ANTIGRAVITY');
    const rc = gCred(root, 'ANTIGRAVITY');
    if (!at && !rp.refreshToken) continue;
    return {
      sourceId: 'antigravity',
      sourceLabel: 'Antigravity',
      accessToken: at,
      refreshToken: rp.refreshToken,
      projectId: pickS(
        acc.projectId,
        acc.managedProjectId,
        rp.projectId,
        rp.managedProjectId,
      ),
      expires: toTs(acc.expires),
      clientId: pickS(ac.clientId, rc.clientId),
      clientSecret: pickS(ac.clientSecret, rc.clientSecret),
      email: pickS(acc.email),
    };
  }
  return null;
}

async function rGAccess(src) {
  if (src.accessToken && (!(typeof src.expires === 'number') || src.expires > Date.now())) {
    return src.accessToken;
  }
  if (!src.refreshToken || !src.clientId || !src.clientSecret) {
    return null;
  }
  try {
    const res = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        client_id: src.clientId,
        client_secret: src.clientSecret,
        refresh_token: src.refreshToken,
        grant_type: 'refresh_token',
      }),
    });
    if (!res.ok) return null;
    const d = await res.json();
    return asS(d && d.access_token);
  } catch {
    return null;
  }
}

async function fGM(src) {
  const projectId = src.projectId || GDP;
  const body = { project: projectId };
  for (const ep of GEP) {
    try {
      const ac = typeof AbortController !== 'undefined' ? new AbortController() : null;
      const tm = ac ? setTimeout(() => ac.abort(), 15000) : null;
      const res = await fetch(ep + '/v1internal:fetchAvailableModels', {
        method: 'POST',
        headers: Object.assign({
          Authorization: 'Bearer ' + src.accessToken,
          'Content-Type': 'application/json',
        }, GHD),
        body: JSON.stringify(body),
        signal: ac && ac.signal,
      });
      if (tm) clearTimeout(tm);
      if (res.ok) return await res.json();
    } catch {}
  }
  return null;
}

async function fGQB(src) {
  if (src.sourceId !== 'gemini') return null;
  const projectId = src.projectId || GDP;
  const body = { project: projectId };
  try {
    const ac = typeof AbortController !== 'undefined' ? new AbortController() : null;
    const tm = ac ? setTimeout(() => ac.abort(), 15000) : null;
    const res = await fetch('https://cloudcode-pa.googleapis.com/v1internal:retrieveUserQuota', {
      method: 'POST',
      headers: {
        Authorization: 'Bearer ' + src.accessToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
      signal: ac && ac.signal,
    });
    if (tm) clearTimeout(tm);
    if (!res.ok) return null;
    return await res.json();
  } catch {
    return null;
  }
}

async function fG(a) {
  const srcs = [];
  const gm = rGem(a);
  if (gm) srcs.push(gm);
  const ag = rAnti();
  if (ag) srcs.push(ag);
  if (!srcs.length) return null;

  const models = {};
  const errs = [];
  for (const src of srcs) {
    const token = await rGAccess(src);
    if (!token) {
      errs.push(src.sourceLabel + ': Missing usable host OAuth data (' + gDiag(src) + ')');
      continue;
    }
    src.accessToken = token;
    let merged = false;
    if (src.sourceId === 'gemini') {
      const qp = await fGQB(src);
      const buckets = Array.isArray(qp && qp.buckets) ? qp.buckets : [];
      for (const b of buckets) {
        const modelId = pickS(b && b.modelId);
        if (!modelId) continue;
        const remF = toN(b && b.remainingFraction);
        const remP = remF !== null ? Math.round(remF * 100) : null;
        const used = remP !== null ? Math.max(0, 100 - remP) : null;
        const rA = toTs(b && b.resetTime);
        const w = gWin(src.sourceId, rA);
        const scoped = modelId.startsWith(src.sourceId + '/')
          ? modelId
          : src.sourceId + '/' + modelId;
        models[scoped] = { windows: {} };
        models[scoped].windows[w.label] = tUW({
          uP: used,
          wS: w.seconds,
          rA: rA,
        });
        merged = true;
      }
    }
    const mp = await fGM(src);
    const raw = mp && typeof mp === 'object' && mp.models && typeof mp.models === 'object' ? mp.models : {};
    for (const key of Object.keys(raw)) {
      const md = raw[key] || {};
      const qi = md && md.quotaInfo && typeof md.quotaInfo === 'object' ? md.quotaInfo : {};
      const remF = toN(qi.remainingFraction);
      const remP = remF !== null ? Math.round(remF * 100) : null;
      const used = remP !== null ? Math.max(0, 100 - remP) : null;
      const rA = toTs(qi.resetTime);
      const w = gWin(src.sourceId, rA);
      const scoped = key.startsWith(src.sourceId + '/') ? key : src.sourceId + '/' + key;
      models[scoped] = {
        windows: {},
      };
      models[scoped].windows[w.label] = tUW({ uP: used, wS: w.seconds, rA: rA });
      merged = true;
    }
    if (!merged) errs.push(src.sourceLabel + ': No quota models visible');
  }

  if (!Object.keys(models).length) {
    return bR({
      pId: 'google',
      pName: 'Google',
      ok: false,
      err: errs[0] || 'Failed to fetch Google quota',
    });
  }
  return bR({
    pId: 'google',
    pName: 'Google',
    ok: true,
    use: {
      windows: {},
      models: models,
    },
  });
}

async function fGH(a) {
  const e = nE(getE(a, ['github-copilot', 'copilot']));
  const t = e && (e.access || e.token);
  if (!t) return null;
  try {
    const res = await fetch('https://api.github.com/copilot_internal/user', {
      headers: {
        Authorization: 'token ' + t,
        Accept: 'application/json',
        'Editor-Version': 'vscode/1.96.2',
        'X-Github-Api-Version': '2025-04-01',
      },
    });
    if (!res.ok) {
      return bR({
        pId: 'github-copilot',
        pName: 'GitHub Copilot',
        ok: false,
        err: 'API error: ' + res.status,
      });
    }
    const d = await res.json();
    const q = d && d.quota_snapshots ? d.quota_snapshots : {};
    const rA = toTs(d && d.quota_reset_date);
    const w = {};
    const aw = (l, s) => {
      if (!s) return;
      const en = toN(s.entitlement);
      const re = toN(s.remaining);
      const uP = en !== null && re !== null && en > 0 ? Math.max(0, 100 - (re / en) * 100) : null;
      const vL = en !== null && re !== null ? re.toFixed(0) + ' / ' + en.toFixed(0) + ' left' : null;
      w[l] = tUW({ uP: uP, wS: null, rA: rA, vL: vL });
    };
    aw('chat', q.chat);
    aw('completions', q.completions);
    aw('premium', q.premium_interactions);
    return bR({ pId: 'github-copilot', pName: 'GitHub Copilot', ok: true, use: { windows: w } });
  } catch (err) {
    return bR({ pId: 'github-copilot', pName: 'GitHub Copilot', ok: false, err: err.message });
  }
}

function nOC(v) {
  if (typeof v !== 'string') return null;
  const t = v.trim();
  if (!t) return null;
  // Normalize browser-copied values without treating base64 padding as a cookie name.
  if (t.indexOf('auth=') === 0) return t;
  return 'auth=' + t;
}

function sHC(h) {
  if (typeof h !== 'string') return h;
  return h.replace(/<!--[^]*?-->/g, '');
}

function nTx(v) {
  if (typeof v !== 'string') return v;
  return v.replace(/\s+/g, ' ').trim();
}

function pRD(v) {
  if (typeof v !== 'string') return null;
  const t = v.trim().toLowerCase();
  if (!t) return null;
  if (t.indexOf('few seconds') !== -1) return 15;
  const ms = Array.from(t.matchAll(/(\d+)\s+(day|days|hour|hours|minute|minutes)/g));
  if (!ms.length) return null;
  let total = 0;
  for (const m of ms) {
    const amt = Number(m[1]);
    if (!Number.isFinite(amt)) continue;
    const u = m[2];
    if (u.indexOf('day') === 0) total += amt * 86400;
    else if (u.indexOf('hour') === 0) total += amt * 3600;
    else if (u.indexOf('minute') === 0) total += amt * 60;
  }
  return total > 0 ? total : null;
}

function pDH(h) {
  if (typeof h !== 'string' || h.indexOf('You are subscribed to OpenCode Go.') === -1) return null;
  const sh = sHC(h);
  const sm = sh.match(/<div data-slot="usage">([\s\S]*?)<\/div><form action=/);
  if (!sm) return null;
  const u = {};
  const ims = Array.from(sm[1].matchAll(
    /<div data-slot="usage-item">[\s\S]*?<span data-slot="usage-label">([^<]+)<\/span><span data-slot="usage-value">(\d+)%<\/span>[\s\S]*?<span data-slot="reset-time">\s*Resets in\s*([^<]+)<\/span>[\s\S]*?<\/div>/g,
  ));
  for (const im of ims) {
    const label = nTx(im[1] || '').toLowerCase();
    let key = null;
    if (label === 'rolling usage') key = 'rolling';
    if (label === 'weekly usage') key = 'weekly';
    if (label === 'monthly usage') key = 'monthly';
    if (!key) continue;
    const used = toN(im[2]);
    const resetAfter = pRD(nTx(im[3] || ''));
    u[key] = {
      usedPercent: used,
      resetAt: resetAfter !== null ? Date.now() + resetAfter * 1000 : null,
    };
  }
  if (!u.rolling || !u.weekly || !u.monthly) return null;
  return u;
}

async function fOCG(a) {
  const e = nE(getE(a, ['opencode-go']));
  const k = e && (e.key || e.access || e.token);
  if (!k) return null;
  try {
    const vRes = await fetch('https://opencode.ai/zen/go/v1/models', {
      method: 'GET',
      headers: { Authorization: 'Bearer ' + k, Accept: 'application/json' },
    });
    if (!vRes.ok) {
      return bR({ pId: 'opencode-go', pName: 'OpenCode Go', ok: false, err: 'API error: ' + vRes.status });
    }
    const wsId = fromB64(OCG_WS_B64) || asS(process.env.OPENCODE_GO_WORKSPACE_ID);
    const rawCk = fromB64(OCG_CK_B64) || asS(process.env.OPENCODE_GO_AUTH_COOKIE) || asS(process.env.OPENCODE_GO_SESSION_COOKIE);
    if (!wsId || !rawCk) {
      return bR({
        pId: 'opencode-go',
        pName: 'OpenCode Go',
        ok: false,
        err: 'OpenCode Go is configured, but subscription usage requires OPENCODE_GO_WORKSPACE_ID and OPENCODE_GO_AUTH_COOKIE env vars on the host.',
      });
    }
    const ck = nOC(rawCk);
    if (!ck) {
      return bR({ pId: 'opencode-go', pName: 'OpenCode Go', ok: false, err: 'Invalid session cookie.' });
    }
    const dRes = await fetch('https://opencode.ai/workspace/' + encodeURIComponent(wsId) + '/go', {
      method: 'GET',
      headers: { Accept: 'text/html,application/xhtml+xml', Cookie: ck },
    });
    const payload = await dRes.text().catch(function() { return null; });
    if (!dRes.ok) {
      const msg = typeof payload === 'string' && payload.indexOf('/auth/authorize') !== -1
        ? 'Dashboard session is not authorized for this workspace'
        : 'Dashboard API error: ' + dRes.status;
      return bR({ pId: 'opencode-go', pName: 'OpenCode Go', ok: false, err: msg });
    }
    const sub = pDH(payload);
    if (!sub) {
      return bR({ pId: 'opencode-go', pName: 'OpenCode Go', ok: false, err: 'Failed to parse OpenCode Go subscription usage from dashboard page.' });
    }
    const w = {};
    w.rolling = tUW({ uP: sub.rolling.usedPercent, wS: null, rA: sub.rolling.resetAt });
    w.weekly = tUW({ uP: sub.weekly.usedPercent, wS: 7 * 86400, rA: sub.weekly.resetAt });
    w.monthly = tUW({ uP: sub.monthly.usedPercent, wS: 30 * 86400, rA: sub.monthly.resetAt });
    return bR({ pId: 'opencode-go', pName: 'OpenCode Go', ok: true, use: { windows: w } });
  } catch (err) {
    return bR({ pId: 'opencode-go', pName: 'OpenCode Go', ok: false, err: err.message });
  }
}

(async () => {
  const a = rAuth();
  const authKeys = Object.keys(a);
  const R = [];
  const c = await fC(a);
  if (c) R.push(c);
  const o = await fO(a);
  if (o) R.push(o);
  const x = await fX(a);
  if (x) R.push(x);
  const g = await fG(a);
  if (g) R.push(g);
  const gh = await fGH(a);
  if (gh) R.push(gh);
  const ocg = await fOCG(a);
  if (ocg) R.push(ocg);
  const unsupported = authKeys.filter(
    (k) =>
      !['anthropic', 'claude', 'openrouter', 'openai', 'codex', 'chatgpt', 'google', 'google.oauth', 'github-copilot', 'copilot', 'opencode-go'].includes(k),
  );
  console.log(
    P +
      JSON.stringify({
        results: R,
        meta: {
          authKeys: authKeys,
          unsupportedConfigured: unsupported,
          resultProviderIds: R.map((r) => r.providerId),
        },
      }),
  );
})().catch((err) => {
  console.log(P + JSON.stringify({ results: [], meta: { error: String(err) } }));
});
''';

    final hydratedScript = jsScript
        .replaceAll('__OCG_WS_B64__', openCodeGoWorkspaceIdB64)
        .replaceAll('__OCG_CK_B64__', openCodeGoAuthCookieB64);
    final b64 = base64Encode(utf8.encode(hydratedScript));
    // Single-line command — avoids multiline if/fi that OpenCode's eval truncates.
    return "node -e \"eval(Buffer.from('$b64','base64').toString('utf8'))\""
        " || printf '%s\\n' '$_shellPrefix{\"results\":[]}'";
  }
}
