import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/app_card.dart';
import 'money_text.dart';

class TransactionAmountPreview extends StatelessWidget {
  static const String _incomeLabel = 'Income';
  static const String _expenseLabel = 'Expense';

  final double amount;
  final bool isIncome;
  final String currencyCode;
  final String currencySymbol;

  const TransactionAmountPreview({
    super.key,
    required this.amount,
    required this.isIncome,
    required this.currencyCode,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final accentColor = isIncome ? tokens.colors.income : tokens.colors.expense;
    final sign = isIncome ? '+' : '-';
    final formattedAmount = MoneyFormatter.format(amount.abs(), symbol: currencySymbol);

    return AppCard(
      accentColor: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isIncome ? _incomeLabel : _expenseLabel,
            style: theme.textTheme.labelLarge?.copyWith(color: accentColor),
          ),
          SizedBox(height: tokens.spacing.xs),
          Text(
            '$sign$formattedAmount',
            style: theme.textTheme.displaySmall?.copyWith(color: accentColor),
          ),
          SizedBox(height: tokens.spacing.xs),
          Text(
            currencyCode,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
