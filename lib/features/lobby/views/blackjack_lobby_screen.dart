import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared_casino/theme/casino_theme.dart';
import '../../shared_casino/audio/audio_service.dart';
import '../../blackjack/views/blackjack_screen.dart';
import '../../blackjack/data/models/player.dart';
import 'custom_table_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlackjackLobbyScreen extends ConsumerStatefulWidget {
  const BlackjackLobbyScreen({super.key});

  @override
  ConsumerState<BlackjackLobbyScreen> createState() => _BlackjackLobbyScreenState();
}

class _BlackjackLobbyScreenState extends ConsumerState<BlackjackLobbyScreen> with SingleTickerProviderStateMixin {
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
      _roundsPlayed = prefs.getInt('rounds_played') ?? 0;
      _wins = prefs.getInt('wins') ?? 0;
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

  Future<void> _resetStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _balance = 1000.0;
      _roundsPlayed = 0;
      _wins = 0;
      _claimedDaily = false;
    });
    await prefs.clear();
    _audio.playClick();
  }

  void _showSettings() {
    _audio.playClick();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CasinoTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: CasinoTheme.tableBorderGold, width: 1.5),
        ),
        title: const Text('Casino Settings', style: TextStyle(color: CasinoTheme.primaryGold)),
        content: StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Mute Casino Audio', style: TextStyle(color: Colors.white)),
                  tileColor: CasinoTheme.lobbyCardDark,
                  value: _audio.isMuted,
                  activeTrackColor: CasinoTheme.accentNeonCyan.withValues(alpha: 0.4),
                  activeThumbColor: CasinoTheme.accentNeonCyan,
                  inactiveTrackColor: CasinoTheme.lobbyDivider.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onChanged: (val) async {
                    await _audio.toggleMute();
                    setModalState(() {});
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    _resetStats();
                    Navigator.pop(context);
                  },
                  child: const Text('Reset Account Stats'),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: CasinoTheme.primaryGold)),
          ),
        ],
      ),
    );
  }

  void _startQuickPlay() {
    _audio.playClick();
    _audio.stopMusic();

    final quickPlayers = [
      const BlackjackPlayer(
        id: 'player_human',
        name: 'You (Player 1)',
        avatar: 'assets/images/avatar_human.png',
        isBot: false,
      ),
      const BlackjackPlayer(
        id: 'bot_dealer_pro',
        name: 'Dealer Pro Bot',
        avatar: 'assets/images/bot_pro.png',
        isBot: true,
        botDifficulty: BotDifficulty.hard,
        botPersonality: BotPersonality.professional,
      ),
      const BlackjackPlayer(
        id: 'bot_risky',
        name: 'Risky Bot',
        avatar: 'assets/images/bot_risky.png',
        isBot: true,
        botDifficulty: BotDifficulty.normal,
        botPersonality: BotPersonality.riskyGambler,
      ),
    ];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlackjackScreen(
          startingMoney: _balance,
          players: quickPlayers,
          feltTheme: 'classic_vegas',
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
        builder: (context) => CustomTableScreen(currentBalance: _balance),
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
        title: const Text('BLACKJACK LOBBY', style: TextStyle(letterSpacing: 2, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: CasinoTheme.bgDarker,
        foregroundColor: CasinoTheme.primaryGold,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: CasinoTheme.primaryGold),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [CasinoTheme.bgDarker, Color(0xFF0C1912), CasinoTheme.bgDark],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top bar: Balance
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
                          color: CasinoTheme.tableBorderGold.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.monetization_on, color: CasinoTheme.primaryGold, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '\$${_balance.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: CasinoTheme.primaryGold,
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
                          'ROYAL BLACKJACK',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            shadows: CasinoTheme.neonGlow(color: CasinoTheme.primaryGold, radius: 10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'THE PRESTIGE CASINO EXPERIENCE',
                        style: TextStyle(
                          color: CasinoTheme.accentNeonCyan,
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
                      _buildStatColumn('Rounds Played', '$_roundsPlayed'),
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
                            color: _claimedDaily ? CasinoTheme.lobbyDivider : CasinoTheme.primaryGold.withValues(alpha: 0.2),
                            border: Border.all(
                              color: _claimedDaily ? Colors.white24 : CasinoTheme.primaryGold,
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            _claimedDaily ? 'Claimed' : 'Daily +\$500',
                            style: TextStyle(
                              color: _claimedDaily ? Colors.white70 : CasinoTheme.primaryGold,
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
                  subtitle: 'Jump into a table with bots instantly',
                  color: CasinoTheme.lobbyCardDark,
                  onTap: _startQuickPlay,
                ),
                const SizedBox(height: 12),
                _buildMenuButton(
                  title: 'CUSTOM TABLE',
                  subtitle: 'Configure rules, bot count, and styles',
                  color: CasinoTheme.lobbyCardSurface,
                  borderColor: CasinoTheme.tableBorderGold,
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
                color: CasinoTheme.primaryGold,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
