import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/financial/budget_model.dart';
import '../../../data/models/financial/category_model.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../providers/financial_providers.dart';
import '../../../providers/app_providers.dart';

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
  static const String _budgetCreatedMessage = 'Budget created successfully';
  static const String _budgetUpdatedMessage = 'Budget updated';
  static const String _budgetDeletedMessage = 'Budget deleted';
  static const String _deleteBudgetTitle = 'Delete Budget';
  static const String _deleteBudgetMessage = 'Are you sure you want to delete this budget?';
  static const String _cancelLabel = 'Cancel';
  static const String _deleteLabel = 'Delete';
  static const String _createCategoryFirstMessage = 'Create a category first';

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
      error: (error, stack) => AsyncErrorView(
        error: error,
        onRetry: () => ref.invalidate(activeBudgetsProvider),
      ),
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
            if (progressAsync.hasError)
              AsyncErrorView(
                error: progressAsync.error!,
                isCompact: true,
                onRetry: () => ref.invalidate(budgetProgressProvider(budget)),
              ),
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
    final settings = await ref.read(settingsServiceProvider).getSettings();
    if (!mounted) return;
    final defaultAlertThreshold =
        (settings['financialDefaultBudgetAlertThreshold'] as num?)?.toDouble() ?? 80.0;
    final categoriesAsync = ref.read(allCategoriesProvider);
    final categories = categoriesAsync.maybeWhen(
      data: (list) => list,
      orElse: () => const <CategoryModel>[],
    );

    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_createCategoryFirstMessage)),
      );
      return;
    }

    final result = await showDialog<_BudgetDialogResult>(
      context: context,
      builder: (_) => _BudgetDialogContent(
        budget: budget,
        categories: categories,
        initialPeriod: budget?.period ?? _selectedPeriod,
      ),
    );

    if (result == null || !mounted) return;

    final service = ref.read(financialServiceProvider);
    final now = DateTime.now();
    final range = result.period == BudgetPeriod.custom
        ? (start: result.customRange.start, end: result.customRange.end)
        : _rangeForPeriod(result.period);

    if (budget == null) {
      final saveResult = await service.createBudget(
        BudgetModel(
          id: _uuid.v4(),
          userId: _defaultUserId,
          categoryId: result.categoryId,
          amount: result.amount,
          period: result.period,
          startDate: range.start,
          endDate: range.end,
          alertThreshold: defaultAlertThreshold,
          createdAt: now,
          updatedAt: now,
        ),
      );
      if (!mounted) return;
      if (saveResult.isSuccess) {
        AppFeedback.showSuccess(context, _budgetCreatedMessage);
      } else {
        AppFeedback.showError(context, saveResult.error!);
        return;
      }
    } else {
      final saveResult = await service.updateBudget(
        budget.copyWith(
          categoryId: result.categoryId,
          amount: result.amount,
          period: result.period,
          startDate: range.start,
          endDate: range.end,
          updatedAt: now,
        ),
      );
      if (!mounted) return;
      if (saveResult.isSuccess) {
        AppFeedback.showSuccess(context, _budgetUpdatedMessage);
      } else {
        AppFeedback.showError(context, saveResult.error!);
        return;
      }
    }

    ref.invalidate(activeBudgetsProvider);
  }

  void _deleteBudget(BudgetModel budget) {
    unawaited(showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(_deleteBudgetTitle),
        content: const Text(_deleteBudgetMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(_cancelLabel),
          ),
          FilledButton(
            onPressed: () async {
              final result =
                  await ref.read(financialServiceProvider).deleteBudget(budget);
              if (!dialogContext.mounted) return;

              if (result.isSuccess) {
                Navigator.pop(dialogContext);
                if (mounted) {
                  ref.invalidate(activeBudgetsProvider);
                  AppFeedback.showSuccess(context, _budgetDeletedMessage);
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

class _BudgetDialogResult {
  _BudgetDialogResult({
    required this.categoryId,
    required this.amount,
    required this.period,
    required this.customRange,
  });

  final String categoryId;
  final double amount;
  final BudgetPeriod period;
  final DateTimeRange customRange;
}

class _BudgetDialogContent extends StatefulWidget {
  const _BudgetDialogContent({
    required this.budget,
    required this.categories,
    required this.initialPeriod,
  });

  final BudgetModel? budget;
  final List<CategoryModel> categories;
  final BudgetPeriod initialPeriod;

  @override
  State<_BudgetDialogContent> createState() => _BudgetDialogContentState();
}

class _BudgetDialogContentState extends State<_BudgetDialogContent> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController amountController;
  String? selectedCategoryId;
  late BudgetPeriod selectedPeriod;
  late DateTimeRange customRange;

  @override
  void initState() {
    super.initState();
    final budget = widget.budget;
    amountController = TextEditingController(text: budget?.amount.toStringAsFixed(2) ?? '');
    selectedCategoryId = budget?.categoryId ?? widget.categories.first.id;
    selectedPeriod = widget.initialPeriod;
    customRange = DateTimeRange(
      start: budget?.startDate ?? DateTime.now(),
      end: budget?.endDate ?? DateTime.now().add(const Duration(days: 30)),
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budget = widget.budget;
    return AlertDialog(
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
                items: widget.categories
                    .map((category) => DropdownMenuItem(value: category.id, child: Text(category.name)))
                    .toList(),
                onChanged: (value) => setState(() => selectedCategoryId = value),
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
                  DropdownMenuItem(value: BudgetPeriod.daily, child: Text('Daily')),
                  DropdownMenuItem(value: BudgetPeriod.weekly, child: Text('Weekly')),
                  DropdownMenuItem(value: BudgetPeriod.monthly, child: Text('Monthly')),
                  DropdownMenuItem(value: BudgetPeriod.yearly, child: Text('Yearly')),
                  DropdownMenuItem(value: BudgetPeriod.custom, child: Text('Custom range')),
                ],
                onChanged: (value) => setState(() => selectedPeriod = value ?? selectedPeriod),
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
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDateRange: customRange,
                    );
                    if (picked != null && mounted) {
                      setState(() => customRange = picked);
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if ((formKey.currentState?.validate() ?? false) && selectedCategoryId != null) {
              Navigator.pop(
                context,
                _BudgetDialogResult(
                  categoryId: selectedCategoryId!,
                  amount: double.parse(amountController.text),
                  period: selectedPeriod,
                  customRange: customRange,
                ),
              );
            }
          },
          child: Text(budget == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}
