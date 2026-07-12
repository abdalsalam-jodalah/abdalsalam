import 'package:abdalsalam/data/models/financial/account_model.dart';
import 'package:abdalsalam/data/models/financial/financial_activity_log_model.dart';
import 'package:abdalsalam/data/models/financial/transaction_model.dart';
import 'package:abdalsalam/features/financial/services/currency_conversion_service.dart';
import 'package:abdalsalam/features/financial/services/financial_activity_logger.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

TransactionModel _transaction() {
  final now = DateTime(2026, 1, 1);
  return TransactionModel(
    id: 'tx-1',
    userId: 'u1',
    type: TransactionType.expense,
    amount: 42,
    currency: 'ILS',
    categoryId: 'cat-1',
    date: now,
    description: 'Groceries',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('FinancialActivityLogger', () {
    test('logs exactly one entry on transaction creation', () async {
      final repo = FakeFinancialActivityLogRepository();
      final logger = FinancialActivityLogger(repo);

      await logger.logTransactionCreated(_transaction());

      expect(repo.entries, hasLength(1));
      expect(repo.entries.first.action, FinancialActionType.created);
      expect(repo.entries.first.entityType, FinancialEntityType.transaction);
      expect(repo.entries.first.entityId, 'tx-1');
    });

    test('logs exactly one entry on transaction update', () async {
      final repo = FakeFinancialActivityLogRepository();
      final logger = FinancialActivityLogger(repo);

      await logger.logTransactionUpdated(_transaction());

      expect(repo.entries, hasLength(1));
      expect(repo.entries.first.action, FinancialActionType.updated);
    });

    test('logs exactly one entry on transaction deletion', () async {
      final repo = FakeFinancialActivityLogRepository();
      final logger = FinancialActivityLogger(repo);

      await logger.logTransactionDeleted(_transaction());

      expect(repo.entries, hasLength(1));
      expect(repo.entries.first.action, FinancialActionType.deleted);
    });

    test('records the conversion rate and its date when provided', () async {
      final repo = FakeFinancialActivityLogRepository();
      final logger = FinancialActivityLogger(repo);
      final conversion = ConversionResult(
        convertedAmount: 100,
        rateUsed: 3.7,
        rateDate: DateTime(2026, 5, 1),
        wasFallback: false,
      );

      await logger.logTransactionCreated(_transaction(), conversion: conversion);

      final entry = repo.entries.single;
      expect(entry.conversionRateUsed, 3.7);
      expect(entry.conversionRateDate, DateTime(2026, 5, 1));
      expect(entry.conversionRateFromTo, 'ILS->ILS');
    });

    test('logs account create/update/delete distinctly', () async {
      final repo = FakeFinancialActivityLogRepository();
      final logger = FinancialActivityLogger(repo);
      final now = DateTime(2026, 1, 1);
      final account = AccountModel(
        id: 'acc-1',
        userId: 'u1',
        name: 'Cash Wallet',
        type: AccountType.cash,
        currency: 'ILS',
        initialBalance: 0,
        iconCodePoint: 0xe000,
        colorValue: 0xFF0000FF,
        createdAt: now,
        updatedAt: now,
      );

      await logger.logAccount(account, FinancialActionType.created);
      await logger.logAccount(account, FinancialActionType.deleted);

      expect(repo.entries.map((e) => e.action),
          [FinancialActionType.created, FinancialActionType.deleted]);
      expect(repo.entries.every((e) => e.entityType == FinancialEntityType.account), isTrue);
    });
  });
}
