import 'package:flutter/material.dart';

import '../widgets/financial_widgets.dart';
import 'budget_management_screen.dart';
import 'financial_reports_screen.dart';
import 'transaction_form_screen.dart';
import 'transaction_list_screen.dart';

class FinancialHomeScreen extends StatelessWidget {
  static const routeName = '/financial/home';

  const FinancialHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Home'),
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
          const BalanceCard(balance: 730),
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
                avatar: const Icon(Icons.savings_outlined),
                label: const Text('Budgets'),
                onPressed: () => Navigator.of(context).pushNamed(BudgetManagementScreen.routeName),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Spending Snapshot', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const CategoryPieChart(
            values: {'Food': 180, 'Transport': 95, 'Bills': 145},
          ),
          const SizedBox(height: 12),
          const MonthlySpendingChart(monthlyValues: [320, 410, 380, 420]),
          const SizedBox(height: 16),
          Text('Budget Health', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Food Budget'),
                  SizedBox(height: 8),
                  BudgetProgressBar(progress: 0.76),
                  SizedBox(height: 12),
                  Text('Transport Budget'),
                  SizedBox(height: 8),
                  BudgetProgressBar(progress: 0.63),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Recent Activity', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Card(
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  leading: Icon(Icons.arrow_upward, color: Colors.redAccent),
                  title: Text('Groceries'),
                  trailing: Text('-\$42.50'),
                ),
                Divider(height: 1),
                ListTile(
                  dense: true,
                  leading: Icon(Icons.arrow_downward, color: Colors.green),
                  title: Text('Salary'),
                  trailing: Text('+\$1,150.00'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
