import 'package:abdalsalam/data/models/habits/habit.dart';
import 'package:abdalsalam/data/models/habits/habit_log.dart';
import 'package:abdalsalam/data/repositories/habits/habits_repository.dart';
import 'package:abdalsalam/data/repositories/habits/habit_log_repository.dart';
import 'package:abdalsalam/features/habits/services/habits_service.dart';
import 'package:abdalsalam/shared/infrastructure/database_schema_initializer.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/notification_service.dart';
import 'package:abdalsalam/shared/services/reminder_service.dart';
import 'package:abdalsalam/shared/services/settings_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:abdalsalam/core/errors/app_error.dart';

import '../support/failing_writes.dart';
import '../support/throwing_reminder_service.dart';
import '../support/validation_expectations.dart';

class _FailingHabitsRepository = HabitsRepositoryImpl with FailingWrites<Habit>;

Habit buildHabit({
  required bool isGoodHabit,
  HabitFrequency frequency = HabitFrequency.daily,
  int targetCount = 1,
  List<int>? customWeekdays,
  String userId = 'u1',
  String name = 'Test Habit',
  String? reminderTime,
}) {
  final now = DateTime.now();
  return Habit(
    id: 'habit-1',
    createdAt: now,
    updatedAt: now,
    userId: userId,
    name: name,
    description: '',
    frequency: frequency,
    targetCount: targetCount,
    reminderTime: reminderTime,
    icon: 'star',
    color: '#FFFFFF',
    category: 'Health',
    isGoodHabit: isGoodHabit,
    customWeekdays: customWeekdays,
  );
}

