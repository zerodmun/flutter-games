import 'package:flutter/material.dart';

/// The current status of an individual arrow
enum ArrowState {
  static,
  movingForward,
  retracting,
  cleared,
}

/// Represents the geometric layout of an arrow's path using relative coordinates.
/// X ranges from -8 to 8, Y from -8 to 8 for a high-density grid.
class ArrowPath {
  final List<Offset> points;

  ArrowPath(this.points) {
    assert(points.length >= 2, "An ArrowPath must contain at least 2 points.");
  }

  /// Calculates cumulative length of the path.
  double get totalLength {
    double len = 0;
    for (int i = 0; i < points.length - 1; i++) {
      len += (points[i + 1] - points[i]).distance;
    }
    return len;
  }

  /// Evaluates the 2D offset position at a given distance along the path.
  /// If the distance exceeds the total length, the position continues along the ray
  /// of the final segment.
  Offset getPositionAtDistance(double d) {
    if (d <= 0) return points.first;

    double accumulated = 0;
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final segmentLength = (p2 - p1).distance;

      if (accumulated + segmentLength >= d) {
        final t = (d - accumulated) / segmentLength;
        return Offset.lerp(p1, p2, t)!;
      }
      accumulated += segmentLength;
    }

    // Beyond final point - extrapolate along the final segment's direction
    final pLast = points.last;
    final pPrevLast = points[points.length - 2];
    final dir = (pLast - pPrevLast);
    final unitDir = dir / dir.distance;
    return pLast + unitDir * (d - accumulated);
  }

  /// Gets the unit direction tangent vector at a given distance along the path.
  Offset getDirectionAtDistance(double d) {
    if (points.length < 2) return const Offset(1, 0);
    
    double accumulated = 0;
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final segmentLength = (p2 - p1).distance;

      if (accumulated + segmentLength >= d) {
        final dir = p2 - p1;
        return dir / dir.distance;
      }
      accumulated += segmentLength;
    }

    // Beyond final point, return final segment direction
    final dir = points.last - points[points.length - 2];
    return dir / dir.distance;
  }
}

/// Model storing the runtime simulation state of an individual arrow.
class ArrowModel {
  final int id;
  final ArrowPath path;
  final Color themeColor;
  final String label; // A, B, C etc. for UI clarity
  
  ArrowState state;
  double distanceTravelled; // distance from original tail position
  double speed;
  double animationT; // current normalized slider value [0.0 - 1.0]

  ArrowModel({
    required this.id,
    required this.path,
    required this.themeColor,
    required this.label,
    this.state = ArrowState.static,
    this.distanceTravelled = 0.0,
    this.speed = 12.0, // snappy responses
    this.animationT = 0.0,
  });

  /// Deep copy factory
  ArrowModel copy() {
    return ArrowModel(
      id: id,
      path: path,
      themeColor: themeColor,
      label: label,
      state: state,
      distanceTravelled: distanceTravelled,
      speed: speed,
      animationT: animationT,
    );
  }

  /// Resets the arrow back to its initial static state
  void reset() {
    state = ArrowState.static;
    distanceTravelled = 0.0;
    animationT = 0.0;
  }
}

/// Represents the level geometry and progression settings.
class LevelSpec {
  final int id;
  final String name;
  final List<ArrowModel> arrows;
  final String description;

  LevelSpec({
    required this.id,
    required this.name,
    required this.arrows,
    required this.description,
  });

  /// Create a fresh deep copy of the level for gameplay reset.
  LevelSpec copy() {
    return LevelSpec(
      id: id,
      name: name,
      arrows: arrows.map((a) => a.copy()).toList(),
      description: description,
    );
  }
}

