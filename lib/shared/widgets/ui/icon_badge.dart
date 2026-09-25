import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';

class IconBadge extends StatelessWidget {
  static const double defaultSize = 44;
  static const double _iconSizeFactor = 0.5;
  static const double _backgroundOpacity = 0.16;

  final IconData icon;
  final Color? color;
  final double size;

  const IconBadge({super.key, required this.icon, this.color, this.size = defaultSize});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: _backgroundOpacity),
        borderRadius: tokens.radius.mediumBorder,
      ),
      child: Icon(icon, color: accent, size: size * _iconSizeFactor),
    );
  }
}
