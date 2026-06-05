import 'dart:math';
import '../data/models/player.dart';
import '../data/models/hand.dart';
import '../data/models/card.dart';

enum BlackjackAction {
  hit,
  stand,
  doubleDown,
  split,
  surrender
}

class AIManager {
  static final Random _random = Random();

  /// Gets the bot action based on difficulty, personality, and current hand vs dealer up-card.
  static BlackjackAction getBotDecision({
    required BlackjackPlayer bot,
    required BlackjackHand hand,
    required BlackjackCard dealerUpCard,
    required bool canDouble,
    required bool canSplit,
    required bool canSurrender,
    required int runningCount, // Support card-counting for Pro bots
  }) {
    final difficulty = bot.botDifficulty ?? BotDifficulty.normal;
    final personality = bot.botPersonality ?? BotPersonality.professional;

    final playerScore = hand.score;
    final isSoft = hand.isSoft;
    final dealerScore = dealerUpCard.rank.value;

    // 1. Get perfect basic strategy decision
    BlackjackAction action = _getBasicStrategyAction(
      playerScore: playerScore,
      isSoft: isSoft,
      dealerScore: dealerScore,
      canDouble: canDouble,
      canSplit: canSplit,
      canSurrender: canSurrender,
    );

    // 2. Pro bot card counting adjustments (Illustrious 18 adjustments)
    if (difficulty == BotDifficulty.casinoPro) {
      action = _applyCardCountingAdjustments(
        action: action,
        playerScore: playerScore,
        dealerScore: dealerScore,
        runningCount: runningCount,
      );
    }

    // 3. Apply difficulty-based mistake/randomness probabilities
    double mistakeChance = 0.0;
    switch (difficulty) {
      case BotDifficulty.easy:
        mistakeChance = 0.25;
        break;
      case BotDifficulty.normal:
        mistakeChance = 0.08;
        break;
      case BotDifficulty.hard:
      case BotDifficulty.casinoPro:
        mistakeChance = 0.0;
        break;
    }

    if (_random.nextDouble() < mistakeChance) {
      // Pick random choice between HIT or STAND (the most common mistakes)
      return _random.nextBool() ? BlackjackAction.hit : BlackjackAction.stand;
    }

    // 4. Apply personality biases
    action = _applyPersonalityBias(
      action: action,
      personality: personality,
      playerScore: playerScore,
      dealerScore: dealerScore,
      canDouble: canDouble,
      canSplit: canSplit,
    );

    // 5. Final fallback checks (e.g. can't double down if not allowed)
    if (action == BlackjackAction.doubleDown && !canDouble) {
      action = BlackjackAction.hit;
    }
    if (action == BlackjackAction.split && !canSplit) {
      action = BlackjackAction.hit;
    }
    if (action == BlackjackAction.surrender && !canSurrender) {
      action = playerScore > 15 ? BlackjackAction.stand : BlackjackAction.hit;
    }

    return action;
  }

