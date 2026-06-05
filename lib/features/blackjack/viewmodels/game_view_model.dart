import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/card.dart';
import '../data/models/hand.dart';
import '../data/models/player.dart';
import '../data/models/game_state.dart';
import 'ai_manager.dart';
import '../../shared_casino/audio/audio_service.dart';

final gameProvider = StateNotifierProvider<GameViewModel, GameSessionState>((ref) {
  return GameViewModel();
});

class GameViewModel extends StateNotifier<GameSessionState> {
  final AudioService _audio = AudioService();
  final Random _random = Random();
  int _runningCount = 0;

  GameViewModel()
      : super(
          GameSessionState(
            dealer: const BlackjackPlayer(
              id: 'dealer',
              name: 'Dealer',
              avatar: 'assets/images/dealer_avatar.png',
              isDealer: true,
            ),
          ),
        );

  /// Initializes a new table with selected human and bot players.
  void initializeTable({
    required double startingMoney,
    required double minBet,
    required double maxBet,
    required List<BlackjackPlayer> seatedPlayers,
    required String feltTheme,
  }) {
    _runningCount = 0;
    
    // Create new shoe/deck (6 decks = 312 cards)
    final deck = _generateShoe(6);

    state = GameSessionState(
      players: seatedPlayers.map((p) => p.copyWith(
        balance: startingMoney,
        hands: [const BlackjackHand(status: HandStatus.betting)],
        lastEmote: null,
      )).toList(),
      dealer: const BlackjackPlayer(
        id: 'dealer',
        name: 'Dealer',
        avatar: 'assets/images/dealer_avatar.png',
        isDealer: true,
        hands: [BlackjackHand(cards: [], status: HandStatus.betting)],
      ),
      deck: deck,
      minBet: minBet,
      maxBet: maxBet,
      tableTheme: feltTheme,
      stage: GameStage.betting,
      currentPlayerIndex: 0,
      currentHandIndex: 0,
      roundNumber: 1,
      statusMessage: 'Place your bets to start the round!',
    );
  }

  /// Shuffles and generates multiple decks of cards.
  List<BlackjackCard> _generateShoe(int numDecks) {
    final List<BlackjackCard> newDeck = [];
    for (int i = 0; i < numDecks; i++) {
      for (var suit in CardSuit.values) {
        for (var rank in CardRank.values) {
          newDeck.add(BlackjackCard(suit: suit, rank: rank, isFaceUp: false));
        }
      }
    }
    newDeck.shuffle(_random);
    return newDeck;
  }

  /// Places a bet for a specific player seat.
  void placeBet(int playerIndex, double amount) {
    if (state.stage != GameStage.betting) return;

    final updatedPlayers = List<BlackjackPlayer>.from(state.players);
    if (playerIndex < 0 || playerIndex >= updatedPlayers.length) return;
    final player = updatedPlayers[playerIndex];

    if (player.balance < amount) return;

    // Accumulate the bet amount
    double currentBet = 0.0;
    if (player.hands.isNotEmpty) {
      currentBet = player.hands.first.bet;
    }
    double newBet = currentBet + amount;

    // Deduct bet from balance and place on hand
    final updatedPlayer = player.copyWith(
      balance: player.balance - amount,
      hands: [BlackjackHand(bet: newBet, status: HandStatus.playing, cards: const [])],
      lastEmote: null,
    );

    updatedPlayers[playerIndex] = updatedPlayer;
    _audio.playChipsBet();

    state = state.copyWith(
      players: updatedPlayers,
      statusMessage: '${player.name} bet \$$newBet',
    );
  }

