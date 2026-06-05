import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared_casino/theme/casino_theme.dart';
import '../../shared_casino/audio/audio_service.dart';
import '../../shared_casino/views/widgets/animated_casino_background.dart';
import '../models/arrows_models.dart';
import '../services/collision_engine.dart';
import 'widgets/arrows_painter.dart';
import 'widgets/particle_system.dart';

class ArrowsGameScreen extends StatefulWidget {
  final LevelSpec levelSpec;
  const ArrowsGameScreen({super.key, required this.levelSpec});

  @override
  State<ArrowsGameScreen> createState() => _ArrowsGameScreenState();
}

class _ArrowsGameScreenState extends State<ArrowsGameScreen> with SingleTickerProviderStateMixin {
  final AudioService _audio = AudioService();
  late LevelSpec _level;
  late Ticker _ticker;

  int _lives = 5;
  bool _isGameOver = false;
  bool _isVictory = false;
  double _screenShake = 0.0;
  Offset? _collisionPoint;
  double _collisionFeedbackTimer = 0.0; // Show collision ring for a brief moment

  final ParticleSystemManager _particleSystem = ParticleSystemManager();
  final Random _random = Random();
  
  double _trailSpawnCooldown = 0.0;

  @override
  void initState() {
    super.initState();
    _level = widget.levelSpec.copy();
    _ticker = createTicker(_onTick);
    _ticker.start();
    _audio.playTableAmbience();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _particleSystem.clear();
    super.dispose();
  }

  /// Reset the current level
  void _resetLevel() {
    setState(() {
      _level = widget.levelSpec.copy();
      _lives = 5;
      _isGameOver = false;
      _isVictory = false;
      _screenShake = 0.0;
      _collisionPoint = null;
      _collisionFeedbackTimer = 0.0;
      _particleSystem.clear();
    });
    _ticker.start();
  }

  /// Core 60fps simulation game loop
  void _onTick(Duration elapsed) {
    if (!mounted || _isGameOver || _isVictory) return;

    // Use a fixed delta-time for absolute physics determinism (~16ms at 60fps)
    const double dt = 0.016; 

    setState(() {
      // 1. Decay screen shake
      _screenShake *= 0.9;
      if (_screenShake < 0.01) _screenShake = 0.0;

      // 2. Clear collision visual feedback rings after 0.5s
      if (_collisionPoint != null) {
        _collisionFeedbackTimer += dt;
        if (_collisionFeedbackTimer >= 0.5) {
          _collisionPoint = null;
          _collisionFeedbackTimer = 0.0;
        }
      }

      // 3. Update particle dynamics
      _particleSystem.update(dt);

      // 4. Update arrow movements and detect collisions
      _updateArrows(dt);

      // 5. Spawn trail particles on moving arrowheads
      _trailSpawnCooldown -= dt;
      if (_trailSpawnCooldown <= 0) {
        _trailSpawnCooldown = 0.05; // 20 particles per second
        for (final arrow in _level.arrows) {
          if (arrow.state == ArrowState.movingForward) {
            final totalLen = arrow.path.totalLength;
            final headPos = arrow.path.getPositionAtDistance(arrow.distanceTravelled + totalLen);
            _particleSystem.spawnTrail(headPos, arrow.themeColor);
          }
        }
      }

      // 6. Check Win/Lose Conditions
      _checkGameStatus();
    });
  }

  void _updateArrows(double dt) {
    for (final arrow in _level.arrows) {
      if (arrow.state == ArrowState.movingForward) {
        // Boost forward speed by 2.2x so the arrow disappears extremely quickly
        arrow.distanceTravelled += arrow.speed * 2.2 * dt;
        
        final totalLen = arrow.path.totalLength;
        // Check if fully cleared off-screen
        if (arrow.distanceTravelled >= totalLen) {
          arrow.state = ArrowState.cleared;
          _audio.playCardSlide();
        }

        // Check if head collides with any other arrow's body
        for (final other in _level.arrows) {
          final colPos = CollisionEngine.checkCollision(arrow, other);
          if (colPos != null) {
            _triggerCollision(arrow, colPos);
            break;
          }
        }
      } else if (arrow.state == ArrowState.retracting) {
        // Retract at 2.5x forward speed for ultra-snappy retraction and quick recovery
        arrow.distanceTravelled -= arrow.speed * 2.2 * 2.5 * dt;
        if (arrow.distanceTravelled <= 0) {
          arrow.distanceTravelled = 0;
          arrow.state = ArrowState.static;
        }
      }
    }
  }

