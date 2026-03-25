import '../infrastructure/storage_gateway.dart';

class SettingsService {
  static const _key = 'app_settings_v1';

  final StorageGateway storage;

  SettingsService(this.storage);

  Future<Map<String, dynamic>> getSettings() async {
    final data = await storage.get<Map<String, dynamic>>(_key);
    return {...defaults, ...(data ?? <String, dynamic>{})};
  }

  Future<void> updateSetting(String key, dynamic value) async {
    final settings = await getSettings();
    settings[key] = value;
    await storage.save(key: _key, value: settings);
  }

  Future<void> resetToDefaults() async {
    await storage.save(key: _key, value: defaults);
  }

  Map<String, dynamic> get defaults => <String, dynamic>{
        'themeMode': 'system',
        'language': 'en',
        'firstDayOfWeek': 'saturday',
        'notificationsEnabled': true,
        'notificationSound': 'default',
        'notificationPriority': 'default',
        'respectDoNotDisturb': true,
        'prayerMethod': 'muslim_world_league',
        'currency': 'USD',
        'biometricEnabled': true,
        'autoLockMinutes': 5,
        'backupReminderDays': 7,
        'autoBackupEnabled': false,
        'dashboardCardOrder': <String>[
          'religious',
          'financial',
          'habits',
          'sports',
          'health',
          'notes',
          'calendar',
          'security',
          'analytics',
        ],
        'dashboardHiddenCards': <String>[],
      };
}
