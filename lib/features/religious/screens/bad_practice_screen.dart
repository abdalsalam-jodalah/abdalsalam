import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/charts/app_line_chart.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../../../shared/widgets/ui/stat_grid.dart';
import '../../../shared/widgets/ui/stat_tile.dart';
import '../providers/bad_practice_providers.dart';
import '../widgets/bad_practice_dialog.dart';
import '../widgets/bad_practice_log_tile.dart';

class BadPracticeScreen extends ConsumerWidget {
  const BadPracticeScreen({super.key});

  static const String routeName = '/religious/bad-practice';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppThemeTokens.of(context);
    final state = ref.watch(badPracticeLogControllerProvider);
    final weeklyTrend = ref.watch(badPracticeWeeklyTrendProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bad Practice Log')),
      body: state.when(
        data: (logs) {
          final now = DateTime.now();
          final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
          final thisWeekCount = logs.where((item) => !item.occurredAt.isBefore(startOfWeek)).length;

          return ListView(
            padding: EdgeInsets.all(tokens.spacing.lg),
            children: [
              StatGrid(
                children: [
                  StatTile(
                    icon: Icons.warning_amber_rounded,
                    label: 'Total entries',
                    value: '${logs.length}',
                    accentColor: tokens.colors.danger,
                  ),
                  StatTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'This week',
                    value: '$thisWeekCount',
                    accentColor: tokens.colors.danger,
                  ),
                ],
              ),
              AppSectionHeader(title: 'Weekly Trend (Last 8 Weeks)'),
              AppCard(child: AppLineChart(points: weeklyTrend, color: tokens.colors.danger)),
              AppSectionHeader(title: 'History'),
              if (logs.isEmpty)
                EmptyState(
                  title: 'No entries yet',
                  subtitle: 'Log a bad practice event to start tracking patterns over time.',
                  actionLabel: 'Log Entry',
                  onAction: () => _showAddDialog(context, ref),
                ),
              for (final log in logs)
                Padding(
                  padding: EdgeInsets.only(bottom: tokens.spacing.sm),
                  child: BadPracticeLogTile(log: log),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncErrorView(
          error: err,
          onRetry: () => ref.invalidate(badPracticeLogControllerProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Log Entry'),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) {
    return showBadPracticeDialog(context, ref);
  }
}
