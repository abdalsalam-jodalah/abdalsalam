import 'storage_gateway.dart';

class DatabaseSchemaInitializer {
  static const List<String> tables = <String>[
    'prayer_logs',
    'religious_entries',
    'prayer_times_snapshots',
    'quran_progress',
    'quran_readings',
    'spiritual_progress',
    'athkar_content',
    'athkar_logs',
    'bad_practice_logs',
    'transactions',
    'financial_categories',
    'categories',
    'budgets',
    'habits',
    'habit_logs',
    'daily_events',
    'workouts',
    'exercises',
    'workout_schedules',
    'medications',
    'medication_logs',
    'blood_tests',
    'health_metrics',
    'notes',
    'todos',
    'note_categories',
    'events',
    'reminders',
    'credentials',
    'credential_categories',
    'life_plans',
    'life_goals',
    'life_achievements',
    'life_reviews',
    'sync_queue',
  ];

  static Future<void> initialize(StorageGateway storage) async {
    for (final table in tables) {
      await storage.createTableIfNeeded(table: table, createIndexes: true);
    }
  }
}
