import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../theme/casino_theme.dart';

class ParticleWinEffect extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onComplete;

  const ParticleWinEffect({
    super.key,
    required this.isActive,
    this.onComplete,
  });

  @override
  State<ParticleWinEffect> createState() => _ParticleWinEffectState();
}

class _ParticleWinEffectState extends State<ParticleWinEffect> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<_Particle> _particles = [];
  final Random _random = Random();
  double _elapsedSeconds = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    if (widget.isActive) {
      _spawnParticles();
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(covariant ParticleWinEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _spawnParticles();
      _elapsedSeconds = 0.0;
      if (!_ticker.isTicking) {
        _ticker.start();
      }
    } else if (!widget.isActive && oldWidget.isActive) {
      _ticker.stop();
      _particles.clear();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _spawnParticles() {
    _particles.clear();
    // Spawn 60 particles bursting from center bottom of the screen
    for (int i = 0; i < 60; i++) {
      final double angle = -pi / 2 + (_random.nextDouble() - 0.5) * (pi / 3); // upward cone
      final double speed = 150 + _random.nextDouble() * 250;
      _particles.add(
        _Particle(
          x: 0.5, // Relative center x
          y: 0.9, // Near bottom
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          size: 6 + _random.nextDouble() * 14,
          color: _random.nextBool() ? CasinoTheme.primaryGold : CasinoTheme.accentNeonCyan,
          life: 1.5 + _random.nextDouble() * 1.0,
          rotation: _random.nextDouble() * pi * 2,
          rotationSpeed: (_random.nextDouble() - 0.5) * 6,
          isDollarSign: _random.nextBool(),
        ),
      );
    }
  }

  void _tick(Duration elapsed) {
    if (_particles.isEmpty) {
      _ticker.stop();
      widget.onComplete?.call();
      return;
    }

    final double dt = elapsed.inMicroseconds / Duration.microsecondsPerSecond - _elapsedSeconds;
    _elapsedSeconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;

    setState(() {
      for (int i = _particles.length - 1; i >= 0; i--) {
        final p = _particles[i];
        p.life -= dt;
        if (p.life <= 0) {
          _particles.removeAt(i);
          continue;
        }

        // Apply physics (gravity)
        p.vy += 220 * dt; // Gravity downward
        p.x += (p.vx * dt) / 400; // Relative translation scaling
        p.y += (p.vy * dt) / 600;
        p.rotation += p.rotationSpeed * dt;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive || _particles.isEmpty) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ParticlePainter(particles: _particles),
        ),
      ),
    );
  }
}

class _Particle {
  double x; // 0.0 to 1.0 relative width
  double y; // 0.0 to 1.0 relative height
  double vx;
  double vy;
  double size;
  Color color;
  double life;
  double rotation;
  double rotationSpeed;
  bool isDollarSign;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.life,
    required this.rotation,
    required this.rotationSpeed,
    required this.isDollarSign,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var p in particles) {
      final double px = p.x * size.width;
      final double py = p.y * size.height;
      if (px < 0 || px > size.width || py < 0 || py > size.height) continue;

      final double opacity = (p.life * 1.5).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation);

      if (p.isDollarSign) {
        // Draw elegant glowing dollar sign text
        textPainter.text = TextSpan(
          text: '\$',
          style: TextStyle(
            color: p.color.withValues(alpha: opacity),
            fontSize: p.size,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: p.color.withValues(alpha: opacity * 0.8),
                blurRadius: 5,
              ),
            ],
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      } else {
        // Draw 5-pointed star
        _drawStar(canvas, paint, p.size);
      }

      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, Paint paint, double size) {
    final Path path = Path();
    final double halfSize = size / 2;
    final double innerRadius = halfSize * 0.4;

    for (int i = 0; i < 5; i++) {
      // Outer point
      double outerAngle = (i * 2 * pi / 5) - pi / 2;
      double ox = cos(outerAngle) * halfSize;
      double oy = sin(outerAngle) * halfSize;
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }

      // Inner point
      double innerAngle = outerAngle + (pi / 5);
      double ix = cos(innerAngle) * innerRadius;
      double iy = sin(innerAngle) * innerRadius;
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
