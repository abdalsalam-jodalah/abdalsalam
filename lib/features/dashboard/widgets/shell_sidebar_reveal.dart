import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';

typedef ShellSidebarPanelBuilder = Widget Function(BuildContext context, double visibleWidth);

class ShellSidebarReveal extends StatefulWidget {
  static const Duration openDuration = AppMotion.normal;
  static const Duration closeDuration = AppMotion.slow;
  static const Curve openCurve = AppMotion.standard;
  static const Curve closeCurve = AppMotion.smooth;

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
  State<ShellSidebarReveal> createState() => _ShellSidebarRevealState();
}

class _ShellSidebarRevealState extends State<ShellSidebarReveal> {
  bool _isShrinking = false;

  @override
  void didUpdateWidget(ShellSidebarReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visibleWidth != oldWidget.visibleWidth) {
      _isShrinking = widget.visibleWidth < oldWidget.visibleWidth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMotionReduced = MediaQuery.disableAnimationsOf(context);
    final duration = isMotionReduced
        ? Duration.zero
        : (_isShrinking ? ShellSidebarReveal.closeDuration : ShellSidebarReveal.openDuration);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: widget.visibleWidth),
      duration: duration,
      curve: _isShrinking ? ShellSidebarReveal.closeCurve : ShellSidebarReveal.openCurve,
      builder: (context, width, _) {
        if (width <= 0) {
          return const SizedBox.shrink();
        }
        if (!widget.slidesFromEdge) {
          return ClipRect(
            child: SizedBox(width: width, child: widget.panelBuilder(context, width)),
          );
        }
        return ClipRect(
          child: SizedBox(
            width: width,
            child: OverflowBox(
              alignment: Alignment.centerRight,
              minWidth: widget.panelWidth,
              maxWidth: widget.panelWidth,
              child: widget.panelBuilder(context, widget.panelWidth),
            ),
          ),
        );
      },
    );
  }
}