  /// Implementation of perfect basic strategy.
  static BlackjackAction _getBasicStrategyAction({
    required int playerScore,
    required bool isSoft,
    required int dealerScore,
    required bool canDouble,
    required bool canSplit,
    required bool canSurrender,
  }) {
    // Check split first
    if (canSplit) {
      // Splitting Aces & 8s is standard blackjack rule
      if (playerScore == 16 || playerScore == 22) { // 8+8 or Ace+Ace (initial ace val is 11, so 22)
        return BlackjackAction.split;
      }
      
      // Split 9s vs dealer 2-9 (except 7)
      if (playerScore == 18 && dealerScore >= 2 && dealerScore <= 9 && dealerScore != 7) {
        return BlackjackAction.split;
      }
      // Split 7s vs dealer 2-7
      if (playerScore == 14 && dealerScore <= 7) {
        return BlackjackAction.split;
      }
      // Split 6s vs dealer 2-6
      if (playerScore == 12 && dealerScore <= 6) {
        return BlackjackAction.split;
      }
      // Split 2s and 3s vs dealer 2-7
      if ((playerScore == 4 || playerScore == 6) && dealerScore <= 7) {
        return BlackjackAction.split;
      }
    }

    // Soft Totals (Ace + X)
    if (isSoft) {
      if (playerScore >= 20) return BlackjackAction.stand;
      if (playerScore == 19) {
        return (canDouble && dealerScore == 6) ? BlackjackAction.doubleDown : BlackjackAction.stand;
      }
      if (playerScore == 18) {
        if (dealerScore >= 2 && dealerScore <= 6 && canDouble) return BlackjackAction.doubleDown;
        if (dealerScore == 7 || dealerScore == 8) return BlackjackAction.stand;
        return BlackjackAction.hit;
      }
      // Soft 13-17: Double if dealer shows 5-6 (or 4-6 for soft 15-17), else hit
      if (playerScore >= 15 && playerScore <= 17) {
        if (dealerScore >= 4 && dealerScore <= 6 && canDouble) return BlackjackAction.doubleDown;
        return BlackjackAction.hit;
      }
      if (playerScore >= 13 && playerScore <= 14) {
        if (dealerScore >= 5 && dealerScore <= 6 && canDouble) return BlackjackAction.doubleDown;
        return BlackjackAction.hit;
      }
    }

    // Hard Totals
    if (playerScore >= 17) return BlackjackAction.stand;
    if (playerScore >= 13 && playerScore <= 16) {
      if (dealerScore >= 2 && dealerScore <= 6) {
        return BlackjackAction.stand;
      }
      // Surrender options for hard 15 or 16 against 9, 10, A
      if (canSurrender) {
        if (playerScore == 16 && (dealerScore == 9 || dealerScore == 10 || dealerScore == 11)) {
          return BlackjackAction.surrender;
        }
        if (playerScore == 15 && (dealerScore == 10 || dealerScore == 11)) {
          return BlackjackAction.surrender;
        }
      }
      return BlackjackAction.hit;
    }
    if (playerScore == 12) {
      return (dealerScore >= 4 && dealerScore <= 6) ? BlackjackAction.stand : BlackjackAction.hit;
    }
    
    // Double down candidates
    if (playerScore == 11) {
      return canDouble ? BlackjackAction.doubleDown : BlackjackAction.hit;
    }
    if (playerScore == 10) {
      return (canDouble && dealerScore <= 9) ? BlackjackAction.doubleDown : BlackjackAction.hit;
    }
    if (playerScore == 9) {
      return (canDouble && dealerScore >= 3 && dealerScore <= 6) ? BlackjackAction.doubleDown : BlackjackAction.hit;
    }

    return BlackjackAction.hit;
  }

  /// Adjust bot actions based on card counting (only for Pro).
  static BlackjackAction _applyCardCountingAdjustments({
    required BlackjackAction action,
    required int playerScore,
    required int dealerScore,
    required int runningCount,
  }) {
    // Illustrious 18 rules:
    // Stand on 16 vs 10 if count is > 0
    if (playerScore == 16 && dealerScore == 10 && runningCount > 0) {
      return BlackjackAction.stand;
    }
    // Stand on 15 vs 10 if count is > 4
    if (playerScore == 15 && dealerScore == 10 && runningCount > 4) {
      return BlackjackAction.stand;
    }
    // Double on 10 vs Ten/Ace if count is highly positive
    if (playerScore == 10 && dealerScore >= 10 && runningCount > 4) {
      return BlackjackAction.doubleDown;
    }
    return action;
  }

