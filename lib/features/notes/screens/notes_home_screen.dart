import 'package:flutter/material.dart';

import '../widgets/notes_widgets.dart';
import 'note_categories_screen.dart';
import 'note_editor_screen.dart';
import 'search_results_screen.dart';
import 'todo_list_screen.dart';

class NotesHomeScreen extends StatelessWidget {
  static const routeName = '/notes/home';

  const NotesHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes Home')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(NoteEditorScreen.routeName),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('New Note'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(TodoListScreen.routeName),
                  icon: const Icon(Icons.checklist_outlined),
                  label: const Text('Todos'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              const TagChip(tag: 'Work'),
              const TagChip(tag: 'Health'),
              const TagChip(tag: 'Learning'),
              ActionChip(
                label: const Text('Categories'),
                onPressed: () => Navigator.of(context).pushNamed(NoteCategoriesScreen.routeName),
              ),
              ActionChip(
                label: const Text('Search'),
                onPressed: () => Navigator.of(context).pushNamed(SearchResultsScreen.routeName),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Pinned Notes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const NoteCard(
            title: 'Quarter Plan',
            preview: 'Key goals, milestones, and weekly execution plan.',
          ),
          const NoteCard(
            title: 'Friday Reflection',
            preview: 'Wins, blockers, and next week focus points.',
          ),
          const SizedBox(height: 12),
          Text('Open Todos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Card(
            child: Column(
              children: [
                TodoItem(title: 'Review blood test report', completed: false),
                Divider(height: 1),
                TodoItem(title: 'Prepare weekly budget summary', completed: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
