import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/casino_theme.dart';

/// A full-screen animated casino background with drifting golden particles
/// over a deep radial gradient. Drop this behind any screen's body for a
/// premium ambient effect.
///
/// Usage:
/// ```dart
/// Stack(
///   children: [
///     const AnimatedCasinoBackground(),
///     // …your screen content
///   ],
/// )
/// ```
class AnimatedCasinoBackground extends StatefulWidget {
  /// Primary gradient center color.
  final Color? gradientCenterColor;

  /// Outer gradient edge color.
  final Color? gradientEdgeColor;

  /// Color of the floating particles. Defaults to [CasinoTheme.primaryGold].
  final Color? particleColor;

  /// Number of particles to render.
  final int particleCount;

  const AnimatedCasinoBackground({
    super.key,
    this.gradientCenterColor,
    this.gradientEdgeColor,
    this.particleColor,
    this.particleCount = 50,
  });

  @override
  State<AnimatedCasinoBackground> createState() =>
      _AnimatedCasinoBackgroundState();
}

class _AnimatedCasinoBackgroundState extends State<AnimatedCasinoBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _particles = List.generate(
      widget.particleCount,
      (_) => _Particle.random(_rng),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final centerColor =
        widget.gradientCenterColor ?? CasinoTheme.bgDark;
    final edgeColor =
        widget.gradientEdgeColor ?? CasinoTheme.bgDarker;
    final particleColor =
        widget.particleColor ?? CasinoTheme.primaryGold;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _CasinoBackgroundPainter(
              particles: _particles,
              animationValue: _controller.value,
              centerColor: centerColor,
              edgeColor: edgeColor,
              particleColor: particleColor,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Particle data class
// ---------------------------------------------------------------------------

class _Particle {
  /// Normalised x position (0..1).
  final double x;

  /// Normalised y position (0..1).
  final double y;

  /// Radius in logical pixels.
  final double radius;

  /// Individual speed multiplier.
  final double speed;

  /// Random phase offset so particles don't move in sync.
  final double phaseOffset;

  /// Base opacity (0..1).
  final double opacity;

  const _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.phaseOffset,
    required this.opacity,
  });

  factory _Particle.random(math.Random rng) {
    return _Particle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      radius: 1.0 + rng.nextDouble() * 2.5,
      speed: 0.3 + rng.nextDouble() * 0.7,
      phaseOffset: rng.nextDouble() * 2 * math.pi,
      opacity: 0.15 + rng.nextDouble() * 0.55,
    );
  }
}

// ---------------------------------------------------------------------------
// CustomPainter – gradient + floating particles
// ---------------------------------------------------------------------------

class _CasinoBackgroundPainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;
  final Color centerColor;
  final Color edgeColor;
  final Color particleColor;

  _CasinoBackgroundPainter({
    required this.particles,
    required this.animationValue,
    required this.centerColor,
    required this.edgeColor,
    required this.particleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGradient(canvas, size);
    _drawParticles(canvas, size);
  }

  void _drawGradient(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint gradientPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: [centerColor, edgeColor],
        stops: const [0.0, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, gradientPaint);
  }

  void _drawParticles(Canvas canvas, Size size) {
    final double time = animationValue * 2 * math.pi;

    for (final p in particles) {
      // Slow sinusoidal drift in both axes
      final double dx =
          math.sin(time * p.speed + p.phaseOffset) * size.width * 0.03;
      final double dy =
          math.cos(time * p.speed * 0.7 + p.phaseOffset) * size.height * 0.04;

      // Wrap-around y movement simulating slow upward float
      final double baseY =
          ((p.y + animationValue * p.speed * 0.15) % 1.0) * size.height;

      final double px = p.x * size.width + dx;
      final double py = baseY + dy;

      // Pulsing opacity for a gentle twinkling effect
      final double pulse =
          0.5 + 0.5 * math.sin(time * 2.0 * p.speed + p.phaseOffset);
      final double alpha = (p.opacity * pulse).clamp(0.0, 1.0);

      final Paint dotPaint = Paint()
        ..color = particleColor.withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 0.8);

      canvas.drawCircle(Offset(px, py), p.radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CasinoBackgroundPainter oldDelegate) {
    // Only the animation value changes frame-to-frame; always repaint.
    return oldDelegate.animationValue != animationValue;
  }
}