  /// Apply personality tweaks.
  static BlackjackAction _applyPersonalityBias({
    required BlackjackAction action,
    required BotPersonality personality,
    required int playerScore,
    required int dealerScore,
    required bool canDouble,
    required bool canSplit,
  }) {
    switch (personality) {
      case BotPersonality.aggressive:
        // Double down aggressively on hard 9 or 10 or soft hands, even if basic strategy doesn't advise
        if (canDouble && (playerScore == 9 || playerScore == 10) && dealerScore > 6 && _random.nextDouble() < 0.4) {
          return BlackjackAction.doubleDown;
        }
        // Hits on hard 12-13 against dealer low cards because they want to score higher
        if (action == BlackjackAction.stand && playerScore <= 13 && _random.nextDouble() < 0.3) {
          return BlackjackAction.hit;
        }
        break;
      case BotPersonality.careful:
        // Stands early to avoid busting
        if (action == BlackjackAction.hit && playerScore >= 14 && _random.nextDouble() < 0.25) {
          return BlackjackAction.stand;
        }
        // Refuses to double on risky hands
        if (action == BlackjackAction.doubleDown && playerScore == 9 && _random.nextDouble() < 0.5) {
          return BlackjackAction.hit;
        }
        break;
      case BotPersonality.riskyGambler:
        // High chance of doubling down on anything from 8 to 12
        if (canDouble && playerScore >= 8 && playerScore <= 12 && _random.nextDouble() < 0.3) {
          return BlackjackAction.doubleDown;
        }
        // Splitting 10s is a bad move but risky gamblers do it!
        if (canSplit && playerScore == 20 && _random.nextDouble() < 0.15) {
          return BlackjackAction.split;
        }
        break;
      case BotPersonality.professional:
        // Professional bot does not deviate from math
        break;
    }
    return action;
  }

  /// Generates reaction emotes based on personality, confidence, and current score.
  static String? getReactionEmote(BotPersonality personality, double scoreConfidence, HandStatus status) {
    final chance = _random.nextDouble();
    if (chance > 0.6) return null; // Bots don't talk all the time

    List<String> emotes = [];
    switch (status) {
      case HandStatus.blackjack:
        emotes = _getBlackjackEmotes(personality);
        break;
      case HandStatus.busted:
        emotes = _getBustEmotes(personality);
        break;
      case HandStatus.stood:
        emotes = _getStandEmotes(personality, scoreConfidence);
        break;
      case HandStatus.doubled:
        emotes = _getDoubleEmotes(personality);
        break;
      case HandStatus.won:
        emotes = _getWinEmotes(personality);
        break;
      case HandStatus.lost:
        emotes = _getLoseEmotes(personality);
        break;
      default:
        // General emotes during card check
        if (scoreConfidence > 0.8) {
          emotes = _getHighConfidenceEmotes(personality);
        } else if (scoreConfidence < 0.4) {
          emotes = _getLowConfidenceEmotes(personality);
        } else {
          emotes = _getNeutralEmotes(personality);
        }
    }

    if (emotes.isEmpty) return null;
    return emotes[_random.nextInt(emotes.length)];
  }

  static List<String> _getBlackjackEmotes(BotPersonality p) {
    switch (p) {
      case BotPersonality.aggressive: return ['😎 Boom!', '🤑 Jackpot!', '💸 Keep them coming!', '💪 Untouchable!'];
      case BotPersonality.careful: return ['😱 Unbelievable!', '🎉 Thank goodness!', '😅 What a relief!'];
      case BotPersonality.riskyGambler: return ['🤪 Woohoo!', '🔥 I\'m on fire!', '🎰 Pure luck!', '✨ MAGIC!'];
      case BotPersonality.professional: return ['🧠 Basic probability.', '📈 Expected value.', '😐 Hand secured.'];
    }
  }

  static List<String> _getBustEmotes(BotPersonality p) {
    switch (p) {
      case BotPersonality.aggressive: return ['😡 Ugh!', '🤬 Bad deck!', '🥊 Next round...'];
      case BotPersonality.careful: return ['😰 Oh no, I knew it...', '😭 My chips...', '🥺 Too risky...'];
      case BotPersonality.riskyGambler: return ['🤪 Double or nothing next!', '💀 Oof!', '🎲 Win some lose some!'];
      case BotPersonality.professional: return ['🧠 Standard deviation.', '😐 Variance happens.', '📉 Recalculating...'];
    }
  }

