import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/accent_palette.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/financial/category_model.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/ui/app_form_dialog.dart';
import '../../../shared/widgets/ui/page_header.dart';
import '../../../shared/widgets/ui/show_app_bottom_sheet.dart';
import '../providers/financial_providers.dart';
import '../widgets/category_detail_sheet.dart';
import '../widgets/category_tile.dart';
import '../widgets/financial_color_swatch_picker.dart';
import '../widgets/financial_delete_confirm_dialog.dart';
import '../widgets/financial_icon_option_picker.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  static const routeName = '/financial/categories';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [FinancialScreen] shell.
  final bool embedded;

  const CategoriesPage({super.key, this.embedded = false});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  static const double _cardAspectRatio = 1.2;
  static const int _gridCrossAxisCount = 2;
  static const _defaultUserId = 'user1';
  static const String _categoryCreatedMessage = 'Category created successfully';
  static const String _categoryUpdatedMessage = 'Category updated';
  static const String _categoryDeletedMessage = 'Category deleted';
  static const String _deleteCategoryTitle = 'Delete Category';
  static const String _cancelLabel = 'Cancel';
  static const String _deleteLabel = 'Delete';
  static const _iconOptions = <IconData>[
    Icons.shopping_cart,
    Icons.restaurant,
    Icons.directions_car,
    Icons.home,
    Icons.movie,
    Icons.fitness_center,
    Icons.medical_services,
    Icons.school,
    Icons.card_giftcard,
    Icons.work,
    Icons.savings,
    Icons.category,
  ];
  static final _colorOptions = <Color>[
    for (final option in AccentPalette.options) option.color,
  ];

  CategoryType _selectedType = CategoryType.expense;
  final _uuid = const Uuid();

  DateRange get _currentMonthRange {
    final now = DateTime.now();
    return DateRange(
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Column(
        children: [
          PageHeader(
            title: 'Categories',
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showCategoryDialog(),
              ),
            ],
          ),
          _buildTypeFilter(),
          Expanded(child: _buildCategoriesList()),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCategoryDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTypeFilter(),
          Expanded(
            child: _buildCategoriesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
    final tokens = AppThemeTokens.of(context);
    return Padding(
      padding: EdgeInsets.all(tokens.spacing.lg),
      child: SegmentedButton<CategoryType>(
        segments: const [
          ButtonSegment(
            value: CategoryType.expense,
            label: Text('Expenses'),
            icon: Icon(Icons.arrow_upward),
          ),
          ButtonSegment(
            value: CategoryType.income,
            label: Text('Income'),
            icon: Icon(Icons.arrow_downward),
          ),
        ],
        selected: {_selectedType},
        onSelectionChanged: (Set<CategoryType> newSelection) {
          setState(() {
            _selectedType = newSelection.first;
          });
        },
      ),
    );
  }

  Widget _buildCategoriesList() {
    final tokens = AppThemeTokens.of(context);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final totalsAsync = ref.watch(categoryTotalsProvider(_currentMonthRange));

    return categoriesAsync.when(
      loading: () => const LoadingSkeleton(),
      error: (error, stack) => AsyncErrorView(
        error: error,
        onRetry: () => ref.invalidate(allCategoriesProvider),
      ),
      data: (allCategories) {
        final categories = allCategories
            .where((category) => category.type == _selectedType)
            .toList();

        if (categories.isEmpty) {
          return EmptyState(
            title: 'No ${_selectedType.name} categories yet',
            subtitle: 'Tap + to create your first category',
            icon: Icons.category_outlined,
          );
        }

        final totals = totalsAsync.maybeWhen(
          data: (value) => value,
          orElse: () => const <String, double>{},
        );

        return Column(
          children: [
            if (totalsAsync.hasError)
              AsyncErrorView(
                error: totalsAsync.error!,
                isCompact: true,
                onRetry: () => ref.invalidate(categoryTotalsProvider(_currentMonthRange)),
              ),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(tokens.spacing.lg),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _gridCrossAxisCount,
                  crossAxisSpacing: tokens.spacing.md,
                  mainAxisSpacing: tokens.spacing.md,
                  childAspectRatio: _cardAspectRatio,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return CategoryTile(
                    category: category,
                    monthTotal: totals[category.id] ?? 0.0,
                    onTap: () => _showCategoryDetails(category, totals[category.id] ?? 0.0),
                    onEdit: () => _showCategoryDialog(category: category),
                    onDelete: () => _deleteCategory(category),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCategoryDetails(CategoryModel category, double monthTotal) {
    unawaited(showAppBottomSheet<void>(
      context,
      title: category.name,
      builder: (_) => CategoryDetailSheet(category: category, monthTotal: monthTotal),
    ));
  }

  Future<void> _showCategoryDialog({CategoryModel? category}) async {
    final result = await showDialog<_CategoryDialogResult>(
      context: context,
      builder: (_) => _CategoryDialogContent(
        category: category,
        initialType: category?.type ?? _selectedType,
        iconOptions: _iconOptions,
        colorOptions: _colorOptions,
      ),
    );

    if (result == null || !mounted) return;

    final service = ref.read(financialServiceProvider);
    final now = DateTime.now();

    if (category == null) {
      final saveResult = await service.createCategory(
        CategoryModel(
          id: _uuid.v4(),
          userId: _defaultUserId,
          name: result.name,
          type: result.type,
          icon: result.icon,
          color: result.color,
          createdAt: now,
          updatedAt: now,
        ),
      );
      if (!mounted) return;
      if (saveResult.isSuccess) {
        AppFeedback.showSuccess(context, _categoryCreatedMessage);
      } else {
        AppFeedback.showError(context, saveResult.error!);
        return;
      }
    } else {
      final saveResult = await service.updateCategory(
        category.copyWith(
          name: result.name,
          type: result.type,
          icon: result.icon,
          color: result.color,
          updatedAt: now,
        ),
      );
      if (!mounted) return;
      if (saveResult.isSuccess) {
        AppFeedback.showSuccess(context, _categoryUpdatedMessage);
      } else {
        AppFeedback.showError(context, saveResult.error!);
        return;
      }
    }

    ref.invalidate(allCategoriesProvider);
    ref.invalidate(categoryTotalsProvider);
  }

  void _deleteCategory(CategoryModel category) {
    unawaited(showFinancialDeleteConfirmDialog(
      context,
      title: _deleteCategoryTitle,
      message: 'Are you sure you want to delete "${category.name}"?',
      cancelLabel: _cancelLabel,
      deleteLabel: _deleteLabel,
      onConfirm: () => ref.read(financialServiceProvider).deleteCategory(category),
      onDeleted: () {
        if (!mounted) return;
        ref.invalidate(allCategoriesProvider);
        ref.invalidate(categoryTotalsProvider);
        AppFeedback.showSuccess(context, _categoryDeletedMessage);
      },
    ));
  }
}

class _CategoryDialogResult {
  _CategoryDialogResult({
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
  });

  final String name;
  final CategoryType type;
  final IconData icon;
  final Color color;
}

class _CategoryDialogContent extends StatefulWidget {
  const _CategoryDialogContent({
    required this.category,
    required this.initialType,
    required this.iconOptions,
    required this.colorOptions,
  });

  final CategoryModel? category;
  final CategoryType initialType;
  final List<IconData> iconOptions;
  final List<Color> colorOptions;

  @override
  State<_CategoryDialogContent> createState() => _CategoryDialogContentState();
}

class _CategoryDialogContentState extends State<_CategoryDialogContent> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late CategoryType selectedType;
  late IconData selectedIcon;
  late Color selectedColor;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    nameController = TextEditingController(text: category?.name ?? '');
    selectedType = category?.type ?? widget.initialType;
    selectedIcon = category?.icon ?? widget.iconOptions.first;
    selectedColor = category?.color ?? widget.colorOptions.first;
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final category = widget.category;
    return AppFormDialog(
      title: category == null ? 'Create Category' : 'Edit Category',
      submitLabel: category == null ? 'Create' : 'Save',
      onSubmit: () {
        if (formKey.currentState?.validate() ?? false) {
          Navigator.pop(
            context,
            _CategoryDialogResult(
              name: nameController.text.trim(),
              type: selectedType,
              icon: selectedIcon,
              color: selectedColor,
            ),
          );
        }
      },
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Category Name'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            SizedBox(height: tokens.spacing.md),
            DropdownButtonFormField<CategoryType>(
              decoration: const InputDecoration(labelText: 'Type'),
              initialValue: selectedType,
              items: const [
                DropdownMenuItem(value: CategoryType.expense, child: Text('Expense')),
                DropdownMenuItem(value: CategoryType.income, child: Text('Income')),
              ],
              onChanged: (value) => setState(() => selectedType = value ?? selectedType),
            ),
            SizedBox(height: tokens.spacing.md),
            Text('Select Icon', style: theme.textTheme.labelLarge),
            SizedBox(height: tokens.spacing.sm),
            FinancialIconOptionPicker(
              options: widget.iconOptions,
              selected: selectedIcon,
              accentColor: selectedColor,
              onSelected: (icon) => setState(() => selectedIcon = icon),
            ),
            SizedBox(height: tokens.spacing.md),
            Text('Select Color', style: theme.textTheme.labelLarge),
            SizedBox(height: tokens.spacing.sm),
            FinancialColorSwatchPicker(
              options: widget.colorOptions,
              selected: selectedColor,
              onSelected: (color) => setState(() => selectedColor = color),
            ),
          ],
        ),
      ),
    );
  }
}
