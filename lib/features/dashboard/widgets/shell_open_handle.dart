import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/glass_surface.dart';

class ShellOpenHandle extends StatefulWidget {
  static const String _label = 'Open sidebar';
  static const double _visibleWidth = 22;
  static const double _visibleHeight = 64;
  static const double _iconSize = 18;
  static const double hitWidth = 48;
  static const double hitHeight = 96;
  static const double _openDragDistance = 24;
  static const double _openDragVelocity = 300;

  final VoidCallback onOpen;
  final ValueChanged<double> onVerticalDrag;

  const ShellOpenHandle({
    super.key,
    required this.onOpen,
    required this.onVerticalDrag,
  });

  @override
  State<ShellOpenHandle> createState() => _ShellOpenHandleState();
}

class _ShellOpenHandleState extends State<ShellOpenHandle> {
  double _horizontalDrag = 0;

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final isFarEnough = _horizontalDrag >= ShellOpenHandle._openDragDistance;
    final isFastEnough = (details.primaryVelocity ?? 0) >= ShellOpenHandle._openDragVelocity;
    _horizontalDrag = 0;
    if (isFarEnough || isFastEnough) {
      widget.onOpen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = AppThemeTokens.of(context).radius;
    return Semantics(
      button: true,
      label: ShellOpenHandle._label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpen,
        onHorizontalDragStart: (_) => _horizontalDrag = 0,
        onHorizontalDragUpdate: (details) => _horizontalDrag += details.delta.dx,
        onHorizontalDragEnd: _handleHorizontalDragEnd,
        onVerticalDragUpdate: (details) => widget.onVerticalDrag(details.delta.dy),
        child: SizedBox(
          width: ShellOpenHandle.hitWidth,
          height: ShellOpenHandle.hitHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: GlassSurface(
              isBlurred: true,
              borderRadius: BorderRadius.horizontal(right: Radius.circular(radius.md)),
              child: const SizedBox(
                width: ShellOpenHandle._visibleWidth,
                height: ShellOpenHandle._visibleHeight,
                child: Center(child: Icon(Icons.chevron_right_rounded, size: ShellOpenHandle._iconSize)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
