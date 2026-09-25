import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import 'shell_destination.dart';
import 'shell_sidebar_item.dart';
import 'shell_sidebar_mode.dart';

class ShellSidebar extends StatelessWidget {
  static const String _pagesLabel = 'Pages';
  static const String _collapseLabel = 'Collapse to icons';
  static const String _expandLabel = 'Expand sidebar';
  static const String _closeAllLabel = 'Close sidebar completely';
  static const String _closeTooltip = 'Close sidebar';

  final ShellSidebarMode mode;
  final int selectedIndex;
  final List<ShellDestination> destinations;
  final VoidCallback onOpenStep;
  final VoidCallback onCloseStep;
  final VoidCallback onCloseAll;
  final ValueChanged<int> onSelect;
  final ReorderCallback onReorder;

  const ShellSidebar({
    super.key,
    required this.mode,
    required this.selectedIndex,
    required this.destinations,
    required this.onOpenStep,
    required this.onCloseStep,
    required this.onCloseAll,
    required this.onSelect,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final isExpanded = mode == ShellSidebarMode.expanded;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: tokens.spacing.sm),
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: isExpanded ? Alignment.centerRight : Alignment.center,
                child: Semantics(
                  button: true,
                  label: isExpanded ? _collapseLabel : _expandLabel,
                  child: IconButton(
                    onPressed: isExpanded ? onCloseStep : onOpenStep,
                    tooltip: isExpanded ? _collapseLabel : _expandLabel,
                    icon: Icon(isExpanded ? Icons.menu_open_rounded : Icons.menu_rounded),
                  ),
                ),
              ),
            ),
            if (isExpanded)
              Semantics(
                button: true,
                label: _closeAllLabel,
                child: IconButton(
                  onPressed: onCloseAll,
                  tooltip: _closeTooltip,
                  icon: const Icon(Icons.keyboard_double_arrow_left_rounded),
                ),
              ),
          ],
        ),
        if (isExpanded)
          Padding(
            padding: EdgeInsets.fromLTRB(tokens.spacing.lg, tokens.spacing.xs, tokens.spacing.lg, tokens.spacing.sm),
            child: Text(_pagesLabel, style: theme.textTheme.labelLarge?.copyWith(color: tokens.colors.muted)),
          ),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            itemCount: destinations.length,
            onReorderItem: onReorder,
            itemBuilder: (context, index) {
              final destination = destinations[index];
              return ReorderableDelayedDragStartListener(
                key: ValueKey(destination.key),
                index: index,
                child: ShellSidebarItem(
                  isExpanded: isExpanded,
                  isSelected: index == selectedIndex,
                  destination: destination,
                  onTap: () => onSelect(index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
