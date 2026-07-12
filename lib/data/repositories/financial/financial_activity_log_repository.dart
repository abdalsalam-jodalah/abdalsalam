import '../../../core/result/result.dart';
import '../../models/financial/financial_activity_log_model.dart';

abstract class FinancialActivityLogRepository {
  Future<Result<FinancialActivityLogModel, Error>> create(FinancialActivityLogModel entry);
  Future<Result<List<FinancialActivityLogModel>, Error>> getAll();
  Future<Result<List<FinancialActivityLogModel>, Error>> getByEntityType(
    FinancialEntityType entityType,
  );
  Future<Result<List<FinancialActivityLogModel>, Error>> getRecent(int limit);
}
