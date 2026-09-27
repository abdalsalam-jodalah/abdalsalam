import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';

/// Generic drag-reorder list core shared by the Weekly Schedule and Daily
/// Log screens, following the [ReorderableListView] pattern used by
/// planning's ReorderableTaskList.
class ReorderableSportList<T> extends StatelessWidget {
  static const String _defaultEmptyMessage = 'Nothing here yet.';
  final List<T> items;
  final String Function(T item) keyOf;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final void Function(List<T> reordered) onReorder;
  final Widget? emptyState;

  const ReorderableSportList({
    super.key,
    required this.items,
    required this.keyOf,
    required this.itemBuilder,
    required this.onReorder,
    this.emptyState,
  });

  void _handleReorder(int oldIndex, int newIndex) {
    final reordered = [...items];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    onReorder(reordered);
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return emptyState ??
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppThemeTokens.of(context).spacing.md),
            child: Text(_defaultEmptyMessage, style: Theme.of(context).textTheme.bodyMedium),
          );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: items.length,
      onReorderItem: _handleReorder,
      itemBuilder: (context, index) {
        final item = items[index];
        return ReorderableDelayedDragStartListener(
          key: ValueKey(keyOf(item)),
          index: index,
          child: itemBuilder(context, item, index),
        );
      },
    );
  }
}
