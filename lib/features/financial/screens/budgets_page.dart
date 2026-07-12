import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/financial/budget_model.dart';
import '../../../data/models/financial/category_model.dart';
import '../providers/financial_providers.dart';

class BudgetsPage extends ConsumerStatefulWidget {
  static const routeName = '/financial/budgets';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [FinancialScreen] shell.
  final bool embedded;

  const BudgetsPage({super.key, this.embedded = false});

  @override
  ConsumerState<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends ConsumerState<BudgetsPage> {
  static const _defaultUserId = 'user1';
  static const _defaultAlertThreshold = 80.0;

  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Column(
        children: [
          _buildEmbeddedHeader(),
          _buildPeriodFilter(),
          Expanded(child: _buildBudgetsList()),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showBudgetDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodFilter(),
          Expanded(
            child: _buildBudgetsList(),
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
            'Budgets',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showBudgetDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<BudgetPeriod>(
          segments: const [
            ButtonSegment(
              value: BudgetPeriod.daily,
              label: Text('Day'),
            ),
            ButtonSegment(
              value: BudgetPeriod.weekly,
              label: Text('Week'),
            ),
            ButtonSegment(
              value: BudgetPeriod.monthly,
              label: Text('Month'),
            ),
            ButtonSegment(
              value: BudgetPeriod.yearly,
              label: Text('Year'),
            ),
            ButtonSegment(
              value: BudgetPeriod.custom,
              label: Text('Custom'),
            ),
          ],
          selected: {_selectedPeriod},
          onSelectionChanged: (Set<BudgetPeriod> newSelection) {
            setState(() {
              _selectedPeriod = newSelection.first;
            });
          },
        ),
      ),
    );
  }

  Widget _buildBudgetsList() {
    final budgetsAsync = ref.watch(activeBudgetsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return budgetsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Failed to load budgets')),
      data: (budgets) {
        final filtered = budgets
            .where((budget) => budget.period == _selectedPeriod)
            .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.savings_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${_selectedPeriod.name} budgets yet',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                const Text('Tap + to create your first budget'),
              ],
            ),
          );
        }

