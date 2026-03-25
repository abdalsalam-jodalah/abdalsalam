import 'package:uuid/uuid.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/religious/quran_progress.dart';
import '../../../data/repositories/religious/quran_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class QuranService extends BaseServiceImpl<QuranProgress> {
  static const _uuid = Uuid();

  QuranService(super.repository, super.logger);

  QuranRepository get _repo => repository as QuranRepository;

  @override
  String get serviceName => 'QuranService';

  @override
  String get version => '1.0.0';

  @override
  QuranProgress fromJson(Map<String, dynamic> json) {
    return QuranProgress.fromJson(json);
  }

  Future<Result<QuranProgress, AppError>> logProgress({
    required String userId,
    required int pagesRead,
    required int minutesSpent,
  }) async {
    final now = DateTime.now();
    final entity = QuranProgress(
      id: _uuid.v4(),
      createdAt: now,
      updatedAt: now,
      userId: userId,
      pagesRead: pagesRead,
      minutesSpent: minutesSpent,
      loggedAt: now,
    );
    return create(entity);
  }

  Future<Result<List<QuranProgress>, AppError>> getTodayProgress(String userId) async {
    final all = await _repo.getByUserId(userId);
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final today = DateTime.now();
    final logs = all.data!
        .where(
          (item) =>
              item.loggedAt.year == today.year &&
              item.loggedAt.month == today.month &&
              item.loggedAt.day == today.day,
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
    final totalPages = all.fold<int>(0, (sum, item) => sum + item.pagesRead);
    final totalMinutes = all.fold<int>(0, (sum, item) => sum + item.minutesSpent);

    return Success(<String, dynamic>{
      'totalLogs': all.length,
      'totalPages': totalPages,
      'totalMinutes': totalMinutes,
      'avgPagesPerLog': all.isEmpty ? 0.0 : totalPages / all.length,
    });
  }

  @override
  Result<void, AppError> validate(QuranProgress entity) {
    if (entity.userId.trim().isEmpty) {
      return Failure(
        ValidationError(
          'Validation failed',
          fieldErrors: const <String, String>{'userId': 'userId is required'},
        ),
      );
    }

    if (entity.pagesRead <= 0) {
      return Failure(
        ValidationError(
          'Validation failed',
          fieldErrors: const <String, String>{
            'pagesRead': 'pagesRead must be greater than zero',
          },
        ),
      );
    }

    if (entity.minutesSpent <= 0) {
      return Failure(
        ValidationError(
          'Validation failed',
          fieldErrors: const <String, String>{
            'minutesSpent': 'minutesSpent must be greater than zero',
          },
        ),
      );
    }

    if (entity.loggedAt.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      return Failure(
        ValidationError(
          'Validation failed',
          fieldErrors: const <String, String>{
            'loggedAt': 'loggedAt cannot be in the future',
          },
        ),
      );
    }

    return const Success(null);
  }
}
