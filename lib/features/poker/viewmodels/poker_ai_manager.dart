import 'dart:math';
import '../data/models/poker_card.dart';
import '../data/models/poker_player.dart';
import 'poker_hand_evaluator.dart';

enum PokerActionType {
  check,
  call,
  raise,
  fold,
  allIn
}

class PokerAction {
  final PokerActionType type;
  final double amount; // Used for raises

  const PokerAction._(this.type, [this.amount = 0.0]);

  factory PokerAction.check() => const PokerAction._(PokerActionType.check);
  factory PokerAction.call() => const PokerAction._(PokerActionType.call);
  factory PokerAction.raise(double amount) => PokerAction._(PokerActionType.raise, amount);
  factory PokerAction.fold() => const PokerAction._(PokerActionType.fold);
  factory PokerAction.allIn() => const PokerAction._(PokerActionType.allIn);
}

class PokerAIManager {
  static final Random _random = Random();

  /// Estimates the hand strength of a player from 0.0 (worst) to 1.0 (best).
  static double estimateHandStrength(List<PokerCard> holeCards, List<PokerCard> communityCards) {
    if (holeCards.length < 2) return 0.0;

    if (communityCards.isEmpty) {
      // Pre-flop estimation: high cards, suited, connected, pocket pairs
      final c1 = holeCards[0];
      final c2 = holeCards[1];

      double score = 0.0;
      // High card value
      score += (c1.rank.value + c2.rank.value) / 28.0;

      // Pocket pairs
      if (c1.rank == c2.rank) {
        score += 0.35;
      }

      // Suited cards
      if (c1.suit == c2.suit) {
        score += 0.08;
      }

      // Connected ranks
      if ((c1.rank.value - c2.rank.value).abs() == 1) {
        score += 0.05;
      }

      return score.clamp(0.0, 1.0);
    } else {
      // Post-flop/Turn/River estimation: run evaluator
      final score = PokerHandEvaluator.getBestHand([...holeCards, ...communityCards]);
      double baseStrength = score.rank.index / 9.0; // HandRank max is 9 (royalFlush)

      // Draw estimation for Flush Draw or Straight Draw
      if (communityCards.length < 5) {
        final suits = <PokerSuit, int>{};
        for (var c in [...holeCards, ...communityCards]) {
          suits[c.suit] = (suits[c.suit] ?? 0) + 1;
        }
        if (suits.values.any((c) => c == 4)) {
          baseStrength += 0.15; // Flush Draw
        }

        final uniqueVals = [...holeCards, ...communityCards].map((c) => c.rank.value).toSet().toList()..sort();
        bool hasStraightDraw = false;
        if (uniqueVals.length >= 4) {
          for (int i = 0; i <= uniqueVals.length - 4; i++) {
            if (uniqueVals[i+3] - uniqueVals[i] <= 4) {
              hasStraightDraw = true;
              break;
            }
          }
        }
        if (hasStraightDraw) {
          baseStrength += 0.1; // Straight Draw
        }
      }

      return baseStrength.clamp(0.0, 1.0);
    }
  }

