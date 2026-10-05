// lib/features/sync/widgets/sync_history_section.dart — last-run summary and the list of previous syncs, shared by both roles.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/sync_ui_text.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/sync/sync_session_report.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../settings/widgets/settings_section_header.dart';
import '../providers/sync_providers.dart';
import 'sync_history_tile.dart';
import 'sync_last_run_card.dart';
import 'sync_report_navigator.dart';

class SyncHistorySection extends ConsumerWidget {
  const SyncHistorySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(syncHistoryProvider);
    return history.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => _buildMessage(context, SyncUiText.historyLoadFailedMessage),
      data: (reports) => _buildContent(context, reports),
    );
  }

  Widget _buildMessage(BuildContext context, String message) {
    final spacing = AppThemeTokens.of(context).spacing;
    return Padding(
      padding: EdgeInsets.only(top: spacing.lg),
      child: Center(child: Text(message)),
    );
  }

  Widget _buildContent(BuildContext context, List<SyncSessionReport> reports) {
    if (reports.isEmpty) {
      return _buildMessage(context, SyncUiText.noHistoryMessage);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsSectionHeader(SyncUiText.lastRunSection),
        SyncLastRunCard(report: reports.first, onViewReport: () => SyncReportNavigator.open(context, reports.first)),
        const SettingsSectionHeader(SyncUiText.historySection),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final report in reports)
                SyncHistoryTile(report: report, onTap: () => SyncReportNavigator.open(context, report)),
            ],
          ),
        ),
      ],
    );
  }
}
