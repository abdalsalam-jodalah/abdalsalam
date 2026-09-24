import 'package:flutter/material.dart';

import 'app_theme_tokens.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    if (!tokens.glass.isGlass) {
      return ColoredBox(color: Theme.of(context).colorScheme.surface, child: child);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tokens.backgroundGradient,
        ),
      ),
      child: child,
    );
  }
}