  /// Clears the bet for a specific player seat (refunds balance).
  void clearBet(int playerIndex) {
    if (state.stage != GameStage.betting) return;

    final updatedPlayers = List<BlackjackPlayer>.from(state.players);
    if (playerIndex < 0 || playerIndex >= updatedPlayers.length) return;
    final player = updatedPlayers[playerIndex];

    double currentBet = 0.0;
    if (player.hands.isNotEmpty) {
      currentBet = player.hands.first.bet;
    }
    if (currentBet <= 0) return;

    // Refund chips back to balance
    final updatedPlayer = player.copyWith(
      balance: player.balance + currentBet,
      hands: [const BlackjackHand(status: HandStatus.betting, cards: [])],
      lastEmote: null,
    );

    updatedPlayers[playerIndex] = updatedPlayer;
    _audio.playChipsWin();

    state = state.copyWith(
      players: updatedPlayers,
      statusMessage: '${player.name} cleared bet',
    );
  }

  /// Starts the game by dealing initial cards to players and dealer with staggered delays.
  Future<void> startRound() async {
    if (state.stage != GameStage.betting) return;

    // Verify everyone has a bet
    bool anyonePlacedBet = state.players.any((p) => p.hands.isNotEmpty && p.hands.first.bet > 0);
    if (!anyonePlacedBet) {
      state = state.copyWith(statusMessage: 'At least one player must place a bet!');
      return;
    }

    // Auto-bet for bots that haven't placed a bet yet
    final updatedPlayers = List<BlackjackPlayer>.from(state.players);
    for (int i = 0; i < updatedPlayers.length; i++) {
      final p = updatedPlayers[i];
      if (p.hands.isEmpty || p.hands.first.bet == 0) {
        double botBet = state.minBet;
        if (p.botPersonality == BotPersonality.aggressive) {
          botBet = state.minBet * 2;
        } else if (p.botPersonality == BotPersonality.riskyGambler) {
          botBet = state.minBet * (1 + _random.nextInt(3));
        }
        botBet = min(botBet, p.balance);
        botBet = max(botBet, state.minBet);

        if (p.balance >= botBet) {
          updatedPlayers[i] = p.copyWith(
            balance: p.balance - botBet,
            hands: [BlackjackHand(bet: botBet, status: HandStatus.playing, cards: const [])],
          );
        }
      }
    }

    state = state.copyWith(
      players: updatedPlayers,
      stage: GameStage.dealing,
      statusMessage: 'Dealing cards...',
    );

    // Prepare mutable deck shoe
    final activeDeck = List<BlackjackCard>.from(state.deck);

    // Helper to draw card
    BlackjackCard draw(bool faceUp) {
      if (activeDeck.isEmpty) {
        activeDeck.addAll(_generateShoe(6));
      }
      final card = activeDeck.removeLast().copyWith(isFaceUp: faceUp);
      _updateCardCount(card);
      return card;
    }

    // DEAL CARD 1 TO PLAYERS
    for (int i = 0; i < state.players.length; i++) {
      if (state.players[i].hands.isEmpty || state.players[i].hands.first.bet == 0) continue;
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _dealToPlayer(i, 0, draw(true));
    }

    // DEAL CARD 1 TO DEALER (FACE UP)
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _dealToDealer(draw(true));

    // DEAL CARD 2 TO PLAYERS
    for (int i = 0; i < state.players.length; i++) {
      if (state.players[i].hands.isEmpty || state.players[i].hands.first.bet == 0) continue;
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _dealToPlayer(i, 0, draw(true));
    }

    // DEAL CARD 2 TO DEALER (FACE DOWN / HIDDEN)
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _dealToDealer(draw(false));

    // Check for Natural Blackjacks
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _evaluateInitialBlackjacks(activeDeck);
  }

  void _dealToPlayer(int playerIndex, int handIndex, BlackjackCard card) {
    final players = List<BlackjackPlayer>.from(state.players);
    if (playerIndex < 0 || playerIndex >= players.length) return;
    final player = players[playerIndex];
    final hands = List<BlackjackHand>.from(player.hands);

    if (handIndex < 0 || handIndex >= hands.length) {
      hands.add(BlackjackHand(cards: [card], status: HandStatus.playing));
    } else {
      hands[handIndex] = hands[handIndex].addCard(card);
    }
    players[playerIndex] = player.copyWith(hands: hands);

    _audio.playCardSlide();
    state = state.copyWith(players: players);
  }

