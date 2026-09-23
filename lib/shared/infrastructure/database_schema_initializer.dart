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
    'accounts',
    'exchange_rates',
    'financial_activity_log',
    'financial_categories',
    'categories',
    'budgets',
    'habits',
    'habit_logs',
    'daily_events',
    'sport_exercise_categories',
    'sport_exercises',
    'sport_weekly_schedule',
    'sport_exercise_logs',
    'sport_exercise_set_logs',
    'sport_body_measurements',
    'medications',
    'medication_logs',
    'blood_tests',
    'health_metrics',
    'doctor_visits',
    'sleep_logs',
    'food_logs',
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
    'life_plan_topics',
    'life_planning_tasks',
    'sync_queue',
  ];

  static Future<void> initialize(StorageGateway storage) async {
    for (final table in tables) {
      await storage.createTableIfNeeded(table: table, createIndexes: true);
    }
  }
}