  void _triggerCollision(ArrowModel collidingArrow, Offset pos) {
    // 1. Trigger screen shake
    _screenShake = 1.0;
    
    // 2. Set retraction
    collidingArrow.state = ArrowState.retracting;
    _collisionPoint = pos;
    _collisionFeedbackTimer = 0.0;

    // 3. Spawns explosion sparks
    _particleSystem.spawnCollisionBurst(pos);

    // 4. Play damage audio & vibration
    _audio.playLose();
    HapticFeedback.heavyImpact();

    // 5. Deduct lives
    _lives--;
    if (_lives <= 0) {
      _lives = 0;
      _isGameOver = true;
      _ticker.stop();
      _audio.playTensionStinger();
    }
  }

  void _checkGameStatus() {
    if (_isGameOver || _isVictory) return;

    // Level is won if ALL arrows are cleared
    final won = _level.arrows.every((a) => a.state == ArrowState.cleared);
    if (won) {
      _isVictory = true;
      _ticker.stop();
      // Cache media viewport size before any async gaps to avoid linter context warnings
      final Size screenSize = MediaQuery.of(context).size;
      _handleVictoryProgress(screenSize);
    }
  }

  Future<void> _handleVictoryProgress(Size screenSize) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Play victory sounds & spawn screen confetti
    _audio.playWin();
    _audio.playVictoryStinger();
    _particleSystem.spawnVictoryConfetti(screenSize);

    // 2. Save level completion
    await prefs.setBool('arrows_level_${_level.id}_completed', true);

    // 3. Award \$200 chips
    final double balance = prefs.getDouble('balance') ?? 1000.0;
    final double newBalance = balance + 200.0;
    await prefs.setDouble('balance', newBalance);

    // 4. Update Recent Activity list for the lobby screen
    final activityJson = prefs.getStringList('recent_activity') ?? [];
    final newActivity = {
      'game': 'Arrows Level ${_level.id}',
      'result': 'win',
      'amount': 200.0,
      'timestamp': DateTime.now().toIso8601String(),
    };
    activityJson.insert(0, json.encode(newActivity));
    await prefs.setStringList('recent_activity', activityJson.take(10).toList());

