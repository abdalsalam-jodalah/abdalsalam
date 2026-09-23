import 'package:abdalsalam/data/models/planning/review.dart';
import 'package:abdalsalam/data/repositories/planning/review_repository.dart';
import 'package:abdalsalam/features/planning/services/review_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/failing_writes.dart';
import '../support/test_storage.dart';
import '../support/validation_expectations.dart';

class _FailingReviewRepository = ReviewRepositoryImpl with FailingWrites<Review>;

final DateTime _periodStart = DateTime(2026, 1, 5);
final DateTime _periodEnd = DateTime(2026, 1, 11);

Review _review({
  String userId = 'u1',
  DateTime? periodStart,
  DateTime? periodEnd,
  int? rating = 4,
  String? wins = 'Shipped the release',
}) {
  final now = DateTime(2026, 1, 11);
  return Review(
    id: 'review-1',
    createdAt: now,
    updatedAt: now,
    userId: userId,
    period: ReviewPeriod.weekly,
    periodStart: periodStart ?? _periodStart,
    periodEnd: periodEnd ?? _periodEnd,
    rating: rating,
    wins: wins,
  );
}

void main() {
  initializeTestDatabaseFactory();

  late LoggerService logger;
  late ReviewService service;

  setUp(() async {
    await resetTestStorage(databaseName: 'test_review_service_test.db', tables: ['life_reviews']);
    logger = LoggerService.forModule('ReviewServiceTest');
    service = ReviewService(ReviewRepositoryImpl(StorageGateway.instance, logger), logger);
  });

  group('ReviewService.validate', () {
    test('should succeed for a well-formed review', () {
      expect(service.validate(_review()).isSuccess, isTrue);
    });

    test('should succeed when rating is absent', () {
      expect(service.validate(_review(rating: null)).isSuccess, isTrue);
    });

    test('should report userId when userId is blank', () {
      expectFieldError(service.validate(_review(userId: '')), ReviewService.userIdField);
    });

    test('should report periodEnd when it is before periodStart', () {
      final result = service.validate(_review(periodEnd: _periodStart.subtract(const Duration(days: 1))));
      expectFieldError(result, ReviewService.periodEndField);
    });

    test('should report rating when rating is below 1', () {
      expectFieldError(service.validate(_review(rating: 0)), ReviewService.ratingField);
    });

    test('should report rating when rating is above 5', () {
      expectFieldError(service.validate(_review(rating: 6)), ReviewService.ratingField);
    });
  });

  group('ReviewService writes', () {
    test('should persist a created review', () async {
      final result = await service.create(_review());

      expect(result.isSuccess, isTrue);
      final stored = await service.getByPeriod(ReviewPeriod.weekly);
      expect(stored.data?.map((review) => review.id), ['review-1']);
    });

    test('should persist an updated review', () async {
      await service.create(_review());

      final result = await service.update(_review(wins: 'Closed every open bug'));

      expect(result.isSuccess, isTrue);
      final stored = await service.getById('review-1');
      expect(stored.data?.wins, 'Closed every open bug');
    });

    test('should propagate a repository create failure', () async {
      final failingService = ReviewService(_FailingReviewRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.create(_review()));
    });

    test('should propagate a repository update failure', () async {
      final failingService = ReviewService(_FailingReviewRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.update(_review()));
    });
  });
}
