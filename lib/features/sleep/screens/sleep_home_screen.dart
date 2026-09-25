import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/sleep/sleep_log.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/charts/app_line_chart.dart';
import '../providers/sleep_providers.dart';
import 'sleep_log_form_screen.dart';

class SleepHomeScreen extends ConsumerWidget {
  static const routeName = '/sleep/home';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [SleepScreen] shell.
  final bool embedded;

  const SleepHomeScreen({super.key, this.embedded = false});

  String _formatRating(double? value) => value == null ? 'No data' : value.toStringAsFixed(1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(sleepLogsProvider);
    final stats = ref.watch(sleepLogStatisticsProvider);
    final insights = ref.watch(sleepInsightsProvider);
    final goalHours = ref.watch(sleepGoalHoursProvider);

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (embedded)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Dashboard',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pushNamed(SleepLogFormScreen.routeName),
          icon: const Icon(Icons.add),
          label: const Text('Log Sleep'),
        ),
        const SizedBox(height: 16),
        Text("Last Night", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        logs.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncErrorView(
            error: error,
            isCompact: true,
            onRetry: () => ref.invalidate(sleepLogsProvider),
          ),
          data: (allLogs) {
            if (allLogs.isEmpty) {
              return const Text('No sleep logs yet.');
            }
            final last = allLogs.first;
            final hours = last.duration.inMinutes / 60;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.bedtime_outlined),
                title: Text('${hours.toStringAsFixed(1)} hours'),
                subtitle: Text('${last.nightWakeCount} wake-up(s)'),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text('Sleep Hours Trend', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        logs.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncErrorView(
            error: error,
            isCompact: true,
            onRetry: () => ref.invalidate(sleepLogsProvider),
          ),
          data: (allLogs) {
            if (allLogs.isEmpty) {
              return const Text('No sleep data yet.');
            }
            final sorted = List<SleepLog>.of(allLogs)
              ..sort((a, b) => a.sleepStart.compareTo(b.sleepStart));
            final points = sorted.map((log) => log.duration.inMinutes / 60).toList();
            return AppLineChart(points: points);
          },
        ),
        const SizedBox(height: 16),
        Text('Weekly Insights', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        insights.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncErrorView(
            error: error,
            isCompact: true,
            onRetry: () => ref.invalidate(sleepInsightsProvider),
          ),
          data: (data) {
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
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.insights_outlined),
                    title: Text(avgLabel),
                  ),
                ),
                if (caffeineNights > 0)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: ListTile(
                      leading: Icon(Icons.warning_amber_outlined, color: Theme.of(context).colorScheme.onErrorContainer),
                      title: Text(
                        'Caffeine within 6h of bedtime on $caffeineNights night(s) this week',
                        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Text('Weekly Sleep Goal', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        goalHours.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncErrorView(
            error: error,
            isCompact: true,
            onRetry: () => ref.invalidate(sleepGoalHoursProvider),
          ),
          data: (goal) {
            return logs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
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
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: 8),
                        Text(
                          '${weekTotalHours.toStringAsFixed(1)}h / ${goalTotalHours.toStringAsFixed(1)}h this week '
                          'toward your ${goal.toStringAsFixed(1)}h/night goal',
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),
        Text('Average Feelings', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        stats.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncErrorView(
            error: error,
            isCompact: true,
            onRetry: () => ref.invalidate(sleepLogStatisticsProvider),
          ),
          data: (data) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Before sleep: ${_formatRating(data['averageFeelingBeforeSleep'] as double?)}'),
                    Text('On wakeup: ${_formatRating(data['averageFeelingOnWakeup'] as double?)}'),
                    Text('During day: ${_formatRating(data['averageFeelingDuringDay'] as double?)}'),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );

    if (embedded) {
      return body;
    }
    return Scaffold(appBar: AppBar(title: const Text('Sleep Home')), body: body);
  }
}