  void _dealToDealer(BlackjackCard card) {
    final dealer = state.dealer;
    final hands = List<BlackjackHand>.from(dealer.hands);

    if (hands.isEmpty) {
      hands.add(BlackjackHand(cards: [card], status: HandStatus.playing));
    } else {
      hands[0] = hands[0].addCard(card);
    }
    _audio.playCardSlide();

    state = state.copyWith(
      dealer: dealer.copyWith(hands: hands),
    );
  }

  void _updateCardCount(BlackjackCard card) {
    if (!card.isFaceUp) return;
    if (card.rank.value >= 10) {
      _runningCount--;
    } else if (card.rank.value <= 6) {
      _runningCount++;
    }
  }

  void _evaluateInitialBlackjacks(List<BlackjackCard> activeDeck) {
    if (state.dealer.hands.isEmpty) {
      state = state.copyWith(
        deck: activeDeck,
        stage: GameStage.playerTurns,
        currentPlayerIndex: 0,
      );
      _moveToNextActiveTurn();
      return;
    }
    final dealerHand = state.dealer.hands.first;

    // Check if dealer up-card is Ace (offer insurance)
    if (dealerHand.cards.isNotEmpty && dealerHand.cards.first.rank == CardRank.ace) {
      state = state.copyWith(
        deck: activeDeck,
        stage: GameStage.playerTurns,
        currentPlayerIndex: 0,
        statusMessage: 'Dealer shows Ace. Hand continues.',
      );
      _moveToNextActiveTurn();
      return;
    }

    state = state.copyWith(
      deck: activeDeck,
      stage: GameStage.playerTurns,
      currentPlayerIndex: 0,
    );

    _moveToNextActiveTurn();
  }

  /// Evaluates state and automatically moves turn if player has split/blackjack/busted.
  void _moveToNextActiveTurn() {
    if (state.stage != GameStage.playerTurns) return;

    if (state.currentPlayerIndex < 0 || state.currentPlayerIndex >= state.players.length) {
      _startDealerTurn();
      return;
    }

    final player = state.players[state.currentPlayerIndex];
    
    // Skip if player didn't bet or is finished
    if (player.hands.isEmpty || player.hands.first.bet == 0) {
      state = state.copyWith(
        currentPlayerIndex: state.currentPlayerIndex + 1,
        currentHandIndex: 0,
      );
      _moveToNextActiveTurn();
      return;
    }

    // Check if current hand is finished
    if (state.currentHandIndex < 0 || state.currentHandIndex >= player.hands.length) {
      state = state.copyWith(
        currentPlayerIndex: state.currentPlayerIndex + 1,
        currentHandIndex: 0,
      );
      _moveToNextActiveTurn();
      return;
    }
    final currentHand = player.hands[state.currentHandIndex];
    if (currentHand.status.isFinished) {
      if (state.currentHandIndex + 1 < player.hands.length) {
        state = state.copyWith(currentHandIndex: state.currentHandIndex + 1);
        _moveToNextActiveTurn();
      } else {
        state = state.copyWith(
          currentPlayerIndex: state.currentPlayerIndex + 1,
          currentHandIndex: 0,
        );
        _moveToNextActiveTurn();
      }
      return;
    }

    // Hand needs turn action
    state = state.copyWith(
      statusMessage: '${player.name}\'s turn (${player.isBot ? "Bot" : "Human"}).',
    );

    _checkNextPlayerOrBot();
  }

