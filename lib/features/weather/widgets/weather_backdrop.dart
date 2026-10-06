import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/weather_condition.dart';

class WeatherBackdrop extends StatefulWidget {
  static const Duration _cycle = Duration(seconds: 12);

  final WeatherCondition condition;
  final bool isNight;
  final bool isAnimated;

  const WeatherBackdrop({super.key, required this.condition, required this.isNight, this.isAnimated = true});

  @override
  State<WeatherBackdrop> createState() => _WeatherBackdropState();
}

class _WeatherBackdropState extends State<WeatherBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: WeatherBackdrop._cycle);

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(WeatherBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.isAnimated) {
      if (!_controller.isAnimating) unawaited(_controller.repeat());
    } else {
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
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _BackdropPainter(condition: widget.condition, isNight: widget.isNight, animation: _controller),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  static const int _particleCount = 26;
  static const double _tau = math.pi * 2;

  final WeatherCondition condition;
  final bool isNight;
  final Animation<double> animation;
  final List<_Particle> _particles;

  _BackdropPainter({required this.condition, required this.isNight, required this.animation})
    : _particles = _buildParticles(),
      super(repaint: animation);

  static List<_Particle> _buildParticles() {
    final random = math.Random(7);
    return List<_Particle>.generate(
      _particleCount,
      (_) => _Particle(
        x: random.nextDouble(),
        phase: random.nextDouble(),
        speed: 0.6 + random.nextDouble() * 0.8,
        size: 0.5 + random.nextDouble(),
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    switch (condition) {
      case WeatherCondition.clear:
        isNight ? _paintStars(canvas, size, t) : _paintSun(canvas, size, t);
      case WeatherCondition.partlyCloudy:
        isNight ? _paintStars(canvas, size, t) : _paintSun(canvas, size, t);
        _paintClouds(canvas, size, t);
      case WeatherCondition.rain:
        _paintClouds(canvas, size, t);
        _paintRain(canvas, size, t);
      case WeatherCondition.thunderstorm:
        _paintClouds(canvas, size, t);
        _paintRain(canvas, size, t);
        _paintLightning(canvas, size, t);
      case WeatherCondition.snow:
        _paintClouds(canvas, size, t);
        _paintSnow(canvas, size, t);
      case WeatherCondition.fog:
        _paintFog(canvas, size, t);
    }
  }

  void _paintSun(Canvas canvas, Size size, double t) {
    final pulse = 0.85 + 0.15 * math.sin(t * _tau);
    final center = Offset(size.width * 0.82, size.height * 0.2);
    final radius = size.shortestSide * 0.75 * pulse;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFFFE9A8).withValues(alpha: 0.55), const Color(0x00FFE9A8)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  void _paintStars(Canvas canvas, Size size, double t) {
    final paint = Paint();
    for (final particle in _particles) {
      final twinkle = 0.4 + 0.6 * (0.5 + 0.5 * math.sin((t + particle.phase) * _tau * particle.speed));
      paint.color = Colors.white.withValues(alpha: 0.7 * twinkle);
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.phase * size.height * 0.7),
        particle.size,
        paint,
      );
    }
  }

  void _paintClouds(Canvas canvas, Size size, double t) {
    final paint = Paint()..color = Colors.white.withValues(alpha: isNight ? 0.08 : 0.16);
    for (var index = 0; index < 3; index++) {
      final drift = ((t * (0.3 + index * 0.12) + index * 0.37) % 1.0);
      final x = (drift * 1.6 - 0.3) * size.width;
      final y = size.height * (0.14 + index * 0.2);
      final width = size.width * (0.45 - index * 0.06);
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: width, height: width * 0.32), paint);
    }
  }

  void _paintRain(Canvas canvas, Size size, double t) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (final particle in _particles) {
      final progress = (t * particle.speed * 3 + particle.phase) % 1.0;
      final x = particle.x * size.width + progress * 18;
      final y = progress * (size.height + 24) - 12;
      canvas.drawLine(Offset(x, y), Offset(x - 4, y + 12 * particle.size), paint);
    }
  }

  void _paintSnow(Canvas canvas, Size size, double t) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.75);
    for (final particle in _particles) {
      final progress = (t * particle.speed + particle.phase) % 1.0;
      final sway = math.sin((progress + particle.phase) * _tau * 2) * 10;
      canvas.drawCircle(
        Offset(particle.x * size.width + sway, progress * size.height),
        1.5 + particle.size * 1.6,
        paint,
      );
    }
  }

  void _paintFog(Canvas canvas, Size size, double t) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.12);
    for (var index = 0; index < 4; index++) {
      final drift = math.sin((t + index * 0.25) * _tau) * size.width * 0.08;
      final top = size.height * (0.12 + index * 0.22);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-20 + drift, top, size.width + 40, size.height * 0.1),
          const Radius.circular(24),
        ),
        paint,
      );
    }
  }

  void _paintLightning(Canvas canvas, Size size, double t) {
    final flash = math.max(0.0, math.sin(t * _tau * 3)) - 0.92;
    if (flash <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white.withValues(alpha: flash * 5));
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) {
    return oldDelegate.condition != condition || oldDelegate.isNight != isNight;
  }
}

class _Particle {
  final double x;
  final double phase;
  final double speed;
  final double size;

  const _Particle({required this.x, required this.phase, required this.speed, required this.size});
}
