import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/financial/transaction_model.dart';
import '../../../data/models/financial/category_model.dart';
import '../../../data/models/financial/recurrence_pattern.dart';
import '../services/currency_service.dart';
import '../services/recurring_transaction_generator.dart';
import '../providers/financial_providers.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  static const routeName = '/financial/transaction-form';
  final TransactionModel? transaction;

  const TransactionFormScreen({super.key, this.transaction});

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;

  TransactionType _type = TransactionType.expense;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  String _selectedPaymentMethod = 'Cash';
  Currency _selectedCurrency = Currency.ils; // Default to ILS
  List<String> _tags = [];
  final _tagController = TextEditingController();
  bool _isRecurring = false;
  RecurrencePattern _recurringPattern = RecurrencePattern.monthly;
  bool _showAdvanced = false;

  final _paymentMethods = [
    ('Cash', Icons.money),
    ('Credit Card', Icons.credit_card),
    ('Debit Card', Icons.credit_card),
    ('Bank Transfer', Icons.account_balance),
    ('Mobile Payment', Icons.phone_android),
    ('Check', Icons.receipt),
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.transaction?.description ?? '',
    );
    _amountController = TextEditingController(
      text: widget.transaction?.amount.toString() ?? '',
    );
    _type = widget.transaction?.type ?? TransactionType.expense;
    _selectedCategoryId = widget.transaction?.categoryId;
    _selectedDate = widget.transaction?.date ?? DateTime.now();
    _selectedPaymentMethod = widget.transaction?.paymentMethod ?? 'Cash';
    _tags = List.from(widget.transaction?.tags ?? []);
    _isRecurring = widget.transaction?.isRecurring ?? false;
    _recurringPattern = widget.transaction?.recurrence ?? RecurrencePattern.monthly;

    // Parse currency from transaction
    if (widget.transaction != null) {
      try {
        _selectedCurrency = Currency.values.firstWhere(
          (c) => c.code == widget.transaction!.currency,
          orElse: () => Currency.ils,
        );
      } catch (e) {
        _selectedCurrency = Currency.ils;
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? 'Add Transaction' : 'Edit Transaction'),
        elevation: 0,
        actions: [
          if (widget.transaction != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteTransaction,
            ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
          ),
          // Form content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick amount display
                _buildAmountPreview(),
                const SizedBox(height: 24),

                // Transaction Type Selector
                _buildTypeSelector(),
                const SizedBox(height: 24),

                // Amount Input
                _buildAmountInput(),
                const SizedBox(height: 20),

                // Description Input
                _buildDescriptionInput(),
                const SizedBox(height: 20),

                // Category Selector with icons
                _buildCategorySelector(),
                const SizedBox(height: 20),

                // Date Picker
                _buildDatePicker(),
                const SizedBox(height: 20),

                // Payment Method with icons
                _buildPaymentMethodSelector(),
                const SizedBox(height: 20),

                // Tags
                _buildTagsInput(),
                const SizedBox(height: 20),

                // Advanced Options
                _buildAdvancedOptions(),
                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButtons(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountPreview() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final isIncome = _type == TransactionType.income;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isIncome
                ? Colors.green.withValues(alpha: 0.8)
                : Colors.red.withValues(alpha: 0.8),
            isIncome
                ? Colors.green.withValues(alpha: 0.6)
                : Colors.red.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isIncome ? Colors.green : Colors.red).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isIncome ? 'Income' : 'Expense',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                isIncome ? '+' : '-',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${_selectedCurrency.symbol}${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _selectedCurrency.code,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaction Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(
                value: TransactionType.expense,
                label: Text('Expense'),
                icon: Icon(Icons.arrow_upward),
              ),
              ButtonSegment(
                value: TransactionType.income,
                label: Text('Income'),
                icon: Icon(Icons.arrow_downward),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (Set<TransactionType> newSelection) {
              setState(() {
                _type = newSelection.first;
                _selectedCategoryId = null;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Currency Selector
            Container(
              width: 100,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.withValues(alpha: 0.05),
              ),
              child: DropdownButtonFormField<Currency>(
                initialValue: _selectedCurrency,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
                items: Currency.values.map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Text(
                      currency.code,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCurrency = value);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            // Amount Input
            Expanded(
              child: TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: '${_selectedCurrency.symbol} ',
                  prefixStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.05),
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: 'What did you spend on?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            filled: true,
            fillColor: Colors.grey.withValues(alpha: 0.05),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        categoriesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, stack) => Text('Failed to load categories: $error'),
          data: (allCategories) {
            final matchingType =
                allCategories.where((c) => c.type == _matchingCategoryType).toList();

            if (matchingType.isEmpty) {
              return Text(
                'No categories yet — add one from the Categories tab first.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              );
            }

            final selectedId = matchingType.any((c) => c.id == _selectedCategoryId)
                ? _selectedCategoryId
                : matchingType.first.id;
            if (selectedId != _selectedCategoryId) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _selectedCategoryId = selectedId);
              });
            }
            final selectedCategory = matchingType.firstWhere((c) => c.id == selectedId);

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
                color: Colors.grey.withValues(alpha: 0.05),
              ),
              child: DropdownButtonFormField<String>(
                initialValue: selectedId,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      selectedCategory.icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                items: matchingType
                    .map((category) => DropdownMenuItem(
                          value: category.id,
                          child: Row(
                            children: [
                              Icon(category.icon, size: 20),
                              const SizedBox(width: 12),
                              Text(category.name),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategoryId = value);
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }

  CategoryType get _matchingCategoryType =>
      _type == TransactionType.income ? CategoryType.income : CategoryType.expense;

  Widget _buildDatePicker() {
    final formatter = DateFormat('MMM dd, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.withValues(alpha: 0.05),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  formatter.format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.edit,
                  size: 18,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _paymentMethods.map((method) {
            final isSelected = _selectedPaymentMethod == method.$1;
            return FilterChip(
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedPaymentMethod = method.$1);
              },
              avatar: Icon(method.$2, size: 18),
              label: Text(method.$1),
              backgroundColor: Colors.grey.withValues(alpha: 0.1),
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTagsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (_tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags
                .map((tag) => Chip(
                      label: Text(tag),
                      onDeleted: () {
                        setState(() => _tags.remove(tag));
                      },
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withValues(alpha: 0.5),
                    ))
                .toList(),
          ),
        if (_tags.isNotEmpty) const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: 'Add a tag',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.05),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _addTag,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showAdvanced = !_showAdvanced),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(
                  _showAdvanced ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Advanced Options',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showAdvanced) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.withValues(alpha: 0.05),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: const Text(
                        'Recurring Transaction',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isRecurring,
                      onChanged: (value) {
                        setState(() => _isRecurring = value);
                      },
                    ),
                  ],
                ),
                if (_isRecurring) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<RecurrencePattern>(
                    initialValue: _recurringPattern,
                    decoration: InputDecoration(
                      labelText: 'Repeat',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: RecurrencePattern.values
                        .map((option) => DropdownMenuItem(
                              value: option,
                              child: Text(
                                option.name[0].toUpperCase() + option.name.substring(1),
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _recurringPattern = value);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _saveTransaction,
            child: Text(widget.transaction == null ? 'Create' : 'Update'),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  Future<void> _saveTransaction() async {
    final amount = double.tryParse(_amountController.text);
    final description = _descriptionController.text.trim();

    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    if (description.isEmpty) {
      _showError('Please enter a description');
      return;
    }

    if (_selectedCategoryId == null) {
      _showError('Please select a category');
      return;
    }

    final transaction = TransactionModel(
      id: widget.transaction?.id ?? const Uuid().v4(),
      userId: 'user1',
      type: _type,
      amount: amount,
      currency: _selectedCurrency.code,
      categoryId: _selectedCategoryId!,
      date: _selectedDate,
      description: description,
      tags: _tags,
      paymentMethod: _selectedPaymentMethod,
      isRecurring: _isRecurring,
      recurringPattern: _isRecurring ? _recurringPattern.name : null,
      recurrenceNextDueDate: _isRecurring
          ? (widget.transaction?.recurrenceNextDueDate ??
              RecurringTransactionGenerator.nextDueDate(_selectedDate, _recurringPattern))
          : null,
      createdAt: widget.transaction?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final financialService = ref.read(financialServiceProvider);
    final isEditing = widget.transaction != null;
    final isSuccess = isEditing
        ? (await financialService.updateTransaction(transaction)).isSuccess
        : (await financialService.createTransaction(transaction)).isSuccess;

    if (!mounted) return;

    if (isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? 'Transaction updated successfully' : 'Transaction created successfully',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, transaction);
    } else {
      _showError('Failed to save transaction');
    }
  }

  void _deleteTransaction() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final result = await ref
                  .read(financialServiceProvider)
                  .deleteTransaction(widget.transaction!.id);
              navigator.pop();
              if (result.isSuccess) {
                navigator.pop('deleted');
              }
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
