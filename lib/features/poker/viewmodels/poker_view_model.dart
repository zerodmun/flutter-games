import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/poker_card.dart';
import '../data/models/poker_player.dart';
import '../data/models/poker_state.dart';
import '../data/models/poker_hand_score.dart';
import 'poker_ai_manager.dart';
import 'poker_hand_evaluator.dart';
import '../../shared_casino/audio/audio_service.dart';

final pokerProvider = StateNotifierProvider<PokerViewModel, PokerGameState>((ref) {
  return PokerViewModel();
});

class PokerViewModel extends StateNotifier<PokerGameState> {
  final AudioService _audio = AudioService();
  final Random _random = Random();
  Timer? _turnTimer;

  PokerViewModel() : super(const PokerGameState());

  @override
  void dispose() {
    _turnTimer?.cancel();
    super.dispose();
  }

  void stopTimer() {
    _turnTimer?.cancel();
  }

  void toggleFastForward() {
    state = state.copyWith(isFastForward: !state.isFastForward);
  }

  void skipToResult() {
    _turnTimer?.cancel();
    state = state.copyWith(isFastForward: true);

    // If it is the human player's turn to act (not folded and active), auto-fold/check them
    final humanIndex = state.players.indexWhere((p) => !p.isBot);
    if (humanIndex >= 0 && state.currentPlayerIndex == humanIndex && state.stage != PokerStage.showdown && state.stage != PokerStage.roundEnded) {
      final human = state.players[humanIndex];
      if (human.status == PokerPlayerStatus.active) {
        final toCall = state.currentBetToCall - human.roundBet;
        if (toCall <= 0) {
          executeAction(PokerAction.check());
        } else {
          executeAction(PokerAction.fold());
        }
      }
    }
  }

  /// Initializes the table with seated players and configuration.
  void initializeTable({
    required double startingMoney,
    required double smallBlind,
    required double bigBlind,
    required List<PokerPlayer> seatedPlayers,
    required String feltTheme,
    bool isFastMode = false,
  }) {
    _turnTimer?.cancel();

    final players = seatedPlayers.map((p) {
      return p.copyWith(
        balance: startingMoney,
        cards: const [],
        status: PokerPlayerStatus.active,
        roundBet: 0.0,
        totalContributed: 0.0,
        lastAction: null,
        lastEmote: null,
        hasActed: false,
      );
    }).toList();

    state = PokerGameState(
      players: players,
      communityCards: const [],
      deck: const [],
      dealerIndex: 0,
      currentPlayerIndex: 0,
      stage: PokerStage.blinds,
      pot: 0.0,
      currentRaise: bigBlind,
      smallBlind: smallBlind,
      bigBlind: bigBlind,
      statusMessage: 'Welcome to Texas Hold\'em! Blinds starting.',
      roundNumber: 1,
      tableTheme: feltTheme,
      currentBetToCall: bigBlind,
      turnTimeLeft: isFastMode ? 8 : 15,
      isFastMode: isFastMode,
    );
  }

