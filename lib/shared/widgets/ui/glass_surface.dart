import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';

class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? tint;
  final bool isBlurred;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.tint,
    this.isBlurred = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final glass = tokens.glass;
    final radius = borderRadius ?? tokens.radius.largeBorder;
    final isHighContrast = MediaQuery.maybeHighContrastOf(context) ?? false;
    final surfaceColor = isHighContrast ? Theme.of(context).colorScheme.surfaceContainerHigh : glass.surfaceTint;
    final content = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: radius,
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );
    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        color: tint == null ? surfaceColor : Color.alphaBlend(tint!, surfaceColor),
        borderRadius: radius,
        border: Border.all(color: glass.borderColor),
        boxShadow: glass.shadows,
      ),
      child: ClipRRect(borderRadius: radius, child: content),
    );
    final shouldBlur = isBlurred && glass.isGlass && !isHighContrast && glass.blurSigma > 0;
    if (!shouldBlur) {
      return decorated;
    }
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: glass.blurSigma, sigmaY: glass.blurSigma),
        child: decorated,
      ),
    );
  }
}
