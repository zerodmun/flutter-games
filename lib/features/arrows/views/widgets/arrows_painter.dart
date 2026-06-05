import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/arrows_models.dart';
import '../../services/collision_engine.dart';
import 'particle_system.dart';

class ArrowsPainter extends CustomPainter {
  final List<ArrowModel> arrows;
  final ParticleSystemManager particleSystem;
  final Offset? collisionPoint;
  final int levelId;

  ArrowsPainter({
    required this.arrows,
    required this.particleSystem,
    this.collisionPoint,
    required this.levelId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Calculate level bounds to frame the screen automatically
    double minX = -8.0;
    double maxX = 8.0;
    double minY = -8.0;
    double maxY = 8.0;

    for (final arrow in arrows) {
      for (final pt in arrow.path.points) {
        if (pt.dx < minX) minX = pt.dx;
        if (pt.dx > maxX) maxX = pt.dx;
        if (pt.dy < minY) minY = pt.dy;
        if (pt.dy > maxY) maxY = pt.dy;
      }
    }

    // Add margin
    minX -= 1.0;
    maxX += 1.0;
    minY -= 1.0;
    maxY += 1.0;

    final width = maxX - minX;
    final height = maxY - minY;

    // Grid to screen projection scaling
    final scale = min(size.width / width, size.height / height);
    final offsetX = (size.width - width * scale) / 2;
    final offsetY = (size.height - height * scale) / 2;

    Offset toScreen(Offset gridPos) {
      return Offset(
        (gridPos.dx - minX) * scale + offsetX,
        (gridPos.dy - minY) * scale + offsetY,
      );
    }

    // 2. Draw static/un-activated guide paths (clean thick solid black lines)
    for (final arrow in arrows) {
      if (arrow.state == ArrowState.cleared) continue;
      _paintStaticPath(canvas, arrow, toScreen);
    }

    // 3. Draw active/moving paths (solid red lines when moving or retracting)
    for (final arrow in arrows) {
      if (arrow.state == ArrowState.cleared) continue;
      _paintActivePath(canvas, arrow, toScreen);
    }

    // 4. Draw Arrowheads (sharp oriented triangles matching reference)
    for (final arrow in arrows) {
      if (arrow.state == ArrowState.cleared) continue;
      _paintArrowHead(canvas, arrow, toScreen);
    }

    // 5. Draw visual collision rings if there is an active collision
    if (collisionPoint != null) {
      final screenCollision = toScreen(collisionPoint!);
      final Paint collisionPaint = Paint()
        ..color = const Color(0xFFFF2E93)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      canvas.drawCircle(screenCollision, 12.0, collisionPaint);
      canvas.drawCircle(screenCollision, 20.0, collisionPaint..strokeWidth = 1.0);
    }

    // 6. Draw active particles on top
    particleSystem.paint(canvas, toScreen);
  }

  /// Renders the static/inactive guide paths of the arrows (thick solid black lines).
  void _paintStaticPath(Canvas canvas, ArrowModel arrow, Offset Function(Offset) toScreen) {
    final path = arrow.path;
    final screenPoints = path.points.map((pt) => toScreen(pt)).toList();

    final Paint corePaint = Paint()
      ..color = const Color(0xFF000000) // Thick solid black lines
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    final drawPath = Path();
    drawPath.moveTo(screenPoints.first.dx, screenPoints.first.dy);
    for (int i = 1; i < screenPoints.length; i++) {
      drawPath.lineTo(screenPoints[i].dx, screenPoints[i].dy);
    }

    canvas.drawPath(drawPath, corePaint);

    // Subtle label at starting point
    final textPainter = TextPainter(
      text: TextSpan(
        text: arrow.label,
        style: const TextStyle(
          color: Colors.black26,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    final startPt = screenPoints.first;
    final dir = path.getDirectionAtDistance(0.0);
    final textOffset = startPt - Offset(dir.dx * 18, dir.dy * 18) - Offset(textPainter.width / 2, textPainter.height / 2);
    
    textPainter.paint(canvas, textOffset);
  }

  /// Renders the active moving paths (clean solid red lines).
  void _paintActivePath(Canvas canvas, ArrowModel arrow, Offset Function(Offset) toScreen) {
    final activePoints = CollisionEngine.getActivePoints(arrow);
    if (activePoints.length < 2) return;

    final screenPoints = activePoints.map((pt) => toScreen(pt)).toList();

    final Paint linePaint = Paint()
      ..color = const Color(0xFFFF2E93) // Solid Red/Pink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    final drawPath = Path();
    drawPath.moveTo(screenPoints.first.dx, screenPoints.first.dy);
    for (int i = 1; i < screenPoints.length; i++) {
      drawPath.lineTo(screenPoints[i].dx, screenPoints[i].dy);
    }

    canvas.drawPath(drawPath, linePaint);
  }

  /// Renders the sharp triangle arrowhead at the tip of the line pointing in the direction of travel.
  void _paintArrowHead(Canvas canvas, ArrowModel arrow, Offset Function(Offset) toScreen) {
    final path = arrow.path;
    final totalLen = path.totalLength;

    double dHead = totalLen;
    if (arrow.state == ArrowState.movingForward || arrow.state == ArrowState.retracting) {
      dHead = arrow.distanceTravelled + totalLen;
    }

    final headPos = path.getPositionAtDistance(dHead);
    final tangent = path.getDirectionAtDistance(dHead);

    final screenHead = toScreen(headPos);
    final angle = atan2(tangent.dy, tangent.dx);

    final isActive = arrow.state == ArrowState.movingForward || arrow.state == ArrowState.retracting;
    final arrowColor = isActive ? const Color(0xFFFF2E93) : const Color(0xFF000000);

    canvas.save();
    canvas.translate(screenHead.dx, screenHead.dy);
    canvas.rotate(angle);

    // Dimensions of the sharp triangle matching reference image
    const double arrowWidth = 11.0;
    const double arrowHeight = 16.0;

    final Path headPath = Path()
      ..moveTo(arrowHeight / 2, 0)
      ..lineTo(-arrowHeight / 2, -arrowWidth)
      ..lineTo(-arrowHeight / 2, arrowWidth)
      ..close();

    final Paint fillPaint = Paint()
      ..color = arrowColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(headPath, fillPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ArrowsPainter oldDelegate) {
    return true;
  }
}
