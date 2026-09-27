import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/ui/module_hub_destination.dart';
import '../../../shared/widgets/ui/module_hub_scaffold.dart';
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
class FinancialScreen extends ConsumerWidget {
  static const routeName = '/financial';

  const FinancialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(financialStartupTasksProvider);

    return ModuleHubScaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTransaction(context, ref),
        child: const Icon(Icons.add),
      ),
      destinations: [
        ModuleHubDestination(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          page: const FinancialDashboardScreen(embedded: true),
        ),
        ModuleHubDestination(
          label: 'Transactions',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          page: const TransactionsPage(embedded: true),
        ),
        ModuleHubDestination(
          label: 'Budgets',
          icon: Icons.savings_outlined,
          selectedIcon: Icons.savings,
          page: const BudgetsPage(embedded: true),
        ),
        ModuleHubDestination(
          label: 'Categories',
          icon: Icons.category_outlined,
          selectedIcon: Icons.category,
          page: const CategoriesPage(embedded: true),
        ),
        ModuleHubDestination(
          label: 'Accounts',
          icon: Icons.account_balance_wallet_outlined,
          selectedIcon: Icons.account_balance_wallet,
          page: const AccountsPage(embedded: true),
        ),
      ],
    );
  }

  Future<void> _addTransaction(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.pushNamed(context, TransactionFormScreen.routeName);
    if (result != null && context.mounted) {
      ref.invalidate(allTransactionsProvider);
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(financialSummaryProvider);
      ref.invalidate(categoryTotalsProvider);
      ref.invalidate(allAccountsProvider);
      ref.invalidate(activeAccountsProvider);
    }
  }
}
