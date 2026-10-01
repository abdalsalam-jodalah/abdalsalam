// lib/shared/services/module_table_registry.dart — maps every storage table to the app module that owns it.

enum DataModule {
  religious(
    label: 'Religious',
    tables: <String>[
      'prayer_logs',
      'religious_entries',
      'prayer_times_snapshots',
      'quran_progress',
      'quran_readings',
      'spiritual_progress',
      'athkar_content',
      'athkar_logs',
      'bad_practice_logs',
    ],
  ),
  financial(
    label: 'Financial',
    tables: <String>[
      'transactions',
      'accounts',
      'exchange_rates',
      'financial_activity_log',
      'financial_categories',
      'categories',
      'budgets',
    ],
  ),
  habits(label: 'Habits', tables: <String>['habits', 'habit_logs', 'daily_events']),
  sports(
    label: 'Sports',
    tables: <String>[
      'sport_exercise_categories',
      'sport_exercises',
      'sport_weekly_schedule',
      'sport_exercise_logs',
      'sport_exercise_set_logs',
      'sport_body_measurements',
    ],
  ),
  health(
    label: 'Health',
    tables: <String>['medications', 'medication_logs', 'blood_tests', 'health_metrics', 'doctor_visits'],
  ),
  sleep(label: 'Sleep', tables: <String>['sleep_logs']),
  food(label: 'Food', tables: <String>['food_logs']),
  notes(label: 'Notes', tables: <String>['notes', 'todos', 'note_categories']),
  calendar(label: 'Calendar', tables: <String>['events', 'reminders']),
  planning(
    label: 'Planning',
    tables: <String>[
      'life_plans',
      'life_goals',
      'life_achievements',
      'life_reviews',
      'life_plan_topics',
      'life_planning_tasks',
    ],
  ),
  security(label: 'Security', tables: <String>['credentials', 'credential_categories']),
  enhancements(label: 'Notes to Enhance', tables: <String>['app_enhancement_notes']),
  system(label: 'System', tables: <String>['sync_queue']);

  final String label;
  final List<String> tables;

  const DataModule({required this.label, required this.tables});
}

class ModuleTableRegistry {
  static const Set<String> readableExportExcludedTables = <String>{
    'credentials',
    'credential_categories',
    'sync_queue',
  };

  static final Map<String, DataModule> _moduleByTable = <String, DataModule>{
    for (final module in DataModule.values)
      for (final table in module.tables) table: module,
  };

  static List<DataModule> get readableExportModules {
    return DataModule.values.where((module) => readableExportTablesFor(module).isNotEmpty).toList(growable: false);
  }

  static List<String> get allTables => _moduleByTable.keys.toList(growable: false);

  static DataModule? moduleOf(String table) => _moduleByTable[table];

  static List<String> readableExportTablesFor(DataModule module) {
    return module.tables.where((table) => !readableExportExcludedTables.contains(table)).toList(growable: false);
  }
}
