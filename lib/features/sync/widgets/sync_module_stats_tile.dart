// lib/features/sync/widgets/sync_module_stats_tile.dart — per-module breakdown of one sync, expandable to full counts.

import 'package:flutter/material.dart';

import '../../../core/constants/sync_ui_text.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/sync/sync_module_stats.dart';
import '../services/sync_display_formatter.dart';
import 'sync_stat_row.dart';

class SyncModuleStatsTile extends StatelessWidget {
  final String moduleKey;
  final SyncModuleStats stats;

  const SyncModuleStatsTile({super.key, required this.moduleKey, required this.stats});

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final title = Text(SyncDisplayFormatter.moduleLabel(moduleKey));
    if (!stats.hasTransfers) {
      return ListTile(title: title, subtitle: const Text(SyncUiText.upToDateLabel));
    }
    return ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      title: title,
      subtitle: Text(
        '${SyncUiText.rowsSentPrefix}${stats.rowsSent}, ${SyncUiText.rowsReceivedPrefix}${stats.rowsReceived}',
      ),
      childrenPadding: EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.sm),
      children: [
        SyncStatRow(label: SyncUiText.addedLabel, value: '${stats.added}'),
        SyncStatRow(label: SyncUiText.updatedLabel, value: '${stats.updated}'),
        SyncStatRow(label: SyncUiText.deletedLabel, value: '${stats.deleted}'),
        SyncStatRow(label: SyncUiText.skippedLabel, value: '${stats.skipped}'),
        SyncStatRow(label: SyncUiText.conflictsLabel, value: '${stats.conflicts}'),
        SyncStatRow(label: SyncUiText.attachmentsLabel, value: '${stats.attachments}'),
        SyncStatRow(label: SyncUiText.bytesSentLabel, value: SyncDisplayFormatter.bytes(stats.bytesSent)),
        SyncStatRow(label: SyncUiText.bytesReceivedLabel, value: SyncDisplayFormatter.bytes(stats.bytesReceived)),
      ],
    );
  }
}
