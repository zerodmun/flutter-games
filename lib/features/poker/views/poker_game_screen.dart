import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared_casino/views/widgets/exit_confirmation_dialog.dart';
import '../../shared_casino/theme/casino_theme.dart';
import '../../shared_casino/audio/audio_service.dart';
import '../../shared_casino/views/widgets/casino_button.dart';
import '../../shared_casino/views/widgets/circular_countdown_timer.dart';
import '../../shared_casino/views/widgets/chip_stack.dart';
import '../../shared_casino/views/widgets/particle_win_effect.dart';
import '../../shared_casino/services/dealer_service.dart' hide PokerStage;
import '../../shared_casino/views/widgets/dealer_message_bubble.dart';
import '../../shared_casino/services/progression_service.dart';
import '../data/models/poker_player.dart';
import '../data/models/poker_state.dart';
import '../viewmodels/poker_view_model.dart';
import '../viewmodels/poker_ai_manager.dart';
import 'widgets/animated_poker_card.dart';
import 'widgets/poker_felt_painter.dart';

class PokerGameScreen extends ConsumerStatefulWidget {
  final double startingMoney;
  final List<PokerPlayer> players;
  final double smallBlind;
  final double bigBlind;
  final String feltTheme;
  final bool isFastMode;

  const PokerGameScreen({
    super.key,
    required this.startingMoney,
    required this.players,
    required this.smallBlind,
    required this.bigBlind,
    this.feltTheme = 'classic_vegas',
    this.isFastMode = false,
  });

  @override
  ConsumerState<PokerGameScreen> createState() => _PokerGameScreenState();
}

class _PokerGameScreenState extends ConsumerState<PokerGameScreen> {
  final AudioService _audio = AudioService();
  bool _particleActive = false;
  double _raiseValue = 20.0;
  bool _showRaiseSlider = false;