  /// Starts the round by shuffling, collecting blinds, and dealing pocket cards.
  Future<void> startRound() async {
    _turnTimer?.cancel();
    if (state.players.length < 2) return;

    // Filter out players who are out of chips
    final activePlayers = state.players.map((p) {
      return p.copyWith(
        cards: const [],
        status: p.balance <= 0 ? PokerPlayerStatus.outOfChips : PokerPlayerStatus.active,
        roundBet: 0.0,
        totalContributed: 0.0,
        lastAction: null,
        lastEmote: null,
        hasActed: false,
      );
    }).toList();

    // Check if we have enough playable players (at least 2)
    final playableCount = activePlayers.where((p) => p.status != PokerPlayerStatus.outOfChips).length;
    if (playableCount < 2) {
      state = state.copyWith(statusMessage: 'Not enough players with chips to start!');
      return;
    }

    // Create shoe deck (52 cards)
    final deck = _generateDeck();

    state = state.copyWith(
      players: activePlayers,
      communityCards: const [],
      deck: deck,
      stage: PokerStage.blinds,
      pot: 0.0,
      currentBetToCall: state.bigBlind,
      currentRaise: state.bigBlind,
      statusMessage: 'Placing blinds...',
    );

    // Apply blinds forced bets
    final updatedPlayers = List<PokerPlayer>.from(state.players);
    final sbIndex = (state.dealerIndex + 1) % updatedPlayers.length;
    final bbIndex = (state.dealerIndex + 2) % updatedPlayers.length;

    // Small blind payment
    final sbPlayer = updatedPlayers[sbIndex];
    final sbAmount = min(state.smallBlind, sbPlayer.balance);
    updatedPlayers[sbIndex] = sbPlayer.copyWith(
      balance: sbPlayer.balance - sbAmount,
      roundBet: sbAmount,
      totalContributed: sbAmount,
      lastAction: 'SB \$${sbAmount.toStringAsFixed(0)}',
      status: sbAmount == sbPlayer.balance ? PokerPlayerStatus.allIn : PokerPlayerStatus.active,
    );

    // Big blind payment
    final bbPlayer = updatedPlayers[bbIndex];
    final bbAmount = min(state.bigBlind, bbPlayer.balance);
    updatedPlayers[bbIndex] = bbPlayer.copyWith(
      balance: bbPlayer.balance - bbAmount,
      roundBet: bbAmount,
      totalContributed: bbAmount,
      lastAction: 'BB \$${bbAmount.toStringAsFixed(0)}',
      status: bbAmount == bbPlayer.balance ? PokerPlayerStatus.allIn : PokerPlayerStatus.active,
    );

    _audio.playChipsBet();
    await Future.delayed(Duration(milliseconds: state.isFastForward ? 10 : 800));
    if (!mounted) return;

    // Deal pocket cards (2 to each active player)
    final activeDeck = List<PokerCard>.from(state.deck);
    for (int c = 0; c < 2; c++) {
      for (int i = 0; i < updatedPlayers.length; i++) {
        final p = updatedPlayers[i];
        if (p.isEliminated) continue;

        final card = activeDeck.removeLast().copyWith(isFaceUp: !p.isBot);
        final updatedCards = List<PokerCard>.from(p.cards)..add(card);
        updatedPlayers[i] = p.copyWith(cards: updatedCards);
        _audio.playCardSlide();
        await Future.delayed(Duration(milliseconds: state.isFastForward ? 5 : 200));
        if (!mounted) return;
      }
    }

    // Preflop: Turn action starts next to Big Blind
    final preflopStarter = (bbIndex + 1) % updatedPlayers.length;

    state = state.copyWith(
      players: updatedPlayers,
      deck: activeDeck,
      stage: PokerStage.preFlop,
      currentPlayerIndex: preflopStarter,
      currentBetToCall: state.bigBlind,
      statusMessage: 'Pre-flop betting round starts.',
    );

    _startTimer();
    _checkNextPlayerOrBot();
  }

  /// Generates a standard deck of 52 cards.
  List<PokerCard> _generateDeck() {
    final List<PokerCard> newDeck = [];
    for (var suit in PokerSuit.values) {
      for (var rank in PokerRank.values) {
        newDeck.add(PokerCard(suit: suit, rank: rank, isFaceUp: false));
      }
    }
    newDeck.shuffle(_random);
    return newDeck;
  }

