import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';

class StatGrid extends StatelessWidget {
  static const double defaultMinTileWidth = 120;

  final List<Widget> children;
  final double minTileWidth;

  const StatGrid({super.key, required this.children, this.minTileWidth = defaultMinTileWidth});

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / minTileWidth).floor().clamp(1, children.isEmpty ? 1 : children.length);
        final tileWidth = (constraints.maxWidth - spacing.md * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing.md,
          runSpacing: spacing.md,
          children: [for (final child in children) SizedBox(width: tileWidth, child: child)],
        );
      },
    );
  }
}
