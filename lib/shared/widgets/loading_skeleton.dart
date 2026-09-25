import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme_tokens.dart';

class LoadingSkeleton extends StatefulWidget {
  static const double _lineHeight = 56;
  static const Duration _shimmerDuration = Duration(milliseconds: 1400);

  final int lines;
  final bool isScrollable;

  const LoadingSkeleton({super.key, this.lines = 5, this.isScrollable = true});

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: LoadingSkeleton._shimmerDuration);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isAnimated = !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (isAnimated && !_controller.isAnimating) {
      unawaited(_controller.repeat());
    } else if (!isAnimated) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final base = colorScheme.surfaceContainerHighest;
    final highlight = colorScheme.surfaceContainerLowest;
    final items = [
      for (var i = 0; i < widget.lines; i++)
        Padding(
          padding: EdgeInsets.only(bottom: tokens.spacing.sm),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Container(
              height: LoadingSkeleton._lineHeight,
              decoration: BoxDecoration(
                borderRadius: tokens.radius.mediumBorder,
                gradient: LinearGradient(
                  begin: Alignment(-1 + _controller.value * 3, 0),
                  end: Alignment(_controller.value * 3, 0),
                  colors: [base, highlight, base],
                ),
              ),
            ),
          ),
        ),
    ];
    return Semantics(
      label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
      child: widget.isScrollable
          ? ListView(padding: EdgeInsets.all(tokens.spacing.lg), children: items)
          : Column(mainAxisSize: MainAxisSize.min, children: items),
    );
  }
}
