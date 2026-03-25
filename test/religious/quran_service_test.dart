import 'package:abdalsalam/data/repositories/religious/quran_repository.dart';
import 'package:abdalsalam/features/religious/services/quran_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuranService', () {
    late QuranService service;

    setUp(() {
      final logger = const LoggerService();
      final repository = QuranRepository(logger);
      service = QuranService(repository, logger);
    });

    test('logs progress and reports statistics', () async {
      final result = await service.logProgress(
        userId: 'u1',
        pagesRead: 8,
        minutesSpent: 25,
      );

      expect(result.isSuccess, isTrue);

      final stats = await service.getStatistics();
      expect(stats.isSuccess, isTrue);
      expect(stats.data?['totalLogs'], 1);
      expect(stats.data?['totalPages'], 8);
      expect(stats.data?['totalMinutes'], 25);
    });

    test('rejects invalid progress values', () async {
      final result = await service.logProgress(
        userId: 'u1',
        pagesRead: 0,
        minutesSpent: 20,
      );

      expect(result.isFailure, isTrue);
    });
  });
}
