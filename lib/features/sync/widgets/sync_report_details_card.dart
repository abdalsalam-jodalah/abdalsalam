// lib/features/sync/widgets/sync_report_details_card.dart — devices, timing, clock offset and safety backup of one sync.

import 'package:flutter/material.dart';

import '../../../core/constants/sync_ui_text.dart';
import '../../../core/formatting/app_date_formatter.dart';
import '../../../data/models/sync/sync_session_report.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../services/sync_display_formatter.dart';
import 'sync_stat_row.dart';

class SyncReportDetailsCard extends StatelessWidget {
  final SyncSessionReport report;

  const SyncReportDetailsCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final backupPath = report.safetyBackupPath;
    return AppCard(
      child: Column(
        children: [
          SyncStatRow(label: SyncUiText.otherDeviceLabel, value: report.remoteDeviceLabel),
          SyncStatRow(label: SyncUiText.startedLabel, value: AppDateFormatter.dateTime(report.startedAt)),
          SyncStatRow(label: SyncUiText.durationLabel, value: SyncDisplayFormatter.duration(report.duration)),
          SyncStatRow(label: SyncUiText.clockOffsetLabel, value: SyncDisplayFormatter.clockOffset(report.clockSkew)),
          if (backupPath != null) SyncStatRow(label: SyncUiText.safetyBackupLabel, value: backupPath),
        ],
      ),
    );
  }
}
