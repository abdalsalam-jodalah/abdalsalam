import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/async_section.dart';
import '../../../shared/widgets/ui/icon_badge.dart';
import '../providers/financial_providers.dart';
import 'money_text.dart';

class FinancialBalanceSummaryCard extends ConsumerWidget {
  static const IconData _icon = Icons.account_balance_wallet_rounded;
  static const String _title = 'Total Balance';
  static const String _incomeLabel = 'Income: ';
  static const String _expenseLabel = ' • Expense: ';

  final DateRange dateRange;

  const FinancialBalanceSummaryCard({super.key, required this.dateRange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = AppModuleAccents.forModule('financial');
    return AppCard(
      accentColor: accent,
      child: AsyncSection(
        value: ref.watch(financialSummaryProvider(dateRange)),
        onRetry: () => ref.invalidate(financialSummaryProvider(dateRange)),
        builder: (summary) => _BalanceContent(summary: summary, accent: accent),
      ),
    );
  }
}

class _BalanceContent extends StatelessWidget {
  final Map<String, double> summary;
  final Color accent;

  const _BalanceContent({required this.summary, required this.accent});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final balance = summary['balance'] ?? 0;
    final income = summary['income'] ?? 0;
    final expense = summary['expense'] ?? 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconBadge(icon: FinancialBalanceSummaryCard._icon, color: accent),
        SizedBox(width: tokens.spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                FinancialBalanceSummaryCard._title,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              SizedBox(height: tokens.spacing.xs),
              MoneyText(balance, style: theme.textTheme.headlineSmall),
              SizedBox(height: tokens.spacing.xs),
              Row(
                children: [
                  Text(FinancialBalanceSummaryCard._incomeLabel, style: theme.textTheme.bodySmall),
                  MoneyText(
                    income,
                    decimalDigits: 0,
                    style: theme.textTheme.bodySmall?.copyWith(color: tokens.colors.income, fontWeight: FontWeight.w600),
                  ),
                  Text(FinancialBalanceSummaryCard._expenseLabel, style: theme.textTheme.bodySmall),
                  MoneyText(
                    expense,
                    decimalDigits: 0,
                    style: theme.textTheme.bodySmall?.copyWith(color: tokens.colors.expense, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
