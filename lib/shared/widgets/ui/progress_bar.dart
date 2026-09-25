import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';

class ProgressBar extends StatelessWidget {
  final double value;
  final Color? color;
  final double? height;

  const ProgressBar({super.key, required this.value, this.color, this.height});

  @override
  Widget build(BuildContext context) {
    final target = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
    final isAnimated = !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: target),
      duration: isAnimated ? AppMotion.slow : Duration.zero,
      curve: AppMotion.standard,
      builder: (context, animatedValue, _) => LinearProgressIndicator(
        value: animatedValue,
        color: color,
        minHeight: height,
      ),
    );
  }
}
