import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/app_card.dart';

class QuranReadingProgressCard extends StatelessWidget {
  final int totalPages;
  final int totalMinutes;
  final AsyncValue<int> pagesThisWeek;

  const QuranReadingProgressCard({
    super.key,
    required this.totalPages,
    required this.totalMinutes,
    required this.pagesThisWeek,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      accentColor: scheme.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_outlined, color: scheme.secondary),
              SizedBox(width: tokens.spacing.sm),
              Text('Reading Progress', style: theme.textTheme.titleMedium),
            ],
          ),
          SizedBox(height: tokens.spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Today'),
              Text(
                '$totalPages pages / $totalMinutes min',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: tokens.spacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('This week'),
              Text(
                pagesThisWeek.when(
                  data: (pages) => '$pages pages',
                  loading: () => '…',
                  error: (_, _) => '-',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
