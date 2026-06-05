import '../data/models/poker_card.dart';
import '../data/models/poker_hand_score.dart';

class PokerHandEvaluator {
  /// Evaluates all 7 available cards (2 hole + 5 community) and finds the best 5-card hand.
  static PokerHandScore getBestHand(List<PokerCard> sevenCards) {
    if (sevenCards.length < 5) {
      return PokerHandScore.worst();
    }
    
    final combos = _combinations(sevenCards, 5);
    PokerHandScore bestScore = PokerHandScore.worst();

    for (var combo in combos) {
      final score = evaluateFiveCards(combo);
      if (score.compareTo(bestScore) > 0) {
        bestScore = score;
      }
    }

    return bestScore;
  }

  /// Evaluates exactly 5 cards and returns their score.
  static PokerHandScore evaluateFiveCards(List<PokerCard> cards) {
    final sorted = List<PokerCard>.from(cards)
      ..sort((a, b) => b.rank.value.compareTo(a.rank.value));

    final isFlush = sorted.every((c) => c.suit == sorted.first.suit);

    // Check straight
    bool isStraight = false;
    
    // Check standard straight (e.g. T-9-8-7-6)
    if (sorted[0].rank.value - sorted[4].rank.value == 4 &&
        sorted[0].rank.value != sorted[1].rank.value &&
        sorted[1].rank.value != sorted[2].rank.value &&
        sorted[2].rank.value != sorted[3].rank.value &&
        sorted[3].rank.value != sorted[4].rank.value) {
      isStraight = true;
    }

    // Check Ace-low straight (A, 5, 4, 3, 2)
    // Ranks sorted will be Ace(14), 5, 4, 3, 2
    bool isAceLowStraight = false;
    if (sorted[0].rank == PokerRank.ace &&
        sorted[1].rank == PokerRank.five &&
        sorted[2].rank == PokerRank.four &&
        sorted[3].rank == PokerRank.three &&
        sorted[4].rank == PokerRank.two) {
      isStraight = true;
      isAceLowStraight = true;
    }

    // Group cards by rank to find pairs, trips, quads
    final counts = <PokerRank, int>{};
    for (var c in sorted) {
      counts[c.rank] = (counts[c.rank] ?? 0) + 1;
    }

    final sortedGroups = counts.entries.toList()
      ..sort((a, b) {
        // Sort by count descending, then by rank value descending
        int cmp = b.value.compareTo(a.value);
        if (cmp == 0) {
          return b.key.value.compareTo(a.key.value);
        }
        return cmp;
      });

    // 1. Straight Flush / Royal Flush
    if (isFlush && isStraight) {
      if (isAceLowStraight) {
        return const PokerHandScore(HandRank.straightFlush, [5]); // Ace-low straight flush max card is 5
      }
      if (sorted.first.rank == PokerRank.ace) {
        return const PokerHandScore(HandRank.royalFlush, [14]);
      }
      return PokerHandScore(HandRank.straightFlush, [sorted.first.rank.value]);
    }

    // 2. Four of a Kind
    if (sortedGroups[0].value == 4) {
      return PokerHandScore(HandRank.fourOfAKind, [
        sortedGroups[0].key.value, // Rank of the four
        sortedGroups[1].key.value, // Kicker
      ]);
    }

    // 3. Full House
    if (sortedGroups[0].value == 3 && sortedGroups[1].value == 2) {
      return PokerHandScore(HandRank.fullHouse, [
        sortedGroups[0].key.value, // Rank of the trips
        sortedGroups[1].key.value, // Rank of the pair
      ]);
    }

    // 4. Flush
    if (isFlush) {
      return PokerHandScore(HandRank.flush, sorted.map((c) => c.rank.value).toList());
    }

    // 5. Straight
    if (isStraight) {
      if (isAceLowStraight) {
        return const PokerHandScore(HandRank.straight, [5]);
      }
      return PokerHandScore(HandRank.straight, [sorted.first.rank.value]);
    }

    // 6. Three of a Kind
    if (sortedGroups[0].value == 3) {
      return PokerHandScore(HandRank.threeOfAKind, [
        sortedGroups[0].key.value, // Rank of the trips
        sortedGroups[1].key.value, // Kicker 1
        sortedGroups[2].key.value, // Kicker 2
      ]);
    }

    // 7. Two Pair
    if (sortedGroups[0].value == 2 && sortedGroups[1].value == 2) {
      return PokerHandScore(HandRank.twoPair, [
        sortedGroups[0].key.value, // High pair rank
        sortedGroups[1].key.value, // Low pair rank
        sortedGroups[2].key.value, // Kicker
      ]);
    }

    // 8. One Pair
    if (sortedGroups[0].value == 2) {
      return PokerHandScore(HandRank.pair, [
        sortedGroups[0].key.value, // Pair rank
        sortedGroups[1].key.value, // Kicker 1
        sortedGroups[2].key.value, // Kicker 2
        sortedGroups[3].key.value, // Kicker 3
      ]);
    }

    // 9. High Card
    return PokerHandScore(HandRank.highCard, sorted.map((c) => c.rank.value).toList());
  }

  /// Generates combinations of size k from a list.
  static List<List<T>> _combinations<T>(List<T> list, int k) {
    final List<List<T>> result = [];
    void helper(List<T> combo, int start) {
      if (combo.length == k) {
        result.add(List<T>.from(combo));
        return;
      }
      for (int i = start; i < list.length; i++) {
        combo.add(list[i]);
        helper(combo, i + 1);
        combo.removeLast();
      }
    }
    helper([], 0);
    return result;
  }
}
