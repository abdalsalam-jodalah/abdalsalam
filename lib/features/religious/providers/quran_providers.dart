import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/religious/quran_progress.dart';
import '../../../data/repositories/religious/quran_repository.dart';
import 'prayer_providers.dart';
import '../services/quran_service.dart';

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  final logger = ref.watch(loggerProvider);
  return QuranRepository(logger);
});

final quranServiceProvider = Provider<QuranService>((ref) {
  final logger = ref.watch(loggerProvider);
  final repository = ref.watch(quranRepositoryProvider);
  return QuranService(repository, logger);
});

final quranProgressControllerProvider =
    AsyncNotifierProvider<QuranProgressController, List<QuranProgress>>(
  QuranProgressController.new,
);

final quranPagesTodayProvider = Provider<int>((ref) {
  final value = ref.watch(quranProgressControllerProvider);
  return value.maybeWhen(
    data: (logs) => logs.fold<int>(0, (sum, item) => sum + item.pagesRead),
    orElse: () => 0,
  );
});

class QuranProgressController extends AsyncNotifier<List<QuranProgress>> {
  @override
  Future<List<QuranProgress>> build() async {
    final service = ref.read(quranServiceProvider);
    final result = await service.getTodayProgress(demoUserId);
    return result.data ?? <QuranProgress>[];
  }

  Future<String?> addProgress({
    required int pagesRead,
    required int minutesSpent,
  }) async {
    final service = ref.read(quranServiceProvider);
    final result = await service.logProgress(
      userId: demoUserId,
      pagesRead: pagesRead,
      minutesSpent: minutesSpent,
    );

    if (result.isFailure) {
      return result.error!.toString();
    }

    state = const AsyncLoading();
    state = AsyncData(await build());
    return null;
  }
}
