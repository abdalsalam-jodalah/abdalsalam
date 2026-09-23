import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/financial/category_model.dart';
import 'package:abdalsalam/features/financial/services/financial_data_seeder.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

class _FailingCategoryRepository extends FakeCategoryRepository {
  @override
  Future<Result<CategoryModel, AppError>> create(CategoryModel category) async {
    return Failure(DatabaseError('create failed'));
  }
}

void main() {
  final logger = LoggerService.forModule('FinancialDataSeederTest');

  FinancialDataSeeder createSeeder({
    FakeTransactionRepository? transactionRepo,
    FakeCategoryRepository? categoryRepo,
    FakeBudgetRepository? budgetRepo,
  }) {
    return FinancialDataSeeder(
      transactionRepo: transactionRepo ?? FakeTransactionRepository(),
      categoryRepo: categoryRepo ?? FakeCategoryRepository(),
      budgetRepo: budgetRepo ?? FakeBudgetRepository(),
      logger: logger,
    );
  }

  group('FinancialDataSeeder', () {
    test('should seed categories, transactions and budgets', () async {
      final transactionRepo = FakeTransactionRepository();
      final categoryRepo = FakeCategoryRepository();
      final budgetRepo = FakeBudgetRepository();
      final seeder = createSeeder(
        transactionRepo: transactionRepo,
        categoryRepo: categoryRepo,
        budgetRepo: budgetRepo,
      );

      await seeder.seedAll();

      expect(categoryRepo.categories, hasLength(7));
      expect(transactionRepo.transactions, hasLength(4));
      expect(budgetRepo.budgets, hasLength(2));
    });

    test('should skip seed data for missing categories instead of throwing', () async {
      final transactionRepo = FakeTransactionRepository();
      final budgetRepo = FakeBudgetRepository();
      final seeder = createSeeder(transactionRepo: transactionRepo, budgetRepo: budgetRepo);

      final transactionsResult = await seeder.seedTransactions(const []);
      final budgetsResult = await seeder.seedBudgets(const []);

      expect(transactionsResult.isSuccess, isTrue);
      expect(budgetsResult.isSuccess, isTrue);
      expect(transactionRepo.transactions, isEmpty);
      expect(budgetRepo.budgets, isEmpty);
    });

    test('should return failure when a category write fails', () async {
      final seeder = createSeeder(categoryRepo: _FailingCategoryRepository());

      final result = await seeder.seedCategories();

      expect(result.isFailure, isTrue);
      expect(result.error, isA<DatabaseError>());
    });
  });
}
