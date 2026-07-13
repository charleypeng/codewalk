import 'package:flutter/foundation.dart';

import '../../../domain/entities/session_attention_overlay/session_attention_models.dart';
import '../cellular_data_saver_service.dart';
import 'session_attention_delay_coordinator.dart';

class SessionAttentionCoordinator extends ChangeNotifier {
  SessionAttentionCoordinator({
    required CellularDataSaverService cellularDataSaverService,
    SessionAttentionDelayCoordinator? delayCoordinator,
  }) : _cellularDataSaverService = cellularDataSaverService,
       _delayCoordinator =
           delayCoordinator ?? SessionAttentionDelayCoordinator(),
       _dataSaverPaused = cellularDataSaverService.shouldSuppressBackgroundWork,
       _awaitingReconciliation =
           cellularDataSaverService.shouldSuppressBackgroundWork {
    _cellularDataSaverService.addListener(_handleDataSaverChanged);
  }

  final CellularDataSaverService _cellularDataSaverService;
  final SessionAttentionDelayCoordinator _delayCoordinator;
  final Set<SessionAttentionIdentity> _trackedIdentities =
      <SessionAttentionIdentity>{};
  final Map<SessionAttentionIdentity, SessionAttentionTimingState> _timingById =
      <SessionAttentionIdentity, SessionAttentionTimingState>{};
  final Set<String> _reconciledDirectories = <String>{};

  bool _dataSaverPaused;
  SessionAttentionPauseReason? _transportPauseReason;
  bool _awaitingReconciliation;
  int _reconciliationGeneration = 0;

  bool get monitoringPaused =>
      _dataSaverPaused ||
      _transportPauseReason != null ||
      (_awaitingReconciliation &&
          _trackedIdentities.any(
            (identity) => !_reconciledDirectories.contains(identity.directory),
          ));

  SessionAttentionPauseReason? get pauseReason => !monitoringPaused
      ? null
      : _dataSaverPaused
      ? SessionAttentionPauseReason.cellularDataSaver
      : _transportPauseReason ?? SessionAttentionPauseReason.hostUnavailable;

  bool get automaticMonitoringPermitted => !monitoringPaused;
  int get reconciliationGeneration => _reconciliationGeneration;
  Duration get delayedThreshold => _delayCoordinator.delayedThreshold;

  SessionAttentionTimingState timingFor(SessionAttentionIdentity identity) {
    return _timingById[identity] ??
        const SessionAttentionTimingState(
          observableBusyElapsed: Duration.zero,
          totalBusyElapsed: Duration.zero,
          delayed: false,
          monitoringPaused: false,
        );
  }

  SessionAttentionTimingState observe({
    required SessionAttentionIdentity identity,
    required bool busy,
    bool progressObserved = false,
  }) {
    _trackedIdentities.add(identity);
    final identityPaused =
        _dataSaverPaused ||
        _transportPauseReason != null ||
        (_awaitingReconciliation &&
            !_reconciledDirectories.contains(identity.directory));
    final state = identityPaused
        ? _delayCoordinator.pause(identity, pauseReason!)
        : _delayCoordinator.observe(
            identity: identity,
            busy: busy,
            monitoringPermittedForInterval: true,
            progressObserved: progressObserved,
          );
    _timingById[identity] = state;
    return state;
  }

  void noteExplicitUserAction({required String reason}) {
    _cellularDataSaverService.noteExplicitUserAction(reason: reason);
  }

  void pauseMonitoring(SessionAttentionPauseReason reason) {
    _transportPauseReason = reason;
    _awaitingReconciliation = true;
    _reconciledDirectories.clear();
    _pauseTrackedIdentities(reason);
    notifyListeners();
  }

  void markMonitoringReconciled({required String directory}) {
    if (_dataSaverPaused) {
      return;
    }
    final normalizedDirectory = directory.trim();
    if (normalizedDirectory.isEmpty) {
      return;
    }
    _transportPauseReason = null;
    _reconciledDirectories.add(normalizedDirectory);
    for (final identity in _trackedIdentities.where(
      (identity) => identity.directory == normalizedDirectory,
    )) {
      _timingById[identity] = _delayCoordinator.resume(identity);
    }
    notifyListeners();
  }

  void remove(SessionAttentionIdentity identity) {
    _trackedIdentities.remove(identity);
    _timingById.remove(identity);
    _delayCoordinator.remove(identity);
  }

  void retainIdentities(Set<SessionAttentionIdentity> identities) {
    final removed = _trackedIdentities.difference(identities).toList();
    for (final identity in removed) {
      remove(identity);
    }
  }

  void _handleDataSaverChanged() {
    final nextDataSaverPaused =
        _cellularDataSaverService.shouldSuppressBackgroundWork;
    if (_dataSaverPaused == nextDataSaverPaused) {
      return;
    }
    _dataSaverPaused = nextDataSaverPaused;
    _awaitingReconciliation = true;
    if (nextDataSaverPaused) {
      _reconciledDirectories.clear();
      _pauseTrackedIdentities(SessionAttentionPauseReason.cellularDataSaver);
    } else {
      _reconciliationGeneration += 1;
    }
    notifyListeners();
  }

  void _pauseTrackedIdentities(SessionAttentionPauseReason reason) {
    for (final identity in _trackedIdentities) {
      _timingById[identity] = _delayCoordinator.pause(identity, reason);
    }
  }

  @override
  void dispose() {
    _cellularDataSaverService.removeListener(_handleDataSaverChanged);
    super.dispose();
  }
}
