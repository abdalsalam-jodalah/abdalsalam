import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/charts/app_line_chart.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/async_section.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../../../shared/widgets/ui/page_header.dart';
import '../../../shared/widgets/ui/progress_bar.dart';
import '../../food/screens/food_home_screen.dart';
import '../../food/screens/food_log_form_screen.dart';
import '../../sleep/screens/sleep_home_screen.dart';
import '../../sleep/screens/sleep_log_form_screen.dart';
import '../providers/health_providers.dart';
import 'medication_form_screen.dart';

class HealthHomeScreen extends ConsumerWidget {
  static const routeName = '/health/home';
  static const String _pageTitle = 'Health Home';
  static const String _dashboardTitle = 'Dashboard';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [HealthScreen] shell.
  final bool embedded;

  const HealthHomeScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppThemeTokens.of(context);
    final accent = AppModuleAccents.forModule('health');
    final medicationStats = ref.watch(medicationStatisticsProvider);
    final checklist = ref.watch(todayMedicationChecklistProvider);
    final metrics = ref.watch(healthMetricsProvider);
    final bloodTestStats = ref.watch(bloodTestStatisticsProvider);
    final doctorVisitStats = ref.watch(doctorVisitStatisticsProvider);
    final activityFeed = ref.watch(healthActivityFeedProvider);
    final healthSummary = ref.watch(healthSummaryProvider);

