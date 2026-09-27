import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/financial/recurrence_pattern.dart';

class TransactionAdvancedOptions extends StatelessWidget {
  static const String _toggleLabel = 'Advanced Options';
  static const String _recurringLabel = 'Recurring Transaction';
  static const String _repeatLabel = 'Repeat';

  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final bool isRecurring;
  final ValueChanged<bool> onRecurringChanged;
  final RecurrencePattern recurrencePattern;
  final ValueChanged<RecurrencePattern> onPatternChanged;

  const TransactionAdvancedOptions({
    super.key,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.isRecurring,
    required this.onRecurringChanged,
    required this.recurrencePattern,
    required this.onPatternChanged,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggleExpanded,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: spacing.sm),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: spacing.sm),
                Text(_toggleLabel, style: theme.textTheme.titleSmall),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          SizedBox(height: spacing.sm),
          Row(
            children: [
              Expanded(child: Text(_recurringLabel, style: theme.textTheme.bodyMedium)),
              Switch(value: isRecurring, onChanged: onRecurringChanged),
            ],
          ),
          if (isRecurring) ...[
            SizedBox(height: spacing.sm),
            DropdownButtonFormField<RecurrencePattern>(
              initialValue: recurrencePattern,
              decoration: const InputDecoration(labelText: _repeatLabel),
              items: [
                for (final option in RecurrencePattern.values)
                  DropdownMenuItem(
                    value: option,
                    child: Text(option.name[0].toUpperCase() + option.name.substring(1)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) onPatternChanged(value);
              },
            ),
          ],
        ],
      ],
    );
  }
}
