// lib/features/financial/widgets/category_tile.dart: grid tile for a single spending or income category.
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/financial/category_model.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/icon_badge.dart';

class CategoryTile extends StatelessWidget {
  static const String currencySymbol = '₪';

  final CategoryModel category;
  final double monthTotal;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryTile({
    super.key,
    required this.category,
    required this.monthTotal,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    return AppCard(
      accentColor: category.color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: category.icon, color: category.color),
              const Spacer(),
              PopupMenuButton<String>(
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
              ),
            ],
          ),
          SizedBox(height: tokens.spacing.sm),
          Text(
            category.name,
            style: theme.textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text('$currencySymbol${monthTotal.toStringAsFixed(2)}', style: theme.textTheme.titleLarge),
          Text(
            'This month',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
