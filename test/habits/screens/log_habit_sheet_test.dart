import 'package:abdalsalam/data/models/habits/habit.dart';
import 'package:abdalsalam/data/models/habits/habit_log.dart';
import 'package:abdalsalam/data/repositories/habits/habit_log_repository.dart';
import 'package:abdalsalam/features/habits/providers/habits_providers.dart';
import 'package:abdalsalam/features/habits/widgets/log_habit_sheet.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/failing_writes.dart';
import '../../support/test_storage.dart';

class _FailingHabitLogRepository = HabitLogRepositoryImpl with FailingWrites<HabitLog>;

Habit _buildHabit({required bool isGoodHabit}) {
  final now = DateTime(2026, 1, 1);
  return Habit(
    id: 'habit-1',
    createdAt: now,
    updatedAt: now,
    userId: 'u1',
    name: 'Test Habit',
    description: '',
    frequency: HabitFrequency.daily,
    targetCount: 1,
    reminderTime: null,
    icon: 'star',
    color: '#FFFFFF',
    category: 'Health',
    isGoodHabit: isGoodHabit,
  );
}

void main() {
  initializeTestDatabaseFactory();

  late LoggerService logger;

  setUp(() async {
    await resetTestStorage(databaseName: 'test_log_habit_sheet_test.db', tables: ['habits', 'habit_logs']);
    logger = LoggerService.forModule('LogHabitSheetTest');
  });

  testWidgets('rejects a bad-habit log with a blank situation and does not save', (tester) async {
    final habit = _buildHabit(isGoodHabit: false);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showLogHabitSheet(context, ref, habit),
                  child: const Text('Open sheet'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Save log'), findsOneWidget);
    await tester.ensureVisible(find.text('Save log'));
    await tester.tap(find.text('Save log'));
    await tester.pumpAndSettle();

    expect(find.text('Situation is required'), findsOneWidget);
    expect(find.text('Save log'), findsOneWidget);
  });

  testWidgets('shows a mapped error and keeps the sheet open when the write fails', (tester) async {
    final habit = _buildHabit(isGoodHabit: true);
    final failingRepository = _FailingHabitLogRepository(StorageGateway.instance, logger);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitLogRepositoryProvider.overrideWithValue(failingRepository),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showLogHabitSheet(context, ref, habit),
                  child: const Text('Open sheet'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save log'));
    await tester.pumpAndSettle();

    expect(find.text('Your data could not be saved or loaded. Please try again.'), findsOneWidget);
    expect(find.text('Save log'), findsOneWidget);
  });
}
