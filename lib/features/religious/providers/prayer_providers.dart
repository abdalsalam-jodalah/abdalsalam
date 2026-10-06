import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../data/models/religious/prayer_log.dart';
import '../../../data/models/religious/prayer_times_snapshot.dart';
import '../../../data/repositories/religious/prayer_repository.dart';
import '../../../providers/app_providers.dart';
import '../services/prayer_service.dart';
import '../services/religious_service.dart';
import 'religious_tracking_providers.dart';

const demoUserId = 'local-user';

final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  final logger = ref.watch(loggerProvider);
  final storage = ref.watch(storageGatewayProvider);
  return PrayerRepositoryImpl(storage, logger);
});

final prayerServiceProvider = Provider<PrayerService>((ref) {
  final logger = ref.watch(loggerProvider);
  final repository = ref.watch(prayerRepositoryProvider);
  return PrayerService(repository, logger);
});

final religiousServiceProvider = Provider<ReligiousService>((ref) {
  final logger = ref.watch(loggerProvider);
  final repository = ref.watch(prayerRepositoryProvider);
  final reminderService = ref.watch(reminderServiceProvider);
  return ReligiousService(repository, logger, reminders: reminderService);
});

final prayerLogsControllerProvider =
    AsyncNotifierProvider<PrayerLogsController, List<PrayerLog>>(
  PrayerLogsController.new,
);

final prayerCountProvider = Provider<int>((ref) {
  final value = ref.watch(prayerLogsControllerProvider);
  return value.maybeWhen(data: (logs) => logs.where((log) => log.prayerName.isObligatory).length, orElse: () => 0);
});

final voluntaryPrayerCountProvider = Provider<int>((ref) {
  final value = ref.watch(prayerLogsControllerProvider);
  return value.maybeWhen(data: (logs) => logs.where((log) => log.prayerName.isVoluntary).length, orElse: () => 0);
});

final religiousStreakProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(religiousServiceProvider);
  final result = await service.getStatistics();
  final stats = result.getOrThrow();
  return (stats['currentStreak'] as int?) ?? 0;
});

final prayerAllLogsProvider = FutureProvider<List<PrayerLog>>((ref) async {
  final repo = ref.watch(prayerRepositoryProvider);
  final result = await repo.getByUserId(demoUserId);
  return result.getOrThrow();
});

class PrayerLogsController extends AsyncNotifier<List<PrayerLog>> {
  @override
  Future<List<PrayerLog>> build() async {
    final service = ref.read(prayerServiceProvider);
    final result = await service.getTodayLogs(demoUserId);
    return result.getOrThrow();
  }

  Future<AppError?> addPrayer({
    required PrayerName prayer,
    bool? onTimeOverride,
    String? notes,
    DateTime? prayedAt,
  }) async {
    final service = ref.read(prayerServiceProvider);
    final actualPrayedAt = prayedAt ?? DateTime.now();

    DateTime? scheduledAt;
    try {
      if (prayer.isObligatory) {
        final snapshot = await ref.read(todayPrayerTimesProvider.future);
        scheduledAt = scheduledTimeForPrayer(prayer, snapshot);
      }
    } catch (error, stackTrace) {
      ref.read(loggerProvider).error(
            'Could not resolve today\'s scheduled prayer time for $prayer; '
            'defaulting the on-time check to true.',
            error: error,
            stackTrace: stackTrace,
          );
      scheduledAt = null;
    }

    final onTime = onTimeOverride ??
        (scheduledAt == null
            ? true
            : service.computeDelta(prayedAt: actualPrayedAt, scheduledAt: scheduledAt).abs() <=
                const Duration(minutes: 30));

    final result = await service.logPrayer(
      userId: demoUserId,
      prayerName: prayer,
      onTime: onTime,
      notes: notes,
      prayedAt: actualPrayedAt,
      scheduledAt: scheduledAt,
    );

    if (result.isFailure) {
      return result.error;
    }

    state = await AsyncValue.guard(() => build());
    ref.invalidate(prayerAllLogsProvider);
    return null;
  }
}

DateTime? scheduledTimeForPrayer(PrayerName prayer, PrayerTimesSnapshot snapshot) {
  return switch (prayer) {
    PrayerName.fajr => snapshot.fajr,
    PrayerName.dhuhr => snapshot.dhuhr,
    PrayerName.asr => snapshot.asr,
    PrayerName.maghrib => snapshot.maghrib,
    PrayerName.isha => snapshot.isha,
    PrayerName.voluntary => null,
  };
}
