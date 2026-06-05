import 'card.dart';

enum HandStatus {
  betting,
  playing,
  stood,
  doubled,
  split,
  busted,
  blackjack,
  surrendered,
  won,
  lost,
  push,
  insuranceWon,
  insuranceLost;

  bool get isFinished => 
    this == HandStatus.stood || 
    this == HandStatus.busted || 
    this == HandStatus.blackjack || 
    this == HandStatus.surrendered ||
    this == HandStatus.doubled; // Doubled down hands automatically stand after 1 card.
}

class BlackjackHand {
  final List<BlackjackCard> cards;
  final double bet;
  final HandStatus status;
  final bool isFromSplit;

  const BlackjackHand({
    this.cards = const [],
    this.bet = 0.0,
    this.status = HandStatus.betting,
    this.isFromSplit = false,
  });

  int get score {
    if (cards.isEmpty) return 0;
    int total = 0;
    int aceCount = 0;

    for (var card in cards) {
      if (!card.isFaceUp) continue;
      total += card.rank.value;
      if (card.rank == CardRank.ace) {
        aceCount++;
      }
    }

    while (total > 21 && aceCount > 0) {
      total -= 10;
      aceCount--;
    }

    return total;
  }

  bool get isBusted => score > 21;
  
  bool get isBlackjack {
    return cards.length == 2 && score == 21 && !isFromSplit;
  }

  bool get isSoft {
    if (cards.isEmpty) return false;
    int total = 0;
    int aceCount = 0;
    for (var card in cards) {
      if (!card.isFaceUp) continue;
      total += card.rank.value;
      if (card.rank == CardRank.ace) {
        aceCount++;
      }
    }
    while (total > 21 && aceCount > 0) {
      total -= 10;
      aceCount--;
    }
    return aceCount > 0;
  }

  BlackjackHand addCard(BlackjackCard card) {
    final updatedCards = List<BlackjackCard>.from(cards)..add(card);
    HandStatus updatedStatus = status;
    if (status == HandStatus.betting) {
      updatedStatus = HandStatus.playing;
    }
    
    // Auto-stand if 21 is hit or hand is busted
    int updatedScore = _calculateScore(updatedCards);
    if (updatedScore > 21) {
      updatedStatus = HandStatus.busted;
    } else if (updatedScore == 21) {
      updatedStatus = updatedCards.length == 2 && !isFromSplit 
          ? HandStatus.blackjack 
          : HandStatus.stood;
    }

    return copyWith(
      cards: updatedCards,
      status: updatedStatus,
    );
  }

  static int _calculateScore(List<BlackjackCard> cardList) {
    int total = 0;
    int aceCount = 0;
    for (var card in cardList) {
      if (!card.isFaceUp) continue;
      total += card.rank.value;
      if (card.rank == CardRank.ace) aceCount++;
    }
    while (total > 21 && aceCount > 0) {
      total -= 10;
      aceCount--;
    }
    return total;
  }

  BlackjackHand copyWith({
    List<BlackjackCard>? cards,
    double? bet,
    HandStatus? status,
    bool? isFromSplit,
  }) {
    return BlackjackHand(
      cards: cards ?? this.cards,
      bet: bet ?? this.bet,
      status: status ?? this.status,
      isFromSplit: isFromSplit ?? this.isFromSplit,
    );
  }

  @override
  String toString() => '$cards (Score: $score, Bet: $bet, Status: $status)';
}
