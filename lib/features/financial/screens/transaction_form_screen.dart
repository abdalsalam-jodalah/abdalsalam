import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/financial/transaction_model.dart';
import '../../../data/models/financial/category_model.dart';
import '../../../data/models/financial/recurrence_pattern.dart';
import '../services/currency_service.dart';
import '../services/recurring_transaction_generator.dart';
import '../providers/financial_providers.dart';
import '../../../providers/app_providers.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/date_time_field.dart';
import '../widgets/transaction_advanced_options.dart';
import '../widgets/transaction_amount_input.dart';
import '../widgets/transaction_amount_preview.dart';
import '../widgets/transaction_category_selector.dart';
import '../widgets/transaction_delete_dialog.dart';
import '../widgets/transaction_payment_method_selector.dart';
import '../widgets/transaction_tags_input.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  static const routeName = '/financial/transaction-form';
  final TransactionModel? transaction;

  const TransactionFormScreen({super.key, this.transaction});

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  static const String _amountRequiredMessage = 'Amount is required';
  static const String _amountInvalidMessage = 'Enter a valid amount';
  static const String _amountPositiveMessage = 'Amount must be greater than 0';
  static const String _descriptionRequiredMessage = 'Description is required';
  static const String _selectCategoryMessage = 'Please select a category';
  static const String _transactionCreatedMessage = 'Transaction created successfully';
  static const String _transactionUpdatedMessage = 'Transaction updated successfully';
  static const Duration _validationSnackBarDuration = Duration(seconds: 2);
  static const double _emptyPreviewAmount = 0;
  static final DateTime _minimumTransactionDate = DateTime(2020);

  static const List<TransactionPaymentMethodOption> _paymentMethods = [
    TransactionPaymentMethodOption('Cash', Icons.money),
    TransactionPaymentMethodOption('Credit Card', Icons.credit_card),
    TransactionPaymentMethodOption('Debit Card', Icons.credit_card),
    TransactionPaymentMethodOption('Bank Transfer', Icons.account_balance),
    TransactionPaymentMethodOption('Mobile Payment', Icons.phone_android),
    TransactionPaymentMethodOption('Check', Icons.receipt),
  ];

  final _formKey = GlobalKey<FormState>();
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

    if (widget.transaction != null) {
      _selectedCurrency = Currency.values.firstWhere(
        (c) => c.code == widget.transaction!.currency,
        orElse: () => Currency.ils,
      );
    } else {
      unawaited(_loadDefaultCurrency());
    }
  }

  Future<void> _loadDefaultCurrency() async {
    final settings = await ref.read(settingsServiceProvider).getSettings();
    final storedCode = settings['currency'];
    final defaultCode = storedCode is String ? storedCode : null;
    final match = Currency.values.where((c) => c.code == defaultCode);
    if (match.isNotEmpty && mounted) {
      setState(() => _selectedCurrency = match.first);
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
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final amount = double.tryParse(_amountController.text) ?? _emptyPreviewAmount;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? 'Add Transaction' : 'Edit Transaction'),
        actions: [
          if (widget.transaction != null)
            IconButton(icon: const Icon(Icons.delete), onPressed: _deleteTransaction),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(tokens.spacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TransactionAmountPreview(
                amount: amount,
                isIncome: _type == TransactionType.income,
                currencyCode: _selectedCurrency.code,
                currencySymbol: _selectedCurrency.symbol,
              ),
              SizedBox(height: tokens.spacing.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Transaction Type', style: theme.textTheme.titleSmall),
                    SizedBox(height: tokens.spacing.sm),
                    SegmentedButton<TransactionType>(
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
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _type = newSelection.first;
                          _selectedCategoryId = null;
                        });
                      },
                    ),
                    SizedBox(height: tokens.spacing.lg),
                    Text('Amount', style: theme.textTheme.titleSmall),
                    SizedBox(height: tokens.spacing.sm),
                    TransactionAmountInput(
                      selectedCurrency: _selectedCurrency,
                      onCurrencyChanged: (currency) => setState(() => _selectedCurrency = currency),
                      amountController: _amountController,
                      onAmountChanged: (_) => setState(() {}),
                      validator: _validateAmount,
                    ),
                    SizedBox(height: tokens.spacing.lg),
                    Text('Description', style: theme.textTheme.titleSmall),
                    SizedBox(height: tokens.spacing.sm),
                    TextFormField(
                      controller: _descriptionController,
                      validator: _validateDescription,
                      maxLines: 2,
                      decoration: const InputDecoration(hintText: 'What did you spend on?'),
                    ),
                    SizedBox(height: tokens.spacing.lg),
                    Text('Category', style: theme.textTheme.titleSmall),
                    SizedBox(height: tokens.spacing.sm),
                    TransactionCategorySelector(
                      categoryType: _matchingCategoryType,
                      selectedCategoryId: _selectedCategoryId,
                      onChanged: (value) {
                        if (mounted) setState(() => _selectedCategoryId = value);
                      },
                    ),
                    SizedBox(height: tokens.spacing.lg),
                    DateTimeField(
                      label: 'Date',
                      value: _selectedDate,
                      mode: DateTimeFieldMode.date,
                      firstDate: _minimumTransactionDate,
                      lastDate: DateTime.now(),
                      onChanged: (date) {
                        if (date != null) setState(() => _selectedDate = date);
                      },
                    ),
                    SizedBox(height: tokens.spacing.lg),
                    Text('Payment Method', style: theme.textTheme.titleSmall),
                    SizedBox(height: tokens.spacing.sm),
                    TransactionPaymentMethodSelector(
                      options: _paymentMethods,
                      selected: _selectedPaymentMethod,
                      onSelected: (method) => setState(() => _selectedPaymentMethod = method),
                    ),
                    SizedBox(height: tokens.spacing.lg),
                    Text('Tags (Optional)', style: theme.textTheme.titleSmall),
                    SizedBox(height: tokens.spacing.sm),
                    TransactionTagsInput(
                      tags: _tags,
                      controller: _tagController,
                      onAdd: _addTag,
                      onRemove: (tag) => setState(() => _tags.remove(tag)),
                    ),
                    SizedBox(height: tokens.spacing.lg),
                    TransactionAdvancedOptions(
                      isExpanded: _showAdvanced,
                      onToggleExpanded: () => setState(() => _showAdvanced = !_showAdvanced),
                      isRecurring: _isRecurring,
                      onRecurringChanged: (value) => setState(() => _isRecurring = value),
                      recurrencePattern: _recurringPattern,
                      onPatternChanged: (value) => setState(() => _recurringPattern = value),
                    ),
                  ],
                ),
              ),
              SizedBox(height: tokens.spacing.xl),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final tokens = AppThemeTokens.of(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        SizedBox(width: tokens.spacing.md),
        Expanded(
          child: FilledButton(
            onPressed: _saveTransaction,
            child: Text(widget.transaction == null ? 'Create' : 'Update'),
          ),
        ),
      ],
    );
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

  CategoryType get _matchingCategoryType =>
      _type == TransactionType.income ? CategoryType.income : CategoryType.expense;

  String? _validateAmount(String? value) {
    final requiredError = ValidationUtils.requiredField(value, 'Amount');
    if (requiredError != null) return _amountRequiredMessage;
    final parsed = double.tryParse(value!.trim());
    if (parsed == null) return _amountInvalidMessage;
    return ValidationUtils.positiveNumber(value: parsed, fieldName: 'Amount') != null
        ? _amountPositiveMessage
        : null;
  }

  String? _validateDescription(String? value) {
    return ValidationUtils.requiredField(value, 'Description') != null
        ? _descriptionRequiredMessage
        : null;
  }

  Future<void> _saveTransaction() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedCategoryId == null) {
      _showValidationMessage(_selectCategoryMessage);
      return;
    }

    final amount = double.parse(_amountController.text.trim());
    final description = _descriptionController.text.trim();

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
    final result = isEditing
        ? await financialService.updateTransaction(transaction)
        : await financialService.createTransaction(transaction);

    if (!mounted) return;

    if (result.isSuccess) {
      AppFeedback.showSuccess(
        context,
        isEditing ? _transactionUpdatedMessage : _transactionCreatedMessage,
      );
      Navigator.pop(context, transaction);
    } else {
      AppFeedback.showError(context, result.error!);
    }
  }

  void _deleteTransaction() {
    unawaited(showDialog<void>(
      context: context,
      builder: (dialogContext) => TransactionDeleteDialog(
        onConfirm: () async {
          final result = await ref.read(financialServiceProvider).deleteTransaction(widget.transaction!.id);
          if (!dialogContext.mounted) return;

          if (result.isSuccess) {
            Navigator.pop(dialogContext);
            if (mounted) Navigator.pop(context, 'deleted');
          } else {
            AppFeedback.showError(dialogContext, result.error!);
          }
        },
      ),
    ));
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: _validationSnackBarDuration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
