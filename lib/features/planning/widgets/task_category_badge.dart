import 'package:flutter/material.dart';

import '../../../core/formatting/hex_color.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/planning/task_category.dart';

class TaskCategoryBadge extends StatelessWidget {
  static const double _horizontalPadding = 8;
  static const double _verticalPadding = 2;
  static const double _fontSize = 12;

  final String name;
  final String colorHex;

  TaskCategoryBadge({super.key, required TaskCategory category}) : name = category.name, colorHex = category.color;

  const TaskCategoryBadge.preview({super.key, required this.name, required this.colorHex});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final background = HexColor.tryParse(colorHex) ?? HexColor.tryParse(TaskCategory.defaultColor)!;
    final foreground = ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: tokens.radius.pillBorder),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding, vertical: _verticalPadding),
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
            fontSize: _fontSize,
          ),
        ),
      ),
    );
  }
}
