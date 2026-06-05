import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared_casino/theme/casino_theme.dart';
import '../../shared_casino/services/progression_service.dart';
import '../../shared_casino/audio/audio_service.dart';
import '../../shared_casino/views/widgets/animated_casino_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProgressionService _progression = ProgressionService();
  final AudioService _audio = AudioService();

  double _balance = 1000.0;
  int _bjRounds = 0;
  int _bjWins = 0;
  int _pokerRounds = 0;
  int _pokerWins = 0;
  double _netProfit = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAllStats();
  }

  Future<void> _loadAllStats() async {
    await _progression.init();
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;
    setState(() {
      _balance = prefs.getDouble('balance') ?? 1000.0;
      _bjRounds = prefs.getInt('rounds_played') ?? 0;
      _bjWins = prefs.getInt('wins') ?? 0;
      _pokerRounds = prefs.getInt('poker_rounds_played') ?? 0;
      _pokerWins = prefs.getInt('poker_wins') ?? 0;
      _netProfit = _balance - 1000.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double levelProgress = _progression.levelProgress;
    final int level = _progression.level;

    return Scaffold(
      body: Stack(
        children: [
          // Ambient animated particle background
          const Positioned.fill(
            child: AnimatedCasinoBackground(),
          ),

          // Dark gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.85),
                  const Color(0xFF050A05).withValues(alpha: 0.90),
                  Colors.black.withValues(alpha: 0.92),
                ],
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top Custom App Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CasinoTheme.lobbyCardSurface,
                            border: Border.all(
                              color: CasinoTheme.lobbyGoldDim.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: CasinoTheme.primaryGold, size: 18),
                            onPressed: () {
                              _audio.playClick();
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        Column(
                          children: [
                            const Text(
                              'VIP PORTFOLIO',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3.0,
                                color: CasinoTheme.primaryGold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: 40,
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    CasinoTheme.primaryGold.withValues(alpha: 0.5),
                                    Colors.transparent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 48), // spacer balance
                      ],
                    ),
                  ),
                ),

                // 1. VIP Identity Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      children: [
                        // Glassmorphic XP Progress meter
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                CasinoTheme.lobbyCardSurface,
                                CasinoTheme.lobbyCardDark,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: CasinoTheme.tableBorderGold.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Radial Level Indicator
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 110,
                                    height: 110,
                                    child: CircularProgressIndicator(
                                      value: levelProgress,
                                      strokeWidth: 6,
                                      backgroundColor: CasinoTheme.lobbyDivider,
                                      valueColor: const AlwaysStoppedAnimation<Color>(CasinoTheme.primaryGold),
                                    ),
                                  ),
                                  CircleAvatar(
                                    radius: 46,
                                    backgroundColor: Colors.black45,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'LEVEL',
                                          style: TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                        ),
                                        Text(
                                          '$level',
                                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              
                              // XP Progress labels
                              Text(
                                '${_progression.xp} / ${(level * 500)} XP',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_progression.xpToNextLevel} XP needed to level up',
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Career Statistics Grid
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'CAREER METRICS',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 2.0),
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                CasinoTheme.lobbyCardSurface,
                                CasinoTheme.lobbyCardDark,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: CasinoTheme.lobbyGoldDim.withValues(alpha: 0.12),
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Blackjack Stats Row
                              _buildStatsRow(
                                title: 'Royal Blackjack',
                                rounds: _bjRounds,
                                wins: _bjWins,
                                accentColor: CasinoTheme.primaryGold,
                              ),
                              Divider(color: Colors.white10, height: 24),
                              // Poker Stats Row
                              _buildStatsRow(
                                title: 'Texas Hold\'em',
                                rounds: _pokerRounds,
                                wins: _pokerWins,
                                accentColor: CasinoTheme.accentNeonCyan,
                              ),
                              Divider(color: Colors.white10, height: 24),
                              
                              // Net Profit Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Net Profit / Loss',
                                    style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${_netProfit >= 0 ? '+' : ''}\$${_netProfit.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: _netProfit >= 0 ? Colors.greenAccent : Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Achievements section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'VIP ACHIEVEMENTS',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 2.0),
                            ),
                            Text(
                              '${_progression.completedAchievements.length}/${_progression.achievementsList.length} UNLOCKED',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: CasinoTheme.primaryGold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),

                // Achievement List Items
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final ach = _progression.achievementsList[index];
                        final isUnlocked = _progression.completedAchievements.contains(ach.id);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isUnlocked
                                    ? [
                                        CasinoTheme.lobbyCardSurface,
                                        CasinoTheme.lobbyCardDark,
                                      ]
                                    : [
                                        CasinoTheme.lobbyCardDark,
                                        const Color(0xFF060806),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isUnlocked
                                    ? CasinoTheme.accentNeonCyan.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.5),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Achievement Icon
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isUnlocked 
                                        ? CasinoTheme.accentNeonCyan.withValues(alpha: 0.15) 
                                        : CasinoTheme.lobbyDivider.withValues(alpha: 0.3),
                                  ),
                                  child: Icon(
                                    ach.icon,
                                    color: isUnlocked ? CasinoTheme.accentNeonCyan : Colors.white70,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Texts
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ach.title,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isUnlocked ? Colors.white : Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        ach.description,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isUnlocked ? Colors.white70 : Colors.white24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Checkmark / Lock status
                                isUnlocked
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F2618),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.greenAccent, width: 0.5),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check, color: Colors.greenAccent, size: 10),
                                            SizedBox(width: 4),
                                            Text(
                                              'PASSED',
                                              style: TextStyle(fontSize: 8, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      )
                                    : const Icon(Icons.lock_outline, color: Colors.white24, size: 16),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: _progression.achievementsList.length,
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(
                  child: SizedBox(height: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow({
    required String title,
    required int rounds,
    required int wins,
    required Color accentColor,
  }) {
    final double winRate = rounds > 0 ? (wins / rounds) * 100 : 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              '$rounds rounds',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(width: 14),
            Text(
              '${winRate.toStringAsFixed(0)}% W/R',
              style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
