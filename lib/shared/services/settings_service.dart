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
        'religiousRemindersEnabled': true,
        'religiousPrayerRemindersEnabled': true,
        'religiousQuranRemindersEnabled': true,
        'religiousAthkarRemindersEnabled': true,
        'religiousNightRemindersEnabled': true,
        'religiousBadEventRemindersEnabled': true,
        'religiousDefaultReminderMinutes': 10,
        'religiousPrayerTimesRetentionDays': 365,
        'prayerMethod': 'muslim_world_league',
        'prayerTimeSource': 'scraped',
        'prayerLocationLatitude': 32.2211,
        'prayerLocationLongitude': 35.2544,
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
