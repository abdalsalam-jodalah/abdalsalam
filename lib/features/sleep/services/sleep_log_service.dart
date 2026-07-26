import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/sleep/sleep_log.dart';
import '../../../data/repositories/sleep/sleep_log_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class SleepLogService extends BaseServiceImpl<SleepLog> {
  static const _caffeineProximityThreshold = Duration(hours: 6);

  SleepLogService(SleepLogRepository super.repository, super.logger);

  SleepLogRepository get _repo => repository as SleepLogRepository;

  @override
  String get serviceName => 'SleepLogService';

  @override
  String get version => '1.0.0';

  @override
  SleepLog fromJson(Map<String, dynamic> json) => SleepLog.fromJson(json);

  @override
  Result<void, AppError> validate(SleepLog entity) {
    if (entity.userId.trim().isEmpty) {
      return Failure(ValidationError('userId is required'));
    }
    if (!entity.sleepEnd.isAfter(entity.sleepStart)) {
      return Failure(ValidationError('sleepEnd must be after sleepStart'));
    }
    if (!_isValidRating(entity.feelingBeforeSleep)) {
      return Failure(ValidationError('feelingBeforeSleep must be between 1 and 5'));
    }
    if (!_isValidRating(entity.feelingOnWakeup)) {
      return Failure(ValidationError('feelingOnWakeup must be between 1 and 5'));
    }
    if (!_isValidRating(entity.feelingDuringDay)) {
      return Failure(ValidationError('feelingDuringDay must be between 1 and 5'));
    }
    return const Success(null);
  }

  bool _isValidRating(int? rating) => rating == null || (rating >= 1 && rating <= 5);

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final all = await getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final logs = all.data!;
    final now = DateTime.now();
    final last7Days = _averageDurationSince(logs, now.subtract(const Duration(days: 7)));
    final last30Days = _averageDurationSince(logs, now.subtract(const Duration(days: 30)));
    final mostRecent = logs.isEmpty
        ? null
        : logs.reduce((a, b) => a.sleepStart.isAfter(b.sleepStart) ? a : b);

    return Success(<String, dynamic>{
      'totalLogs': logs.length,
      'averageDurationMinutesLast7Days': last7Days,
      'averageDurationMinutesLast30Days': last30Days,
      'averageFeelingBeforeSleep': _averageRating(logs.map((log) => log.feelingBeforeSleep)),
      'averageFeelingOnWakeup': _averageRating(logs.map((log) => log.feelingOnWakeup)),
      'averageFeelingDuringDay': _averageRating(logs.map((log) => log.feelingDuringDay)),
      'mostRecentLog': mostRecent,
    });
  }

  double? _averageDurationSince(List<SleepLog> logs, DateTime since) {
    final inRange = logs.where((log) => log.sleepStart.isAfter(since)).toList();
    if (inRange.isEmpty) {
      return null;
    }
    final totalMinutes = inRange.fold<int>(0, (sum, log) => sum + log.duration.inMinutes);
    return totalMinutes / inRange.length;
  }

  double? _averageRating(Iterable<int?> ratings) {
    final present = ratings.whereType<int>().toList();
    if (present.isEmpty) {
      return null;
    }
    return present.reduce((a, b) => a + b) / present.length;
  }

  Future<Result<List<SleepLog>, AppError>> getTrend(DateTime start, DateTime end) {
    return _repo.getByDateRange(start, end);
  }

  Future<Result<Map<String, dynamic>, AppError>> getInsights() async {
    final all = await getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final logs = all.data!;
    final now = DateTime.now();
    final startOfThisWeek = _startOfWeek(now);
    final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));

    final avgHoursThisWeek = _averageHoursInRange(logs, startOfThisWeek, startOfThisWeek.add(const Duration(days: 7)));
    final avgHoursLastWeek = _averageHoursInRange(logs, startOfLastWeek, startOfThisWeek);
    final weeklyDeltaHours =
        (avgHoursThisWeek != null && avgHoursLastWeek != null) ? avgHoursThisWeek - avgHoursLastWeek : null;

    final since = now.subtract(const Duration(days: 7));
    final recentLogs = logs.where((log) => log.sleepStart.isAfter(since)).toList();
    final flagged = recentLogs.where((log) {
      final caffeineTime = log.lastCaffeineTime;
      if (caffeineTime == null) {
        return false;
      }
      return log.sleepStart.difference(caffeineTime) <= _caffeineProximityThreshold;
    }).toList();

    return Success(<String, dynamic>{
      'avgHoursThisWeek': avgHoursThisWeek,
      'avgHoursLastWeek': avgHoursLastWeek,
      'weeklyDeltaHours': weeklyDeltaHours,
      'caffeineTooCloseNights': flagged.length,
      'caffeineTooCloseDates': flagged.map((log) => log.sleepStart).toList(),
    });
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - DateTime.monday));
  }

  double? _averageHoursInRange(List<SleepLog> logs, DateTime start, DateTime end) {
    final inRange = logs.where((log) => !log.sleepStart.isBefore(start) && log.sleepStart.isBefore(end)).toList();
    if (inRange.isEmpty) {
      return null;
    }
    final totalMinutes = inRange.fold<int>(0, (sum, log) => sum + log.duration.inMinutes);
    return totalMinutes / inRange.length / 60;
  }
}
