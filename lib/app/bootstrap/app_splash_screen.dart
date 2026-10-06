import 'dart:async';

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
  static const double _progressWidth = 96;
  static const double _progressHeight = 3;
  static const double _progressBottomPadding = 64;
  static const double _progressTrackOpacity = 0.12;
  static const double _progressStart = 0.8;

  const AppSplashScreen({super.key});

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _SplashTile {
  final String assetName;
  final Offset direction;

  const _SplashTile({required this.assetName, required this.direction});
}

class _AppSplashScreenState extends State<AppSplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppSplashScreen._animationDuration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _progressBetween(double start, double end, [Curve curve = Curves.linear]) {
    final raw = ((_controller.value - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(raw);
  }

  Widget _buildTile(int index, _SplashTile tile) {
    final start = index * AppSplashScreen._tileStaggerStep;
    final progress = _progressBetween(start, start + AppSplashScreen._tileAnimationSpan, Curves.easeOutBack);
    final opacity = _progressBetween(start, start + AppSplashScreen._tileAnimationSpan / 2).clamp(0.0, 1.0);
    final travel = tile.direction * AppSplashScreen._tileTravelDistance * (1 - progress);
    final scale = AppSplashScreen._tileStartScale + (1 - AppSplashScreen._tileStartScale) * progress;
    return Opacity(
      opacity: opacity,
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

  Widget _buildProgress() {
    return Opacity(
      opacity: _progressBetween(AppSplashScreen._progressStart, 1),
      child: SizedBox(
        width: AppSplashScreen._progressWidth,
        height: AppSplashScreen._progressHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSplashScreen._progressHeight),
          child: LinearProgressIndicator(
            color: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: AppSplashScreen._progressTrackOpacity),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppSplashScreen.backgroundColor,
      child: AnimatedBuilder(
        animation: _controller,
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
              Positioned(
                bottom: AppSplashScreen._progressBottomPadding,
                child: _buildProgress(),
              ),
            ],
          );
        },
      ),
    );
  }
}
