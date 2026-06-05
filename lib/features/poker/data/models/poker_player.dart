import 'poker_card.dart';

enum PokerPlayerStatus {
  active,     // In the hand, needs to act
  acted,      // Action complete for current round
  folded,     // Folded out of the hand
  allIn,      // Went all-in
  outOfChips  // Eliminated from the game (balance = 0)
}

enum PokerBotDifficulty {
  easy,
  medium,
  hard,
  pro
}

enum PokerBotPersonality {
  aggressive,
  passive,
  tight,
  loose,
  bluffHeavy,
  smartBalanced,
  random;

  String get displayName {
    switch (this) {
      case PokerBotPersonality.aggressive: return 'Aggressive';
      case PokerBotPersonality.passive: return 'Passive';
      case PokerBotPersonality.tight: return 'Tight';
      case PokerBotPersonality.loose: return 'Loose';
      case PokerBotPersonality.bluffHeavy: return 'Maniac';
      case PokerBotPersonality.smartBalanced: return 'Pro Balanced';
      case PokerBotPersonality.random: return 'Wildcard';
    }
  }
}

class PokerPlayer {
  final String id;
  final String name;
  final String avatar;
  final double balance;
  final List<PokerCard> cards;
  final PokerPlayerStatus status;
  final double roundBet;
  final double totalContributed;
  final bool isBot;
  final PokerBotDifficulty? botDifficulty;
  final PokerBotPersonality? botPersonality;
  final String? lastEmote;
  final String? lastAction;
  final bool hasActed;

  const PokerPlayer({
    required this.id,
    required this.name,
    required this.avatar,
    this.balance = 1000.0,
    this.cards = const [],
    this.status = PokerPlayerStatus.active,
    this.roundBet = 0.0,
    this.totalContributed = 0.0,
    this.isBot = false,
    this.botDifficulty,
    this.botPersonality,
    this.lastEmote,
    this.lastAction,
    this.hasActed = false,
  });

  bool get isFolded => status == PokerPlayerStatus.folded;
  bool get isAllIn => status == PokerPlayerStatus.allIn;
  bool get isEliminated => status == PokerPlayerStatus.outOfChips;
  bool get isPlayable => !isFolded && !isEliminated;

  PokerPlayer copyWith({
    String? id,
    String? name,
    String? avatar,
    double? balance,
    List<PokerCard>? cards,
    PokerPlayerStatus? status,
    double? roundBet,
    double? totalContributed,
    bool? isBot,
    PokerBotDifficulty? botDifficulty,
    PokerBotPersonality? botPersonality,
    String? lastEmote,
    String? lastAction,
    bool? hasActed,
  }) {
    return PokerPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      balance: balance ?? this.balance,
      cards: cards ?? this.cards,
      status: status ?? this.status,
      roundBet: roundBet ?? this.roundBet,
      totalContributed: totalContributed ?? this.totalContributed,
      isBot: isBot ?? this.isBot,
      botDifficulty: botDifficulty ?? this.botDifficulty,
      botPersonality: botPersonality ?? this.botPersonality,
      lastEmote: lastEmote ?? this.lastEmote,
      lastAction: lastAction ?? this.lastAction,
      hasActed: hasActed ?? this.hasActed,
    );
  }

  @override
  String toString() {
    return 'PokerPlayer($name, Balance: \$$balance, Status: $status, Hand: $cards, roundBet: $roundBet)';
  }
}
