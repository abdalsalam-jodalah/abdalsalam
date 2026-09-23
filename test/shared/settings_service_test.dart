import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsService', () {
    late SettingsService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageGateway.instance.initialize(databaseName: 'test_settings_service_test.db');
      await StorageGateway.instance.delete('app_settings_v1');
      service = SettingsService(StorageGateway.instance);
    });

    test('every default value is non-null and correctly typed for its key', () {
      final defaults = service.defaults;

      for (final entry in defaults.entries) {
        expect(entry.value, isNotNull, reason: '${entry.key} has no default value');
      }
      expect(defaults['themeMode'], isA<String>());
      expect(defaults['autoLockMinutes'], isA<int>());
      expect(defaults['sleepGoalHours'], isA<double>());
      expect(defaults['autoBackupEnabled'], isA<bool>());
      expect(defaults['dashboardCardOrder'], isA<List<String>>());
    });

    test('getSettings returns defaults when nothing is stored', () async {
      final settings = await service.getSettings();

      expect(settings, service.defaults);
    });

    test('getSettings merges stored overrides on top of defaults', () async {
      await service.updateSetting('currency', 'EUR');

      final settings = await service.getSettings();

      expect(settings['currency'], 'EUR');
      expect(settings['themeMode'], service.defaults['themeMode']);
    });

    test('updateSetting performs a read-modify-write without dropping other keys', () async {
      await service.updateSetting('currency', 'EUR');
      await service.updateSetting('autoLockMinutes', 15);

      final settings = await service.getSettings();

      expect(settings['currency'], 'EUR');
      expect(settings['autoLockMinutes'], 15);
    });

    test('resetToDefaults discards all overrides', () async {
      await service.updateSetting('currency', 'EUR');

      await service.resetToDefaults();

      final settings = await service.getSettings();
      expect(settings['currency'], service.defaults['currency']);
    });

    test('should fall back to defaults when stored settings have the wrong type', () async {
      await StorageGateway.instance.save(key: 'app_settings_v1', value: 'not a map');

      final settings = await service.getSettings();

      expect(settings, service.defaults);
    });

    test('should repair corrupt settings on the next update', () async {
      await StorageGateway.instance.save(key: 'app_settings_v1', value: 'not a map');

      await service.updateSetting('themeMode', 'dark');

      expect((await service.getSettings())['themeMode'], 'dark');
    });
  });
}
