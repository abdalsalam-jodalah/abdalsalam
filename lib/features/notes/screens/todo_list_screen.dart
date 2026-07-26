import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/notes/todo.dart';
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
        error: (error, stack) => const Center(child: Text('Failed to load todos')),
        data: (todos) {
          if (todos.isEmpty) {
            return const Center(child: Text('No todos yet. Tap + to add one.'));
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            buildDefaultDragHandles: false,
            itemCount: todos.length,
            onReorderItem: (oldIndex, newIndex) => _reorder(ref, todos, oldIndex, newIndex),
            itemBuilder: (context, index) {
              final todo = todos[index];
              return ReorderableDelayedDragStartListener(
                key: ValueKey(todo.id),
                index: index,
                child: TodoItem(
                  title: todo.title,
                  completed: todo.status == TodoStatus.done,
                  onChanged: (value) => _toggleTodo(ref, todo, value ?? false),
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
                        onSelected: (action) {
                          switch (action) {
                            case _TodoMenuAction.edit:
                              _editTodo(context, ref, todo);
                            case _TodoMenuAction.delete:
                              _deleteTodo(ref, todo);
                            case _TodoMenuAction.unlinkHabit:
                              _unlinkHabit(ref, todo);
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

  Future<void> _toggleTodo(WidgetRef ref, Todo todo, bool completed) async {
    final repo = ref.read(todoRepositoryProvider);
    await repo.update(
      todo.copyWith(
        status: completed ? TodoStatus.done : TodoStatus.pending,
        updatedAt: DateTime.now(),
      ),
    );
    ref.invalidate(activeTodosProvider);
  }

  Future<void> _deleteTodo(WidgetRef ref, Todo todo) async {
    final repo = ref.read(todoRepositoryProvider);
    await repo.softDelete(todo.id);
    ref.invalidate(activeTodosProvider);
  }

  Future<void> _unlinkHabit(WidgetRef ref, Todo todo) async {
    final repo = ref.read(todoRepositoryProvider);
    await repo.update(todo.copyWith(clearHabitId: true, updatedAt: DateTime.now()));
    ref.invalidate(activeTodosProvider);
  }

  Future<void> _reorder(WidgetRef ref, List<Todo> todos, int oldIndex, int newIndex) async {
    final reordered = [...todos];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    final repo = ref.read(todoRepositoryProvider);
    final updated = [
      for (var i = 0; i < reordered.length; i++) reordered[i].copyWith(order: i, updatedAt: DateTime.now()),
    ];
    await repo.updateBulk(updated);
    ref.invalidate(activeTodosProvider);
  }
}
