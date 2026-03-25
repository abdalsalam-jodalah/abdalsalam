import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/financial/category.dart';
import '../../../data/models/financial/transaction.dart';
import '../../../data/repositories/financial/financial_repository.dart';
import '../../../shared/services/base_service_impl.dart';
import '../../../shared/services/reminder_service.dart';

class FinancialService extends BaseServiceImpl<Transaction> {
  final ReminderService reminders;

  FinancialService(super.repository, super.logger, {required this.reminders});

  FinancialRepository get _repo => repository as FinancialRepository;

  @override
  String get serviceName => 'FinancialService';

  @override
  String get version => '2.0.0';

  @override
  Transaction fromJson(Map<String, dynamic> json) => Transaction.fromJson(json);

  @override
  Result<void, AppError> validate(Transaction entity) {
    if (entity.userId.trim().isEmpty) {
      return Failure(ValidationError('userId is required'));
    }
    if (entity.amount <= 0) {
      return Failure(ValidationError('amount must be greater than zero'));
    }
    if (entity.category.trim().isEmpty) {
      return Failure(ValidationError('category is required'));
    }
    return const Success(null);
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final all = await _repo.getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final transactions = all.data!;
    final income = transactions
        .where((item) => item.type == TransactionType.income)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expenses = transactions
        .where((item) => item.type == TransactionType.expense)
        .fold<double>(0, (sum, item) => sum + item.amount);

    return Success(<String, dynamic>{
      'income': income,
      'expenses': expenses,
      'balance': income - expenses,
      'categoryBreakdown': categoryBreakdown(transactions),
    });
  }

  Map<String, double> categoryBreakdown(List<Transaction> transactions) {
    final out = <String, double>{};
    for (final item in transactions.where((it) => it.type == TransactionType.expense)) {
      out[item.category] = (out[item.category] ?? 0) + item.amount;
    }
    return out;
  }

  Future<Result<void, AppError>> checkBudgetAlert({
    required String budgetId,
    required double spent,
    required double limit,
  }) async {
    final ratio = limit <= 0 ? 0 : (spent / limit);
    if (ratio >= 1) {
      await reminders.schedule(
        ReminderPayload(
          module: ReminderModule.financial,
          targetId: budgetId,
          title: 'Budget exceeded',
          body: 'Your spending exceeded the budget limit.',
          scheduledAt: DateTime.now(),
        ),
      );
    }
    return const Success(null);
  }

  List<Category> defaultCategories({required String userId, required DateTime now}) {
    const names = <String>['Food', 'Transport', 'Health', 'Entertainment', 'Bills', 'Salary', 'Investment'];
    return names
        .map(
          (name) => Category(
            id: '$userId-$name',
            createdAt: now,
            updatedAt: now,
            userId: userId,
            name: name,
            type: name == 'Salary' || name == 'Investment' ? CategoryType.income : CategoryType.expense,
            icon: 'circle',
            color: '#448AFF',
            parentCategoryId: null,
          ),
        )
        .toList(growable: false);
  }
}
