import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/religious/athkar_content.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/charts/app_bar_chart.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../providers/athkar_providers.dart';

class AthkarHistoryScreen extends ConsumerWidget {
  const AthkarHistoryScreen({super.key});

  static const String routeName = '/religious/athkar/history';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Athkar History')),
      body: const AthkarHistoryView(),
    );
  }
}

/// Chart + full completion log, reusable both as a standalone screen
/// ([AthkarHistoryScreen]) and embedded as a tab inside [AthkarScreen].
class AthkarHistoryView extends ConsumerWidget {
  const AthkarHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final logsState = ref.watch(athkarLogsControllerProvider);
    final weeklyByCategory = ref.watch(athkarWeeklyCompletionsByCategoryProvider);

    return logsState.when(
      data: (logs) {
        final sorted = [...logs]..sort((a, b) => b.completedAt.compareTo(a.completedAt));

        return ListView(
          padding: EdgeInsets.all(tokens.spacing.lg),
          children: [
            AppSectionHeader(title: 'Completions this week (by category)'),
            AppCard(
              child: Column(
                children: [
                  AppBarChart(values: weeklyByCategory),
                  SizedBox(height: tokens.spacing.sm),
                  Wrap(
                    spacing: tokens.spacing.md,
                    children: [
                      for (final category in AthkarCategory.values)
                        Text(athkarCategoryLabel(category), style: theme.textTheme.labelSmall),
                    ],
                  ),
                ],
              ),
            ),
            AppSectionHeader(title: 'All Completions'),
            if (sorted.isEmpty)
              const EmptyState(
                title: 'No athkar completed yet',
                subtitle: 'Complete an athkar to see your history here.',
              ),
            for (final log in sorted)
              Padding(
                padding: EdgeInsets.only(bottom: tokens.spacing.sm),
                child: EntityTile(
                  icon: Icons.favorite_outline,
                  accentColor: theme.colorScheme.tertiary,
                  title: athkarCategoryLabel(log.category),
                  subtitle: '${log.countDone}/${log.targetCount} • ${AppDateFormatter.dateTime(log.completedAt)}'
                      '${log.notes != null && log.notes!.isNotEmpty ? '\n${log.notes}' : ''}',
                  subtitleMaxLines: 3,
                  trailing: Icon(
                    log.countDone >= log.targetCount ? Icons.check_circle : Icons.timelapse,
                    color: log.countDone >= log.targetCount ? theme.colorScheme.primary : theme.colorScheme.tertiary,
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => AsyncErrorView(
        error: err,
        onRetry: () => ref.invalidate(athkarLogsControllerProvider),
      ),
    );
  }
}

String athkarCategoryLabel(AthkarCategory category) {
  return switch (category) {
    AthkarCategory.morning => 'Morning',
    AthkarCategory.evening => 'Evening',
    AthkarCategory.afterPrayer => 'After Prayer',
    AthkarCategory.sleep => 'Sleep',
    AthkarCategory.wakingUp => 'Waking Up',
    AthkarCategory.custom => 'Custom',
  };
}
