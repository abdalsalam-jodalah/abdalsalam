import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../services/currency_service.dart';

class TransactionAmountInput extends StatelessWidget {
  static const double _currencyFieldWidth = 104;
  static const String _amountHint = '0.00';

  final Currency selectedCurrency;
  final ValueChanged<Currency> onCurrencyChanged;
  final TextEditingController amountController;
  final ValueChanged<String> onAmountChanged;
  final String? Function(String?) validator;

  const TransactionAmountInput({
    super.key,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    required this.amountController,
    required this.onAmountChanged,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _currencyFieldWidth,
          child: DropdownButtonFormField<Currency>(
            initialValue: selectedCurrency,
            items: [
              for (final currency in Currency.values)
                DropdownMenuItem(value: currency, child: Text(currency.code, style: theme.textTheme.titleMedium)),
            ],
            onChanged: (value) {
              if (value != null) onCurrencyChanged(value);
            },
          ),
        ),
        SizedBox(width: spacing.md),
        Expanded(
          child: TextFormField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: onAmountChanged,
            validator: validator,
            style: theme.textTheme.titleMedium,
            decoration: InputDecoration(
              hintText: _amountHint,
              prefixText: '${selectedCurrency.symbol} ',
              prefixStyle: theme.textTheme.titleMedium,
            ),
          ),
        ),
      ],
    );
  }
}