  @override
  void initState() {
    super.initState();
    _audio.playPokerMusic();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pokerProvider.notifier).initializeTable(
        startingMoney: widget.startingMoney,
        smallBlind: widget.smallBlind,
        bigBlind: widget.bigBlind,
        seatedPlayers: widget.players,
        feltTheme: widget.feltTheme,
        isFastMode: widget.isFastMode,
      );
      ref.read(pokerProvider.notifier).startRound();
    });

    _raiseValue = widget.bigBlind;
  }

  // Persists stats to SharedPreferences on round complete
  Future<void> _saveSessionResults(List<PokerPlayer> players) async {
    if (players.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final human = players.firstWhere((p) => !p.isBot, orElse: () => players.first);
    await prefs.setDouble('balance', human.balance);

    int currentRounds = prefs.getInt('poker_rounds_played') ?? 0;
    await prefs.setInt('poker_rounds_played', currentRounds + 1);

    final progression = ProgressionService();
    await progression.init();

    int totalXpGained = 15; // Base XP for playing poker

    final bool won = human.lastAction != null && human.lastAction!.startsWith('Won');
    if (won) {
      int currentWins = prefs.getInt('poker_wins') ?? 0;
      await prefs.setInt('poker_wins', currentWins + 1);

      totalXpGained += 40; // Win Poker XP
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

      // Extract won amount if possible to check high roller
      final parts = human.lastAction!.split('\$');
      if (parts.length > 1) {
        final amountStr = parts[1];
        final amount = double.tryParse(amountStr) ?? 0.0;
        if (amount >= 500) {
          if (mounted && context.mounted) {
            await progression.completeAchievement('high_roller', context);
          } else {
            await progression.completeAchievement('high_roller');
          }
        }
      }
      
      // Award Poker Royal (won with 3 of a kind or better)
      if (mounted && context.mounted) {
        await progression.completeAchievement('poker_royal', context);
      } else {
        await progression.completeAchievement('poker_royal');
      }
    } else {
      await progression.recordLoss();
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

  DealerMood _getDealerMoodForPokerStage(PokerStage stage) {
    switch (stage) {
      case PokerStage.blinds:
        return DealerMood.neutral;
      case PokerStage.preFlop:
        return DealerMood.tense;
      case PokerStage.flop:
        return DealerMood.excited;
      case PokerStage.turn:
        return DealerMood.excited;
      case PokerStage.river:
        return DealerMood.dramatic;
      case PokerStage.showdown:
        return DealerMood.dramatic;
      case PokerStage.roundEnded:
        return DealerMood.congratulatory;
    }
  }

  // Seating relative coordinate offsets around the felt table
  List<Offset> _getSeatCoordinates(int count) {
    switch (count) {
      case 2:
        return [
          const Offset(0.50, 0.76), // Human bottom
          const Offset(0.50, 0.16), // Opponent top
        ];
      case 3:
        return [
          const Offset(0.50, 0.76),
          const Offset(0.20, 0.35),
          const Offset(0.80, 0.35),
        ];
      case 4:
        return [
          const Offset(0.50, 0.76),
          const Offset(0.18, 0.50),
          const Offset(0.50, 0.16),
          const Offset(0.82, 0.50),
        ];
      case 5:
        return [
          const Offset(0.50, 0.76),
          const Offset(0.18, 0.58),
          const Offset(0.28, 0.20),
          const Offset(0.72, 0.20),
          const Offset(0.82, 0.58),
        ];
      case 6:
        return [
          const Offset(0.50, 0.76),
          const Offset(0.16, 0.60),
          const Offset(0.18, 0.28),
          const Offset(0.50, 0.16),
          const Offset(0.82, 0.28),
          const Offset(0.84, 0.60),
        ];
      case 7:
        return [
          const Offset(0.50, 0.76),
          const Offset(0.16, 0.62),
          const Offset(0.16, 0.36),
          const Offset(0.35, 0.18),
          const Offset(0.65, 0.18),
          const Offset(0.84, 0.36),
          const Offset(0.84, 0.62),
        ];
      case 8:
      default:
        return [
          const Offset(0.50, 0.76),
          const Offset(0.16, 0.64),
          const Offset(0.15, 0.40),
          const Offset(0.28, 0.18),
          const Offset(0.50, 0.15),
          const Offset(0.72, 0.18),
          const Offset(0.85, 0.40),
          const Offset(0.84, 0.64),
        ];
    }
  }

  // Returns a dynamic contextual text prompt based on active Stage
  String _getContextualStatus(PokerGameState state, bool isHumanTurn) {
    switch (state.stage) {
      case PokerStage.blinds:
        return '💰 PLACING FORCED BLINDS...';
      case PokerStage.preFlop:
        if (isHumanTurn) return '🔥 DECISION TIME • YOUR POCKETS ARE DEALT!';
        return '🤖 OPPONENTS PRE-FLOP BETTING ROUND...';
      case PokerStage.flop:
        if (isHumanTurn) return '🃏 THE FLOP IS DEALT • DECISION TIME';
        return '🤖 OPPONENTS DISCUSSING THE FLOP...';
      case PokerStage.turn:
        if (isHumanTurn) return '⚡ THE TURN IS DEALT • TENSION RISES...';
        return '🤖 STAKES INCREASING ON THE TURN...';
      case PokerStage.river:
        if (isHumanTurn) return '💥 THE RIVER IS DEALT • MAKE YOUR STAND!';
        return '🤖 FINAL CALLS BEFORE THE RIVER SHOWDOWN...';
      case PokerStage.showdown:
        return '🧐 SHOWDOWN • REVEALING ALL HANDS...';
      case PokerStage.roundEnded:
        return '🏆 ROUND OVER • CHIPS AWARDED TO WINNERS';
    }
  }

  // Calculate slight natural card offsets so cards look physically dealt
  double _getCardRotationalOffset(int seatIdx, int cardIdx) {
    // Deterministic rotation based on index so it doesn't wobble on rebuilds
    final angles = [-0.06, 0.04, -0.02, 0.05, -0.04, 0.03, -0.03, 0.06];
    final baseAngle = angles[seatIdx % angles.length];
    return baseAngle + (cardIdx == 0 ? -0.015 : 0.015);
  }

  void _showExitDialog(BuildContext context) {
    final gameState = ref.read(pokerProvider);
    ExitConfirmationDialog.show(
      context,
      onResume: () {},
      onLeave: () async {
        ref.read(pokerProvider.notifier).stopTimer();
        await _saveSessionResults(gameState.players);
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      onRestart: () {
        ref.read(pokerProvider.notifier).initializeTable(
          startingMoney: widget.startingMoney,
          smallBlind: widget.smallBlind,
          bigBlind: widget.bigBlind,
          seatedPlayers: widget.players,
          feltTheme: widget.feltTheme,
          isFastMode: widget.isFastMode,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(pokerProvider);
    final humanIndex = gameState.players.indexWhere((p) => !p.isBot);
    final isHumanTurn = gameState.currentPlayerIndex == humanIndex &&
        (gameState.stage == PokerStage.preFlop ||
            gameState.stage == PokerStage.flop ||
            gameState.stage == PokerStage.turn ||
            gameState.stage == PokerStage.river);

    // Listen for payouts/round complete to save results & show particles
    ref.listen<PokerGameState>(pokerProvider, (previous, next) {
      if (next.stage == PokerStage.roundEnded && previous?.stage != PokerStage.roundEnded) {
        if (next.players.isNotEmpty) {
          _saveSessionResults(next.players);
          final human = next.players.firstWhere((p) => !p.isBot, orElse: () => next.players.first);
          if (human.lastAction != null && human.lastAction!.startsWith('Won')) {
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
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final double height = constraints.maxHeight;

              return Stack(
                children: [
                  // 1. Painted Table Felt
                  Positioned.fill(
                    child: CustomPaint(
                      painter: PokerTableFeltPainter(theme: gameState.tableTheme),
                    ),
                  ),

                  // 2. Top Header Toolbar
                  Positioned(
                    top: 48,
                    left: 16,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: CasinoTheme.glassDecoration(opacity: 0.1),
                          child: Text(
                            'Blinds: \$${gameState.smallBlind.toInt()}/\$${gameState.bigBlind.toInt()}',
                            style: TextStyle(fontSize: 11, color: tableStyle.highlightColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (gameState.isFastMode)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: CasinoTheme.neonPink,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'FAST',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                             ),
                           ),
                         ],
                    ),
                  ),

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
                            child: Text('Leave Table', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Central Pot Indicator
                  Positioned(
                    top: height * 0.28,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (gameState.pot > 0) ...[
                            ChipStack(totalBet: gameState.pot),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: CasinoTheme.glassDecoration(
                                color: Colors.black,
                                opacity: 0.5,
                                borderRadius: 12,
                              ),
                              child: Text(
                                'POT: \$${gameState.pot.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: CasinoTheme.textGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // 4. Center Community Cards Row
                  Positioned(
                    top: height * 0.38 - 38,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: 76,
                      child: Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: List.generate(
                            gameState.communityCards.length,
                            (cIndex) {
                              final card = gameState.communityCards[cIndex];
                              return Positioned(
                                left: (width - (5 * 54 + 4 * 8)) / 2 + cIndex * (54 + 8),
                                child: AnimatedPokerCard(
                                  card: card,
                                  index: cIndex,
                                  tableTheme: gameState.tableTheme,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Curated glassmorphic Dealer Message Bubble
                  if (gameState.statusMessage != null && gameState.statusMessage!.isNotEmpty)
                    Positioned(
                      top: height * 0.44,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: DealerMessageBubble(
                          message: gameState.statusMessage!,
                          mood: _getDealerMoodForPokerStage(gameState.stage),
                        ),
                      ),
                    ),

                  // 5. Curved Seats (with dimming and active timers)
                  ..._buildSeatedPlayers(width, height, gameState, tableStyle),

                  // 6. Center Contextual status message band
                  Positioned(
                    top: height * 0.52,
                    left: 20,
                    right: 20,
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
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // 7. Interactive Action Control Panels
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: _buildControlsPanel(gameState, isHumanTurn, humanIndex, tableStyle),
                  ),
                ],
              );
            },
          ),

          // Showdown Winner cinematic overlays
          if (gameState.stage == PokerStage.roundEnded)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (context, scaleVal, child) {
                      return Transform.scale(
                        scale: scaleVal,
                        child: Container(
                          width: 320,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: CasinoTheme.bgCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: CasinoTheme.primaryGold, width: 2.0),
                            boxShadow: CasinoTheme.neonGlow(color: CasinoTheme.primaryGold, radius: 15),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium, color: CasinoTheme.primaryGold, size: 48),
                              const SizedBox(height: 12),
                              const Text(
                                'ROUND OVER',
                                style: TextStyle(
                                  fontSize: 14,
                                  letterSpacing: 3.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                gameState.statusMessage ?? 'Showdown complete.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),
                              CasinoButton(
                                onTap: () {
                                  ref.read(pokerProvider.notifier).startNewRound();
                                  ref.read(pokerProvider.notifier).startRound();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: CasinoTheme.feltGreenLight,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: CasinoTheme.neonGlow(color: CasinoTheme.feltGreenLight, radius: 4),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'NEXT ROUND',
                                     style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

          // 8. Celebration Particles Layer
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

  // Seated players widgets builder (with spotlights & timers)
  List<Widget> _buildSeatedPlayers(double width, double height, PokerGameState state, CasinoTableStyle tableStyle) {
    final coordinates = _getSeatCoordinates(state.players.length);
    final List<Widget> widgets = [];

    for (int i = 0; i < state.players.length; i++) {
      final player = state.players[i];
      final pos = coordinates[i];
      final isCurrentTurn = state.currentPlayerIndex == i &&
          (state.stage == PokerStage.preFlop ||
              state.stage == PokerStage.flop ||
              state.stage == PokerStage.turn ||
              state.stage == PokerStage.river);
      final bool dimOut = (state.stage == PokerStage.preFlop ||
              state.stage == PokerStage.flop ||
              state.stage == PokerStage.turn ||
              state.stage == PokerStage.river) && !isCurrentTurn;

      widgets.add(
        Positioned(
          left: (pos.dx * width) - 70, // offset half card width
          top: pos.dy * height - 55,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: dimOut ? 0.45 : 1.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chat/Emote speech bubble
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

                // Seated Cards Pocket Row (Dealt with natural rotational offsets)
                SizedBox(
                  height: 80,
                  width: 110,
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: List.generate(
                        player.cards.length,
                        (cIndex) {
                          final card = player.cards[cIndex];
                          final rotAngle = _getCardRotationalOffset(i, cIndex);
                          return Transform.rotate(
                            angle: rotAngle,
                            child: AnimatedPokerCard(
                              card: card,
                              index: cIndex,
                              tableTheme: state.tableTheme,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Player Bet stack indicator
                if (player.roundBet > 0) ...[
                  ChipStack(totalBet: player.roundBet, chipSize: 32),
                  const SizedBox(height: 2),
                ],

                // Identity Capsule
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 120,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCurrentTurn ? tableStyle.highlightColor.withValues(alpha: 0.2) : Colors.black45,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCurrentTurn
                          ? tableStyle.highlightColor
                          : (player.isBot
                              ? tableStyle.linePatternColor.withValues(alpha: 0.3)
                              : Colors.white24),
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
                                fontSize: 10,
                                fontWeight: isCurrentTurn ? FontWeight.bold : FontWeight.normal,
                                color: isCurrentTurn ? tableStyle.highlightColor : Colors.white,
                              ),
                            ),
                          ),
                          // Dealer Button overlay
                          if (state.dealerIndex == i)
                            Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                color: CasinoTheme.primaryGold,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'D',
                                style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            player.isEliminated
                                ? 'BUSTED'
                                : '\$${player.balance.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 9,
                              color: player.isEliminated ? Colors.red : CasinoTheme.textGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // Action/Status badge
                          if (player.lastAction != null)
                            Text(
                              player.lastAction!,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: player.status == PokerPlayerStatus.folded
                                    ? Colors.grey
                                    : (player.status == PokerPlayerStatus.allIn
                                        ? CasinoTheme.neonPink
                                        : tableStyle.highlightColor),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Circular countdown timer overlay below active player
                if (isCurrentTurn) ...[
                  const SizedBox(height: 4),
                  CircularCountdownTimer(
                    timeLeft: state.turnTimeLeft,
                    totalDuration: state.isFastMode ? 8 : 15,
                    size: 26,
                    activeColor: tableStyle.highlightColor,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  // Interactive Betting Action Panel Builder
  Widget _buildControlsPanel(PokerGameState state, bool isHumanTurn, int humanIndex, CasinoTableStyle tableStyle) {
    if (state.players.isEmpty || humanIndex < 0) return const SizedBox.shrink();

    final human = state.players[humanIndex];
    if (human.isEliminated || human.status == PokerPlayerStatus.folded) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: CasinoTheme.glassDecoration(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  human.isEliminated ? 'Eliminated' : 'Folded',
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Spectating...",
                   style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Toggle Fast‑Forward',
                  onPressed: () => ref.read(pokerProvider.notifier).toggleFastForward(),
                  icon: Icon(
                    Icons.fast_forward,
                    color: state.isFastForward ? Colors.amber : Colors.white70,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Skip to Result',
                  onPressed: () => ref.read(pokerProvider.notifier).skipToResult(),
                  icon: const Icon(Icons.skip_next, color: Colors.white70),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Leave Table',
                  onPressed: () => _showExitDialog(context),
                  icon: const Icon(Icons.exit_to_app, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (!isHumanTurn) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: CasinoTheme.glassDecoration(),
        child: Text(
          'Waiting for opponents to act...',
          style: TextStyle(color: tableStyle.highlightColor, fontWeight: FontWeight.bold),
        ),
      );
    }

    final toCall = state.currentBetToCall - human.roundBet;
    final canCheck = toCall <= 0;
    final canRaise = human.balance > toCall;
    final minRaiseVal = state.currentRaise;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: CasinoTheme.glassDecoration(borderRadius: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stake indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Stack: \$${human.balance.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Text(
                toCall > 0 ? 'To Call: \$${toCall.toStringAsFixed(0)}' : 'You can Check',
                style: const TextStyle(color: CasinoTheme.textGold, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Raise Slider Overlay
          if (_showRaiseSlider && canRaise) ...[
            Row(
              children: [
                const Text('Raise Amount:', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                Text(
                  '\$${_raiseValue.toStringAsFixed(0)}',
                  style: TextStyle(color: tableStyle.highlightColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() => _showRaiseSlider = false);
                  },
                  child: const Text('Cancel', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
              ],
            ),
            Slider(
              value: _raiseValue.clamp(minRaiseVal, human.balance - toCall),
              min: minRaiseVal,
              max: human.balance - toCall,
              divisions: max(1, ((human.balance - toCall - minRaiseVal) / 10).round()),
              activeColor: tableStyle.highlightColor,
              inactiveColor: CasinoTheme.lobbyDivider,
              onChanged: (val) {
                setState(() => _raiseValue = val);
              },
            ),
            const SizedBox(height: 6),
          ],

          // Controls Row (CasinoButton Scale Physics)
          Row(
            children: [
              // FOLD BUTTON
              Expanded(
                child: CasinoButton(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ref.read(pokerProvider.notifier).executeAction(PokerAction.fold());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                    ),
                    alignment: Alignment.center,
                    child: Text('FOLD', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // CHECK/CALL BUTTON
              Expanded(
                child: CasinoButton(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (canCheck) {
                      ref.read(pokerProvider.notifier).executeAction(PokerAction.check());
                    } else {
                      ref.read(pokerProvider.notifier).executeAction(PokerAction.call());
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: CasinoTheme.feltGreenLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                      boxShadow: CasinoTheme.neonGlow(color: CasinoTheme.feltGreenLight, radius: 4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      canCheck ? 'CHECK' : 'CALL \$${toCall.toStringAsFixed(0)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // RAISE / CONFIRM RAISE BUTTON
              if (canRaise)
                Expanded(
                  child: CasinoButton(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      if (!_showRaiseSlider) {
                        setState(() {
                          _raiseValue = minRaiseVal;
                          _showRaiseSlider = true;
                        });
                      } else {
                        // If confirming raise, check if raise amount is All-In level
                        if (toCall + _raiseValue >= human.balance) {
                          _audio.playTensionStinger();
                        }
                        ref.read(pokerProvider.notifier).executeAction(PokerAction.raise(_raiseValue));
                        setState(() {
                          _showRaiseSlider = false;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: CasinoTheme.primaryGold,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: CasinoTheme.neonGlow(color: CasinoTheme.primaryGold, radius: 4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _showRaiseSlider ? 'CONFIRM RSE' : 'RAISE',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
