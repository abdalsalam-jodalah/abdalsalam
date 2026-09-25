import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/glass_surface.dart';

class ShellOpenHandle extends StatelessWidget {
  static const String _label = 'Open sidebar';
  static const double _width = 22;
  static const double _height = 64;
  static const double _iconSize = 18;

  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final ValueChanged<double> onVerticalDrag;

  const ShellOpenHandle({
    super.key,
    required this.onTap,
    required this.onDoubleTap,
    required this.onVerticalDrag,
  });

  @override
  Widget build(BuildContext context) {
    final radius = AppThemeTokens.of(context).radius;
    return Semantics(
      button: true,
      label: _label,
      child: GestureDetector(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onVerticalDragUpdate: (details) => onVerticalDrag(details.delta.dy),
        child: GlassSurface(
          isBlurred: true,
          borderRadius: BorderRadius.horizontal(right: Radius.circular(radius.md)),
          child: const SizedBox(
            width: _width,
            height: _height,
            child: Center(child: Icon(Icons.chevron_right_rounded, size: _iconSize)),
          ),
        ),
      ),
    );
  }
}
