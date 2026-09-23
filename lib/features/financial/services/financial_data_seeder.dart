import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/financial/transaction_model.dart';
import '../../../data/models/financial/category_model.dart';
import '../../../data/models/financial/budget_model.dart';
import '../../../data/repositories/financial/transaction_repository.dart';
import '../../../data/repositories/financial/category_repository.dart';
import '../../../data/repositories/financial/budget_repository.dart';
import '../../../shared/infrastructure/logger_service.dart';

/// Helper class to seed initial financial data for testing
class FinancialDataSeeder {
  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final BudgetRepository _budgetRepo;
  final LoggerService _logger;

  static const String _foodCategoryName = 'Food & Dining';
  static const String _transportCategoryName = 'Transport';
  static const String _salaryCategoryName = 'Salary';

  const FinancialDataSeeder({
    required TransactionRepository transactionRepo,
    required CategoryRepository categoryRepo,
    required BudgetRepository budgetRepo,
    required LoggerService logger,
  })  : _transactionRepo = transactionRepo,
        _categoryRepo = categoryRepo,
        _budgetRepo = budgetRepo,
        _logger = logger;

  /// Seed sample categories
  Future<Result<List<CategoryModel>, AppError>> seedCategories() async {
    _logger.info('Seeding categories...');
    
    final categories = [
      // Expense categories
      CategoryModel(
        id: const Uuid().v4(),
        userId: 'user1',
        name: _foodCategoryName,
        type: CategoryType.expense,
        icon: Icons.restaurant,
        color: Colors.orange,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CategoryModel(
        id: const Uuid().v4(),
        userId: 'user1',
        name: _transportCategoryName,
        type: CategoryType.expense,
        icon: Icons.directions_car,
        color: Colors.blue,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CategoryModel(
        id: const Uuid().v4(),
        userId: 'user1',
        name: 'Shopping',
        type: CategoryType.expense,
        icon: Icons.shopping_bag,
        color: Colors.purple,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CategoryModel(
        id: const Uuid().v4(),
        userId: 'user1',
        name: 'Bills',
        type: CategoryType.expense,
        icon: Icons.receipt,
        color: Colors.red,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CategoryModel(
        id: const Uuid().v4(),
        userId: 'user1',
        name: 'Entertainment',
        type: CategoryType.expense,
        icon: Icons.movie,
        color: Colors.pink,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      // Income categories
      CategoryModel(
        id: const Uuid().v4(),
        userId: 'user1',
        name: _salaryCategoryName,
        type: CategoryType.income,
        icon: Icons.attach_money,
        color: Colors.green,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CategoryModel(
        id: const Uuid().v4(),
        userId: 'user1',
        name: 'Freelance',
        type: CategoryType.income,
        icon: Icons.work,
        color: Colors.teal,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    AppError? firstFailure;
    for (final category in categories) {
      final result = await _categoryRepo.create(category);
      if (result.isFailure) {
        _logger.warning('Failed to seed category ${category.name}: ${result.error}');
        firstFailure ??= result.error;
      }
    }
    if (firstFailure != null) {
      return Failure(firstFailure);
    }

    _logger.info('Seeded ${categories.length} categories');
    return Success(categories);
  }

  /// Seed sample transactions
  Future<Result<void, AppError>> seedTransactions(List<CategoryModel> categories) async {
    _logger.info('Seeding transactions...');
    
    final now = DateTime.now();
    final foodCategory = _categoryNamed(categories, _foodCategoryName);
    final transportCategory = _categoryNamed(categories, _transportCategoryName);
    final salaryCategory = _categoryNamed(categories, _salaryCategoryName);

    final transactions = [
      if (salaryCategory != null) TransactionModel(
        id: const Uuid().v4(),
        userId: 'user1',
        type: TransactionType.income,
        amount: 15000,
        currency: 'ILS',
        categoryId: salaryCategory.id,
        date: now.subtract(const Duration(days: 5)),
        description: 'Monthly Salary',
        paymentMethod: 'Bank Transfer',
        createdAt: now,
        updatedAt: now,
      ),
      if (foodCategory != null) TransactionModel(
        id: const Uuid().v4(),
        userId: 'user1',
        type: TransactionType.expense,
        amount: 250,
        currency: 'ILS',
        categoryId: foodCategory.id,
        date: now.subtract(const Duration(days: 1)),
        description: 'Grocery Shopping',
        paymentMethod: 'Credit Card',
        createdAt: now,
        updatedAt: now,
      ),
      if (transportCategory != null) TransactionModel(
        id: const Uuid().v4(),
        userId: 'user1',
        type: TransactionType.expense,
        amount: 120,
        currency: 'ILS',
        categoryId: transportCategory.id,
        date: now.subtract(const Duration(days: 2)),
        description: 'Gas Station',
        paymentMethod: 'Cash',
        createdAt: now,
        updatedAt: now,
      ),
      if (foodCategory != null) TransactionModel(
        id: const Uuid().v4(),
        userId: 'user1',
        type: TransactionType.expense,
        amount: 85,
        currency: 'ILS',
        categoryId: foodCategory.id,
        date: now,
        description: 'Restaurant',
        paymentMethod: 'Credit Card',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    AppError? firstFailure;
    for (final transaction in transactions) {
      final result = await _transactionRepo.create(transaction);
      if (result.isFailure) {
        _logger.warning('Failed to seed transaction ${transaction.description}: ${result.error}');
        firstFailure ??= result.error;
      }
    }
    if (firstFailure != null) {
      return Failure(firstFailure);
    }

    _logger.info('Seeded ${transactions.length} transactions');
    return const Success(null);
  }

  /// Seed sample budgets
  Future<Result<void, AppError>> seedBudgets(List<CategoryModel> categories) async {
    _logger.info('Seeding budgets...');
    
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final foodCategory = _categoryNamed(categories, _foodCategoryName);
    final transportCategory = _categoryNamed(categories, _transportCategoryName);

    final budgets = [
      if (foodCategory != null) BudgetModel(
        id: const Uuid().v4(),
        userId: 'user1',
        categoryId: foodCategory.id,
        amount: 2000,
        period: BudgetPeriod.monthly,
        startDate: startOfMonth,
        endDate: endOfMonth,
        alertThreshold: 80,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      if (transportCategory != null) BudgetModel(
        id: const Uuid().v4(),
        userId: 'user1',
        categoryId: transportCategory.id,
        amount: 800,
        period: BudgetPeriod.monthly,
        startDate: startOfMonth,
        endDate: endOfMonth,
        alertThreshold: 80,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    AppError? firstFailure;
    for (final budget in budgets) {
      final result = await _budgetRepo.create(budget);
      if (result.isFailure) {
        _logger.warning('Failed to seed budget for category ${budget.categoryId}: ${result.error}');
        firstFailure ??= result.error;
      }
    }
    if (firstFailure != null) {
      return Failure(firstFailure);
    }

    _logger.info('Seeded ${budgets.length} budgets');
    return const Success(null);
  }

  CategoryModel? _categoryNamed(List<CategoryModel> categories, String name) {
    final category = categories.where((c) => c.name == name).firstOrNull;
    if (category == null) {
      _logger.warning('Seed category "$name" not found; skipping seed data that depends on it');
    }
    return category;
  }

  /// Seed all financial data
  Future<void> seedAll() async {
    try {
      _logger.info('Starting financial data seeding...');
      
      final categories = (await seedCategories()).getOrThrow();
      (await seedTransactions(categories)).getOrThrow();
      (await seedBudgets(categories)).getOrThrow();
      
      _logger.info('Financial data seeding completed successfully!');
    } catch (e, st) {
      _logger.error('Failed to seed financial data', error: e, stackTrace: st);
      rethrow;
    }
  }
}
