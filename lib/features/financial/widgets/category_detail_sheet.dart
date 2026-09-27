// lib/features/financial/widgets/category_detail_sheet.dart: bottom sheet showing a category's monthly total and recent transactions.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/financial/category_model.dart';
import '../../../data/models/financial/transaction_model.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../../../shared/widgets/ui/stat_tile.dart';
import '../providers/financial_providers.dart';

class CategoryDetailSheet extends ConsumerWidget {
  static const String currencySymbol = '₪';
  static const double _sheetHeightFraction = 0.7;

  final CategoryModel category;
  final double monthTotal;

  const CategoryDetailSheet({super.key, required this.category, required this.monthTotal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppThemeTokens.of(context);
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final categoryTransactions = transactionsAsync.maybeWhen(
      data: (transactions) => transactions
          .where((transaction) => transaction.categoryId == category.id)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)),
      orElse: () => const <TransactionModel>[],
    );
    final transactionsError = transactionsAsync.hasError ? transactionsAsync.error : null;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * _sheetHeightFraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatTile(
            icon: category.icon,
            accentColor: category.color,
            label: 'This month',
            value: '$currencySymbol${monthTotal.toStringAsFixed(2)}',
          ),
          SizedBox(height: tokens.spacing.md),
          const AppSectionHeader(title: 'Recent Transactions'),
          Expanded(
            child: transactionsError != null
                ? AsyncErrorView(
                    error: transactionsError,
                    onRetry: () => ref.invalidate(allTransactionsProvider),
                  )
                : categoryTransactions.isEmpty
                ? const EmptyState(
                    title: 'No transactions yet',
                    subtitle: 'Transactions in this category will show up here',
                    icon: Icons.receipt_long_outlined,
                    isCompact: true,
                  )
                : ListView.separated(
                    itemCount: categoryTransactions.length,
                    separatorBuilder: (_, _) => SizedBox(height: tokens.spacing.sm),
                    itemBuilder: (context, index) {
                      final transaction = categoryTransactions[index];
                      return EntityTile(
                        icon: Icons.receipt_rounded,
                        title: transaction.description,
                        subtitle: AppDateFormatter.date(transaction.date),
                        trailing: Text(
                          '$currencySymbol${transaction.amount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
