import 'package:uuid/uuid.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/religious/prayer_log.dart';
import '../../../data/repositories/religious/prayer_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class PrayerService extends BaseServiceImpl<PrayerLog> {
  static const _uuid = Uuid();

  PrayerService(super.repository, super.logger);

  PrayerRepository get _repo => repository as PrayerRepository;

  @override
  String get serviceName => 'PrayerService';

  @override
  String get version => '1.0.0';

  @override
  PrayerLog fromJson(Map<String, dynamic> json) {
    return PrayerLog.fromJson(json);
  }

  Future<Result<PrayerLog, AppError>> logPrayer({
    required String userId,
    required PrayerName prayerName,
    required bool onTime,
    String? notes,
    DateTime? prayedAt,
    DateTime? scheduledAt,
  }) async {
    final now = DateTime.now();
    final entity = PrayerLog(
      id: _uuid.v4(),
      createdAt: now,
      updatedAt: now,
      userId: userId,
      prayerName: prayerName,
      prayedAt: prayedAt ?? now,
      onTime: onTime,
      notes: notes,
      scheduledAt: scheduledAt,
    );
    return create(entity);
  }

  /// Difference between when a prayer was actually performed and its
  /// scheduled time. Positive = late, negative = early.
  Duration computeDelta({required DateTime prayedAt, required DateTime scheduledAt}) {
    return prayedAt.difference(scheduledAt);
  }

  Future<Result<List<PrayerLog>, AppError>> getTodayLogs(String userId) async {
    final all = await _repo.getByUserId(userId);
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final today = DateTime.now();
    final logs = all.data!
        .where(
          (item) =>
              item.prayedAt.year == today.year &&
              item.prayedAt.month == today.month &&
              item.prayedAt.day == today.day,
        )
        .toList(growable: false);

    return Success(logs);
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final allResult = await _repo.getAll();
    if (allResult.isFailure) {
      return Failure(allResult.error!);
    }

    final all = allResult.data!;
    final onTimeCount = all.where((entry) => entry.onTime).length;

    final byPrayer = <String, int>{
      for (final prayer in PrayerName.values)
        prayer.name: all.where((entry) => entry.prayerName == prayer).length,
    };

    final percent = all.isEmpty ? 0.0 : (onTimeCount / all.length) * 100.0;

    return Success(<String, dynamic>{
      'totalLogs': all.length,
      'onTimeCount': onTimeCount,
      'onTimePercent': percent,
      'byPrayer': byPrayer,
    });
  }

  @override
  Result<void, AppError> validate(PrayerLog entity) {
    if (entity.userId.trim().isEmpty) {
      return Failure(
        ValidationError(
          'Validation failed',
          fieldErrors: const <String, String>{'userId': 'userId is required'},
        ),
      );
    }

    if (entity.prayedAt.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      return Failure(
        ValidationError(
          'Validation failed',
          fieldErrors: const <String, String>{
            'prayedAt': 'prayedAt cannot be in the future',
          },
        ),
      );
    }

    return const Success(null);
  }
}
