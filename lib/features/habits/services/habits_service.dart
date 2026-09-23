import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../core/validation/validation_result_factory.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/habits/habit.dart';
import '../../../data/models/habits/habit_log.dart';
import '../../../data/repositories/habits/habits_repository.dart';
import '../../../shared/services/base_service_impl.dart';
import '../../../shared/services/error_handler.dart';
import '../../../shared/services/reminder_service.dart';

class HabitsService extends BaseServiceImpl<Habit> {
  static const String userIdField = 'userId';
  static const String nameField = 'name';
  static const String targetCountField = 'targetCount';

  final ReminderService reminders;

  HabitsService(HabitsRepository super.repository, super.logger, {required this.reminders});

  HabitsRepository get _repo => repository as HabitsRepository;

  ErrorHandler get _errorHandler => ErrorHandler(logger);

  @override
  String get serviceName => 'HabitsService';

  @override
  String get version => '2.0.0';

  @override
  Habit fromJson(Map<String, dynamic> json) => Habit.fromJson(json);

  @override
  Result<void, AppError> validate(Habit entity) {
    return ValidationResultFactory.fromFieldErrors(
      ValidationUtils.collect([
        MapEntry(userIdField, ValidationUtils.requiredField(entity.userId, userIdField)),
        MapEntry(nameField, ValidationUtils.requiredField(entity.name, nameField)),
        MapEntry(
          targetCountField,
          ValidationUtils.positiveNumber(value: entity.targetCount, fieldName: targetCountField),
        ),
      ]),
    );
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final all = await _repo.getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    return Success(<String, dynamic>{
      'activeHabits': all.data!.length,
      'goodHabits': all.data!.where((habit) => habit.isGoodHabit).length,
      'badHabits': all.data!.where((habit) => !habit.isGoodHabit).length,
    });
  }

  int streakFromLogs(List<HabitLog> logs) {
    if (logs.isEmpty) {
      return 0;
    }
    final days = _dayset(logs);

    var streak = 0;
    var cursor = DateTime.now();
    while (days.contains(_dateOnly(cursor))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  double completionRate(int completed, int target) {
    if (target <= 0) {
      return 0;
    }
    return (completed / target) * 100;
  }

  /// Combines streak/completion metrics for a single habit. For good habits a
  /// "streak" is consecutive days *with* a log; for bad habits it inverts to
  /// consecutive days *since the last log* (a relapse-free run), since more
  /// logs means the habit is doing worse, not better.
  Map<String, dynamic> habitStatistics(Habit habit, List<HabitLog> logs) {
    final currentStreak = habit.isGoodHabit ? streakFromLogs(logs) : _relapseFreeStreak(logs);
    final bestStreak = habit.isGoodHabit ? _bestGoodStreak(logs) : _bestRelapseFreeStreak(logs);
    final now = DateTime.now();
    final monthLogs = logs
        .where((log) => log.completedAt.year == now.year && log.completedAt.month == now.month)
        .length;
    final expected = _expectedOccurrences(habit, now);
    return <String, dynamic>{
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'completionRateThisMonth': completionRate(monthLogs, expected),
      'totalLogs': logs.length,
    };
  }

  Set<DateTime> _dayset(List<HabitLog> logs) =>
      logs.map((log) => _dateOnly(log.completedAt)).toSet();

  DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  int _bestGoodStreak(List<HabitLog> logs) {
    if (logs.isEmpty) {
      return 0;
    }
    final days = _dayset(logs).toList()..sort();
    var best = 1;
    var current = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        current += 1;
      } else {
        current = 1;
      }
      if (current > best) {
        best = current;
      }
    }
    return best;
  }

  int _relapseFreeStreak(List<HabitLog> logs) {
    if (logs.isEmpty) {
      return 0;
    }
    final lastLog = _dayset(logs).reduce((a, b) => a.isAfter(b) ? a : b);
    return _dateOnly(DateTime.now()).difference(lastLog).inDays;
  }

  int _bestRelapseFreeStreak(List<HabitLog> logs) {
    if (logs.isEmpty) {
      return 0;
    }
    final days = _dayset(logs).toList()..sort();
    var best = 0;
    for (var i = 1; i < days.length; i++) {
      final gap = days[i].difference(days[i - 1]).inDays;
      if (gap > best) {
        best = gap;
      }
    }
    final sinceLast = _relapseFreeStreak(logs);
    return sinceLast > best ? sinceLast : best;
  }

  int _expectedOccurrences(Habit habit, DateTime month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    switch (habit.frequency) {
      case HabitFrequency.daily:
        return daysInMonth * habit.targetCount;
      case HabitFrequency.weekly:
        return (daysInMonth / 7).ceil() * habit.targetCount;
      case HabitFrequency.custom:
        final weekdays = habit.customWeekdays ?? const <int>[];
        if (weekdays.isEmpty) {
          return daysInMonth * habit.targetCount;
        }
        var matchingDays = 0;
        for (var day = 1; day <= daysInMonth; day++) {
          if (weekdays.contains(DateTime(month.year, month.month, day).weekday)) {
            matchingDays += 1;
          }
        }
        return matchingDays * habit.targetCount;
    }
  }

  Future<Result<void, AppError>> scheduleHabitReminder(Habit habit) async {
    if (habit.reminderTime == null) {
      return const Success(null);
    }
    try {
      await reminders.schedule(
        ReminderPayload(
          module: ReminderModule.habits,
          targetId: habit.id,
          title: 'Habit reminder',
          body: 'Time to complete ${habit.name}',
          scheduledAt: DateTime.now(),
        ),
      );
      return const Success(null);
    } catch (e, st) {
      return Failure(_errorHandler.mapException(e, context: '$serviceName.scheduleHabitReminder', stackTrace: st));
    }
  }

  Future<Result<void, AppError>> handleReminderTap(Habit habit) async {
    try {
      reminders.handleNotificationTap(
        ReminderPayload(
          module: ReminderModule.habits,
          targetId: habit.id,
          title: 'Open habit',
          body: habit.name,
          scheduledAt: DateTime.now(),
        ),
      );
      return const Success(null);
    } catch (e, st) {
      return Failure(_errorHandler.mapException(e, context: '$serviceName.handleReminderTap', stackTrace: st));
    }
  }
}