  /// Triggers bot decision with simulated thinking delay.
  Future<void> _checkNextPlayerOrBot() async {
    final player = state.currentPlayer;
    if (player == null || !player.isBot || state.stage != GameStage.playerTurns) return;

    if (state.currentHandIndex < 0 || state.currentHandIndex >= player.hands.length) {
      _moveToNextActiveTurn();
      return;
    }
    final hand = player.hands[state.currentHandIndex];
    if (hand.status.isFinished) {
      _moveToNextActiveTurn();
      return;
    }

    // Bot "thinking" delay
    await Future.delayed(Duration(milliseconds: 700 + _random.nextInt(600)));
    if (!mounted) return;

    if (state.dealer.hands.isEmpty || state.dealer.hands.first.cards.isEmpty) {
      _moveToNextActiveTurn();
      return;
    }
    final dealerUpCard = state.dealer.hands.first.cards.first;

    // Check split possibility
    bool canSplit = hand.cards.length == 2 &&
        hand.cards[0].rank.value == hand.cards[1].rank.value &&
        player.hands.length < 4 && // Max 4 splits
        player.balance >= hand.bet;

    bool canDouble = hand.cards.length == 2 && player.balance >= hand.bet;
    bool canSurrender = hand.cards.length == 2 && !hand.isFromSplit;

    final action = AIManager.getBotDecision(
      bot: player,
      hand: hand,
      dealerUpCard: dealerUpCard,
      canDouble: canDouble,
      canSplit: canSplit,
      canSurrender: canSurrender,
      runningCount: _runningCount,
    );

    // Calculate simulated hand confidence for emote reaction
    double confidence = _calculateHandConfidence(hand, dealerUpCard);
    String? emote = AIManager.getReactionEmote(
      player.botPersonality ?? BotPersonality.professional,
      confidence,
      hand.status,
    );

    if (emote != null) {
      _updatePlayerEmote(state.currentPlayerIndex, emote);
    }

    switch (action) {
      case BlackjackAction.hit:
        hit();
        break;
      case BlackjackAction.stand:
        stand();
        break;
      case BlackjackAction.doubleDown:
        doubleDown();
        break;
      case BlackjackAction.split:
        split();
        break;
      case BlackjackAction.surrender:
        surrender();
        break;
    }
  }

  double _calculateHandConfidence(BlackjackHand hand, BlackjackCard dealerCard) {
    int score = hand.score;
    int dealerScore = dealerCard.rank.value;
    if (score >= 19) return 0.9;
    if (score <= 11) return 0.6;
    if (score >= 12 && score <= 16 && dealerScore >= 7) return 0.2; // dangerous zone
    return 0.5;
  }

  void _updatePlayerEmote(int playerIndex, String emote) {
    final players = List<BlackjackPlayer>.from(state.players);
    players[playerIndex] = players[playerIndex].copyWith(
      lastEmote: emote,
      confidenceLevel: _random.nextDouble(),
    );
    state = state.copyWith(players: players);
  }

  /// Performs standard Blackjack Hit.
  void hit() {
    if (state.stage != GameStage.playerTurns) return;
    if (state.currentPlayerIndex < 0 || state.currentPlayerIndex >= state.players.length) return;
    
    final activeDeck = List<BlackjackCard>.from(state.deck);
    if (activeDeck.isEmpty) {
      activeDeck.addAll(_generateShoe(6));
    }

    final card = activeDeck.removeLast().copyWith(isFaceUp: true);
    _updateCardCount(card);

    final players = List<BlackjackPlayer>.from(state.players);
    final player = players[state.currentPlayerIndex];
    final hands = List<BlackjackHand>.from(player.hands);

    if (state.currentHandIndex < 0 || state.currentHandIndex >= hands.length) return;
    final updatedHand = hands[state.currentHandIndex].addCard(card);
    hands[state.currentHandIndex] = updatedHand;
    players[state.currentPlayerIndex] = player.copyWith(hands: hands);

    _audio.playCardSlide();
    
    state = state.copyWith(
      players: players,
      deck: activeDeck,
    );

    // If busted or stood, move on, otherwise let player continue
    if (updatedHand.status.isFinished) {
      if (updatedHand.status == HandStatus.busted) {
        _audio.playLose();
      }
      _moveToNextActiveTurn();
    } else {
      _checkNextPlayerOrBot();
    }
  }

