import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/financial/transaction.dart';
import '../providers/financial_providers.dart';
import 'budget_management_screen.dart';
import 'financial_categories_screen.dart';
import 'financial_reports_screen.dart';
import 'transaction_form_screen.dart';
import 'transaction_list_screen.dart';

class FinancialHomeScreen extends ConsumerStatefulWidget {
  static const routeName = '/financial/home';

  const FinancialHomeScreen({super.key});

  @override
  ConsumerState<FinancialHomeScreen> createState() => _FinancialHomeScreenState();
}

class _FinancialHomeScreenState extends ConsumerState<FinancialHomeScreen> {
  int _rangeDays = 30;
  late DateTime _rangeAnchor;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _rangeAnchor = DateTime(now.year, now.month, now.day, 12);
  }

  DateTimeRange get _dateRange {
    return DateTimeRange(
      start: DateTime(
        _rangeAnchor.year,
        _rangeAnchor.month,
        _rangeAnchor.day,
      ).subtract(Duration(days: _rangeDays - 1)),
      end: _rangeAnchor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsState = ref.watch(financialTransactionsControllerProvider);
    final summaryState = ref.watch(financialDashboardSummaryProvider(_dateRange));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Reports',
            onPressed: () => Navigator.of(context).pushNamed(FinancialReportsScreen.routeName),
            icon: const Icon(Icons.pie_chart_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          summaryState.when(
            data: (summary) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Balance', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      summary.balance.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricPill(
                            label: 'In',
                            value: summary.income,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricPill(
                            label: 'Out',
                            value: summary.expense,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, stackTrace) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Could not load summary: $error'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.add),
                label: const Text('Add Transaction'),
                onPressed: () => Navigator.of(context).pushNamed(TransactionFormScreen.routeName),
              ),
              ActionChip(
                avatar: const Icon(Icons.list_alt_outlined),
                label: const Text('Transactions'),
                onPressed: () => Navigator.of(context).pushNamed(TransactionListScreen.routeName),
              ),
              ActionChip(
                avatar: const Icon(Icons.category_outlined),
                label: const Text('Categories'),
                onPressed: () => Navigator.of(context).pushNamed(FinancialCategoriesScreen.routeName),
              ),
              ActionChip(
                avatar: const Icon(Icons.savings_outlined),
                label: const Text('Budgets'),
                onPressed: () => Navigator.of(context).pushNamed(BudgetManagementScreen.routeName),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Date Range', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final days in const [7, 30, 90, 365])
                ChoiceChip(
                  label: Text('$days days'),
                  selected: _rangeDays == days,
                  onSelected: (_) => setState(() {
                    _rangeDays = days;
                    final now = DateTime.now();
                    _rangeAnchor = DateTime(now.year, now.month, now.day, 12);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('In vs Out', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          summaryState.when(
            data: (summary) => _InOutMiniChart(income: summary.income, expense: summary.expense),
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          Text('Category Amounts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          summaryState.when(
            data: (summary) => _CategoryAmountMiniChart(values: summary.categoryExpenses),
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('Latest Records', style: Theme.of(context).textTheme.titleMedium),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed(TransactionListScreen.routeName),
                child: const Text('Show All'),
              ),
            ],
          ),
          transactionsState.when(
            data: (rows) {
              final latest = [...rows]..sort((a, b) => b.date.compareTo(a.date));
              final display = latest.take(5).toList(growable: false);
              if (display.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No records yet. Add your first financial record.'),
                  ),
                );
              }
              return Card(
                child: Column(
                  children: [
                    for (var i = 0; i < display.length; i++) ...[
                      _RecentRecordTile(item: display[i]),
                      if (i < display.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Could not load records: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MetricPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.12), Theme.of(context).colorScheme.surface),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(value.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _InOutMiniChart extends StatelessWidget {
  final double income;
  final double expense;

  const _InOutMiniChart({required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final total = income + expense;
    final inRatio = total <= 0 ? 0.0 : income / total;
    final outRatio = total <= 0 ? 0.0 : expense / total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: inRatio,
              minHeight: 12,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: outRatio,
              minHeight: 12,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('In ${income.toStringAsFixed(2)}'),
                Text('Out ${expense.toStringAsFixed(2)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryAmountMiniChart extends StatelessWidget {
  final Map<String, double> values;

  const _CategoryAmountMiniChart({required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('No category expenses in selected range.'),
        ),
      );
    }

    final sorted = values.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = sorted.first.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (final entry in sorted.take(5)) ...[
              Row(
                children: [
                  SizedBox(width: 90, child: Text(entry.key, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: maxValue <= 0 ? 0 : entry.value / maxValue,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(entry.value.toStringAsFixed(2)),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentRecordTile extends StatelessWidget {
  final Transaction item;

  const _RecentRecordTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isIn = item.type == TransactionType.income;
    return ListTile(
      dense: true,
      leading: Icon(
        isIn ? Icons.arrow_downward : Icons.arrow_upward,
        color: isIn ? Colors.green : Colors.red,
      ),
      title: Text(item.description),
      subtitle: Text('${item.category} • ${DateFormat('yyyy-MM-dd').format(item.date)}'),
      trailing: Text('${isIn ? '+' : '-'}${item.amount.toStringAsFixed(2)} ${item.currency}'),
    );
  }
}
