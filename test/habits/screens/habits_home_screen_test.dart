import 'package:abdalsalam/features/habits/providers/habits_providers.dart';
import 'package:abdalsalam/features/habits/screens/habits_home_screen.dart';
import 'package:abdalsalam/providers/app_providers.dart';
import 'package:abdalsalam/shared/infrastructure/database_schema_initializer.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../habits_providers_test.dart' show FakeHabitLogRepository, FakeHabitsRepository, buildHabit;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await StorageGateway.instance.initialize(databaseName: 'test_habits_home_screen_test.db');
    await DatabaseSchemaInitializer.initialize(StorageGateway.instance);
    for (final table in ['habits', 'habit_logs']) {
      await StorageGateway.instance.clearTable(table);
    }
  });

  Widget buildApp(List<Override> overrides) {
    final appStateManager = logic.AppStateManagerImpl.create(config: const logic.AppStateConfig());
    return ProviderScope(
      overrides: [
        appStateManagerProvider.overrideWithValue(appStateManager),
        habitLogRepositoryProvider.overrideWithValue(FakeHabitLogRepository()),
        ...overrides,
      ],
      child: const MaterialApp(home: HabitsHomeScreen()),
    );
  }

  testWidgets('shows a mapped error with Retry when activeHabitsProvider fails', (tester) async {
    final failingRepository = FakeHabitsRepository()..shouldFailGetActive = true;

    await tester.pumpWidget(buildApp([
      habitsRepositoryProvider.overrideWithValue(failingRepository),
    ]));
    await tester.pumpAndSettle();

    expect(find.textContaining('Failed to load habits'), findsNothing);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('renders the habits list on success', (tester) async {
    final habit = buildHabit();

    await tester.pumpWidget(buildApp([
      habitsRepositoryProvider.overrideWithValue(FakeHabitsRepository([habit])),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Habits Home'), findsOneWidget);
    expect(find.text(habit.name), findsOneWidget);
  });
}