  /// Performs standard Stand.
  void stand() {
    if (state.stage != GameStage.playerTurns) return;
    if (state.currentPlayerIndex < 0 || state.currentPlayerIndex >= state.players.length) return;

    final players = List<BlackjackPlayer>.from(state.players);
    final player = players[state.currentPlayerIndex];
    final hands = List<BlackjackHand>.from(player.hands);

    if (state.currentHandIndex < 0 || state.currentHandIndex >= hands.length) return;
    hands[state.currentHandIndex] = hands[state.currentHandIndex].copyWith(
      status: HandStatus.stood,
    );
    players[state.currentPlayerIndex] = player.copyWith(hands: hands);

    _audio.playClick();

    state = state.copyWith(players: players);
    _moveToNextActiveTurn();
  }

  /// Performs Double Down.
  void doubleDown() {
    if (state.stage != GameStage.playerTurns) return;
    if (state.currentPlayerIndex < 0 || state.currentPlayerIndex >= state.players.length) return;

    final players = List<BlackjackPlayer>.from(state.players);
    final player = players[state.currentPlayerIndex];
    final hands = List<BlackjackHand>.from(player.hands);
    
    if (state.currentHandIndex < 0 || state.currentHandIndex >= hands.length) return;
    final hand = hands[state.currentHandIndex];

    if (player.balance < hand.bet) return; // Insufficient balance

    final activeDeck = List<BlackjackCard>.from(state.deck);
    if (activeDeck.isEmpty) {
      activeDeck.addAll(_generateShoe(6));
    }

    final card = activeDeck.removeLast().copyWith(isFaceUp: true);
    _updateCardCount(card);

    final updatedHand = hand.copyWith(
      bet: hand.bet * 2,
    ).addCard(card);

    // Double-down only allows exactly 1 more card
    HandStatus finalStatus = updatedHand.score > 21 
        ? HandStatus.busted 
        : HandStatus.stood;

    hands[state.currentHandIndex] = updatedHand.copyWith(status: finalStatus);

    players[state.currentPlayerIndex] = player.copyWith(
      balance: player.balance - hand.bet, // Deduct matching bet
      hands: hands,
    );

    _audio.playChipsBet();
    _audio.playCardSlide();

    state = state.copyWith(
      players: players,
      deck: activeDeck,
    );

    if (finalStatus == HandStatus.busted) {
      _audio.playLose();
    }

    _moveToNextActiveTurn();
  }

  /// Performs Split.
  void split() {
    if (state.stage != GameStage.playerTurns) return;
    if (state.currentPlayerIndex < 0 || state.currentPlayerIndex >= state.players.length) return;

    final players = List<BlackjackPlayer>.from(state.players);
    final player = players[state.currentPlayerIndex];
    final hands = List<BlackjackHand>.from(player.hands);
    
    if (state.currentHandIndex < 0 || state.currentHandIndex >= hands.length) return;
    final hand = hands[state.currentHandIndex];

    if (hand.cards.length != 2 || 
        hand.cards[0].rank.value != hand.cards[1].rank.value || 
        player.balance < hand.bet) {
      return;
    }

    final activeDeck = List<BlackjackCard>.from(state.deck);
    if (activeDeck.isEmpty) {
      activeDeck.addAll(_generateShoe(6));
    }

    // Split cards
    final card1 = hand.cards[0];
    final card2 = hand.cards[1];

    // Create 2 new hands
    var hand1 = BlackjackHand(
      cards: [card1],
      bet: hand.bet,
      isFromSplit: true,
      status: HandStatus.playing,
    );
    var hand2 = BlackjackHand(
      cards: [card2],
      bet: hand.bet,
      isFromSplit: true,
      status: HandStatus.playing,
    );

    // Immediately draw a card for each of the new hands from the activeDeck
    final draw1 = activeDeck.removeLast().copyWith(isFaceUp: true);
    _updateCardCount(draw1);
    hand1 = hand1.addCard(draw1);

    final draw2 = activeDeck.removeLast().copyWith(isFaceUp: true);
    _updateCardCount(draw2);
    hand2 = hand2.addCard(draw2);

    hands.removeAt(state.currentHandIndex);
    hands.insert(state.currentHandIndex, hand1);
    hands.insert(state.currentHandIndex + 1, hand2);

    players[state.currentPlayerIndex] = player.copyWith(
      balance: player.balance - hand.bet, // deduct split bet
      hands: hands,
    );

    _audio.playChipsBet();
    _audio.playCardSlide();
    _audio.playCardSlide();

    state = state.copyWith(
      players: players,
      deck: activeDeck,
    );

    _moveToNextActiveTurn();
  }

