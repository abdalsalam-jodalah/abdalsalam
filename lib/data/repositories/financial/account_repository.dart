import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/financial/account_model.dart';

abstract class AccountRepository {
  Future<Result<AccountModel, AppError>> create(AccountModel account);
  Future<Result<AccountModel?, AppError>> getById(String id);
  Future<Result<List<AccountModel>, AppError>> getAll();
  Future<Result<List<AccountModel>, AppError>> getActive();
  Future<Result<void, AppError>> update(AccountModel account);
  Future<Result<void, AppError>> delete(String id);
}
