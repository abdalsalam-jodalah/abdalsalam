import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/planning/task_category.dart';
import '../providers/planning_providers.dart';
import '../screens/task_categories_screen.dart';
import 'task_category_badge.dart';

class TaskCategoryPicker extends ConsumerWidget {
  static const String _title = 'Categories';
  static const String _hint = 'Tap to select one or more';
  static const String _emptyMessage = 'No categories yet';
  static const String _manageLabel = 'Manage';
  static const String _loadFailedMessage = 'Categories could not be loaded';

  final List<String> selectedCategoryIds;
  final ValueChanged<List<String>> onChanged;

  const TaskCategoryPicker({super.key, required this.selectedCategoryIds, required this.onChanged});

  List<String> _toggled(String categoryId, List<TaskCategory> categories) {
    final knownIds = categories.map((category) => category.id).toSet();
    final remaining = selectedCategoryIds.where((id) => knownIds.contains(id) && id != categoryId).toList();
    final wasSelected = selectedCategoryIds.contains(categoryId);
    return wasSelected ? remaining : <String>[...remaining, categoryId];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = AppThemeTokens.of(context).spacing;
    final textTheme = Theme.of(context).textTheme;
    final categoriesAsync = ref.watch(taskCategoriesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(_title, style: textTheme.labelLarge),
            SizedBox(width: spacing.sm),
            Text(_hint, style: textTheme.bodySmall),
          ],
        ),
        SizedBox(height: spacing.sm),
        categoriesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, stack) =>
              Text(_loadFailedMessage, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          data: (categories) => Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (categories.isEmpty) Text(_emptyMessage, style: textTheme.bodySmall),
              for (final category in categories)
                _CategoryChoice(
                  category: category,
                  isSelected: selectedCategoryIds.contains(category.id),
                  onTap: () => onChanged(_toggled(category.id, categories)),
                ),
              ActionChip(
                avatar: const Icon(Icons.settings_outlined, size: 16),
                label: const Text(_manageLabel),
                onPressed: () => Navigator.of(context).pushNamed(TaskCategoriesScreen.routeName),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryChoice extends StatelessWidget {
  static const double _selectedBorderWidth = 2;
  static const double _checkSize = 16;

  final TaskCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChoice({required this.category, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: isSelected,
      label: category.name,
      child: InkWell(
        key: ValueKey('category-choice-${category.id}'),
        borderRadius: tokens.radius.pillBorder,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: tokens.radius.pillBorder,
            border: Border.all(color: isSelected ? colors.primary : Colors.transparent, width: _selectedBorderWidth),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(Icons.check_circle, size: _checkSize, color: colors.primary),
                SizedBox(width: tokens.spacing.xs),
              ],
              TaskCategoryBadge(category: category),
            ],
          ),
        ),
      ),
    );
  }
}
