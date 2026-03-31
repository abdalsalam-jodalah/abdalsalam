import '../../../core/result/result.dart';
import '../../models/financial/category_model.dart';

abstract class CategoryRepository {
  Future<Result<CategoryModel, Error>> create(CategoryModel category);
  Future<Result<CategoryModel?, Error>> getById(String id);
  Future<Result<List<CategoryModel>, Error>> getAll();
  Future<Result<List<CategoryModel>, Error>> getByType(CategoryType type);
  Future<Result<void, Error>> update(CategoryModel category);
  Future<Result<void, Error>> delete(String id);
}
