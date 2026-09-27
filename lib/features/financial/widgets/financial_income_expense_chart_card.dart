import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/financial/transaction_model.dart';
import '../../../shared/widgets/charts/app_line_chart.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/async_section.dart';
import '../../../shared/widgets/ui/filter_bar.dart';
import '../../../shared/widgets/ui/filter_option.dart';
import '../providers/financial_providers.dart';
import 'financial_time_period.dart';
import 'money_text.dart';

class FinancialIncomeExpenseChartCard extends ConsumerWidget {
  static const String _title = 'Income vs Expenses';
  static const String _incomeLegendLabel = 'Income';
  static const String _expenseLegendLabel = 'Expense';

  final FinancialTimePeriod selectedPeriod;
  final DateRange dateRange;
  final ValueChanged<FinancialTimePeriod> onPeriodChanged;

  const FinancialIncomeExpenseChartCard({
    super.key,
    required this.selectedPeriod,
    required this.dateRange,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_title, style: theme.textTheme.titleMedium),
          SizedBox(height: tokens.spacing.sm),
          _PeriodSelector(selected: selectedPeriod, onChanged: onPeriodChanged),
          SizedBox(height: tokens.spacing.md),
          AsyncSection(
            value: ref.watch(allTransactionsProvider),
            onRetry: () => ref.invalidate(allTransactionsProvider),
            builder: (transactions) => _ChartContent(dateRange: dateRange, transactions: transactions),
          ),
          SizedBox(height: tokens.spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: tokens.colors.income, label: _incomeLegendLabel),
              SizedBox(width: tokens.spacing.lg),
              _LegendItem(color: tokens.colors.expense, label: _expenseLegendLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  static const List<FilterOption<FinancialTimePeriod>> _options = [
    FilterOption(FinancialTimePeriod.day, 'Day'),
    FilterOption(FinancialTimePeriod.week, 'Week'),
    FilterOption(FinancialTimePeriod.month, 'Month'),
    FilterOption(FinancialTimePeriod.year, 'Year'),
  ];

  final FinancialTimePeriod selected;
  final ValueChanged<FinancialTimePeriod> onChanged;

  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return FilterBar<FinancialTimePeriod>(options: _options, selected: selected, onSelected: onChanged);
  }
}

class _ChartContent extends StatelessWidget {
  final DateRange dateRange;
  final List<TransactionModel> transactions;

  const _ChartContent({required this.dateRange, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final filtered = transactions
        .where((transaction) =>
            transaction.date.isAfter(dateRange.start.subtract(const Duration(seconds: 1))) &&
            transaction.date.isBefore(dateRange.end.add(const Duration(seconds: 1))))
        .toList();

    final totalDays = dateRange.end.difference(dateRange.start).inDays;
    final incomeByDay = List<double>.filled(totalDays + 1, 0);
    final expenseByDay = List<double>.filled(totalDays + 1, 0);

    for (final transaction in filtered) {
      final dayIndex = transaction.date.difference(dateRange.start).inDays.clamp(0, totalDays);
      if (transaction.type == TransactionType.income) {
        incomeByDay[dayIndex] += transaction.amount;
      } else {
        expenseByDay[dayIndex] += transaction.amount;
      }
    }

    final labels = [
      for (var day = 0; day <= totalDays; day++) AppDateFormatter.shortDate(dateRange.start.add(Duration(days: day))),
    ];

    return AppLineChart(
      points: incomeByDay,
      color: tokens.colors.income,
      extraSeries: [AppChartSeries(points: expenseByDay, color: tokens.colors.expense)],
      axisLabels: labels,
      yAxisLabelBuilder: (value) => '${MoneyFormatter.defaultSymbol}${(value / 1000).toStringAsFixed(1)}k',
      formatValue: (value) => MoneyFormatter.format(value),
    );
  }
}

class _LegendItem extends StatelessWidget {
  static const double _dotSize = 10;

  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: _dotSize, height: _dotSize, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: tokens.spacing.sm),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
