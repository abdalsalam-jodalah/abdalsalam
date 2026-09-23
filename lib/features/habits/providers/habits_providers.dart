import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;

import '../../../data/models/habits/habit.dart';
import '../../../data/models/habits/habit_log.dart';
import '../../../data/repositories/habits/habits_repository.dart';
import '../../../data/repositories/habits/habit_log_repository.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../services/habit_log_service.dart';
import '../services/habits_service.dart';

const String habitsUserId = 'user1';

final habitsRepositoryProvider = Provider<HabitsRepository>((ref) {
  return HabitsRepositoryImpl(
    ref.watch(storageGatewayProvider),
    LoggerService.forModule('HabitsRepository', moduleType: logic.ModuleType.repository),
  );
});

final habitLogRepositoryProvider = Provider<HabitLogRepository>((ref) {
  return HabitLogRepositoryImpl(
    ref.watch(storageGatewayProvider),
    LoggerService.forModule('HabitLogRepository', moduleType: logic.ModuleType.repository),
  );
});

final habitsServiceProvider = Provider<HabitsService>((ref) {
  return HabitsService(
    ref.watch(habitsRepositoryProvider),
    LoggerService.forModule('HabitsService', moduleType: logic.ModuleType.service),
    reminders: ref.watch(reminderServiceProvider),
  );
});

final habitLogServiceProvider = Provider<HabitLogService>((ref) {
  return HabitLogService(
    ref.watch(habitLogRepositoryProvider),
    LoggerService.forModule('HabitLogService', moduleType: logic.ModuleType.service),
  );
});

final activeHabitsProvider = FutureProvider<List<Habit>>((ref) async {
  final repo = ref.watch(habitsRepositoryProvider);
  final result = await repo.getActive();
  return result.data ?? [];
});

final habitByIdProvider = FutureProvider.family<Habit?, String>((ref, habitId) async {
  final habits = await ref.watch(activeHabitsProvider.future);
  for (final habit in habits) {
    if (habit.id == habitId) {
      return habit;
    }
  }
  return null;
});

final logsForHabitProvider = FutureProvider.family<List<HabitLog>, String>((ref, habitId) async {
  final repo = ref.watch(habitLogRepositoryProvider);
  final result = await repo.getByHabit(habitId);
  return result.data ?? [];
});

final habitStatisticsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, habitId) async {
  final habit = await ref.watch(habitByIdProvider(habitId).future);
  if (habit == null) {
    return <String, dynamic>{};
  }
  final logs = await ref.watch(logsForHabitProvider(habitId).future);
  return ref.watch(habitsServiceProvider).habitStatistics(habit, logs);
});
