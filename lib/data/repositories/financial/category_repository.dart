import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/financial/category_model.dart';

abstract class CategoryRepository {
  Future<Result<CategoryModel, AppError>> create(CategoryModel category);
  Future<Result<CategoryModel?, AppError>> getById(String id);
  Future<Result<List<CategoryModel>, AppError>> getAll();
  Future<Result<List<CategoryModel>, AppError>> getByType(CategoryType type);
  Future<Result<void, AppError>> update(CategoryModel category);
  Future<Result<void, AppError>> delete(String id);
}
