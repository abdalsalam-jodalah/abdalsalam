import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/financial/financial_activity_log_model.dart';

abstract class FinancialActivityLogRepository {
  Future<Result<FinancialActivityLogModel, AppError>> create(FinancialActivityLogModel entry);
  Future<Result<List<FinancialActivityLogModel>, AppError>> getAll();
  Future<Result<List<FinancialActivityLogModel>, AppError>> getByEntityType(
    FinancialEntityType entityType,
  );
  Future<Result<List<FinancialActivityLogModel>, AppError>> getRecent(int limit);
}
