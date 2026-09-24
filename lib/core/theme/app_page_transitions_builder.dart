import 'package:flutter/material.dart';

import 'app_background.dart';
import 'app_motion.dart';

class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  static const double _initialScale = 0.97;

  const AppPageTransitionsBuilder();

  @override
  Duration get transitionDuration => AppMotion.normal;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final page = AppBackground(child: child);
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return page;
    }
    final curved = CurvedAnimation(parent: animation, curve: AppMotion.standard);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: _initialScale, end: 1).animate(curved),
        child: page,
      ),
    );
  }
}