  /// Performs Surrender.
  void surrender() {
    if (state.stage != GameStage.playerTurns) return;
    if (state.currentPlayerIndex < 0 || state.currentPlayerIndex >= state.players.length) return;

    final players = List<BlackjackPlayer>.from(state.players);
    final player = players[state.currentPlayerIndex];
    final hands = List<BlackjackHand>.from(player.hands);
    
    if (state.currentHandIndex < 0 || state.currentHandIndex >= hands.length) return;
    final hand = hands[state.currentHandIndex];

    // Mark hand as surrendered
    hands[state.currentHandIndex] = hand.copyWith(
      status: HandStatus.surrendered,
    );

    // Return half the bet
    players[state.currentPlayerIndex] = player.copyWith(
      balance: player.balance + (hand.bet / 2),
      hands: hands,
    );

    _audio.playChipsWin();

    state = state.copyWith(players: players);
    _moveToNextActiveTurn();
  }

  /// Initiates the dealer's card draw turn.
  Future<void> _startDealerTurn() async {
    state = state.copyWith(
      stage: GameStage.dealerTurn,
      statusMessage: 'Dealer\'s turn.',
    );

    // Reveal dealer's face-down card
    final dealer = state.dealer;
    if (dealer.hands.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      _evaluatePayouts();
      return;
    }
    final dealerHands = List<BlackjackHand>.from(dealer.hands);
    final dealerCards = List<BlackjackCard>.from(dealerHands.first.cards);

    if (dealerCards.length >= 2) {
      dealerCards[1] = dealerCards[1].copyWith(isFaceUp: true);
      _updateCardCount(dealerCards[1]); // count revealed card
      dealerHands.first = dealerHands.first.copyWith(cards: dealerCards);
      
      _audio.playCardFlip();
      state = state.copyWith(dealer: dealer.copyWith(hands: dealerHands));
    }

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // Deal cards to dealer until score is at least 17
    final activeDeck = List<BlackjackCard>.from(state.deck);
    while (dealerHands.isNotEmpty && dealerHands.first.score < 17) {
      if (activeDeck.isEmpty) {
        activeDeck.addAll(_generateShoe(6));
      }
      final card = activeDeck.removeLast().copyWith(isFaceUp: true);
      _updateCardCount(card);

      dealerHands.first = dealerHands.first.addCard(card);
      _audio.playCardSlide();

      state = state.copyWith(
        dealer: dealer.copyWith(hands: dealerHands),
        deck: activeDeck,
        statusMessage: 'Dealer hits...',
      );

      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
    }

    if (dealerHands.isNotEmpty && dealerHands.first.score > 21) {
      state = state.copyWith(statusMessage: 'Dealer busts!');
    } else {
      final dealerFinalScore = dealerHands.isNotEmpty ? dealerHands.first.score : 0;
      state = state.copyWith(statusMessage: 'Dealer stands on $dealerFinalScore');
    }

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    _evaluatePayouts();
  }

