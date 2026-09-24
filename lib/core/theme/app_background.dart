import 'package:flutter/material.dart';

import 'app_theme_tokens.dart';

class AppBackground extends StatelessWidget {
  static const double _orbOpacity = 0.22;
  static const double _darkOrbOpacity = 0.16;
  static const double _primaryOrbSizeFactor = 0.9;
  static const double _tertiaryOrbSizeFactor = 0.75;
  static const Alignment _primaryOrbAlignment = Alignment(-1.1, -1.05);
  static const Alignment _tertiaryOrbAlignment = Alignment(1.15, 0.85);

  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    if (!tokens.glass.isGlass) {
      return ColoredBox(color: colorScheme.surface, child: child);
    }
    final orbOpacity = colorScheme.brightness == Brightness.dark ? _darkOrbOpacity : _orbOpacity;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tokens.backgroundGradient,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final shortestSide = constraints.biggest.shortestSide;
                  return Stack(
                    children: [
                      _Orb(
                        alignment: _primaryOrbAlignment,
                        diameter: shortestSide * _primaryOrbSizeFactor,
                        color: colorScheme.primary.withValues(alpha: orbOpacity),
                      ),
                      _Orb(
                        alignment: _tertiaryOrbAlignment,
                        diameter: shortestSide * _tertiaryOrbSizeFactor,
                        color: colorScheme.tertiary.withValues(alpha: orbOpacity),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final Alignment alignment;
  final double diameter;
  final Color color;

  const _Orb({required this.alignment, required this.diameter, required this.color});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
