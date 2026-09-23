import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/data/models/financial/account_model.dart';
import 'package:abdalsalam/data/models/financial/budget_model.dart';
import 'package:abdalsalam/data/models/financial/category_model.dart';
import 'package:abdalsalam/data/models/financial/exchange_rate_model.dart';
import 'package:abdalsalam/data/models/financial/financial_activity_log_model.dart';
import 'package:abdalsalam/data/models/financial/financial_icon_palette.dart';
import 'package:abdalsalam/data/models/financial/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime createdAt = DateTime(2026, 1, 15, 9, 30);
final DateTime updatedAt = DateTime(2026, 1, 16, 10);
const String badDate = 'not-a-date';
const String unknownEnumValue = 'unknownValue';

Map<String, dynamic> withoutKeys(Map<String, dynamic> json, List<String> keys) {
  return Map<String, dynamic>.of(json)..removeWhere((key, value) => keys.contains(key));
}

Matcher corruptField(String field) {
  return isA<CorruptDataError>().having((error) => error.field, 'field', field);
}

void main() {
  group('TransactionModel.fromJson', () {
    final transaction = TransactionModel(
      id: 'tx-1',
      userId: 'user-1',
      type: TransactionType.expense,
      amount: 42.5,
      currency: 'ILS',
      categoryId: 'cat-1',
      accountId: 'acc-1',
      date: DateTime(2026, 1, 14),
      description: 'Groceries',
      tags: const ['food', 'weekly'],
      paymentMethod: 'card',
      isRecurring: true,
      recurringPattern: 'weekly',
      recurrenceNextDueDate: DateTime(2026, 1, 21),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    test('should keep every field when round-tripping valid json', () {
      final json = transaction.toJson();

      final parsed = TransactionModel.fromJson(json);

      expect(parsed.props, transaction.props);
    });

    test('should use defaults when optional fields are missing', () {
      final json = withoutKeys(transaction.toJson(), [
        'userId',
        'accountId',
        'description',
        'tags',
        'paymentMethod',
        'isRecurring',
        'recurringPattern',
        'recurrenceNextDueDate',
        'updatedAt',
        'deletedAt',
      ]);

      final parsed = TransactionModel.fromJson(json);

      expect(parsed.userId, '');
      expect(parsed.accountId, isNull);
      expect(parsed.description, '');
      expect(parsed.tags, isEmpty);
      expect(parsed.isRecurring, isFalse);
      expect(parsed.recurrenceNextDueDate, isNull);
      expect(parsed.updatedAt, createdAt);
    });

    test('should tolerate an int amount, a numeric string amount and mixed tag types', () {
      final intAmountJson = transaction.toJson()..['amount'] = 42;
      final stringAmountJson = transaction.toJson()
        ..['amount'] = '42.5'
        ..['tags'] = ['food', 3, null]
        ..['isRecurring'] = 1;

      final fromInt = TransactionModel.fromJson(intAmountJson);
      final fromString = TransactionModel.fromJson(stringAmountJson);

      expect(fromInt.amount, 42.0);
      expect(fromString.amount, 42.5);
      expect(fromString.tags, ['food']);
      expect(fromString.isRecurring, isTrue);
    });

    test('should return null for a bad optional date and fall back for a bad updatedAt', () {
      final json = transaction.toJson()
        ..['recurrenceNextDueDate'] = badDate
        ..['deletedAt'] = badDate
        ..['updatedAt'] = badDate;

      final parsed = TransactionModel.fromJson(json);

      expect(parsed.recurrenceNextDueDate, isNull);
      expect(parsed.deletedAt, isNull);
      expect(parsed.updatedAt, createdAt);
    });

    test('should throw CorruptDataError when the transaction type is unknown', () {
      final json = transaction.toJson()..['type'] = unknownEnumValue;

      expect(() => TransactionModel.fromJson(json), throwsA(corruptField('type')));
    });

    for (final field in ['id', 'createdAt', 'type', 'amount', 'currency', 'categoryId', 'date']) {
      test('should throw CorruptDataError when $field is missing', () {
        final json = withoutKeys(transaction.toJson(), [field]);

        expect(() => TransactionModel.fromJson(json), throwsA(corruptField(field)));
      });
    }

    test('should throw CorruptDataError when amount is not numeric', () {
      final json = transaction.toJson()..['amount'] = 'forty';

      expect(() => TransactionModel.fromJson(json), throwsA(corruptField('amount')));
    });
  });

  group('BudgetModel.fromJson', () {
    final budget = BudgetModel(
      id: 'budget-1',
      userId: 'user-1',
      categoryId: 'cat-1',
      amount: 1500,
      currency: 'USD',
      period: BudgetPeriod.monthly,
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 31),
      alertThreshold: 70,
      isActive: false,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    test('should keep every field when round-tripping valid json', () {
      final json = budget.toJson();

      final parsed = BudgetModel.fromJson(json);

      expect(parsed.props, budget.props);
    });

    test('should use defaults when optional fields are missing', () {
      final json = withoutKeys(budget.toJson(), [
        'userId',
        'currency',
        'alertThreshold',
        'isActive',
        'updatedAt',
        'deletedAt',
      ]);

      final parsed = BudgetModel.fromJson(json);

      expect(parsed.userId, '');
      expect(parsed.currency, isNull);
      expect(parsed.alertThreshold, BudgetModel.defaultAlertThreshold);
      expect(parsed.isActive, isTrue);
      expect(parsed.updatedAt, createdAt);
    });

    test('should tolerate a numeric string amount and an int threshold', () {
      final json = budget.toJson()
        ..['amount'] = '1500'
        ..['alertThreshold'] = 90
        ..['isActive'] = 'true';

      final parsed = BudgetModel.fromJson(json);

      expect(parsed.amount, 1500.0);
      expect(parsed.alertThreshold, 90.0);
      expect(parsed.isActive, isTrue);
    });

    test('should return null for a bad deletedAt date', () {
      final json = budget.toJson()..['deletedAt'] = badDate;

      final parsed = BudgetModel.fromJson(json);

      expect(parsed.deletedAt, isNull);
    });

    test('should fall back to the custom period when the period is unknown', () {
      final json = budget.toJson()..['period'] = unknownEnumValue;

      final parsed = BudgetModel.fromJson(json);

      expect(parsed.period, BudgetPeriod.custom);
    });

    for (final field in ['id', 'createdAt', 'categoryId', 'amount', 'startDate', 'endDate']) {
      test('should throw CorruptDataError when $field is missing', () {
        final json = withoutKeys(budget.toJson(), [field]);

        expect(() => BudgetModel.fromJson(json), throwsA(corruptField(field)));
      });
    }

    test('should throw CorruptDataError when startDate is not a date', () {
      final json = budget.toJson()..['startDate'] = badDate;

      expect(() => BudgetModel.fromJson(json), throwsA(corruptField('startDate')));
    });
  });

  group('CategoryModel.fromJson', () {
    final category = CategoryModel(
      id: 'cat-1',
      userId: 'user-1',
      name: 'Food',
      type: CategoryType.expense,
      icon: Icons.restaurant,
      color: const Color(0xFF4CAF50),
      parentCategoryId: 'cat-parent',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    test('should keep every field when round-tripping valid json', () {
      final json = category.toJson();

      final parsed = CategoryModel.fromJson(json);

      expect(parsed.props, category.props);
    });

    test('should use defaults when optional fields are missing', () {
      final json = withoutKeys(category.toJson(), [
        'userId',
        'name',
        'iconKey',
        'colorValue',
        'parentCategoryId',
        'updatedAt',
        'deletedAt',
      ]);

      final parsed = CategoryModel.fromJson(json);

      expect(parsed.userId, '');
      expect(parsed.name, '');
      expect(parsed.icon, financialIconForKey(null));
      expect(parsed.color, const Color(financialDefaultColorValue));
      expect(parsed.parentCategoryId, isNull);
      expect(parsed.updatedAt, createdAt);
    });

    test('should resolve a legacy icon code point stored as a double', () {
      final json = withoutKeys(category.toJson(), ['iconKey'])
        ..['iconCodePoint'] = Icons.restaurant.codePoint.toDouble()
        ..['iconFontFamily'] = Icons.restaurant.fontFamily
        ..['colorValue'] = 0xFF4CAF50.toDouble();

      final parsed = CategoryModel.fromJson(json);

      expect(parsed.icon, Icons.restaurant);
      expect(parsed.color, const Color(0xFF4CAF50));
    });

    test('should return null for a bad deletedAt date', () {
      final json = category.toJson()..['deletedAt'] = badDate;

      final parsed = CategoryModel.fromJson(json);

      expect(parsed.deletedAt, isNull);
    });

    test('should throw CorruptDataError when the category type is unknown', () {
      final json = category.toJson()..['type'] = unknownEnumValue;

      expect(() => CategoryModel.fromJson(json), throwsA(corruptField('type')));
    });

    for (final field in ['id', 'createdAt', 'type']) {
      test('should throw CorruptDataError when $field is missing', () {
        final json = withoutKeys(category.toJson(), [field]);

        expect(() => CategoryModel.fromJson(json), throwsA(corruptField(field)));
      });
    }
  });

  group('AccountModel.fromJson', () {
    final account = AccountModel(
      id: 'acc-1',
      userId: 'user-1',
      name: 'Main bank',
      type: AccountType.bank,
      currency: 'JOD',
      initialBalance: 250.75,
      iconKey: 'account_balance',
      colorValue: 0xFF2196F3,
      isActive: false,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    test('should keep every field when round-tripping valid json', () {
      final json = account.toJson();

      final parsed = AccountModel.fromJson(json);

      expect(parsed.props, account.props);
    });

    test('should use defaults when optional fields are missing', () {
      final json = withoutKeys(account.toJson(), [
        'userId',
        'name',
        'iconKey',
        'colorValue',
        'isActive',
        'updatedAt',
        'deletedAt',
      ]);

      final parsed = AccountModel.fromJson(json);

      expect(parsed.userId, '');
      expect(parsed.name, '');
      expect(parsed.iconKey, financialIconKeyFor(financialIconForKey(null)));
      expect(parsed.colorValue, financialDefaultColorValue);
      expect(parsed.isActive, isTrue);
      expect(parsed.updatedAt, createdAt);
    });

    test('should tolerate an int balance, a double color value and a 0/1 flag', () {
      final json = account.toJson()
        ..['initialBalance'] = 250
        ..['colorValue'] = 0xFF2196F3.toDouble()
        ..['isActive'] = 1;

      final parsed = AccountModel.fromJson(json);

      expect(parsed.initialBalance, 250.0);
      expect(parsed.colorValue, 0xFF2196F3);
      expect(parsed.isActive, isTrue);
    });

    test('should fall back to updatedAt from createdAt when updatedAt is a bad date', () {
      final json = account.toJson()..['updatedAt'] = badDate;

      final parsed = AccountModel.fromJson(json);

      expect(parsed.updatedAt, createdAt);
    });

    test('should fall back to cash when the account type is unknown', () {
      final json = account.toJson()..['type'] = unknownEnumValue;

      final parsed = AccountModel.fromJson(json);

      expect(parsed.type, AccountType.cash);
    });

    for (final field in ['id', 'createdAt', 'currency', 'initialBalance']) {
      test('should throw CorruptDataError when $field is missing', () {
        final json = withoutKeys(account.toJson(), [field]);

        expect(() => AccountModel.fromJson(json), throwsA(corruptField(field)));
      });
    }
  });

  group('ExchangeRateModel.fromJson', () {
    final rate = ExchangeRateModel(
      id: 'rate-1',
      fromCurrency: 'ILS',
      toCurrency: 'USD',
      rate: 0.27,
      date: DateTime(2026, 1, 15),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    test('should keep every field when round-tripping valid json', () {
      final json = rate.toJson();

      final parsed = ExchangeRateModel.fromJson(json);

      expect(parsed.props, rate.props);
    });

    test('should use defaults when optional fields are missing', () {
      final json = withoutKeys(rate.toJson(), ['updatedAt', 'deletedAt']);

      final parsed = ExchangeRateModel.fromJson(json);

      expect(parsed.updatedAt, createdAt);
      expect(parsed.deletedAt, isNull);
    });

    test('should tolerate a numeric string rate and an epoch-ms date', () {
      final json = rate.toJson()
        ..['rate'] = '0.27'
        ..['date'] = DateTime(2026, 1, 15).millisecondsSinceEpoch;

      final parsed = ExchangeRateModel.fromJson(json);

      expect(parsed.rate, 0.27);
      expect(parsed.date, DateTime(2026, 1, 15));
    });

    test('should return null for a bad deletedAt date', () {
      final json = rate.toJson()..['deletedAt'] = badDate;

      final parsed = ExchangeRateModel.fromJson(json);

      expect(parsed.deletedAt, isNull);
    });

    for (final field in ['id', 'createdAt', 'fromCurrency', 'toCurrency', 'rate', 'date']) {
      test('should throw CorruptDataError when $field is missing', () {
        final json = withoutKeys(rate.toJson(), [field]);

        expect(() => ExchangeRateModel.fromJson(json), throwsA(corruptField(field)));
      });
    }
  });

  group('FinancialActivityLogModel.fromJson', () {
    final entry = FinancialActivityLogModel(
      id: 'log-1',
      userId: 'user-1',
      entityType: FinancialEntityType.transaction,
      action: FinancialActionType.created,
      entityId: 'tx-1',
      summary: 'Created expense',
      amount: 42.5,
      currency: 'ILS',
      categoryId: 'cat-1',
      accountId: 'acc-1',
      conversionRateUsed: 0.27,
      conversionRateFromTo: 'ILS->USD',
      conversionRateDate: DateTime(2026, 1, 14),
      metadata: const {'source': 'form'},
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    test('should keep every field when round-tripping valid json', () {
      final json = entry.toJson();

      final parsed = FinancialActivityLogModel.fromJson(json);

      expect(parsed.props, entry.props);
    });

    test('should use defaults when optional fields are missing', () {
      final json = withoutKeys(entry.toJson(), [
        'userId',
        'summary',
        'amount',
        'currency',
        'categoryId',
        'accountId',
        'conversionRateUsed',
        'conversionRateFromTo',
        'conversionRateDate',
        'metadata',
        'updatedAt',
        'deletedAt',
      ]);

      final parsed = FinancialActivityLogModel.fromJson(json);

      expect(parsed.userId, '');
      expect(parsed.summary, '');
      expect(parsed.amount, isNull);
      expect(parsed.conversionRateUsed, isNull);
      expect(parsed.conversionRateDate, isNull);
      expect(parsed.metadata, isNull);
      expect(parsed.updatedAt, createdAt);
    });

    test('should tolerate an int amount, a numeric string rate and a non-string-keyed map', () {
      final json = entry.toJson()
        ..['amount'] = 42
        ..['conversionRateUsed'] = '0.27'
        ..['metadata'] = <dynamic, dynamic>{1: 'one'};

      final parsed = FinancialActivityLogModel.fromJson(json);

      expect(parsed.amount, 42.0);
      expect(parsed.conversionRateUsed, 0.27);
      expect(parsed.metadata, {'1': 'one'});
    });

    test('should return null for a bad conversion rate date', () {
      final json = entry.toJson()..['conversionRateDate'] = badDate;

      final parsed = FinancialActivityLogModel.fromJson(json);

      expect(parsed.conversionRateDate, isNull);
    });

    test('should throw CorruptDataError when the action is unknown', () {
      final json = entry.toJson()..['action'] = unknownEnumValue;

      expect(() => FinancialActivityLogModel.fromJson(json), throwsA(corruptField('action')));
    });

    for (final field in ['id', 'createdAt', 'entityType', 'action', 'entityId']) {
      test('should throw CorruptDataError when $field is missing', () {
        final json = withoutKeys(entry.toJson(), [field]);

        expect(() => FinancialActivityLogModel.fromJson(json), throwsA(corruptField(field)));
      });
    }
  });
}
