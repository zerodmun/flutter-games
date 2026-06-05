import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared_casino/theme/casino_theme.dart';
import '../../shared_casino/audio/audio_service.dart';
import '../../shared_casino/views/widgets/casino_button.dart';
import '../../shared_casino/views/widgets/exit_confirmation_dialog.dart';
import '../../shared_casino/views/widgets/chip_stack.dart';
import '../../shared_casino/views/widgets/particle_win_effect.dart';
import '../../shared_casino/services/dealer_service.dart';
import '../../shared_casino/views/widgets/dealer_message_bubble.dart';
import '../../shared_casino/services/progression_service.dart';
import '../data/models/game_state.dart';
import '../data/models/player.dart';
import '../data/models/hand.dart';
import '../viewmodels/game_view_model.dart';
import 'widgets/table_felt_painter.dart';
import 'widgets/animated_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlackjackScreen extends ConsumerStatefulWidget {
  final double startingMoney;
  final List<BlackjackPlayer> players;
  final String feltTheme;

  const BlackjackScreen({
    super.key,
    required this.startingMoney,
    required this.players,
    required this.feltTheme,
  });

  @override
  ConsumerState<BlackjackScreen> createState() => _BlackjackScreenState();
}

class _BlackjackScreenState extends ConsumerState<BlackjackScreen> {
  final AudioService _audio = AudioService();
  bool _particleActive = false;
  ChipValue _selectedChip = ChipValue.ten;

