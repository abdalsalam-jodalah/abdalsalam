import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/religious/prayer_times_snapshot.dart';
import '../../../data/models/religious/religious_entry.dart';
import '../../../data/repositories/religious/prayer_times_snapshot_repository.dart';
import '../../../data/repositories/religious/religious_entry_repository.dart';
import '../../../providers/app_providers.dart';
import '../services/religious_tracker_service.dart';

const religiousDemoUserId = 'local-user';

final religiousEntryRepositoryProvider = Provider<ReligiousEntryRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = ref.watch(loggerProvider);
  return ReligiousEntryRepository(storage, logger);
});

final prayerTimesSnapshotRepositoryProvider = Provider<PrayerTimesSnapshotRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = ref.watch(loggerProvider);
  return PrayerTimesSnapshotRepository(storage, logger);
});

final religiousTrackerServiceProvider = Provider<ReligiousTrackerService>((ref) {
  final entryRepo = ref.watch(religiousEntryRepositoryProvider);
  final snapshotRepo = ref.watch(prayerTimesSnapshotRepositoryProvider);
  final logger = ref.watch(loggerProvider);
  final reminders = ref.watch(reminderServiceProvider);
  final settings = ref.watch(settingsServiceProvider);

  return ReligiousTrackerService(
    entryRepo,
    snapshotRepo,
    logger,
    reminders: reminders,
    settings: settings,
  );
});

final religiousSyncSchedulerProvider = Provider<ReligiousPrayerSyncScheduler>((ref) {
  final scheduler = ReligiousPrayerSyncScheduler(
    service: ref.watch(religiousTrackerServiceProvider),
    logger: ref.watch(loggerProvider),
  );
  ref.onDispose(scheduler.dispose);
  return scheduler;
});

final todayPrayerTimesProvider = FutureProvider<PrayerTimesSnapshot>((ref) async {
  final service = ref.watch(religiousTrackerServiceProvider);
  final result = await service.getTodayPrayerTimes();
  if (result.isFailure) {
    throw result.error!;
  }
  return result.data!;
});

final religiousLogsControllerProvider =
    AsyncNotifierProvider<ReligiousLogsController, List<ReligiousEntry>>(
  ReligiousLogsController.new,
);

final todayReligiousLogsProvider = Provider<List<ReligiousEntry>>((ref) {
  final state = ref.watch(religiousLogsControllerProvider);
  return state.maybeWhen(
    data: (items) {
      final now = DateTime.now();
      return items
          .where(
            (entry) =>
                entry.loggedAt.year == now.year &&
                entry.loggedAt.month == now.month &&
                entry.loggedAt.day == now.day,
          )
          .toList(growable: false);
    },
    orElse: () => <ReligiousEntry>[],
  );
});

final todayPrayerCountProvider = Provider<int>((ref) {
  final today = ref.watch(todayReligiousLogsProvider);
  return today
      .where((entry) => entry.type == ReligiousEntryType.prayer)
      .fold<int>(0, (sum, entry) => sum + entry.count);
});

class ReligiousLogsController extends AsyncNotifier<List<ReligiousEntry>> {
  @override
  Future<List<ReligiousEntry>> build() async {
    final service = ref.read(religiousTrackerServiceProvider);
    final result = await service.getHistory(religiousDemoUserId);
    return result.data ?? <ReligiousEntry>[];
  }

  Future<String?> addEntry({
    required ReligiousEntryType type,
    required String title,
    required int count,
    String? details,
    String? prayerName,
    DateTime? reminderAt,
  }) async {
    final service = ref.read(religiousTrackerServiceProvider);
    final result = await service.logEntry(
      userId: religiousDemoUserId,
      type: type,
      title: title,
      count: count,
      details: details,
      prayerName: prayerName,
      reminderAt: reminderAt,
    );

    if (result.isFailure) {
      return result.error!.toString();
    }

    state = const AsyncLoading();
    state = AsyncData(await build());
    return null;
  }

  Future<String?> syncPrayerTimes() async {
    final service = ref.read(religiousTrackerServiceProvider);
    final result = await service.syncPrayerTimesForToday(force: true);
    if (result.isFailure) {
      return result.error!.toString();
    }
    ref.invalidate(todayPrayerTimesProvider);
    return null;
  }
}
