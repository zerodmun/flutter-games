import 'dart:math';
import 'package:flutter/material.dart';

enum ParticleType {
  trail,
  tapBurst,
  collisionBurst,
  confetti,
}

class GameParticle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  double life; // remaining life in seconds
  final double maxLife; // max life in seconds
  final ParticleType type;

  GameParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.maxLife,
    required this.type,
  }) : life = maxLife;

  bool update(double dt) {
    position += velocity * dt;
    life -= dt;
    
    // Apply drag to tap/collision bursts
    if (type == ParticleType.tapBurst || type == ParticleType.collisionBurst) {
      velocity *= 0.95;
    } else if (type == ParticleType.confetti) {
      // Add gravity-like fall to confetti
      velocity = Offset(velocity.dx, velocity.dy + 3.0 * dt);
    }
    
    return life > 0;
  }
}

class ParticleSystemManager {
  final List<GameParticle> particles = [];
  final Random random = Random();

  /// Spawns a trail particle behind an arrow's moving head
  void spawnTrail(Offset pos, Color color) {
    particles.add(
      GameParticle(
        position: pos,
        velocity: Offset(
          (random.nextDouble() - 0.5) * 0.5,
          (random.nextDouble() - 0.5) * 0.5,
        ),
        color: color.withValues(alpha: 0.7),
        size: 3.0 + random.nextDouble() * 2.0,
        maxLife: 0.4 + random.nextDouble() * 0.2,
        type: ParticleType.trail,
      ),
    );
  }

  /// Spawns a radial spark burst when an arrow is tapped
  void spawnTapBurst(Offset pos, Color color) {
    const int count = 12;
    for (int i = 0; i < count; i++) {
      final angle = (i * 2 * pi) / count + (random.nextDouble() - 0.5) * 0.3;
      final speed = 3.0 + random.nextDouble() * 4.0;
      particles.add(
        GameParticle(
          position: pos,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          color: color,
          size: 4.0 + random.nextDouble() * 3.0,
          maxLife: 0.5 + random.nextDouble() * 0.3,
          type: ParticleType.tapBurst,
        ),
      );
    }
  }

  /// Spawns a dramatic neon red burst at the collision site
  void spawnCollisionBurst(Offset pos) {
    const int count = 25;
    final collisionColor = const Color(0xFFFF2E93); // Neon Pink / Red
    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = 5.0 + random.nextDouble() * 8.0;
      particles.add(
        GameParticle(
          position: pos,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          color: random.nextBool() ? collisionColor : Colors.white,
          size: 5.0 + random.nextDouble() * 4.0,
          maxLife: 0.8 + random.nextDouble() * 0.4,
          type: ParticleType.collisionBurst,
        ),
      );
    }
  }

  /// Spawns victory confetti falling from the top
  void spawnVictoryConfetti(Size viewportSize) {
    final colors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFF00E5FF), // Neon Cyan
      const Color(0xFFFF2E93), // Neon Pink
      const Color(0xFF22C55E), // Emerald Green
    ];
    
    // Spawn 60 confetti particles at the top edge
    for (int i = 0; i < 60; i++) {
      particles.add(
        GameParticle(
          position: Offset(
            random.nextDouble() * viewportSize.width,
            -random.nextDouble() * 100, // spawn slightly above screen
          ),
          velocity: Offset(
            (random.nextDouble() - 0.5) * 2.0,
            2.0 + random.nextDouble() * 4.0,
          ),
          color: colors[random.nextInt(colors.length)],
          size: 5.0 + random.nextDouble() * 6.0,
          maxLife: 3.0 + random.nextDouble() * 2.0,
          type: ParticleType.confetti,
        ),
      );
    }
  }

  /// Updates all active particles. Removes expired ones.
  void update(double dt) {
    for (int i = particles.length - 1; i >= 0; i--) {
      final alive = particles[i].update(dt);
      if (!alive) {
        particles.removeAt(i);
      }
    }
  }

  /// Renders all particles on the canvas.
  /// Renders screen-space particles (confetti) and coordinate-space particles (trails/bursts).
  void paint(Canvas canvas, Function(Offset) toScreenSpace) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    for (final particle in particles) {
      final lifeRatio = particle.life / particle.maxLife;
      paint.color = particle.color.withValues(alpha: lifeRatio.clamp(0.0, 1.0));

      if (particle.type == ParticleType.confetti) {
        // Confetti is in screen-space, draw directly
        canvas.drawCircle(particle.position, particle.size, paint);
      } else {
        // Trails, Tap, and Collision bursts are in local grid coordinate-space, 
        // convert to screen-space first!
        final screenPos = toScreenSpace(particle.position);
        
        // Add a soft glow to trails and explosions
        if (particle.type == ParticleType.collisionBurst || particle.type == ParticleType.trail) {
          final glowPaint = Paint()
            ..color = paint.color.withValues(alpha: (lifeRatio * 0.3).clamp(0.0, 1.0))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
          canvas.drawCircle(screenPos, particle.size * 2.0, glowPaint);
        }
        
        canvas.drawCircle(screenPos, particle.size, paint);
      }
    }
  }

  void clear() {
    particles.clear();
  }
}
