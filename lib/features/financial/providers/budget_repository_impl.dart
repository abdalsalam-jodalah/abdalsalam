import '../../../core/result/result.dart';
import '../../../core/errors/financial_errors.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/infrastructure/storage_gateway.dart';
import '../../../data/models/financial/budget_model.dart';
import '../../../data/repositories/financial/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final StorageGateway _storage;
  final LoggerService _logger;
  static const String _tableName = 'budgets';

  BudgetRepositoryImpl(this._storage, this._logger);

  @override
  Future<Result<BudgetModel, Error>> create(BudgetModel budget) async {
    try {
      await _storage.upsertRecord(
        table: _tableName,
        id: budget.id,
        record: budget.toJson(),
        userId: budget.userId,
      );
      _logger.info('Budget created: ${budget.id}');
      return Success(budget);
    } catch (e, st) {
      _logger.error('Failed to create budget', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<BudgetModel?, Error>> getById(String id) async {
    try {
      final record = await _storage.getRecord(table: _tableName, id: id);
      if (record == null) {
        return const Success(null);
      }
      return Success(BudgetModel.fromJson(record));
    } catch (e, st) {
      _logger.error('Failed to get budget', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<BudgetModel>, Error>> getAll() async {
    try {
      final records = await _storage.getAllRecords(table: _tableName);
      final budgets = records
          .map((r) => BudgetModel.fromJson(r))
          .where((b) => b.deletedAt == null)
          .toList();
      return Success(budgets);
    } catch (e, st) {
      _logger.error('Failed to get all budgets', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<BudgetModel>, Error>> getActive() async {
    try {
      final allResult = await getAll();
      if (allResult.isFailure) {
        return Failure(allResult.error!);
      }

      final now = DateTime.now();
      final active = allResult.data!
          .where((b) =>
              b.isActive &&
              b.startDate.isBefore(now) &&
              b.endDate.isAfter(now))
          .toList();

      return Success(active);
    } catch (e, st) {
      _logger.error('Failed to get active budgets', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<BudgetModel>, Error>> getByPeriod(BudgetPeriod period) async {
    try {
      final allResult = await getAll();
      if (allResult.isFailure) {
        return Failure(allResult.error!);
      }

      final filtered = allResult.data!.where((b) => b.period == period).toList();
      return Success(filtered);
    } catch (e, st) {
      _logger.error('Failed to get budgets by period', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, Error>> update(BudgetModel budget) async {
    try {
      final updated = budget.copyWith(updatedAt: DateTime.now());
      await _storage.upsertRecord(
        table: _tableName,
        id: updated.id,
        record: updated.toJson(),
        userId: updated.userId,
      );
      _logger.info('Budget updated: ${budget.id}');
      return const Success(null);
    } catch (e, st) {
      _logger.error('Failed to update budget', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, Error>> delete(String id) async {
    try {
      await _storage.deleteRecord(table: _tableName, id: id);
      _logger.info('Budget deleted: $id');
      return const Success(null);
    } catch (e, st) {
      _logger.error('Failed to delete budget', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }
}
