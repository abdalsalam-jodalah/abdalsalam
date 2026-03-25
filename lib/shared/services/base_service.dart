import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../data/models/base_model.dart';

abstract class BaseService<T extends BaseModel> {
  String get serviceName;
  String get version;

  Future<Result<T, AppError>> create(T entity);
  Future<Result<T?, AppError>> getById(String id);
  Future<Result<List<T>, AppError>> getAll();
  Future<Result<List<T>, AppError>> getActive();
  Future<Result<List<T>, AppError>> getByDateRange(DateTime start, DateTime end);
  Future<Result<void, AppError>> update(T entity);
  Future<Result<void, AppError>> delete(String id);
  Future<Result<void, AppError>> softDelete(String id);

  Future<Result<List<T>, AppError>> createBulk(List<T> entities);
  Future<Result<void, AppError>> updateBulk(List<T> entities);
  Future<Result<void, AppError>> deleteBulk(List<String> ids);

  Future<Result<List<T>, AppError>> search(String query);
  Future<Result<List<T>, AppError>> filter(Map<String, dynamic> filters);

  Future<Result<String, AppError>> exportToJson();
  Future<Result<Map<String, dynamic>, AppError>> exportWithMetadata();
  Future<Result<void, AppError>> importFromJson(String json);
  Future<Result<void, AppError>> importWithValidation(Map<String, dynamic> data);

  Future<Result<int, AppError>> count();
  Future<Result<Map<String, dynamic>, AppError>> getStatistics();
  Future<Result<Map<String, dynamic>, AppError>> getMetadata();
  Future<Result<List<T>, AppError>> getRecent(int limit);

  Result<void, AppError> validate(T entity);
  Result<void, AppError> validateBulk(List<T> entities);

  Future<Result<String, AppError>> backup();
  Future<Result<void, AppError>> restore(String backupData);
}