  /// Starts the active turn timer.
  void _startTimer() {
    _turnTimer?.cancel();
    state = state.copyWith(turnTimeLeft: state.isFastMode ? 8 : 15);
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (state.turnTimeLeft <= 1) {
        timer.cancel();
        _handleTimeout();
      } else {
        state = state.copyWith(turnTimeLeft: state.turnTimeLeft - 1);
      }
    });
  }

  /// Automatically calls check/fold on time expiry.
  void _handleTimeout() {
    final toCall = state.currentBetToCall - (state.currentPlayer?.roundBet ?? 0.0);
    if (toCall <= 0) {
      executeAction(PokerAction.check());
    } else {
      executeAction(PokerAction.fold());
    }
  }

  /// Handles action submission (Fold, Check, Call, Raise, All-in) for the current player.
  void executeAction(PokerAction action) {
    _turnTimer?.cancel();

    final players = List<PokerPlayer>.from(state.players);
    final playerIndex = state.currentPlayerIndex;
    final player = players[playerIndex];

    final toCall = state.currentBetToCall - player.roundBet;
    double currentBetToCall = state.currentBetToCall;
    double currentRaise = state.currentRaise;

    var updatedStatus = player.status;
    double roundBet = player.roundBet;
    double totalContr = player.totalContributed;
    double balance = player.balance;
    String actionLabel = '';

    switch (action.type) {
      case PokerActionType.fold:
        updatedStatus = PokerPlayerStatus.folded;
        actionLabel = 'Folded';
        break;

      case PokerActionType.check:
        if (toCall > 0) {
          // If they cannot check, forcefold
          updatedStatus = PokerPlayerStatus.folded;
          actionLabel = 'Folded';
        } else {
          actionLabel = 'Check';
        }
        break;

      case PokerActionType.call:
        final callAmount = min(toCall, balance);
        balance -= callAmount;
        roundBet += callAmount;
        totalContr += callAmount;
        if (balance <= 0) {
          updatedStatus = PokerPlayerStatus.allIn;
          actionLabel = 'All-in Call \$${roundBet.toStringAsFixed(0)}';
        } else {
          actionLabel = 'Call \$${roundBet.toStringAsFixed(0)}';
        }
        _audio.playChipsBet();
        break;

      case PokerActionType.raise:
        final raiseDiff = toCall + action.amount;
        final actualBet = min(raiseDiff, balance);
        balance -= actualBet;
        roundBet += actualBet;
        totalContr += actualBet;

        currentBetToCall = roundBet;
        currentRaise = action.amount; // Raise minimum is updated

        // Mark all other active players hasActed = false so they must respond to the raise
        for (int i = 0; i < players.length; i++) {
          if (i != playerIndex && players[i].status != PokerPlayerStatus.folded && players[i].status != PokerPlayerStatus.allIn && !players[i].isEliminated) {
            players[i] = players[i].copyWith(hasActed: false);
          }
        }

        if (balance <= 0) {
          updatedStatus = PokerPlayerStatus.allIn;
          actionLabel = 'All-in Raise \$${roundBet.toStringAsFixed(0)}';
        } else {
          actionLabel = 'Raise \$${roundBet.toStringAsFixed(0)}';
        }
        _audio.playChipsBet();
        break;

      case PokerActionType.allIn:
        final allInBet = balance;
        balance = 0;
        roundBet += allInBet;
        totalContr += allInBet;

        if (roundBet > currentBetToCall) {
          final raiseAmount = roundBet - currentBetToCall;
          currentBetToCall = roundBet;
          currentRaise = raiseAmount;

          for (int i = 0; i < players.length; i++) {
            if (i != playerIndex && players[i].status != PokerPlayerStatus.folded && players[i].status != PokerPlayerStatus.allIn && !players[i].isEliminated) {
              players[i] = players[i].copyWith(hasActed: false);
            }
          }
        }

        updatedStatus = PokerPlayerStatus.allIn;
        actionLabel = 'All-in \$${roundBet.toStringAsFixed(0)}';
        _audio.playChipsBet();
        break;
    }

    players[playerIndex] = player.copyWith(
      balance: balance,
      roundBet: roundBet,
      totalContributed: totalContr,
      status: updatedStatus,
      lastAction: actionLabel,
      hasActed: true,
    );

    state = state.copyWith(
      players: players,
      currentBetToCall: currentBetToCall,
      currentRaise: currentRaise,
      statusMessage: '${player.name}: $actionLabel',
    );

    // Compute next player
    _moveToNextPlayer();
  }

  /// Finds the next active player or concludes the betting round if everyone has acted.
  void _moveToNextPlayer() {
    final activePlayable = state.players.where((p) => p.status == PokerPlayerStatus.active).toList();
    final notFolded = state.players.where((p) => p.status != PokerPlayerStatus.folded && !p.isEliminated).toList();

    // 1. Check if only one player is remaining (everyone else folded)
    if (notFolded.length == 1) {
      _awardPotToSingleWinner(notFolded.first);
      return;
    }

    // 2. Check if all playable players have acted and bets are matched
    bool roundFinished = true;
    
    // Bets are matched if all active players roundBets are equal to currentBetToCall
    for (var p in state.players) {
      if (p.status == PokerPlayerStatus.active) {
        if (!p.hasActed || p.roundBet < state.currentBetToCall) {
          roundFinished = false;
          break;
        }
      }
    }

    if (roundFinished || activePlayable.isEmpty) {
      _concludeBettingRound();
    } else {
      // Find the next active player to the left
      int nextIndex = state.currentPlayerIndex;
      do {
        nextIndex = (nextIndex + 1) % state.players.length;
      } while (state.players[nextIndex].status != PokerPlayerStatus.active);

      state = state.copyWith(currentPlayerIndex: nextIndex);
      _startTimer();
      _checkNextPlayerOrBot();
    }
  }

  /// Concludes the current betting stage, sweeps chips into pot, and deals the next community cards.
  Future<void> _concludeBettingRound() async {
    _turnTimer?.cancel();

    // Sweep chips to main pot
    double additionalPot = 0.0;
    final updatedPlayers = state.players.map((p) {
      additionalPot += p.roundBet;
      return p.copyWith(
        roundBet: 0.0,
        hasActed: false,
      );
    }).toList();

    state = state.copyWith(
      players: updatedPlayers,
      pot: state.pot + additionalPot,
      currentBetToCall: 0.0,
      currentRaise: state.bigBlind,
    );

    final notFoldedAndNotAllIn = state.players.where((p) => p.status == PokerPlayerStatus.active).toList();

    // If there are less than 2 players who can make betting decisions (e.g. all in), just run out board
    if (notFoldedAndNotAllIn.length < 2 && state.stage != PokerStage.river) {
      state = state.copyWith(statusMessage: 'All-in showdown! Dealing cards...');
      await Future.delayed(Duration(milliseconds: state.isFastForward ? 10 : 1000));
      if (!mounted) return;
      _runOutBoard();
      return;
    }

    // Transition to next stage
    switch (state.stage) {
      case PokerStage.preFlop:
        _dealFlop();
        break;
      case PokerStage.flop:
        _dealTurn();
        break;
      case PokerStage.turn:
        _dealRiver();
        break;
      case PokerStage.river:
        _resolvePayouts();
        break;
      default:
        break;
    }
  }

  /// Deals 3 community cards (Flop).
  Future<void> _dealFlop() async {
    final activeDeck = List<PokerCard>.from(state.deck);
    final community = <PokerCard>[];

    // Burn 1 card
    activeDeck.removeLast();

    // Deal 3 Flop cards
    for (int i = 0; i < 3; i++) {
      community.add(activeDeck.removeLast().copyWith(isFaceUp: true));
      _audio.playCardSlide();
      await Future.delayed(Duration(milliseconds: state.isFastForward ? 5 : 300));
      if (!mounted) return;
    }

    // Starting action postflop is small blind (first player to left of dealer button)
    final nextIndex = _getFirstActiveToLeft(state.dealerIndex);

    state = state.copyWith(
      deck: activeDeck,
      communityCards: community,
      stage: PokerStage.flop,
      currentPlayerIndex: nextIndex,
      statusMessage: 'Dealing the Flop.',
    );

    _startTimer();
    _checkNextPlayerOrBot();
  }

  /// Deals 1 community card (Turn).
  Future<void> _dealTurn() async {
    final activeDeck = List<PokerCard>.from(state.deck);
    final community = List<PokerCard>.from(state.communityCards);

    // Burn 1 card
    activeDeck.removeLast();

    // Deal Turn card
    community.add(activeDeck.removeLast().copyWith(isFaceUp: true));
    _audio.playCardSlide();
    await Future.delayed(Duration(milliseconds: state.isFastForward ? 5 : 300));
    if (!mounted) return;

    final nextIndex = _getFirstActiveToLeft(state.dealerIndex);

    state = state.copyWith(
      deck: activeDeck,
      communityCards: community,
      stage: PokerStage.turn,
      currentPlayerIndex: nextIndex,
      statusMessage: 'Dealing the Turn.',
    );

    _startTimer();
    _checkNextPlayerOrBot();
  }

  /// Deals 1 community card (River).
  Future<void> _dealRiver() async {
    final activeDeck = List<PokerCard>.from(state.deck);
    final community = List<PokerCard>.from(state.communityCards);

    // Burn 1 card
    activeDeck.removeLast();

    // Deal River card
    community.add(activeDeck.removeLast().copyWith(isFaceUp: true));
    _audio.playCardSlide();
    await Future.delayed(Duration(milliseconds: state.isFastForward ? 5 : 300));
    if (!mounted) return;

    final nextIndex = _getFirstActiveToLeft(state.dealerIndex);

    state = state.copyWith(
      deck: activeDeck,
      communityCards: community,
      stage: PokerStage.river,
      currentPlayerIndex: nextIndex,
      statusMessage: 'Dealing the River.',
    );

    _startTimer();
    _checkNextPlayerOrBot();
  }

  /// Deals remaining community cards to showdown automatically (Run-out board).
  Future<void> _runOutBoard() async {
    final activeDeck = List<PokerCard>.from(state.deck);
    final community = List<PokerCard>.from(state.communityCards);

    while (community.length < 5) {
      // Burn 1
      activeDeck.removeLast();
      // Deal 1
      community.add(activeDeck.removeLast().copyWith(isFaceUp: true));
      _audio.playCardSlide();
      await Future.delayed(Duration(milliseconds: state.isFastForward ? 5 : 400));
      if (!mounted) return;
    }

    state = state.copyWith(
      deck: activeDeck,
      communityCards: community,
      stage: PokerStage.river,
    );

    await Future.delayed(Duration(milliseconds: state.isFastForward ? 10 : 600));
    if (!mounted) return;
    _resolvePayouts();
  }

  /// Gets the first active player index to the left of the dealer button.
  int _getFirstActiveToLeft(int dealerIdx) {
    int idx = dealerIdx;
    do {
      idx = (idx + 1) % state.players.length;
    } while (state.players[idx].status == PokerPlayerStatus.folded || state.players[idx].isEliminated);
    return idx;
  }

  /// Directly awards pot to the only player remaining after everyone else folds.
  void _awardPotToSingleWinner(PokerPlayer winner) {
    _turnTimer?.cancel();

    final updatedPlayers = state.players.map((p) {
      double reward = 0.0;
      if (p.id == winner.id) {
        reward = state.pot + p.roundBet; // Sweep current round bet too
      }
      return p.copyWith(
        balance: p.balance + reward,
        lastAction: reward > 0 ? 'Won \$${reward.toStringAsFixed(0)} (Folds)' : 'Folded',
        roundBet: 0.0,
      );
    }).toList();

    _audio.playChipsWin();

    state = state.copyWith(
      players: updatedPlayers,
      pot: 0.0,
      stage: PokerStage.roundEnded,
      statusMessage: '${winner.name} wins the pot of \$${state.pot.toStringAsFixed(0)} because everyone folded.',
    );
  }

  /// Resolves the winning hands and side pots.
  void _resolvePayouts() {
    final activePlayers = state.players.where((p) => p.status != PokerPlayerStatus.folded && !p.isEliminated).toList();

    if (activePlayers.isEmpty) {
      state = state.copyWith(stage: PokerStage.roundEnded, statusMessage: 'No players left in the hand.');
      return;
    }

    // Evaluate hands for active players
    final scores = <String, PokerHandScore>{};
    for (var p in activePlayers) {
      scores[p.id] = PokerHandEvaluator.getBestHand([...p.cards, ...state.communityCards]);
    }

    // Reveal bot pocket cards for showdown
    final revealedPlayers = state.players.map((p) {
      return p.copyWith(
        cards: p.cards.map((c) => c.copyWith(isFaceUp: true)).toList(),
      );
    }).toList();

    // Side pot resolution using contribution tiering
    final sortedContr = revealedPlayers.where((p) => p.totalContributed > 0).toList()
      ..sort((a, b) => a.totalContributed.compareTo(b.totalContributed));

    final payouts = <String, double>{};
    double lastTier = 0.0;

    for (var tierPlayer in sortedContr) {
      final currentTierVal = tierPlayer.totalContributed;
      final tierDiff = currentTierVal - lastTier;
      if (tierDiff <= 0) continue;

      // Calculate total chips in this contribution tier
      double tierPot = 0.0;
      final eligiblePlayers = <PokerPlayer>[];

      for (var p in revealedPlayers) {
        if (p.totalContributed >= currentTierVal) {
          tierPot += tierDiff;
          if (p.status != PokerPlayerStatus.folded && !p.isEliminated) {
            eligiblePlayers.add(p);
          }
        } else if (p.totalContributed > lastTier) {
          tierPot += p.totalContributed - lastTier;
        }
      }

      if (tierPot > 0 && eligiblePlayers.isNotEmpty) {
        // Find the best hand among eligible players
        eligiblePlayers.sort((a, b) {
          final scoreA = scores[a.id] ?? PokerHandScore.worst();
          final scoreB = scores[b.id] ?? PokerHandScore.worst();
          return scoreB.compareTo(scoreA); // descending
        });

        final bestScore = scores[eligiblePlayers.first.id] ?? PokerHandScore.worst();
        final winners = eligiblePlayers.where((p) => (scores[p.id] ?? PokerHandScore.worst()).compareTo(bestScore) == 0).toList();

        // Divide this tier pot among winners
        final share = tierPot / winners.length;
        for (var w in winners) {
          payouts[w.id] = (payouts[w.id] ?? 0.0) + share;
        }
      }

      lastTier = currentTierVal;
    }

    // Award chips to winners and update states
    final updatedPlayers = revealedPlayers.map((p) {
      final reward = payouts[p.id] ?? 0.0;
      double newBal = p.balance + reward;
      var status = p.status;
      if (newBal <= 0) {
        status = PokerPlayerStatus.outOfChips;
        newBal = 0.0;
      }
      return p.copyWith(
        balance: newBal,
        lastAction: reward > 0 ? 'Won \$${reward.toStringAsFixed(0)}' : 'Lost',
        status: status,
      );
    }).toList();

    String payoutSummary = 'Showdown: ';
    for (var p in activePlayers) {
      final reward = payouts[p.id] ?? 0.0;
      final score = scores[p.id] ?? PokerHandScore.worst();
      if (reward > 0) {
        payoutSummary += '${p.name} won \$${reward.toStringAsFixed(0)} with ${score.rank.displayName}. ';
      }
    }

    _audio.playChipsWin();

    state = state.copyWith(
      players: updatedPlayers,
      stage: PokerStage.roundEnded,
      statusMessage: payoutSummary,
    );
  }

  /// Triggers bot decision loops after a staggered thinking delay.
  Future<void> _checkNextPlayerOrBot() async {
    if (state.stage == PokerStage.showdown || state.stage == PokerStage.roundEnded) return;

    final currentPlayer = state.currentPlayer;
    if (currentPlayer == null || !currentPlayer.isBot) return;

    // Thinking delay
    await Future.delayed(Duration(milliseconds: state.isFastForward ? 10 : 700 + _random.nextInt(600)));
    if (!mounted) return;

    final decision = PokerAIManager.getBotDecision(
      bot: currentPlayer,
      communityCards: state.communityCards,
      potSize: state.pot,
      currentBetToCall: state.currentBetToCall,
      currentRaise: state.currentRaise,
    );

    final strength = PokerAIManager.estimateHandStrength(currentPlayer.cards, state.communityCards);
    final emote = PokerAIManager.getReactionEmote(currentPlayer.botPersonality ?? PokerBotPersonality.smartBalanced, strength);
    if (emote != null) {
      _updatePlayerEmote(state.currentPlayerIndex, emote);
    }

    executeAction(decision);
  }

  void _updatePlayerEmote(int playerIdx, String emote) {
    final players = List<PokerPlayer>.from(state.players);
    players[playerIdx] = players[playerIdx].copyWith(lastEmote: emote);
    state = state.copyWith(players: players);
  }

  /// Prepares the table for the next Texas Hold'em round.
  void startNewRound() {
    if (state.stage != PokerStage.roundEnded) return;

    // Filter active players and reset configurations
    final updatedPlayers = state.players.map((p) {
      return p.copyWith(
        cards: const [],
        status: p.balance <= 0 ? PokerPlayerStatus.outOfChips : PokerPlayerStatus.active,
        roundBet: 0.0,
        totalContributed: 0.0,
        lastAction: null,
        lastEmote: null,
        hasActed: false,
      );
    }).toList();

    // Rotate dealer button
    final nextDealer = (state.dealerIndex + 1) % updatedPlayers.length;

    state = state.copyWith(
      players: updatedPlayers,
      communityCards: const [],
      deck: const [],
      dealerIndex: nextDealer,
      currentPlayerIndex: nextDealer,
      stage: PokerStage.blinds,
      pot: 0.0,
      currentBetToCall: state.bigBlind,
      currentRaise: state.bigBlind,
      roundNumber: state.roundNumber + 1,
      statusMessage: 'Starting Round ${state.roundNumber + 1}! Forced blinds placement.',
    );
  }
}
