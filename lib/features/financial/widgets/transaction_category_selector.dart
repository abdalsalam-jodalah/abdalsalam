import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/financial/category_model.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../providers/financial_providers.dart';

class TransactionCategorySelector extends ConsumerWidget {
  static const String _noCategoriesMessage =
      'No categories yet — add one from the Categories tab first.';
  static const double _menuItemIconSize = 20;

  final CategoryType categoryType;
  final String? selectedCategoryId;
  final ValueChanged<String> onChanged;

  const TransactionCategorySelector({
    super.key,
    required this.categoryType,
    required this.selectedCategoryId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = AppThemeTokens.of(context).spacing;
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return categoriesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, stack) => AsyncErrorView(
        error: error,
        isCompact: true,
        onRetry: () => ref.invalidate(allCategoriesProvider),
      ),
      data: (allCategories) {
        final matchingType = allCategories.where((category) => category.type == categoryType).toList();
        if (matchingType.isEmpty) {
          return Text(
            _noCategoriesMessage,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
          );
        }
        final resolvedSelectedId = matchingType.any((category) => category.id == selectedCategoryId)
            ? selectedCategoryId!
            : matchingType.first.id;
        if (resolvedSelectedId != selectedCategoryId) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onChanged(resolvedSelectedId));
        }
        final selectedCategory = matchingType.firstWhere((category) => category.id == resolvedSelectedId);
        return DropdownButtonFormField<String>(
          initialValue: resolvedSelectedId,
          decoration: InputDecoration(
            prefixIcon: Icon(selectedCategory.icon, color: theme.colorScheme.primary),
          ),
          items: [
            for (final category in matchingType)
              DropdownMenuItem(
                value: category.id,
                child: Row(
                  children: [
                    Icon(category.icon, size: _menuItemIconSize),
                    SizedBox(width: spacing.sm),
                    Text(category.name),
                  ],
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        );
      },
    );
  }
}
