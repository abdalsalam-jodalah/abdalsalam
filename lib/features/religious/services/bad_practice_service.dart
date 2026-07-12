import 'package:uuid/uuid.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/religious/bad_practice_log.dart';
import '../../../data/repositories/religious/bad_practice_log_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class BadPracticeService extends BaseServiceImpl<BadPracticeLog> {
  static const _uuid = Uuid();

  BadPracticeService(super.repository, super.logger);

  BadPracticeLogRepository get _repo => repository as BadPracticeLogRepository;

  @override
  String get serviceName => 'BadPracticeService';

  @override
  String get version => '1.0.0';

  @override
  BadPracticeLog fromJson(Map<String, dynamic> json) => BadPracticeLog.fromJson(json);

  Future<Result<BadPracticeLog, AppError>> logEvent({
    required String userId,
    required String title,
    required DateTime occurredAt,
    String? feelingBefore,
    String? feelingAfter,
    String? consequences,
    String? notes,
  }) async {
    final now = DateTime.now();
    final entity = BadPracticeLog(
      id: _uuid.v4(),
      createdAt: now,
      updatedAt: now,
      userId: userId,
      title: title,
      occurredAt: occurredAt,
      feelingBefore: feelingBefore,
      feelingAfter: feelingAfter,
      consequences: consequences,
      notes: notes,
    );
    return create(entity);
  }

  Future<Result<List<BadPracticeLog>, AppError>> getHistory(String userId) {
    return _repo.getByUserId(userId);
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final allResult = await _repo.getAll();
    if (allResult.isFailure) {
      return Failure(allResult.error!);
    }

    final all = allResult.data!;
    final byTitle = <String, int>{};
    for (final item in all) {
      byTitle[item.title] = (byTitle[item.title] ?? 0) + 1;
    }

    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final thisWeekCount =
        all.where((item) => !item.occurredAt.isBefore(startOfWeek)).length;

    return Success(<String, dynamic>{
      'totalLogs': all.length,
      'thisWeekCount': thisWeekCount,
      'byTitle': byTitle,
    });
  }

  @override
  Result<void, AppError> validate(BadPracticeLog entity) {
    if (entity.userId.trim().isEmpty) {
      return Failure(
        ValidationError(
          'Validation failed',
          fieldErrors: const <String, String>{'userId': 'userId is required'},
        ),
      );
    }
    if (entity.title.trim().isEmpty) {
      return Failure(
        ValidationError(
          'Validation failed',
          fieldErrors: const <String, String>{'title': 'title is required'},
        ),
      );
    }
    if (entity.occurredAt.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      return Failure(
        ValidationError(
          'Validation failed',
          fieldErrors: const <String, String>{
            'occurredAt': 'occurredAt cannot be in the future',
          },
        ),
      );
    }
    return const Success(null);
  }
}
