import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../models/base_model.dart';

abstract class BaseRepository<T extends BaseModel> {
  Future<Result<T, AppError>> create(T entity);
  Future<Result<T?, AppError>> getById(String id);
  Future<Result<List<T>, AppError>> getAll();
  Future<Result<List<T>, AppError>> getActive();
  Future<Result<List<T>, AppError>> getDeleted();
  Future<Result<void, AppError>> update(T entity);
  Future<Result<void, AppError>> delete(String id);
  Future<Result<void, AppError>> softDelete(String id);
  Future<Result<void, AppError>> restore(String id);

  Future<Result<List<T>, AppError>> createBulk(List<T> entities);
  Future<Result<void, AppError>> updateBulk(List<T> entities);
  Future<Result<void, AppError>> deleteBulk(List<String> ids);

  Future<Result<List<T>, AppError>> getByDateRange(DateTime start, DateTime end);
  Future<Result<List<T>, AppError>> getByUserId(String userId);
  Future<Result<List<T>, AppError>> query(Map<String, dynamic> filters);
  Future<Result<List<T>, AppError>> search(String searchTerm);

  Future<Result<int, AppError>> count();
  Future<Result<int, AppError>> countActive();
  Future<Result<int, AppError>> countDeleted();

  Future<Result<void, AppError>> deleteAll();
  Future<Result<void, AppError>> vacuum();
}
