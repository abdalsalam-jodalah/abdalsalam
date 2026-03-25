import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/religious/prayer_log.dart';
import '../../../data/repositories/religious/prayer_repository.dart';
import '../../../shared/services/base_service_impl.dart';
import '../../../shared/services/reminder_service.dart';

class ReligiousService extends BaseServiceImpl<PrayerLog> {
  final ReminderService reminders;

  ReligiousService(super.repository, super.logger, {required this.reminders});

  PrayerRepository get _repo => repository as PrayerRepository;

  @override
  String get serviceName => 'ReligiousService';

  @override
  String get version => '2.0.0';

  @override
  PrayerLog fromJson(Map<String, dynamic> json) => PrayerLog.fromJson(json);

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final all = await _repo.getAll();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final logs = all.data!;
    final completionRate = _completionRate(logs);
    final streak = _currentStreak(logs);

    return Success(<String, dynamic>{
      'totalLogs': logs.length,
      'completionRate': completionRate,
      'currentStreak': streak,
      'byPrayer': {
        for (final prayer in PrayerName.values)
          prayer.name: logs.where((row) => row.prayerName == prayer).length,
      },
    });
  }

  double _completionRate(List<PrayerLog> logs) {
    if (logs.isEmpty) {
      return 0;
    }

    final grouped = <String, Set<PrayerName>>{};
    for (final item in logs) {
      final key = item.prayedAt.toIso8601String().split('T').first;
      grouped.putIfAbsent(key, () => <PrayerName>{}).add(item.prayerName);
    }

    final fullDays = grouped.values.where((set) => set.length == PrayerName.values.length).length;
    return (fullDays / grouped.length) * 100;
  }

  int _currentStreak(List<PrayerLog> logs) {
    final grouped = <String, Set<PrayerName>>{};
    for (final item in logs) {
      final key = item.prayedAt.toIso8601String().split('T').first;
      grouped.putIfAbsent(key, () => <PrayerName>{}).add(item.prayerName);
    }

    var streak = 0;
    var date = DateTime.now();
    while (true) {
      final key = date.toIso8601String().split('T').first;
      final completed = grouped[key];
      if (completed == null || completed.length < PrayerName.values.length) {
        break;
      }
      streak += 1;
      date = date.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<Result<void, AppError>> schedulePrayerReminder({
    required String prayerName,
    required DateTime prayerTime,
    required String targetId,
  }) async {
    await reminders.schedule(
      ReminderPayload(
        module: ReminderModule.religious,
        targetId: targetId,
        title: 'Prayer reminder',
        body: '$prayerName in 10 minutes',
        scheduledAt: prayerTime.subtract(const Duration(minutes: 10)),
      ),
    );
    return const Success(null);
  }

  Future<Result<void, AppError>> handlePrayerReminderTap(String prayerLogId) async {
    reminders.handleNotificationTap(
      ReminderPayload(
        module: ReminderModule.religious,
        targetId: prayerLogId,
        title: 'Open prayer log',
        body: 'Navigate to prayer log details',
        scheduledAt: DateTime.now(),
      ),
    );
    return const Success(null);
  }

  @override
  Result<void, AppError> validate(PrayerLog entity) {
    if (entity.userId.trim().isEmpty) {
      return Failure(ValidationError('userId is required'));
    }
    if (entity.prayedAt.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      return Failure(ValidationError('prayedAt cannot be in the future'));
    }
    return const Success(null);
  }
}
