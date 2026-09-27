import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/page_header.dart';
import '../providers/financial_providers.dart';
import '../widgets/financial_balance_summary_card.dart';
import '../widgets/financial_budgets_section.dart';
import '../widgets/financial_categories_section.dart';
import '../widgets/financial_income_expense_chart_card.dart';
import '../widgets/financial_net_worth_card.dart';
import '../widgets/financial_recent_transactions_section.dart';
import '../widgets/financial_time_period.dart';
import 'financial_activity_log_screen.dart';

class FinancialDashboardScreen extends ConsumerStatefulWidget {
  static const String _title = 'Financial Dashboard';
  static const String _embeddedTitle = 'Dashboard';
  static const String _activityLogTooltip = 'Activity log';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [FinancialScreen] shell.
  final bool embedded;

  const FinancialDashboardScreen({super.key, this.embedded = false});

  @override
  ConsumerState<FinancialDashboardScreen> createState() => _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends ConsumerState<FinancialDashboardScreen> {
  FinancialTimePeriod _selectedPeriod = FinancialTimePeriod.month;

  @override
  Widget build(BuildContext context) {
    ref.watch(financialStartupTasksProvider);

    if (widget.embedded) {
      return _buildBody(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(FinancialDashboardScreen._title),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: FinancialDashboardScreen._activityLogTooltip,
            onPressed: _openActivityLog,
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: _addTransaction),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final dateRange = resolveFinancialDateRange(_selectedPeriod);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FinancialNetWorthCard(),
        SizedBox(height: tokens.spacing.md),
        FinancialBalanceSummaryCard(dateRange: dateRange),
        SizedBox(height: tokens.spacing.md),
        FinancialIncomeExpenseChartCard(
          selectedPeriod: _selectedPeriod,
          dateRange: dateRange,
          onPeriodChanged: (period) => setState(() => _selectedPeriod = period),
        ),
        SizedBox(height: tokens.spacing.md),
        const FinancialBudgetsSection(),
        SizedBox(height: tokens.spacing.md),
        const FinancialRecentTransactionsSection(),
        SizedBox(height: tokens.spacing.md),
        FinancialCategoriesSection(dateRange: dateRange),
      ],
    );

    if (!widget.embedded) {
      return ListView(padding: EdgeInsets.all(tokens.spacing.lg), children: [content]);
    }

    return ListView(
      children: [
        PageHeader(
          title: FinancialDashboardScreen._embeddedTitle,
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: FinancialDashboardScreen._activityLogTooltip,
              onPressed: _openActivityLog,
            ),
          ],
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: tokens.spacing.lg), child: content),
      ],
    );
  }

  Future<void> _addTransaction() async {
    final result = await Navigator.pushNamed(context, '/financial/transaction-form');

    if (result != null && mounted) {
      ref.invalidate(allTransactionsProvider);
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(financialSummaryProvider);
      ref.invalidate(categoryTotalsProvider);
    }
  }

  Future<void> _openActivityLog() async {
    await Navigator.pushNamed(context, FinancialActivityLogScreen.routeName);
  }
}
