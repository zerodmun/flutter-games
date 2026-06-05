import 'package:flutter/material.dart';
import '../../shared_casino/theme/casino_theme.dart';
import '../../shared_casino/audio/audio_service.dart';
import '../../poker/data/models/poker_player.dart';
import '../../poker/views/poker_game_screen.dart';

class PokerCustomTableScreen extends StatefulWidget {
  final double currentBalance;

  const PokerCustomTableScreen({super.key, required this.currentBalance});

  @override
  State<PokerCustomTableScreen> createState() => _PokerCustomTableScreenState();
}

class _PokerCustomTableScreenState extends State<PokerCustomTableScreen> {
  final AudioService _audio = AudioService();

  double _startingMoney = 1000.0;
  double _smallBlind = 10.0;
  double _bigBlind = 20.0;
  String _feltTheme = 'classic_vegas';
  bool _isFastMode = false;

  // Seat config (Index 0 is human, seats 1-7 can be bots/empty)
  final List<PokerPlayer?> _seats = [
    const PokerPlayer(
      id: 'player_human',
      name: 'You (Player 1)',
      avatar: 'assets/images/avatar_human.png',
      isBot: false,
    ),
    null, // Seat 2 (empty)
    null, // Seat 3 (empty)
    null, // Seat 4 (empty)
    null, // Seat 5
    null, // Seat 6
    null, // Seat 7
    null, // Seat 8
  ];

  final List<String> _feltThemes = ['classic_vegas', 'neon_cyber', 'luxury_gold', 'emerald_casino', 'crimson_royale', 'minimal_dark'];

  @override
  void initState() {
    super.initState();
    _startingMoney = widget.currentBalance;
    if (_startingMoney < 100) {
      _startingMoney = 1000.0;
    }
  }

  void _addBot(int seatIndex) {
    _audio.playClick();
    setState(() {
      _seats[seatIndex] = PokerPlayer(
        id: 'bot_$seatIndex',
        name: 'Bot ${seatIndex + 1}',
        avatar: 'assets/images/bot_$seatIndex.png',
        isBot: true,
        botDifficulty: PokerBotDifficulty.medium,
        botPersonality: PokerBotPersonality.smartBalanced,
      );
    });
  }

  void _removePlayer(int seatIndex) {
    if (seatIndex == 0) return; // Cannot remove the human player
    _audio.playClick();
    setState(() {
      _seats[seatIndex] = null;
    });
  }

  void _updateBotConfig(int seatIndex, {PokerBotDifficulty? difficulty, PokerBotPersonality? personality}) {
    final current = _seats[seatIndex];
    if (current == null || !current.isBot) return;

    setState(() {
      _seats[seatIndex] = current.copyWith(
        botDifficulty: difficulty ?? current.botDifficulty,
        botPersonality: personality ?? current.botPersonality,
        name: '${personality?.displayName ?? current.botPersonality!.displayName} Bot ${seatIndex + 1}',
      );
    });
  }

