import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/state_aware_service.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StateAwareService', () {
    const settingsKey = 'state_aware_settings';
    late StateAwareService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LoggerService.initialize();
      await StorageGateway.instance.initialize(databaseName: 'test_state_aware_service_test.db');
      await StorageGateway.instance.delete(settingsKey);
      StorageGateway.instance.integrityReporter.clearReports();
      service = StateAwareService(
        appState: logic.AppStateManagerImpl.create(config: const logic.AppStateConfig()),
        storage: StorageGateway.instance,
        logger: LoggerService.forModule('StateAwareServiceTest'),
      );
    });

    test('should return default settings when nothing is stored', () async {
      final result = await service.getSettings();

      final settings = result.getOrThrow();
      expect(settings.forceSync, isFalse);
      expect(settings.syncPolicy, SyncPolicy.wifiOnly);
    });

    test('should persist settings and read them back', () async {
      const saved = StateAwareSettings(forceSync: true, syncPolicy: SyncPolicy.wifiOrCellular);

      final saveResult = await service.saveSettings(saved);
      final settings = (await service.getSettings()).getOrThrow();

      expect(saveResult.isSuccess, isTrue);
      expect(settings.forceSync, isTrue);
      expect(settings.syncPolicy, SyncPolicy.wifiOrCellular);
    });

    test('should fall back to defaults and report when stored settings are corrupt', () async {
      await StorageGateway.instance.save(key: settingsKey, value: 'not a map');

      final result = await service.getSettings();

      expect(result.isSuccess, isTrue);
      expect(result.data!.syncPolicy, SyncPolicy.wifiOnly);
      expect(
        StorageGateway.instance.integrityReporter.reports.map((report) => report.recordId),
        contains(settingsKey),
      );
    });

    test('should default unknown or mistyped fields when parsing settings json', () {
      final settings = StateAwareSettings.fromJson(<String, dynamic>{
        'forceSync': 'yes',
        'disableBatteryOptimization': 1,
        'syncPolicy': 'satellite',
      });

      expect(settings.forceSync, isFalse);
      expect(settings.disableBatteryOptimization, isTrue);
      expect(settings.syncPolicy, SyncPolicy.wifiOnly);
    });
  });
}
