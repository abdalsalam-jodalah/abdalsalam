import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/planning/task_category.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../providers/planning_board_provider.dart';
import '../providers/planning_providers.dart';
import '../widgets/task_category_badge.dart';
import '../widgets/task_category_dialog.dart';

const _uuid = Uuid();

class TaskCategoriesScreen extends ConsumerWidget {
  static const routeName = '/planning/task-categories';
  static const String _emptyTitle = 'No categories yet';
  static const String _emptySubtitle = 'Create labels like Work or Health to group your tasks.';
  static const String _newCategoryLabel = 'New category';

  const TaskCategoriesScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref, List<TaskCategory> existing) async {
    final draft = await showTaskCategoryDialog(context, takenNames: _namesTaken(existing));
    if (draft == null) return;
    final now = DateTime.now();
    final result = await ref
        .read(taskCategoryServiceProvider)
        .create(
          TaskCategory(
            id: _uuid.v4(),
            createdAt: now,
            updatedAt: now,
            userId: planningUserId,
            name: draft.name,
            color: draft.color,
          ),
        );
    if (!context.mounted) return;
    if (result.isFailure) {
      AppFeedback.showError(context, result.error!);
      return;
    }
    ref.invalidate(taskCategoriesProvider);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, TaskCategory category, List<TaskCategory> all) async {
    final others = all.where((item) => item.id != category.id).toList(growable: false);
    final draft = await showTaskCategoryDialog(context, existing: category, takenNames: _namesTaken(others));
    if (draft == null) return;
    final result = await ref
        .read(taskCategoryServiceProvider)
        .update(category.copyWith(name: draft.name, color: draft.color, updatedAt: DateTime.now()));
    if (!context.mounted) return;
    if (result.isFailure) {
      AppFeedback.showError(context, result.error!);
      return;
    }
    ref.invalidate(taskCategoriesProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, TaskCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete "${category.name}"?'),
        content: const Text('Tasks in this category keep existing but lose the label.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await ref.read(taskCategoryServiceProvider).deleteAndDetach(category.id);
    ref.invalidate(taskCategoriesProvider);
    ref.invalidate(planningBoardProvider);
    if (!context.mounted) return;
    if (result.isFailure) {
      AppFeedback.showError(context, result.error!);
    }
  }

  Set<String> _namesTaken(List<TaskCategory> categories) {
    return categories.map((category) => category.name.trim().toLowerCase()).toSet();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = AppThemeTokens.of(context).spacing;
    final categoriesAsync = ref.watch(taskCategoriesProvider);
    final categories = categoriesAsync.value ?? const <TaskCategory>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Task categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref, categories),
        icon: const Icon(Icons.add),
        label: const Text(_newCategoryLabel),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => AsyncErrorView(error: error, onRetry: () => ref.invalidate(taskCategoriesProvider)),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              title: _emptyTitle,
              subtitle: _emptySubtitle,
              icon: Icons.label_outline,
              actionLabel: _newCategoryLabel,
              onAction: () => _create(context, ref, items),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(spacing.lg, spacing.lg, spacing.lg, spacing.xxl * 2),
            itemCount: items.length,
            separatorBuilder: (context, index) => SizedBox(height: spacing.sm),
            itemBuilder: (context, index) {
              final category = items[index];
              return AppCard(
                key: ValueKey('category-row-${category.id}'),
                padding: EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(alignment: Alignment.centerLeft, child: TaskCategoryBadge(category: category)),
                    ),
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _edit(context, ref, category, items),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(context, ref, category),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
