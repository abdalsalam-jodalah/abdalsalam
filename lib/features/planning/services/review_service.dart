import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../core/validation/validation_result_factory.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/planning/review.dart';
import '../../../data/repositories/planning/review_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class ReviewService extends BaseServiceImpl<Review> {
  static const String userIdField = 'userId';
  static const String periodStartField = 'periodStart';
  static const String periodEndField = 'periodEnd';
  static const String ratingField = 'rating';
  static const int _minRating = 1;
  static const int _maxRating = 5;

  ReviewService(ReviewRepository super.repository, super.logger);

  ReviewRepository get _repo => repository as ReviewRepository;

  @override
  String get serviceName => 'ReviewService';

  @override
  String get version => '1.0.0';

  @override
  Review fromJson(Map<String, dynamic> json) => Review.fromJson(json);

  @override
  Result<void, AppError> validate(Review entity) {
    return ValidationResultFactory.fromFieldErrors(
      ValidationUtils.collect([
        MapEntry(userIdField, ValidationUtils.requiredField(entity.userId, userIdField)),
        MapEntry(
          periodEndField,
          ValidationUtils.dateRange(
            start: entity.periodStart,
            end: entity.periodEnd,
            startField: periodStartField,
            endField: periodEndField,
          ),
        ),
        MapEntry(
          ratingField,
          ValidationUtils.numericRange(
            value: entity.rating,
            fieldName: ratingField,
            min: _minRating,
            max: _maxRating,
          ),
        ),
      ]),
    );
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final active = await getActive();
    if (active.isFailure) {
      return Failure(active.error!);
    }
    final ratings = active.data!.map((review) => review.rating).whereType<int>().toList();
    return Success(<String, dynamic>{
      'totalReviews': active.data!.length,
      'averageRating': ratings.isEmpty ? null : ratings.reduce((a, b) => a + b) / ratings.length,
    });
  }

  Future<Result<List<Review>, AppError>> getByPeriod(ReviewPeriod period) {
    return _repo.getByPeriod(period);
  }
}
