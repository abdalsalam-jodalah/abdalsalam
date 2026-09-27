import 'package:flutter/material.dart';

import '../../../data/models/planning/planning_task.dart';
import '../../../shared/widgets/empty_state.dart';

enum _TaskMenuAction { edit, delete }

class ReorderableTaskList extends StatelessWidget {
  final List<PlanningTask> tasks;
  final void Function(PlanningTask task, bool completed) onToggle;
  final void Function(PlanningTask task) onEdit;
  final void Function(PlanningTask task) onDelete;
  final void Function(List<PlanningTask> reordered) onReorder;
  final Widget Function(PlanningTask task)? trailingExtra;

  const ReorderableTaskList({
    super.key,
    required this.tasks,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onReorder,
    this.trailingExtra,
  });

  void _handleReorder(int oldIndex, int newIndex) {
    final reordered = [...tasks];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    onReorder(reordered);
  }

  static const String _emptyTitle = 'No tasks yet';
  static const String _emptySubtitle = 'Tap + to add one.';

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const EmptyState(
        title: _emptyTitle,
        subtitle: _emptySubtitle,
        icon: Icons.checklist_rounded,
        isCompact: true,
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: tasks.length,
      onReorderItem: _handleReorder,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ReorderableDelayedDragStartListener(
          key: ValueKey(task.id),
          index: index,
          child: CheckboxListTile(
            key: ValueKey('checkbox-${task.id}'),
            value: task.isCompleted,
            onChanged: (value) => onToggle(task, value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: task.isCompleted
                  ? Theme.of(context).textTheme.bodyLarge?.copyWith(decoration: TextDecoration.lineThrough)
                  : null,
            ),
            subtitle: task.description != null && task.description!.isNotEmpty
                ? Text(task.description!, maxLines: 2, overflow: TextOverflow.ellipsis)
                : null,
            secondary: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailingExtra != null) trailingExtra!(task),
                PopupMenuButton<_TaskMenuAction>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) {
                    switch (action) {
                      case _TaskMenuAction.edit:
                        onEdit(task);
                      case _TaskMenuAction.delete:
                        onDelete(task);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: _TaskMenuAction.edit, child: Text('Edit')),
                    PopupMenuItem(value: _TaskMenuAction.delete, child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
