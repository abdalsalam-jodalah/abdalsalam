import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/sleep/sleep_log.dart';
import '../../../shared/widgets/chart_widgets.dart';
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
          error: (error, _) => Text('Failed to load sleep logs: $error'),
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
          error: (error, _) => Text('Failed to load trend: $error'),
          data: (allLogs) {
            if (allLogs.isEmpty) {
              return const Text('No sleep data yet.');
            }
            final sorted = List<SleepLog>.of(allLogs)
              ..sort((a, b) => a.sleepStart.compareTo(b.sleepStart));
            final points = sorted.map((log) => log.duration.inMinutes / 60).toList();
            return TrendLineChart(points: points);
          },
        ),
        const SizedBox(height: 16),
        Text('Average Feelings', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        stats.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Failed to load stats: $error'),
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
