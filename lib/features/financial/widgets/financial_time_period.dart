import '../providers/financial_providers.dart';

enum FinancialTimePeriod { day, week, month, year }

DateRange resolveFinancialDateRange(FinancialTimePeriod period, [DateTime? referenceDate]) {
  final now = referenceDate ?? DateTime.now();
  switch (period) {
    case FinancialTimePeriod.day:
      return DateRange(
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    case FinancialTimePeriod.week:
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      return DateRange(
        DateTime(weekStart.year, weekStart.month, weekStart.day),
        DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    case FinancialTimePeriod.month:
      return DateRange(
        DateTime(now.year, now.month, 1),
        DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      );
    case FinancialTimePeriod.year:
      return DateRange(
        DateTime(now.year, 1, 1),
        DateTime(now.year, 12, 31, 23, 59, 59),
      );
  }
}