/// Factory class containing the pre-configured 10 Labyrinth Levels.
class LevelSpecs {
  static List<LevelSpec> get allLevels => [
    // ----------------------------------------------------
    // LEVEL 1: Labyrinth Crossroads (5 non-crossing winding paths)
    // ----------------------------------------------------
    LevelSpec(
      id: 1,
      name: "LABYRINTH CROSS",
      description: "Level 1: 5 disjoint paths. Time your exits carefully!",
      arrows: [
        ArrowModel(id: 101, label: "1", speed: 11.5, themeColor: Colors.black, path: ArrowPath([
          const Offset(-6, 6), const Offset(-6, -6), const Offset(-3, -6)
        ])),
        ArrowModel(id: 102, label: "2", speed: 11.5, themeColor: Colors.black, path: ArrowPath([
          const Offset(-2, 6), const Offset(-2, 2)
        ])),
        ArrowModel(id: 103, label: "3", speed: 11.5, themeColor: Colors.black, path: ArrowPath([
          const Offset(0, 6), const Offset(0, 0), const Offset(3, 0)
        ])),
        ArrowModel(id: 104, label: "4", speed: 11.5, themeColor: Colors.black, path: ArrowPath([
          const Offset(5, 6), const Offset(5, -6), const Offset(2, -6)
        ])),
        ArrowModel(id: 105, label: "5", speed: 11.5, themeColor: Colors.black, path: ArrowPath([
          const Offset(-5, -2), const Offset(1, -2)
        ])),
      ],
    ),
    
    // ----------------------------------------------------
    // LEVEL 2: Snake Pit (6 highly curved, completely separate snake lines)
    // ----------------------------------------------------
    LevelSpec(
      id: 2,
      name: "SNAKE PIT",
      description: "Level 2: 6 winding snake paths that never cross when static.",
      arrows: [
        ArrowModel(id: 201, label: "1", speed: 12.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-7, 7), const Offset(-7, -7), const Offset(-5, -7)
        ])),
        ArrowModel(id: 202, label: "2", speed: 12.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-3, 7), const Offset(-3, -3), const Offset(0, -3)
        ])),
        ArrowModel(id: 203, label: "3", speed: 12.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(2, 7), const Offset(2, 0), const Offset(5, 0)
        ])),
        ArrowModel(id: 204, label: "4", speed: 12.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(7, 7), const Offset(7, -7), const Offset(5, -7)
        ])),
        ArrowModel(id: 205, label: "5", speed: 12.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-5, 4), const Offset(0, 4)
        ])),
        ArrowModel(id: 206, label: "6", speed: 12.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-1, -6), const Offset(3, -6)
        ])),
      ],
    ),

    // ----------------------------------------------------
    // LEVEL 3: Labyrinth Junction (7 separate paths)
    // ----------------------------------------------------
    LevelSpec(
      id: 3,
      name: "LABYRINTH JUNCTION",
      description: "Level 3: 7 separate parallel winding paths. Find the safe exit order!",
      arrows: [
        ArrowModel(id: 301, label: "1", speed: 12.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-6, 6), const Offset(-6, -6), const Offset(-4, -6)
        ])),
        ArrowModel(id: 302, label: "2", speed: 12.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-3, 6), const Offset(-3, -2), const Offset(1, -2)
        ])),
        ArrowModel(id: 303, label: "3", speed: 12.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(2, 6), const Offset(2, 2), const Offset(5, 2)
        ])),
        ArrowModel(id: 304, label: "4", speed: 12.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(6, 6), const Offset(6, -6), const Offset(4, -6)
        ])),
        ArrowModel(id: 305, label: "5", speed: 12.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-5, 4), const Offset(0, 4)
        ])),
        ArrowModel(id: 306, label: "6", speed: 12.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-1, 0), const Offset(3, 0)
        ])),
        ArrowModel(id: 307, label: "7", speed: 12.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-2, -5), const Offset(2, -5)
        ])),
      ],
    ),

    // ----------------------------------------------------
    // LEVEL 4: Chevron Labyrinth (8 parallel maze chevrons)
    // ----------------------------------------------------
    LevelSpec(
      id: 4,
      name: "CHEVRON LABYRINTH",
      description: "Level 4: 8 parallel chevrons that block each other's exits.",
      arrows: [
        ArrowModel(id: 401, label: "1", speed: 12.5, themeColor: Colors.black, path: ArrowPath([
          const Offset(-7, 5), const Offset(-7, -5)
        ])),
        ArrowModel(id: 402, label: "2", speed: 12.5, themeColor: Colors.black, path: ArrowPath([
          const Offset(-5, 5), const Offset(-5, -2), const Offset(-3, -2)
        ])),
        ArrowModel(id: 403, label: "3", speed: 12.5, themeColor: Colors.black, path: ArrowPath([
          const Offset(-2, 5), const Offset(-2, 1), const Offset(1, 1)
        ])),
        ArrowModel(id: 404, label: "4", speed: 12.5, themeColor: Colors.black, path: ArrowPath([
          const Offset(2, 5), const Offset(2, -3), const Offset(4, -3)
        ])),
        ArrowModel(id: 405, label: "5", speed: 12.5, themeColor: Colors.black, path: ArrowPath([
          const Offset(6, 5), const Offset(6, -5)
        ])),
        ArrowModel(id: 406, label: "6", speed: 12.5, themeColor: Colors.black, path: ArrowPath([
          const Offset(-6, 3), const Offset(-3, 3)
        ])),
        ArrowModel(id: 407, label: "7", speed: 12.5, themeColor: Colors.black, path: ArrowPath([
          const Offset(-1, -1), const Offset(3, -1)
        ])),
        ArrowModel(id: 408, label: "8", speed: 12.5, themeColor: Colors.black, path: ArrowPath([
          const Offset(-4, -6), const Offset(4, -6)
        ])),
      ],
    ),

    // ----------------------------------------------------
    // LEVEL 5: Spiral Labyrinth (9 nested concentric square shells)
    // ----------------------------------------------------
    LevelSpec(
      id: 5,
      name: "SPIRAL WINDINGS",
      description: "Level 5: 9 perfectly nested concentric shells. Fire from outer to inner!",
      arrows: [
        ArrowModel(id: 501, label: "1", speed: 13.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-7, 7), const Offset(7, 7), const Offset(7, -7), const Offset(-7, -7), const Offset(-7, 5)
        ])),
        ArrowModel(id: 502, label: "2", speed: 13.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-5, 5), const Offset(5, 5), const Offset(5, -5), const Offset(-5, -5), const Offset(-5, 3)
        ])),
        ArrowModel(id: 503, label: "3", speed: 13.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-3, 3), const Offset(3, 3), const Offset(3, -3), const Offset(-3, -3), const Offset(-3, 1)
        ])),
        ArrowModel(id: 504, label: "4", speed: 13.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-1, 1), const Offset(1, 1), const Offset(1, -1), const Offset(-1, -1), const Offset(-1, 0)
        ])),
        ArrowModel(id: 505, label: "5", speed: 13.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-6, 6), const Offset(-5.5, 6)
        ])),
        ArrowModel(id: 506, label: "6", speed: 13.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(6, -6), const Offset(6.5, -6)
        ])),
        ArrowModel(id: 507, label: "7", speed: 13.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(4, -6), const Offset(4.5, -6)
        ])),
        ArrowModel(id: 508, label: "8", speed: 13.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(2, -6), const Offset(2.5, -6)
        ])),
        ArrowModel(id: 509, label: "9", speed: 13.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(0, -6), const Offset(0.5, -6)
        ])),
      ],
    ),

    // ----------------------------------------------------
    // LEVEL 6: Crossover Grid (10 separate paths)
    // ----------------------------------------------------
    LevelSpec(
      id: 6,
      name: "CROSSOVER MATRIX",
      description: "Level 6: 10 parallel disjoint paths. Master the sequencing!",
      arrows: [
        ArrowModel(id: 601, label: "1", speed: 13.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-7, 6), const Offset(-7, -6)
        ])),
        ArrowModel(id: 602, label: "2", speed: 13.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-5, 6), const Offset(-5, -3), const Offset(-3, -3)
        ])),
        ArrowModel(id: 603, label: "3", speed: 13.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-2, 6), const Offset(-2, 0), const Offset(0, 0)
        ])),
        ArrowModel(id: 604, label: "4", speed: 13.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(1, 6), const Offset(1, 2), const Offset(3, 2)
        ])),
        ArrowModel(id: 605, label: "5", speed: 13.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(4, 6), const Offset(4, -3), const Offset(6, -3)
        ])),
        ArrowModel(id: 606, label: "6", speed: 13.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(7, 6), const Offset(7, -6)
        ])),
        ArrowModel(id: 607, label: "7", speed: 13.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-6, 4), const Offset(-3, 4)
        ])),
        ArrowModel(id: 608, label: "8", speed: 13.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-1, -2), const Offset(2, -2)
        ])),
        ArrowModel(id: 609, label: "9", speed: 13.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-4, -5), const Offset(0, -5)
        ])),
        ArrowModel(id: 610, label: "10", speed: 13.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(2, -5), const Offset(6, -5)
        ])),
      ],
    ),

    // ----------------------------------------------------
    // LEVEL 7: Labyrinth Lobe (10 bent paths)
    // ----------------------------------------------------
    LevelSpec(
      id: 7,
      name: "LABYRINTH LOBE",
      description: "Level 7: 10 non-crossing winding paths forming lobes.",
      arrows: [
        ArrowModel(id: 701, label: "1", speed: 13.5, themeColor: Colors.black, path: ArrowPath([
          const Offset(-7, 7), const Offset(-7, -7), const Offset(-6, -7)
        ])),
        ArrowModel(id: 702, label: "2", speed: 13.5, themeColor: Colors.black, path: ArrowPath([
          const Offset(-5, 7), const Offset(-5, -4), const Offset(-3, -4)
        ])),
        ArrowModel(id: 703, label: "3", speed: 13.5, themeColor: Colors.black, path: ArrowPath([
          const Offset(-2, 7), const Offset(-2, 0), const Offset(0, 0)
        ])),
        ArrowModel(id: 704, label: "4", speed: 13.5, themeColor: Colors.black, path: ArrowPath([
          const Offset(1, 7), const Offset(1, 3), const Offset(3, 3)
        ])),
        ArrowModel(id: 705, label: "5", speed: 13.5, themeColor: Colors.black, path: ArrowPath([
          const Offset(4, 7), const Offset(4, -3), const Offset(5, -3)
        ])),
        ArrowModel(id: 706, label: "6", speed: 13.5, themeColor: Colors.black, path: ArrowPath([
          const Offset(7, 7), const Offset(7, -7), const Offset(6, -7)
        ])),
        ArrowModel(id: 707, label: "7", speed: 13.5, themeColor: Colors.black, path: ArrowPath([
          const Offset(-6, 5), const Offset(-3, 5)
        ])),
        ArrowModel(id: 708, label: "8", speed: 13.5, themeColor: Colors.black, path: ArrowPath([
          const Offset(-1, -2), const Offset(2, -2)
        ])),
        ArrowModel(id: 709, label: "9", speed: 13.5, themeColor: Colors.black, path: ArrowPath([
          const Offset(-4, -6), const Offset(0, -6)
        ])),
        ArrowModel(id: 710, label: "10", speed: 13.5, themeColor: Colors.black, path: ArrowPath([
          const Offset(2, -6), const Offset(5, -6)
        ])),
      ],
    ),

    // ----------------------------------------------------
    // LEVEL 8: Node Labyrinth (8 disjoint symmetrical paths)
    // ----------------------------------------------------
    LevelSpec(
      id: 8,
      name: "NODE MAZE",
      description: "Level 8: 8 symmetric corner winding paths. Clean layout!",
      arrows: [
        ArrowModel(id: 801, label: "1", speed: 14.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-6, 6), const Offset(-6, 2), const Offset(-4, 2)
        ])),
        ArrowModel(id: 802, label: "2", speed: 14.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-3, 6), const Offset(-3, 2), const Offset(-1, 2)
        ])),
        ArrowModel(id: 803, label: "3", speed: 14.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(1, 6), const Offset(1, 2), const Offset(3, 2)
        ])),
        ArrowModel(id: 804, label: "4", speed: 14.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(4, 6), const Offset(4, 2), const Offset(6, 2)
        ])),
        ArrowModel(id: 805, label: "5", speed: 14.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-6, -2), const Offset(-6, -6), const Offset(-4, -6)
        ])),
        ArrowModel(id: 806, label: "6", speed: 14.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-3, -2), const Offset(-3, -6), const Offset(-1, -6)
        ])),
        ArrowModel(id: 807, label: "7", speed: 14.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(1, -2), const Offset(1, -6), const Offset(3, -6)
        ])),
        ArrowModel(id: 808, label: "8", speed: 14.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(4, -2), const Offset(4, -6), const Offset(6, -6)
        ])),
      ],
    ),

    // ----------------------------------------------------
    // LEVEL 9: Labyrinth Matrix (10 nested corridors)
    // ----------------------------------------------------
    LevelSpec(
      id: 9,
      name: "LABYRINTH MATRIX",
      description: "Level 9: 10 nested winding corridors. Clean precision timing!",
      arrows: [
        ArrowModel(id: 901, label: "1", speed: 14.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-7, 7), const Offset(7, 7), const Offset(7, -7)
        ])),
        ArrowModel(id: 902, label: "2", speed: 14.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(6, -7), const Offset(-7, -7), const Offset(-7, 6)
        ])),
        ArrowModel(id: 903, label: "3", speed: 14.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-6, 5), const Offset(5, 5), const Offset(5, -5)
        ])),
        ArrowModel(id: 904, label: "4", speed: 14.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(4, -5), const Offset(-5, -5), const Offset(-5, 4)
        ])),
        ArrowModel(id: 905, label: "5", speed: 14.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-4, 3), const Offset(3, 3), const Offset(3, -3)
        ])),
        ArrowModel(id: 906, label: "6", speed: 14.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(2, -3), const Offset(-3, -3), const Offset(-3, 2)
        ])),
        ArrowModel(id: 907, label: "7", speed: 14.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-2, 1), const Offset(1, 1), const Offset(1, -1)
        ])),
        ArrowModel(id: 908, label: "8", speed: 14.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(0, -1), const Offset(-1, -1), const Offset(-1, 0)
        ])),
        ArrowModel(id: 909, label: "9", speed: 14.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-6, -1), const Offset(-6, 1)
        ])),
        ArrowModel(id: 910, label: "10", speed: 14.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(6, -1), const Offset(6, 1)
        ])),
      ],
    ),

    // ----------------------------------------------------
    // LEVEL 10: Figure-8 Orbit (10 ultimate nested concentric pathways)
    // ----------------------------------------------------
    LevelSpec(
      id: 10,
      name: "INFINITY MAZE",
      description: "Level 10: 10 Concentric Infinite loops. Solve the ultimate sequencing puzzle!",
      arrows: [
        ArrowModel(id: 1001, label: "1", speed: 15.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-7, 7), const Offset(7, 7), const Offset(7, -7), const Offset(-7, -7), const Offset(-7, 6)
        ])),
        ArrowModel(id: 1002, label: "2", speed: 15.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-5, 5), const Offset(5, 5), const Offset(5, -5), const Offset(-5, -5), const Offset(-5, 4)
        ])),
        ArrowModel(id: 1003, label: "3", speed: 15.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-3, 3), const Offset(3, 3), const Offset(3, -3), const Offset(-3, -3), const Offset(-3, 2)
        ])),
        ArrowModel(id: 1004, label: "4", speed: 15.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-1, 1), const Offset(1, 1), const Offset(1, -1), const Offset(-1, -1), const Offset(-1, 0)
        ])),
        ArrowModel(id: 1005, label: "5", speed: 15.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-6, 0), const Offset(-6, 1)
        ])),
        ArrowModel(id: 1006, label: "6", speed: 15.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(6, 0), const Offset(6, 1)
        ])),
        ArrowModel(id: 1007, label: "7", speed: 15.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-4, 0), const Offset(-4, 1)
        ])),
        ArrowModel(id: 1008, label: "8", speed: 15.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(4, 0), const Offset(4, 1)
        ])),
        ArrowModel(id: 1009, label: "9", speed: 15.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(-2, 0), const Offset(-2, 1)
        ])),
        ArrowModel(id: 1010, label: "10", speed: 15.0, themeColor: Colors.black, path: ArrowPath([
          const Offset(2, 0), const Offset(2, 1)
        ])),
      ],
    ),
  ];
}
