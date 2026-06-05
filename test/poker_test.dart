import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:best_casino/features/poker/data/models/poker_card.dart';
import 'package:best_casino/features/poker/data/models/poker_player.dart';
import 'package:best_casino/features/poker/data/models/poker_state.dart';
import 'package:best_casino/features/poker/data/models/poker_hand_score.dart';
import 'package:best_casino/features/poker/viewmodels/poker_hand_evaluator.dart';
import 'package:best_casino/features/poker/viewmodels/poker_ai_manager.dart';
import 'package:best_casino/features/poker/viewmodels/poker_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock MethodChannel for audioplayers plugin to avoid platform exceptions
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

  group('Poker Hand Evaluator Tests', () {
    test('Royal Flush evaluation', () {
      final cards = [
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.ace),
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.king),
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.queen),
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.jack),
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.ten),
        const PokerCard(suit: PokerSuit.spades, rank: PokerRank.two),
        const PokerCard(suit: PokerSuit.clubs, rank: PokerRank.three),
      ];

      final score = PokerHandEvaluator.getBestHand(cards);
      expect(score.rank, HandRank.royalFlush);
    });

    test('Straight Flush evaluation', () {
      final cards = [
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.nine),
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.eight),
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.seven),
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.six),
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.five),
        const PokerCard(suit: PokerSuit.spades, rank: PokerRank.two),
        const PokerCard(suit: PokerSuit.clubs, rank: PokerRank.three),
      ];

      final score = PokerHandEvaluator.getBestHand(cards);
      expect(score.rank, HandRank.straightFlush);
      expect(score.values.first, 9); // High card of straight
    });

    test('Ace-low Straight (Wheel) evaluation', () {
      final cards = [
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.ace),
        const PokerCard(suit: PokerSuit.spades, rank: PokerRank.two),
        const PokerCard(suit: PokerSuit.clubs, rank: PokerRank.three),
        const PokerCard(suit: PokerSuit.diamonds, rank: PokerRank.four),
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.five),
        const PokerCard(suit: PokerSuit.spades, rank: PokerRank.king),
        const PokerCard(suit: PokerSuit.clubs, rank: PokerRank.queen),
      ];

      final score = PokerHandEvaluator.getBestHand(cards);
      expect(score.rank, HandRank.straight);
      expect(score.values.first, 5); // 5-high straight
    });

    test('Four of a Kind evaluation', () {
      final cards = [
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.nine),
        const PokerCard(suit: PokerSuit.spades, rank: PokerRank.nine),
        const PokerCard(suit: PokerSuit.clubs, rank: PokerRank.nine),
        const PokerCard(suit: PokerSuit.diamonds, rank: PokerRank.nine),
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.five),
        const PokerCard(suit: PokerSuit.spades, rank: PokerRank.two),
        const PokerCard(suit: PokerSuit.clubs, rank: PokerRank.three),
      ];

      final score = PokerHandEvaluator.getBestHand(cards);
      expect(score.rank, HandRank.fourOfAKind);
      expect(score.values[0], 9); // Quad card rank
      expect(score.values[1], 5); // Kicker rank
    });

    test('Full House evaluation', () {
      final cards = [
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.ace),
        const PokerCard(suit: PokerSuit.spades, rank: PokerRank.ace),
        const PokerCard(suit: PokerSuit.clubs, rank: PokerRank.ace),
        const PokerCard(suit: PokerSuit.diamonds, rank: PokerRank.king),
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.king),
        const PokerCard(suit: PokerSuit.spades, rank: PokerRank.two),
        const PokerCard(suit: PokerSuit.clubs, rank: PokerRank.three),
      ];

      final score = PokerHandEvaluator.getBestHand(cards);
      expect(score.rank, HandRank.fullHouse);
      expect(score.values[0], 14); // Trips value
      expect(score.values[1], 13); // Pair value
    });

    test('Kicker Tie Breakers (Two Pairs)', () {
      // Hand A: Kings and Queens with Ace kicker
      final handACards = [
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.king),
        const PokerCard(suit: PokerSuit.spades, rank: PokerRank.king),
        const PokerCard(suit: PokerSuit.clubs, rank: PokerRank.queen),
        const PokerCard(suit: PokerSuit.diamonds, rank: PokerRank.queen),
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.ace),
        const PokerCard(suit: PokerSuit.spades, rank: PokerRank.two),
        const PokerCard(suit: PokerSuit.clubs, rank: PokerRank.three),
      ];

      // Hand B: Kings and Queens with Ten kicker
      final handBCards = [
        const PokerCard(suit: PokerSuit.diamonds, rank: PokerRank.king),
        const PokerCard(suit: PokerSuit.clubs, rank: PokerRank.king),
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.queen),
        const PokerCard(suit: PokerSuit.spades, rank: PokerRank.queen),
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.ten),
        const PokerCard(suit: PokerSuit.spades, rank: PokerRank.four),
        const PokerCard(suit: PokerSuit.clubs, rank: PokerRank.three),
      ];

      final scoreA = PokerHandEvaluator.getBestHand(handACards);
      final scoreB = PokerHandEvaluator.getBestHand(handBCards);

      expect(scoreA.rank, HandRank.twoPair);
      expect(scoreB.rank, HandRank.twoPair);

      // scoreA beats scoreB because 14 (Ace) > 10 (Ten) kicker
      expect(scoreA.compareTo(scoreB), 1);
    });
  });

  group('Poker AI Manager Tests', () {
    const tightBot = PokerPlayer(
      id: 'bot_tight',
      name: 'Tight Bot',
      avatar: '',
      isBot: true,
      botPersonality: PokerBotPersonality.tight,
      botDifficulty: PokerBotDifficulty.pro,
    );

    test('Tight AI folds weak hands pre-flop', () {
      final holeCards = [
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.two),
        const PokerCard(suit: PokerSuit.spades, rank: PokerRank.seven),
      ];

      final botPlayer = tightBot.copyWith(cards: holeCards, balance: 1000.0, roundBet: 0.0);
      final decision = PokerAIManager.getBotDecision(
        bot: botPlayer,
        communityCards: const [],
        potSize: 30.0,
        currentBetToCall: 20.0,
        currentRaise: 20.0,
      );

      expect(decision.type, PokerActionType.fold);
    });

    test('AI calls with high connection pre-flop', () {
      final holeCards = [
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.ace),
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.king),
      ];

      final botPlayer = tightBot.copyWith(cards: holeCards, balance: 1000.0, roundBet: 0.0);
      final decision = PokerAIManager.getBotDecision(
        bot: botPlayer,
        communityCards: const [],
        potSize: 30.0,
        currentBetToCall: 20.0,
        currentRaise: 20.0,
      );

      expect(decision.type, PokerActionType.call);
    });
  });

  group('PokerViewModel & Side Pot Tests', () {
    test('Forced blinds and initial state checks', () async {
      final viewModel = PokerViewModel();
      viewModel.initializeTable(
        startingMoney: 1000.0,
        smallBlind: 10.0,
        bigBlind: 20.0,
        seatedPlayers: [
          const PokerPlayer(id: 'human', name: 'Human', avatar: '', isBot: false),
          const PokerPlayer(id: 'bot1', name: 'Bot 1', avatar: '', isBot: true),
        ],
        feltTheme: 'emerald_gold',
      );

      // Verify initialization
      expect(viewModel.state.players.length, 2);
      expect(viewModel.state.players[0].balance, 1000.0);
      expect(viewModel.state.stage, PokerStage.blinds);

      // Start round and trigger forced blinds
      await viewModel.startRound();

      // Human (at dealerIndex 0) - rotates so blinds are next.
      // sbIndex = (0 + 1) % 2 = 1 (Bot 1 pays small blind $10)
      // bbIndex = (0 + 2) % 2 = 0 (Human pays big blind $20)
      final human = viewModel.state.players.firstWhere((p) => p.id == 'human');
      final bot1 = viewModel.state.players.firstWhere((p) => p.id == 'bot1');

      expect(bot1.balance, 990.0);
      expect(bot1.roundBet, 10.0);

      expect(human.balance, 980.0);
      expect(human.roundBet, 20.0);

      expect(viewModel.state.currentBetToCall, 20.0);
      expect(viewModel.state.stage, PokerStage.preFlop);
    });

    test('Showdown Side Pot contribution tiering validation', () {
      final viewModel = PokerViewModel();

      // Configure a manual table state at showdown
      // Three players:
      // Player A: total contribution $100 (All-in), weak hand
      // Player B: total contribution $200 (All-in), medium hand
      // Player C: total contribution $300, strong hand
      // Total chips in pot should be: 100 + 200 + 200 (Player C is capped at $200 contribution for B's tier since C can't bet more than B if B is all in, but let's say C contributes 300 anyway)
      // Tiers should resolve:
      // Tier 1: $100 contribution. Total = 100 * 3 = $300. Eligible: A, B, C.
      // Tier 2: Next $100 contribution. Total = (200 - 100) * 2 = $200. Eligible: B, C.
      // Tier 3: Next $100 contribution. Total = (300 - 200) * 1 = $100. Eligible: C.
      // Let's configure hand strengths:
      // Player A: Pair of Twos (weakest)
      // Player B: Pair of Tens (medium)
      // Player C: Pair of Aces (strongest)

      viewModel.initializeTable(
        startingMoney: 1000.0,
        smallBlind: 10.0,
        bigBlind: 20.0,
        seatedPlayers: [
          const PokerPlayer(id: 'playerA', name: 'A', avatar: '', isBot: false),
          const PokerPlayer(id: 'playerB', name: 'B', avatar: '', isBot: true),
          const PokerPlayer(id: 'playerC', name: 'C', avatar: '', isBot: true),
        ],
        feltTheme: 'emerald_gold',
      );

      final commCards = [
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.king),
        const PokerCard(suit: PokerSuit.spades, rank: PokerRank.eight),
        const PokerCard(suit: PokerSuit.clubs, rank: PokerRank.six),
        const PokerCard(suit: PokerSuit.diamonds, rank: PokerRank.four),
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.three),
      ];

      viewModel.state = PokerGameState(
        players: [
          const PokerPlayer(
            id: 'playerA',
            name: 'A',
            avatar: '',
            balance: 0.0, // Went All-In
            totalContributed: 100.0,
            status: PokerPlayerStatus.allIn,
            cards: [
              PokerCard(suit: PokerSuit.hearts, rank: PokerRank.two),
              PokerCard(suit: PokerSuit.spades, rank: PokerRank.two),
            ], // Pair of 2s
          ),
          const PokerPlayer(
            id: 'playerB',
            name: 'B',
            avatar: '',
            balance: 0.0, // Went All-In
            totalContributed: 200.0,
            status: PokerPlayerStatus.allIn,
            cards: [
              PokerCard(suit: PokerSuit.hearts, rank: PokerRank.ten),
              PokerCard(suit: PokerSuit.spades, rank: PokerRank.ten),
            ], // Pair of 10s
          ),
          const PokerPlayer(
            id: 'playerC',
            name: 'C',
            avatar: '',
            balance: 700.0,
            totalContributed: 300.0, // Over-contributed
            status: PokerPlayerStatus.active,
            cards: [
              PokerCard(suit: PokerSuit.hearts, rank: PokerRank.ace),
              PokerCard(suit: PokerSuit.spades, rank: PokerRank.ace),
            ], // Pair of Aces (Strongest)
          ),
        ],
        communityCards: commCards,
        stage: PokerStage.river,
        currentPlayerIndex: 2,
        pot: 600.0, // 100 + 200 + 300
        smallBlind: 10.0,
        bigBlind: 20.0,
      );

      // Run payouts calculation
      viewModel.executeAction(PokerAction.check()); // Triggers moving to conclusion/showdown

      // Let's verify balances after resolution.
      // Since C has the best hand (Pair of Aces) and is eligible for all tiers:
      // Tier 1 ($300): C wins because Aces beat 10s and 2s.
      // Tier 2 ($200): C wins because Aces beat 10s.
      // Tier 3 ($100): C wins (only one eligible).
      // Total payouts to C: 300 + 200 + 100 = $600.
      // Balances:
      // A = 0.0
      // B = 0.0
      // C = 700.0 + 600.0 = 1300.0
      final playerC = viewModel.state.players.firstWhere((p) => p.id == 'playerC');
      expect(playerC.balance, 1300.0);
    });

    test('Showdown Side Pot where weaker player wins main pot and stronger player wins side pot', () {
      final viewModel = PokerViewModel();

      // Configure a showdown:
      // Player A: contributed $100 (All-in), has Pair of Aces (Best hand)
      // Player B: contributed $300 (All-in), has Pair of Tens (Medium hand)
      // Player C: contributed $300, has Pair of Twos (Weakest hand)
      // Tiers:
      // Tier 1 ($300): A, B, C eligible. A has best hand (Aces) -> A wins $300.
      // Tier 2 ($400): B, C eligible. B has better hand than C (10s > 2s) -> B wins $400.
      // Balances:
      // A = $300 (won Tier 1)
      // B = $400 (won Tier 2)
      // C = $700 (original stack 700 + 0 won)

      viewModel.initializeTable(
        startingMoney: 1000.0,
        smallBlind: 10.0,
        bigBlind: 20.0,
        seatedPlayers: [
          const PokerPlayer(id: 'playerA', name: 'A', avatar: '', isBot: false),
          const PokerPlayer(id: 'playerB', name: 'B', avatar: '', isBot: true),
          const PokerPlayer(id: 'playerC', name: 'C', avatar: '', isBot: true),
        ],
        feltTheme: 'emerald_gold',
      );

      final commCards = [
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.king),
        const PokerCard(suit: PokerSuit.spades, rank: PokerRank.eight),
        const PokerCard(suit: PokerSuit.clubs, rank: PokerRank.six),
        const PokerCard(suit: PokerSuit.diamonds, rank: PokerRank.four),
        const PokerCard(suit: PokerSuit.hearts, rank: PokerRank.three),
      ];

      viewModel.state = PokerGameState(
        players: [
          const PokerPlayer(
            id: 'playerA',
            name: 'A',
            avatar: '',
            balance: 0.0,
            totalContributed: 100.0,
            status: PokerPlayerStatus.allIn,
            cards: [
              PokerCard(suit: PokerSuit.hearts, rank: PokerRank.ace),
              PokerCard(suit: PokerSuit.spades, rank: PokerRank.ace),
            ], // Pair of Aces
          ),
          const PokerPlayer(
            id: 'playerB',
            name: 'B',
            avatar: '',
            balance: 0.0,
            totalContributed: 300.0,
            status: PokerPlayerStatus.allIn,
            cards: [
              PokerCard(suit: PokerSuit.hearts, rank: PokerRank.ten),
              PokerCard(suit: PokerSuit.spades, rank: PokerRank.ten),
            ], // Pair of Tens
          ),
          const PokerPlayer(
            id: 'playerC',
            name: 'C',
            avatar: '',
            balance: 700.0,
            totalContributed: 300.0,
            status: PokerPlayerStatus.active,
            cards: [
              PokerCard(suit: PokerSuit.hearts, rank: PokerRank.two),
              PokerCard(suit: PokerSuit.spades, rank: PokerRank.two),
            ], // Pair of Twos
          ),
        ],
        communityCards: commCards,
        stage: PokerStage.river,
        currentPlayerIndex: 2,
        pot: 700.0,
        smallBlind: 10.0,
        bigBlind: 20.0,
      );

      viewModel.executeAction(PokerAction.check());

      final playerA = viewModel.state.players.firstWhere((p) => p.id == 'playerA');
      final playerB = viewModel.state.players.firstWhere((p) => p.id == 'playerB');
      final playerC = viewModel.state.players.firstWhere((p) => p.id == 'playerC');

      expect(playerA.balance, 300.0);
      expect(playerB.balance, 400.0);
      expect(playerC.balance, 700.0);
    });
  });
}
