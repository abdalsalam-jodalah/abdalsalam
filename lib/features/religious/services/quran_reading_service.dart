import 'package:uuid/uuid.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/religious/quran_reading.dart';
import '../../../data/repositories/religious/quran_reading_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class QuranReadingService extends BaseServiceImpl<QuranReading> {
  static const _uuid = Uuid();

  QuranReadingService(super.repository, super.logger);

  QuranReadingRepository get _repo => repository as QuranReadingRepository;

  @override
  String get serviceName => 'QuranReadingService';

  @override
  String get version => '1.0.0';

  @override
  QuranReading fromJson(Map<String, dynamic> json) => QuranReading.fromJson(json);

  Future<Result<QuranReading, AppError>> logReading({
    required String userId,
    required int surahNumber,
    required int ayahFrom,
    required int ayahTo,
    required int durationMinutes,
    required int pagesRead,
    required bool memorized,
    String? place,
    DateTime? readAt,
  }) async {
    final now = DateTime.now();
    final entity = QuranReading(
      id: _uuid.v4(),
      createdAt: now,
      updatedAt: now,
      userId: userId,
      surahNumber: surahNumber,
      ayahFrom: ayahFrom,
      ayahTo: ayahTo,
      readAt: readAt ?? now,
      durationMinutes: durationMinutes,
      memorized: memorized,
      pagesRead: pagesRead,
      place: place,
    );
    return create(entity);
  }

  Future<Result<List<QuranReading>, AppError>> getTodayReadings(String userId) async {
    final all = await _repo.getByUserId(userId);
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final today = DateTime.now();
    final logs = all.data!
        .where(
          (item) =>
              item.readAt.year == today.year &&
              item.readAt.month == today.month &&
              item.readAt.day == today.day,
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
    final totalMinutes = all.fold<int>(0, (sum, item) => sum + item.durationMinutes);
    final memorizedCount = all.where((item) => item.memorized).length;
    final byPlace = <String, int>{};
    for (final item in all) {
      final place = item.place ?? 'unspecified';
      byPlace[place] = (byPlace[place] ?? 0) + 1;
    }

    return Success(<String, dynamic>{
      'totalLogs': all.length,
      'totalPages': totalPages,
      'totalMinutes': totalMinutes,
      'memorizedCount': memorizedCount,
      'byPlace': byPlace,
    });
  }

  @override
  Result<void, AppError> validate(QuranReading entity) {
    if (entity.userId.trim().isEmpty) {
      return Failure(
        ValidationError(
          'Validation failed',
          fieldErrors: const <String, String>{'userId': 'userId is required'},
        ),
      );
    }

    if (entity.surahNumber < 1 || entity.surahNumber > 114) {
      return Failure(
        ValidationError(
          'Validation failed',
          fieldErrors: const <String, String>{
            'surahNumber': 'surahNumber must be between 1 and 114',
          },
        ),
      );
    }

    if (entity.ayahTo < entity.ayahFrom) {
      return Failure(
        ValidationError(
          'Validation failed',
          fieldErrors: const <String, String>{
            'ayahTo': 'ayahTo must be greater than or equal to ayahFrom',
          },
        ),
      );
    }

    if (entity.pagesRead < 0) {
      return Failure(
        ValidationError(
          'Validation failed',
          fieldErrors: const <String, String>{
            'pagesRead': 'pagesRead cannot be negative',
          },
        ),
      );
    }

    if (entity.durationMinutes <= 0) {
      return Failure(
        ValidationError(
          'Validation failed',
          fieldErrors: const <String, String>{
            'durationMinutes': 'durationMinutes must be greater than zero',
          },
        ),
      );
    }

    return const Success(null);
  }
}
