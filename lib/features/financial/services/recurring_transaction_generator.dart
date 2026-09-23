import 'package:uuid/uuid.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/financial/recurrence_pattern.dart';
import '../../../data/models/financial/transaction_model.dart';
import '../../../data/repositories/financial/transaction_repository.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/services/error_handler.dart';
import 'financial_activity_logger.dart';

/// Materializes due occurrences of recurring transactions as real
/// [TransactionModel] rows. Kept intentionally simple: fixed interval
/// advancement per [RecurrencePattern], no RRULE-style exceptions.
class RecurringTransactionGenerator {
  final TransactionRepository _transactionRepo;
  final FinancialActivityLogger _activityLogger;
  final LoggerService _logger;
  final ErrorHandler _errorHandler;
  static const _uuid = Uuid();

  /// Safety cap on how many missed occurrences a single series will
  /// catch up in one run (e.g. app not opened for a long time).
  static const int maxCatchUpPerSeries = 24;

  RecurringTransactionGenerator(this._transactionRepo, this._activityLogger, this._logger)
      : _errorHandler = ErrorHandler(_logger);

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

  Future<Result<int, AppError>> catchUpDueRecurrences({DateTime? now}) async {
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
      AppError? firstFailure;
      for (final original in dueSeries) {
        final seriesResult = await _catchUpSeries(original, effectiveNow);
        if (seriesResult.isFailure) {
          firstFailure ??= seriesResult.error;
          continue;
        }
        generatedCount += seriesResult.data!;
      }

      if (firstFailure != null) {
        return Failure(firstFailure);
      }
      return Success(generatedCount);
    } catch (error, stackTrace) {
      return Failure(_errorHandler.mapException(
        error,
        context: 'RecurringTransactionGenerator.catchUpDueRecurrences',
        stackTrace: stackTrace,
      ));
    }
  }

  Future<Result<int, AppError>> _catchUpSeries(TransactionModel original, DateTime now) async {
    var dueDate = original.recurrenceNextDueDate!;
    var generated = 0;

    while (!dueDate.isAfter(now) && generated < maxCatchUpPerSeries) {
      final existsResult = await _occurrenceAlreadyExists(original, dueDate);
      if (existsResult.isFailure) {
        _logger.warning(
          'Stopping catch-up for series ${original.id}: duplicate check for $dueDate failed: ${existsResult.error}',
        );
        return Failure(existsResult.error!);
      }

      if (!existsResult.data!) {
        final occurrence = original.copyWith(
          id: _uuid.v4(),
          date: dueDate,
          isRecurring: false,
          recurringPattern: null,
          recurrenceNextDueDate: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final createResult = await _transactionRepo.create(occurrence);
        if (createResult.isFailure) {
          _logger.warning(
            'Stopping catch-up for series ${original.id}: creating occurrence for $dueDate failed: ${createResult.error}',
          );
          return Failure(createResult.error!);
        }
        await _activityLogger.logTransactionRecurringGenerated(occurrence);
        generated++;
      }

      final followingDueDate = nextDueDate(dueDate, original.recurrence!);
      final advanceResult = await _transactionRepo.update(
        original.copyWith(recurrenceNextDueDate: followingDueDate),
      );
      if (advanceResult.isFailure) {
        _logger.warning(
          'Stopping catch-up for series ${original.id}: advancing due date to $followingDueDate failed: ${advanceResult.error}',
        );
        return Failure(advanceResult.error!);
      }
      dueDate = followingDueDate;
    }

    return Success(generated);
  }

  Future<Result<bool, AppError>> _occurrenceAlreadyExists(TransactionModel original, DateTime dueDate) async {
    final startOfDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final endOfDay = DateTime(dueDate.year, dueDate.month, dueDate.day, 23, 59, 59);
    final existingResult = await _transactionRepo.getByCategoryAndDateRange(
      original.categoryId,
      startOfDay,
      endOfDay,
    );
    return existingResult.map((existing) => existing.any((t) =>
        t.id != original.id &&
        t.description == original.description &&
        t.accountId == original.accountId));
  }
}
