import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';

class TransactionPaymentMethodOption {
  final String label;
  final IconData icon;

  const TransactionPaymentMethodOption(this.label, this.icon);
}

class TransactionPaymentMethodSelector extends StatelessWidget {
  final List<TransactionPaymentMethodOption> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const TransactionPaymentMethodSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      children: [
        for (final option in options)
          FilterChip(
            selected: option.label == selected,
            onSelected: (_) => onSelected(option.label),
            avatar: Icon(option.icon),
            label: Text(option.label),
          ),
      ],
    );
  }
}