  static List<String> _getStandEmotes(BotPersonality p, double confidence) {
    if (confidence > 0.7) {
      switch (p) {
        case BotPersonality.aggressive: return ['😎 Try beating this.', '💪 Strong hand.', '🔥 Locked in.'];
        case BotPersonality.careful: return ['😅 Good enough.', '🙂 Safe zone.'];
        case BotPersonality.riskyGambler: return ['🤪 Pray for me!', '🍀 Luck check.'];
        case BotPersonality.professional: return ['🧠 Highly probable win.', '😐 Stand complete.'];
      }
    } else {
      switch (p) {
        case BotPersonality.aggressive: return ['😤 I dare you.', '👀 Your move.'];
        case BotPersonality.careful: return ['🫣 Scared to bust.', '😬 Holding my breath...'];
        case BotPersonality.riskyGambler: return ['🎲 Let\'s see the cards!', '🧐 Hmmm.'];
        case BotPersonality.professional: return ['😐 Mathematically sound.'];
      }
    }
  }

  static List<String> _getDoubleEmotes(BotPersonality p) {
    switch (p) {
      case BotPersonality.aggressive: return ['🚀 MAXIMUM VALUE!', '💪 Double or nothing!', '😎 Big stacks only.'];
      case BotPersonality.careful: return ['😬 Oh boy, hope this works...', '😰 High stakes...'];
      case BotPersonality.riskyGambler: return ['🤪 WE GO BIG!', '🔥 Let it ride!', '🎰 JACKPOT PATH!'];
      case BotPersonality.professional: return ['🧠 Doubling down is positive EV.', '😐 Math mandates a double.'];
    }
  }

  static List<String> _getWinEmotes(BotPersonality p) {
    switch (p) {
      case BotPersonality.aggressive: return ['🤑 Paid out!', '😎 Too easy.', '💪 Told you!'];
      case BotPersonality.careful: return ['😅 Safe and sound.', '🎉 Wonderful!'];
      case BotPersonality.riskyGambler: return ['🤪 Keep the streak!', '💸 Rich life!'];
      case BotPersonality.professional: return ['📈 positive variance.', '😐 Routine payout.'];
    }
  }

  static List<String> _getLoseEmotes(BotPersonality p) {
    switch (p) {
      case BotPersonality.aggressive: return ['😡 Rigged table!', '🥊 Not finished yet.'];
      case BotPersonality.careful: return ['😭 Should have surrendered.', '🥺 Sad times...'];
      case BotPersonality.riskyGambler: return ['🤪 Next one is mine!', '💀 Reloading!'];
      case BotPersonality.professional: return ['📉 Standard house edge.', '😐 Next distribution.'];
    }
  }

  static List<String> _getHighConfidenceEmotes(BotPersonality p) {
    switch (p) {
      case BotPersonality.aggressive: return ['😎 Feeling good.', '💪 Easiest game.'];
      case BotPersonality.careful: return ['🙂 Looking okay.'];
      case BotPersonality.riskyGambler: return ['🤪 I smell a victory!'];
      case BotPersonality.professional: return ['🧠 High probability cards.'];
    }
  }

  static List<String> _getLowConfidenceEmotes(BotPersonality p) {
    switch (p) {
      case BotPersonality.aggressive: return ['😤 Tough break.'];
      case BotPersonality.careful: return ['😰 Bad cards...', '😬 Sweating...'];
      case BotPersonality.riskyGambler: return ['🤪 Risky, just how I like it!'];
      case BotPersonality.professional: return ['😐 Negative expected value.'];
    }
  }

  static List<String> _getNeutralEmotes(BotPersonality p) {
    switch (p) {
      case BotPersonality.aggressive: return ['👀 Waiting...'];
      case BotPersonality.careful: return ['🤔 Let me check.'];
      case BotPersonality.riskyGambler: return ['🎲 Flipping coins.'];
      case BotPersonality.professional: return ['🧠 Running strategy...'];
    }
  }
}
