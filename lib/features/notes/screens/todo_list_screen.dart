import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/notes/todo.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../habits/screens/habit_detail_screen.dart';
import '../providers/notes_providers.dart';
import '../widgets/notes_widgets.dart';
import '../widgets/todo_dialog.dart';

enum _TodoMenuAction { edit, delete, unlinkHabit }

class TodoListScreen extends ConsumerWidget {
  static const routeName = '/notes/todos';

  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(activeTodosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTodo(context, ref),
        child: const Icon(Icons.add),
      ),
      body: todosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => AsyncErrorView(
          error: error,
          onRetry: () => ref.invalidate(activeTodosProvider),
        ),
        data: (todos) {
          if (todos.isEmpty) {
            return const Center(child: Text('No todos yet. Tap + to add one.'));
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            buildDefaultDragHandles: false,
            itemCount: todos.length,
            onReorderItem: (oldIndex, newIndex) => _reorder(context, ref, todos, oldIndex, newIndex),
            itemBuilder: (context, index) {
              final todo = todos[index];
              return ReorderableDelayedDragStartListener(
                key: ValueKey(todo.id),
                index: index,
                child: TodoItem(
                  title: todo.title,
                  completed: todo.status == TodoStatus.done,
                  onChanged: (value) => _toggleTodo(context, ref, todo, value ?? false),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (todo.habitId != null)
                        IconButton(
                          icon: const Icon(Icons.link),
                          tooltip: 'Open linked habit',
                          onPressed: () => Navigator.of(context).pushNamed(
                            HabitDetailScreen.routeName,
                            arguments: todo.habitId,
                          ),
                        ),
                      PopupMenuButton<_TodoMenuAction>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (action) async {
                          switch (action) {
                            case _TodoMenuAction.edit:
                              await _editTodo(context, ref, todo);
                            case _TodoMenuAction.delete:
                              await _deleteTodo(context, ref, todo);
                            case _TodoMenuAction.unlinkHabit:
                              await _unlinkHabit(context, ref, todo);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: _TodoMenuAction.edit, child: Text('Edit')),
                          const PopupMenuItem(value: _TodoMenuAction.delete, child: Text('Delete')),
                          if (todo.habitId != null)
                            const PopupMenuItem(
                              value: _TodoMenuAction.unlinkHabit,
                              child: Text('Unlink habit'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addTodo(BuildContext context, WidgetRef ref) async {
    final currentTodos = ref.read(activeTodosProvider).maybeWhen(
          data: (list) => list,
          orElse: () => const <Todo>[],
        );
    await showTodoDialog(context, ref, order: currentTodos.length);
  }

  Future<void> _editTodo(BuildContext context, WidgetRef ref, Todo todo) async {
    await showTodoDialog(context, ref, existing: todo);
  }

  Future<void> _toggleTodo(BuildContext context, WidgetRef ref, Todo todo, bool completed) async {
    final service = ref.read(todoServiceProvider);
    final updateResult = await service.update(
      todo.copyWith(
        status: completed ? TodoStatus.done : TodoStatus.pending,
        updatedAt: DateTime.now(),
      ),
    );
    if (!context.mounted) return;
    if (updateResult.isFailure) AppFeedback.showError(context, updateResult.error!);
    ref.invalidate(activeTodosProvider);
  }

  Future<void> _deleteTodo(BuildContext context, WidgetRef ref, Todo todo) async {
    final service = ref.read(todoServiceProvider);
    final deleteResult = await service.softDelete(todo.id);
    if (!context.mounted) return;
    if (deleteResult.isFailure) AppFeedback.showError(context, deleteResult.error!);
    ref.invalidate(activeTodosProvider);
  }

  Future<void> _unlinkHabit(BuildContext context, WidgetRef ref, Todo todo) async {
    final service = ref.read(todoServiceProvider);
    final updateResult = await service.update(todo.copyWith(clearHabitId: true, updatedAt: DateTime.now()));
    if (!context.mounted) return;
    if (updateResult.isFailure) AppFeedback.showError(context, updateResult.error!);
    ref.invalidate(activeTodosProvider);
  }

  Future<void> _reorder(BuildContext context, WidgetRef ref, List<Todo> todos, int oldIndex, int newIndex) async {
    final reordered = [...todos];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    final service = ref.read(todoServiceProvider);
    final updated = [
      for (var i = 0; i < reordered.length; i++) reordered[i].copyWith(order: i, updatedAt: DateTime.now()),
    ];
    final updateResult = await service.updateBulk(updated);
    if (!context.mounted) return;
    if (updateResult.isFailure) AppFeedback.showError(context, updateResult.error!);
    ref.invalidate(activeTodosProvider);
  }
}
