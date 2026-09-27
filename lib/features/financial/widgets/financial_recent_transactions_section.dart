import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/financial/category_model.dart';
import '../../../data/models/financial/transaction_model.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../providers/financial_providers.dart';
import '../screens/transactions_page.dart';
import 'financial_transaction_tile.dart';

class FinancialRecentTransactionsSection extends ConsumerWidget {
  static const String _title = 'Recent Transactions';
  static const String _viewMoreLabel = 'View More';
  static const String _emptyTitle = 'No transactions yet';
  static const String _emptySubtitle = 'Add your first transaction to see it here.';
  static const int _displayLimit = 5;

  const FinancialRecentTransactionsSection({super.key});

  Future<void> _viewMore(BuildContext context, WidgetRef ref) async {
    await Navigator.pushNamed(context, TransactionsPage.routeName);
    if (!context.mounted) return;
    ref.invalidate(allTransactionsProvider);
    ref.invalidate(recentTransactionsProvider);
    ref.invalidate(financialSummaryProvider);
    ref.invalidate(categoryTotalsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppThemeTokens.of(context);
    final transactionsAsync = ref.watch(recentTransactionsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: _title,
          padding: EdgeInsets.zero,
          action: TextButton(onPressed: () => _viewMore(context, ref), child: const Text(_viewMoreLabel)),
        ),
        SizedBox(height: tokens.spacing.sm),
        transactionsAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return const EmptyState(
                title: _emptyTitle,
                subtitle: _emptySubtitle,
                icon: Icons.receipt_long_outlined,
                isCompact: true,
              );
            }
            return categoriesAsync.when(
              data: (categories) => Column(
                children: [
                  for (final transaction in transactions.take(_displayLimit))
                    Padding(
                      padding: EdgeInsets.only(bottom: tokens.spacing.sm),
                      child: _buildTile(transaction, categories),
                    ),
                ],
              ),
              loading: () => const LoadingSkeleton(lines: 3, isScrollable: false),
              error: (error, stack) => AsyncErrorView(
                error: error,
                isCompact: true,
                onRetry: () => ref.invalidate(allCategoriesProvider),
              ),
            );
          },
          loading: () => const LoadingSkeleton(lines: 3, isScrollable: false),
          error: (error, stack) => AsyncErrorView(error: error, onRetry: () => ref.invalidate(recentTransactionsProvider)),
        ),
      ],
    );
  }

  Widget _buildTile(TransactionModel transaction, List<CategoryModel> categories) {
    final category = categories.firstWhere(
      (c) => c.id == transaction.categoryId,
      orElse: CategoryModel.unknown,
    );
    return FinancialTransactionTile(
      title: transaction.description,
      categoryName: category.name,
      signedAmount: transaction.type == TransactionType.income ? transaction.amount : -transaction.amount,
      date: transaction.date,
      icon: category.icon,
      accentColor: category.color,
    );
  }
}
