import 'package:flutter/material.dart';

import '../../../core/theme/accent_option.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_theme_tokens.dart';

class AccentSwatchPicker extends StatelessWidget {
  static const double _swatchSize = 44;
  static const double _selectedRingWidth = 3;

  final List<AccentOption> options;
  final String selectedId;
  final ValueChanged<AccentOption> onSelected;

  const AccentSwatchPicker({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: spacing.md,
      runSpacing: spacing.md,
      children: [
        for (final option in options)
          Semantics(
            button: true,
            selected: option.id == selectedId,
            label: option.label,
            child: Tooltip(
              message: option.label,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onSelected(option),
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.standard,
                  width: _swatchSize,
                  height: _swatchSize,
                  decoration: BoxDecoration(
                    color: option.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: option.id == selectedId ? colorScheme.onSurface : colorScheme.surface,
                      width: _selectedRingWidth,
                    ),
                  ),
                  child: option.id == selectedId
                      ? Icon(Icons.check_rounded, color: colorScheme.surface)
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
