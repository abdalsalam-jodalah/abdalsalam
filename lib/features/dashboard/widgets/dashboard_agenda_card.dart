import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/dashboard_card_catalog.dart';
import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/planning/planning_task.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/async_section.dart';
import '../../../shared/widgets/ui/icon_badge.dart';
import '../../../shared/widgets/ui/progress_ring.dart';
import '../../planning/providers/planning_board_provider.dart';
import '../../planning/providers/planning_providers.dart';
import '../../planning/services/day_planning_range.dart';
import '../../planning/services/planning_task_arranger.dart';
import '../../planning/widgets/task_category_badge.dart';

class DashboardAgendaCard extends ConsumerWidget {
  static const int _maxVisibleTasks = 6;
  static const double _ringSize = 48;
  static const String _emptyTitle = 'Nothing planned for today';
  static const String _emptySubtitle = 'Add tasks in Day Planning to see them here';

  const DashboardAgendaCard({super.key});

  void _toggle(BuildContext context, WidgetRef ref, PlanningTask task, bool completed) {
    unawaited(
      ref.read(planningBoardProvider.notifier).toggleTask(task, isCompleted: completed).then((error) {
        if (error != null && context.mounted) AppFeedback.showError(context, error);
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DayPlanningRange.dateOnly(DateTime.now());
    return AsyncSection<List<PlanningTask>>(
      value: ref.watch(planningBoardProvider),
      onRetry: () => ref.invalidate(planningBoardProvider),
      builder: (allTasks) {
        final tasks = PlanningTaskArranger.tasksOn(allTasks, today);
        return AppCard(child: _content(context, ref, tasks));
      },
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, List<PlanningTask> tasks) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final accent = AppModuleAccents.forModule('day-planning');
    final doneCount = tasks.where((task) => task.isCompleted).length;
    final categories = ref.watch(taskCategoryLookupProvider);
    final visible = tasks.take(_maxVisibleTasks).toList(growable: false);
    final hiddenCount = tasks.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconBadge(icon: Icons.checklist_rounded, color: accent),
            SizedBox(width: tokens.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DashboardCardCatalog.labels[DashboardCardCatalog.agenda]!, style: theme.textTheme.titleMedium),
                  Text(
                    tasks.isEmpty ? 'No tasks yet' : '$doneCount of ${tasks.length} done',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (tasks.isNotEmpty)
              ProgressRing(
                value: doneCount / tasks.length,
                size: _ringSize,
                color: accent,
                center: Text('${(doneCount / tasks.length * 100).round()}%', style: theme.textTheme.labelSmall),
              ),
          ],
        ),
        if (tasks.isEmpty)
          const EmptyState(title: _emptyTitle, subtitle: _emptySubtitle, icon: Icons.event_available_rounded, isCompact: true)
        else ...[
          SizedBox(height: tokens.spacing.sm),
          for (final task in visible)
            CheckboxListTile(
              key: ValueKey('agenda-task-${task.id}'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              value: task.isCompleted,
              onChanged: (value) => _toggle(context, ref, task, value ?? false),
              title: Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: task.isCompleted ? TextStyle(decoration: TextDecoration.lineThrough, color: theme.colorScheme.onSurfaceVariant) : null,
              ),
              subtitle: task.categoryIds.any(categories.containsKey)
                  ? Padding(
                      padding: EdgeInsets.only(top: tokens.spacing.xs),
                      child: Wrap(
                        spacing: tokens.spacing.xs,
                        runSpacing: tokens.spacing.xs,
                        children: [
                          for (final id in task.categoryIds)
                            if (categories[id] != null) TaskCategoryBadge(category: categories[id]!),
                        ],
                      ),
                    )
                  : null,
            ),
          if (hiddenCount > 0)
            Padding(
              padding: EdgeInsets.only(top: tokens.spacing.xs),
              child: Text(
                '+$hiddenCount more in Day Planning',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ],
    );
  }
}