        final categories = categoriesAsync.maybeWhen(
          data: (list) => list,
          orElse: () => const <CategoryModel>[],
        );

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(activeBudgetsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final budget = filtered[index];
              return _buildBudgetCard(budget, _categoryFor(categories, budget.categoryId));
            },
          ),
        );
      },
    );
  }

  CategoryModel? _categoryFor(List<CategoryModel> categories, String categoryId) {
    for (final category in categories) {
      if (category.id == categoryId) {
        return category;
      }
    }
    return null;
  }

  Widget _buildBudgetCard(BudgetModel budget, CategoryModel? category) {
    final progressAsync = ref.watch(budgetProgressProvider(budget));
    final spent = progressAsync.maybeWhen(
      data: (progress) => (progress['spent'] as num?)?.toDouble() ?? 0.0,
      orElse: () => 0.0,
    );
    final percentage = budget.amount == 0 ? 0.0 : (spent / budget.amount) * 100;
    final remaining = budget.amount - spent;
    final isOverBudget = spent > budget.amount;
    final isNearLimit = percentage >= budget.alertThreshold;
    final categoryColor = category?.color ?? Colors.grey;
    final categoryIcon = category?.icon ?? Icons.category;
    final categoryName = category?.name ?? 'Unknown category';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                    color: categoryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    categoryIcon,
                    color: categoryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        budget.period.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isOverBudget
                            ? Colors.red
                            : isNearLimit
                                ? Colors.orange
                                : Colors.green,
                      ),
                    ),
                    if (isOverBudget)
                      const Text(
                        'Over Budget',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget
                      ? Colors.red
                      : isNearLimit
                          ? Colors.orange
                          : Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spent',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '₪${spent.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Remaining',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '₪${remaining.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: remaining < 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Budget',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '₪${budget.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showBudgetDialog(budget: budget),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteBudget(budget),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ({DateTime start, DateTime end}) _rangeForPeriod(BudgetPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case BudgetPeriod.daily:
        return (start: today, end: today.add(const Duration(days: 1)));
      case BudgetPeriod.weekly:
        final start = today.subtract(Duration(days: today.weekday - 1));
        return (start: start, end: start.add(const Duration(days: 7)));
      case BudgetPeriod.monthly:
        return (
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 1),
        );
      case BudgetPeriod.yearly:
        return (
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year + 1, 1, 1),
        );
      case BudgetPeriod.custom:
        return (
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 1),
        );
    }
  }

  Future<void> _showBudgetDialog({BudgetModel? budget}) async {
    final categoriesAsync = ref.read(allCategoriesProvider);
    final categories = categoriesAsync.maybeWhen(
      data: (list) => list,
      orElse: () => const <CategoryModel>[],
    );

    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a category first')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(
      text: budget?.amount.toStringAsFixed(2) ?? '',
    );
    String? selectedCategoryId = budget?.categoryId ?? categories.first.id;
    BudgetPeriod selectedPeriod = budget?.period ?? _selectedPeriod;
    DateTimeRange customRange = DateTimeRange(
      start: budget?.startDate ?? DateTime.now(),
      end: budget?.endDate ?? DateTime.now().add(const Duration(days: 30)),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(budget == null ? 'Create Budget' : 'Edit Budget'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: selectedCategoryId,
                    items: categories
                        .map((category) => DropdownMenuItem(
                              value: category.id,
                              child: Text(category.name),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedCategoryId = value),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      prefixText: '₪',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final parsed = double.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<BudgetPeriod>(
                    decoration: const InputDecoration(
                      labelText: 'Period',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: selectedPeriod,
                    items: const [
                      DropdownMenuItem(
                        value: BudgetPeriod.daily,
                        child: Text('Daily'),
                      ),
                      DropdownMenuItem(
                        value: BudgetPeriod.weekly,
                        child: Text('Weekly'),
                      ),
                      DropdownMenuItem(
                        value: BudgetPeriod.monthly,
                        child: Text('Monthly'),
                      ),
                      DropdownMenuItem(
                        value: BudgetPeriod.yearly,
                        child: Text('Yearly'),
                      ),
                      DropdownMenuItem(
                        value: BudgetPeriod.custom,
                        child: Text('Custom range'),
                      ),
                    ],
                    onChanged: (value) => setDialogState(
                        () => selectedPeriod = value ?? selectedPeriod),
                  ),
                  if (selectedPeriod == BudgetPeriod.custom) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        '${DateFormat('MMM d, yyyy').format(customRange.start)} – '
                        '${DateFormat('MMM d, yyyy').format(customRange.end)}',
                      ),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: dialogContext,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDateRange: customRange,
                        );
                        if (picked != null) {
                          setDialogState(() => customRange = picked);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: Text(budget == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || selectedCategoryId == null) {
      amountController.dispose();
      return;
    }

    final amount = double.parse(amountController.text);
    amountController.dispose();
    final service = ref.read(financialServiceProvider);
    final now = DateTime.now();
    final range = selectedPeriod == BudgetPeriod.custom
        ? (start: customRange.start, end: customRange.end)
        : _rangeForPeriod(selectedPeriod);

    if (budget == null) {
      final result = await service.createBudget(
        BudgetModel(
          id: _uuid.v4(),
          userId: _defaultUserId,
          categoryId: selectedCategoryId!,
          amount: amount,
          period: selectedPeriod,
          startDate: range.start,
          endDate: range.end,
          alertThreshold: _defaultAlertThreshold,
          createdAt: now,
          updatedAt: now,
        ),
      );
      if (!mounted) return;
      _showResultSnackBar(
        isSuccess: result.isSuccess,
        successMessage: 'Budget created successfully',
        successColor: Colors.green,
      );
    } else {
      final result = await service.updateBudget(
        budget.copyWith(
          categoryId: selectedCategoryId,
          amount: amount,
          period: selectedPeriod,
          startDate: range.start,
          endDate: range.end,
          updatedAt: now,
        ),
      );
      if (!mounted) return;
      _showResultSnackBar(
        isSuccess: result.isSuccess,
        successMessage: 'Budget updated',
        successColor: Colors.green,
      );
    }

    ref.invalidate(activeBudgetsProvider);
  }

  void _deleteBudget(BudgetModel budget) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text('Are you sure you want to delete this budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final result =
                  await ref.read(financialServiceProvider).deleteBudget(budget);
              if (!mounted) return;
              _showResultSnackBar(
                isSuccess: result.isSuccess,
                successMessage: 'Budget deleted',
                successColor: Colors.red,
              );
              ref.invalidate(activeBudgetsProvider);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showResultSnackBar({
    required bool isSuccess,
    required String successMessage,
    required Color successColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSuccess ? successMessage : 'Something went wrong'),
        backgroundColor: isSuccess ? successColor : Colors.red,
      ),
    );
  }
}
