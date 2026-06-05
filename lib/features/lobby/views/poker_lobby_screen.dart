import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared_casino/theme/casino_theme.dart';
import '../../shared_casino/audio/audio_service.dart';
import '../../poker/views/poker_game_screen.dart';
import '../../poker/data/models/poker_player.dart';
import 'poker_custom_table_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PokerLobbyScreen extends ConsumerStatefulWidget {
  const PokerLobbyScreen({super.key});

  @override
  ConsumerState<PokerLobbyScreen> createState() => _PokerLobbyScreenState();
}

class _PokerLobbyScreenState extends ConsumerState<PokerLobbyScreen> with SingleTickerProviderStateMixin {
  final AudioService _audio = AudioService();
  late AnimationController _pulseController;

  double _balance = 1000.0;
  int _roundsPlayed = 0;
  int _wins = 0;
  bool _claimedDaily = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _loadStats();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _balance = prefs.getDouble('balance') ?? 1000.0;
      _roundsPlayed = prefs.getInt('poker_rounds_played') ?? 0;
      _wins = prefs.getInt('poker_wins') ?? 0;
      _claimedDaily = prefs.getBool('claimed_daily') ?? false;
    });
  }

  Future<void> _claimDailyReward() async {
    if (_claimedDaily) return;
    _audio.playChipsWin();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _balance += 500;
      _claimedDaily = true;
    });
    await prefs.setDouble('balance', _balance);
    await prefs.setBool('claimed_daily', true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: CasinoTheme.feltGreenLight,
          content: Text(
            'Claimed \$500 Daily Chips! 🤑',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  void _startQuickPlay() {
    _audio.playClick();
    _audio.stopMusic();

    // Standard Quick Play setup: Human + 3 bots
    final quickPlayers = [
      const PokerPlayer(
        id: 'player_human',
        name: 'You (Player 1)',
        avatar: 'assets/images/avatar_human.png',
        isBot: false,
      ),
      const PokerPlayer(
        id: 'bot_tight_passive',
        name: 'Tight Bot',
        avatar: 'assets/images/bot_0.png',
        isBot: true,
        botDifficulty: PokerBotDifficulty.medium,
        botPersonality: PokerBotPersonality.tight,
      ),
      const PokerPlayer(
        id: 'bot_aggro',
        name: 'Aggro Bot',
        avatar: 'assets/images/bot_1.png',
        isBot: true,
        botDifficulty: PokerBotDifficulty.medium,
        botPersonality: PokerBotPersonality.aggressive,
      ),
      const PokerPlayer(
        id: 'bot_smart',
        name: 'Smart Bot',
        avatar: 'assets/images/bot_2.png',
        isBot: true,
        botDifficulty: PokerBotDifficulty.hard,
        botPersonality: PokerBotPersonality.smartBalanced,
      ),
    ];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PokerGameScreen(
          startingMoney: _balance,
          players: quickPlayers,
          smallBlind: 10.0,
          bigBlind: 20.0,
          isFastMode: false,
        ),
      ),
    ).then((_) {
      _loadStats();
      _audio.playLobbyMusic();
    });
  }

  void _openCustomTable() {
    _audio.playClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PokerCustomTableScreen(currentBalance: _balance),
      ),
    ).then((_) {
      _loadStats();
      _audio.playLobbyMusic();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POKER LOBBY', style: TextStyle(letterSpacing: 2, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: CasinoTheme.bgDarker,
        foregroundColor: CasinoTheme.accentNeonCyan,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [CasinoTheme.bgDarker, Color(0xFF0C161D), CasinoTheme.bgDark],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Balance indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [CasinoTheme.lobbyCardSurface, CasinoTheme.lobbyCardDark],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: CasinoTheme.accentNeonCyan.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.monetization_on, color: CasinoTheme.accentNeonCyan, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '\$${_balance.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: CasinoTheme.accentNeonCyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Grand Animated Logo header
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.96, end: 1.04).animate(
                          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                        ),
                        child: Text(
                          'TEXAS HOLD\'EM',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: CasinoTheme.accentNeonCyan,
                            shadows: CasinoTheme.neonGlow(color: CasinoTheme.accentNeonCyan, radius: 10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'THE PRESTIGE POKER ROOM',
                        style: TextStyle(
                          color: CasinoTheme.primaryGold,
                          letterSpacing: 4.0,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats Dashboard (Glassmorphism)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [CasinoTheme.lobbyCardSurface, CasinoTheme.lobbyCardDark],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: CasinoTheme.lobbyGoldDim.withValues(alpha: 0.15),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('Hands Played', '$_roundsPlayed'),
                      Container(width: 1, height: 40, color: Colors.white10),
                      _buildStatColumn('Win Rate', _roundsPlayed > 0 ? '${((_wins / _roundsPlayed) * 100).toStringAsFixed(0)}%' : '0%'),
                      Container(width: 1, height: 40, color: Colors.white10),
                      GestureDetector(
                        onTap: _claimedDaily ? null : _claimDailyReward,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: _claimedDaily ? CasinoTheme.lobbyDivider : CasinoTheme.accentNeonCyan.withValues(alpha: 0.2),
                            border: Border.all(
                              color: _claimedDaily ? Colors.white24 : CasinoTheme.accentNeonCyan,
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            _claimedDaily ? 'Claimed' : 'Daily +\$500',
                            style: TextStyle(
                              color: _claimedDaily ? Colors.white70 : CasinoTheme.accentNeonCyan,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Menu items
                _buildMenuButton(
                  title: 'QUICK PLAY',
                  subtitle: 'Enter a 4-player Texas Hold\'em ring game',
                  color: CasinoTheme.lobbyCyanDeep,
                  onTap: _startQuickPlay,
                ),
                const SizedBox(height: 12),
                _buildMenuButton(
                  title: 'CUSTOM ROOM',
                  subtitle: 'Build a private table with up to 8 players',
                  color: CasinoTheme.lobbyCardSurface,
                  borderColor: CasinoTheme.accentNeonCyan.withValues(alpha: 0.5),
                  onTap: _openCustomTable,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton({
    required String title,
    required String subtitle,
    required Color color,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor ?? Colors.transparent,
            width: borderColor != null ? 1.5 : 0.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: CasinoTheme.accentNeonCyan,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
