// lib/features/enhancements/screens/enhancement_notes_screen.dart: the "Notes to Enhance" page listing ideas to improve the app.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/enhancements/enhancement_note.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../providers/enhancement_providers.dart';
import '../widgets/enhancement_note_dialog.dart';

enum _EnhancementFilter { all, open, done }

enum _EnhancementMenuAction { edit, delete }

class EnhancementNotesScreen extends ConsumerStatefulWidget {
  static const routeName = '/enhancements';

  const EnhancementNotesScreen({super.key});

  @override
  ConsumerState<EnhancementNotesScreen> createState() => _EnhancementNotesScreenState();
}

class _EnhancementNotesScreenState extends ConsumerState<EnhancementNotesScreen> {
  static const String _title = 'Notes to Enhance';
  static const String _addTooltip = 'Add a note';
  static const String _emptyAllTitle = 'No notes yet';
  static const String _emptyAllSubtitle = 'Write down anything you want to improve in the app.';
  static const String _emptyOpenTitle = 'Nothing left to improve';
  static const String _emptyOpenSubtitle = 'Every note is done.';
  static const String _emptyDoneTitle = 'Nothing done yet';
  static const String _emptyDoneSubtitle = 'Completed notes show up here.';
  static const int _detailsPreviewLines = 3;

  _EnhancementFilter _filter = _EnhancementFilter.open;

  List<EnhancementNote> _applyFilter(List<EnhancementNote> notes) {
    return switch (_filter) {
      _EnhancementFilter.all => notes,
      _EnhancementFilter.open => notes.where((note) => !note.isDone).toList(growable: false),
      _EnhancementFilter.done => notes.where((note) => note.isDone).toList(growable: false),
    };
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final notesAsync = ref.watch(enhancementNotesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(_title)),
      floatingActionButton: FloatingActionButton(
        tooltip: _addTooltip,
        onPressed: () => showEnhancementNoteDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: notesAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (error, stack) => AsyncErrorView(
          error: error,
          onRetry: () => ref.invalidate(enhancementNotesProvider),
        ),
        data: (notes) {
          final visible = _applyFilter(notes);
          final openCount = notes.where((note) => !note.isDone).length;
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(tokens.spacing.lg, tokens.spacing.md, tokens.spacing.lg, tokens.spacing.sm),
                child: SegmentedButton<_EnhancementFilter>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: _EnhancementFilter.open, label: Text('Open ($openCount)')),
                    ButtonSegment(value: _EnhancementFilter.done, label: Text('Done (${notes.length - openCount})')),
                    ButtonSegment(value: _EnhancementFilter.all, label: Text('All (${notes.length})')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (selection) => setState(() => _filter = selection.first),
                ),
              ),
              Expanded(child: visible.isEmpty ? _buildEmptyState(notes.isEmpty) : _buildList(visible, tokens)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool hasNoNotesAtAll) {
    if (hasNoNotesAtAll) {
      return EmptyState(
        title: _emptyAllTitle,
        subtitle: _emptyAllSubtitle,
        icon: Icons.lightbulb_outline_rounded,
        actionLabel: 'Add a note',
        onAction: () => showEnhancementNoteDialog(context, ref),
      );
    }
    final isOpenFilter = _filter == _EnhancementFilter.open;
    return EmptyState(
      title: isOpenFilter ? _emptyOpenTitle : _emptyDoneTitle,
      subtitle: isOpenFilter ? _emptyOpenSubtitle : _emptyDoneSubtitle,
      icon: Icons.task_alt_rounded,
      isCompact: true,
    );
  }

  Widget _buildList(List<EnhancementNote> notes, AppThemeTokens tokens) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(tokens.spacing.lg, tokens.spacing.sm, tokens.spacing.lg, tokens.spacing.xxl * 2),
      itemCount: notes.length,
      separatorBuilder: (context, index) => SizedBox(height: tokens.spacing.sm),
      itemBuilder: (context, index) => _buildNoteCard(notes[index]),
    );
  }

  Widget _buildNoteCard(EnhancementNote note) {
    final theme = Theme.of(context);
    final details = note.details;
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: () => showEnhancementNoteDialog(context, ref, existing: note),
        leading: Checkbox(
          value: note.isDone,
          onChanged: (value) => _toggleDone(note, value ?? false),
        ),
        title: Text(
          note.title,
          style: note.isDone
              ? theme.textTheme.titleMedium?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : theme.textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (details != null)
              Text(details, maxLines: _detailsPreviewLines, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            _PriorityBadge(priority: note.priority),
          ],
        ),
        trailing: PopupMenuButton<_EnhancementMenuAction>(
          icon: const Icon(Icons.more_vert),
          onSelected: (action) async {
            switch (action) {
              case _EnhancementMenuAction.edit:
                await showEnhancementNoteDialog(context, ref, existing: note);
              case _EnhancementMenuAction.delete:
                await _delete(note);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: _EnhancementMenuAction.edit, child: Text('Edit')),
            PopupMenuItem(value: _EnhancementMenuAction.delete, child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleDone(EnhancementNote note, bool isDone) async {
    final result = await ref.read(enhancementNoteServiceProvider).setDone(note, isDone: isDone);
    if (!mounted) return;
    if (result.isFailure) AppFeedback.showError(context, result.error!);
    ref.invalidate(enhancementNotesProvider);
  }

  Future<void> _delete(EnhancementNote note) async {
    final result = await ref.read(enhancementNoteServiceProvider).softDelete(note.id);
    if (!mounted) return;
    if (result.isFailure) AppFeedback.showError(context, result.error!);
    ref.invalidate(enhancementNotesProvider);
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final EnhancementPriority priority;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, background, foreground) = switch (priority) {
      EnhancementPriority.high => ('High', colorScheme.errorContainer, colorScheme.onErrorContainer),
      EnhancementPriority.medium => ('Medium', colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer),
      EnhancementPriority.low => ('Low', colorScheme.surfaceContainerHighest, colorScheme.onSurfaceVariant),
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground),
        ),
      ),
    );
  }
}
