import 'hand.dart';

enum BotDifficulty {
  easy,
  normal,
  hard,
  casinoPro;

  String get displayName {
    switch (this) {
      case BotDifficulty.easy: return 'Easy';
      case BotDifficulty.normal: return 'Normal';
      case BotDifficulty.hard: return 'Hard';
      case BotDifficulty.casinoPro: return 'Casino Pro';
    }
  }
}

enum BotPersonality {
  aggressive,
  careful,
  riskyGambler,
  professional;

  String get displayName {
    switch (this) {
      case BotPersonality.aggressive: return 'Aggressive';
      case BotPersonality.careful: return 'Careful';
      case BotPersonality.riskyGambler: return 'Risky';
      case BotPersonality.professional: return 'Pro Dealer';
    }
  }

  String get description {
    switch (this) {
      case BotPersonality.aggressive: return 'Hits often, loves doubling down.';
      case BotPersonality.careful: return 'Stands early, plays very safe.';
      case BotPersonality.riskyGambler: return 'Loves splits and taking wild chances.';
      case BotPersonality.professional: return 'Follows optimal casino strategy.';
    }
  }
}

class BlackjackPlayer {
  final String id;
  final String name;
  final String avatar;
  final double balance;
  final List<BlackjackHand> hands;
  final bool isBot;
  final BotDifficulty? botDifficulty;
  final BotPersonality? botPersonality;
  final String? lastEmote;
  final double confidenceLevel; // 0.0 to 1.0
  final bool isDealer;

  const BlackjackPlayer({
    required this.id,
    required this.name,
    required this.avatar,
    this.balance = 1000.0,
    this.hands = const [BlackjackHand()],
    this.isBot = false,
    this.botDifficulty,
    this.botPersonality,
    this.lastEmote,
    this.confidenceLevel = 0.5,
    this.isDealer = false,
  });

  bool get isBusted => hands.every((hand) => hand.isBusted);
  
  bool get hasActiveHand => hands.any((hand) => !hand.status.isFinished);

  BlackjackPlayer copyWith({
    String? id,
    String? name,
    String? avatar,
    double? balance,
    List<BlackjackHand>? hands,
    bool? isBot,
    BotDifficulty? botDifficulty,
    BotPersonality? botPersonality,
    String? lastEmote,
    double? confidenceLevel,
    bool? isDealer,
  }) {
    return BlackjackPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      balance: balance ?? this.balance,
      hands: hands ?? this.hands,
      isBot: isBot ?? this.isBot,
      botDifficulty: botDifficulty ?? this.botDifficulty,
      botPersonality: botPersonality ?? this.botPersonality,
      lastEmote: lastEmote ?? this.lastEmote,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      isDealer: isDealer ?? this.isDealer,
    );
  }

  @override
  String toString() {
    return 'Player($name, Balance: \$$balance, Hands: $hands, isBot: $isBot)';
  }
}
