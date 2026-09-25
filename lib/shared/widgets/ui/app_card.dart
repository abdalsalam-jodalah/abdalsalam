import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import 'glass_surface.dart';

class AppCard extends StatelessWidget {
  static const double _accentTintOpacity = 0.08;

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? accentColor;
  final bool isBlurred;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.accentColor,
    this.isBlurred = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    return GlassSurface(
      padding: padding ?? EdgeInsets.all(spacing.lg),
      tint: accentColor?.withValues(alpha: _accentTintOpacity),
      isBlurred: isBlurred,
      onTap: onTap,
      onLongPress: onLongPress,
      child: child,
    );
  }
}
