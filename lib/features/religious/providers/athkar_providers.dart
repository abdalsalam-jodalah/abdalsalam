import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/religious/athkar_content.dart';
import '../../../data/models/religious/athkar_log.dart';
import '../../../data/repositories/religious/athkar_content_repository.dart';
import '../../../data/repositories/religious/athkar_log_repository.dart';
import '../../../providers/app_providers.dart';
import '../services/athkar_service.dart';
import 'prayer_providers.dart';

final athkarContentRepositoryProvider = Provider<AthkarContentRepository>((ref) {
  final logger = ref.watch(loggerProvider);
  final storage = ref.watch(storageGatewayProvider);
  return AthkarContentRepository(storage, logger);
});

final athkarLogRepositoryProvider = Provider<AthkarLogRepository>((ref) {
  final logger = ref.watch(loggerProvider);
  final storage = ref.watch(storageGatewayProvider);
  return AthkarLogRepository(storage, logger);
});

final athkarServiceProvider = Provider<AthkarService>((ref) {
  final logger = ref.watch(loggerProvider);
  final contentRepo = ref.watch(athkarContentRepositoryProvider);
  final logsRepo = ref.watch(athkarLogRepositoryProvider);
  final reminders = ref.watch(reminderServiceProvider);
  final settings = ref.watch(settingsServiceProvider);
  return AthkarService(
    contentRepo,
    logsRepo,
    logger,
    reminders: reminders,
    settings: settings,
  );
});

final athkarCategoryProvider =
    FutureProvider.family<List<AthkarContent>, AthkarCategory?>((ref, category) async {
  final service = ref.watch(athkarServiceProvider);
  final result = await service.getMerged(category: category);
  return result.data ?? <AthkarContent>[];
});

final athkarSuggestionsProvider = FutureProvider<List<AthkarCategory>>((ref) async {
  final service = ref.watch(athkarServiceProvider);
  final result = await service.getCategoriesForNow();
  return result.getOrThrow();
});

final athkarLogsControllerProvider =
    AsyncNotifierProvider<AthkarLogsController, List<AthkarLog>>(
  AthkarLogsController.new,
);

final athkarTodayCountProvider = Provider<int>((ref) {
  final value = ref.watch(athkarLogsControllerProvider);
  return value.maybeWhen(
    data: (logs) {
      final now = DateTime.now();
      return logs
          .where(
            (log) =>
                log.completedAt.year == now.year &&
                log.completedAt.month == now.month &&
                log.completedAt.day == now.day,
          )
          .length;
    },
    orElse: () => 0,
  );
});

/// Completions per category over the last 7 days — feeds a bar chart, one
/// bar per [AthkarCategory] in enum order.
final athkarWeeklyCompletionsByCategoryProvider = Provider<List<double>>((ref) {
  final value = ref.watch(athkarLogsControllerProvider);
  final logs = value.maybeWhen(data: (logs) => logs, orElse: () => <AthkarLog>[]);
  final start = DateTime.now().subtract(const Duration(days: 7));

  return [
    for (final category in AthkarCategory.values)
      logs
          .where((log) => log.category == category && log.completedAt.isAfter(start))
          .length
          .toDouble(),
  ];
});

class AthkarLogsController extends AsyncNotifier<List<AthkarLog>> {
  @override
  Future<List<AthkarLog>> build() async {
    final repo = ref.read(athkarLogRepositoryProvider);
    final result = await repo.getByUserId(demoUserId);
    return result.data ?? <AthkarLog>[];
  }

  Future<String?> logCompletion({
    required AthkarContent content,
    required int countDone,
    String? notes,
  }) async {
    final service = ref.read(athkarServiceProvider);
    final result = await service.logCompletion(
      userId: demoUserId,
      content: content,
      countDone: countDone,
      notes: notes,
    );

    if (result.isFailure) {
      return result.error!.toString();
    }

    state = const AsyncLoading();
    state = AsyncData(await build());
    return null;
  }

  Future<String?> addCustomAthkar({
    required String arabicText,
    String? transliteration,
    String? translation,
    required AthkarCategory category,
    required int targetCount,
    String? reference,
  }) async {
    final service = ref.read(athkarServiceProvider);
    final result = await service.addCustomAthkar(
      arabicText: arabicText,
      transliteration: transliteration,
      translation: translation,
      category: category,
      targetCount: targetCount,
      reference: reference,
    );

    if (result.isFailure) {
      return result.error!.toString();
    }

    ref.invalidate(athkarCategoryProvider);
    return null;
  }

  Future<String?> deleteCustomAthkar(String id) async {
    final service = ref.read(athkarServiceProvider);
    final result = await service.deleteCustomAthkar(id);

    if (result.isFailure) {
      return result.error!.toString();
    }

    ref.invalidate(athkarCategoryProvider);
    return null;
  }
}
