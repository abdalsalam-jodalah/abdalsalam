// lib/features/sync/screens/sync_report_screen.dart — full summary of one finished sync: totals, per-module breakdown and details.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/sync_constants.dart';
import '../../../core/constants/sync_ui_text.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/sync/sync_module_stats.dart';
import '../../../data/models/sync/sync_session_report.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../settings/widgets/settings_section_header.dart';
import '../services/sync_display_formatter.dart';
import '../widgets/sync_clock_skew_banner.dart';
import '../widgets/sync_module_stats_tile.dart';
import '../widgets/sync_report_details_card.dart';
import '../widgets/sync_totals_card.dart';

class SyncReportScreen extends ConsumerWidget {
  static const routeName = SyncConstants.reportRouteName;

  final SyncSessionReport report;

  const SyncReportScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = AppThemeTokens.of(context).spacing;
    final theme = Theme.of(context);
    final totals = report.totals;
    final hasTransfers = totals.hasTransfers;
    final hasDataChanges = totals.added + totals.updated + totals.deleted > 0;
    return Scaffold(
      appBar: AppBar(title: const Text(SyncUiText.reportTitle)),
      body: ListView(
        padding: EdgeInsets.all(spacing.lg),
        children: [
          if (report.hasClockSkewWarning) ...[const SyncClockSkewBanner(), SizedBox(height: spacing.md)],
          if (!hasTransfers)
            AppCard(
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: spacing.xxl, color: theme.colorScheme.primary),
                  SizedBox(height: spacing.sm),
                  Text(SyncUiText.emptyReportTitle, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                  SizedBox(height: spacing.xs),
                  const Text(SyncUiText.emptyReportMessage, textAlign: TextAlign.center),
                ],
              ),
            )
          else ...[
            const SettingsSectionHeader(SyncUiText.totalsSection),
            SyncTotalsCard(totals: totals),
            const SettingsSectionHeader(SyncUiText.modulesSection),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final entry in _sortedModules(report.moduleStats))
                    SyncModuleStatsTile(moduleKey: entry.key, stats: entry.value),
                ],
              ),
            ),
          ],
          const SettingsSectionHeader(SyncUiText.detailsSection),
          SyncReportDetailsCard(report: report),
          if (hasDataChanges) ...[
            SizedBox(height: spacing.lg),
            Text(SyncUiText.reloadHint, style: theme.textTheme.bodySmall),
            SizedBox(height: spacing.sm),
            FilledButton.icon(
              onPressed: () => ref.read(appReloadProvider)(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(SyncUiText.reloadAppLabel),
            ),
          ],
        ],
      ),
    );
  }

  List<MapEntry<String, SyncModuleStats>> _sortedModules(Map<String, SyncModuleStats> stats) {
    final entries = stats.entries.toList();
    entries.sort((first, second) {
      final transferOrder = (second.value.hasTransfers ? 1 : 0) - (first.value.hasTransfers ? 1 : 0);
      if (transferOrder != 0) {
        return transferOrder;
      }
      return SyncDisplayFormatter.moduleLabel(first.key).compareTo(SyncDisplayFormatter.moduleLabel(second.key));
    });
    return entries;
  }
}
