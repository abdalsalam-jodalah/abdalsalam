import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/financial/budget_model.dart';
import '../../../data/models/financial/category_model.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/ui/app_form_dialog.dart';
import '../../../shared/widgets/ui/filter_bar.dart';
import '../../../shared/widgets/ui/filter_option.dart';
import '../../../shared/widgets/ui/page_header.dart';
import '../providers/financial_providers.dart';
import '../widgets/budget_card.dart';
import '../widgets/financial_delete_confirm_dialog.dart';

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
  static const List<FilterOption<BudgetPeriod>> _periodOptions = [
    FilterOption(BudgetPeriod.daily, 'Day'),
    FilterOption(BudgetPeriod.weekly, 'Week'),
    FilterOption(BudgetPeriod.monthly, 'Month'),
    FilterOption(BudgetPeriod.yearly, 'Year'),
    FilterOption(BudgetPeriod.custom, 'Custom'),
  ];

  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Column(
        children: [
          PageHeader(
            title: 'Budgets',
            actions: [
              IconButton(icon: const Icon(Icons.add), onPressed: _showBudgetDialog),
            ],
          ),
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

  Widget _buildPeriodFilter() {
    final tokens = AppThemeTokens.of(context);
    return Padding(
      padding: EdgeInsets.all(tokens.spacing.lg),
      child: FilterBar<BudgetPeriod>(
        options: _periodOptions,
        selected: _selectedPeriod,
        onSelected: (value) => setState(() => _selectedPeriod = value),
      ),
    );
  }

  Widget _buildBudgetsList() {
    final tokens = AppThemeTokens.of(context);
    final budgetsAsync = ref.watch(activeBudgetsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return budgetsAsync.when(
      loading: () => const LoadingSkeleton(),
      error: (error, stack) => AsyncErrorView(
        error: error,
        onRetry: () => ref.invalidate(activeBudgetsProvider),
      ),
      data: (budgets) {
        final filtered = budgets
            .where((budget) => budget.period == _selectedPeriod)
            .toList();

        if (filtered.isEmpty) {
          return EmptyState(
            title: 'No ${_selectedPeriod.name} budgets yet',
            subtitle: 'Tap + to create your first budget',
            icon: Icons.savings_outlined,
          );
        }

        final categories = categoriesAsync.maybeWhen(
          data: (list) => list,
          orElse: () => const <CategoryModel>[],
        );

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(activeBudgetsProvider),
          child: ListView.separated(
            padding: EdgeInsets.all(tokens.spacing.lg),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => SizedBox(height: tokens.spacing.md),
            itemBuilder: (context, index) {
              final budget = filtered[index];
              final category = _categoryFor(categories, budget.categoryId);
              return BudgetCard(
                budget: budget,
                category: category,
                progress: ref.watch(budgetProgressProvider(budget)),
                onRetryProgress: () => ref.invalidate(budgetProgressProvider(budget)),
                onEdit: () => _showBudgetDialog(budget: budget),
                onDelete: () => _deleteBudget(budget),
              );
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
    unawaited(showFinancialDeleteConfirmDialog(
      context,
      title: _deleteBudgetTitle,
      message: _deleteBudgetMessage,
      cancelLabel: _cancelLabel,
      deleteLabel: _deleteLabel,
      onConfirm: () => ref.read(financialServiceProvider).deleteBudget(budget),
      onDeleted: () {
        if (!mounted) return;
        ref.invalidate(activeBudgetsProvider);
        AppFeedback.showSuccess(context, _budgetDeletedMessage);
      },
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
  static const String _amountCurrencySymbol = '₪';

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
    final tokens = AppThemeTokens.of(context);
    final budget = widget.budget;
    return AppFormDialog(
      title: budget == null ? 'Create Budget' : 'Edit Budget',
      submitLabel: budget == null ? 'Create' : 'Save',
      onSubmit: () {
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
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Category'),
              initialValue: selectedCategoryId,
              items: widget.categories
                  .map((category) => DropdownMenuItem(value: category.id, child: Text(category.name)))
                  .toList(),
              onChanged: (value) => setState(() => selectedCategoryId = value),
            ),
            SizedBox(height: tokens.spacing.md),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: _amountCurrencySymbol,
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
            SizedBox(height: tokens.spacing.md),
            DropdownButtonFormField<BudgetPeriod>(
              decoration: const InputDecoration(labelText: 'Period'),
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
              SizedBox(height: tokens.spacing.md),
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(
                  '${AppDateFormatter.date(customRange.start)} – ${AppDateFormatter.date(customRange.end)}',
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
    );
  }
}
