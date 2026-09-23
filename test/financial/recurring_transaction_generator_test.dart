import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/data/models/financial/financial_activity_log_model.dart';
import 'package:abdalsalam/data/models/financial/recurrence_pattern.dart';
import 'package:abdalsalam/data/models/financial/transaction_model.dart';
import 'package:abdalsalam/features/financial/services/financial_activity_logger.dart';
import 'package:abdalsalam/features/financial/services/recurring_transaction_generator.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

TransactionModel _recurringTemplate({
  required DateTime nextDueDate,
  RecurrencePattern pattern = RecurrencePattern.monthly,
}) {
  final now = DateTime(2026, 1, 1);
  return TransactionModel(
    id: 'template-1',
    userId: 'u1',
    type: TransactionType.expense,
    amount: 50,
    currency: 'ILS',
    categoryId: 'cat-1',
    date: now,
    description: 'Netflix subscription',
    isRecurring: true,
    recurringPattern: pattern.name,
    recurrenceNextDueDate: nextDueDate,
    createdAt: now,
    updatedAt: now,
  );
}

final _logger = LoggerService.forModule('RecurringTransactionGeneratorTest');

void main() {
  group('RecurringTransactionGenerator.nextDueDate', () {
    test('advances daily by one day', () {
      final next = RecurringTransactionGenerator.nextDueDate(
        DateTime(2026, 3, 10),
        RecurrencePattern.daily,
      );
      expect(next, DateTime(2026, 3, 11));
    });

    test('advances weekly by seven days', () {
      final next = RecurringTransactionGenerator.nextDueDate(
        DateTime(2026, 3, 10),
        RecurrencePattern.weekly,
      );
      expect(next, DateTime(2026, 3, 17));
    });

    test('advances monthly and clamps to the shorter month length', () {
      final next = RecurringTransactionGenerator.nextDueDate(
        DateTime(2026, 1, 31),
        RecurrencePattern.monthly,
      );
      expect(next, DateTime(2026, 2, 28));
    });

    test('advances yearly by one year', () {
      final next = RecurringTransactionGenerator.nextDueDate(
        DateTime(2026, 3, 10),
        RecurrencePattern.yearly,
      );
      expect(next, DateTime(2027, 3, 10));
    });
  });

  group('RecurringTransactionGenerator.catchUpDueRecurrences', () {
    test('generates one occurrence and advances the next due date', () async {
      final transactionRepo = FakeTransactionRepository([
        _recurringTemplate(nextDueDate: DateTime(2026, 1, 1)),
      ]);
      final generator = RecurringTransactionGenerator(
        transactionRepo,
        FinancialActivityLogger(FakeFinancialActivityLogRepository(), _logger),
        _logger,
      );

      final result = await generator.catchUpDueRecurrences(now: DateTime(2026, 1, 15));

      expect(result.isSuccess, isTrue);
      expect(result.data, 1);
      // Original template + one generated occurrence.
      expect(transactionRepo.transactions.length, 2);

      final template = transactionRepo.transactions.firstWhere((t) => t.id == 'template-1');
      expect(template.recurrenceNextDueDate, DateTime(2026, 2, 1));
    });

    test('catches up multiple missed occurrences in one run', () async {
      final transactionRepo = FakeTransactionRepository([
        _recurringTemplate(
          nextDueDate: DateTime(2026, 1, 1),
          pattern: RecurrencePattern.monthly,
        ),
      ]);
      final generator = RecurringTransactionGenerator(
        transactionRepo,
        FinancialActivityLogger(FakeFinancialActivityLogRepository(), _logger),
        _logger,
      );

      // Three monthly due dates (Jan 1, Feb 1, Mar 1) have passed by Mar 15.
      final result = await generator.catchUpDueRecurrences(now: DateTime(2026, 3, 15));

      expect(result.data, 3);
      expect(transactionRepo.transactions.length, 4); // template + 3 occurrences
    });

    test('does not regenerate on a second run with the same "now"', () async {
      final transactionRepo = FakeTransactionRepository([
        _recurringTemplate(nextDueDate: DateTime(2026, 1, 1)),
      ]);
      final generator = RecurringTransactionGenerator(
        transactionRepo,
        FinancialActivityLogger(FakeFinancialActivityLogRepository(), _logger),
        _logger,
      );

      final now = DateTime(2026, 1, 15);
      final first = await generator.catchUpDueRecurrences(now: now);
      final second = await generator.catchUpDueRecurrences(now: now);

      expect(first.data, 1);
      expect(second.data, 0);
      expect(transactionRepo.transactions.length, 2);
    });

    test('generated occurrences are logged as recurringGenerated', () async {
      final activityLogRepo = FakeFinancialActivityLogRepository();
      final transactionRepo = FakeTransactionRepository([
        _recurringTemplate(nextDueDate: DateTime(2026, 1, 1)),
      ]);
      final generator = RecurringTransactionGenerator(
        transactionRepo,
        FinancialActivityLogger(activityLogRepo, _logger),
        _logger,
      );

      await generator.catchUpDueRecurrences(now: DateTime(2026, 1, 15));

      expect(activityLogRepo.entries, hasLength(1));
      expect(activityLogRepo.entries.first.action, FinancialActionType.recurringGenerated);
    });
    test('should not advance the due date when creating the occurrence fails', () async {
      final transactionRepo = FailingTransactionRepository(
        [_recurringTemplate(nextDueDate: DateTime(2026, 1, 1))],
        isCreateFailing: true,
      );
      final generator = RecurringTransactionGenerator(
        transactionRepo,
        FinancialActivityLogger(FakeFinancialActivityLogRepository(), _logger),
        _logger,
      );

      final result = await generator.catchUpDueRecurrences(now: DateTime(2026, 1, 15));

      expect(result.isFailure, isTrue);
      expect(transactionRepo.transactions, hasLength(1));
      expect(transactionRepo.transactions.single.recurrenceNextDueDate, DateTime(2026, 1, 1));
    });

    test('should not create an occurrence when the duplicate lookup fails', () async {
      final activityLogRepo = FakeFinancialActivityLogRepository();
      final transactionRepo = FailingTransactionRepository(
        [_recurringTemplate(nextDueDate: DateTime(2026, 1, 1))],
        isCategoryDateLookupFailing: true,
      );
      final generator = RecurringTransactionGenerator(
        transactionRepo,
        FinancialActivityLogger(activityLogRepo, _logger),
        _logger,
      );

      final result = await generator.catchUpDueRecurrences(now: DateTime(2026, 1, 15));

      expect(result.isFailure, isTrue);
      expect(result.error, isA<DatabaseError>());
      expect(transactionRepo.transactions, hasLength(1));
      expect(transactionRepo.transactions.single.recurrenceNextDueDate, DateTime(2026, 1, 1));
      expect(activityLogRepo.entries, isEmpty);
    });

    test('should report failure when advancing the due date fails', () async {
      final transactionRepo = FailingTransactionRepository(
        [_recurringTemplate(nextDueDate: DateTime(2026, 1, 1))],
        isUpdateFailing: true,
      );
      final generator = RecurringTransactionGenerator(
        transactionRepo,
        FinancialActivityLogger(FakeFinancialActivityLogRepository(), _logger),
        _logger,
      );

      final result = await generator.catchUpDueRecurrences(now: DateTime(2026, 3, 15));

      expect(result.isFailure, isTrue);
      expect(transactionRepo.transactions, hasLength(2));
    });

    test('should not duplicate an occurrence on retry after a failed due date advance', () async {
      final transactionRepo = FailingTransactionRepository(
        [_recurringTemplate(nextDueDate: DateTime(2026, 1, 1))],
        isUpdateFailing: true,
      );
      final failingGenerator = RecurringTransactionGenerator(
        transactionRepo,
        FinancialActivityLogger(FakeFinancialActivityLogRepository(), _logger),
        _logger,
      );
      await failingGenerator.catchUpDueRecurrences(now: DateTime(2026, 1, 15));
      final retryRepo = FakeTransactionRepository(transactionRepo.transactions);
      final retryGenerator = RecurringTransactionGenerator(
        retryRepo,
        FinancialActivityLogger(FakeFinancialActivityLogRepository(), _logger),
        _logger,
      );

      final result = await retryGenerator.catchUpDueRecurrences(now: DateTime(2026, 1, 15));

      expect(result.data, 0);
      expect(retryRepo.transactions, hasLength(2));
      expect(
        retryRepo.transactions.firstWhere((t) => t.id == 'template-1').recurrenceNextDueDate,
        DateTime(2026, 2, 1),
      );
    });

    test('should still succeed when the activity log write fails', () async {
      final transactionRepo = FakeTransactionRepository([
        _recurringTemplate(nextDueDate: DateTime(2026, 1, 1)),
      ]);
      final generator = RecurringTransactionGenerator(
        transactionRepo,
        FinancialActivityLogger(FailingFinancialActivityLogRepository(), _logger),
        _logger,
      );

      final result = await generator.catchUpDueRecurrences(now: DateTime(2026, 1, 15));

      expect(result.data, 1);
      expect(transactionRepo.transactions, hasLength(2));
    });
  });
}