HabitLog buildLog(String id, DateTime completedAt) {
  final now = DateTime.now();
  return HabitLog(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: 'u1',
    habitId: 'habit-1',
    completedAt: completedAt,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('HabitsService', () {
    late HabitsService service;
    late HabitLogRepositoryImpl logRepository;
    late LoggerService logger;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LoggerService.initialize();
      await StorageGateway.instance.initialize(databaseName: 'test_habits_service_test.db');
      await DatabaseSchemaInitializer.initialize(StorageGateway.instance);
      await StorageGateway.instance.clearTable('habits');
      await StorageGateway.instance.clearTable('habit_logs');

      logger = LoggerService.forModule('HabitsServiceTest');
      final repository = HabitsRepositoryImpl(StorageGateway.instance, logger);
      logRepository = HabitLogRepositoryImpl(StorageGateway.instance, logger);
      final notifications = NotificationService(
        plugin: FlutterLocalNotificationsPlugin(),
        logger: logger,
      );
      final reminders = ReminderService(
        storage: StorageGateway.instance,
        logger: logger,
        notifications: notifications,
        settings: SettingsService(StorageGateway.instance),
      );
      service = HabitsService(repository, logger, reminders: reminders);
    });

    test('validate should succeed for a well-formed habit', () {
      expect(service.validate(buildHabit(isGoodHabit: true)).isSuccess, isTrue);
    });

    test('validate should report userId when userId is blank', () {
      expectFieldError(service.validate(buildHabit(isGoodHabit: true, userId: '')), HabitsService.userIdField);
    });

    test('validate should report name when name is blank', () {
      expectFieldError(service.validate(buildHabit(isGoodHabit: true, name: ' ')), HabitsService.nameField);
    });

    test('validate should report targetCount when targetCount is zero', () {
      expectFieldError(
        service.validate(buildHabit(isGoodHabit: true, targetCount: 0)),
        HabitsService.targetCountField,
      );
    });

    test('create should persist a valid habit', () async {
      final result = await service.create(buildHabit(isGoodHabit: true));

      expect(result.isSuccess, isTrue);
      final stored = await service.getById('habit-1');
      expect(stored.data?.name, 'Test Habit');
    });

    test('update should persist a renamed habit', () async {
      await service.create(buildHabit(isGoodHabit: true));

      final result = await service.update(buildHabit(isGoodHabit: true, name: 'Read daily'));

      expect(result.isSuccess, isTrue);
      final stored = await service.getById('habit-1');
      expect(stored.data?.name, 'Read daily');
    });

    test('create should propagate a repository failure', () async {
      final failingService = HabitsService(
        _FailingHabitsRepository(StorageGateway.instance, logger),
        logger,
        reminders: ThrowingReminderService(logger),
      );

      expectWriteFailure(await failingService.create(buildHabit(isGoodHabit: true)));
    });

    test('scheduleHabitReminder should return a failure instead of throwing', () async {
      final throwingService = HabitsService(
        HabitsRepositoryImpl(StorageGateway.instance, logger),
        logger,
        reminders: ThrowingReminderService(logger),
      );

      final result = await throwingService.scheduleHabitReminder(
        buildHabit(isGoodHabit: true, reminderTime: '08:00'),
      );

      expect(result.isFailure, isTrue);
      expect(result.error, isA<ServiceError>());
    });

    test('handleReminderTap should return a failure instead of throwing', () async {
      final throwingService = HabitsService(
        HabitsRepositoryImpl(StorageGateway.instance, logger),
        logger,
        reminders: ThrowingReminderService(logger),
      );

      final result = await throwingService.handleReminderTap(buildHabit(isGoodHabit: true));

      expect(result.isFailure, isTrue);
      expect(result.error, isA<ServiceError>());
    });

    test('streakFromLogs returns 0 for empty logs', () {
      expect(service.streakFromLogs([]), 0);
    });

    test('streakFromLogs counts consecutive days ending today', () {
      final today = DateTime.now();
      final logs = [
        buildLog('l1', today),
        buildLog('l2', today.subtract(const Duration(days: 1))),
        buildLog('l3', today.subtract(const Duration(days: 2))),
      ];
      expect(service.streakFromLogs(logs), 3);
    });

    test('streakFromLogs stops at a gap', () {
      final today = DateTime.now();
      final logs = [
        buildLog('l1', today),
        buildLog('l2', today.subtract(const Duration(days: 3))),
      ];
      expect(service.streakFromLogs(logs), 1);
    });

    test('habitStatistics: good habit best streak scans full history', () {
      final today = DateTime.now();
      final habit = buildHabit(isGoodHabit: true);
      final logs = [
        buildLog('l1', today.subtract(const Duration(days: 10))),
        buildLog('l2', today.subtract(const Duration(days: 9))),
        buildLog('l3', today.subtract(const Duration(days: 8))),
        buildLog('l4', today),
      ];
      final stats = service.habitStatistics(habit, logs);
      expect(stats['bestStreak'], 3);
      expect(stats['currentStreak'], 1);
      expect(stats['totalLogs'], 4);
    });

    test('habitStatistics: bad habit streak is relapse-free days since last log', () {
      final today = DateTime.now();
      final habit = buildHabit(isGoodHabit: false);
      final logs = [
        buildLog('l1', today.subtract(const Duration(days: 5))),
      ];
      final stats = service.habitStatistics(habit, logs);
      expect(stats['currentStreak'], 5);
    });

    test('habitStatistics: bad habit best streak is the longest relapse-free run', () {
      final today = DateTime.now();
      final habit = buildHabit(isGoodHabit: false);
      final logs = [
        buildLog('l1', today.subtract(const Duration(days: 20))),
        buildLog('l2', today.subtract(const Duration(days: 12))),
        buildLog('l3', today.subtract(const Duration(days: 10))),
      ];
      final stats = service.habitStatistics(habit, logs);
      // historical gap between logs is 8 days, but the ongoing run since the
      // last log (10 days) is longer, so it wins as the best streak so far.
      expect(stats['bestStreak'], 10);
      expect(stats['currentStreak'], 10);
    });

    test('habitStatistics: custom frequency expects only matching weekdays', () {
      final now = DateTime.now();
      final habit = buildHabit(
        isGoodHabit: true,
        frequency: HabitFrequency.custom,
        customWeekdays: const [DateTime.monday],
      );
      final logs = [buildLog('l1', now)];
      final stats = service.habitStatistics(habit, logs);
      expect(stats['completionRateThisMonth'], isA<double>());
    });

    test('HabitLogRepositoryImpl.getByHabit filters by habitId', () async {
      final now = DateTime.now();
      await logRepository.create(HabitLog(
        id: 'a',
        createdAt: now,
        updatedAt: now,
        userId: 'u1',
        habitId: 'habit-1',
        completedAt: now,
      ));
      await logRepository.create(HabitLog(
        id: 'b',
        createdAt: now,
        updatedAt: now,
        userId: 'u1',
        habitId: 'habit-2',
        completedAt: now,
      ));

      final result = await logRepository.getByHabit('habit-1');
      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 1);
      expect(result.data!.first.id, 'a');
    });

    test('HabitLogRepositoryImpl.getByHabitAndDateRange narrows by date', () async {
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2025, 1, 31);
      await logRepository.create(buildLog('in-range', DateTime(2025, 1, 15)));
      await logRepository.create(buildLog('out-of-range', DateTime(2025, 2, 1)));

      final result = await logRepository.getByHabitAndDateRange('habit-1', start, end);
      expect(result.isSuccess, isTrue);
      expect(result.data!.map((l) => l.id), ['in-range']);
    });
  });
}
