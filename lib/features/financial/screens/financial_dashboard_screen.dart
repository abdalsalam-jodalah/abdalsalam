import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/financial_providers.dart';
import '../../../data/models/financial/transaction_model.dart';
import '../../../data/models/financial/category_model.dart';
import '../../../shared/widgets/async_error_view.dart';
import 'transactions_page.dart';
import 'budgets_page.dart';
import 'categories_page.dart';
import 'financial_activity_log_screen.dart';

enum TimePeriod { day, week, month, year }

class FinancialDashboardScreen extends ConsumerStatefulWidget {
  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [FinancialScreen] shell.
  final bool embedded;

  const FinancialDashboardScreen({super.key, this.embedded = false});

  @override
  ConsumerState<FinancialDashboardScreen> createState() =>
      _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends ConsumerState<FinancialDashboardScreen> {
  TimePeriod _selectedPeriod = TimePeriod.month;

  DateRange _getDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case TimePeriod.day:
        return DateRange(
          DateTime(now.year, now.month, now.day),
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case TimePeriod.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return DateRange(
          DateTime(weekStart.year, weekStart.month, weekStart.day),
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case TimePeriod.month:
        return DateRange(
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case TimePeriod.year:
        return DateRange(
          DateTime(now.year, 1, 1),
          DateTime(now.year, 12, 31, 23, 59, 59),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(financialStartupTasksProvider);

    if (widget.embedded) {
      return _buildBody();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Activity log',
            onPressed: _openActivityLog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addTransaction,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Future<void> _addTransaction() async {
    final result = await Navigator.pushNamed(
      context,
      '/financial/transaction-form',
    );

    if (result != null && mounted) {
      ref.invalidate(allTransactionsProvider);
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(financialSummaryProvider);
      ref.invalidate(categoryTotalsProvider);
    }
  }

  void _openActivityLog() {
    Navigator.pushNamed(context, FinancialActivityLogScreen.routeName);
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.embedded) ...[
            _buildEmbeddedHeader(),
            const SizedBox(height: 16),
          ],

          // Net summary
          _buildNetSummaryCard(),
          const SizedBox(height: 24),

          // 1. Total Money Widget
          _buildTotalMoneyWidget(),
          const SizedBox(height: 24),

          // 2. Chart Section
          _buildChartSection(),
          const SizedBox(height: 24),

          // 3. Budgets Section
          _buildBudgetsSection(),
          const SizedBox(height: 24),

          // 4. Recent Transactions Section
          _buildTransactionsSection(),
          const SizedBox(height: 24),

          // 5. Categories Section
          _buildCategoriesSection(),
        ],
      ),
    );
  }

  Widget _buildEmbeddedHeader() {
    return Row(
      children: [
        Text(
          'Dashboard',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: 'Activity log',
          onPressed: _openActivityLog,
        ),
      ],
    );
  }

  Widget _buildNetSummaryCard() {
    final summaryAsync = ref.watch(netWorthProvider);

    return summaryAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: AsyncErrorView(
            error: error,
            onRetry: () => ref.invalidate(netWorthProvider),
          ),
        ),
      ),
      data: (summary) {
        final netWorth = (summary['netWorth'] as double?) ?? 0;
        final accountCount = (summary['accountCount'] as int?) ?? 0;
        final totalBudgets = (summary['totalBudgets'] as int?) ?? 0;
        final budgetsNearOrOverLimit = (summary['budgetsNearOrOverLimit'] as int?) ?? 0;
        final upcomingRecurring =
            (summary['upcomingRecurring'] as List<TransactionModel>?) ?? [];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.savings, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Net Worth',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '₪${netWorth.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '$accountCount account${accountCount == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(
                      budgetsNearOrOverLimit > 0 ? Icons.warning_amber : Icons.check_circle,
                      size: 18,
                      color: budgetsNearOrOverLimit > 0 ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        totalBudgets == 0
                            ? 'No active budgets'
                            : '$budgetsNearOrOverLimit of $totalBudgets budgets near/over limit',
                      ),
                    ),
                  ],
                ),
                if (upcomingRecurring.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Upcoming recurring',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  ...upcomingRecurring.map((t) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text(t.description)),
                            Text(
                              '${t.amount.toStringAsFixed(2)} ${t.currency} • '
                              '${DateFormat('MMM d').format(t.recurrenceNextDueDate!)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalMoneyWidget() {
    final dateRange = _getDateRange();
    final summaryAsync = ref.watch(financialSummaryProvider(dateRange));

    return summaryAsync.when(
      data: (summary) {
        final balance = summary['balance'] ?? 0;
        final income = summary['income'] ?? 0;
        final expense = summary['expense'] ?? 0;

        return Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Balance',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₪${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Income: ₪${income.toStringAsFixed(0)} • ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Expense: ₪${expense.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: AsyncErrorView(
            error: error,
            onRetry: () => ref.invalidate(financialSummaryProvider(dateRange)),
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Income vs Expenses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: _buildPeriodSelector(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: _buildLineChart(),
            ),
            const SizedBox(height: 16),
            _buildChartLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<TimePeriod>(
        segments: const [
          ButtonSegment(
            value: TimePeriod.day,
            label: Text('Day'),
          ),
          ButtonSegment(
            value: TimePeriod.week,
            label: Text('Week'),
          ),
          ButtonSegment(
            value: TimePeriod.month,
            label: Text('Month'),
          ),
          ButtonSegment(
            value: TimePeriod.year,
            label: Text('Year'),
          ),
        ],
        selected: {_selectedPeriod},
        onSelectionChanged: (Set<TimePeriod> newSelection) {
          setState(() {
            _selectedPeriod = newSelection.first;
          });
        },
      ),
    );
  }

  Widget _buildLineChart() {
    final dateRange = _getDateRange();
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return transactionsAsync.when(
      data: (transactions) {
        // Filter transactions by date range
        final filtered = transactions.where((t) =>
            t.date.isAfter(dateRange.start.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(dateRange.end.add(const Duration(seconds: 1)))).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No data available'));
        }

        // Group by day and calculate totals
        final incomeByDay = <int, double>{};
        final expenseByDay = <int, double>{};

        for (final transaction in filtered) {
          final dayIndex = transaction.date.difference(dateRange.start).inDays;
          if (transaction.type == TransactionType.income) {
            incomeByDay[dayIndex] = (incomeByDay[dayIndex] ?? 0) + transaction.amount;
          } else {
            expenseByDay[dayIndex] = (expenseByDay[dayIndex] ?? 0) + transaction.amount;
          }
        }

        final incomeSpots = incomeByDay.entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList();
        final expenseSpots = expenseByDay.entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList();

        if (incomeSpots.isEmpty && expenseSpots.isEmpty) {
          return const Center(child: Text('No data for selected period'));
        }

        final maxY = [
          ...incomeSpots.map((s) => s.y),
          ...expenseSpots.map((s) => s.y),
        ].reduce((a, b) => a > b ? a : b) * 1.2;

        return LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withValues(alpha: 0.2),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    return Text(
                      '₪${(value / 1000).toStringAsFixed(1)}k',
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            minY: 0,
            maxY: maxY,
            lineBarsData: [
              if (incomeSpots.isNotEmpty)
                LineChartBarData(
                  spots: incomeSpots,
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withValues(alpha: 0.1),
                  ),
                ),
              if (expenseSpots.isNotEmpty)
                LineChartBarData(
                  spots: expenseSpots,
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.red.withValues(alpha: 0.1),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => AsyncErrorView(
        error: error,
        isCompact: true,
        onRetry: () => ref.invalidate(allTransactionsProvider),
      ),
    );
  }

  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Income', Colors.green),
        const SizedBox(width: 24),
        _buildLegendItem('Expenses', Colors.red),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetsSection() {
    final budgetsAsync = ref.watch(activeBudgetsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Budgets',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () async {
                await Navigator.pushNamed(context, BudgetsPage.routeName);

                if (!mounted) return;
                ref.invalidate(activeBudgetsProvider);
              },
              child: const Text('View More'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        budgetsAsync.when(
          data: (budgets) {
            if (budgets.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('No active budgets')),
                ),
              );
            }

            return SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: budgets.length,
                itemBuilder: (context, index) {
                  final budget = budgets[index];
                  return categoriesAsync.when(
                    data: (categories) {
                      final category = categories.firstWhere(
                        (c) => c.id == budget.categoryId,
                        orElse: CategoryModel.unknown,
                      );

                      final progressAsync = ref.watch(budgetProgressProvider(budget));

                      return progressAsync.when(
                        data: (progress) {
                          final spent = (progress['spent'] as double?) ?? 0;
                          return _buildBudgetCard(
                            category.name,
                            budget.amount,
                            spent,
                            category.icon,
                            category.color,
                          );
                        },
                        loading: () => _buildBudgetCard(
                          category.name,
                          budget.amount,
                          0,
                          category.icon,
                          category.color,
                        ),
                        error: (error, stack) => _buildBudgetCardError(
                          category.name,
                          category.icon,
                          category.color,
                          error,
                          () => ref.invalidate(budgetProgressProvider(budget)),
                        ),
                      );
                    },
                    loading: () => const SizedBox(
                      width: 160,
                      child: Card(child: Center(child: CircularProgressIndicator())),
                    ),
                    error: (error, stack) => SizedBox(
                      width: 160,
                      child: Card(
                        child: AsyncErrorView(
                          error: error,
                          isCompact: true,
                          onRetry: () => ref.invalidate(allCategoriesProvider),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => AsyncErrorView(
            error: error,
            onRetry: () => ref.invalidate(activeBudgetsProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCardError(
    String name,
    IconData icon,
    Color color,
    Object error,
    VoidCallback onRetry,
  ) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            AsyncErrorView(error: error, onRetry: onRetry, isCompact: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(
    String name,
    double budget,
    double spent,
    IconData icon,
    Color color,
  ) {
    final percentage = budget > 0 ? (spent / budget) * 100 : 0;

    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const Spacer(),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: percentage > 80 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage > 80 ? Colors.red : color,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '₪${spent.toStringAsFixed(0)}/₪${budget.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsSection() {
    final transactionsAsync = ref.watch(recentTransactionsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () async {
                await Navigator.pushNamed(context, TransactionsPage.routeName);

                if (!mounted) return;
                ref.invalidate(allTransactionsProvider);
                ref.invalidate(recentTransactionsProvider);
                ref.invalidate(financialSummaryProvider);
                ref.invalidate(categoryTotalsProvider);
              },
              child: const Text('View More'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        transactionsAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('No transactions yet')),
                ),
              );
            }

            return categoriesAsync.when(
              data: (categories) {
                return Column(
                  children: transactions.take(5).map((transaction) {
                    final category = categories.firstWhere(
                      (c) => c.id == transaction.categoryId,
                      orElse: CategoryModel.unknown,
                    );

                    return _buildTransactionItem(
                      transaction.description,
                      category.name,
                      transaction.type == TransactionType.income
                          ? transaction.amount
                          : -transaction.amount,
                      transaction.date,
                      category.icon,
                      category.color,
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => AsyncErrorView(
                error: error,
                isCompact: true,
                onRetry: () => ref.invalidate(allCategoriesProvider),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => AsyncErrorView(
            error: error,
            onRetry: () => ref.invalidate(recentTransactionsProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    String title,
    String category,
    double amount,
    DateTime date,
    IconData icon,
    Color color,
  ) {
    final isIncome = amount > 0;
    final formatter = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '$category • ${formatter.format(date)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '${isIncome ? '+' : ''}₪${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final dateRange = _getDateRange();
    final categoryTotalsAsync = ref.watch(categoryTotalsProvider(dateRange));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () async {
                await Navigator.pushNamed(context, CategoriesPage.routeName);

                if (!mounted) return;
                ref.invalidate(allCategoriesProvider);
                ref.invalidate(categoryTotalsProvider);
              },
              child: const Text('View More'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('No categories yet')),
                ),
              );
            }

            return categoryTotalsAsync.when(
              data: (totals) {
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.take(4).length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final amount = totals[category.id] ?? 0;

                    return _buildCategoryCard(
                      category.name,
                      amount,
                      category.icon,
                      category.color,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => AsyncErrorView(
                error: error,
                isCompact: true,
                onRetry: () => ref.invalidate(categoryTotalsProvider(dateRange)),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => AsyncErrorView(
            error: error,
            onRetry: () => ref.invalidate(allCategoriesProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    String name,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '₪${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
