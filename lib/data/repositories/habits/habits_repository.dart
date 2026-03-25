import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/habits/habit.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class HabitsRepository extends BaseRepository<Habit> {
  Future<Result<List<Habit>, AppError>> getByCategory(String category);
}

class HabitsRepositoryImpl extends BaseRepositoryImpl<Habit>
    implements HabitsRepository {
  HabitsRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'habits';

  @override
  Habit fromJson(Map<String, dynamic> json) => Habit.fromJson(json);

  @override
  Future<Result<List<Habit>, AppError>> getByCategory(String category) {
    return query(<String, dynamic>{'category': category});
  }
}