  void _launchGame() {
    _audio.playClick();
    _audio.stopMusic();

    final List<PokerPlayer> activePlayers = [];
    for (var seat in _seats) {
      if (seat != null) {
        activePlayers.add(seat);
      }
    }

    if (activePlayers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 2 players are required to start a Texas Hold\'em game.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PokerGameScreen(
          startingMoney: _startingMoney,
          players: activePlayers,
          smallBlind: _smallBlind,
          bigBlind: _bigBlind,
          feltTheme: _feltTheme,
          isFastMode: _isFastMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CUSTOM POKER ROOM', style: TextStyle(letterSpacing: 2, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: CasinoTheme.bgDarker,
        foregroundColor: CasinoTheme.accentNeonCyan,
        centerTitle: true,
      ),
      body: Container(
        color: CasinoTheme.bgDarker,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Felt Style
                const Text('TABLE STYLE', style: TextStyle(color: CasinoTheme.accentNeonCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _feltThemes.map((theme) {
                    final isSelected = _feltTheme == theme;
                    final tableStyle = CasinoTheme.getTableStyle(theme);
                    final color = tableStyle.feltDeep;
                    final label = tableStyle.displayName.split(' ').first;

                    return GestureDetector(
                      onTap: () {
                        _audio.playClick();
                        setState(() => _feltTheme = theme);
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? CasinoTheme.accentNeonCyan : Colors.white24,
                                width: isSelected ? 2.5 : 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(label, style: TextStyle(fontSize: 10, color: isSelected ? CasinoTheme.accentNeonCyan : Colors.white70)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Table Economics
                const Text('ROOM STAKES & LIMITS', style: TextStyle(color: CasinoTheme.accentNeonCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 12),
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
                  child: Column(
                    children: [
                      // Chips
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Starting Stack', style: TextStyle(fontSize: 14)),
                          Text('\$${_startingMoney.toStringAsFixed(0)}', style: const TextStyle(color: CasinoTheme.accentNeonCyan, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: _startingMoney,
                        min: 200,
                        max: 10000,
                        divisions: 98,
                        activeColor: CasinoTheme.accentNeonCyan,
                        inactiveColor: CasinoTheme.lobbyDivider,
                        onChanged: (val) {
                          setState(() => _startingMoney = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      // Small Blind
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Small Blind', style: TextStyle(fontSize: 14)),
                          Text('\$${_smallBlind.toInt()}', style: const TextStyle(color: CasinoTheme.accentNeonCyan, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: _smallBlind,
                        min: 5,
                        max: 100,
                        divisions: 19,
                        activeColor: CasinoTheme.accentNeonCyan,
                        inactiveColor: CasinoTheme.lobbyDivider,
                        onChanged: (val) {
                          setState(() {
                            _smallBlind = val;
                            _bigBlind = _smallBlind * 2; // BB is always 2x SB in standard rooms
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Fast Mode
                      SwitchListTile(
                        title: const Text('Fast Action Timer (8s)', style: TextStyle(fontSize: 14, color: Colors.white)),
                        subtitle: const Text('Standard turn timer is 15s', style: TextStyle(fontSize: 11, color: Colors.white70)),
                        tileColor: Colors.transparent,
                        value: _isFastMode,
                        activeTrackColor: CasinoTheme.accentNeonCyan.withValues(alpha: 0.4),
                        activeThumbColor: CasinoTheme.accentNeonCyan,
                        inactiveTrackColor: CasinoTheme.lobbyDivider.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onChanged: (val) {
                          setState(() => _isFastMode = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Seating
                const Text('ROOM SEATING', style: TextStyle(color: CasinoTheme.accentNeonCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 12),
                Column(
                  children: List.generate(8, (index) {
                    final player = _seats[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [CasinoTheme.lobbyCardSurface, CasinoTheme.lobbyCardDark],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: player != null
                              ? (player.isBot ? CasinoTheme.tableBorderGold.withValues(alpha: 0.3) : CasinoTheme.accentNeonCyan.withValues(alpha: 0.3))
                              : Colors.white.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      child: player == null
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Seat ${index + 1}: [ Empty ]', style: const TextStyle(color: Colors.white70)),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF132F3C),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                  onPressed: () => _addBot(index),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add Bot', style: TextStyle(fontSize: 11)),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: player.isBot ? CasinoTheme.tableBorderGold.withValues(alpha: 0.3) : CasinoTheme.accentNeonCyan.withValues(alpha: 0.3),
                                          child: Icon(
                                            player.isBot ? Icons.android : Icons.person,
                                            size: 18,
                                            color: player.isBot ? CasinoTheme.primaryGold : CasinoTheme.accentNeonCyan,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          player.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    if (index > 0)
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                        onPressed: () => _removePlayer(index),
                                      ),
                                  ],
                                ),
                                if (player.isBot) ...[
                                  const Divider(color: Colors.white10, height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<PokerBotDifficulty>(
                                          initialValue: player.botDifficulty,
                                          decoration: const InputDecoration(
                                            labelText: 'Difficulty',
                                            labelStyle: TextStyle(fontSize: 11, color: Colors.white70),
                                            isDense: true,
                                            contentPadding: EdgeInsets.all(6),
                                          ),
                                          dropdownColor: CasinoTheme.bgCard,
                                          items: PokerBotDifficulty.values.map((d) {
                                            return DropdownMenuItem(value: d, child: Text(d.name, style: const TextStyle(fontSize: 12)));
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) _updateBotConfig(index, difficulty: val);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: DropdownButtonFormField<PokerBotPersonality>(
                                          initialValue: player.botPersonality,
                                          decoration: const InputDecoration(
                                            labelText: 'Personality',
                                            labelStyle: TextStyle(fontSize: 11, color: Colors.white70),
                                            isDense: true,
                                            contentPadding: EdgeInsets.all(6),
                                          ),
                                          dropdownColor: CasinoTheme.bgCard,
                                          items: PokerBotPersonality.values.map((p) {
                                            return DropdownMenuItem(value: p, child: Text(p.displayName, style: const TextStyle(fontSize: 12)));
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) _updateBotConfig(index, personality: val);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                    );
                  }),
                ),
                const SizedBox(height: 30),

                // Launch Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CasinoTheme.accentNeonCyan,
                    foregroundColor: CasinoTheme.bgDarker,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    shadowColor: CasinoTheme.accentNeonCyan,
                    elevation: 8,
                  ),
                  onPressed: _launchGame,
                  child: const Text(
                    'LAUNCH POKER ROOM',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
