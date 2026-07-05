import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/planning/review.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class ReviewRepository extends BaseRepository<Review> {
  Future<Result<List<Review>, AppError>> getByPeriod(ReviewPeriod period);
}

class ReviewRepositoryImpl extends BaseRepositoryImpl<Review>
    implements ReviewRepository {
  ReviewRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'life_reviews';

  @override
  Review fromJson(Map<String, dynamic> json) => Review.fromJson(json);

  @override
  Future<Result<List<Review>, AppError>> getByPeriod(ReviewPeriod period) {
    return query(<String, dynamic>{'period': period.name});
  }
}
