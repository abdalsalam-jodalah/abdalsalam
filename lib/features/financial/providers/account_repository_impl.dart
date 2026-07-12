import '../../../core/result/result.dart';
import '../../../core/errors/financial_errors.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/infrastructure/storage_gateway.dart';
import '../../../data/models/financial/account_model.dart';
import '../../../data/repositories/financial/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  final StorageGateway _storage;
  final LoggerService _logger;
  static const String _tableName = 'accounts';

  AccountRepositoryImpl(this._storage, this._logger);

  @override
  Future<Result<AccountModel, Error>> create(AccountModel account) async {
    try {
      await _storage.upsertRecord(
        table: _tableName,
        id: account.id,
        record: account.toJson(),
        userId: account.userId,
      );
      _logger.info('Account created: ${account.id}');
      return Success(account);
    } catch (e, st) {
      _logger.error('Failed to create account', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<AccountModel?, Error>> getById(String id) async {
    try {
      final record = await _storage.getRecord(table: _tableName, id: id);
      if (record == null) {
        return const Success(null);
      }
      return Success(AccountModel.fromJson(record));
    } catch (e, st) {
      _logger.error('Failed to get account', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<AccountModel>, Error>> getAll() async {
    try {
      final records = await _storage.getAllRecords(table: _tableName);
      final accounts = records
          .map((r) => AccountModel.fromJson(r))
          .where((a) => a.deletedAt == null)
          .toList();
      return Success(accounts);
    } catch (e, st) {
      _logger.error('Failed to get all accounts', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<AccountModel>, Error>> getActive() async {
    try {
      final allResult = await getAll();
      if (allResult.isFailure) {
        return Failure(allResult.error!);
      }
      final active = allResult.data!.where((a) => a.isActive).toList();
      return Success(active);
    } catch (e, st) {
      _logger.error('Failed to get active accounts', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, Error>> update(AccountModel account) async {
    try {
      final updated = account.copyWith(updatedAt: DateTime.now());
      await _storage.upsertRecord(
        table: _tableName,
        id: updated.id,
        record: updated.toJson(),
        userId: updated.userId,
      );
      _logger.info('Account updated: ${account.id}');
      return const Success(null);
    } catch (e, st) {
      _logger.error('Failed to update account', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, Error>> delete(String id) async {
    try {
      await _storage.deleteRecord(table: _tableName, id: id);
      _logger.info('Account deleted: $id');
      return const Success(null);
    } catch (e, st) {
      _logger.error('Failed to delete account', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }
}
