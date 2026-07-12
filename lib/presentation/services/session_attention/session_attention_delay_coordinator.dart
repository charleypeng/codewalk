import 'package:flutter/foundation.dart';

import '../../../domain/entities/session_attention_overlay/session_attention_models.dart';

typedef SessionAttentionClock = DateTime Function();

@immutable
class SessionAttentionTimingState {
  const SessionAttentionTimingState({
    required this.observableBusyElapsed,
    required this.totalBusyElapsed,
    required this.delayed,
    required this.monitoringPaused,
    this.pauseReason,
  });

  final Duration observableBusyElapsed;
  final Duration totalBusyElapsed;
  final bool delayed;
  final bool monitoringPaused;
  final SessionAttentionPauseReason? pauseReason;
}

class SessionAttentionDelayCoordinator {
  SessionAttentionDelayCoordinator({
    SessionAttentionClock? clock,
    this.delayedThreshold = const Duration(minutes: 5),
  }) : _clock = clock ?? DateTime.now;

  final SessionAttentionClock _clock;
  final Duration delayedThreshold;
  final Map<SessionAttentionIdentity, _MutableTimingState> _states =
      <SessionAttentionIdentity, _MutableTimingState>{};

  SessionAttentionTimingState observe({
    required SessionAttentionIdentity identity,
    required bool busy,
    required bool monitoringPermittedForInterval,
    bool progressObserved = false,
  }) {
    final now = _clock();
    final state = _states.putIfAbsent(
      identity,
      () => _MutableTimingState(lastObservedAt: now),
    );
    final interval = now.isAfter(state.lastObservedAt)
        ? now.difference(state.lastObservedAt)
        : Duration.zero;

    if (state.busy && busy && monitoringPermittedForInterval) {
      state.observableBusyElapsed += interval;
      state.totalBusyElapsed += interval;
    }
    if (progressObserved) {
      state.observableBusyElapsed = Duration.zero;
    }

    state
      ..lastObservedAt = now
      ..busy = busy
      ..monitoringPaused = !monitoringPermittedForInterval
      ..pauseReason = monitoringPermittedForInterval ? null : state.pauseReason;
    if (!busy) {
      state.observableBusyElapsed = Duration.zero;
    }
    return _snapshot(state);
  }

  SessionAttentionTimingState pause(
    SessionAttentionIdentity identity,
    SessionAttentionPauseReason reason,
  ) {
    final now = _clock();
    final state = _states.putIfAbsent(
      identity,
      () => _MutableTimingState(lastObservedAt: now),
    );
    state
      ..lastObservedAt = now
      ..monitoringPaused = true
      ..pauseReason = reason;
    return _snapshot(state);
  }

  SessionAttentionTimingState resume(SessionAttentionIdentity identity) {
    final now = _clock();
    final state = _states.putIfAbsent(
      identity,
      () => _MutableTimingState(lastObservedAt: now),
    );
    state
      ..lastObservedAt = now
      ..monitoringPaused = false
      ..pauseReason = null;
    return _snapshot(state);
  }

  void remove(SessionAttentionIdentity identity) => _states.remove(identity);

  SessionAttentionTimingState _snapshot(_MutableTimingState state) {
    return SessionAttentionTimingState(
      observableBusyElapsed: state.observableBusyElapsed,
      totalBusyElapsed: state.totalBusyElapsed,
      delayed: state.observableBusyElapsed >= delayedThreshold,
      monitoringPaused: state.monitoringPaused,
      pauseReason: state.pauseReason,
    );
  }
}

class _MutableTimingState {
  _MutableTimingState({required this.lastObservedAt});

  DateTime lastObservedAt;
  Duration observableBusyElapsed = Duration.zero;
  Duration totalBusyElapsed = Duration.zero;
  bool busy = false;
  bool monitoringPaused = false;
  SessionAttentionPauseReason? pauseReason;
}
