import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/financial/transaction_model.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/ui/app_form_dialog.dart';
import '../../../shared/widgets/ui/page_header.dart';
import '../../../shared/widgets/ui/show_app_bottom_sheet.dart';
import '../providers/financial_providers.dart';
import '../widgets/financial_delete_confirm_dialog.dart';
import '../widgets/transaction_detail_sheet.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_form_screen.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  static const routeName = '/financial/transactions';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [FinancialScreen] shell.
  final bool embedded;

  const TransactionsPage({super.key, this.embedded = false});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  static const String _deleteDialogTitle = 'Delete Transaction';
  static const String _deleteDialogMessage =
      'Are you sure you want to delete this transaction?';
  static const String _cancelLabel = 'Cancel';
  static const String _deleteLabel = 'Delete';
  static const String _transactionDeletedMessage = 'Transaction deleted';

  String? _selectedCategory;
  TransactionType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    if (widget.embedded) {
      return Column(
        children: [
          PageHeader(
            title: 'Transactions',
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
              ),
            ],
          ),
          if (_selectedCategory != null || _selectedType != null) _buildActiveFilters(tokens),
          Expanded(child: _buildTransactionsList(tokens)),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addTransaction(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedCategory != null || _selectedType != null) _buildActiveFilters(tokens),
          Expanded(
            child: _buildTransactionsList(tokens),
          ),
        ],
      ),
    );
  }

  Future<void> _addTransaction() async {
    final result = await Navigator.pushNamed(
      context,
      TransactionFormScreen.routeName,
    );

    if (result != null && mounted) {
      ref.invalidate(allTransactionsProvider);
    }
  }

  Widget _buildActiveFilters(AppThemeTokens tokens) {
    return Container(
      padding: EdgeInsets.all(tokens.spacing.lg),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Wrap(
        spacing: tokens.spacing.sm,
        children: [
          if (_selectedCategory != null)
            Chip(
              label: Text(_selectedCategory!),
              onDeleted: () {
                setState(() => _selectedCategory = null);
              },
            ),
          if (_selectedType != null)
            Chip(
              label: Text(_selectedType!.name),
              onDeleted: () {
                setState(() => _selectedType = null);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(AppThemeTokens tokens) {
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return const EmptyState(
            title: 'No transactions yet',
            subtitle: 'Tap + to add your first transaction',
            icon: Icons.receipt_long_outlined,
          );
        }

        var filtered = transactions;
        if (_selectedType != null) {
          filtered = filtered.where((t) => t.type == _selectedType).toList();
        }
        if (_selectedCategory != null) {
          filtered = filtered.where((t) => t.categoryId == _selectedCategory).toList();
        }

        if (filtered.isEmpty) {
          return const EmptyState(
            title: 'No transactions match filters',
            subtitle: 'Try clearing a filter to see more transactions',
            icon: Icons.filter_list_off,
            isCompact: true,
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(tokens.spacing.lg),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => SizedBox(height: tokens.spacing.md),
          itemBuilder: (context, index) {
            final transaction = filtered[index];
            return TransactionTile(
              transaction: transaction,
              onTap: () => _showTransactionDetails(transaction),
            );
          },
        );
      },
      loading: () => const LoadingSkeleton(),
      error: (error, stack) => AsyncErrorView(
        error: error,
        onRetry: () => ref.invalidate(allTransactionsProvider),
      ),
    );
  }

  void _showFilterDialog() {
    final categoriesAsync = ref.read(allCategoriesProvider);

    unawaited(showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final tokens = AppThemeTokens.of(dialogContext);
        return AppFormDialog(
          title: 'Filter Transactions',
          submitLabel: 'Apply',
          onSubmit: () => Navigator.pop(dialogContext),
          extraActions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                  _selectedType = null;
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Clear'),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return const Text('No categories available');
                  }
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Category'),
                    initialValue: _selectedCategory,
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategory = value);
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => AsyncErrorView(
                  error: error,
                  isCompact: true,
                  onRetry: () => ref.invalidate(allCategoriesProvider),
                ),
              ),
              SizedBox(height: tokens.spacing.md),
              DropdownButtonFormField<TransactionType>(
                decoration: const InputDecoration(labelText: 'Type'),
                initialValue: _selectedType,
                items: const [
                  DropdownMenuItem(
                    value: TransactionType.income,
                    child: Text('Income'),
                  ),
                  DropdownMenuItem(
                    value: TransactionType.expense,
                    child: Text('Expense'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedType = value);
                },
              ),
            ],
          ),
        );
      },
    ));
  }

  void _showTransactionDetails(TransactionModel transaction) {
    unawaited(showAppBottomSheet<void>(
      context,
      title: 'Transaction Details',
      builder: (sheetContext) => TransactionDetailSheet(
        transaction: transaction,
        onEdit: () async {
          Navigator.pop(sheetContext);
          final result = await Navigator.pushNamed(
            context,
            TransactionFormScreen.routeName,
            arguments: transaction,
          );
          if (!mounted) return;
          if (result != null) {
            ref.invalidate(allTransactionsProvider);
          }
        },
        onDelete: () {
          Navigator.pop(sheetContext);
          _deleteTransaction(transaction);
        },
      ),
    ));
  }

  void _deleteTransaction(TransactionModel transaction) {
    unawaited(showFinancialDeleteConfirmDialog(
      context,
      title: _deleteDialogTitle,
      message: _deleteDialogMessage,
      cancelLabel: _cancelLabel,
      deleteLabel: _deleteLabel,
      onConfirm: () => ref.read(financialServiceProvider).deleteTransaction(transaction.id),
      onDeleted: () {
        if (!mounted) return;
        ref.invalidate(allTransactionsProvider);
        ref.invalidate(recentTransactionsProvider);
        ref.invalidate(financialSummaryProvider);
        ref.invalidate(categoryTotalsProvider);
        AppFeedback.showSuccess(context, _transactionDeletedMessage);
      },
    ));
  }
}
