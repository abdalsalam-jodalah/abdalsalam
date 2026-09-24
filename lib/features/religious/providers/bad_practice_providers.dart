import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../data/models/religious/bad_practice_log.dart';
import '../../../data/repositories/religious/bad_practice_log_repository.dart';
import '../../../providers/app_providers.dart';
import '../services/bad_practice_service.dart';
import 'prayer_providers.dart';

final badPracticeLogRepositoryProvider = Provider<BadPracticeLogRepository>((ref) {
  final logger = ref.watch(loggerProvider);
  final storage = ref.watch(storageGatewayProvider);
  return BadPracticeLogRepository(storage, logger);
});

final badPracticeServiceProvider = Provider<BadPracticeService>((ref) {
  final logger = ref.watch(loggerProvider);
  final repository = ref.watch(badPracticeLogRepositoryProvider);
  return BadPracticeService(repository, logger);
});

final badPracticeLogControllerProvider =
    AsyncNotifierProvider<BadPracticeLogController, List<BadPracticeLog>>(
  BadPracticeLogController.new,
);

/// Weekly frequency over the last 8 weeks, oldest first — feeds a trend chart.
final badPracticeWeeklyTrendProvider = Provider<List<double>>((ref) {
  final value = ref.watch(badPracticeLogControllerProvider);
  final logs = value.maybeWhen(data: (logs) => logs, orElse: () => <BadPracticeLog>[]);

  final now = DateTime.now();
  final currentWeekStart =
      DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

  return List<double>.generate(8, (i) {
    final weekStart = currentWeekStart.subtract(Duration(days: 7 * (7 - i)));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return logs
        .where((log) => !log.occurredAt.isBefore(weekStart) && log.occurredAt.isBefore(weekEnd))
        .length
        .toDouble();
  });
});

class BadPracticeLogController extends AsyncNotifier<List<BadPracticeLog>> {
  @override
  Future<List<BadPracticeLog>> build() async {
    final service = ref.read(badPracticeServiceProvider);
    final result = await service.getHistory(demoUserId);
    return result.getOrThrow();
  }

  Future<AppError?> logEvent({
    required String title,
    required DateTime occurredAt,
    String? feelingBefore,
    String? feelingAfter,
    String? consequences,
    String? notes,
  }) async {
    final service = ref.read(badPracticeServiceProvider);
    final result = await service.logEvent(
      userId: demoUserId,
      title: title,
      occurredAt: occurredAt,
      feelingBefore: feelingBefore,
      feelingAfter: feelingAfter,
      consequences: consequences,
      notes: notes,
    );

    if (result.isFailure) {
      return result.error;
    }

    state = await AsyncValue.guard(() => build());
    return null;
  }
}
