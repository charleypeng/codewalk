import 'package:codewalk/domain/entities/experience_settings.dart';
import 'package:codewalk/presentation/services/cellular_data_saver_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CellularDataSaverService', () {
    test(
      'activates only when cellular transport and setting are both true',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final prefs = await SharedPreferences.getInstance();
        final service = CellularDataSaverService(
          sharedPreferences: prefs,
          startMonitoring: false,
        );
        addTearDown(service.dispose);

        service.debugSetDataSaverEnabled(true);
        service.debugSetTransport(DataSaverTransport.cellular);
        expect(service.isDataSaverActive, isTrue);

        service.debugSetTransport(DataSaverTransport.other);
        expect(service.isDataSaverActive, isFalse);
      },
    );

    test('aggressive tier stretches sync and burst intervals', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final service = CellularDataSaverService(
        sharedPreferences: prefs,
        startMonitoring: false,
      );
      addTearDown(service.dispose);

      service.debugSetDataSaverLevel(DataSaverLevel.aggressive);
      service.debugSetTransport(DataSaverTransport.cellular);

      expect(service.isDataSaverActive, isTrue);
      expect(service.isAggressiveDataSaverActive, isTrue);
      expect(service.automaticSyncInterval, const Duration(minutes: 5));

      service.noteExplicitUserAction(reason: 'manual-refresh');

      expect(service.hasInteractiveBurst, isTrue);
    });

    test(
      'blocks automatic foreground syncs inside the cooldown window',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final prefs = await SharedPreferences.getInstance();
        final service = CellularDataSaverService(
          sharedPreferences: prefs,
          startMonitoring: false,
        );
        addTearDown(service.dispose);

        service.debugSetDataSaverEnabled(true);
        service.debugSetTransport(DataSaverTransport.cellular);

        expect(
          service.allowAutomaticForegroundSync(reason: 'first-tick'),
          isTrue,
        );
        expect(
          service.allowAutomaticForegroundSync(reason: 'second-tick'),
          isFalse,
        );
      },
    );

    test('explicit user action opens an interactive burst', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final service = CellularDataSaverService(
        sharedPreferences: prefs,
        startMonitoring: false,
      );
      addTearDown(service.dispose);

      service.debugSetDataSaverEnabled(true);
      service.debugSetTransport(DataSaverTransport.cellular);

      service.noteExplicitUserAction(reason: 'manual-refresh');

      expect(service.hasInteractiveBurst, isTrue);
      expect(service.shouldDisableBackgroundNetworkTasks, isTrue);
    });
  });
}
