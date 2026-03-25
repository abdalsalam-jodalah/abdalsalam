import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/habits/habit.dart';
import '../../../data/models/habits/habit_log.dart';
import '../../../data/repositories/habits/habits_repository.dart';
import '../../../shared/services/base_service_impl.dart';
import '../../../shared/services/reminder_service.dart';

class HabitsService extends BaseServiceImpl<Habit> {
  final ReminderService reminders;

  HabitsService(super.repository, super.logger, {required this.reminders});

  HabitsRepository get _repo => repository as HabitsRepository;

  @override
  String get serviceName => 'HabitsService';

  @override
  String get version => '2.0.0';

  @override
  Habit fromJson(Map<String, dynamic> json) => Habit.fromJson(json);

  @override
  Result<void, AppError> validate(Habit entity) {
    if (entity.userId.trim().isEmpty) {
      return Failure(ValidationError('userId is required'));
    }
    if (entity.name.trim().isEmpty) {
      return Failure(ValidationError('name is required'));
    }
    if (entity.targetCount <= 0) {
      return Failure(ValidationError('targetCount must be > 0'));
    }
    return const Success(null);
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final all = await _repo.getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    return Success(<String, dynamic>{
      'activeHabits': all.data!.length,
      'completionRate': 0.0,
      'bestStreak': 0,
    });
  }

  int streakFromLogs(List<HabitLog> logs) {
    if (logs.isEmpty) {
      return 0;
    }
    final days = logs
        .map((item) => DateTime(item.completedAt.year, item.completedAt.month, item.completedAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    var streak = 0;
    var cursor = DateTime.now();
    while (days.contains(DateTime(cursor.year, cursor.month, cursor.day))) {
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

  Future<Result<void, AppError>> scheduleHabitReminder(Habit habit) async {
    if (habit.reminderTime == null) {
      return const Success(null);
    }
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
  }

  Future<Result<void, AppError>> handleReminderTap(Habit habit) async {
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
  }
}
