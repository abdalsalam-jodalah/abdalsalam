// lib/features/sync/widgets/sync_history_tile.dart — one past sync run in the history list.

import 'package:flutter/material.dart';

import '../../../core/constants/sync_ui_text.dart';
import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/sync/sync_session_report.dart';

class SyncHistoryTile extends StatelessWidget {
  final SyncSessionReport report;
  final VoidCallback onTap;

  const SyncHistoryTile({super.key, required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeTokens.of(context).colors;
    final hasTransfers = report.totalRowsSent > 0 || report.totalRowsReceived > 0;
    return ListTile(
      leading: Icon(
        report.hasClockSkewWarning ? Icons.warning_amber_rounded : Icons.sync_rounded,
        color: report.hasClockSkewWarning ? colors.warning : null,
      ),
      title: Text('${SyncUiText.withDevicePrefix}${report.remoteDeviceLabel}'),
      subtitle: Text(
        '${AppDateFormatter.dateTime(report.startedAt)}\n'
        '${hasTransfers ? '${SyncUiText.rowsSentPrefix}${report.totalRowsSent}, ${SyncUiText.rowsReceivedPrefix}${report.totalRowsReceived}' : SyncUiText.nothingTransferredLabel}',
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
