// lib/features/financial/widgets/budget_card.dart: card summarizing a single budget's progress.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/financial/budget_model.dart';
import '../../../data/models/financial/category_model.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/icon_badge.dart';
import '../../../shared/widgets/ui/progress_bar.dart';

class BudgetCard extends StatelessWidget {
  static const String currencySymbol = '₪';

  final BudgetModel budget;
  final CategoryModel? category;
  final AsyncValue<Map<String, dynamic>> progress;
  final VoidCallback onRetryProgress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BudgetCard({
    super.key,
    required this.budget,
    required this.category,
    required this.progress,
    required this.onRetryProgress,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final spent = progress.maybeWhen(
      data: (value) => (value['spent'] as num?)?.toDouble() ?? 0.0,
      orElse: () => 0.0,
    );
    final percentage = budget.amount == 0 ? 0.0 : (spent / budget.amount) * 100;
    final remaining = budget.amount - spent;
    final isOverBudget = spent > budget.amount;
    final isNearLimit = percentage >= budget.alertThreshold;
    final statusColor = isOverBudget
        ? tokens.colors.danger
        : isNearLimit
        ? tokens.colors.warning
        : tokens.colors.success;
    final categoryColor = category?.color ?? tokens.colors.muted;
    final categoryIcon = category?.icon ?? Icons.category;
    final categoryName = category?.name ?? 'Unknown category';

    return AppCard(
      accentColor: categoryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (progress.hasError)
            AsyncErrorView(error: progress.error!, isCompact: true, onRetry: onRetryProgress),
          Row(
            children: [
              IconBadge(icon: categoryIcon, color: categoryColor),
              SizedBox(width: tokens.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(categoryName, style: theme.textTheme.titleSmall),
                    Text(
                      budget.period.name.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: theme.textTheme.titleMedium?.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                  if (isOverBudget)
                    Text(
                      'Over Budget',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: tokens.colors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: tokens.spacing.md),
          ProgressBar(value: percentage / 100, color: statusColor),
          SizedBox(height: tokens.spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AmountColumn(label: 'Spent', value: '$currencySymbol${spent.toStringAsFixed(2)}'),
              _AmountColumn(
                label: 'Remaining',
                value: '$currencySymbol${remaining.toStringAsFixed(2)}',
                valueColor: remaining < 0 ? tokens.colors.danger : tokens.colors.success,
              ),
              _AmountColumn(
                label: 'Budget',
                value: '$currencySymbol${budget.amount.toStringAsFixed(2)}',
                crossAxisAlignment: CrossAxisAlignment.end,
              ),
            ],
          ),
          SizedBox(height: tokens.spacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              SizedBox(width: tokens.spacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(foregroundColor: tokens.colors.danger),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final CrossAxisAlignment crossAxisAlignment;

  const _AmountColumn({
    required this.label,
    required this.value,
    this.valueColor,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(color: valueColor, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
