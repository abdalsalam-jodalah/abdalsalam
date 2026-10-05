// lib/features/sync/widgets/sync_totals_card.dart — session-wide totals for the report screen.

import 'package:flutter/material.dart';

import '../../../core/constants/sync_ui_text.dart';
import '../../../data/models/sync/sync_module_stats.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../services/sync_display_formatter.dart';
import 'sync_stat_row.dart';

class SyncTotalsCard extends StatelessWidget {
  final SyncModuleStats totals;

  const SyncTotalsCard({super.key, required this.totals});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          SyncStatRow(label: SyncUiText.rowsSentLabel, value: '${totals.rowsSent}'),
          SyncStatRow(label: SyncUiText.rowsReceivedLabel, value: '${totals.rowsReceived}'),
          SyncStatRow(label: SyncUiText.addedLabel, value: '${totals.added}'),
          SyncStatRow(label: SyncUiText.updatedLabel, value: '${totals.updated}'),
          SyncStatRow(label: SyncUiText.deletedLabel, value: '${totals.deleted}'),
          SyncStatRow(label: SyncUiText.skippedLabel, value: '${totals.skipped}'),
          SyncStatRow(label: SyncUiText.conflictsLabel, value: '${totals.conflicts}'),
          SyncStatRow(label: SyncUiText.attachmentsLabel, value: '${totals.attachments}'),
          SyncStatRow(label: SyncUiText.bytesSentLabel, value: SyncDisplayFormatter.bytes(totals.bytesSent)),
          SyncStatRow(label: SyncUiText.bytesReceivedLabel, value: SyncDisplayFormatter.bytes(totals.bytesReceived)),
        ],
      ),
    );
  }
}
