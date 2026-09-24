import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/financial/category_model.dart';
import '../../../data/models/financial/transaction_model.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../providers/financial_providers.dart';

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
  static const _colorOptions = <Color>[
    Colors.orange,
    Colors.blue,
    Colors.purple,
    Colors.green,
    Colors.red,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
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
          _buildEmbeddedHeader(),
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

  Widget _buildEmbeddedHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        children: [
          Text(
            'Categories',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCategoryDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
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
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final totalsAsync = ref.watch(categoryTotalsProvider(_currentMonthRange));

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => AsyncErrorView(
        error: error,
        onRetry: () => ref.invalidate(allCategoriesProvider),
      ),
      data: (allCategories) {
        final categories = allCategories
            .where((category) => category.type == _selectedType)
            .toList();

        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${_selectedType.name} categories yet',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                const Text('Tap + to create your first category'),
              ],
            ),
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
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _buildCategoryCard(category, totals[category.id] ?? 0.0);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryCard(CategoryModel category, double monthTotal) {
    return Card(
      child: InkWell(
        onTap: () => _showCategoryDetails(category, monthTotal),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      category.icon,
                      color: category.color,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await _showCategoryDialog(category: category);
                      } else if (value == 'delete') {
                        _deleteCategory(category);
                      }
                    },
                  ),
                ],
              ),
              const Spacer(),
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '₪${monthTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'This month',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryDetails(CategoryModel category, double monthTotal) {
    unawaited(showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (sheetContext, scrollController) {
          final transactionsAsync = ref.read(allTransactionsProvider);
          final categoryTransactions = transactionsAsync.maybeWhen(
            data: (transactions) => transactions
                .where((transaction) => transaction.categoryId == category.id)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date)),
            orElse: () => const <TransactionModel>[],
          );
          final transactionsError = transactionsAsync.hasError ? transactionsAsync.error : null;

          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        category.icon,
                        color: category.color,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            category.type.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatCard('This Month', '₪${monthTotal.toStringAsFixed(2)}', category.color),
                const SizedBox(height: 24),
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: transactionsError != null
                      ? AsyncErrorView(
                          error: transactionsError,
                          onRetry: () => ref.invalidate(allTransactionsProvider),
                        )
                      : categoryTransactions.isEmpty
                      ? const Center(child: Text('No transactions in this category yet'))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: categoryTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = categoryTransactions[index];
                            return _buildTransactionItem(
                              transaction.description,
                              transaction.amount,
                              transaction.date,
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    ));
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(String description, double amount, DateTime date) {
    return ListTile(
      leading: const Icon(Icons.receipt),
      title: Text(description),
      subtitle: Text(
        '${date.day}/${date.month}/${date.year}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        '₪${amount.toStringAsFixed(2)}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
    unawaited(showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(_deleteCategoryTitle),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(_cancelLabel),
          ),
          FilledButton(
            onPressed: () async {
              final result =
                  await ref.read(financialServiceProvider).deleteCategory(category);
              if (!dialogContext.mounted) return;

              if (result.isSuccess) {
                Navigator.pop(dialogContext);
                if (mounted) {
                  ref.invalidate(allCategoriesProvider);
                  ref.invalidate(categoryTotalsProvider);
                  AppFeedback.showSuccess(context, _categoryDeletedMessage);
                }
              } else {
                AppFeedback.showError(dialogContext, result.error!);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(_deleteLabel),
          ),
        ],
      ),
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
    final category = widget.category;
    return AlertDialog(
      title: Text(category == null ? 'Create Category' : 'Edit Category'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CategoryType>(
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                initialValue: selectedType,
                items: const [
                  DropdownMenuItem(value: CategoryType.expense, child: Text('Expense')),
                  DropdownMenuItem(value: CategoryType.income, child: Text('Income')),
                ],
                onChanged: (value) => setState(() => selectedType = value ?? selectedType),
              ),
              const SizedBox(height: 16),
              const Text('Select Icon'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.iconOptions
                    .map((icon) => InkWell(
                          onTap: () => setState(() => selectedIcon = icon),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: icon == selectedIcon ? selectedColor.withValues(alpha: 0.2) : null,
                              border: Border.all(
                                color: icon == selectedIcon ? selectedColor : Colors.grey.withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              const Text('Select Color'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.colorOptions
                    .map((color) => InkWell(
                          onTap: () => setState(() => selectedColor = color),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color == selectedColor ? Colors.black : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
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
          child: Text(category == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}
