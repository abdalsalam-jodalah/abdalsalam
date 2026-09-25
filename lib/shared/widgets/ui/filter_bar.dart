import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import 'filter_option.dart';

class FilterBar<T> extends StatelessWidget {
  final List<FilterOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  const FilterBar({super.key, required this.options, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options)
            Padding(
              padding: EdgeInsets.only(right: spacing.sm),
              child: ChoiceChip(
                label: Text(option.label),
                avatar: option.icon == null ? null : Icon(option.icon),
                selected: option.value == selected,
                showCheckmark: false,
                onSelected: (_) => onSelected(option.value),
              ),
            ),
        ],
      ),
    );
  }
}
