import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared_casino/theme/casino_theme.dart';
import '../../shared_casino/audio/audio_service.dart';
import '../../shared_casino/views/widgets/animated_casino_background.dart';
import '../models/arrows_models.dart';
import 'arrows_game_screen.dart';

class ArrowsLobbyScreen extends StatefulWidget {
  const ArrowsLobbyScreen({super.key});

  @override
  State<ArrowsLobbyScreen> createState() => _ArrowsLobbyScreenState();
}

class _ArrowsLobbyScreenState extends State<ArrowsLobbyScreen> {
  final AudioService _audio = AudioService();
  double _balance = 1000.0;
  List<int> _completedLevels = [];

  @override
  void initState() {
    super.initState();
    _loadBalanceAndProgress();
  }

  Future<void> _loadBalanceAndProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final balance = prefs.getDouble('balance') ?? 1000.0;
    
    // Load completed levels
    List<int> completed = [];
    for (int i = 1; i <= 10; i++) {
      if (prefs.getBool('arrows_level_${i}_completed') ?? false) {
        completed.add(i);
      }
    }

    if (!mounted) return;
    setState(() {
      _balance = balance;
      _completedLevels = completed;
    });
  }

  void _playLevel(LevelSpec level) {
    _audio.playClick();
    HapticFeedback.lightImpact();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArrowsGameScreen(levelSpec: level),
      ),
    ).then((_) => _loadBalanceAndProgress());
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _completedLevels.length;

    return Scaffold(
      body: Stack(
        children: [
          // Background particle layer
          const Positioned.fill(child: AnimatedCasinoBackground()),

          // Semi-transparent gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF06080C),
                  Color(0xFF0A0E14),
                  Color(0xFF080C12),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Premium Top App Bar
                _buildAppBar(context),

                // Level Progress Banner
                _buildProgressBanner(completedCount),

                // Level grid select
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.15,
                          ),
                          itemCount: 10,
                          itemBuilder: (context, index) {
                            final levelId = index + 1;
                            final isCompleted = _completedLevels.contains(levelId);
                            
                            // Sequential unlock logic: Level 1 is always unlocked. 
                            // Level N is unlocked if level N-1 is completed.
                            final isUnlocked = levelId == 1 || _completedLevels.contains(levelId - 1);
                            
                            final allSpecs = LevelSpecs.allLevels;
                            final spec = allSpecs[index];

                            return _buildLevelButton(spec, isUnlocked, isCompleted);
                          },
                        ),
                        const SizedBox(height: 30),
                        _buildHelpTip(),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Exit button
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
          const SizedBox(width: 14),

          // Title
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ARROWS PUZZLE',
                  style: TextStyle(
                    color: CasinoTheme.primaryGold,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                Text(
                  'CHRONICLES OF TIMING',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Chip counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CasinoTheme.primaryGold.withValues(alpha: 0.12),
                  CasinoTheme.primaryGold.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CasinoTheme.primaryGold.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: CasinoTheme.primaryGold, size: 14),
                const SizedBox(width: 6),
                Text(
                  '\$${_balance.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: CasinoTheme.primaryGold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBanner(int completedCount) {
    final double completionPercent = completedCount / 10.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111820), Color(0xFF0C1018)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CHRONICLES PROGRESS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white70,
                ),
              ),
              Text(
                '$completedCount / 10 COMPLETED',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: CasinoTheme.primaryGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completionPercent,
              minHeight: 5,
              backgroundColor: CasinoTheme.lobbyDivider,
              valueColor: const AlwaysStoppedAnimation<Color>(CasinoTheme.primaryGold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelButton(LevelSpec level, bool isUnlocked, bool isCompleted) {
    final accentColor = isUnlocked 
        ? (isCompleted ? CasinoTheme.primaryGold : CasinoTheme.accentNeonCyan)
        : Colors.white.withValues(alpha: 0.2);

    return GestureDetector(
      onTap: isUnlocked ? () => _playLevel(level) : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnlocked 
              ? const Color(0xFF1E222B).withValues(alpha: 0.4) 
              : const Color(0xFF0F121C).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withValues(alpha: isUnlocked ? 0.3 : 0.08),
            width: isCompleted ? 1.2 : 0.8,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.03),
                    blurRadius: 10,
                  )
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Gold Corner glow if completed
            if (isCompleted)
              Positioned(
                top: -10,
                right: -10,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CasinoTheme.primaryGold.withValues(alpha: 0.08),
                  ),
                ),
              ),

            // Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LEVEL ${level.id.toString().padLeft(2, "0")}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: isUnlocked ? Colors.white38 : Colors.white24,
                        letterSpacing: 1.0,
                      ),
                    ),
                    if (isCompleted)
                      const Icon(Icons.stars, color: CasinoTheme.primaryGold, size: 16)
                    else if (!isUnlocked)
                      const Icon(Icons.lock, color: Colors.white24, size: 14),
                  ],
                ),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isUnlocked ? Colors.white : Colors.white.withValues(alpha: 0.3),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${level.arrows.length} Arrows',
                      style: TextStyle(
                        fontSize: 9,
                        color: isUnlocked ? accentColor.withValues(alpha: 0.8) : Colors.white24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpTip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: CasinoTheme.accentNeonCyan, size: 18),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOW TO PLAY',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white70,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Tap arrows to fire them along their paths. Time your launches perfectly to prevent arrows from intersecting/crashing! Clear all arrows to unlock the next level and win \$200!',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white38,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
