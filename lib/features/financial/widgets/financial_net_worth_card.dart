import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/financial/transaction_model.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/async_section.dart';
import '../../../shared/widgets/ui/icon_badge.dart';
import '../providers/financial_providers.dart';
import 'money_text.dart';

class FinancialNetWorthCard extends ConsumerWidget {
  static const IconData _icon = Icons.savings_rounded;
  static const String _title = 'Net Worth';
  static const String _noBudgetsMessage = 'No active budgets';
  static const String _upcomingRecurringTitle = 'Upcoming recurring';

  const FinancialNetWorthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = AppModuleAccents.forModule('financial');
    return AppCard(
      accentColor: accent,
      child: AsyncSection(
        value: ref.watch(netWorthProvider),
        onRetry: () => ref.invalidate(netWorthProvider),
        builder: (summary) => _NetWorthContent(summary: summary, accent: accent),
      ),
    );
  }
}

class _NetWorthContent extends StatelessWidget {
  final Map<String, dynamic> summary;
  final Color accent;

  const _NetWorthContent({required this.summary, required this.accent});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final netWorth = (summary['netWorth'] as double?) ?? 0;
    final accountCount = (summary['accountCount'] as int?) ?? 0;
    final totalBudgets = (summary['totalBudgets'] as int?) ?? 0;
    final budgetsNearOrOverLimit = (summary['budgetsNearOrOverLimit'] as int?) ?? 0;
    final upcomingRecurring = (summary['upcomingRecurring'] as List<TransactionModel>?) ?? [];
    final hasBudgetWarning = budgetsNearOrOverLimit > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconBadge(icon: FinancialNetWorthCard._icon, color: accent),
            SizedBox(width: tokens.spacing.sm),
            Text(FinancialNetWorthCard._title, style: theme.textTheme.titleMedium),
          ],
        ),
        SizedBox(height: tokens.spacing.sm),
        MoneyText(netWorth, style: theme.textTheme.headlineSmall),
        SizedBox(height: tokens.spacing.xs),
        Text(
          '$accountCount account${accountCount == 1 ? '' : 's'}',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        SizedBox(height: tokens.spacing.md),
        Row(
          children: [
            Icon(
              hasBudgetWarning ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
              size: _statusIconSize,
              color: hasBudgetWarning ? tokens.colors.warning : tokens.colors.success,
            ),
            SizedBox(width: tokens.spacing.sm),
            Expanded(
              child: Text(
                totalBudgets == 0
                    ? FinancialNetWorthCard._noBudgetsMessage
                    : '$budgetsNearOrOverLimit of $totalBudgets budgets near/over limit',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        if (upcomingRecurring.isNotEmpty) ...[
          SizedBox(height: tokens.spacing.md),
          Text(FinancialNetWorthCard._upcomingRecurringTitle, style: theme.textTheme.labelLarge),
          SizedBox(height: tokens.spacing.xs),
          for (final transaction in upcomingRecurring)
            Padding(
              padding: EdgeInsets.only(top: tokens.spacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      transaction.description,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${MoneyFormatter.format(transaction.amount, symbol: '', decimalDigits: 2)} '
                    '${transaction.currency} • ${AppDateFormatter.shortDate(transaction.recurrenceNextDueDate!)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  static const double _statusIconSize = 18;
}
