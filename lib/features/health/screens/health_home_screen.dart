import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/health/health_metric.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/charts/app_line_chart.dart';
import '../../food/screens/food_home_screen.dart';
import '../../food/screens/food_log_form_screen.dart';
import '../../sleep/screens/sleep_home_screen.dart';
import '../../sleep/screens/sleep_log_form_screen.dart';
import '../providers/health_providers.dart';
import 'medication_form_screen.dart';

class HealthHomeScreen extends ConsumerWidget {
  static const routeName = '/health/home';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [HealthScreen] shell.
  final bool embedded;

  const HealthHomeScreen({super.key, this.embedded = false});

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationStats = ref.watch(medicationStatisticsProvider);
    final checklist = ref.watch(todayMedicationChecklistProvider);
    final metrics = ref.watch(healthMetricsProvider);
    final bloodTestStats = ref.watch(bloodTestStatisticsProvider);
    final doctorVisitStats = ref.watch(doctorVisitStatisticsProvider);
    final activityFeed = ref.watch(healthActivityFeedProvider);
    final healthSummary = ref.watch(healthSummaryProvider);

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
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(MedicationFormScreen.routeName),
                icon: const Icon(Icons.add),
                label: const Text('Add Medication'),
              ),
            ),
            const SizedBox(width: 8),
            const _ExportReportButton(),
          ],
        ),
        const SizedBox(height: 16),
        Text("Today's Schedule", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        checklist.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncErrorView(
            error: error,
            isCompact: true,
            onRetry: () => ref.invalidate(todayMedicationChecklistProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const Text('No medications scheduled today.');
            }
            return Column(
              children: items
                  .map((item) => Card(
                        child: ListTile(
                          leading: Icon(
                            item.isChecked ? Icons.check_circle : Icons.medication_outlined,
                            color: item.isChecked ? Colors.green : null,
                          ),
                          title: Text(item.medicationName),
                          subtitle: Text('${item.displayTime} • ${item.dosage}'),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 16),
        Text('Adherence', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: medicationStats.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AsyncErrorView(
                error: error,
                isCompact: true,
                onRetry: () => ref.invalidate(medicationStatisticsProvider),
              ),
              data: (stats) {
                final adherenceRate = stats['adherenceRate'];
                final adherence = adherenceRate is num ? adherenceRate.toDouble() : 0.0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Adherence: ${adherence.toStringAsFixed(1)}%'),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: (adherence / 100).clamp(0, 1)),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Metrics Trend', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        metrics.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncErrorView(
            error: error,
            isCompact: true,
            onRetry: () => ref.invalidate(healthMetricsProvider),
          ),
          data: (allMetrics) {
            if (allMetrics.isEmpty) {
              return const Text('No metrics logged yet.');
            }
            final types = allMetrics.map((m) => m.metricType).toSet();
            final primaryType = types.contains('Weight') ? 'Weight' : types.first;
            final history = allMetrics.where((m) => m.metricType == primaryType).toList()
              ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
            final points = history.map((HealthMetric m) => m.value).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(primaryType, style: Theme.of(context).textTheme.bodySmall),
                AppLineChart(points: points),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Text('Sleep & Food', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        healthSummary.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncErrorView(
            error: error,
            isCompact: true,
            onRetry: () => ref.invalidate(healthSummaryProvider),
          ),
          data: (summary) {
            final sleepMinutes = summary['sleepAverageDurationMinutesLast7Days'] as double?;
            final sleepFeeling = summary['sleepAverageFeelingOnWakeup'] as double?;
            final foodCalories = (summary['foodTodayCalories'] as num?)?.toDouble() ?? 0;
            final foodProtein = (summary['foodTodayProteinGrams'] as num?)?.toDouble() ?? 0;
            final foodFat = (summary['foodTodayFatGrams'] as num?)?.toDouble() ?? 0;
            final foodCarb = (summary['foodTodayCarbGrams'] as num?)?.toDouble() ?? 0;

            return Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sleep', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          sleepMinutes == null
                              ? 'No sleep logged in the last 7 days.'
                              : 'Avg last 7 days: ${(sleepMinutes / 60).toStringAsFixed(1)}h'
                                  '${sleepFeeling != null ? ' • wakeup feeling ${sleepFeeling.toStringAsFixed(1)}/5' : ''}',
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () =>
                                  Navigator.of(context).pushNamed(SleepLogFormScreen.routeName),
                              icon: const Icon(Icons.add),
                              label: const Text('Log Sleep'),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pushNamed(SleepHomeScreen.routeName),
                              child: const Text('View Sleep'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Food', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          'Today: ${foodCalories.toStringAsFixed(0)} kcal • '
                          'P ${foodProtein.toStringAsFixed(0)}g • '
                          'F ${foodFat.toStringAsFixed(0)}g • '
                          'C ${foodCarb.toStringAsFixed(0)}g',
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () =>
                                  Navigator.of(context).pushNamed(FoodLogFormScreen.routeName),
                              icon: const Icon(Icons.add),
                              label: const Text('Log Food'),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pushNamed(FoodHomeScreen.routeName),
                              child: const Text('View Food'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Text('Upcoming', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        bloodTestStats.when(
          loading: () => const SizedBox.shrink(),
          error: (error, _) => AsyncErrorView(
            error: error,
            isCompact: true,
            onRetry: () => ref.invalidate(bloodTestStatisticsProvider),
          ),
          data: (stats) {
            final nextTest = stats['nextTestDate'] as String?;
            final nextTestDate = nextTest != null ? DateTime.tryParse(nextTest) : null;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.science_outlined),
                title: Text(nextTestDate != null ? 'Next blood test: ${_formatDate(nextTestDate)}' : 'No upcoming blood test'),
                subtitle: Text('${stats['scheduledCount'] ?? 0} scheduled, ${stats['completedCount'] ?? 0} completed'),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        doctorVisitStats.when(
          loading: () => const SizedBox.shrink(),
          error: (error, _) => AsyncErrorView(
            error: error,
            isCompact: true,
            onRetry: () => ref.invalidate(doctorVisitStatisticsProvider),
          ),
          data: (stats) {
            final nextVisit = stats['nextVisitDate'] as String?;
            final nextVisitDate = nextVisit != null ? DateTime.tryParse(nextVisit) : null;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.medical_services_outlined),
                title: Text(nextVisitDate != null ? 'Next visit: ${_formatDate(nextVisitDate)}' : 'No upcoming doctor visit'),
                subtitle: Text('${stats['totalVisits'] ?? 0} visit(s) logged'),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text('Recent Activity', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        activityFeed.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncErrorView(
            error: error,
            isCompact: true,
            onRetry: () => ref.invalidate(healthActivityFeedProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const Text('No recent activity yet.');
            }
            return Column(
              children: items
                  .map((item) => Card(
                        child: ListTile(
                          leading: Icon(item.icon),
                          title: Text(item.title),
                          subtitle: Text('${item.subtitle} • ${_formatDate(item.date)}'),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );

    if (embedded) {
      return body;
    }
    return Scaffold(appBar: AppBar(title: const Text('Health Home')), body: body);
  }
}

class _ExportReportButton extends ConsumerStatefulWidget {
  const _ExportReportButton();

  @override
  ConsumerState<_ExportReportButton> createState() => _ExportReportButtonState();
}

class _ExportReportButtonState extends ConsumerState<_ExportReportButton> {
  bool _isExporting = false;

  Future<void> _export() async {
    setState(() => _isExporting = true);
    final result = await ref.read(healthReportServiceProvider).shareReport();
    if (!mounted) {
      return;
    }
    if (result.isFailure) {
      AppFeedback.showError(context, result.error!);
    }
    setState(() => _isExporting = false);
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _isExporting ? null : _export,
      icon: _isExporting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.picture_as_pdf_outlined),
      label: const Text('Export'),
    );
  }
}
