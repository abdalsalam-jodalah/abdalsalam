import 'package:uuid/uuid.dart';

import '../../../core/result/result.dart';
import '../../../core/errors/financial_errors.dart';
import '../../../data/models/financial/recurrence_pattern.dart';
import '../../../data/models/financial/transaction_model.dart';
import '../../../data/repositories/financial/transaction_repository.dart';
import 'financial_activity_logger.dart';

/// Materializes due occurrences of recurring transactions as real
/// [TransactionModel] rows. Kept intentionally simple: fixed interval
/// advancement per [RecurrencePattern], no RRULE-style exceptions.
class RecurringTransactionGenerator {
  final TransactionRepository _transactionRepo;
  final FinancialActivityLogger _activityLogger;
  static const _uuid = Uuid();

  /// Safety cap on how many missed occurrences a single series will
  /// catch up in one run (e.g. app not opened for a long time).
  static const int maxCatchUpPerSeries = 24;

  RecurringTransactionGenerator(this._transactionRepo, this._activityLogger);

  static DateTime nextDueDate(DateTime from, RecurrencePattern pattern) {
    switch (pattern) {
      case RecurrencePattern.daily:
        return from.add(const Duration(days: 1));
      case RecurrencePattern.weekly:
        return from.add(const Duration(days: 7));
      case RecurrencePattern.monthly:
        final nextMonth = DateTime(from.year, from.month + 1, 1);
        final lastDayOfNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
        return DateTime(
          nextMonth.year,
          nextMonth.month,
          from.day > lastDayOfNextMonth ? lastDayOfNextMonth : from.day,
          from.hour,
          from.minute,
        );
      case RecurrencePattern.yearly:
        return DateTime(from.year + 1, from.month, from.day, from.hour, from.minute);
    }
  }

  Future<Result<int, Error>> catchUpDueRecurrences({DateTime? now}) async {
    final effectiveNow = now ?? DateTime.now();
    try {
      final allResult = await _transactionRepo.getAll();
      if (allResult.isFailure) {
        return Failure(allResult.error!);
      }

      final dueSeries = allResult.data!.where((t) =>
          t.isRecurring &&
          t.recurrence != null &&
          t.recurrenceNextDueDate != null &&
          !t.recurrenceNextDueDate!.isAfter(effectiveNow));

      var generatedCount = 0;
      for (final original in dueSeries) {
        generatedCount += await _catchUpSeries(original, effectiveNow);
      }

      return Success(generatedCount);
    } catch (e) {
      return Failure(FinancialError(e.toString()));
    }
  }

  Future<int> _catchUpSeries(TransactionModel original, DateTime now) async {
    var dueDate = original.recurrenceNextDueDate!;
    var generated = 0;

    while (!dueDate.isAfter(now) && generated < maxCatchUpPerSeries) {
      final alreadyExists = await _occurrenceAlreadyExists(original, dueDate);
      if (!alreadyExists) {
        final occurrence = original.copyWith(
          id: _uuid.v4(),
          date: dueDate,
          isRecurring: false,
          recurringPattern: null,
          recurrenceNextDueDate: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _transactionRepo.create(occurrence);
        await _activityLogger.logTransactionRecurringGenerated(occurrence);
        generated++;
      }

      dueDate = nextDueDate(dueDate, original.recurrence!);
      await _transactionRepo.update(original.copyWith(recurrenceNextDueDate: dueDate));
    }

    return generated;
  }

  Future<bool> _occurrenceAlreadyExists(TransactionModel original, DateTime dueDate) async {
    final startOfDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final endOfDay = DateTime(dueDate.year, dueDate.month, dueDate.day, 23, 59, 59);
    final existingResult = await _transactionRepo.getByCategoryAndDateRange(
      original.categoryId,
      startOfDay,
      endOfDay,
    );
    if (existingResult.isFailure) {
      return false;
    }
    return existingResult.data!.any((t) =>
        t.id != original.id &&
        t.description == original.description &&
        t.accountId == original.accountId);
  }
}