  @override
  void initState() {
    super.initState();
    _audio.playBlackjackMusic();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).initializeTable(
        startingMoney: widget.startingMoney,
        minBet: 10.0,
        maxBet: 500.0,
        seatedPlayers: widget.players,
        feltTheme: widget.feltTheme,
      );
    });
  }

  // Persists scores to SharedPreferences and awards Progression XP
  Future<void> _saveSessionResults(List<BlackjackPlayer> players) async {
    if (players.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    
    // Find the human player
    final human = players.firstWhere((p) => !p.isBot, orElse: () => players.first);
    await prefs.setDouble('balance', human.balance);

    // Increment stats
    int currentRounds = prefs.getInt('rounds_played') ?? 0;
    await prefs.setInt('rounds_played', currentRounds + 1);

    final progression = ProgressionService();
    await progression.init();

    // Base XP gained per hand played
    int totalXpGained = 10;

    // Check if won
    bool wonAny = human.hands.isNotEmpty && human.hands.any((h) => h.status == HandStatus.won || h.status == HandStatus.blackjack);
    if (wonAny) {
      int currentWins = prefs.getInt('wins') ?? 0;
      await prefs.setInt('wins', currentWins + 1);

      totalXpGained += 25; // Win bonus XP
      if (mounted && context.mounted) {
        await progression.recordWin(context);
      } else {
        await progression.recordWin();
      }
      if (mounted && context.mounted) {
        await progression.completeAchievement('first_win', context);
      } else {
        await progression.completeAchievement('first_win');
      }
    } else {
      await progression.recordLoss();
    }

    // Check natural blackjack
    bool hasBlackjack = human.hands.isNotEmpty && human.hands.any((h) => h.status == HandStatus.blackjack);
    if (hasBlackjack) {
      totalXpGained += 50; // Blackjack bonus XP
      if (mounted && context.mounted) {
        await progression.completeAchievement('blackjack_elite', context);
      } else {
        await progression.completeAchievement('blackjack_elite');
      }
    }

    // High Roller check
    bool isHighRoller = human.hands.isNotEmpty && human.hands.any((h) => h.bet >= 500);
    if (isHighRoller) {
      if (mounted && context.mounted) {
        await progression.completeAchievement('high_roller', context);
      } else {
        await progression.completeAchievement('high_roller');
      }
    }

    if (mounted && context.mounted) {
      await progression.addXp(totalXpGained, context);
    } else {
      await progression.addXp(totalXpGained);
    }
  }

  void _triggerWinParticles() {
    setState(() {
      _particleActive = true;
    });
  }

  DealerMood _getDealerMoodForStage(GameStage stage) {
    switch (stage) {
      case GameStage.betting:
        return DealerMood.neutral;
      case GameStage.dealing:
        return DealerMood.dramatic;
      case GameStage.playerTurns:
        return DealerMood.tense;
      case GameStage.dealerTurn:
        return DealerMood.dramatic;
      case GameStage.payouts:
        return DealerMood.excited;
      case GameStage.roundEnded:
        return DealerMood.congratulatory;
    }
  }

  // Returns relative (x, y) coordinates for seating 1 to 6 players in a clean arch
  List<Offset> _getSeatCoordinates(int count) {
    switch (count) {
      case 1:
        return [const Offset(0.5, 0.72)];
      case 2:
        return [const Offset(0.33, 0.71), const Offset(0.67, 0.71)];
      case 3:
        return [const Offset(0.20, 0.67), const Offset(0.50, 0.75), const Offset(0.80, 0.67)];
      case 4:
        return [
          const Offset(0.15, 0.61),
          const Offset(0.38, 0.73),
          const Offset(0.62, 0.73),
          const Offset(0.85, 0.61)
        ];
      case 5:
        return [
          const Offset(0.12, 0.58),
          const Offset(0.31, 0.71),
          const Offset(0.50, 0.77),
          const Offset(0.69, 0.71),
          const Offset(0.88, 0.58)
        ];
      case 6:
      default:
        return [
          const Offset(0.10, 0.56),
          const Offset(0.26, 0.69),
          const Offset(0.42, 0.76),
          const Offset(0.58, 0.76),
          const Offset(0.74, 0.69),
          const Offset(0.90, 0.56)
        ];
    }
  }

  // Returns a dynamic contextual text prompt based on state
  String _getContextualStatus(GameSessionState state, bool isHumanTurn) {
    if (state.players.isEmpty) {
      return 'LOADING ROYAL BLACKJACK TABLE...';
    }
    switch (state.stage) {
      case GameStage.betting:
        final human = state.players.firstWhere((p) => !p.isBot, orElse: () => state.players.first);
        final humanBet = human.hands.isNotEmpty ? human.hands.first.bet : 0.0;
        if (humanBet <= 0) return '👉 PLACE YOUR BETS • FEELING LUCKY?';
        return '💰 BET PLACED • TAP DEAL WHEN READY';
      case GameStage.playerTurns:
        if (isHumanTurn) return '🔥 DECISION TIME • ALL EYES ON YOU!';
        return '🤖 OPPONENTS ARE MAKING THEIR CHOICES...';
      case GameStage.dealerTurn:
        return '🃏 SUSPENSE BUILDS • DEALER IS DRAWING...';
      case GameStage.payouts:
        return '🎰 RESOLVING ROUND PAYOUTS...';
      case GameStage.roundEnded:
        final human = state.players.firstWhere((p) => !p.isBot, orElse: () => state.players.first);
        bool won = human.hands.isNotEmpty && human.hands.any((h) => h.status == HandStatus.won || h.status == HandStatus.blackjack);
        return won ? '🎉 VICTORY STINGER! YOU WON!' : '🎲 ROUND COMPLETED. TRY AGAIN?';
      default:
        return 'ROYAL BLACKJACK TABLE';
    }
  }

  void _showExitDialog(BuildContext context) {
    final gameState = ref.read(gameProvider);
    ExitConfirmationDialog.show(
      context,
      onResume: () {},
      onLeave: () async {
        await _saveSessionResults(gameState.players);
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      onRestart: () {
        ref.read(gameProvider.notifier).initializeTable(
          startingMoney: widget.startingMoney,
          minBet: gameState.minBet,
          maxBet: gameState.maxBet,
          seatedPlayers: widget.players,
          feltTheme: widget.feltTheme,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final isHumanTurn = !gameState.isDealerTurn && 
        gameState.currentPlayer != null && 
        !gameState.currentPlayer!.isBot;

    final isDealerFocus = gameState.stage == GameStage.dealerTurn || gameState.isDealerTurn;

    // React to round end to trigger particles & save stats
    ref.listen<GameSessionState>(gameProvider, (previous, next) {
      if (next.stage == GameStage.roundEnded && previous?.stage != GameStage.roundEnded) {
        if (next.players.isNotEmpty) {
          _saveSessionResults(next.players);
          final human = next.players.firstWhere((p) => !p.isBot, orElse: () => next.players.first);
          bool won = human.hands.isNotEmpty && human.hands.any((h) => h.status == HandStatus.won || h.status == HandStatus.blackjack);
          if (won) {
            _audio.playVictoryStinger();
            _triggerWinParticles();
          } else {
            _audio.playLose();
          }
        }
      }
    });

    final tableStyle = CasinoTheme.getTableStyle(gameState.tableTheme);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitDialog(context);
      },
      child: Scaffold(
        backgroundColor: CasinoTheme.bgDarker,
      body: Stack(
        children: [
          // 1. Realistic Canvas Table felt
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final double height = constraints.maxHeight;

              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: TableFeltPainter(theme: gameState.tableTheme),
                    ),
                  ),

                  // TOP-LEFT Info: Running Card Count
                  Positioned(
                    top: 48,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: CasinoTheme.glassDecoration(opacity: 0.1),
                      child: Text(
                        'Count: ${gameState.stage == GameStage.betting ? "-" : "Card counting is ON"}',
                        style: TextStyle(fontSize: 11, color: tableStyle.highlightColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // TOP-RIGHT Exit / Mute panel
                  Positioned(
                    top: 44,
                    right: 16,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _audio.isMuted ? Icons.volume_off : Icons.volume_up,
                            color: CasinoTheme.primaryGold,
                          ),
                          onPressed: () {
                            _audio.toggleMute();
                            setState(() {});
                          },
                        ),
                        const SizedBox(width: 8),
                        CasinoButton(
                          onTap: () {
                            _showExitDialog(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text('Exit Table', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Dealer Seat (Center top) - Spotlight if dealer turn
                  Positioned(
                    top: height * 0.15,
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isDealerFocus ? 1.0 : (gameState.stage == GameStage.playerTurns ? 0.45 : 1.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDealerFocus ? tableStyle.highlightColor : Colors.transparent,
                                    width: 1.5,
                                  ),
                                  boxShadow: isDealerFocus ? CasinoTheme.neonGlow(color: tableStyle.highlightColor, radius: 4) : [],
                                ),
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: CasinoTheme.primaryGold.withValues(alpha: 0.2),
                                  child: const Icon(Icons.support_agent, size: 16, color: CasinoTheme.primaryGold),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'DEALER',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900, 
                                  fontSize: 13, 
                                  color: isDealerFocus ? tableStyle.highlightColor : Colors.white70,
                                ),
                              ),
                              // Score badge
                              if (gameState.dealer.hands.isNotEmpty && gameState.dealer.hands.first.cards.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: CasinoTheme.primaryGold,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: isDealerFocus ? CasinoTheme.neonGlow(color: CasinoTheme.primaryGold, radius: 4) : [],
                                  ),
                                  child: Text(
                                    '${gameState.dealer.hands.first.score}',
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Dealer Cards Row
                          SizedBox(
                            height: 94,
                            child: Center(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: List.generate(
                                  gameState.dealer.hands.isNotEmpty ? gameState.dealer.hands.first.cards.length : 0,
                                  (cIndex) {
                                    final card = gameState.dealer.hands.isNotEmpty && cIndex < gameState.dealer.hands.first.cards.length
                                        ? gameState.dealer.hands.first.cards[cIndex]
                                        : null;
                                    if (card == null) return const SizedBox.shrink();
                                    return AnimatedCard(
                                      card: card,
                                      index: cIndex,
                                      tableTheme: gameState.tableTheme,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2.5. Dealer Reactive Message Bubble
                  if (gameState.statusMessage != null && gameState.statusMessage!.isNotEmpty)
                    Positioned(
                      top: height * 0.34,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: DealerMessageBubble(
                          message: gameState.statusMessage!,
                          mood: _getDealerMoodForStage(gameState.stage),
                        ),
                      ),
                    ),

                  // 3. Curved Seated Players (with spotlights)
                  ..._buildSeatedPlayers(width, height, gameState, tableStyle),

                  // 4. Premium Contextual Prompt Bar
                  Positioned(
                    top: height * 0.49,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(gameState.stage),
                        tween: Tween<double>(begin: 0.95, end: 1.0),
                        duration: const Duration(milliseconds: 300),
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: tableStyle.highlightColor.withValues(alpha: 0.5), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: tableStyle.highlightColor.withValues(alpha: 0.15),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Text(
                                _getContextualStatus(gameState, isHumanTurn),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // 5. Action Controls Overlays (bottom)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: _buildControls(gameState, isHumanTurn, tableStyle),
                  ),
                ],
              );
            },
          ),

          // 6. Celebration Particles Layer
          ParticleWinEffect(
            isActive: _particleActive,
            onComplete: () {
              setState(() {
                _particleActive = false;
              });
            },
          ),
        ],
      ),
    ),
  );
}

  // Generates curved seat layouts dynamically with spotlight filters
  List<Widget> _buildSeatedPlayers(double width, double height, GameSessionState state, CasinoTableStyle tableStyle) {
    final coordinates = _getSeatCoordinates(state.players.length);
    final List<Widget> widgets = [];

    for (int i = 0; i < state.players.length; i++) {
      final player = state.players[i];
      final pos = coordinates[i];
      final isCurrentTurn = state.currentPlayerIndex == i && state.stage == GameStage.playerTurns;
      final bool dimOut = state.stage == GameStage.playerTurns && !isCurrentTurn;

      widgets.add(
        Positioned(
          left: (pos.dx * width) - 80, // Offset half seat width
          top: pos.dy * height,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: dimOut ? 0.45 : 1.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bot Emote speech bubble (if active)
                if (player.lastEmote != null) ...[
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 250),
                    builder: (context, opacity, child) {
                      return Opacity(
                        opacity: opacity,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            color: CasinoTheme.bgCard,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4),
                            ],
                          ),
                          child: Text(
                            player.lastEmote!,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                  ],

                // Player Card Stack representation
                SizedBox(
                  height: 94,
                  width: 140,
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: List.generate(
                        player.hands.isNotEmpty ? player.hands.first.cards.length : 0,
                        (cIndex) {
                          final card = player.hands.isNotEmpty && cIndex < player.hands.first.cards.length
                              ? player.hands.first.cards[cIndex]
                              : null;
                          if (card == null) return const SizedBox.shrink();
                          return AnimatedCard(
                            card: card,
                            index: cIndex,
                            tableTheme: state.tableTheme,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Chip bet stack positioning
                if (player.hands.isNotEmpty && player.hands.first.bet > 0) ...[
                  ChipStack(totalBet: player.hands.first.bet),
                  const SizedBox(height: 4),
                ],

                // Player Identity Capsule (Glowing active ring)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 130,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCurrentTurn ? tableStyle.highlightColor.withValues(alpha: 0.22) : Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrentTurn 
                          ? tableStyle.highlightColor 
                          : (player.isBot ? tableStyle.linePatternColor.withValues(alpha: 0.3) : Colors.white24),
                      width: isCurrentTurn ? 2.0 : 1.0,
                    ),
                    boxShadow: isCurrentTurn ? CasinoTheme.neonGlow(color: tableStyle.highlightColor, radius: 8) : [],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              player.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isCurrentTurn ? FontWeight.bold : FontWeight.normal,
                                color: isCurrentTurn ? tableStyle.highlightColor : Colors.white,
                              ),
                            ),
                          ),
                          // Hand Score Badge
                          if (player.hands.isNotEmpty && player.hands.first.cards.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: player.isBusted ? Colors.red.shade900 : tableStyle.linePatternColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${player.hands.first.score}',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${player.balance.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 10, color: CasinoTheme.textGold, fontWeight: FontWeight.w600),
                          ),
                          // Hand result tag
                          if (state.stage == GameStage.roundEnded && player.hands.isNotEmpty)
                            Text(
                              _getHandResultText(player.hands.first.status),
                              style: TextStyle(
                                fontSize: 9, 
                                fontWeight: FontWeight.bold,
                                color: _getHandResultColor(player.hands.first.status),
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
      );
    }
    return widgets;
  }

  String _getHandResultText(HandStatus status) {
    switch (status) {
      case HandStatus.won: return 'WON';
      case HandStatus.blackjack: return 'BJ';
      case HandStatus.lost: return 'LOST';
      case HandStatus.busted: return 'BUST';
      case HandStatus.push: return 'PUSH';
      case HandStatus.surrendered: return 'SURR';
      default: return '';
    }
  }

  Color _getHandResultColor(HandStatus status) {
    switch (status) {
      case HandStatus.won:
      case HandStatus.blackjack:
        return Colors.greenAccent;
      case HandStatus.lost:
      case HandStatus.busted:
        return Colors.redAccent;
      case HandStatus.push:
        return Colors.amberAccent;
      default:
        return Colors.grey;
    }
  }

  // Renders different controls panels based on active game stage (betting, playing, round ended)
  Widget _buildControls(GameSessionState state, bool isHumanTurn, CasinoTableStyle tableStyle) {
    if (state.players.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: CasinoTheme.glassDecoration(borderRadius: 16),
        child: const Center(
          child: CircularProgressIndicator(color: CasinoTheme.primaryGold),
        ),
      );
    }

    if (state.stage == GameStage.betting) {
      final human = state.players.firstWhere((p) => !p.isBot, orElse: () => state.players.first);
      final humanBet = human.hands.isNotEmpty ? human.hands.first.bet : 0.0;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: CasinoTheme.glassDecoration(borderRadius: 16, opacity: 0.15),
        child: Column(
          children: [
            // Current Bet and Player Cash status
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Balance: \$${human.balance.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Current Bet: \$${humanBet.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 13, color: tableStyle.highlightColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Chip Selectors
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ChipValue.values.map((chip) {
                return BetChip(
                  chip: chip,
                  isSelected: _selectedChip == chip,
                  onTap: () {
                    _audio.playClick();
                    setState(() => _selectedChip = chip);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Place Bet Actions
            Row(
              children: [
                Expanded(
                  child: CasinoButton(
                    onTap: () {
                      ref.read(gameProvider.notifier).placeBet(0, _selectedChip.value);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: CasinoTheme.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      alignment: Alignment.center,
                      child: Text('Add \$${_selectedChip.value.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CasinoButton(
                    enabled: humanBet > 0,
                    onTap: () {
                      ref.read(gameProvider.notifier).clearBet(0);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                      ),
                      alignment: Alignment.center,
                      child: Text('Clear', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CasinoButton(
                    enabled: humanBet > 0,
                    onTap: () {
                      ref.read(gameProvider.notifier).startRound();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: CasinoTheme.primaryGold,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: CasinoTheme.neonGlow(color: CasinoTheme.primaryGold, radius: 4),
                      ),
                      alignment: Alignment.center,
                      child: const Text('DEAL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (state.stage == GameStage.playerTurns) {
      if (!isHumanTurn) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: CasinoTheme.glassDecoration(),
          child: Text(
            'Bots are making choices...', 
            style: TextStyle(color: tableStyle.highlightColor, fontWeight: FontWeight.bold),
          ),
        );
      }

      // Human is making decision
      final human = state.currentPlayer;
      if (human == null || state.currentHandIndex < 0 || state.currentHandIndex >= human.hands.length) {
        return const SizedBox.shrink();
      }
      final hand = human.hands[state.currentHandIndex];
      final canDouble = human.balance >= hand.bet;
      final canSplit = hand.cards.length == 2 && 
          hand.cards[0].rank.value == hand.cards[1].rank.value && 
          human.hands.length < 4 &&
          human.balance >= hand.bet;
      final canSurrender = hand.cards.length == 2 && !hand.isFromSplit;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: CasinoTheme.glassDecoration(borderRadius: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton('HIT', tableStyle.highlightColor, () {
                  ref.read(gameProvider.notifier).hit();
                }),
                const SizedBox(width: 8),
                _buildActionButton('STAND', CasinoTheme.primaryGold, () {
                  ref.read(gameProvider.notifier).stand();
                }),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSecondaryButton('DOUBLE', canDouble, () {
                  ref.read(gameProvider.notifier).doubleDown();
                }),
                const SizedBox(width: 8),
                _buildSecondaryButton('SPLIT', canSplit, () {
                  ref.read(gameProvider.notifier).split();
                }),
                const SizedBox(width: 8),
                _buildSecondaryButton('SURRENDER', canSurrender, () {
                  ref.read(gameProvider.notifier).surrender();
                }),
              ],
            ),
          ],
        ),
      );
    }

    if (state.stage == GameStage.dealerTurn || state.stage == GameStage.payouts) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: CasinoTheme.glassDecoration(),
        child: const CircularProgressIndicator(color: CasinoTheme.primaryGold),
      );
    }

    if (state.stage == GameStage.roundEnded) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: CasinoTheme.glassDecoration(borderRadius: 16),
        child: CasinoButton(
          onTap: () {
            ref.read(gameProvider.notifier).startNewRound();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: CasinoTheme.feltGreenLight,
              borderRadius: BorderRadius.circular(12),
              boxShadow: CasinoTheme.neonGlow(color: CasinoTheme.feltGreenLight, radius: 4),
            ),
            alignment: Alignment.center,
            child: Text('PLAY NEXT ROUND', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 2.0, color: Colors.white)),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionButton(String label, Color neonColor, VoidCallback onTap) {
    return Expanded(
      child: CasinoButton(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: CasinoTheme.bgDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: neonColor, width: 1.5),
            boxShadow: CasinoTheme.neonGlow(color: neonColor, radius: 4),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 14, color: neonColor),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String label, bool enabled, VoidCallback onTap) {
    return Expanded(
      child: CasinoButton(
        enabled: enabled,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: enabled ? CasinoTheme.bgCard : Colors.black12,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: enabled ? Colors.white24 : Colors.transparent),
          ),
          alignment: Alignment.center,
          child: Text(
            label, 
            style: TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.bold,
              color: enabled ? Colors.white : Colors.white38,
            ),
          ),
        ),
      ),
    );
  }
}