  /// Calculates game results and updates player balances.
  void _evaluatePayouts() {
    state = state.copyWith(stage: GameStage.payouts);

    if (state.dealer.hands.isEmpty) {
      state = state.copyWith(
        stage: GameStage.roundEnded,
        statusMessage: 'Round ended: No dealer hand.',
      );
      return;
    }
    final dealerHand = state.dealer.hands.first;
    final dealerScore = dealerHand.score;
    final dealerBusted = dealerHand.isBusted;
    final dealerBlackjack = dealerHand.isBlackjack;

    final updatedPlayers = List<BlackjackPlayer>.from(state.players);
    String payoutSummary = 'Round ended: ';
    bool playerWinAny = false;

    for (int i = 0; i < updatedPlayers.length; i++) {
      final player = updatedPlayers[i];
      if (player.hands.isEmpty || player.hands.first.bet == 0) continue;

      final updatedHands = <BlackjackHand>[];
      double balanceChange = 0.0;

      for (var hand in player.hands) {
        if (hand.status == HandStatus.surrendered) {
          updatedHands.add(hand); // Handled during action
          continue;
        }

        if (hand.isBusted) {
          updatedHands.add(hand.copyWith(status: HandStatus.lost));
          payoutSummary += '${player.name} busted (-\$${hand.bet}). ';
          continue;
        }

        final score = hand.score;
        final isBJ = hand.isBlackjack;

        if (dealerBusted) {
          // Dealer busted, player wins!
          double payoutMultiplier = isBJ ? 2.5 : 2.0; // BJ pays 3:2, regular pays 1:1
          balanceChange += hand.bet * payoutMultiplier;
          updatedHands.add(hand.copyWith(status: HandStatus.won));
          payoutSummary += '${player.name} wins +\$${hand.bet * (payoutMultiplier - 1)}. ';
          playerWinAny = true;
        } else if (isBJ && !dealerBlackjack) {
          // Player Blackjack (3:2 payout)
          balanceChange += hand.bet * 2.5;
          updatedHands.add(hand.copyWith(status: HandStatus.won));
          payoutSummary += '${player.name} Blackjack! +\$${hand.bet * 1.5}. ';
          playerWinAny = true;
        } else if (dealerBlackjack && !isBJ) {
          // Dealer Blackjack, player loses
          updatedHands.add(hand.copyWith(status: HandStatus.lost));
          payoutSummary += '${player.name} loses vs BJ (-\$${hand.bet}). ';
        } else if (score > dealerScore) {
          // Player higher score
          balanceChange += hand.bet * 2.0;
          updatedHands.add(hand.copyWith(status: HandStatus.won));
          payoutSummary += '${player.name} wins +\$${hand.bet}. ';
          playerWinAny = true;
        } else if (score < dealerScore) {
          // Player lower score
          updatedHands.add(hand.copyWith(status: HandStatus.lost));
          payoutSummary += '${player.name} loses (-\$${hand.bet}). ';
        } else {
          // Push (equal score)
          balanceChange += hand.bet;
          updatedHands.add(hand.copyWith(status: HandStatus.push));
          payoutSummary += '${player.name} pushes. ';
        }
      }

      // Distribute money
      updatedPlayers[i] = player.copyWith(
        balance: player.balance + balanceChange,
        hands: updatedHands,
      );
    }

    if (playerWinAny) {
      _audio.playChipsWin();
      _audio.playWin();
    } else {
      _audio.playLose();
    }

    // Set end-of-round state
    state = state.copyWith(
      players: updatedPlayers,
      stage: GameStage.roundEnded,
      statusMessage: payoutSummary,
    );
  }

  /// Resets the table for the next round.
  void startNewRound() {
    if (state.stage != GameStage.roundEnded) return;

    final updatedPlayers = state.players.map((p) {
      // Clear hands, reset bet to 0
      return p.copyWith(
        hands: [const BlackjackHand(status: HandStatus.betting)],
        lastEmote: null,
      );
    }).toList();

    state = state.copyWith(
      players: updatedPlayers,
      dealer: state.dealer.copyWith(
        hands: [const BlackjackHand(status: HandStatus.betting)],
      ),
      stage: GameStage.betting,
      currentPlayerIndex: 0,
      currentHandIndex: 0,
      roundNumber: state.roundNumber + 1,
      statusMessage: 'Place bets for Round ${state.roundNumber + 1}!',
    );
  }
}