    final sections = [
      Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(MedicationFormScreen.routeName),
              icon: const Icon(Icons.add),
              label: const Text('Add Medication'),
            ),
          ),
          SizedBox(width: tokens.spacing.sm),
          const _ExportReportButton(),
        ],
      ),
      AsyncSection(
        title: "Today's Schedule",
        value: checklist,
        onRetry: () => ref.invalidate(todayMedicationChecklistProvider),
        builder: (items) {
          if (items.isEmpty) {
            return const Text('No medications scheduled today.');
          }
          return Column(
            children: [
              for (final item in items) ...[
                EntityTile(
                  icon: item.isChecked ? Icons.check_circle_rounded : Icons.medication_outlined,
                  accentColor: item.isChecked ? tokens.colors.success : accent,
                  title: item.medicationName,
                  subtitle: '${item.displayTime} • ${item.dosage}',
                ),
                SizedBox(height: tokens.spacing.sm),
              ],
            ],
          );
        },
      ),
      AsyncSection(
        title: 'Adherence',
        value: medicationStats,
        onRetry: () => ref.invalidate(medicationStatisticsProvider),
        builder: (stats) {
          final adherenceRate = stats['adherenceRate'];
          final adherence = adherenceRate is num ? adherenceRate.toDouble() : 0.0;
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Adherence: ${adherence.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.titleSmall),
                SizedBox(height: tokens.spacing.sm),
                ProgressBar(value: adherence / 100, color: accent),
              ],
            ),
          );
        },
      ),
      AsyncSection(
        title: 'Metrics Trend',
        value: metrics,
        onRetry: () => ref.invalidate(healthMetricsProvider),
        builder: (allMetrics) {
          if (allMetrics.isEmpty) {
            return const Text('No metrics logged yet.');
          }
          final types = allMetrics.map((metric) => metric.metricType).toSet();
          final primaryType = types.contains('Weight') ? 'Weight' : types.first;
          final history = allMetrics.where((metric) => metric.metricType == primaryType).toList()
            ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
          final points = history.map((metric) => metric.value).toList();

          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(primaryType, style: Theme.of(context).textTheme.bodySmall),
                SizedBox(height: tokens.spacing.sm),
                AppLineChart(points: points, color: accent),
              ],
            ),
          );
        },
      ),
      AsyncSection(
        title: 'Sleep & Food',
        value: healthSummary,
        onRetry: () => ref.invalidate(healthSummaryProvider),
        builder: (summary) => _SleepAndFoodSummary(summary: summary),
      ),
      AsyncSection(
        title: 'Upcoming',
        value: bloodTestStats,
        onRetry: () => ref.invalidate(bloodTestStatisticsProvider),
        builder: (stats) {
          final nextTest = stats['nextTestDate'] as String?;
          final nextTestDate = nextTest != null ? DateTime.tryParse(nextTest) : null;
          return EntityTile(
            icon: Icons.science_outlined,
            accentColor: accent,
            title: nextTestDate != null
                ? 'Next blood test: ${AppDateFormatter.shortDate(nextTestDate)}'
                : 'No upcoming blood test',
            subtitle: '${stats['scheduledCount'] ?? 0} scheduled, ${stats['completedCount'] ?? 0} completed',
          );
        },
      ),
      AsyncSection(
        value: doctorVisitStats,
        onRetry: () => ref.invalidate(doctorVisitStatisticsProvider),
        builder: (stats) {
          final nextVisit = stats['nextVisitDate'] as String?;
          final nextVisitDate = nextVisit != null ? DateTime.tryParse(nextVisit) : null;
          return EntityTile(
            icon: Icons.medical_services_outlined,
            accentColor: accent,
            title: nextVisitDate != null
                ? 'Next visit: ${AppDateFormatter.shortDate(nextVisitDate)}'
                : 'No upcoming doctor visit',
            subtitle: '${stats['totalVisits'] ?? 0} visit(s) logged',
          );
        },
      ),
      AsyncSection(
        title: 'Recent Activity',
        value: activityFeed,
        onRetry: () => ref.invalidate(healthActivityFeedProvider),
        builder: (items) {
          if (items.isEmpty) {
            return const Text('No recent activity yet.');
          }
          return Column(
            children: [
              for (final item in items) ...[
                EntityTile(
                  icon: item.icon,
                  accentColor: accent,
                  title: item.title,
                  subtitle: '${item.subtitle} • ${AppDateFormatter.shortDate(item.date)}',
                ),
                SizedBox(height: tokens.spacing.sm),
              ],
            ],
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

class _SleepAndFoodSummary extends StatelessWidget {
  final Map<String, dynamic> summary;

  const _SleepAndFoodSummary({required this.summary});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final sleepMinutes = summary['sleepAverageDurationMinutesLast7Days'] as double?;
    final sleepFeeling = summary['sleepAverageFeelingOnWakeup'] as double?;
    final foodCalories = (summary['foodTodayCalories'] as num?)?.toDouble() ?? 0;
    final foodProtein = (summary['foodTodayProteinGrams'] as num?)?.toDouble() ?? 0;
    final foodFat = (summary['foodTodayFatGrams'] as num?)?.toDouble() ?? 0;
    final foodCarb = (summary['foodTodayCarbGrams'] as num?)?.toDouble() ?? 0;

    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sleep', style: theme.textTheme.titleSmall),
              SizedBox(height: tokens.spacing.xs),
              Text(
                sleepMinutes == null
                    ? 'No sleep logged in the last 7 days.'
                    : 'Avg last 7 days: ${(sleepMinutes / 60).toStringAsFixed(1)}h'
                        '${sleepFeeling != null ? ' • wakeup feeling ${sleepFeeling.toStringAsFixed(1)}/5' : ''}',
              ),
              SizedBox(height: tokens.spacing.sm),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed(SleepLogFormScreen.routeName),
                    icon: const Icon(Icons.add),
                    label: const Text('Log Sleep'),
                  ),
                  SizedBox(width: tokens.spacing.sm),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(SleepHomeScreen.routeName),
                    child: const Text('View Sleep'),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Food', style: theme.textTheme.titleSmall),
              SizedBox(height: tokens.spacing.xs),
              Text(
                'Today: ${foodCalories.toStringAsFixed(0)} kcal • '
                'P ${foodProtein.toStringAsFixed(0)}g • '
                'F ${foodFat.toStringAsFixed(0)}g • '
                'C ${foodCarb.toStringAsFixed(0)}g',
              ),
              SizedBox(height: tokens.spacing.sm),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed(FoodLogFormScreen.routeName),
                    icon: const Icon(Icons.add),
                    label: const Text('Log Food'),
                  ),
                  SizedBox(width: tokens.spacing.sm),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(FoodHomeScreen.routeName),
                    child: const Text('View Food'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExportReportButton extends ConsumerStatefulWidget {
  const _ExportReportButton();

  @override
  ConsumerState<_ExportReportButton> createState() => _ExportReportButtonState();
}

class _ExportReportButtonState extends ConsumerState<_ExportReportButton> {
  static const double _spinnerSize = 16;
  static const double _spinnerStrokeWidth = 2;

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
              width: _spinnerSize,
              height: _spinnerSize,
              child: CircularProgressIndicator(strokeWidth: _spinnerStrokeWidth),
            )
          : const Icon(Icons.picture_as_pdf_outlined),
      label: const Text('Export'),
    );
  }
}
