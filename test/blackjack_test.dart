import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:best_casino/features/blackjack/data/models/card.dart';
import 'package:best_casino/features/blackjack/data/models/hand.dart';
import 'package:best_casino/features/blackjack/data/models/player.dart';
import 'package:best_casino/features/blackjack/viewmodels/ai_manager.dart';
import 'package:best_casino/features/blackjack/viewmodels/game_view_model.dart';
import 'package:best_casino/features/blackjack/data/models/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    (MethodCall methodCall) async {
      return null;
    },
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (MethodCall methodCall) async {
      return null;
    },
  );
  group('Blackjack Hand Scoring Tests', () {
    test('Empty hand should score 0', () {
      const hand = BlackjackHand();
      expect(hand.score, 0);
    });

    test('Hard total without Aces', () {
      var hand = const BlackjackHand();
      hand = hand.addCard(const BlackjackCard(suit: CardSuit.hearts, rank: CardRank.ten));
      hand = hand.addCard(const BlackjackCard(suit: CardSuit.spades, rank: CardRank.five));
      expect(hand.score, 15);
      expect(hand.isSoft, false);
      expect(hand.isBusted, false);
    });

    test('Soft total with single Ace', () {
      var hand = const BlackjackHand();
      hand = hand.addCard(const BlackjackCard(suit: CardSuit.hearts, rank: CardRank.ace));
      hand = hand.addCard(const BlackjackCard(suit: CardSuit.spades, rank: CardRank.five));
      expect(hand.score, 16);
      expect(hand.isSoft, true);
    });

    test('Ace reduction when score exceeds 21', () {
      var hand = const BlackjackHand();
      hand = hand.addCard(const BlackjackCard(suit: CardSuit.hearts, rank: CardRank.ace)); // 11
      hand = hand.addCard(const BlackjackCard(suit: CardSuit.spades, rank: CardRank.five)); // 11 + 5 = 16
      hand = hand.addCard(const BlackjackCard(suit: CardSuit.clubs, rank: CardRank.ten)); // 16 + 10 = 26 -> Ace becomes 1 -> score = 16
      expect(hand.score, 16);
      expect(hand.isSoft, false);
      expect(hand.isBusted, false);
    });

    test('Multiple Aces handling', () {
      var hand = const BlackjackHand();
      hand = hand.addCard(const BlackjackCard(suit: CardSuit.hearts, rank: CardRank.ace)); // 11
      hand = hand.addCard(const BlackjackCard(suit: CardSuit.spades, rank: CardRank.ace)); // 11 + 1 = 12
      expect(hand.score, 12);
      expect(hand.isSoft, true);
    });
  });

  group('AI Decision Engine Tests', () {
    const testBot = BlackjackPlayer(
      id: 'bot_test',
      name: 'Test Bot',
      avatar: '',
      isBot: true,
      botDifficulty: BotDifficulty.hard, // Hard plays perfect basic strategy
      botPersonality: BotPersonality.professional,
    );

    test('AI stands on high values (20)', () {
      var hand = const BlackjackHand();
      hand = hand.addCard(const BlackjackCard(suit: CardSuit.hearts, rank: CardRank.ten));
      hand = hand.addCard(const BlackjackCard(suit: CardSuit.spades, rank: CardRank.ten));

      final action = AIManager.getBotDecision(
        bot: testBot,
        hand: hand,
        dealerUpCard: const BlackjackCard(suit: CardSuit.clubs, rank: CardRank.six),
        canDouble: true,
        canSplit: false,
        canSurrender: false,
        runningCount: 0,
      );

      expect(action, BlackjackAction.stand);
    });

    test('AI splits Aces', () {
      var hand = const BlackjackHand();
      hand = hand.addCard(const BlackjackCard(suit: CardSuit.hearts, rank: CardRank.ace));
      hand = hand.addCard(const BlackjackCard(suit: CardSuit.spades, rank: CardRank.ace));

      final action = AIManager.getBotDecision(
        bot: testBot,
        hand: hand,
        dealerUpCard: const BlackjackCard(suit: CardSuit.clubs, rank: CardRank.six),
        canDouble: true,
        canSplit: true,
        canSurrender: false,
        runningCount: 0,
      );

      expect(action, BlackjackAction.split);
    });

    test('AI hits on low score (8)', () {
      var hand = const BlackjackHand();
      hand = hand.addCard(const BlackjackCard(suit: CardSuit.hearts, rank: CardRank.five));
      hand = hand.addCard(const BlackjackCard(suit: CardSuit.spades, rank: CardRank.three));

      final action = AIManager.getBotDecision(
        bot: testBot,
        hand: hand,
        dealerUpCard: const BlackjackCard(suit: CardSuit.clubs, rank: CardRank.seven),
        canDouble: true,
        canSplit: false,
        canSurrender: false,
        runningCount: 0,
      );

      expect(action, BlackjackAction.hit);
    });
  });

  group('GameViewModel Tests', () {
    test('Bet accumulation and clearing bet', () {
      final viewModel = GameViewModel();
      viewModel.initializeTable(
        startingMoney: 1000.0,
        minBet: 10.0,
        maxBet: 500.0,
        seatedPlayers: [
          const BlackjackPlayer(id: 'human', name: 'Human', avatar: '', isBot: false),
        ],
        feltTheme: 'emerald_gold',
      );

      // Verify initial state
      expect(viewModel.state.players.length, 1);
      expect(viewModel.state.players.first.balance, 1000.0);
      expect(viewModel.state.players.first.hands.first.bet, 0.0);

      // Add bet $10
      viewModel.placeBet(0, 10.0);
      expect(viewModel.state.players.first.balance, 990.0);
      expect(viewModel.state.players.first.hands.first.bet, 10.0);

      // Add bet $25 (accumulate)
      viewModel.placeBet(0, 25.0);
      expect(viewModel.state.players.first.balance, 965.0);
      expect(viewModel.state.players.first.hands.first.bet, 35.0);

      // Clear bet
      viewModel.clearBet(0);
      expect(viewModel.state.players.first.balance, 1000.0);
      expect(viewModel.state.players.first.hands.first.bet, 0.0);
    });

    test('Atomic split logic', () {
      final viewModel = GameViewModel();
      viewModel.initializeTable(
        startingMoney: 1000.0,
        minBet: 10.0,
        maxBet: 500.0,
        seatedPlayers: [
          const BlackjackPlayer(id: 'human', name: 'Human', avatar: '', isBot: false),
        ],
        feltTheme: 'emerald_gold',
      );

      // Set the state manually to playerTurns for human turn with split-ready cards
      viewModel.state = viewModel.state.copyWith(
        stage: GameStage.playerTurns,
        currentPlayerIndex: 0,
        players: [
          viewModel.state.players.first.copyWith(
            hands: [
              const BlackjackHand(
                cards: [
                  BlackjackCard(suit: CardSuit.hearts, rank: CardRank.eight),
                  BlackjackCard(suit: CardSuit.spades, rank: CardRank.eight),
                ],
                bet: 10.0,
                status: HandStatus.playing,
              ),
            ],
          ),
        ],
      );

      viewModel.split();

      // Verify the player now has 2 hands, and balance is deducted by another $10 (1000 - 10 split = 990)
      expect(viewModel.state.players.first.hands.length, 2);
      expect(viewModel.state.players.first.balance, 990.0);
      expect(viewModel.state.players.first.hands[0].cards.length, 2);
      expect(viewModel.state.players.first.hands[1].cards.length, 2);
      expect(viewModel.state.players.first.hands[0].isFromSplit, true);
      expect(viewModel.state.players.first.hands[1].isFromSplit, true);
    });
  });
}
