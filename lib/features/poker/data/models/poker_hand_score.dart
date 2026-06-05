import 'dart:math';

enum HandRank {
  highCard,
  pair,
  twoPair,
  threeOfAKind,
  straight,
  flush,
  fullHouse,
  fourOfAKind,
  straightFlush,
  royalFlush;

  String get displayName {
    switch (this) {
      case HandRank.highCard: return 'High Card';
      case HandRank.pair: return 'Pair';
      case HandRank.twoPair: return 'Two Pair';
      case HandRank.threeOfAKind: return 'Three of a Kind';
      case HandRank.straight: return 'Straight';
      case HandRank.flush: return 'Flush';
      case HandRank.fullHouse: return 'Full House';
      case HandRank.fourOfAKind: return 'Four of a Kind';
      case HandRank.straightFlush: return 'Straight Flush';
      case HandRank.royalFlush: return 'Royal Flush';
    }
  }
}

class PokerHandScore implements Comparable<PokerHandScore> {
  final HandRank rank;
  final List<int> values; // High card values used for kicker resolution

  const PokerHandScore(this.rank, this.values);

  @override
  int compareTo(PokerHandScore other) {
    int cmp = rank.index.compareTo(other.rank.index);
    if (cmp != 0) return cmp;
    
    // Compare kicker/value lists element by element
    final len = min(values.length, other.values.length);
    for (int i = 0; i < len; i++) {
      int valCmp = values[i].compareTo(other.values[i]);
      if (valCmp != 0) return valCmp;
    }
    return 0;
  }

  static PokerHandScore worst() => const PokerHandScore(HandRank.highCard, [0]);

  @override
  String toString() => '${rank.displayName} (${values.join(", ")})';
}
