import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/infrastructure/storage_gateway.dart';
import '../../../data/models/financial/category_model.dart';
import '../../../data/repositories/financial/category_repository.dart';
import '../../../data/repositories/record_parser.dart';
import '../../../data/repositories/repository_operation_guard.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final StorageGateway _storage;
  final LoggerService _logger;
  static const String _tableName = 'categories';

  CategoryRepositoryImpl(this._storage, this._logger);

  RepositoryOperationGuard get _guard => RepositoryOperationGuard(table: _tableName, logger: _logger);

  RecordParser<CategoryModel> get _parser => RecordParser<CategoryModel>(
        table: _tableName,
        fromJson: CategoryModel.fromJson,
        integrityReporter: _storage.integrityReporter,
      );

  @override
  Future<Result<CategoryModel, AppError>> create(CategoryModel category) {
    return _guard.run('create', () async {
      await _storage.upsertRecord(
        table: _tableName,
        id: category.id,
        record: category.toJson(),
        userId: category.userId,
      );
      _logger.info('Category created: ${category.id}');
      return category;
    });
  }

  @override
  Future<Result<CategoryModel?, AppError>> getById(String id) {
    return _guard.run('getById', () async {
      final record = await _storage.getRecord(table: _tableName, id: id);
      if (record == null) {
        return null;
      }
      return _parser.parseOne(record);
    });
  }

  @override
  Future<Result<List<CategoryModel>, AppError>> getAll() {
    return _guard.run('getAll', _readAll);
  }

  @override
  Future<Result<List<CategoryModel>, AppError>> getByType(CategoryType type) {
    return _guard.run('getByType', () async {
      final categories = await _readAll();
      return categories.where((c) => c.type == type).toList();
    });
  }

  @override
  Future<Result<void, AppError>> update(CategoryModel category) {
    return _guard.run('update', () async {
      final updated = category.copyWith(updatedAt: DateTime.now());
      await _storage.upsertRecord(
        table: _tableName,
        id: updated.id,
        record: updated.toJson(),
        userId: updated.userId,
      );
      _logger.info('Category updated: ${category.id}');
    });
  }

  @override
  Future<Result<void, AppError>> delete(String id) {
    return _guard.run('delete', () async {
      await _storage.deleteRecord(table: _tableName, id: id);
      _logger.info('Category deleted: $id');
    });
  }

  Future<List<CategoryModel>> _readAll() async {
    final records = await _storage.getAllRecords(table: _tableName);
    return _parser.parseAll(records).where((c) => c.deletedAt == null).toList();
  }
}
