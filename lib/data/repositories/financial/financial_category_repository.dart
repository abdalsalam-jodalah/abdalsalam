import '../../models/financial/category.dart';
import '../base_repository_impl.dart';

class FinancialCategoryRepository extends BaseRepositoryImpl<Category> {
  FinancialCategoryRepository(super.storage, super.logger);

  @override
  String get tableName => 'financial_categories';

  @override
  Category fromJson(Map<String, dynamic> json) {
    return Category.fromJson(json);
  }
}
