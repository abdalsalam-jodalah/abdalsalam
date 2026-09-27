// lib/features/financial/widgets/financial_color_swatch_picker.dart: circular colour swatch picker for category and account forms.
import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_theme_tokens.dart';

class FinancialColorSwatchPicker extends StatelessWidget {
  static const double _swatchSize = 36;
  static const double _selectedRingWidth = 2;

  final List<Color> options;
  final Color selected;
  final ValueChanged<Color> onSelected;

  const FinancialColorSwatchPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      children: [
        for (final color in options)
          Semantics(
            button: true,
            selected: color.toARGB32() == selected.toARGB32(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => onSelected(color),
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.standard,
                width: _swatchSize,
                height: _swatchSize,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.toARGB32() == selected.toARGB32() ? colorScheme.onSurface : Colors.transparent,
                    width: _selectedRingWidth,
                  ),
                ),
                child: color.toARGB32() == selected.toARGB32()
                    ? Icon(Icons.check_rounded, color: colorScheme.surface)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
