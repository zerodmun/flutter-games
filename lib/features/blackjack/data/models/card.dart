enum CardSuit {
  hearts,
  diamonds,
  clubs,
  spades;

  String get symbol {
    switch (this) {
      case CardSuit.hearts: return '♥';
      case CardSuit.diamonds: return '♦';
      case CardSuit.clubs: return '♣';
      case CardSuit.spades: return '♠';
    }
  }

  bool get isRed => this == CardSuit.hearts || this == CardSuit.diamonds;
}

enum CardRank {
  two('2', 2),
  three('3', 3),
  four('4', 4),
  five('5', 5),
  six('6', 6),
  seven('7', 7),
  eight('8', 8),
  nine('9', 9),
  ten('10', 10),
  jack('J', 10),
  queen('Q', 10),
  king('K', 10),
  ace('A', 11);

  final String label;
  final int value;
  const CardRank(this.label, this.value);
}

class BlackjackCard {
  final CardSuit suit;
  final CardRank rank;
  final bool isFaceUp;

  const BlackjackCard({
    required this.suit,
    required this.rank,
    this.isFaceUp = true,
  });

  BlackjackCard copyWith({
    CardSuit? suit,
    CardRank? rank,
    bool? isFaceUp,
  }) {
    return BlackjackCard(
      suit: suit ?? this.suit,
      rank: rank ?? this.rank,
      isFaceUp: isFaceUp ?? this.isFaceUp,
    );
  }

  @override
  String toString() => '${rank.label}${suit.symbol}';
}
