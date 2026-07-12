import 'package:codewalk/domain/entities/session_attention_overlay/session_attention_models.dart';
import 'package:codewalk/presentation/services/session_attention/session_attention_delay_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const identity = SessionAttentionIdentity(
    serverId: 'server-a',
    directory: '/work/app',
    rootSessionId: 'root-1',
  );

  test('marks delayed after five observable busy minutes', () {
    var now = DateTime.utc(2026, 7, 12);
    final coordinator = SessionAttentionDelayCoordinator(clock: () => now);

    coordinator.observe(
      identity: identity,
      busy: true,
      monitoringPermittedForInterval: true,
    );
    now = now.add(const Duration(minutes: 5));
    final state = coordinator.observe(
      identity: identity,
      busy: true,
      monitoringPermittedForInterval: true,
    );

    expect(state.observableBusyElapsed, const Duration(minutes: 5));
    expect(state.delayed, isTrue);
  });

  test('paused intervals add zero observable time', () {
    var now = DateTime.utc(2026, 7, 12);
    final coordinator = SessionAttentionDelayCoordinator(clock: () => now);

    coordinator.observe(
      identity: identity,
      busy: true,
      monitoringPermittedForInterval: true,
    );
    now = now.add(const Duration(minutes: 2));
    coordinator.observe(
      identity: identity,
      busy: true,
      monitoringPermittedForInterval: true,
    );
    coordinator.pause(identity, SessionAttentionPauseReason.cellularDataSaver);
    now = now.add(const Duration(minutes: 20));
    final resumed = coordinator.resume(identity);

    expect(resumed.observableBusyElapsed, const Duration(minutes: 2));
    expect(resumed.monitoringPaused, isFalse);
    expect(resumed.pauseReason, isNull);

    now = now.add(const Duration(minutes: 3));
    final delayed = coordinator.observe(
      identity: identity,
      busy: true,
      monitoringPermittedForInterval: true,
    );
    expect(delayed.observableBusyElapsed, const Duration(minutes: 5));
    expect(delayed.delayed, isTrue);
  });

  test('progress clears delayed window but preserves total busy time', () {
    var now = DateTime.utc(2026, 7, 12);
    final coordinator = SessionAttentionDelayCoordinator(clock: () => now);

    coordinator.observe(
      identity: identity,
      busy: true,
      monitoringPermittedForInterval: true,
    );
    now = now.add(const Duration(minutes: 5));
    coordinator.observe(
      identity: identity,
      busy: true,
      monitoringPermittedForInterval: true,
    );
    now = now.add(const Duration(minutes: 1));
    final progressed = coordinator.observe(
      identity: identity,
      busy: true,
      monitoringPermittedForInterval: true,
      progressObserved: true,
    );

    expect(progressed.delayed, isFalse);
    expect(progressed.observableBusyElapsed, Duration.zero);
    expect(progressed.totalBusyElapsed, const Duration(minutes: 6));
  });
}
