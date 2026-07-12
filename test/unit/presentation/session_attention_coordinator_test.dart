import 'package:codewalk/domain/entities/experience_settings.dart';
import 'package:codewalk/domain/entities/session_attention_overlay/session_attention_models.dart';
import 'package:codewalk/presentation/services/cellular_data_saver_service.dart';
import 'package:codewalk/presentation/services/session_attention/session_attention_coordinator.dart';
import 'package:codewalk/presentation/services/session_attention/session_attention_delay_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const identity = SessionAttentionIdentity(
    serverId: 'server-a',
    directory: '/work/app',
    rootSessionId: 'root-1',
  );
  const otherIdentity = SessionAttentionIdentity(
    serverId: 'server-a',
    directory: '/work/other',
    rootSessionId: 'root-2',
  );

  test(
    'cellular background pauses monitoring and reconciliation resumes it',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      final saver = CellularDataSaverService(
        sharedPreferences: preferences,
        startMonitoring: false,
      );
      saver.applyLevel(DataSaverLevel.standard);
      saver.debugSetTransport(DataSaverTransport.cellular);
      saver.setAppForeground(true);
      var now = DateTime.utc(2026, 7, 12);
      final coordinator = SessionAttentionCoordinator(
        cellularDataSaverService: saver,
        delayCoordinator: SessionAttentionDelayCoordinator(clock: () => now),
      );
      addTearDown(coordinator.dispose);
      addTearDown(saver.dispose);

      coordinator.observe(identity: identity, busy: true);
      now = now.add(const Duration(minutes: 2));
      coordinator.observe(identity: identity, busy: true);

      saver.setAppForeground(false);
      expect(coordinator.monitoringPaused, isTrue);
      expect(
        coordinator.pauseReason,
        SessionAttentionPauseReason.cellularDataSaver,
      );
      now = now.add(const Duration(minutes: 20));
      coordinator.observe(identity: identity, busy: true);
      expect(
        coordinator.timingFor(identity).observableBusyElapsed,
        const Duration(minutes: 2),
      );

      saver.setAppForeground(true);
      expect(coordinator.monitoringPaused, isTrue);
      expect(coordinator.reconciliationGeneration, 1);
      coordinator.markMonitoringReconciled(directory: identity.directory);
      expect(coordinator.monitoringPaused, isFalse);
      now = now.add(const Duration(minutes: 3));
      final resumed = coordinator.observe(identity: identity, busy: true);
      expect(resumed.observableBusyElapsed, const Duration(minutes: 5));
      expect(resumed.delayed, isTrue);
    },
  );

  test('offline time stays paused until a valid reconciliation', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final saver = CellularDataSaverService(
      sharedPreferences: preferences,
      startMonitoring: false,
    );
    var now = DateTime.utc(2026, 7, 12);
    final coordinator = SessionAttentionCoordinator(
      cellularDataSaverService: saver,
      delayCoordinator: SessionAttentionDelayCoordinator(clock: () => now),
    );
    addTearDown(coordinator.dispose);
    addTearDown(saver.dispose);

    coordinator.observe(identity: identity, busy: true);
    now = now.add(const Duration(minutes: 2));
    coordinator.observe(identity: identity, busy: true);
    coordinator.pauseMonitoring(SessionAttentionPauseReason.offline);
    now = now.add(const Duration(minutes: 20));
    coordinator.observe(identity: identity, busy: true);

    expect(
      coordinator.timingFor(identity).observableBusyElapsed,
      const Duration(minutes: 2),
    );
    coordinator.markMonitoringReconciled(directory: identity.directory);
    now = now.add(const Duration(minutes: 3));
    final resumed = coordinator.observe(identity: identity, busy: true);
    expect(resumed.observableBusyElapsed, const Duration(minutes: 5));
    expect(resumed.delayed, isTrue);

    final unreconciled = coordinator.observe(
      identity: otherIdentity,
      busy: true,
    );
    expect(unreconciled.monitoringPaused, isTrue);
  });

  test('Wi-Fi and saver off do not suppress automatic monitoring', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final saver = CellularDataSaverService(
      sharedPreferences: preferences,
      startMonitoring: false,
    );
    final coordinator = SessionAttentionCoordinator(
      cellularDataSaverService: saver,
    );
    addTearDown(coordinator.dispose);
    addTearDown(saver.dispose);
    coordinator.observe(identity: identity, busy: true);

    saver.applyLevel(DataSaverLevel.aggressive);
    saver.debugSetTransport(DataSaverTransport.other);
    saver.setAppForeground(false);
    expect(coordinator.automaticMonitoringPermitted, isTrue);

    saver.debugSetTransport(DataSaverTransport.cellular);
    saver.applyLevel(DataSaverLevel.off);
    expect(coordinator.automaticMonitoringPermitted, isFalse);
    coordinator.markMonitoringReconciled(directory: identity.directory);
    expect(coordinator.automaticMonitoringPermitted, isTrue);
  });
}
