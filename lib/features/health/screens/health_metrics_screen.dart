import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/health/health_metric.dart';
import '../providers/health_providers.dart';
import 'health_metric_form_screen.dart';

class HealthMetricsScreen extends ConsumerStatefulWidget {
  static const routeName = '/health/metrics';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [HealthScreen] shell.
  final bool embedded;

  const HealthMetricsScreen({super.key, this.embedded = false});

  @override
  ConsumerState<HealthMetricsScreen> createState() => _HealthMetricsScreenState();
}

class _HealthMetricsScreenState extends ConsumerState<HealthMetricsScreen> {
  Future<void> _delete(HealthMetric metric) async {
    final service = ref.read(healthMetricServiceProvider);
    await service.softDelete(metric.id);
    ref.invalidate(healthMetricsProvider);
    ref.invalidate(healthMetricStatisticsProvider);
  }

  Future<void> _openForm({HealthMetric? metric}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => HealthMetricFormScreen(metric: metric)),
    );
    if (saved == true) {
      ref.invalidate(healthMetricsProvider);
      ref.invalidate(healthMetricStatisticsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(healthMetricsProvider);
    final statsAsync = ref.watch(healthMetricStatisticsProvider);

    final content = metricsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Failed to load metrics: $error')),
      data: (metrics) {
        if (metrics.isEmpty) {
          return const Center(child: Text('No metrics logged yet. Tap + to add one.'));
        }

        final latestByType = statsAsync.value?['latestByType'] as Map<String, HealthMetric>? ?? const {};

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.embedded)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Metrics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            if (latestByType.isNotEmpty) ...[
              Text('Latest', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: latestByType.entries
                    .map((entry) => Chip(
                          label: Text('${entry.key}: ${entry.value.value} ${entry.value.unit}'),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
            Text('History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...metrics.map((metric) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.monitor_heart_outlined),
                    title: Text('${metric.metricType}: ${metric.value} ${metric.unit}'),
                    subtitle: Text(
                      '${metric.measuredAt.year}-${metric.measuredAt.month.toString().padLeft(2, '0')}-${metric.measuredAt.day.toString().padLeft(2, '0')}'
                      '${metric.notes != null ? '\n${metric.notes}' : ''}',
                    ),
                    isThreeLine: metric.notes != null,
                    onTap: () => _openForm(metric: metric),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(metric),
                    ),
                  ),
                )),
          ],
        );
      },
    );
    final fab = FloatingActionButton(
      onPressed: () => _openForm(),
      child: const Icon(Icons.add),
    );

    if (widget.embedded) {
      return Stack(
        children: [
          content,
          Positioned(right: 16, bottom: 16, child: fab),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Health Metrics')),
      floatingActionButton: fab,
      body: content,
    );
  }
}
