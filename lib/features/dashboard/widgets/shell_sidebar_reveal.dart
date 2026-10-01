import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';

class ShellSidebarReveal extends StatelessWidget {
  final double visibleWidth;
  final double panelWidth;
  final bool slidesFromEdge;
  final Widget child;

  const ShellSidebarReveal({
    super.key,
    required this.visibleWidth,
    required this.panelWidth,
    required this.slidesFromEdge,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.normal;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: visibleWidth),
      duration: duration,
      curve: AppMotion.standard,
      child: child,
      builder: (context, width, panel) {
        if (width <= 0) {
          return const SizedBox.shrink();
        }
        return ClipRect(
          child: SizedBox(
            width: width,
            child: OverflowBox(
              alignment: slidesFromEdge ? Alignment.centerRight : Alignment.centerLeft,
              minWidth: panelWidth,
              maxWidth: panelWidth,
              child: panel,
            ),
          ),
        );
      },
    );
  }
}