    // 5. Award Experience Progression
    final currentExp = prefs.getInt('xp') ?? 0;
    await prefs.setInt('xp', currentExp + 100);
  }

  /// Maps a screen touch position to detect if the user clicked close to a static path
  void _handleCanvasTap(TapUpDetails details, Size paintSize) {
    if (_isGameOver || _isVictory) return;

    final tapPos = details.localPosition;

    // 1. Recalculate painter coordinate bounds to map tap offsets exactly matching ArrowsPainter
    double minX = -8.0;
    double maxX = 8.0;
    double minY = -8.0;
    double maxY = 8.0;
    for (final arrow in _level.arrows) {
      for (final pt in arrow.path.points) {
        if (pt.dx < minX) minX = pt.dx;
        if (pt.dx > maxX) maxX = pt.dx;
        if (pt.dy < minY) minY = pt.dy;
        if (pt.dy > maxY) maxY = pt.dy;
      }
    }
    minX -= 1.0;
    maxX += 1.0;
    minY -= 1.0;
    maxY += 1.0;
    final width = maxX - minX;
    final height = maxY - minY;

    final scale = min(paintSize.width / width, paintSize.height / height);
    final offsetX = (paintSize.width - width * scale) / 2;
    final offsetY = (paintSize.height - height * scale) / 2;

    Offset toScreen(Offset gridPos) {
      return Offset(
        (gridPos.dx - minX) * scale + offsetX,
        (gridPos.dy - minY) * scale + offsetY,
      );
    }

    // 2. Iterate and check distance from tap to each arrow's guide path
    for (final arrow in _level.arrows) {
      if (arrow.state != ArrowState.static) continue;

      final path = arrow.path;
      final screenPoints = path.points.map((pt) => toScreen(pt)).toList();

      for (int i = 0; i < screenPoints.length - 1; i++) {
        final a = screenPoints[i];
        final b = screenPoints[i + 1];

        // Measure distance to guide segment
        final dist = CollisionEngine.distanceToSegment(tapPos, a, b);
        
        // Tap hit-box radius of 45 logical screen pixels for extremely comfortable touch targets
        if (dist < 45.0) {
          setState(() {
            arrow.state = ArrowState.movingForward;
            _audio.playClick();
            HapticFeedback.lightImpact();
            
            // Spawn splash tap spark particles
            final localTapGrid = Offset(
              (tapPos.dx - offsetX) / scale + minX,
              (tapPos.dy - offsetY) / scale + minY,
            );
            _particleSystem.spawnTapBurst(localTapGrid, arrow.themeColor);
          });
          return; // Trigger one arrow per tap
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double shakeDx = (_random.nextDouble() - 0.5) * _screenShake * 16.0;
    final double shakeDy = (_random.nextDouble() - 0.5) * _screenShake * 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFF090A0C),
      body: Stack(
        children: [
          // Background casino ambience particles
          const Positioned.fill(child: AnimatedCasinoBackground()),

          // Deep green felt layout gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  Color(0xFF0F2218), // Deep velvet green
                  Color(0xFF060D09),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top status bar
                _buildTopBar(),

                // Subtitle instructions
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      _level.description.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white38,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // Interactive clean-white arcade bezel display board
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white, // Pure white background exactly like in the screenshot
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final paintSize = Size(constraints.maxWidth, constraints.maxHeight);

                        return InteractiveViewer(
                          boundaryMargin: const EdgeInsets.all(120.0),
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (details) => _handleCanvasTap(details, paintSize),
                            child: Transform.translate(
                              offset: Offset(shakeDx, shakeDy),
                              child: CustomPaint(
                                size: paintSize,
                                painter: ArrowsPainter(
                                  arrows: _level.arrows,
                                  particleSystem: _particleSystem,
                                  collisionPoint: _collisionPoint,
                                  levelId: _level.id,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Overlays
          if (_isGameOver) _buildLoseOverlay(),
          if (_isVictory) _buildWinOverlay(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              _audio.playClick();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 16),
            ),
          ),

          // Level Name
          Column(
            children: [
              Text(
                'LEVEL ${_level.id.toString().padLeft(2, "0")}',
                style: const TextStyle(
                  color: CasinoTheme.primaryGold,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              Text(
                _level.name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),

          // Hearts/Lives Counter and Restart
          Row(
            children: [
              // Restart level
              GestureDetector(
                onTap: _resetLevel,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: const Icon(Icons.refresh, color: Colors.white70, size: 16),
                ),
              ),
              const SizedBox(width: 12),

              // Heart Stack
              Row(
                children: List.generate(5, (index) {
                  final hasHeart = index < _lives;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Icon(
                      hasHeart ? Icons.favorite : Icons.favorite_border,
                      color: hasHeart ? const Color(0xFFFF2E93) : Colors.white24,
                      size: 18,
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWinOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF141E15), Color(0xFF0A0F0B)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: CasinoTheme.primaryGold.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: CasinoTheme.primaryGold.withValues(alpha: 0.1),
                blurRadius: 30,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Large Gold Medal
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [CasinoTheme.primaryGold, CasinoTheme.secondaryGold],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CasinoTheme.primaryGold.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.workspace_premium, color: Colors.black, size: 36),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'VICTORY',
                style: TextStyle(
                  color: CasinoTheme.primaryGold,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3.0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'ALL LINES CLEARED SUCCESSFULLY',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 20),

              // Award section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on, color: CasinoTheme.primaryGold, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      '+\$200 CHIPS AWARDED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Next level or Return button
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        _audio.playClick();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                      ),
                      child: const Text(
                        'LOBBY',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _audio.playClick();
                        if (_level.id < 10) {
                          final nextLevel = LevelSpecs.allLevels[_level.id]; // id is 1-indexed, so Level N+1 is at index N
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ArrowsGameScreen(levelSpec: nextLevel),
                            ),
                          );
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CasinoTheme.primaryGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        _level.id < 10 ? 'NEXT LEVEL' : 'COMPLETE',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoseOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1417), Color(0xFF0F0A0C)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFF2E93).withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF2E93).withValues(alpha: 0.1),
                blurRadius: 30,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Large Heartbreak
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF2E93).withValues(alpha: 0.1),
                  border: Border.all(color: const Color(0xFFFF2E93).withValues(alpha: 0.3)),
                ),
                child: const Center(
                  child: Icon(Icons.heart_broken_sharp, color: Color(0xFFFF2E93), size: 36),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'DEFEAT',
                style: TextStyle(
                  color: Color(0xFFFF2E93),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3.0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'LIVES EXHAUSTED - TOO MANY COLLISIONS',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 26),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        _audio.playClick();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                      ),
                      child: const Text(
                        'EXIT',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _resetLevel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2E93),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'TRY AGAIN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
