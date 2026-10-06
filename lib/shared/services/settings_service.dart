import '../../core/constants/dashboard_card_catalog.dart';
import '../../core/errors/app_error.dart';
import '../../core/theme/appearance.dart';
import '../infrastructure/storage_gateway.dart';

class SettingsService {
  static const _key = 'app_settings_v1';

  final StorageGateway storage;

  SettingsService(this.storage);

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final data = await storage.get<Map<String, dynamic>>(_key);
      return {...defaults, ...(data ?? <String, dynamic>{})};
    } on CorruptDataError catch (error, stackTrace) {
      storage.integrityReporter.reportCorruptRecord(
        table: 'preferences',
        recordId: _key,
        reason: error,
        stackTrace: stackTrace,
      );
      return defaults;
    }
  }

  Future<void> updateSetting(String key, dynamic value) async {
    await updateSettings(<String, dynamic>{key: value});
  }

  Future<void> updateSettings(Map<String, dynamic> values) async {
    final settings = await getSettings();
    settings.addAll(values);
    await storage.save(key: _key, value: settings);
  }

  Future<void> resetToDefaults() async {
    await storage.save(key: _key, value: defaults);
  }

  Map<String, dynamic> get defaults => <String, dynamic>{
        ...Appearance.defaults.toSettings(),
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
        'securityPasswordExpiryDays': 90,
        'backupReminderDays': 7,
        'autoBackupEnabled': false,
        'sleepGoalHours': 8.0,
        'religiousQuranDailyGoalPages': 1,
        'religiousBadEventThreshold': 3,
        'financialDefaultBudgetAlertThreshold': 80.0,
        'financialDefaultExportFormat': 'csv',
        'habitsDefaultStreakGoal': 21,
        'habitsDefaultReminderMinutes': 480,
        'sportsUnitSystem': 'metric',
        'sportsDefaultWorkoutRemindersPerWeek': 3,
        'sportsWeeklyWorkoutGoal': 3,
        'sportsDailyStepGoal': 8000,
        'healthBloodTestRecheckIntervalDays': 180,
        'healthMetricUnitSystem': 'metric',
        'medicationsDefaultRefillReminderDays': 7,
        'foodDailyCalorieTarget': 2000,
        'foodDailyProteinTargetGrams': 100,
        'notesDefaultColor': 'default',
        'notesDefaultPinned': false,
        'calendarGoogleSyncEnabled': false,
        'calendarReminderType': 'notification',
        DashboardCardCatalog.cardOrderSetting: DashboardCardCatalog.defaultOrder,
        'dashboardHiddenCards': <String>[],
        DashboardCardCatalog.showQuoteSetting: true,
        'sidebarAutoCloseSeconds': 10,
        'sidebarOrder': <String>[
          'dashboard',
          'religious',
          'financial',
          'habits',
          'planning',
          'sports',
          'health',
          'medications',
          'notes',
          'calendar',
          'security',
          'analytics',
          'enhancements',
          'settings',
        ],
      };
}
