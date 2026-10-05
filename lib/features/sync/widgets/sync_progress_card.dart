// lib/features/sync/widgets/sync_progress_card.dart — live phase, module, row counts and overall progress of a running sync.

import 'package:flutter/material.dart';

import '../../../core/constants/sync_ui_text.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/sync/sync_progress_event.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../services/sync_display_formatter.dart';
import '../services/sync_progress_fraction.dart';

class SyncProgressCard extends StatelessWidget {
  final SyncProgressEvent? event;

  const SyncProgressCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final theme = Theme.of(context);
    final current = event;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            current == null ? SyncUiText.idleProgress : SyncDisplayFormatter.phase(current.phase),
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: spacing.sm),
          LinearProgressIndicator(value: current == null ? 0 : SyncProgressFraction.of(current.phase)),
          if (current != null && current.moduleKey != null) ...[
            SizedBox(height: spacing.sm),
            Text(
              '${SyncUiText.currentModulePrefix}${SyncDisplayFormatter.moduleLabel(current.moduleKey!)}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (current != null && current.rowsTotal > 0)
            Text(
              '${current.rowsDone}${SyncUiText.rowsProgressSeparator}${current.rowsTotal} ${SyncUiText.rowsSuffix}',
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
