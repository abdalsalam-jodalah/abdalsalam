import 'package:flutter/material.dart';

import '../../../core/formatting/hex_color.dart';
import '../../../core/theme/app_theme_tokens.dart';
import 'task_category_palette.dart';

class TaskCategoryPalettePicker extends StatelessWidget {
  static const double _swatchSize = 34;
  static const double _checkSize = 18;

  final String selectedColor;
  final ValueChanged<String> onChanged;

  const TaskCategoryPalettePicker({super.key, required this.selectedColor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      children: [
        for (final hex in TaskCategoryPalette.presets)
          Semantics(
            button: true,
            selected: hex == selectedColor,
            label: 'Color $hex',
            child: InkWell(
              key: ValueKey('category-color-$hex'),
              customBorder: const CircleBorder(),
              onTap: () => onChanged(hex),
              child: Container(
                width: _swatchSize,
                height: _swatchSize,
                decoration: BoxDecoration(color: HexColor.tryParse(hex), shape: BoxShape.circle),
                child: hex == selectedColor
                    ? Icon(
                        Icons.check_rounded,
                        size: _checkSize,
                        color: ThemeData.estimateBrightnessForColor(HexColor.tryParse(hex)!) == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
