import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/financial_providers.dart';
import 'accounts_page.dart';
import 'budgets_page.dart';
import 'categories_page.dart';
import 'financial_dashboard_screen.dart';
import 'transaction_form_screen.dart';
import 'transactions_page.dart';

/// Tabbed hub for the financial module: Dashboard / Transactions / Budgets /
/// Categories / Accounts, with a persistent add-transaction FAB reachable
/// from every tab.
class FinancialScreen extends ConsumerStatefulWidget {
  static const routeName = '/financial';

  const FinancialScreen({super.key});

  @override
  ConsumerState<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends ConsumerState<FinancialScreen> {
  int _selectedIndex = 0;

  static const _tabs = [
    FinancialDashboardScreen(embedded: true),
    TransactionsPage(embedded: true),
    BudgetsPage(embedded: true),
    CategoriesPage(embedded: true),
    AccountsPage(embedded: true),
  ];

  @override
  Widget build(BuildContext context) {
    ref.watch(financialStartupTasksProvider);

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _tabs,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: 'Budgets',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Accounts',
          ),
        ],
      ),
    );
  }

  Future<void> _addTransaction() async {
    final result = await Navigator.pushNamed(context, TransactionFormScreen.routeName);
    if (result != null && mounted) {
      ref.invalidate(allTransactionsProvider);
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(financialSummaryProvider);
      ref.invalidate(categoryTotalsProvider);
      ref.invalidate(allAccountsProvider);
      ref.invalidate(activeAccountsProvider);
    }
  }
}
