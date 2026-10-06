import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class AppSplashScreen extends StatefulWidget {
  static const Color backgroundColor = Color(0xFF0F1226);
  static const String _appName = 'Abdalsalam';
  static const String _tagline = 'Your whole life, in one place';
  static const String _fontFamily = 'Inter';
  static const String _tileAssetPrefix = 'assets/branding/emblem_';
  static const List<_SplashTile> _tiles = <_SplashTile>[
    _SplashTile(assetName: 'top_left', direction: Offset(-1, -1)),
    _SplashTile(assetName: 'top_right', direction: Offset(1, -1)),
    _SplashTile(assetName: 'bottom_right', direction: Offset(1, 1)),
    _SplashTile(assetName: 'bottom_left', direction: Offset(-1, 1)),
  ];

  static const Duration _animationDuration = Duration(milliseconds: 1100);
  static const double _emblemSize = 160;
  static const double _tileTravelDistance = 28;
  static const double _tileStartScale = 0.7;
  static const double _tileStaggerStep = 0.09;
  static const double _tileAnimationSpan = 0.5;
  static const double _textStart = 0.55;
  static const double _textRiseDistance = 12;
  static const double _emblemToTextSpacing = 32;
  static const double _wordmarkOverflow = 120;
  static const double _taglineSpacing = 8;
  static const double _appNameFontSize = 28;
  static const double _taglineFontSize = 14;
  static const double _appNameLetterSpacing = 0.5;
  static const double _taglineOpacity = 0.6;
  static const Duration _loopDuration = Duration(milliseconds: 1600);
  static const double _loopStrengthStart = 0.8;
  static const double _loopMinimumOpacity = 0.3;
  static const double _loopMinimumScale = 0.92;

  const AppSplashScreen({super.key});

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _SplashTile {
  final String assetName;
  final Offset direction;

  const _SplashTile({required this.assetName, required this.direction});
}

class _AppSplashScreenState extends State<AppSplashScreen> with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppSplashScreen._animationDuration,
  );
  late final AnimationController _loopController = AnimationController(
    vsync: this,
    duration: AppSplashScreen._loopDuration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      _loopController.stop();
    } else if (!_controller.isAnimating && _controller.value == 0) {
      unawaited(_controller.forward());
      unawaited(_loopController.repeat());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _loopController.dispose();
    super.dispose();
  }

  double _progressBetween(double start, double end, [Curve curve = Curves.linear]) {
    final raw = ((_controller.value - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(raw);
  }

  double _loopPulse(int index) {
    final strength = _progressBetween(AppSplashScreen._loopStrengthStart, 1);
    final phase = (_loopController.value - index / AppSplashScreen._tiles.length) % 1;
    final dimness = 0.5 - 0.5 * cos(2 * pi * phase);
    return strength * dimness;
  }

  Widget _buildTile(int index, _SplashTile tile) {
    final start = index * AppSplashScreen._tileStaggerStep;
    final progress = _progressBetween(start, start + AppSplashScreen._tileAnimationSpan, Curves.easeOutBack);
    final opacity = _progressBetween(start, start + AppSplashScreen._tileAnimationSpan / 2).clamp(0.0, 1.0);
    final travel = tile.direction * AppSplashScreen._tileTravelDistance * (1 - progress);
    final introScale = AppSplashScreen._tileStartScale + (1 - AppSplashScreen._tileStartScale) * progress;
    final pulse = _loopPulse(index);
    final scale = introScale * (1 - pulse * (1 - AppSplashScreen._loopMinimumScale));
    return Opacity(
      opacity: opacity * (1 - pulse * (1 - AppSplashScreen._loopMinimumOpacity)),
      child: Transform.translate(
        offset: travel,
        child: Transform.scale(
          scale: scale,
          child: Image.asset(
            '${AppSplashScreen._tileAssetPrefix}${tile.assetName}.png',
            width: AppSplashScreen._emblemSize,
            height: AppSplashScreen._emblemSize,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }

  Widget _buildWordmark() {
    final progress = _progressBetween(AppSplashScreen._textStart, 1, Curves.easeOutCubic);
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(0, AppSplashScreen._textRiseDistance * (1 - progress)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              AppSplashScreen._appName,
              style: TextStyle(
                fontFamily: AppSplashScreen._fontFamily,
                fontSize: AppSplashScreen._appNameFontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: AppSplashScreen._appNameLetterSpacing,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: AppSplashScreen._taglineSpacing),
            Text(
              AppSplashScreen._tagline,
              style: TextStyle(
                fontFamily: AppSplashScreen._fontFamily,
                fontSize: AppSplashScreen._taglineFontSize,
                color: Colors.white.withValues(alpha: AppSplashScreen._taglineOpacity),
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppSplashScreen.backgroundColor,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_controller, _loopController]),
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: AppSplashScreen._emblemSize,
                height: AppSplashScreen._emblemSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var index = 0; index < AppSplashScreen._tiles.length; index++)
                      _buildTile(index, AppSplashScreen._tiles[index]),
                    Positioned(
                      top: AppSplashScreen._emblemSize + AppSplashScreen._emblemToTextSpacing,
                      left: -AppSplashScreen._wordmarkOverflow,
                      right: -AppSplashScreen._wordmarkOverflow,
                      child: _buildWordmark(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
