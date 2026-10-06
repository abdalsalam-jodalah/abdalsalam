import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/religious/prayer_log.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../../../shared/widgets/ui/page_header.dart';
import '../providers/prayer_providers.dart';
import '../providers/religious_tracking_providers.dart';
import '../widgets/prayer_calendar_heatmap.dart';
import '../widgets/prayer_log_dialog.dart';
import '../widgets/prayer_log_tile.dart';
import '../widgets/prayer_stats_summary.dart';
import '../widgets/prayer_streak_widget.dart';
import 'quran_progress_screen.dart';

class PrayerLogsScreen extends ConsumerWidget {
  /// When true, renders without its own [Scaffold]/[AppBar]/FAB for
  /// embedding inside the tabbed [ReligiousScreen] shell.
  final bool embedded;

  const PrayerLogsScreen({super.key, this.embedded = false});

  static const String routeName = '/religious/prayers';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (embedded) {
      return Column(
        children: [
          PageHeader(
            title: 'Prayers',
            actions: [
              IconButton(
                icon: const Icon(Icons.menu_book_outlined),
                tooltip: 'Quran progress',
                onPressed: () => Navigator.of(context).pushNamed(QuranProgressScreen.routeName),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Log',
                onPressed: () => _showAddDialog(context, ref),
              ),
            ],
          ),
          Expanded(child: _buildBody(context, ref)),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Logs'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(QuranProgressScreen.routeName),
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Quran'),
          ),
        ],
      ),
      body: _buildBody(context, ref),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        label: const Text('Add Log'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final tokens = AppThemeTokens.of(context);
    final logsState = ref.watch(prayerLogsControllerProvider);
    final allLogsState = ref.watch(prayerAllLogsProvider);
    final streak = ref.watch(religiousStreakProvider);

    return ListView(
      padding: EdgeInsets.all(tokens.spacing.lg),
      children: [
        streak.maybeWhen(
          data: (value) => PrayerStreakWidget(streakDays: value),
          orElse: () => const SizedBox.shrink(),
        ),
        SizedBox(height: tokens.spacing.md),
        allLogsState.when(
          data: (allLogs) => PrayerStatsSummary(allLogs: allLogs),
          loading: () => Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.spacing.xl),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => AsyncErrorView(
            error: err,
            isCompact: true,
            onRetry: () => ref.invalidate(prayerAllLogsProvider),
          ),
        ),
        SizedBox(height: tokens.spacing.md),
        allLogsState.when(
          data: (allLogs) => PrayerCalendarHeatmap(dailyCompletions: _dailyCompletions(allLogs)),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => AsyncErrorView(
            error: err,
            isCompact: true,
            onRetry: () => ref.invalidate(prayerAllLogsProvider),
          ),
        ),
        AppSectionHeader(title: 'Today'),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: const ValueKey('log-prayer-for-god'),
            onPressed: () => _showAddDialog(context, ref, initialPrayer: PrayerName.voluntary),
            icon: const Icon(Icons.volunteer_activism_rounded),
            label: const Text('Log a prayer for God'),
          ),
        ),
        SizedBox(height: tokens.spacing.sm),
        logsState.when(
          data: (logs) => logs.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: tokens.spacing.sm),
                  child: Text('No prayer logs for today yet.', style: Theme.of(context).textTheme.bodyMedium),
                )
              : Column(
                  children: [
                    for (final log in logs)
                      Padding(
                        padding: EdgeInsets.only(bottom: tokens.spacing.sm),
                        child: PrayerLogTile(log: log),
                      ),
                  ],
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => AsyncErrorView(
            error: err,
            isCompact: true,
            onRetry: () => ref.invalidate(prayerLogsControllerProvider),
          ),
        ),
        AppSectionHeader(title: 'History'),
        allLogsState.when(
          data: (allLogs) {
            if (allLogs.isEmpty) {
              return EmptyState(
                title: 'No prayer logs yet',
                subtitle: 'Add your first prayer log to start tracking.',
                actionLabel: 'Add Log',
                onAction: () => _showAddDialog(context, ref),
              );
            }
            final sorted = [...allLogs]..sort((a, b) => b.prayedAt.compareTo(a.prayedAt));
            return Column(
              children: [
                for (final log in sorted)
                  Padding(
                    padding: EdgeInsets.only(bottom: tokens.spacing.sm),
                    child: PrayerLogTile(log: log),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => AsyncErrorView(
            error: err,
            isCompact: true,
            onRetry: () => ref.invalidate(prayerAllLogsProvider),
          ),
        ),
      ],
    );
  }

  static Map<DateTime, int> _dailyCompletions(List<PrayerLog> logs) {
    final map = <DateTime, int>{};
    for (final log in logs.where((log) => log.prayerName.isObligatory)) {
      final day = DateTime(log.prayedAt.year, log.prayedAt.month, log.prayedAt.day);
      map[day] = (map[day] ?? 0) + 1;
    }
    return map;
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref, {PrayerName initialPrayer = PrayerName.fajr}) async {
    DateTime? scheduledAt;
    try {
      final snapshot = await ref.read(todayPrayerTimesProvider.future);
      scheduledAt = scheduledTimeForPrayer(initialPrayer, snapshot);
    } catch (error, stackTrace) {
      ref.read(loggerProvider).error(
            'Could not resolve today\'s scheduled prayer time for the add-log dialog default.',
            error: error,
            stackTrace: stackTrace,
          );
      scheduledAt = null;
    }

    if (!context.mounted) {
      return;
    }

    final result = await showPrayerLogDialog(
      context,
      ref,
      initialScheduledAt: scheduledAt,
      initialPrayer: initialPrayer,
    );

    if (result == null) return;

    final error = await ref.read(prayerLogsControllerProvider.notifier).addPrayer(
          prayer: result.prayer,
          onTimeOverride: result.overrideOnTime ? result.manualOnTime : null,
          prayedAt: result.prayedAt,
          notes: result.notes,
        );

    if (error != null && context.mounted) {
      AppFeedback.showError(context, error);
    }
  }
}
