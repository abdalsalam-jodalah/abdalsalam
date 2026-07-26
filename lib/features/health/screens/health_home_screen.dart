import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/health/health_metric.dart';
import '../../../shared/widgets/chart_widgets.dart';
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
          error: (error, _) => Text('Failed to load schedule: $error'),
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
              error: (error, _) => Text('Failed to load stats: $error'),
              data: (stats) {
                final adherence = double.tryParse('${stats['adherenceRate'] ?? 0}') ?? 0;
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
          error: (error, _) => Text('Failed to load metrics: $error'),
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
                TrendLineChart(points: points),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Text('Upcoming', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        bloodTestStats.when(
          loading: () => const SizedBox.shrink(),
          error: (error, _) => Text('Failed to load blood test stats: $error'),
          data: (stats) {
            final nextTest = stats['nextTestDate'] as String?;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.science_outlined),
                title: Text(nextTest != null ? 'Next blood test: ${_formatDate(DateTime.parse(nextTest))}' : 'No upcoming blood test'),
                subtitle: Text('${stats['scheduledCount'] ?? 0} scheduled, ${stats['completedCount'] ?? 0} completed'),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        doctorVisitStats.when(
          loading: () => const SizedBox.shrink(),
          error: (error, _) => Text('Failed to load doctor visit stats: $error'),
          data: (stats) {
            final nextVisit = stats['nextVisitDate'] as String?;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.medical_services_outlined),
                title: Text(nextVisit != null ? 'Next visit: ${_formatDate(DateTime.parse(nextVisit))}' : 'No upcoming doctor visit'),
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
          error: (error, _) => Text('Failed to load activity: $error'),
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
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(healthReportServiceProvider).shareReport();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to generate report: $error'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
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
