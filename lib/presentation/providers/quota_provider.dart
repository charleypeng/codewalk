import 'package:flutter/foundation.dart';

import '../../core/logging/app_logger.dart';
import '../../data/datasources/quota_remote_datasource.dart';
import '../../domain/entities/quota.dart';
import '../utils/quota_pace_utils.dart';

class QuotaProvider extends ChangeNotifier {
  QuotaProvider({required QuotaRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final QuotaRemoteDataSource _remoteDataSource;

  static const Duration _cacheTtl = Duration(seconds: 60);

  String? _serverId;
  bool _isLoading = false;
  DateTime? _lastFetchedAt;
  List<QuotaProviderResult> _results = const <QuotaProviderResult>[];

  bool get isLoading => _isLoading;
  DateTime? get lastFetchedAt => _lastFetchedAt;
  List<QuotaProviderResult> get results =>
      List<QuotaProviderResult>.unmodifiable(_results);

  bool get hasAnyQuotaData => groups.isNotEmpty;

  List<QuotaProviderGroup> get groups {
    final built = _results
        .where((result) => result.hasVisibleData)
        .map(_buildGroup)
        .where((group) => group.entries.isNotEmpty)
        .toList(growable: false);
    built.sort(
      (left, right) => right.criticalEntry.severityScore.compareTo(
        left.criticalEntry.severityScore,
      ),
    );
    return built;
  }

  Future<void> ensureLoaded({
    required String? serverId,
    bool force = false,
  }) async {
    final normalizedServerId = serverId?.trim();
    AppLogger.info(
      '[Quota] ensureLoaded called — serverId=$normalizedServerId '
      'force=$force isLoading=$_isLoading',
    );
    if (normalizedServerId == null || normalizedServerId.isEmpty) {
      AppLogger.info('[Quota] ensureLoaded abort: serverId is null/empty');
      if (_serverId != null || _results.isNotEmpty || _lastFetchedAt != null) {
        _serverId = null;
        _results = const <QuotaProviderResult>[];
        _lastFetchedAt = null;
        _isLoading = false;
        notifyListeners();
      }
      return;
    }

    final serverChanged = _serverId != normalizedServerId;
    if (serverChanged) {
      _serverId = normalizedServerId;
      _results = const <QuotaProviderResult>[];
      _lastFetchedAt = null;
    }

    if (_isLoading) {
      AppLogger.info('[Quota] ensureLoaded abort: already loading');
      return;
    }

    final now = DateTime.now();
    final isFresh =
        !force &&
        !serverChanged &&
        _lastFetchedAt != null &&
        now.difference(_lastFetchedAt!) < _cacheTtl;
    if (isFresh) {
      AppLogger.info('[Quota] ensureLoaded abort: cache still fresh');
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      AppLogger.info('[Quota] ensureLoaded: starting fetch...');
      _results = await _remoteDataSource.fetchQuotaResults();
      _lastFetchedAt = DateTime.now();
      AppLogger.info(
        '[Quota] ensureLoaded: fetch complete — '
        '${_results.length} results, ${groups.length} visible groups',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  QuotaProviderGroup _buildGroup(QuotaProviderResult result) {
    final entries = <QuotaEntry>[];
    final usage = result.usage;
    if (usage == null) {
      return QuotaProviderGroup(
        providerId: result.providerId,
        providerName: result.providerName,
        entries: const <QuotaEntry>[],
      );
    }

    usage.windows.forEach((windowLabel, window) {
      final label = usage.windows.length == 1 && usage.models.isEmpty
          ? result.providerName
          : formatWindowLabel(windowLabel);
      final entry = _buildEntry(
        result: result,
        label: label,
        window: window,
        windowLabel: windowLabel,
      );
      if (entry != null) {
        entries.add(entry);
      }
    });

    usage.models.forEach((modelName, modelUsage) {
      modelUsage.windows.forEach((windowLabel, window) {
        final prettyWindow = formatWindowLabel(windowLabel);
        final label = modelUsage.windows.length > 1
            ? '$modelName · $prettyWindow'
            : modelName;
        final entry = _buildEntry(
          result: result,
          label: label,
          window: window,
          windowLabel: windowLabel,
        );
        if (entry != null) {
          entries.add(entry);
        }
      });
    });

    entries.sort(
      (left, right) => right.severityScore.compareTo(left.severityScore),
    );

    return QuotaProviderGroup(
      providerId: result.providerId,
      providerName: result.providerName,
      entries: entries,
    );
  }

  QuotaEntry? _buildEntry({
    required QuotaProviderResult result,
    required String label,
    required UsageWindow window,
    required String windowLabel,
  }) {
    if (!window.hasVisibleData) {
      return null;
    }
    final paceInfo = calculatePace(
      usedPercent: window.usedPercent,
      resetAt: window.resetAt,
      windowSeconds: window.windowSeconds,
      windowLabel: windowLabel,
    );
    return QuotaEntry(
      providerId: result.providerId,
      providerName: result.providerName,
      label: label,
      usedPercent: window.usedPercent,
      remainingPercent: window.remainingPercent,
      windowSeconds: window.windowSeconds,
      resetAfterSeconds: window.resetAfterSeconds,
      resetAt: window.resetAt,
      valueLabel: window.valueLabel,
      paceInfo: paceInfo,
    );
  }
}
