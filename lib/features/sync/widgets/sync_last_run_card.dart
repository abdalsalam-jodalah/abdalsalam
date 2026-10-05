// lib/features/sync/widgets/sync_last_run_card.dart — compact summary of the most recent sync with a link to its report.

import 'package:flutter/material.dart';

import '../../../core/constants/sync_ui_text.dart';
import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/sync/sync_session_report.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../services/sync_display_formatter.dart';
import 'sync_stat_row.dart';

class SyncLastRunCard extends StatelessWidget {
  final SyncSessionReport report;
  final VoidCallback onViewReport;

  const SyncLastRunCard({super.key, required this.report, required this.onViewReport});

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${SyncUiText.withDevicePrefix}${report.remoteDeviceLabel}', style: theme.textTheme.titleMedium),
          Text(AppDateFormatter.dateTime(report.startedAt), style: theme.textTheme.bodySmall),
          SizedBox(height: spacing.sm),
          SyncStatRow(label: SyncUiText.rowsSentLabel, value: '${report.totalRowsSent}'),
          SyncStatRow(label: SyncUiText.rowsReceivedLabel, value: '${report.totalRowsReceived}'),
          SyncStatRow(label: SyncUiText.durationLabel, value: SyncDisplayFormatter.duration(report.duration)),
          SizedBox(height: spacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onViewReport, child: const Text(SyncUiText.viewReportLabel)),
          ),
        ],
      ),
    );
  }
}
