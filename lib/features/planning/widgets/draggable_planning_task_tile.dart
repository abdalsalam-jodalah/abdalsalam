import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/planning/planning_task.dart';
import '../providers/planning_providers.dart';
import 'planning_drag_controller.dart';
import 'planning_task_actions.dart';
import 'task_category_badge.dart';

enum _TaskMenuAction { edit, delete }

class DraggablePlanningTaskTile extends StatelessWidget {
  static const Duration _dragDelay = Duration(milliseconds: 250);
  static const double _insertionLineHeight = 3;
  static const double _draggedOpacity = 0.35;
  static const double _feedbackElevation = 8;
  static const double _completedOpacity = 0.6;

  final PlanningTask task;
  final int index;
  final DateTime? date;
  final PlanningDragController dragController;
  final PlanningTaskActions actions;

  const DraggablePlanningTaskTile({
    super.key,
    required this.task,
    required this.index,
    required this.date,
    required this.dragController,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = AppThemeTokens.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final body = _TaskTileBody(task: task, actions: actions);
        return DragTarget<PlanningTask>(
          onWillAcceptWithDetails: (details) => details.data.id != task.id,
          onAcceptWithDetails: (details) => actions.onDrop(details.data, date, index),
          builder: (context, candidates, _) => Stack(
            children: [
              LongPressDraggable<PlanningTask>(
                data: task,
                delay: _dragDelay,
                onDragStarted: () => dragController.start(task),
                onDragEnd: (_) => dragController.end(),
                feedback: Material(
                  elevation: _feedbackElevation,
                  borderRadius: tokens.radius.mediumBorder,
                  color: colorScheme.surfaceContainerHigh,
                  child: SizedBox(width: constraints.maxWidth, child: body),
                ),
                childWhenDragging: Opacity(opacity: _draggedOpacity, child: body),
                child: Opacity(opacity: task.isCompleted ? _completedOpacity : 1, child: body),
              ),
              if (candidates.isNotEmpty)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: _insertionLineHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: colorScheme.primary, borderRadius: tokens.radius.pillBorder),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TaskTileBody extends ConsumerWidget {
  final PlanningTask task;
  final PlanningTaskActions actions;

  const _TaskTileBody({required this.task, required this.actions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = AppThemeTokens.of(context);
    final description = task.description;
    final lookup = ref.watch(taskCategoryLookupProvider);
    final categories = [
      for (final id in task.categoryIds)
        if (lookup[id] != null) lookup[id]!,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sm, vertical: tokens.spacing.xs / 2),
      child: Material(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: tokens.radius.mediumBorder),
        clipBehavior: Clip.antiAlias,
        child: CheckboxListTile(
          key: ValueKey('checkbox-${task.id}'),
          value: task.isCompleted,
          onChanged: (value) => actions.onToggle(task, value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding: EdgeInsets.only(left: tokens.spacing.xs, right: 0),
          title: Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: task.isCompleted ? textTheme.bodyLarge?.copyWith(decoration: TextDecoration.lineThrough) : null,
          ),
          subtitle: (description != null && description.isNotEmpty) || categories.isNotEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (description != null && description.isNotEmpty)
                      Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (categories.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: tokens.spacing.xs),
                        child: Wrap(
                          spacing: tokens.spacing.xs,
                          runSpacing: tokens.spacing.xs,
                          children: [
                            for (final category in categories)
                              TaskCategoryBadge(key: ValueKey('task-badge-${task.id}-${category.id}'), category: category),
                          ],
                        ),
                      ),
                  ],
                )
              : null,
          secondary: PopupMenuButton<_TaskMenuAction>(
            icon: const Icon(Icons.more_vert),
            iconSize: 20,
            onSelected: (action) {
              switch (action) {
                case _TaskMenuAction.edit:
                  actions.onEdit(task);
                case _TaskMenuAction.delete:
                  actions.onDelete(task);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: _TaskMenuAction.edit, child: Text('Edit')),
              PopupMenuItem(value: _TaskMenuAction.delete, child: Text('Delete')),
            ],
          ),
        ),
      ),
    );
  }
}
