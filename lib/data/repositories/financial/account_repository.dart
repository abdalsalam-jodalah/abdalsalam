import '../../../core/result/result.dart';
import '../../models/financial/account_model.dart';

abstract class AccountRepository {
  Future<Result<AccountModel, Error>> create(AccountModel account);
  Future<Result<AccountModel?, Error>> getById(String id);
  Future<Result<List<AccountModel>, Error>> getAll();
  Future<Result<List<AccountModel>, Error>> getActive();
  Future<Result<void, Error>> update(AccountModel account);
  Future<Result<void, Error>> delete(String id);
}
