import '../../../core/result/result.dart';
import '../../../core/errors/financial_errors.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/infrastructure/storage_gateway.dart';
import '../../../data/models/financial/category_model.dart';
import '../../../data/repositories/financial/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final StorageGateway _storage;
  final LoggerService _logger;
  static const String _tableName = 'categories';

  CategoryRepositoryImpl(this._storage, this._logger);

  @override
  Future<Result<CategoryModel, Error>> create(CategoryModel category) async {
    try {
      await _storage.upsertRecord(
        table: _tableName,
        id: category.id,
        record: category.toJson(),
        userId: category.userId,
      );
      _logger.info('Category created: ${category.id}');
      return Success(category);
    } catch (e, st) {
      _logger.error('Failed to create category', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<CategoryModel?, Error>> getById(String id) async {
    try {
      final record = await _storage.getRecord(table: _tableName, id: id);
      if (record == null) {
        return const Success(null);
      }
      return Success(CategoryModel.fromJson(record));
    } catch (e, st) {
      _logger.error('Failed to get category', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<CategoryModel>, Error>> getAll() async {
    try {
      final records = await _storage.getAllRecords(table: _tableName);
      final categories = records
          .map((r) => CategoryModel.fromJson(r))
          .where((c) => c.deletedAt == null)
          .toList();
      return Success(categories);
    } catch (e, st) {
      _logger.error('Failed to get all categories', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<CategoryModel>, Error>> getByType(CategoryType type) async {
    try {
      final allResult = await getAll();
      if (allResult.isFailure) {
        return Failure(allResult.error!);
      }

      final filtered = allResult.data!.where((c) => c.type == type).toList();
      return Success(filtered);
    } catch (e, st) {
      _logger.error('Failed to get categories by type', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, Error>> update(CategoryModel category) async {
    try {
      final updated = category.copyWith(updatedAt: DateTime.now());
      await _storage.upsertRecord(
        table: _tableName,
        id: updated.id,
        record: updated.toJson(),
        userId: updated.userId,
      );
      _logger.info('Category updated: ${category.id}');
      return const Success(null);
    } catch (e, st) {
      _logger.error('Failed to update category', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, Error>> delete(String id) async {
    try {
      await _storage.deleteRecord(table: _tableName, id: id);
      _logger.info('Category deleted: $id');
      return const Success(null);
    } catch (e, st) {
      _logger.error('Failed to delete category', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }
}
