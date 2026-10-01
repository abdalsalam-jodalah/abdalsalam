import 'package:flutter/material.dart';

class ShellSwipeDetector extends StatefulWidget {
  static const double openDistance = 56;
  static const double openVelocity = 420;
  static const double closeDistance = 24;
  static const double closeVelocity = 300;

  final VoidCallback? onSwipeOpen;
  final VoidCallback? onSwipeClose;
  final Widget? child;

  const ShellSwipeDetector({
    super.key,
    this.onSwipeOpen,
    this.onSwipeClose,
    this.child,
  });

  @override
  State<ShellSwipeDetector> createState() => _ShellSwipeDetectorState();
}

class _ShellSwipeDetectorState extends State<ShellSwipeDetector> {
  double _dragDistance = 0;

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final distance = _dragDistance;
    _dragDistance = 0;
    final isOpenSwipe = distance >= ShellSwipeDetector.openDistance || velocity > ShellSwipeDetector.openVelocity;
    final isCloseSwipe = distance <= -ShellSwipeDetector.closeDistance || velocity < -ShellSwipeDetector.closeVelocity;
    if (isOpenSwipe) {
      widget.onSwipeOpen?.call();
    } else if (isCloseSwipe) {
      widget.onSwipeClose?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => _dragDistance = 0,
      onHorizontalDragUpdate: (details) => _dragDistance += details.delta.dx,
      onHorizontalDragEnd: _handleDragEnd,
      child: widget.child,
    );
  }
}
