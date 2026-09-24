import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';

class AppearanceSegmentOption<T> {
  final T value;
  final String label;
  final IconData? icon;

  const AppearanceSegmentOption(this.value, this.label, {this.icon});
}

class AppearanceSegmentedSetting<T extends Object> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final T value;
  final List<AppearanceSegmentOption<T>> options;
  final ValueChanged<T> onChanged;

  const AppearanceSegmentedSetting({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleSmall),
          if (subtitle != null)
            Text(subtitle!, style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          SizedBox(height: spacing.sm),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<T>(
              showSelectedIcon: false,
              segments: [
                for (final option in options)
                  ButtonSegment<T>(
                    value: option.value,
                    label: Text(option.label),
                    icon: option.icon == null ? null : Icon(option.icon),
                  ),
              ],
              selected: <T>{value},
              onSelectionChanged: (selection) => onChanged(selection.first),
            ),
          ),
        ],
      ),
    );
  }
}