  /// Evaluates bot parameters and returns a poker action.
  static PokerAction getBotDecision({
    required PokerPlayer bot,
    required List<PokerCard> communityCards,
    required double potSize,
    required double currentBetToCall,
    required double currentRaise,
  }) {
    final strength = estimateHandStrength(bot.cards, communityCards);
    final personality = bot.botPersonality ?? PokerBotPersonality.smartBalanced;
    final difficulty = bot.botDifficulty ?? PokerBotDifficulty.medium;

    final toCall = currentBetToCall - bot.roundBet;
    final canCheck = toCall <= 0;

    // Apply difficulty noise
    double noise = 0.0;
    if (difficulty == PokerBotDifficulty.easy) {
      noise = (_random.nextDouble() - 0.5) * 0.35;
    } else if (difficulty == PokerBotDifficulty.medium) {
      noise = (_random.nextDouble() - 0.5) * 0.18;
    }

    final finalStrength = (strength + noise).clamp(0.0, 1.0);

    // Bluffing probabilities
    bool isBluffing = false;
    double bluffChance = 0.05;
    if (personality == PokerBotPersonality.bluffHeavy) {
      bluffChance = 0.25;
    } else if (personality == PokerBotPersonality.aggressive) {
      bluffChance = 0.12;
    } else if (personality == PokerBotPersonality.passive) {
      bluffChance = 0.01;
    }

    if (_random.nextDouble() < bluffChance && communityCards.isNotEmpty) {
      isBluffing = true;
    }

    // Force call/fold if balance is too low or we have a bluffing action
    if (isBluffing) {
      if (canCheck) {
        return PokerAction.raise(currentRaise * (1 + _random.nextInt(2)));
      } else {
        if (_random.nextDouble() < 0.4 && bot.balance >= toCall + currentRaise) {
          return PokerAction.raise(currentRaise);
        }
        return PokerAction.call();
      }
    }

    switch (personality) {
      case PokerBotPersonality.tight:
        if (finalStrength < 0.4) {
          return canCheck ? PokerAction.check() : PokerAction.fold();
        }
        if (finalStrength >= 0.75 && bot.balance >= toCall + currentRaise && _random.nextDouble() < 0.4) {
          return PokerAction.raise(currentRaise);
        }
        return canCheck ? PokerAction.check() : PokerAction.call();

      case PokerBotPersonality.loose:
        if (finalStrength < 0.22) {
          return canCheck ? PokerAction.check() : PokerAction.fold();
        }
        if (finalStrength >= 0.7 && bot.balance >= toCall + currentRaise && _random.nextDouble() < 0.25) {
          return PokerAction.raise(currentRaise);
        }
        return canCheck ? PokerAction.check() : PokerAction.call();

      case PokerBotPersonality.aggressive:
        if (finalStrength < 0.28) {
          return canCheck ? PokerAction.check() : PokerAction.fold();
        }
        if (finalStrength >= 0.48 && bot.balance >= toCall + currentRaise) {
          return PokerAction.raise(currentRaise * (1 + _random.nextInt(2)));
        }
        return canCheck ? PokerAction.check() : PokerAction.call();

      case PokerBotPersonality.passive:
        if (finalStrength < 0.32) {
          return canCheck ? PokerAction.check() : PokerAction.fold();
        }
        return canCheck ? PokerAction.check() : PokerAction.call();

      case PokerBotPersonality.bluffHeavy:
        if (finalStrength < 0.18) {
          return canCheck ? PokerAction.check() : PokerAction.fold();
        }
        if (_random.nextDouble() < 0.4 && bot.balance >= toCall + currentRaise) {
          return PokerAction.raise(currentRaise * (1 + _random.nextInt(2)));
        }
        return canCheck ? PokerAction.check() : PokerAction.call();

      case PokerBotPersonality.random:
        final roll = _random.nextDouble();
        if (roll < 0.15) {
          return canCheck ? PokerAction.check() : PokerAction.fold();
        }
        if (roll < 0.65) {
          return canCheck ? PokerAction.check() : PokerAction.call();
        }
        if (bot.balance >= toCall + currentRaise) {
          return PokerAction.raise(currentRaise);
        }
        return canCheck ? PokerAction.check() : PokerAction.call();

      case PokerBotPersonality.smartBalanced:
        if (finalStrength < 0.35) {
          if (toCall > potSize * 0.25) {
            return PokerAction.fold();
          }
          return canCheck ? PokerAction.check() : PokerAction.call();
        }
        if (finalStrength >= 0.68 && bot.balance >= toCall + currentRaise && _random.nextDouble() < 0.5) {
          return PokerAction.raise(currentRaise);
        }
        return canCheck ? PokerAction.check() : PokerAction.call();
    }
  }

  /// Generates reaction emotes based on personality and confidence.
  static String? getReactionEmote(PokerBotPersonality personality, double strength) {
    if (_random.nextDouble() > 0.4) return null; // Keep talking infrequent

    final List<String> emotes;
    if (strength > 0.75) {
      switch (personality) {
        case PokerBotPersonality.aggressive: emotes = ['🔥 My time.', '💰 Build that pot!', '💪 Easy money.']; break;
        case PokerBotPersonality.passive: emotes = ['😅 Looking ok.', '🙂 Nice board.']; break;
        case PokerBotPersonality.tight: emotes = ['😐 Solid hands.', '📈 Mathematically sound.']; break;
        case PokerBotPersonality.loose: emotes = ['🤪 Let\'s ride!', '🎰 JACKPOT!']; break;
        case PokerBotPersonality.bluffHeavy: emotes = ['😎 You guys are scared.', '🤫 Shhh...']; break;
        case PokerBotPersonality.smartBalanced: emotes = ['🧠 Positive expected value.', '😐 Standard range.']; break;
        case PokerBotPersonality.random: emotes = ['🎲 Wild times!', '🤪 Woohoo!']; break;
      }
    } else if (strength < 0.3) {
      switch (personality) {
        case PokerBotPersonality.aggressive: emotes = ['😤 Bad run.', '🥊 Still swinging.']; break;
        case PokerBotPersonality.passive: emotes = ['😰 I\'m sweating...', '😬 Scared.']; break;
        case PokerBotPersonality.tight: emotes = ['🧐 Fold targets.', '😐 Variance.']; break;
        case PokerBotPersonality.loose: emotes = ['🤪 I play anything!', '💀 Risky.']; break;
        case PokerBotPersonality.bluffHeavy: emotes = ['😎 I got this.', '🔥 Fear me.']; break;
        case PokerBotPersonality.smartBalanced: emotes = ['📉 Negative EV.', '😐 Recalculating...']; break;
        case PokerBotPersonality.random: emotes = ['🎲 Coin flips.', '🤪 Folds? Never!']; break;
      }
    } else {
      switch (personality) {
        case PokerBotPersonality.aggressive: emotes = ['👀 Your move.', '😤 Waiting...']; break;
        case PokerBotPersonality.passive: emotes = ['🙂 I check.', '😅 Good cards?']; break;
        case PokerBotPersonality.tight: emotes = ['🧐 Range checks.']; break;
        case PokerBotPersonality.loose: emotes = ['🤪 Blinds and calls!', '🎲 Gamble!']; break;
        case PokerBotPersonality.bluffHeavy: emotes = ['😎 Keep raising.', '🤫 Bluffing? Me?']; break;
        case PokerBotPersonality.smartBalanced: emotes = ['🧠 Calculating odds...']; break;
        case PokerBotPersonality.random: emotes = ['🤪 What\'s poker?']; break;
      }
    }

    return emotes[_random.nextInt(emotes.length)];
  }
}
