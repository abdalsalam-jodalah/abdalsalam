import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/infrastructure/storage_gateway.dart';
import '../../../data/models/financial/account_model.dart';
import '../../../data/repositories/financial/account_repository.dart';
import '../../../data/repositories/record_parser.dart';
import '../../../data/repositories/repository_operation_guard.dart';

class AccountRepositoryImpl implements AccountRepository {
  final StorageGateway _storage;
  final LoggerService _logger;
  static const String _tableName = 'accounts';

  AccountRepositoryImpl(this._storage, this._logger);

  RepositoryOperationGuard get _guard => RepositoryOperationGuard(table: _tableName, logger: _logger);

  RecordParser<AccountModel> get _parser => RecordParser<AccountModel>(
        table: _tableName,
        fromJson: AccountModel.fromJson,
        integrityReporter: _storage.integrityReporter,
      );

  @override
  Future<Result<AccountModel, AppError>> create(AccountModel account) {
    return _guard.run('create', () async {
      await _storage.upsertRecord(
        table: _tableName,
        id: account.id,
        record: account.toJson(),
        userId: account.userId,
      );
      _logger.info('Account created: ${account.id}');
      return account;
    });
  }

  @override
  Future<Result<AccountModel?, AppError>> getById(String id) {
    return _guard.run('getById', () async {
      final record = await _storage.getRecord(table: _tableName, id: id);
      if (record == null) {
        return null;
      }
      return _parser.parseOne(record);
    });
  }

  @override
  Future<Result<List<AccountModel>, AppError>> getAll() {
    return _guard.run('getAll', _readAll);
  }

  @override
  Future<Result<List<AccountModel>, AppError>> getActive() {
    return _guard.run('getActive', () async {
      final accounts = await _readAll();
      return accounts.where((a) => a.isActive).toList();
    });
  }

  @override
  Future<Result<void, AppError>> update(AccountModel account) {
    return _guard.run('update', () async {
      final updated = account.copyWith(updatedAt: DateTime.now());
      await _storage.upsertRecord(
        table: _tableName,
        id: updated.id,
        record: updated.toJson(),
        userId: updated.userId,
      );
      _logger.info('Account updated: ${account.id}');
    });
  }

  @override
  Future<Result<void, AppError>> delete(String id) {
    return _guard.run('delete', () async {
      await _storage.deleteRecord(table: _tableName, id: id);
      _logger.info('Account deleted: $id');
    });
  }

  Future<List<AccountModel>> _readAll() async {
    final records = await _storage.getAllRecords(table: _tableName);
    return _parser.parseAll(records).where((a) => a.deletedAt == null).toList();
  }
}
