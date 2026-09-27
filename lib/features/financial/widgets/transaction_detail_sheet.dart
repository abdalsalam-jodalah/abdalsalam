// lib/features/financial/widgets/transaction_detail_sheet.dart: bottom sheet body showing a transaction's details with edit/delete actions.
import 'package:flutter/material.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/financial/transaction_model.dart';

class TransactionDetailSheet extends StatelessWidget {
  static const String _amountCurrencySymbol = '\$';
  static const double _labelWidth = 120;

  final TransactionModel transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TransactionDetailSheet({
    super.key,
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailRow(
          label: 'Amount',
          value: '$_amountCurrencySymbol${transaction.amount.toStringAsFixed(2)}',
        ),
        _DetailRow(label: 'Type', value: transaction.type.name),
        _DetailRow(label: 'Description', value: transaction.description),
        _DetailRow(label: 'Date', value: AppDateFormatter.date(transaction.date)),
        if (transaction.paymentMethod != null)
          _DetailRow(label: 'Payment Method', value: transaction.paymentMethod!),
        if (transaction.tags.isNotEmpty) _DetailRow(label: 'Tags', value: transaction.tags.join(', ')),
        SizedBox(height: tokens.spacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit'),
              ),
            ),
            SizedBox(width: tokens.spacing.sm),
            Expanded(
              child: FilledButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_rounded),
                label: const Text('Delete'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: TransactionDetailSheet._labelWidth,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
