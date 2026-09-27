import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/sleep/sleep_log.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/charts/app_line_chart.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/async_section.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../../../shared/widgets/ui/page_header.dart';
import '../../../shared/widgets/ui/progress_bar.dart';
import '../providers/sleep_providers.dart';
import 'sleep_log_form_screen.dart';

class SleepHomeScreen extends ConsumerWidget {
  static const routeName = '/sleep/home';
  static const String _pageTitle = 'Sleep Home';
  static const String _dashboardTitle = 'Dashboard';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [SleepScreen] shell.
  final bool embedded;

  const SleepHomeScreen({super.key, this.embedded = false});

  String _formatRating(double? value) => value == null ? 'No data' : value.toStringAsFixed(1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppThemeTokens.of(context);
    final accent = AppModuleAccents.forModule('sleep');
    final logs = ref.watch(sleepLogsProvider);
    final stats = ref.watch(sleepLogStatisticsProvider);
    final insights = ref.watch(sleepInsightsProvider);
    final goalHours = ref.watch(sleepGoalHoursProvider);

    final sections = [
      FilledButton.icon(
        onPressed: () => Navigator.of(context).pushNamed(SleepLogFormScreen.routeName),
        icon: const Icon(Icons.add),
        label: const Text('Log Sleep'),
      ),
      AsyncSection(
        title: 'Last Night',
        value: logs,
        onRetry: () => ref.invalidate(sleepLogsProvider),
        builder: (allLogs) {
          if (allLogs.isEmpty) {
            return const Text('No sleep logs yet.');
          }
          final last = allLogs.first;
          final hours = last.duration.inMinutes / 60;
          return EntityTile(
            icon: Icons.bedtime_outlined,
            accentColor: accent,
            title: '${hours.toStringAsFixed(1)} hours',
            subtitle: '${last.nightWakeCount} wake-up(s)',
          );
        },
      ),
      AsyncSection(
        title: 'Sleep Hours Trend',
        value: logs,
        onRetry: () => ref.invalidate(sleepLogsProvider),
        builder: (allLogs) {
          if (allLogs.isEmpty) {
            return const Text('No sleep data yet.');
          }
          final sorted = List<SleepLog>.of(allLogs)..sort((a, b) => a.sleepStart.compareTo(b.sleepStart));
          final points = sorted.map((log) => log.duration.inMinutes / 60).toList();
          return AppCard(child: AppLineChart(points: points, color: accent));
        },
      ),
      AsyncSection(
        title: 'Weekly Insights',
        value: insights,
        onRetry: () => ref.invalidate(sleepInsightsProvider),
        builder: (data) {
          final avgThisWeek = data['avgHoursThisWeek'] as double?;
          final deltaHours = data['weeklyDeltaHours'] as double?;
          final caffeineNights = data['caffeineTooCloseNights'] as int? ?? 0;
          final avgLabel = avgThisWeek == null
              ? 'No data yet this week'
              : '${avgThisWeek.toStringAsFixed(1)}h avg this week'
                  '${deltaHours == null ? '' : ' (${deltaHours >= 0 ? '+' : ''}${deltaHours.toStringAsFixed(1)}h vs last week)'}';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EntityTile(icon: Icons.insights_outlined, accentColor: accent, title: avgLabel),
              if (caffeineNights > 0) ...[
                SizedBox(height: tokens.spacing.sm),
                EntityTile(
                  icon: Icons.warning_amber_outlined,
                  accentColor: tokens.colors.warning,
                  title: 'Caffeine within 6h of bedtime on $caffeineNights night(s) this week',
                ),
              ],
            ],
          );
        },
      ),
      AsyncSection(
        title: 'Weekly Sleep Goal',
        value: goalHours,
        onRetry: () => ref.invalidate(sleepGoalHoursProvider),
        builder: (goal) {
          return logs.when(
            loading: () => const SizedBox.shrink(),
            error: (error, _) => AsyncErrorView(
              error: error,
              isCompact: true,
              onRetry: () => ref.invalidate(sleepLogsProvider),
            ),
            data: (allLogs) {
              final startOfWeek = DateTime.now().subtract(Duration(days: DateTime.now().weekday - DateTime.monday));
              final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
              final weekTotalHours = allLogs
                  .where((log) => !log.sleepStart.isBefore(startOfWeekDay))
                  .fold<double>(0, (sum, log) => sum + log.duration.inMinutes / 60);
              final goalTotalHours = goal * 7;
              final progress = goalTotalHours == 0 ? 0.0 : (weekTotalHours / goalTotalHours).clamp(0.0, 1.0);
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProgressBar(value: progress, color: accent),
                    SizedBox(height: tokens.spacing.sm),
                    Text(
                      '${weekTotalHours.toStringAsFixed(1)}h / ${goalTotalHours.toStringAsFixed(1)}h this week '
                      'toward your ${goal.toStringAsFixed(1)}h/night goal',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      AsyncSection(
        title: 'Average Feelings',
        value: stats,
        onRetry: () => ref.invalidate(sleepLogStatisticsProvider),
        builder: (data) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Before sleep: ${_formatRating(data['averageFeelingBeforeSleep'] as double?)}'),
                Text('On wakeup: ${_formatRating(data['averageFeelingOnWakeup'] as double?)}'),
                Text('During day: ${_formatRating(data['averageFeelingDuringDay'] as double?)}'),
              ],
            ),
          );
        },
      ),
    ];

    if (embedded) {
      return ListView(
        children: [
          const PageHeader(title: _dashboardTitle),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (final section in sections) ...[section, SizedBox(height: tokens.spacing.lg)]],
            ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text(_pageTitle)),
      body: ListView(
        padding: EdgeInsets.all(tokens.spacing.lg),
        children: [for (final section in sections) ...[section, SizedBox(height: tokens.spacing.lg)]],
      ),
    );
  }
}
