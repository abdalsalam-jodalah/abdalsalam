import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';

typedef ShellSidebarPanelBuilder = Widget Function(BuildContext context, double visibleWidth);

class ShellSidebarReveal extends StatelessWidget {
  final double visibleWidth;
  final double panelWidth;
  final bool slidesFromEdge;
  final ShellSidebarPanelBuilder panelBuilder;

  const ShellSidebarReveal({
    super.key,
    required this.visibleWidth,
    required this.panelWidth,
    required this.slidesFromEdge,
    required this.panelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.normal;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: visibleWidth),
      duration: duration,
      curve: AppMotion.standard,
      builder: (context, width, _) {
        if (width <= 0) {
          return const SizedBox.shrink();
        }
        if (!slidesFromEdge) {
          return ClipRect(
            child: SizedBox(width: width, child: panelBuilder(context, width)),
          );
        }
        return ClipRect(
          child: SizedBox(
            width: width,
            child: OverflowBox(
              alignment: Alignment.centerRight,
              minWidth: panelWidth,
              maxWidth: panelWidth,
              child: panelBuilder(context, panelWidth),
            ),
          ),
        );
      },
    );
  }
}
