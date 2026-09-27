import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/icon_badge.dart';
import '../../../shared/widgets/ui/progress_bar.dart';
import 'money_text.dart';

class FinancialBudgetTile extends StatelessWidget {
  static const double width = 168;
  static const double _overThresholdPercent = 80;
  static const double _tileIconSize = 32;

  final String categoryName;
  final IconData categoryIcon;
  final Color accentColor;
  final double budgetAmount;
  final double? spentAmount;
  final Object? error;
  final VoidCallback? onRetry;

  const FinancialBudgetTile({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.accentColor,
    required this.budgetAmount,
    this.spentAmount,
    this.error,
    this.onRetry,
  });

  double get _percentage => budgetAmount > 0 ? ((spentAmount ?? 0) / budgetAmount) * 100 : 0;

  bool get _isOverThreshold => _percentage > _overThresholdPercent;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final progressColor = _isOverThreshold ? tokens.colors.danger : accentColor;

    return SizedBox(
      width: width,
      child: AppCard(
        padding: EdgeInsets.all(tokens.spacing.md),
        accentColor: accentColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconBadge(icon: categoryIcon, color: accentColor, size: _tileIconSize),
                const Spacer(),
                if (error == null)
                  Text(
                    '${_percentage.toStringAsFixed(0)}%',
                    style: theme.textTheme.labelMedium?.copyWith(color: progressColor),
                  ),
              ],
            ),
            SizedBox(height: tokens.spacing.sm),
            Text(
              categoryName,
              style: theme.textTheme.labelLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: tokens.spacing.xs),
            if (error != null)
              AsyncErrorView(error: error!, onRetry: onRetry, isCompact: true)
            else ...[
              ProgressBar(value: budgetAmount > 0 ? (spentAmount ?? 0) / budgetAmount : 0, color: progressColor),
              SizedBox(height: tokens.spacing.xs),
              Text(
                '${MoneyFormatter.format(spentAmount ?? 0, decimalDigits: 0)}/'
                '${MoneyFormatter.format(budgetAmount, decimalDigits: 0)}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
