import 'storage_gateway.dart';

class DatabaseSchemaInitializer {
  static const List<String> tables = <String>[
    'prayer_logs',
    'quran_progress',
    'quran_readings',
    'spiritual_progress',
    'transactions',
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
    'sync_queue',
  ];

  static Future<void> initialize(StorageGateway storage) async {
    for (final table in tables) {
      await storage.createTableIfNeeded(table: table, createIndexes: true);
    }

    const indexes = <String, List<String>>{
      'prayer_logs': <String>['prayedAt', 'prayerName'],
      'quran_readings': <String>['readAt', 'surahNumber'],
      'spiritual_progress': <String>['date'],
      'transactions': <String>['date', 'category', 'type'],
      'categories': <String>['name', 'type', 'parentCategoryId'],
      'budgets': <String>['categoryId', 'startDate', 'endDate'],
      'habits': <String>['category', 'frequency'],
      'habit_logs': <String>['completedAt', 'habitId'],
      'daily_events': <String>['occurredAt', 'eventType'],
      'workouts': <String>['startTime', 'type'],
      'exercises': <String>['workoutId', 'muscleGroup'],
      'workout_schedules': <String>['scheduledFor', 'workoutType'],
      'medications': <String>['startDate', 'refillDate'],
      'medication_logs': <String>['takenAt', 'medicationId'],
      'blood_tests': <String>['scheduledDate', 'completedDate'],
      'health_metrics': <String>['measuredAt', 'metricType'],
      'notes': <String>['title', 'categoryId', 'pinned'],
      'todos': <String>['status', 'dueDate', 'categoryId'],
      'note_categories': <String>['type', 'name', 'parentId'],
    };

    for (final entry in indexes.entries) {
      for (final column in entry.value) {
        await storage.createIndexIfNeeded(
          table: entry.key,
          indexName: 'idx_${entry.key}_$column',
          columnName: column,
        );
      }
    }
  }
}
