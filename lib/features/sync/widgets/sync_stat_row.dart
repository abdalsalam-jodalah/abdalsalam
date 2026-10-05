// lib/features/sync/widgets/sync_stat_row.dart — one label and value line used by sync report cards.

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';

class SyncStatRow extends StatelessWidget {
  final String label;
  final String value;

  const SyncStatRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textTheme.bodyMedium)),
          SizedBox(width: spacing.md),
          Flexible(
            child: Text(value, style: textTheme.titleSmall, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
