// lib/features/financial/widgets/financial_icon_option_picker.dart: icon option picker for category and account forms.
import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_theme_tokens.dart';

class FinancialIconOptionPicker extends StatelessWidget {
  static const double _tileSize = 44;

  final List<IconData> options;
  final IconData selected;
  final Color accentColor;
  final ValueChanged<IconData> onSelected;

  const FinancialIconOptionPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.accentColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: tokens.spacing.sm,
      runSpacing: tokens.spacing.sm,
      children: [
        for (final icon in options)
          Semantics(
            button: true,
            selected: icon == selected,
            child: InkWell(
              borderRadius: tokens.radius.mediumBorder,
              onTap: () => onSelected(icon),
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.standard,
                width: _tileSize,
                height: _tileSize,
                decoration: BoxDecoration(
                  color: icon == selected ? accentColor.withValues(alpha: 0.2) : colorScheme.surfaceContainerHighest,
                  borderRadius: tokens.radius.mediumBorder,
                  border: Border.all(color: icon == selected ? accentColor : Colors.transparent),
                ),
                child: Icon(icon, color: icon == selected ? accentColor : colorScheme.onSurfaceVariant),
              ),
            ),
          ),
      ],
    );
  }
}
