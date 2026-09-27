import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/notes/note.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../providers/notes_providers.dart';
import '../widgets/note_dialog.dart';
import '../widgets/notes_widgets.dart';
import 'todo_list_screen.dart';

enum _NoteMenuAction { edit, delete }

class NotesHomeScreen extends ConsumerWidget {
  static const routeName = '/notes/home';
  static const String _title = 'Notes';
  static const String _todosTooltip = 'Todos';
  static const String _emptyTitle = 'No notes yet';
  static const String _emptySubtitle = 'Tap + to add one.';

  const NotesHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppThemeTokens.of(context);
    final notesAsync = ref.watch(activeNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist_outlined),
            tooltip: _todosTooltip,
            onPressed: () => Navigator.of(context).pushNamed(TodoListScreen.routeName),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNote(context, ref),
        child: const Icon(Icons.add),
      ),
      body: notesAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (error, stack) => AsyncErrorView(
          error: error,
          onRetry: () => ref.invalidate(activeNotesProvider),
        ),
        data: (notes) {
          if (notes.isEmpty) {
            return const EmptyState(title: _emptyTitle, subtitle: _emptySubtitle);
          }
          return ReorderableListView.builder(
            padding: EdgeInsets.all(tokens.spacing.lg),
            buildDefaultDragHandles: false,
            itemCount: notes.length,
            onReorderItem: (oldIndex, newIndex) => _reorder(context, ref, notes, oldIndex, newIndex),
            itemBuilder: (context, index) {
              final note = notes[index];
              return ReorderableDelayedDragStartListener(
                key: ValueKey(note.id),
                index: index,
                child: Padding(
                  padding: EdgeInsets.only(bottom: tokens.spacing.md),
                  child: NoteCard(
                    title: note.title,
                    preview: note.content,
                    accentColor: noteColorFromKey(note.color),
                    onTap: () => _editNote(context, ref, note),
                    trailing: PopupMenuButton<_NoteMenuAction>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (action) async {
                        switch (action) {
                          case _NoteMenuAction.edit:
                            await _editNote(context, ref, note);
                          case _NoteMenuAction.delete:
                            await _deleteNote(context, ref, note);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: _NoteMenuAction.edit, child: Text('Edit')),
                        PopupMenuItem(value: _NoteMenuAction.delete, child: Text('Delete')),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final currentNotes = ref.read(activeNotesProvider).maybeWhen(
          data: (list) => list,
          orElse: () => const <Note>[],
        );
    await showNoteDialog(context, ref, order: currentNotes.length);
  }

  Future<void> _editNote(BuildContext context, WidgetRef ref, Note note) async {
    await showNoteDialog(context, ref, existing: note);
  }

  Future<void> _deleteNote(BuildContext context, WidgetRef ref, Note note) async {
    final service = ref.read(notesServiceProvider);
    final deleteResult = await service.softDelete(note.id);
    if (!context.mounted) return;
    if (deleteResult.isFailure) AppFeedback.showError(context, deleteResult.error!);
    ref.invalidate(activeNotesProvider);
  }

  Future<void> _reorder(BuildContext context, WidgetRef ref, List<Note> notes, int oldIndex, int newIndex) async {
    final reordered = [...notes];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    final service = ref.read(notesServiceProvider);
    final updated = [
      for (var i = 0; i < reordered.length; i++) reordered[i].copyWith(order: i, updatedAt: DateTime.now()),
    ];
    final updateResult = await service.updateBulk(updated);
    if (!context.mounted) return;
    if (updateResult.isFailure) AppFeedback.showError(context, updateResult.error!);
    ref.invalidate(activeNotesProvider);
  }
}
