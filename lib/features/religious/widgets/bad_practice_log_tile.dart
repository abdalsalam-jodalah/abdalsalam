import 'package:flutter/material.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/religious/bad_practice_log.dart';
import '../../../shared/widgets/ui/app_card.dart';

class BadPracticeLogTile extends StatelessWidget {
  static const double _iconSize = 18;

  final BadPracticeLog log;

  const BadPracticeLogTile({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      accentColor: tokens.colors.danger,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_outlined, color: tokens.colors.danger, size: _iconSize),
                    SizedBox(width: tokens.spacing.sm),
                    Expanded(child: Text(log.title, style: theme.textTheme.titleMedium)),
                  ],
                ),
              ),
              Text(
                AppDateFormatter.dateTime(log.occurredAt),
                style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          if (log.feelingBefore != null || log.feelingAfter != null) ...[
            SizedBox(height: tokens.spacing.sm),
            Text('Feeling: ${log.feelingBefore ?? '-'} → ${log.feelingAfter ?? '-'}', style: theme.textTheme.bodySmall),
          ],
          if (log.consequences != null && log.consequences!.isNotEmpty) ...[
            SizedBox(height: tokens.spacing.xs),
            Text('Consequences: ${log.consequences}', style: theme.textTheme.bodySmall),
          ],
          if (log.notes != null && log.notes!.isNotEmpty) ...[
            SizedBox(height: tokens.spacing.xs),
            Text(log.notes!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
