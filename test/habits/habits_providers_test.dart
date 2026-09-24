import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/habits/habit.dart';
import 'package:abdalsalam/data/models/habits/habit_log.dart';
import 'package:abdalsalam/data/repositories/habits/habit_log_repository.dart';
import 'package:abdalsalam/data/repositories/habits/habits_repository.dart';
import 'package:abdalsalam/features/habits/providers/habits_providers.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeHabitsRepository implements HabitsRepository {
  final List<Habit> items;
  bool shouldFailGetActive = false;

  FakeHabitsRepository([List<Habit>? seed]) : items = seed ?? <Habit>[];

  @override
  Future<Result<List<Habit>, AppError>> getActive() async {
    if (shouldFailGetActive) {
      return Failure(DatabaseError('fake storage failure'));
    }
    return Success(List<Habit>.of(items));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

class FakeHabitLogRepository implements HabitLogRepository {
  final List<HabitLog> items;
  bool shouldFailGetByHabit = false;

  FakeHabitLogRepository([List<HabitLog>? seed]) : items = seed ?? <HabitLog>[];

  @override
  Future<Result<List<HabitLog>, AppError>> getByHabit(String habitId) async {
    if (shouldFailGetByHabit) {
      return Failure(DatabaseError('fake storage failure'));
    }
    return Success(items.where((log) => log.habitId == habitId).toList());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

Habit buildHabit({String id = 'habit-1'}) {
  final now = DateTime(2026, 1, 1);
  return Habit(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: 'u1',
    name: 'Read',
    description: '',
    frequency: HabitFrequency.daily,
    targetCount: 1,
    reminderTime: null,
    icon: 'star',
    color: '#FFFFFF',
    category: 'Health',
    isGoodHabit: true,
  );
}

void main() {
  setUpAll(() async {
    await LoggerService.initialize();
  });

  ProviderContainer buildContainer({
    HabitsRepository? habitsRepository,
    HabitLogRepository? habitLogRepository,
  }) {
    return ProviderContainer(
      overrides: [
        habitsRepositoryProvider.overrideWithValue(habitsRepository ?? FakeHabitsRepository()),
        habitLogRepositoryProvider.overrideWithValue(habitLogRepository ?? FakeHabitLogRepository()),
      ],
    );
  }

  group('activeHabitsProvider', () {
    test('surfaces a failed lookup as AsyncError instead of an empty list', () async {
      final container = buildContainer(
        habitsRepository: FakeHabitsRepository()..shouldFailGetActive = true,
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(activeHabitsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns the active habits on success', () async {
      final habit = buildHabit();
      final container = buildContainer(habitsRepository: FakeHabitsRepository([habit]));
      addTearDown(container.dispose);

      final result = await container.read(activeHabitsProvider.future);
      expect(result, [habit]);
    });
  });

  group('logsForHabitProvider', () {
    test('surfaces a failed lookup as AsyncError instead of an empty list', () async {
      final container = buildContainer(
        habitLogRepository: FakeHabitLogRepository()..shouldFailGetByHabit = true,
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(logsForHabitProvider('habit-1').future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns an empty list on success when there are no logs', () async {
      final container = buildContainer();
      addTearDown(container.dispose);

      final result = await container.read(logsForHabitProvider('habit-1').future);
      expect(result, isEmpty);
    });
  });

  group('habit family providers are autoDispose', () {
    test('habitByIdProvider disposes its state once nothing is listening', () async {
      final habit = buildHabit();
      final container = buildContainer(habitsRepository: FakeHabitsRepository([habit]));
      addTearDown(container.dispose);

      final provider = habitByIdProvider(habit.id);
      final subscription = container.listen(provider, (previous, next) {});
      await container.read(provider.future);
      expect(container.exists(provider), isTrue);

      subscription.close();
      await container.pump();

      expect(container.exists(provider), isFalse);
    });

    test('logsForHabitProvider disposes its state once nothing is listening', () async {
      final container = buildContainer();
      addTearDown(container.dispose);

      final provider = logsForHabitProvider('habit-1');
      final subscription = container.listen(provider, (previous, next) {});
      await container.read(provider.future);
      expect(container.exists(provider), isTrue);

      subscription.close();
      await container.pump();

      expect(container.exists(provider), isFalse);
    });

    test('habitStatisticsProvider disposes its state once nothing is listening', () async {
      final habit = buildHabit();
      final container = buildContainer(habitsRepository: FakeHabitsRepository([habit]));
      addTearDown(container.dispose);

      final provider = habitStatisticsProvider(habit.id);
      final subscription = container.listen(provider, (previous, next) {});
      await container.read(provider.future);
      expect(container.exists(provider), isTrue);

      subscription.close();
      await container.pump();

      expect(container.exists(provider), isFalse);
    });
  });
}
