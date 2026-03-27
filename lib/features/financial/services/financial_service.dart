import 'package:uuid/uuid.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/financial/category.dart';
import '../../../data/models/financial/transaction.dart';
import '../../../data/repositories/financial/financial_category_repository.dart';
import '../../../data/repositories/financial/financial_repository.dart';
import '../../../shared/services/base_service_impl.dart';
import '../../../shared/services/reminder_service.dart';

class FinancialService extends BaseServiceImpl<Transaction> {
  static const _uuid = Uuid();

  final ReminderService reminders;
  final FinancialCategoryRepository categoryRepository;

  FinancialService(
    super.repository,
    super.logger, {
    required this.reminders,
    required this.categoryRepository,
  });

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

  Future<Result<Transaction, AppError>> createTransaction({
    required String userId,
    required double amount,
    required String category,
    required String currency,
    required TransactionType direction,
    required DateTime date,
    required String description,
    required String paymentMethod,
    List<String> tags = const <String>[],
  }) async {
    final now = DateTime.now();
    final transaction = Transaction(
      id: _uuid.v4(),
      createdAt: now,
      updatedAt: now,
      userId: userId,
      type: direction,
      amount: amount,
      currency: currency,
      category: category,
      subcategory: null,
      date: date,
      description: description,
      tags: tags,
      paymentMethod: paymentMethod,
    );

    return create(transaction);
  }

  Future<Result<List<Transaction>, AppError>> getTransactionsForUser(String userId) {
    return _repo.getByUserId(userId);
  }

  Future<Result<List<Transaction>, AppError>> filterTransactions({
    required String userId,
    String? category,
    TransactionType? direction,
    DateTime? start,
    DateTime? end,
    String sortBy = 'date_desc',
  }) async {
    final all = await _repo.getByUserId(userId);
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final filtered = all.data!
        .where((item) {
          final matchesCategory = category == null || category == 'all' || item.category == category;
          final matchesDirection = direction == null || item.type == direction;
          final matchesStart = start == null || !item.date.isBefore(start);
          final matchesEnd = end == null || !item.date.isAfter(end);
          return matchesCategory && matchesDirection && matchesStart && matchesEnd;
        })
        .toList(growable: true);

    if (sortBy == 'amount_desc') {
      filtered.sort((a, b) => b.amount.compareTo(a.amount));
    } else if (sortBy == 'amount_asc') {
      filtered.sort((a, b) => a.amount.compareTo(b.amount));
    } else if (sortBy == 'date_asc') {
      filtered.sort((a, b) => a.date.compareTo(b.date));
    } else {
      filtered.sort((a, b) => b.date.compareTo(a.date));
    }

    return Success(filtered);
  }

  Future<Result<Category, AppError>> addCategory({
    required String userId,
    required String name,
    required CategoryType type,
  }) async {
    final now = DateTime.now();
    final category = Category(
      id: _uuid.v4(),
      createdAt: now,
      updatedAt: now,
      userId: userId,
      name: name,
      type: type,
      icon: 'circle',
      color: type == CategoryType.income ? '#2E7D32' : '#C62828',
      parentCategoryId: null,
    );

    final existing = await getCategories(userId);
    if (existing.isFailure) {
      return Failure(existing.error!);
    }
    final alreadyExists = existing.data!
        .any((row) => row.name.toLowerCase().trim() == name.toLowerCase().trim() && row.type == type);
    if (alreadyExists) {
      return Failure(ValidationError('Category already exists'));
    }

    return categoryRepository.create(category);
  }

  Future<Result<Category, AppError>> createCategory(Category category) {
    return categoryRepository.create(category);
  }

  Future<Result<List<Category>, AppError>> getCategories(String userId) {
    return categoryRepository.getByUserId(userId);
  }

  Future<Result<FinancialDashboardSummary, AppError>> getDashboardSummary({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    final transactions = await filterTransactions(
      userId: userId,
      start: start,
      end: end,
      sortBy: 'date_desc',
    );
    if (transactions.isFailure) {
      return Failure(transactions.error!);
    }

    final rows = transactions.data!;
    final income = rows
        .where((item) => item.type == TransactionType.income)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expense = rows
        .where((item) => item.type == TransactionType.expense)
        .fold<double>(0, (sum, item) => sum + item.amount);

    final byCategory = <String, double>{};
    for (final row in rows.where((item) => item.type == TransactionType.expense)) {
      byCategory[row.category] = (byCategory[row.category] ?? 0) + row.amount;
    }

    return Success(
      FinancialDashboardSummary(
        income: income,
        expense: expense,
        balance: income - expense,
        categoryExpenses: byCategory,
      ),
    );
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

class FinancialDashboardSummary {
  final double income;
  final double expense;
  final double balance;
  final Map<String, double> categoryExpenses;

  const FinancialDashboardSummary({
    required this.income,
    required this.expense,
    required this.balance,
    required this.categoryExpenses,
  });
}
