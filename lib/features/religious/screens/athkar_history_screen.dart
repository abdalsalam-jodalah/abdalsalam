import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/religious/athkar_content.dart';
import '../../../shared/widgets/chart_widgets.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
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
    final logsState = ref.watch(athkarLogsControllerProvider);
    final weeklyByCategory = ref.watch(athkarWeeklyCompletionsByCategoryProvider);

    return logsState.when(
      data: (logs) {
        final sorted = [...logs]..sort((a, b) => b.completedAt.compareTo(a.completedAt));

        final scheme = Theme.of(context).colorScheme;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionHeader(title: 'Completions this week (by category)'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ComparisonBarChart(values: weeklyByCategory),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      children: [
                        for (final category in AthkarCategory.values)
                          Text(athkarCategoryLabel(category),
                              style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'All Completions'),
            const SizedBox(height: 8),
            if (sorted.isEmpty)
              const EmptyState(
                title: 'No athkar completed yet',
                subtitle: 'Complete an athkar to see your history here.',
              ),
            ...sorted.map(
              (log) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.tertiary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.favorite_outline, color: scheme.tertiary, size: 20),
                  ),
                  title: Text(athkarCategoryLabel(log.category)),
                  subtitle: Text(
                    '${log.countDone}/${log.targetCount} • '
                    '${DateFormat('MMM d, hh:mm a').format(log.completedAt)}'
                    '${log.notes != null && log.notes!.isNotEmpty ? '\n${log.notes}' : ''}',
                  ),
                  isThreeLine: log.notes != null && log.notes!.isNotEmpty,
                  trailing: Icon(
                    log.countDone >= log.targetCount ? Icons.check_circle : Icons.timelapse,
                    color: log.countDone >= log.targetCount ? scheme.primary : scheme.tertiary,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
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
