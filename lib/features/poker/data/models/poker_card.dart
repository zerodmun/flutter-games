enum PokerSuit {
  hearts,
  diamonds,
  clubs,
  spades;

  String get symbol {
    switch (this) {
      case PokerSuit.hearts: return '♥';
      case PokerSuit.diamonds: return '♦';
      case PokerSuit.clubs: return '♣';
      case PokerSuit.spades: return '♠';
    }
  }

  bool get isRed => this == PokerSuit.hearts || this == PokerSuit.diamonds;
}

enum PokerRank {
  two('2', 2),
  three('3', 3),
  four('4', 4),
  five('5', 5),
  six('6', 6),
  seven('7', 7),
  eight('8', 8),
  nine('9', 9),
  ten('10', 10),
  jack('J', 11),
  queen('Q', 12),
  king('K', 13),
  ace('A', 14);

  final String label;
  final int value;
  const PokerRank(this.label, this.value);
}

class PokerCard {
  final PokerSuit suit;
  final PokerRank rank;
  final bool isFaceUp;

  const PokerCard({
    required this.suit,
    required this.rank,
    this.isFaceUp = true,
  });

  PokerCard copyWith({
    PokerSuit? suit,
    PokerRank? rank,
    bool? isFaceUp,
  }) {
    return PokerCard(
      suit: suit ?? this.suit,
      rank: rank ?? this.rank,
      isFaceUp: isFaceUp ?? this.isFaceUp,
    );
  }

  @override
  String toString() => '${rank.label}${suit.symbol}';
}
