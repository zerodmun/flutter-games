import 'package:flutter/material.dart';
import '../models/arrows_models.dart';

class CollisionEngine {
  /// The distance threshold in grid coordinates for a collision.
  /// If the arrowhead is closer than this to any segment, they collide.
  static const double collisionThreshold = 0.3;

  /// Sample points along an arrow's active segment from tail to head.
  /// This handles straight, bent, or complex curved lines perfectly.
  static List<Offset> getActivePoints(ArrowModel arrow) {
    if (arrow.state == ArrowState.cleared) return [];

    final path = arrow.path;
    final totalLen = path.totalLength;

    double dTail = 0.0;
    double dHead = totalLen;

    if (arrow.state == ArrowState.movingForward || arrow.state == ArrowState.retracting) {
      dTail = arrow.distanceTravelled;
      dHead = arrow.distanceTravelled + totalLen;
    }

    List<Offset> points = [];
    
    // Sampling resolution (smaller is more accurate, e.g., 0.2 units per step)
    const double step = 0.2;
    double d = dTail;
    
    while (d < dHead) {
      points.add(path.getPositionAtDistance(d));
      d += step;
    }
    points.add(path.getPositionAtDistance(dHead));

    return points;
  }

  /// Calculates the shortest distance from point P to line segment AB.
  static double distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;

    final abLenSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (abLenSq == 0) return ap.distance; // A and B are the same point

    // Projection factor clamped to [0.0 - 1.0]
    double t = (ap.dx * ab.dx + ap.dy * ab.dy) / abLenSq;
    t = t.clamp(0.0, 1.0);

    final closestPoint = a + ab * t;
    return (p - closestPoint).distance;
  }

  /// Checks if the head of the active moving arrow [activeArrow]
  /// is colliding with any active part of another arrow [otherArrow].
  /// Returns the Offset of the collision point if yes, else null.
  static Offset? checkCollision(ArrowModel activeArrow, ArrowModel otherArrow) {
    if (activeArrow.id == otherArrow.id) return null;
    if (activeArrow.state != ArrowState.movingForward) return null;
    if (otherArrow.state == ArrowState.cleared) return null;

    final pathA = activeArrow.path;
    final totalLenA = pathA.totalLength;
    final dHeadA = activeArrow.distanceTravelled + totalLenA;

    // Get the exact current position of the active arrowhead
    final headPos = pathA.getPositionAtDistance(dHeadA);

    // Get the points representing the active body of the other arrow
    final otherPoints = getActivePoints(otherArrow);
    if (otherPoints.length < 2) return null;

    // Check distance of head to each segment of the other arrow
    for (int i = 0; i < otherPoints.length - 1; i++) {
      final a = otherPoints[i];
      final b = otherPoints[i + 1];

      // To avoid immediate self-collision at starting intersection points,
      // skip checking segments if they are near the initial starting point of A
      // and the animation has just begun.
      // With increased speeds, we use wider thresholds (0.8 distance, 0.9 margin) for safety.
      final startPosA = pathA.getPositionAtDistance(0.0);
      if (activeArrow.distanceTravelled < 0.8) {
        if ((a - startPosA).distance < 0.9 || (b - startPosA).distance < 0.9) {
          continue;
        }
      }

      final dist = distanceToSegment(headPos, a, b);
      if (dist < collisionThreshold) {
        // Return the collision location (the closest point on the hit segment)
        final ab = b - a;
        final ap = headPos - a;
        final abLenSq = ab.dx * ab.dx + ab.dy * ab.dy;
        final t = (abLenSq == 0) ? 0.0 : ((ap.dx * ab.dx + ap.dy * ab.dy) / abLenSq).clamp(0.0, 1.0);
        return a + ab * t;
      }
    }

    return null;
  }
}
