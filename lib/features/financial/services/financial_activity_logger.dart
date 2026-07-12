import 'package:uuid/uuid.dart';

import '../../../data/models/financial/account_model.dart';
import '../../../data/models/financial/budget_model.dart';
import '../../../data/models/financial/category_model.dart';
import '../../../data/models/financial/financial_activity_log_model.dart';
import '../../../data/models/financial/transaction_model.dart';
import '../../../data/repositories/financial/financial_activity_log_repository.dart';
import 'currency_conversion_service.dart';

/// Records an append-only audit trail of financial mutations, including the
/// exchange rate (and its date) used whenever a non-base-currency amount is
/// converted for a summary — so historical conversions stay auditable.
class FinancialActivityLogger {
  final FinancialActivityLogRepository _repo;
  static const _uuid = Uuid();

  FinancialActivityLogger(this._repo);

  /// [conversion] is populated by the caller when [transaction].currency
  /// differs from the base currency — it captures the rate actually used to
  /// value this transaction in base currency at write time, so the exchange
  /// rate stays auditable without ever being recomputed/re-logged on later
  /// reads (aggregations reconvert transiently but never write log rows).
  Future<void> logTransactionCreated(
    TransactionModel transaction, {
    ConversionResult? conversion,
  }) {
    return _logTransaction(transaction, FinancialActionType.created, conversion);
  }

  Future<void> logTransactionUpdated(
    TransactionModel updated, {
    ConversionResult? conversion,
  }) {
    return _logTransaction(updated, FinancialActionType.updated, conversion);
  }

  Future<void> logTransactionDeleted(TransactionModel transaction) {
    return _logTransaction(transaction, FinancialActionType.deleted, null);
  }

  Future<void> logTransactionRecurringGenerated(
    TransactionModel generated, {
    ConversionResult? conversion,
  }) {
    return _logTransaction(
      generated,
      FinancialActionType.recurringGenerated,
      conversion,
    );
  }

  Future<void> _logTransaction(
    TransactionModel transaction,
    FinancialActionType action,
    ConversionResult? conversion,
  ) async {
    final now = DateTime.now();
    final conversionSuffix = conversion == null
        ? ''
        : ' (≈${conversion.convertedAmount.toStringAsFixed(2)} '
            '${CurrencyConversionService.baseCurrencyCode} '
            '@ ${conversion.rateUsed.toStringAsFixed(4)} on '
            '${conversion.rateDate.toIso8601String().split('T').first}'
            '${conversion.wasFallback ? ', fallback rate' : ''})';
    await _repo.create(FinancialActivityLogModel(
      id: _uuid.v4(),
      userId: transaction.userId,
      entityType: FinancialEntityType.transaction,
      action: action,
      entityId: transaction.id,
      summary: '${transaction.type.name} ${transaction.amount.toStringAsFixed(2)} '
          '${transaction.currency} – ${transaction.description}$conversionSuffix',
      amount: transaction.amount,
      currency: transaction.currency,
      categoryId: transaction.categoryId,
      accountId: transaction.accountId,
      conversionRateUsed: conversion?.rateUsed,
      conversionRateFromTo: conversion == null
          ? null
          : '${transaction.currency}->${CurrencyConversionService.baseCurrencyCode}',
      conversionRateDate: conversion?.rateDate,
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<void> logBudget(BudgetModel budget, FinancialActionType action) async {
    final now = DateTime.now();
    await _repo.create(FinancialActivityLogModel(
      id: _uuid.v4(),
      userId: budget.userId,
      entityType: FinancialEntityType.budget,
      action: action,
      entityId: budget.id,
      summary: 'Budget ${budget.amount.toStringAsFixed(2)} for category ${budget.categoryId}',
      amount: budget.amount,
      currency: budget.currency,
      categoryId: budget.categoryId,
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<void> logCategory(CategoryModel category, FinancialActionType action) async {
    final now = DateTime.now();
    await _repo.create(FinancialActivityLogModel(
      id: _uuid.v4(),
      userId: category.userId,
      entityType: FinancialEntityType.category,
      action: action,
      entityId: category.id,
      summary: 'Category "${category.name}"',
      categoryId: category.id,
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<void> logAccount(AccountModel account, FinancialActionType action) async {
    final now = DateTime.now();
    await _repo.create(FinancialActivityLogModel(
      id: _uuid.v4(),
      userId: account.userId,
      entityType: FinancialEntityType.account,
      action: action,
      entityId: account.id,
      summary: 'Account "${account.name}"',
      currency: account.currency,
      accountId: account.id,
      createdAt: now,
      updatedAt: now,
    ));
  }
}
