import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';

class ProgressRing extends StatelessWidget {
  static const double defaultSize = 64;
  static const double _strokeFactor = 0.11;

  final double value;
  final double size;
  final Color? color;
  final Widget? center;

  const ProgressRing({super.key, required this.value, this.size = defaultSize, this.color, this.center});

  @override
  Widget build(BuildContext context) {
    final target = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
    final isAnimated = !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: target),
            duration: isAnimated ? AppMotion.slow : Duration.zero,
            curve: AppMotion.standard,
            builder: (context, animatedValue, _) => SizedBox.square(
              dimension: size,
              child: CircularProgressIndicator(
                value: animatedValue,
                color: color,
                strokeWidth: size * _strokeFactor,
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          ?center,
        ],
      ),
    );
  }
}
