import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
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
  Future<List<CategoryModel>> seedCategories() async {
    _logger.info('Seeding categories...');
    
    final categories = [
      // Expense categories
      CategoryModel(
        id: const Uuid().v4(),
        userId: 'user1',
        name: 'Food & Dining',
        type: CategoryType.expense,
        icon: Icons.restaurant,
        color: Colors.orange,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CategoryModel(
        id: const Uuid().v4(),
        userId: 'user1',
        name: 'Transport',
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
        name: 'Salary',
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

    for (final category in categories) {
      await _categoryRepo.create(category);
    }

    _logger.info('Seeded ${categories.length} categories');
    return categories;
  }

  /// Seed sample transactions
  Future<void> seedTransactions(List<CategoryModel> categories) async {
    _logger.info('Seeding transactions...');
    
    final now = DateTime.now();
    final foodCategory = categories.firstWhere((c) => c.name == 'Food & Dining');
    final transportCategory = categories.firstWhere((c) => c.name == 'Transport');
    final salaryCategory = categories.firstWhere((c) => c.name == 'Salary');

    final transactions = [
      TransactionModel(
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
      TransactionModel(
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
      TransactionModel(
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
      TransactionModel(
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

    for (final transaction in transactions) {
      await _transactionRepo.create(transaction);
    }

    _logger.info('Seeded ${transactions.length} transactions');
  }

  /// Seed sample budgets
  Future<void> seedBudgets(List<CategoryModel> categories) async {
    _logger.info('Seeding budgets...');
    
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final foodCategory = categories.firstWhere((c) => c.name == 'Food & Dining');
    final transportCategory = categories.firstWhere((c) => c.name == 'Transport');

    final budgets = [
      BudgetModel(
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
      BudgetModel(
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

    for (final budget in budgets) {
      await _budgetRepo.create(budget);
    }

    _logger.info('Seeded ${budgets.length} budgets');
  }

  /// Seed all financial data
  Future<void> seedAll() async {
    try {
      _logger.info('Starting financial data seeding...');
      
      final categories = await seedCategories();
      await seedTransactions(categories);
      await seedBudgets(categories);
      
      _logger.info('Financial data seeding completed successfully!');
    } catch (e, st) {
      _logger.error('Failed to seed financial data', error: e, stackTrace: st);
      rethrow;
    }
  }
}
