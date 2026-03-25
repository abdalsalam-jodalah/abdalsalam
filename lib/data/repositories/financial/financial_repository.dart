import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/financial/transaction.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class FinancialRepository extends BaseRepository<Transaction> {
  Future<Result<double, AppError>> getRunningBalance();
}

class FinancialRepositoryImpl extends BaseRepositoryImpl<Transaction>
    implements FinancialRepository {
  FinancialRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'transactions';

  @override
  Transaction fromJson(Map<String, dynamic> json) => Transaction.fromJson(json);

  @override
  Future<Result<double, AppError>> getRunningBalance() async {
    final all = await getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final balance = all.data!.fold<double>(0, (sum, item) {
      return item.type == TransactionType.income
          ? sum + item.amount
          : sum - item.amount;
    });

    return Success(balance);
  }
}
