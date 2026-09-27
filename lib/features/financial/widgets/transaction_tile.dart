// lib/features/financial/widgets/transaction_tile.dart: list row for a single transaction.
import 'package:flutter/material.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/financial/transaction_model.dart';
import '../../../shared/widgets/ui/entity_tile.dart';

class TransactionTile extends StatelessWidget {
  static const String amountCurrencySymbol = '\$';

  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionTile({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final isIncome = transaction.type == TransactionType.income;
    final accentColor = isIncome ? tokens.colors.income : tokens.colors.expense;
    final sign = isIncome ? '+' : '-';
    return EntityTile(
      icon: isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
      accentColor: accentColor,
      title: transaction.description,
      subtitle: AppDateFormatter.dateTime(transaction.date),
      onTap: onTap,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$sign$amountCurrencySymbol${transaction.amount.toStringAsFixed(2)}',
            style: theme.textTheme.titleSmall?.copyWith(color: accentColor, fontWeight: FontWeight.bold),
          ),
          if (transaction.paymentMethod != null)
            Text(
              transaction.paymentMethod!,
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
