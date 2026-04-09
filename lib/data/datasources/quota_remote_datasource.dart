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
      AppLogger.debug('[Quota] REST path returned ${viaRest.length} results');
      return viaRest;
    }
    AppLogger.debug('[Quota] REST path unavailable, trying shell fallback');
    return _fetchViaShellFallback();
  }

  Future<List<QuotaProviderResult>?> _fetchViaOpenChamberRest() async {
    try {
      final response = await dio.get<dynamic>('/api/quota/providers');
      if (response.statusCode != 200) {
        AppLogger.debug(
          '[Quota] REST /api/quota/providers returned ${response.statusCode}',
        );
        return null;
      }
      final payload = response.data;
      if (payload is! Map) {
        AppLogger.debug('[Quota] REST payload is not a Map: ${payload.runtimeType}');
        return null;
      }
      final providers =
          (payload['providers'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<String>()
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false);
      if (providers.isEmpty) {
        AppLogger.debug('[Quota] REST returned empty providers list');
        return const <QuotaProviderResult>[];
      }
      AppLogger.debug('[Quota] REST found providers: $providers');
      final results = await Future.wait(
        providers.map(_fetchQuotaForProviderRest),
      );
      return results.whereType<QuotaProviderResult>().toList(growable: false);
    } on DioException catch (error) {
      // Any DioException means the REST endpoint is not available on this
      // host.  Return null so the strategy chain falls through to the shell
      // fallback instead of silently returning an empty list.
      AppLogger.debug(
        '[Quota] REST DioException (status=${error.response?.statusCode}): '
        '${error.type}',
      );
      return null;
    } catch (error) {
      AppLogger.debug('[Quota] REST unexpected error: $error');
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
        AppLogger.debug('[Quota] Shell fallback: failed to create session');
        return const <QuotaProviderResult>[];
      }
      AppLogger.debug('[Quota] Shell fallback: session $sessionId created');
      final response = await dio.post<dynamic>(
        '/session/$sessionId/shell',
        data: <String, dynamic>{
          'agent': 'build',
          'command': _buildQuotaShellCommand(),
        },
      );
      if (response.statusCode != 200 || response.data is! Map) {
        AppLogger.debug(
          '[Quota] Shell fallback: bad response '
          '(status=${response.statusCode}, '
          'type=${response.data.runtimeType})',
        );
        return const <QuotaProviderResult>[];
      }
      final envelope = Map<String, dynamic>.from(response.data as Map);
      final output = _extractShellJsonPayload(envelope);
      if (output == null) {
        AppLogger.debug(
          '[Quota] Shell fallback: no CW_QUOTA_JSON found in response. '
          'Keys: ${envelope.keys.toList()}',
        );
        return const <QuotaProviderResult>[];
      }
      final decoded = jsonDecode(output);
      if (decoded is! Map) {
        AppLogger.debug(
          '[Quota] Shell fallback: decoded payload is not a Map',
        );
        return const <QuotaProviderResult>[];
      }
      final results =
          decoded['results'] as List<dynamic>? ?? const <dynamic>[];
      AppLogger.debug(
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
      AppLogger.debug('[Quota] Shell fallback error: $error');
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
      if (map['type'] != 'text') {
        continue;
      }
      final text = map['text'];
      if (text is! String || text.trim().isEmpty) {
        continue;
      }
      for (final line in text.split('\n').reversed) {
        final trimmed = line.trim();
        if (trimmed.startsWith(_shellPrefix)) {
          return trimmed.substring(_shellPrefix.length);
        }
      }
    }
    return null;
  }

  String _buildQuotaShellCommand() {
    return '''if command -v node >/dev/null 2>&1; then
node <<'NODE'
const fs = require('fs');
const os = require('os');
const path = require('path');

const PREFIX = '$_shellPrefix';

function authPath() {
  const dataHome = process.env.XDG_DATA_HOME || path.join(os.homedir(), '.local', 'share');
  return path.join(dataHome, 'opencode', 'auth.json');
}

function readAuthFile() {
  try {
    const filePath = authPath();
    if (!fs.existsSync(filePath)) {
      return {};
    }
    const raw = fs.readFileSync(filePath, 'utf8').trim();
    if (!raw) {
      return {};
    }
    return JSON.parse(raw);
  } catch {
    return {};
  }
}

function getAuthEntry(auth, aliases) {
  for (const alias of aliases) {
    if (auth[alias]) {
      return auth[alias];
    }
  }
  return null;
}

function normalizeAuthEntry(entry) {
  if (!entry) return null;
  if (typeof entry === 'string') return { token: entry };
  if (typeof entry === 'object') return entry;
  return null;
}

function toNumber(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string') {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function toTimestamp(value) {
  if (!value) return null;
  const timestamp = new Date(value).getTime();
  return Number.isFinite(timestamp) ? timestamp : null;
}

function toUsageWindow({ usedPercent, windowSeconds, resetAt, valueLabel }) {
  const clamped = typeof usedPercent === 'number'
    ? Math.max(0, Math.min(100, usedPercent))
    : null;
  const resetAfterSeconds = typeof resetAt === 'number'
    ? Math.max(0, Math.round((resetAt - Date.now()) / 1000))
    : null;
  return {
    usedPercent: clamped,
    remainingPercent: clamped === null ? null : Math.max(0, 100 - clamped),
    windowSeconds: typeof windowSeconds === 'number' ? windowSeconds : null,
    resetAfterSeconds,
    resetAt: typeof resetAt === 'number' ? resetAt : null,
    resetAtFormatted: null,
    resetAfterFormatted: null,
    valueLabel: valueLabel ?? null,
  };
}

function buildResult({ providerId, providerName, ok, configured, usage, error }) {
  return {
    providerId,
    providerName,
    ok,
    configured,
    usage: usage ?? null,
    error: error ?? null,
    fetchedAt: Date.now(),
  };
}

async function fetchClaude(auth) {
  const entry = normalizeAuthEntry(getAuthEntry(auth, ['anthropic', 'claude']));
  const accessToken = entry && (entry.access || entry.token);
  if (!accessToken) return null;
  try {
    const response = await fetch('https://api.anthropic.com/api/oauth/usage', {
      method: 'GET',
      headers: {
        Authorization: 'Bearer ' + accessToken,
        'anthropic-beta': 'oauth-2025-04-20',
      },
    });
    if (!response.ok) {
      return buildResult({
        providerId: 'claude',
        providerName: 'Claude',
        ok: false,
        configured: true,
        error: 'API error: ' + response.status,
      });
    }
    const payload = await response.json();
    const windows = {};
    if (payload && payload.five_hour) {
      windows['5h'] = toUsageWindow({
        usedPercent: toNumber(payload.five_hour.utilization),
        windowSeconds: null,
        resetAt: toTimestamp(payload.five_hour.resets_at),
      });
    }
    if (payload && payload.seven_day) {
      windows['7d'] = toUsageWindow({
        usedPercent: toNumber(payload.seven_day.utilization),
        windowSeconds: null,
        resetAt: toTimestamp(payload.seven_day.resets_at),
      });
    }
    if (payload && payload.seven_day_sonnet) {
      windows['7d-sonnet'] = toUsageWindow({
        usedPercent: toNumber(payload.seven_day_sonnet.utilization),
        windowSeconds: null,
        resetAt: toTimestamp(payload.seven_day_sonnet.resets_at),
      });
    }
    if (payload && payload.seven_day_opus) {
      windows['7d-opus'] = toUsageWindow({
        usedPercent: toNumber(payload.seven_day_opus.utilization),
        windowSeconds: null,
        resetAt: toTimestamp(payload.seven_day_opus.resets_at),
      });
    }
    return buildResult({
      providerId: 'claude',
      providerName: 'Claude',
      ok: true,
      configured: true,
      usage: { windows },
    });
  } catch (error) {
    return buildResult({
      providerId: 'claude',
      providerName: 'Claude',
      ok: false,
      configured: true,
      error: error instanceof Error ? error.message : 'Request failed',
    });
  }
}

function formatMoney(value) {
  return Number(value).toFixed(2);
}

async function fetchOpenRouter(auth) {
  const entry = normalizeAuthEntry(getAuthEntry(auth, ['openrouter']));
  const apiKey = entry && (entry.key || entry.token);
  if (!apiKey) return null;
  try {
    const response = await fetch('https://openrouter.ai/api/v1/credits', {
      method: 'GET',
      headers: {
        Authorization: 'Bearer ' + apiKey,
        'Content-Type': 'application/json',
      },
    });
    if (!response.ok) {
      return buildResult({
        providerId: 'openrouter',
        providerName: 'OpenRouter',
        ok: false,
        configured: true,
        error: 'API error: ' + response.status,
      });
    }
    const payload = await response.json();
    const credits = payload && payload.data ? payload.data : {};
    const totalCredits = toNumber(credits.total_credits);
    const totalUsage = toNumber(credits.total_usage);
    const remaining = totalCredits !== null && totalUsage !== null
      ? Math.max(0, totalCredits - totalUsage)
      : null;
    const usedPercent = totalCredits && totalUsage !== null
      ? Math.max(0, Math.min(100, (totalUsage / totalCredits) * 100))
      : null;
    return buildResult({
      providerId: 'openrouter',
      providerName: 'OpenRouter',
      ok: true,
      configured: true,
      usage: {
        windows: {
          credits: toUsageWindow({
            usedPercent,
            windowSeconds: null,
            resetAt: null,
            valueLabel: remaining !== null ? '\$' + formatMoney(remaining) + ' remaining' : null,
          }),
        },
      },
    });
  } catch (error) {
    return buildResult({
      providerId: 'openrouter',
      providerName: 'OpenRouter',
      ok: false,
      configured: true,
      error: error instanceof Error ? error.message : 'Request failed',
    });
  }
}

(async () => {
  const auth = readAuthFile();
  const results = [];
  const claude = await fetchClaude(auth);
  if (claude) results.push(claude);
  const openrouter = await fetchOpenRouter(auth);
  if (openrouter) results.push(openrouter);
  console.log(PREFIX + JSON.stringify({ results }));
})().catch(() => {
  console.log(PREFIX + JSON.stringify({ results: [] }));
});
NODE
else
printf '%s\n' '$_shellPrefix{"results":[]}'
fi''';
  }
}
