import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/health/health_metric.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../../../shared/widgets/ui/page_header.dart';
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
    final result = await service.softDelete(metric.id);
    if (!mounted) return;
    if (result.isFailure) {
      AppFeedback.showError(context, result.error!);
      return;
    }
    ref.invalidate(healthMetricsProvider);
    ref.invalidate(healthMetricStatisticsProvider);
  }

  Future<void> _openForm({HealthMetric? metric}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => HealthMetricFormScreen(metric: metric)),
    );
    if (!mounted) return;
    if (saved == true) {
      ref.invalidate(healthMetricsProvider);
      ref.invalidate(healthMetricStatisticsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final accent = AppModuleAccents.forModule('health');
    final metricsAsync = ref.watch(healthMetricsProvider);
    final statsAsync = ref.watch(healthMetricStatisticsProvider);

    final content = metricsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AsyncErrorView(
        error: error,
        onRetry: () => ref.invalidate(healthMetricsProvider),
      ),
      data: (metrics) {
        if (metrics.isEmpty) {
          return const Center(child: Text('No metrics logged yet. Tap + to add one.'));
        }

        final latestByType = statsAsync.value?['latestByType'] as Map<String, HealthMetric>? ?? const {};

        return ListView(
          children: [
            if (widget.embedded) const PageHeader(title: 'Metrics'),
            Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.spacing.lg,
                widget.embedded ? 0 : tokens.spacing.lg,
                tokens.spacing.lg,
                tokens.spacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (latestByType.isNotEmpty) ...[
                    const AppSectionHeader(title: 'Latest', padding: EdgeInsets.zero),
                    Wrap(
                      spacing: tokens.spacing.sm,
                      runSpacing: tokens.spacing.sm,
                      children: [
                        for (final entry in latestByType.entries)
                          Chip(label: Text('${entry.key}: ${entry.value.value} ${entry.value.unit}')),
                      ],
                    ),
                    SizedBox(height: tokens.spacing.lg),
                  ],
                  const AppSectionHeader(title: 'History', padding: EdgeInsets.zero),
                  SizedBox(height: tokens.spacing.sm),
                  for (final metric in metrics) ...[
                    EntityTile(
                      icon: Icons.monitor_heart_outlined,
                      accentColor: accent,
                      title: '${metric.metricType}: ${metric.value} ${metric.unit}',
                      subtitle: '${AppDateFormatter.date(metric.measuredAt)}'
                          '${metric.notes != null ? '\n${metric.notes}' : ''}',
                      subtitleMaxLines: 2,
                      onTap: () => _openForm(metric: metric),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(metric),
                      ),
                    ),
                    SizedBox(height: tokens.spacing.sm),
                  ],
                ],
              ),
            ),
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
          Positioned(right: tokens.spacing.lg, bottom: tokens.spacing.lg, child: fab),
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
