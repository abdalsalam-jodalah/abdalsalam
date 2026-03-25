import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/religious/prayer_log.dart';
import '../../../data/repositories/religious/prayer_repository.dart';
import '../../../providers/app_providers.dart';
import '../services/prayer_service.dart';

const demoUserId = 'local-user';

final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  final logger = ref.watch(loggerProvider);
  final storage = ref.watch(storageGatewayProvider);
  return PrayerRepository(storage, logger);
});

final prayerServiceProvider = Provider<PrayerService>((ref) {
  final logger = ref.watch(loggerProvider);
  final repository = ref.watch(prayerRepositoryProvider);
  return PrayerService(repository, logger);
});

final prayerLogsControllerProvider =
    AsyncNotifierProvider<PrayerLogsController, List<PrayerLog>>(
  PrayerLogsController.new,
);

final prayerCountProvider = Provider<int>((ref) {
  final value = ref.watch(prayerLogsControllerProvider);
  return value.maybeWhen(data: (logs) => logs.length, orElse: () => 0);
});

class PrayerLogsController extends AsyncNotifier<List<PrayerLog>> {
  @override
  Future<List<PrayerLog>> build() async {
    final service = ref.read(prayerServiceProvider);
    final result = await service.getTodayLogs(demoUserId);
    return result.data ?? <PrayerLog>[];
  }

  Future<String?> addPrayer({
    required PrayerName prayer,
    required bool onTime,
    String? notes,
  }) async {
    final service = ref.read(prayerServiceProvider);
    final result = await service.logPrayer(
      userId: demoUserId,
      prayerName: prayer,
      onTime: onTime,
      notes: notes,
    );

    if (result.isFailure) {
      return result.error!.toString();
    }

    state = const AsyncLoading();
    state = AsyncData(await build());
    return null;
  }
}
